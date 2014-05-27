package Catmandu::Importer::MARC::MicroLIF;
use Catmandu::Sane;
use Moo;
use MARC::File::USMARC;
use MARC::File::MicroLIF;
use MARC::File::XML (BinaryEncoding => 'UTF-8', DefaultEncoding => 'UTF-8', RecordFormat => 'MARC21');
use MARC::Record;

extends 'Catmandu::Importer::MARC::Record';

sub generator {
    my ($self) = @_;
    my $type = $self->type;
    my $file = MARC::File::MicroLIF->in($self->fh);
    sub  {
      $self->decode_marc($file->next());
    }
}


1;