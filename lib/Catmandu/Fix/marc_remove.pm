package Catmandu::Fix::marc_remove;

use Catmandu::Sane;
use Catmandu::MARC;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

our $VERSION = '0.219';

has marc_path => (fix_arg => 1);
has record    => (fix_opt => 1);

sub fix {
    my ($self,$data) = @_;
    my $marc_path  = $self->marc_path;
    my $record_key = $self->record // 'record';
    return Catmandu::MARC::marc_remove($data, $marc_path, record => $record_key);
}

=head1 NAME

Catmandu::Fix::marc_remove - remove marc (sub)fields

=head1 SYNOPSIS

    # remove all marc 600 fields
    marc_remove('600')

    # remove the 245-a subfield
    marc_remove('245a')

    # the same with the marc fields in 'record2'
    marc_remove('600', record:record2)

=head1 DESCRIPTION

Remove (sub)fields in a MARC record

=head1 METHODS

=head2 marc_remove( MARC_PATH , [OPT1:VAL, OPT2: VAL])

Delete the (sub)fields from the MARC record as indicated by the MARC_PATH.

=head1 OPTIONS

=head2 record: STR

Specify the JSON_PATH where the MARC record can be found (default: record).

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_remove as => 'marc_remove';

    my $data = { record => [...] };

    $data = marc_remove($data,'600');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
