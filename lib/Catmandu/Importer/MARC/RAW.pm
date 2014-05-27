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