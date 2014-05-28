package Catmandu::Fix::marc_xml;

use Catmandu::Sane;
use Moo;
use IO::String;
use Catmandu::Exporter::MARC::XML;
use Catmandu::Util qw(:is :data);
use Catmandu::Fix::Has;

has path  => (fix_arg => 1);

# Transform a raw MARC array into MARCXML
sub fix {
    my ($self, $data) = @_;
    my $path    = $self->path;

    my $xml;
    my $exporter = Catmandu::Exporter::MARC::XML->new(file => \$xml , xml_declaration => 0 , collection => 0);
    $exporter->add($data);
    $exporter->commit;

    $data->{$path} = $xml;

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
