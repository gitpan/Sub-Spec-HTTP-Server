package Sub::Spec::HTTP::Server;
BEGIN {
  $Sub::Spec::HTTP::Server::VERSION = '0.05';
}
# ABSTRACT: Serve subroutine calls via HTTP/HTTPS

use 5.010;
use strict;
use warnings;
use Log::Any '$log';

use CGI::Lite;
use HTTP::Daemon;
use HTTP::Daemon::SSL;
use HTTP::Parser;
use HTTP::Request::AsCGI;
use HTTP::Response;
use IO::Handle::Record;
use IO::Select;
use IO::Socket::UNIX;
use Log::Any::Adapter;
use JSON;
use Moo;
use PHP::Serialization;
use SHARYANTO::Proc::Daemon;
use SHARYANTO::YAML::Any;
use Sub::Spec::Caller;
use Sub::Spec::CmdLine;
use Time::HiRes qw(gettimeofday tv_interval);


has name => (is => 'rw', default => sub {
                 my $name = $0;
                 $name =~ s!.*/!!;
                 $name;
             });


has daemonize => (is => 'rw', default=>sub{1});


has sock_path => (is => 'rw');


has pid_path => (is => 'rw');


has error_log_path => (is => 'rw');


has access_log_path => (is => 'rw');


has access_log_max_args_len => (is => 'rw', default=>sub{1024});


has access_log_max_resp_len => (is => 'rw', default=>sub{1024});


has http_port => (is => 'rw', default => sub{80});


has http_bind_host => (is => 'rw', default => sub{"localhost"});


has https_port => (is => 'rw', default => sub{443});


has https_bind_host => (is => 'rw', default=>sub{"localhost"});


has ssl_key_file => (is => 'rw');


has ssl_cert_file => (is => 'rw');


has start_servers => (is => 'rw', default=>sub{3});


has max_requests_per_child => (is => 'rw', default=>sub{1000});


has module_prefix => (is => 'rw');


has req => (is => 'rw');


has resp => (is => 'rw');

# SHARYANTO::Proc::Daemon object
has _daemon => (is => 'rw');

# store server sockets
has _server_socks => (is => 'rw');


my $json = JSON->new->allow_nonref;



sub BUILD {
    my ($self) = @_;

    unless ($self->error_log_path) {
        $self->error_log_path("/var/log/".$self->name."-error.log");
    }
    unless ($self->access_log_path) {
        $self->access_log_path("/var/log/".$self->name."-access.log");
    }
    unless ($self->pid_path) {
        $self->pid_path("/var/run/".$self->name.".pid");
    }
    unless ($self->_daemon) {
        my $daemon = SHARYANTO::Proc::Daemon->new(
            name                    => $self->name,
            error_log_path          => $self->error_log_path,
            access_log_path         => $self->access_log_path,
            pid_path                => $self->pid_path,
            daemonize               => $self->daemonize,
            prefork                 => $self->start_servers,
            after_init              => sub { $self->_after_init },
            main_loop               => sub { $self->_main_loop },
            # currently auto reloading is turned off
        );
        $self->_daemon($daemon);
    }
}


sub stop {
    my ($self) = @_;
    $self->_daemon->kill_running;
}


sub run {
    my ($self) = @_;
    $self->_daemon->run;
}


sub restart {
    my ($self) = @_;
    $self->_daemon->kill_running;
    $self->_daemon->run;
}


sub is_running {
    my ($self) = @_;
    my $pid = $self->_daemon->check_pidfile;
    $pid ? 1:0;
}

sub _main_loop {
    my ($self) = @_;
    $log->info("Child process started (PID $$)");

    my $sel = IO::Select->new(@{ $self->_server_socks });

    for (my $i=1; $i<$self->max_requests_per_child; $i++) {
        $self->_daemon->set_label("listening");
        my @ready = $sel->can_read();
        for my $s (@ready) {
            my $sock = $s->accept();
            $self->req({sock=>$sock});
            $self->resp(undef);
            $self->handle_request();
        }
    }
}


sub before_prefork {}

