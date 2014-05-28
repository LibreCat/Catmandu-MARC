=head1 NAME

Catmandu::Exporter::MARC::MARCMaker - Exporter for MARC records to USMARC

=head1 SYNOPSIS

    # From the command line 
    $ catmandu convert MARC --type XML to MARC --type MARCMaker < /foo/data.mrc

    # From Perl
    use Catmandu;

    my $importer = Catmandu->importer('MARC', file => "/foo/bar.mrc" , type => 'XML');
    my $exporter = Catmandu->exporter('MARC', file => "marc.xml", type => 'MARCMaker' );

    $exporter->add($importer);
    $exporter->commit;

=head1 METHODS

=head2 new(file => $file , %opts)

Create a new L<Catmandu::Exporter> to serialize MARC record into MARCMaker. Provide the path
of a $file to write exported records to. Optionally the following paramters can be
specified:

	record : the key containing the marc record (default: 'record')
	record_format : optionally set to 'MARC-in-JSON' when the input format is in MARC-in-JSON

=head1 INHERTED METHODS

=head2 count

=head2 add($hashref)

=head2 add_many($array)

=head2 add_many($iterator)

=head2 add_many(sub {})

=head2 ...

All the L<Catmandu::Exporter> methods are inherited.

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut
package Catmandu::Exporter::MARC::MARCMaker;
use Catmandu::Sane;
use Catmandu::Util qw(xml_escape is_different :array :is);
use Moo;
use MARC::Record;
use MARC::Field;
use MARC::File::MARCMaker;

with 'Catmandu::Exporter', 'Catmandu::Exporter::MARC::Base';

has record               => (is => 'ro' , default => sub { 'record'});
has record_format        => (is => 'ro' , default => sub { 'raw'} );

sub add {
	my ($self, $data) = @_;

    if ($self->record_format eq 'MARC-in-JSON') { 
        $data = $self->_json_to_raw($data);
    }

	my $marc = $self->_raw_to_marc_record($data->{$self->record});

	$self->fh->print(MARC::File::MARCMaker::encode($marc));
}

sub commit {
	my ($self) = @_;
	$self->fh->flush;
}

1;