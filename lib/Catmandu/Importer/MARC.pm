=head1 NAME

Catmandu::Importer::MARC - Package that imports MARC data

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert MARC --fix "marc_map('245a','title')" < /foo/bar.mrc

    # From Perl
    use Catmandu;

    # import records from file
    my $importer = Catmandu->importer('MARC',file => '/foo/bar.mrc');
    my $fixer    = Catmandu->fixer("marc_map('245a','title')");

    $importer->each(sub {
        my $item = shift;
        ...
    });

    # or using the fixer

    $fixer->fix($importer)->each(sub {
        my $item = shift;
        printf "title: %s\n" , $item->{title};
    });


=head1 DESCRIPTION

Catmandu::Importer::MARC is a L<Catmandu::Iterable> to import MARC records from an
external source. When given an input file an Catmandu::Iterable is create generating 
items as perl HASH-es containing two keys:

     '_id'    : the system identifier of the record (usually the 001 field) 
     'record' : an ARRAY of ARRAYs containing the record data

Read more about processing data with Catmandu on the wiki: L<https://github.com/LibreCat/Catmandu/wiki>

=head1 EXAMPLE ITEM

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
                        '245',
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

=head2 new(file => $filename, type => $type)

Create a new MARC importer for $filename or $records. Use STDIN when no filename is given.
Type describes the MARC parser to be used. Currently we support: 
        
    USMARC    L<Catmandu::Importer::MARC::USMARC>
    MicroLIF  L<Catmandu::Importer::MARC::MicroLIF>
    MARCMaker L<Catmandu::Importer::MARC::MARCMaker>
    JSON      L<Catmandu::Importer::MARC::MiJ>
    XML       L<Catmandu::Importer::MARC::XML>
    RAW       L<Catmandu::Importer::MARC::RAW>
    Lint      L<Catmandu::Importer::MARC::Lint>
    ALEPHSEQ  L<Catmandu::Importer::MARC::ALEPHSEQ>

Read the documentation of the parser modules for extra configuration options.

=head1 INHERTED METHODS

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. 

=head1 WARNING

The Catmandu::Importer::MARC methods are not idempotent: MARC feeds can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>, 
L<Catmandu::Fix::marc_map> , 
L<Catmandu::Fix::marc_xml>

=cut
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

1;