sub _after_init {
    my ($self) = @_;

    my @server_socks;
    if ($self->sock_path) {
        my $path = $self->sock_path;
        $log->infof("Binding to Unix socket %s (http) ...", $path);

        # probe the unix socket first, this code portion copied from cgiexecd
        my $sock = IO::Socket::UNIX->new(
            Type=>SOCK_STREAM,
            Peer=>$path);
        my $err = $@ unless $sock;
        if ($sock) {
            die "Some process is already listening on $path, aborting";
        } elsif ($err =~ /^connect: permission denied/i) {
            # XXX language dependant
            die "Cannot access $path, aborting";
        } elsif (1) { #$err =~ /^connect: connection refused/i) {
            # XXX language dependant
            unlink $path;
        } elsif ($err !~ /^connect: no such file/i) {
            # XXX language dependant
            die "Cannot bind to $path: $err";
        }
        $sock = IO::Socket::UNIX->new(
            Type=>SOCK_STREAM,
            Local=>$path,
            Listen=>1);
        die "Unable to bind to Unix socket $path" unless $sock;
        push @server_socks, $sock;
    }

    if ($self->http_port) {
        my $port = $self->http_port;
        my $host = $self->http_bind_host;
        $log->infof("Binding to TCP socket %s:%d (http) ...",
                    $host // "*", $port);
        my %args = (LocalPort => $port, Reuse => 1);
        $args{LocalHost} = $host if $host;
        my $sock = HTTP::Daemon->new(%args);
        die sprintf("Unable to bind to TCP socket %s:%d", $host//"*", $port)
            unless $sock;
        push @server_socks, $sock;
    }

    if ($self->https_port) {
        my $port = $self->https_port;
        my $host = $self->https_bind_host;
        $log->infof("Binding to TCP socket %s:%d (https) ...",
                   $host//"*", $port);
        my %args = (LocalPort => $port, Reuse => 1);
        $args{LocalHost} = $host if $host;
        # currently commented out, hangs with larger POST
        #$args{Timeout} = 180;

        $args{SSL_key_file}  = $self->ssl_key_file;
        $args{SSL_cert_file} = $self->ssl_cert_file;
        #$args{SSL_ca_file} = $self->ssl_ca_file;
        #$args{SSL_verify_mode} => 0x01;

        # IO::Socket::SSL is weird? can't work well with IO::Select? it
        # always reports ready.
        my $sock = HTTP::Daemon::SSL->new(%args);

        die sprintf("Unable to bind to TCP socket %s:%d, common cause include ".
                        "port taken or missing server key/cert file",
                    $host//"*", $port)
            unless $sock;
        push @server_socks, $sock;
    }

    $self->_server_socks(\@server_socks);
    $self->before_prefork();
}


sub handle_request {
    my ($self) = @_;

    my $req = $self->req;
    $req->{time_connect} = [gettimeofday];
    $req->{log_extra} = {};
    $self->_daemon->set_label('serving');
    eval {
        $self->_set_req_vars();
        $self->before_parse_http_request();
        $self->parse_http_request();
        $self->get_sub_name();
        $self->get_sub_args();
        $self->auth();
        $self->get_sub_spec();
        $self->authz();
        if ($req->{chunked}) {
            # if client specified logging, we temporarily divert Log::Any logs
            # to the client via chunked response
            $self->_start_chunked_http_response();
            Log::Any::Adapter->set(
                {lexically=>\my $lex},
                "Callback",
                logging_cb => sub {
                    my ($method, $self, $format, @params) = @_;
                    my $msg = join(
                        "",
                        $req->{mark_chunk} ? "L" : "",
                        "[$method]",
                        "[", scalar(localtime), "] ",
                        $format, "\n");
                    $req->{sock}->print(
                        sprintf("%02x\r\n", length($msg)),
                        $msg, "\r\n");
                    # this seems needed?
                    $req->{sock}->flush();
                    # XXX also log to the previous adapter
                },
            );
            $self->call_sub();
        } else {
            # otherwise, logs will be sent to default location (set by
            # Spanel::Log)
            $self->call_sub();
        }
    };
    my $eval_err = $@;
    if ($eval_err) {
        $log->debug("Child died: $eval_err")
            unless $eval_err =~ /^Died at .+ line \d+\.$/; # deliberate die
        $self->resp([500, "Died when processing request: $eval_err"])
            unless $self->resp;
    }
    $self->resp([500, "BUG: response not set"]) if !$self->resp;

    eval { $self->send_http_response() };
    $eval_err = $@;
    $log->debug("Child died when sending response: $eval_err") if $eval_err;

    $req->{time_finish_response} = [gettimeofday];
    $self->access_log();
}


sub before_parse_http_request {}

sub _set_req_vars {
    my ($self) = @_;

    my $req = $self->req;
    my $sock = $req->{sock};

    $req->{proto} = ''; # to avoid perl undef warning
    if ($sock->isa("IO::Socket::UNIX")) {
        $req->{proto}       = 'unix';
        $req->{socket_path} = $sock->hostpath;
        my ($pid, $uid, $gid)  = $sock->peercred;
        $log->trace("Unix socket info: path=$req->{socket_path}, ".
                        "pid=$pid, uid=$uid, gid=$gid");
        $req->{unix_uid}    = $uid;
        $req->{unix_gid}    = $gid;

        # XXX show unix socket path (if later we have more than one)
        $self->_daemon->set_label("serving unix (pid=$pid, uid=$uid)");
    } else {
        $req->{proto}       = 'tcp';
        $req->{server_port} = $sock->sockport;
        $req->{https}       = 1 if $sock->sockport == 950;
        $req->{remote_ip}   = $sock->peerhost;
        $req->{remote_port} = $sock->peerport;
        $self->_daemon->set_label(
            join("",
                 "serving ",
                 $sock->sockport==$self->http_port ? 'http' : 'https',
                 " (", $sock->peerhost, ":", $sock->peerport, ")",
             ));
    }
}


sub parse_http_request {
    my ($self) = @_;
    my $req = $self->req;
    my $sock = $req->{sock};

    $log->trace("-> parse_http_request()");

    if ($req->{proto} eq 'unix') {
        my $parser = HTTP::Parser->new;
        my $status;
        while (my $line = <$sock>) {
            $status = $parser->add($line);
            last if $status == 0;
        }
        if (!defined($status) || # can be undefined too sometimes...
                $status > 0 || ($status < 0 && $status != -3)) {
            # incomplete stat
            $self->resp([400, "Incomplete request (1)"]);
            die;
        }
        $req->{http_req} = $parser->object;
    } else {
        $req->{http_req} = $sock->get_request;
    }

    unless ($req->{http_req}) {
        $self->resp([400, "Incomplete request (2)"]);
        die;
    }

    my $xff = $req->{http_req}->header("X-Forwarded-For");
    $req->{remote_ip_xff} = $xff if $xff;
}


sub get_sub_name {
    my ($self) = @_;
    my $req = $self->req;
    my $http_req = $req->{http_req};

    if ($http_req->header('X-SS-Log-Level')) {
        $req->{log_level} = $http_req->header('X-SS-Log-Level');
        $log->trace("Turning on chunked transfer ...");
        $req->{chunked}++;
    }
    if ($http_req->header('X-SS-Mark-Chunk')) {
        $log->trace("Turning on mark prefix on each chunk ...");
        $req->{mark_chunk}++;
        $log->trace("Turning on chunked transfer ...");
        $req->{chunked}++;
    }

    my $uri = $http_req->uri;
    $log->trace("request URI = $uri");
    unless ($uri =~ m!\A/+v1
                      /+([^/]+(?:/+[^/]+)*) # module
                      /+([^/]+?)    # func
                      (?:;([^?]*))? # opts
                      (?:\?|\z)
                     !x) {
        $self->resp([
            400, "Invalid request URI, please use the syntax ".
                "/v1/MODULE/SUBMODULE/FUNCTION?PARAM=VALUE..."]);
        die;
    }
    my ($module, $sub, $opts) = ($1, $2, $3);

    $module =~ s!/+!::!g;
    unless ($module =~ /\A\w+(?:::\w+)*\z/) {
        $self->resp([
            400, "Invalid module, please use alphanums only, e.g. My/Module"]);
        die;
    }
    $req->{sub_module} = $self->module_prefix ?
        $self->module_prefix.'::'.$module : $module;

    unless ($sub =~ /\A\w+(?:::\w+)*\z/) {
        $self->resp([
            400, "Invalid sub, please use alphanums only, e.g. my_func"]);
        die;
    }
    $req->{sub_name}   = $sub;

    $req->{opts}       = $opts;

    # parse opts
    $opts //= "";
    if (length($opts)) {
        if ($opts =~ /0/) {
            $http_req->header('Content-Type' => 'application/x-spanel-noargs');
        }
        if ($opts =~ /y/) {
            $http_req->header('Accept' => 'text/yaml');
        }
        if ($opts =~ /t/) {
            $http_req->header('Accept' => 'text/html');
        }
        if ($opts =~ /r/) {
            $http_req->header('Accept' => 'text/x-spanel-pretty');
        }
        if ($opts =~ /R/) {
            $http_req->header('Accept' => 'text/x-spanel-nopretty');
        }
        if ($opts =~ /j/) {
            $http_req->header('Accept' => 'application/json');
        }
        if ($opts =~ /p/) {
            $http_req->header('Accept' => 'application/vnd.php.serialized');
        }
        if ($opts =~ /[h?]/) {
            $req->{help}++;
            $http_req->header('Content-Type' => 'application/x-spanel-noargs');
        }

        if ($opts =~ /l:([1-6])(m?)(?::|\z)/) {
            $http_req->header('X-SS-Mark-Chunk' => 1) if $2;
            my $l = $1;
            my $level =
                $l == 6 ? 'trace' :
                $l == 5 ? 'debug' :
                $l == 4 ? 'info' :
                $l == 3 ? 'warning' :
                $l == 2 ? 'error' :
                $l == 1 ? 'fatal' : '';
            $http_req->header('X-SS-Log-Level' => $level) if $level;
        }
    }
    $log->trace("parse request URI: module=$module, sub=$sub, opts=$opts");
}


sub get_sub_args {
    my ($self) = @_;
    my $req = $self->req;
    my $http_req = $req->{http_req};

    my $ct = $http_req->header('Content-Type') // '';
    my $args;
    if ($ct eq 'application/vnd.php.serialized') {
        $log->trace('Request is JSON');
        eval { $args = PHP::Serialization::unserialize($http_req->content) };
        if ($@) {
            $self->resp([
                400, "Invalid PHP serialized data in request body: $@"]);
            die;
        }
    } elsif ($ct eq 'application/x-spanel-noargs') {
        $log->trace("Request doesn't have args");
        $args = {};
    } elsif ($ct eq 'text/yaml') {
        $log->trace('Request is YAML');
        eval { $args = Load($http_req->content) };
        if ($@) {
            $self->resp([
                400, "Invalid YAML in request body: $@"]);
            die;
        }
    } elsif ($ct eq 'application/json') {
        $log->trace('Request is JSON');
        eval { $args = $json->decode($http_req->content) };
        if ($@) {
            $self->resp([
                400, "Invalid JSON in request body: $@"]);
            die;
        }
    } else {
        $log->trace('Request is CGI');
        # normal GET/POST, check each query parameter for :j, :y, :p decoding
        my $c    = HTTP::Request::AsCGI->new($http_req)->setup;
        my $cgi  = CGI::Lite->new;
        my $form = $cgi->parse_form_data;
        $args = {};

        while (my ($k, $v) = each %$form) {
            if ($k =~ /(.+):j$/) {
                $k = $1;
                #$log->trace("CGI parameter $k (json)=$v");
                eval { $v = $json->decode($v) };
                if ($@) {
                    $self->resp([
                        400, "Invalid JSON in query parameter $k: $@"]);
                    die;
                }
                $args->{$k} = $v;
            } elsif ($k =~ /(.+):y$/) {
                $k = $1;
                #$log->trace("CGI parameter $k (yaml)=$v");
                eval { $v = Load($v) };
                if ($@) {
                    $self->resp([
                        400, "Invalid YAML in query parameter $k: $@"]);
                    die;
                }
                $args->{$k} = $v;
            } elsif ($k =~ /(.+):p$/) {
                $k = $1;
                #$log->trace("CGI parameter $k (php)=$v");
                eval { $v = PHP::Serialization::unserialize($v) };
                if ($@) {
                    $self->resp([
                        400, "Invalid PHP serialized data ".
                            "in query parameter $k: $@"]);
                    die;
                }
                $args->{$k} = $v;
            } else {
                #$log->trace("CGI parameter $k=$v");
                $args->{$k} = $v;
            }
        }
    }

    # sanity check on args
    $args //= {};
    unless (ref($args) eq 'HASH') {
        $self->resp([400, "Invalid args, must be a hash"]);
        die;
    }
    #$log->tracef("args = %s", $args);
    $req->{sub_args} = $args;
}


sub get_sub_spec {
    my ($self) = @_;
    my $req = $self->req;

    my $module = $req->{sub_module};
    my $func = $req->{sub_name};
    my $fqspec = $module . "::SPEC";
    no strict 'refs';
    my $fspec = ${$fqspec}{$func};
    unless ($fspec) {
        $self->resp([500, "Can't find spec for module $module sub $func"]);
        die;
    }
    $req->{sub_spec} = $fspec;
}


sub auth {}


sub authz {}


sub call_sub {
    my ($self) = @_;
    my $req = $self->req;

    my $module = $req->{sub_module};
    my $func   = $req->{sub_name};
    my $args   = $req->{sub_args};
    my $spec   = $req->{sub_spec};

    if ($req->{help}) {
        $req->{access_log_mute_resp}++;
        $self->resp([200, "OK", Sub::Spec::CmdLine::gen_usage($spec)]);
        return;
    }

    # help check for unknown arguments here, in the future Sah will handle it
    #$log->tracef("known_args: %s", $known_args);
    for (keys %$args) {
        unless ($spec->{args}{$_}) {
            $self->resp([400, "Unknown arg: $_"]);
            die;
        }
    }

    $req->{time_call_start} = [gettimeofday];
    $self->resp(Sub::Spec::Caller::call_sub(
        $module, $func, $args, {load=>0, convert_datetime_objects=>1}));
    $req->{time_call_end}   = [gettimeofday];
}

sub _start_chunked_http_response {
    my ($self) = @_;
    my $req = $self->req;
    my $sock = $req->{sock};

    $sock->print("HTTP/1.1 200 OK\r\n");
    $sock->print("Content-Type: text/plain\r\n");
    $sock->print("Transfer-Encoding: chunked\r\n");
    $sock->print("\r\n");
    $req->{chunked}++;
}


sub send_http_response {
    $log->trace("-> send_http_response()");
    my ($self) = @_;
    my $req = $self->req;
    my $http_req = $req->{http_req};
    my $sock = $req->{sock};
    my $resp = $self->resp;

    # determine output format

    my $accept;
    $accept = $http_req->header('Accept') if $http_req;
    $accept //= "application/json";
    my $format;
    my $ct;
    if ($accept =~ m!text/(?:html|x-spanel-(?:no)?pretty)!) {
        # if access from browser, give nice readable text dump
        $ct     = 'text/plain';
        $format = $accept =~ /nopretty/ ? 'nopretty' :
            $accept =~ /pretty/ ? 'pretty' : 'text';
        $resp->[2] //= "Success" if $resp->[0] == 200;
    } elsif ($accept eq 'text/yaml') {
        $ct       = $accept;
        $format   = 'yaml';
    } elsif ($accept eq 'application/vnd.php.serialized') {
        $ct       = $accept;
        $format   = 'php';
    } else {
        # fallback is json
        $ct       = 'application/json';
        $format   = 'json';
    }
    my $output = Sub::Spec::CmdLine::format_result(
        $resp, $format, {default_success_message => 'Success'});

    # construct an appropriate HTTP::Response

    my $http_resp = HTTP::Response->new;
    $http_resp->header ('Content-Type' => $ct);
    $http_resp->content($output);
    $http_resp->code(200);
    #$http_resp->message(...);
    # extra headers
    $http_resp->header('Content-Length' => length($output));
    $http_resp->header('Connection' => 'close');
    # Date?

    # send it!
    $log->trace("Sending HTTP response ...");

    # as_string & status_line doesn't produce "HTTP/x.y " in status line
    my $str = join(
        "",
        $req->{mark_chunk} ? "R" : "",
        "HTTP/1.0 ", $http_resp->as_string);
    if ($req->{chunked}) {
        $sock->print(sprintf("%02x\r\n", length($str)));
    }
    $sock->print($str);
    if ($req->{chunked}) {
        $sock->print("\r\n");
        $sock->print("0\r\n");
    }
    $sock->close;
}


sub after_send_http_response {}


sub access_log {
    my ($self) = @_;
    my $req = $self->req;
    my $http_req = $req->{http_req};
    my $resp = $self->resp;

    my $fmt = join(
        "",
        "[%s] ", # time
        "[%s] ", # from
        "\"%s %s\" ", # HTTP method & URI
        "[user %s] ",
        "[mod %s] [sub %s] [args %s %s] ",
        "[resp %s %s] [subt %s] [reqt %s]",
        "%s", # extra info
        "\n"
    );
    my $from;
    if ($req->{proto} eq 'tcp') {
        $from = $req->{remote_ip} . ":" .
            ($req->{https} ? $self->https_port : $self->http_port);
    } else {
        $from = "unix";
    }

    my $args_s = $json->encode($self->{sub_args} // "");
    my $args_len = length($args_s);
    my $args_partial = $args_len > $self->access_log_max_args_len;
    $args_s = substr($args_s, 0, $self->access_log_max_args_len)
        if $args_partial;

    my ($resp_s, $resp_len, $resp_partial);
    if ($req->{access_log_mute_resp}) {
        $resp_s = "*";
        $resp_partial = 0;
        $resp_len = "*";
    } else {
        $resp_s = $json->encode($self->resp // "");
        $resp_len = length($resp_s);
        $resp_partial = $resp_len > $self->access_log_max_resp_len;
        $resp_s = substr($resp_s, 0, $self->access_log_max_resp_len)
            if $resp_partial;
    }

    my $logline = sprintf(
        $fmt,
        scalar(localtime $req->{time_connect}[0]),
        $from,
        $http_req->method, $http_req->uri,
        $req->{auth_user} // "-",
        $req->{sub_module} // "-", $req->{sub_name} // "-",
        $args_len.($args_partial ? "p" : ""), $args_s,
        $resp_len.($resp_partial ? "p" : ""), $resp_s,
        (!defined($req->{time_call_start}) ? "-" :
             !defined($req->{time_call_end}) ? "D" :
                 sprintf("%.3fms",
                         1000*tv_interval($req->{time_call_start},
                                          $req->{time_call_end}))),
        sprintf("%.3fms",
                1000*tv_interval($req->{time_connect},
                                 $req->{time_finish_response})),
        keys(%{$req->{log_extra}}) ? " ".$json->encode($req->{log_extra}) : "",
    );

    if ($self->_daemon->{daemonized}) {
        #warn "Printing to access log $daemon->{_access_log}: $logline";
        # XXX rotating?
        syswrite($self->_daemon->{_access_log}, $logline);
    } else {
        warn $logline;
    }
}

1;


=pod

=head1 NAME

Sub::Spec::HTTP::Server - Serve subroutine calls via HTTP/HTTPS

=head1 VERSION

version 0.05

=head1 SYNOPSIS

In your program:

 use Sub::Spec::HTTP::Server;
 use My::Module1;
 use My::Module2;

 my $server = Sub::Spec::HTTP::Server->new(
     sock_path   => '/var/run/apid.sock',  # activate listening to Unix socket
     #http_port  => 949,                   # default is 80
     #https_port => 1234,                  # activate https
     #ssl_key_file => '/path/to/key.pem',  # need this for https
     #ssl_cert_file => '/path/to/crt.pem', # need this for https
     #max_requests_per_child => 100,       # default is 1000
     #start_servers => 0,                  # default is 3, 0 means don't prefork
     #daemonize => 0,                      # do not go to background
 );
 $server->run;

After running the program, accessing:

 http://localhost:949/My/Module2/func?arg1=1&arg2=2

You will be getting a JSON response:

 [200,"OK",{"the":"result data"}]

=head1 DESCRIPTION

This class is a preforking HTTP (TCP and Unix socket)/HTTPS (TCP) daemon for
serving function call requests (usually for API calls). All functions should
have L<Sub::Spec> specs.

This module uses L<Log::Any> for logging.

This module uses L<Moo> for object system.

=head1 ATTRIBUTES

=head2 name => STR

Name of server, for display in process table ('ps ax'). Default is basename of
$0.

=head2 daemonize => BOOL

Whether to daemonize (go into background). Default is true.

=head2 sock_path => STR

Location of Unix socket. Default is none, which means not listening to Unix
socket.

=head2 pid_path => STR

Location of PID file. Default is /var/run/<name>.pid.

=head2 error_log_path => STR

Location of error log. Default is /var/log/<name>-error.log. It will be opened
in append mode.

=head2 access_log_path => STR

Location of access log. Default is /var/log/<name>-access.log. It will be opened
in append mode.

=head2 access_log_max_args_len => INT

Maximum number of characters to log args (in JSON format). Default is 1024. Over
this length, only the first 1024 characters are logged.

=head2 access_log_max_resp_len => INT

Maximum number of characters to log response (in JSON format). Default is 1024.
Over this length, only the first 1024 characters are logged.

=head2 http_port => INT

Port to listen to HTTP requests. Default is 80. Undef means not listening for
HTTP requests. Note that in Unix environment, binding to ports 1024 and below
requires superuser privileges.

=head2 http_bind_host => STR

If you only want to bind to a specific interface for HTTP, specify it here, for
example 'localhost' or '1.2.3.4'. Setting to undef or '' means to bind to all
interface ('*'). Default is 'localhost'.

=head2 https_port => INT

Port to listen to HTTPS requests. Default is undef. Undef means not listening
for HTTPS requests. Note that in Unix environment, binding to ports 1024 and
below requires superuser privileges.

=head2 https_bind_host => STR

If you only want to bind to a specific interface for HTTPS, specify it here, for
example 'localhost' or '1.2.3.4'. Setting to undef or '' means to bind to all
interface ('*'). Default is 'localhost'.

=head2 ssl_key_file => STR

Path to SSL key file, to be passed to HTTP::Daemon::SSL. If you enable HTTPS,
you need to supply this.

=head2 ssl_cert_file => STR

Path to SSL cert file, to be passed to HTTP::Daemon::SSL. If you enable HTTPS,
you need to supply this.

=head2 start_servers

Number of children to fork at the start of run. Default is 3. If you set this to
0, the server becomes a nonforking one.

Tip: You can set start_servers to 0 and 'daemonize' to false for debugging.

=head2 max_requests_per_child

Number of requests each child will serve until it exists. Default is 1000.

=head2 module_prefix

Prefix for module. Default is none. Affects get_sub_name().

=head2 req

The request object, will be set at the start of each request (before
handle_request() is run). Currently this is a barebones hash, but will be a
proper object.

=head2 resp

The response, should be in the form of [HTTP_STATUS_CODE, MESSAGE, DATA].

=head1 METHODS

=for Pod::Coverage BUILD

=head2 new()

Create a new server object.

=head2 $server->stop()

Stop running server.

=head2 $server->run()

Run server.

=head2 $server->restart()

Restart server.

=head2 $server->is_running() => BOOL

Check whether server is running

=head2 $server->before_prefork()

Override this hook to do stuffs before preforking. For example, you can preload
all modules. This is more efficient than each children loading modules
separately.

The default implementation does nothing.

=head2 $server->handle_request()

The main routine to handle request, will be called by run(). Below is the order
of processing. At any time during the request, you can set $server->resp() and
die to exit early and directly go to access_log().

=over 4

=item * before_parse_http_request()

=item * parse_http_request()

=item * get_sub_name()

=item * get_sub_args()

=item * auth()

=item * get_sub_spec()

=item * authz()

=item * call_sub()

=item * send_http_response()

=item * after_send_http_response()

=item * access_log()

=back

=head2 $server->before_parse_http_request()

Override this to add action before HTTP request is parsed.

=head2 $server->parse_http_request()

Parse HTTP request (result in $server->req->{http_req}). Will be called by
handle_request().

=head2 $server->get_sub_name()

Parse sub's fully qualified name from HTTP request object. Result should be put
in $server->req->{sub_module} and $server->req->{sub_name}.

You can override this method to provide other URL syntax. The default
implementation parses URI using this syntax:

 /MODULE/SUBMODULE/FUNCTION

which will result in sub_module being 'MODULE::SUBMODULE' and sub_name
'FUNCTION'. In addition, some options are allowed:

 /MODULE/SUBMODULE/FUNCTION;OPTS

OPTS are a string of one or more option letters. 'j' means to ask server to
return response in JSON format. 'r' (the default) means return in pretty
formatted text (e.g. tables). 'R' means return in non-pretty/plain text. 'y'
means return in YAML. 'p' means return in PHP serialization format.

For example:

 /My/Module/my_func;j

If 'module_prefix' attribute is set, it will be prepended to
$server->req->{sub_module}. For example, if 'module_prefix' is 'Our::Project',
then with the above URI, the final sub_module will become
'Our::Project::My::Module'.

=head2 $server->get_sub_args()

Parse sub's args from HTTP request object. Result should be put in
$server->req->{sub_args}. It should be a hashref.

The default implementation can get args from request body in PHP serialization
format (if C<Content-Type> HTTP request header is set to
C<application/vnd.php.serialized>) or JSON (C<application/json>) or YAML
(C<text/yaml>).

Alternatively, it can get args from URL query parameters. Each query parameter
corresponds to an argument name. If you add ":j" suffix to query parameter name,
it means query parameter value is in JSON format. If ":y" suffix, YAML format.
If ":p", PHP serialization format.

You can override this method to provide other ways to parse arguments from HTTP
request.

=head2 $server->get_sub_args()

Get sub's spec. Result should be put in $server->req->{sub_spec}.

The default implementation will simply looks for the spec in %SPEC in the
package specified in $server->req->{sub_module}.

=head2 $server->auth()

Authenticate client. Override this if needed. The default implementation does
nothing. Authenticated client should be put in $server->req->{auth_user}.

=head2 $server->authz()

Authorize client. Override this if needed. The default implementation does
nothing.

=head2 $server->call_sub()

Call function specified in $server->req->{module} and $server->req->{sub}) using
arguments specified in $server->req->{args}. Set $server->resp() with the return
value of function.

=head2 $server->send_http_response()

Send HTTP response to client. Called by handle_request().

=head2 $server->after_send_http_response()

Hook to do stuffs before logging. The default implementation does nothing. You
can override this e.g. to mask some arguments from being logged or limit its
size.

=head2 $server->access_log()

Log request. The default implementation logs like this (all in one line):

 [Fri Feb 18 22:05:38 2011] "GET /v1/MyModule/my_func;j?arg1=1&arg2=2"
 [127.0.0.1:949] [-] [mod MyModule] [sub my_func]
 [args 14 {"name":"val"}] [resp 12 [200,"OK",1]] [subt 2.123ms] [reqt 5.947ms]

where subt is time spent in the subroutine, and reqt is time spent for the whole
request (from connect until response is sent, which includes reqt).

=head1 FAQ

=head1 BUGS/TODOS

I would like to use L<Plack>/L<PSGI>, but the current implementation of this
module (using L<HTTP::Daemon> + L<HTTP::Daemon::SSL>) conveniently supports
HTTPS out of the box.

=head1 SEE ALSO

L<Sub::Spec>

L<Sub::Spec::HTTP::Client>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
