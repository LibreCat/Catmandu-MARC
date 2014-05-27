package Catmandu::Importer::MARC;
use Catmandu::Sane;
use Catmandu::Util;
use Moo;

has type           => (is => 'ro' , default => sub { 'USMARC' });
has _importer      => (is => 'ro' , lazy => 1 , builder => '_build_importer' , handles => 'Catmandu::Importer');
has _importer_args => (is => 'rwp', writer => '_set_importer_args');

sub _build_importer {
    my ($self) = @_;
    my $type = $self->type;

    $type = 'Record' if exists $self->_importer_args->{records};
    
    my $pkg = Catmandu::Util::require_package($type,'Catmandu::Importer::MARC');

    $pkg->new($self->_importer_args);
}

sub BUILD {
    my ($self,$args) = @_;
    $self->_set_importer_args($args);
}

=head1 NAME

Catmandu::Importer::MARC - Package that imports MARC data

=head1 SYNOPSIS

    use Catmandu::Importer::MARC;

    # import records from file
    my $importer = Catmandu::Importer::MARC->new(file => "/foo/bar.marc", type=> "USMARC");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

    # import from array of MARC::Record objects
    my $importer = Catmandu::Importer::MARC->new(records => \@records);

    my $records = $importer->to_array;


=head1 MARC

The parsed MARC is a HASH containing two keys '_id' containing the 001 field (or the system
identifier of the record) and 'record' containing an ARRAY of ARRAYs for every field:

 {
  'record' => [
                      [
                        '001',
                        undef,
                        undef,
                        '_',
                        'fol05882032 '
                      ],
              [
                        245,
                        '1',
                        '0',
                        'a',
                        'Cross-platform Perl /',
                        'c',
                        'Eric F. Johnson.'
                      ],
          ],
  '_id' => 'fol05882032'
 }

=head1 METHODS

=head2 new(file => $filename, type => $type, $records => $records, [id=>$id_field])

Create a new MARC importer for $filename or $records. Use STDIN when no filename is given.
Type describes the sytax of the MARC records. Currently we support: USMARC, MicroLIF
, XML, ALEPHSEQ or MARC::Record.
Optionally provide an 'id' option pointing to the identifier field of the MARC record
(default 001). If the field isn't a control field, it'll default to the 'a'
subfield. A subfield can be provided like '999c'.

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. The
Catmandu::Importer::MARC methods are not idempotent: MARC feeds can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
