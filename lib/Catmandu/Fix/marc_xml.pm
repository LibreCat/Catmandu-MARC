package Catmandu::Fix::marc_xml;

use Catmandu::Sane;
use Moo;
use Catmandu::Exporter::MARC;
use Catmandu::Util qw(:is :data);
use Catmandu::Fix::Has;

has path  => (fix_arg => 1);

# Transform a raw MARC array into MARCXML
sub fix {
    my ($self, $data) = @_;
    my $path    = $self->path;

    $data->{$path} = Catmandu::Exporter::MARC->marc_raw_to_marc_xml($data->{$path});

    $data;
}

=head1 NAME

Catmandu::Fix::marc_xml - transform a Catmandu MARC record into MARCXML

=head1 SYNOPSIS
   
   # Transforms the 'record' key into an MARCXML string
   marc_xml('record')

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
