=head1 NAME

Catmandu::Importer::MARC::MiJ - Package that imports MARC-in-JSON records

=head1 SYNOPSIS

    # From the command line 
    $ catmandu convert MARC --type MiJ --fix "marc_map('245a','title')" < /foo/data.js

    # From perl
    use Catmandu;

    # import records from file
    my $importer = Catmandu->importer('MARC',file => '/foo/data.js', type => 'MiJ');
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

L<MARC::File::MARCMaker>

=cut
package Catmandu::Importer::MARC::MiJ;
use Catmandu::Sane;
use Moo;
use MARC::Record;
use MARC::File::MiJ;

extends 'Catmandu::Importer::MARC::Record';

sub generator {
    my ($self) = @_;
    my $file = MARC::File::MiJ->in($self->file);
    sub  {
      $self->decode_marc($file->next());
    }
}

1;