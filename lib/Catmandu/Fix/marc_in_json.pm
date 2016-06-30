package Catmandu::Fix::marc_in_json;

use Catmandu::Sane;
use Catmandu::MARC;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

our $VERSION = '0.219';

has record  => (fix_opt => 1);
has reverse => (fix_opt => 1);

# Transform a raw MARC array into MARC-in-JSON
# See Ross Singer work at:
#  http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/
sub fix {
    my ($self, $data) = @_;
    my $record_key = $self->record // 'record';

    if ($self->reverse) {
        return Catmandu::MARC::marc_json_to_record($data, record => $record_key);
    }
    else {
        return Catmandu::MARC::marc_record_to_json($data, record => $record_key);
    }
}

=head1 NAME

Catmandu::Fix::marc_in_json - transform a Catmandu MARC record into MARC-in-JSON

=head1 SYNOPSIS

   # Transform a Catmandu MARC 'record' into a MARC-in-JSON record
   marc_in_json()

   # Optionally provide a pointer to the marc record
   marc_in_json(record:record)

   # Reverse, transform a MARC-in-JSON record into a Catmandu MARC record
   marc_in_json(reverse:1)

=head1 DESCRIPTION

Convert the MARC record into MARC-in-JSON format

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
