package Catmandu::Importer::MARC::XML;
use Catmandu::Sane;
use Moo;
use MARC::File::XML (BinaryEncoding => 'UTF-8', DefaultEncoding => 'UTF-8', RecordFormat => 'MARC21');

extends 'Catmandu::Importer::MARC::Record';

sub generator {
    my ($self) = @_;
    my $file = MARC::File::XML->in($self->fh);
    sub  {
      $self->decode_marc($file->next());
    }
}

1;