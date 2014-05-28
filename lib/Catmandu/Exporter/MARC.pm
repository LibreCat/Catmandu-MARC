=head1 NAME

Catmandu::Exporter::MARC - Exporter for MARC records

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert MARC --type USMARC to MARC --type XML < /foo/bar.mrc

    # From Perl
    use Catmandu;

    my $importer = Catmandu->importer('MARC', file => "/foo/bar.mrc" , type => 'USMARC');
    my $exporter = Catmandu->exporter('MARC', file => "marc.xml", type => "XML" );

    $exporter->add($importer);
    $exporter->commit;

=head1 METHODS

=head2 new(file => $file, type => $type)

Create a new L<Catmandu::Exporter> which serializes MARC records into a $file. 
Type describes the MARC serializer to be used. Currently we support: 

    USMARC    L<Catmandu::Exporter::MARC::USMARC>
    XML       L<Catmandu::Exporter::MARC::XML>
    MARCMaker L<Catmandu::Exporter::MARC::MARCMaker>
    MiJ       L<Catmandu::Exporter::MARC::MiJ>
    ALEPHSEQ  L<Catmandu::Exporter::MARC::ALEPHSEQ>

Read the documentation of the parser modules for extra configuration options.

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut
package Catmandu::Exporter::MARC;
use Catmandu::Sane;
use Moo;

has type           => (is => 'ro' , default => sub { 'XML' });
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
}

1;
