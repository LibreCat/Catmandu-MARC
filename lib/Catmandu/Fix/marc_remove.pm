package Catmandu::Fix::marc_remove;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

has marc_tag => (fix_arg => 1);
has record   => (fix_opt => 1);

sub fix {
    my ($self, $data) = @_;
    my $marc_tag   = $self->marc_tag;
    my $record_tag = $self->record // 'record';

    if (my $marc = $data->{$record_tag}) {
        for (my $i = @$marc - 1; $i >= 0; $i--) {
            if ($marc->[$i][0] eq $marc_tag) {
                splice @$marc, $i, 1;
            }
        }
    }

    $data;
}

=head1 NAME

Catmandu::Fix::marc_remove - remove marc fields

=head1 SYNOPSIS

    # remove all marc 600 fields
    marc_remove('600')

    # the same with the marc fields in 'record2'
    marc_remove('600', '-record', 'record2')

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
