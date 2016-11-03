=head1 NAME

Catmandu::Exporter::MARC - Exporter for MARC records

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert MARC --type ISO to MARC --type XML < /foo/bar.mrc

    # From Perl
    use Catmandu;

    my $importer = Catmandu->importer('MARC', file => "/foo/bar.mrc" , type => 'ISO');
    my $exporter = Catmandu->exporter('MARC', file => "marc.xml", type => "XML" );

    $exporter->add($importer);
    $exporter->commit;

=head1 DESCRIPTION

Catmandu::Exporter::MARC is a L<Catmandu::Exporter> to serialize (write) MARC records
to a file or the standard output.

=head1 CONFIGURATION

=over

=item type

Create a new MARC exporter of the given type. Currently we support:

=over

=item * USMARC: alias for ISO, B<deprecated, will be removed in future version>

=item * ISO: L<Catmandu::Importer::MARC::ISO>

=item * XML: L<Catmandu::Exporter::MARC::XML>

=item * MARCMaker: L<Catmandu::Exporter::MARC::MARCMaker>

=item * MiJ: L<Catmandu::Exporter::MARC::MiJ> (Marc in Json)

=item * ALEPHSEQ: L<Catmandu::Exporter::MARC::ALEPHSEQ>

=back

=item file

Write output to a local file given by its path or file handle.  Alternatively a
scalar reference can be passed to write to a string and a code reference can be
used to write to a callback function.

=item fh

Write the output to an L<IO::Handle>. If not specified,
L<Catmandu::Util::io|Catmandu::Util/IO-functions> is used to create the output
handle from the C<file> argument or by using STDOUT.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to exported items.

=item encoding

Binmode of the output stream C<fh>. Set to "C<:utf8>" by default.

=back

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut
package Catmandu::Exporter::MARC;
use Catmandu::Sane;
use Moo;

our $VERSION = '1.03';

has type           => (is => 'ro' , default => sub { 'ISO' });
has _exporter      => (is => 'ro' , lazy => 1 , builder => '_build_exporter' , handles => 'Catmandu::Exporter');
has _exporter_args => (is => 'rwp', writer => '_set_exporter_args');

sub _build_exporter {
    my ($self) = @_;

    my $type = $self->type;

    my $pkg = Catmandu::Util::require_package($type,'Catmandu::Exporter::MARC');

    $pkg->new($self->_exporter_args);
}

sub BUILD {
    my ($self,$args) = @_;
    $self->_set_exporter_args($args);

    # keep USMARC temporary as alias for ISO, remove in future version
    # print deprecation warning
    if ($self->{type} eq 'USMARC') {
        $self->{type} = 'ISO';
        warn( "deprecated", "Oops! Exporter \"USMARC\" is deprecated. Use \"ISO\" instead." );
    }
}

1;
