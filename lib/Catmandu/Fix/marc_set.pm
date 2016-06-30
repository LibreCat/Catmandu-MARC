package Catmandu::Fix::marc_set;

use Catmandu::Sane;
use Moo;
use Catmandu::MARC;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

our $VERSION = '0.219';

has marc_path      => (fix_arg => 1);
has value          => (fix_arg => 1);
has record         => (fix_opt => 1);

sub fix {
    my ($self,$data) = @_;
    my $marc_path   = $self->marc_path;
    my $value       = $self->value;
    my $record_key  = $self->record;
    return Catmandu::MARC::marc_set($data,$marc_path,$value, record => $record_key);
}

=head1 NAME

Catmandu::Fix::marc_set - set a marc value of one (sub)field to a new value

=head1 SYNOPSIS

    # Set a field in the leader
    if marc_match('LDR/6','c')
        marc_set('LDR/6','p')
    end

    # Set all the 650-p fields to 'test'
    marc_set('650p','test')

    # Set the 100-a subfield where indicator-1 is 3
    marc_set('100[3]a','Farquhar family.')

    # Copy data from another field in a subfield
    marc_set('100a','$.my.deep.field')

=head1 DESCRIPTION

Set the value of a MARC subfield to a new value.

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
