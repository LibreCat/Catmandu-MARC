package Catmandu::Importer::MARC::USMARC;
use Catmandu::Sane;
use Moo;
use MARC::File::USMARC;

extends 'Catmandu::Importer::MARC::Record';

sub generator {
    my ($self) = @_;
    my $file = MARC::File::USMARC->in($self->fh);
    sub  {
      $self->decode_marc($file->next());
    }
}

1;