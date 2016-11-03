=head1 NAME

Catmandu::Importer::MARC - Package that imports MARC data

=head1 SYNOPSIS

    # From the command line convert MARC to JSON mapping 245a to a title
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

=head1 CONFIGURATION

=over

=item type

Create a new MARC importer of the given type. Currently we support:

=over

=item * USMARC: alias for ISO, B<deprecated, will be removed in future version>

=item * ISO: L<Catmandu::Importer::MARC::ISO>

=item * MicroLIF: L<Catmandu::Importer::MARC::MicroLIF>

=item * MARCMaker: L<Catmandu::Importer::MARC::MARCMaker>

=item * MiJ: L<Catmandu::Importer::MARC::MiJ>

=item * XML: L<Catmandu::Importer::MARC::XML>

=item * RAW: L<Catmandu::Importer::MARC::RAW>

=item * Lint: L<Catmandu::Importer::MARC::Lint>

=item * ALEPHSEQ: L<Catmandu::Importer::MARC::ALEPHSEQ>

=back

=item file

Read input from a local file given by its path. Alternatively a scalar
reference can be passed to read from a string.

=item fh

Read input from an L<IO::Handle>. If not specified, L<Catmandu::Util::io> is used to
create the input stream from the C<file> argument or by using STDIN.

=item encoding

Binmode of the input stream C<fh>. Set to C<:utf8> by default.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to imported items.

=back

=head1 METHODS

Every L<Catmandu::Importer> is a L<Catmandu::Iterable> all its methods are inherited.

=head1 SEE ALSO

L<Catmandu::Importer>,
L<Catmandu::Iterable>

=cut
package Catmandu::Importer::MARC;
use Catmandu::Sane;
use Catmandu::Util;
use Moo;

our $VERSION = '1.03';

has type           => (is => 'ro' , default => sub { 'ISO' });
has _importer      => (is => 'ro' , lazy => 1 , builder => '_build_importer' , handles => ['generator']);
has _importer_args => (is => 'rwp', writer => '_set_importer_args');

with 'Catmandu::Importer';

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

    # keep USMARC temporary as alias for ISO, remove in future version
    # print deprecation warning
    if ($self->{type} eq 'USMARC') {
        $self->{type} = 'ISO';
        warn( "deprecated", "Oops! Importer \"USMARC\" is deprecated. Use \"ISO\" instead." );
    }
}


1;
