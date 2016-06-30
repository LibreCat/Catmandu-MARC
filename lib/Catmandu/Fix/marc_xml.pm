package Catmandu::Fix::marc_xml;

use Catmandu::Sane;
use Moo;
use Catmandu::MARC;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

our $VERSION = '0.219';

has path  => (fix_arg => 1);

# Transform a raw MARC array into MARCXML
sub fix {
    my ($self, $data) = @_;
    my $xml = Catmandu::MARC::marc_xml($data);
    $data->{$self->path} = $xml;
    $data;
}

=head1 NAME

Catmandu::Fix::marc_xml - transform a Catmandu MARC record into MARCXML

=head1 SYNOPSIS

   # Transforms the 'record' key into a MARCXML string
   marc_xml('record')

=head1 DESCRIPTION

Convert MARC data into a MARCXML string

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
