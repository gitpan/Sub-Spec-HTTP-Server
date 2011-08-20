package Plack::Util::SubSpec;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(errpage);

our $VERSION = '0.06'; # VERSION

sub errpage {
    my ($msg, $code) = @_;
    $msg .= "\n" unless $msg =~ /\n\z/;
    [$code // 400,
     ["Content-Type" => "text/plain", "Content-Length" => length($msg)],
     [$msg]];
}

1;

__END__
=pod

=head1 NAME

Plack::Util::SubSpec

=head1 VERSION

version 0.06

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

