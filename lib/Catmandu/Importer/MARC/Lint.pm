=head1 NAME

Catmandu::Importer::MARC::Lint - Package that imports USMARC records validated with MARC::Lint

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert MARC --type Lint --fix "marc_map('245a','title')" < /foo/data.mrc

    # From perl
    use Catmandu;

    # import records from file
    my $importer = Catmandu->importer('MARC',file => '/foo/data.mrc', type => 'Lint');
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

All items produced with the Catmandu::Importer::MARC::Lint importer contain three keys:

     '_id'    : the system identifier of the record (usually the 001 field) 
     'record' : an ARRAY of ARRAYs containing the record data
     'lint'   : the output of MARC::Lint's check_record on the MARC record

=head1 METHODS

=head2 new(file => $file , fh => $fh , id => $field)

Parse a file or a filehandle into a L<Catmandu::Iterable>. Optionally provide an
id attribute specifying the source of the system identifer '_id' field (e.g. '001').

=head1 INHERTED METHODS

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. 

=head1 SEE ALSO

L<MARC::File::USMARC>,
L<MARC::File::Lint>,

=cut
package Catmandu::Importer::MARC::Lint;
use Catmandu::Sane;
use Moo;
use MARC::File::USMARC;
use MARC::Lint;

extends 'Catmandu::Importer::MARC::Record';

sub generator {
    my ($self) = @_;
    my $lint = MARC::Lint->new;
    my $file = MARC::File::USMARC->in($self->fh);
    sub  {
       my $marc = $file->next();
       my $doc  = $self->decode_marc($marc);
       $lint->check_record( $marc );
       $doc->{lint} = [$lint->warnings];
       $doc;
    }
}

1;