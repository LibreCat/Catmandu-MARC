=head1 NAME

Catmandu::Importer::MARC::RAW - Package that imports ISO 2709 encoded MARC records

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert MARC --type RAW --fix "marc_map('245a','title')" < /foo/bar.mrc

    # From perl
    use Catmandu;

    # import records from file
    my $importer = Catmandu->importer('MARC',file => '/foo/bar.mrc' , type => 'RAW');
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

L<MARC::Parser::RAW>

=cut
package Catmandu::Importer::MARC::RAW;
use Catmandu::Sane;
use Moo;
use MARC::Parser::RAW;

with 'Catmandu::Importer';

has id => (is => 'ro' , default => sub { '001' });

sub generator {
    my $self = shift;
    my $parser = MARC::Parser::RAW->new($self->fh);
    sub {
    	my $record = $parser->next();

        return undef unless defined $record;

    	my $id;
    	for my $field (@$record) {
    		my ($field,$ind1,$ind2,$p,$data,@q) = @$field;
    		if ($field eq $self->id) {
    			$id = $data;
    			last;
    		}
    	}

    	+{ _id => $id , record => $record };
    };
}


1;