package Catmandu::Fix::marc_remove;

use Catmandu::Sane;
use Moo;

has marc_tag => (is => 'ro', required => 1);
has record_key => (is => 'ro', default => sub { "record" });

around BUILDARGS => sub {
    my ($orig, $class, $marc_tag, %opts) = @_;
    my $attrs = { marc_tag => $marc_tag };
    $attrs->{record_key} = $opts{-record} if defined $opts{-record};
    $orig->($class, $attrs);
};

sub fix {
    my ($self, $data) = @_;
    my $marc_tag = $self->marc_tag;

    if (my $marc = $data->{$self->record_key}) {
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
    marc_remove('600');

    # the same with the marc fields in 'record2'
    marc_remove('600', '-record', 'record2');

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
