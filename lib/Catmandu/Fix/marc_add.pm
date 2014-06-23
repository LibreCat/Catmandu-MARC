package Catmandu::Fix::marc_add;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

has marc_tag    => (fix_arg => 1);
has subfields   => (fix_arg => 'collect');

sub fix {
    my ($self, $data) = @_;
    my $marc_tag   = $self->marc_tag;

    my @subfields  = @{$self->subfields};
    my %subfields  = @subfields;
    my $record_key = $subfields{'-record'} // 'record';
    my $marc       = $data->{$record_key} // [];

    if ($marc_tag =~ /^\w{3}$/) {
        my @field = ();
        push @field , $marc_tag;
        push @field , $subfields{ind1} // ' ';
        push @field , $subfields{ind2} // ' ';
        for (my $i = 0 ; $i < @subfields ; $i += 2) {
            my $code  = $subfields[$i];
            next unless length $code == 1;
            my $value = $subfields[$i+1];
            push @field , $code;
            push @field , $value;
        }

        push @{ $marc } , \@field;

        $data->{$record_key} = $marc;
    }

    $data;
}

=head1 NAME

Catmandu::Fix::marc_add - add new fields to marc 

=head1 SYNOPSIS

    marc_add('900', a, 'test' , 'b', test)
    marc_add('900', ind1 , ' ' , a, 'test' , 'b', test)
    marc_add('900', ind1 , ' ' , a, 'test' , 'b', test , -record => 'record2')

=head1 DESCRIPTION

Read our Wiki pages at L<https://github.com/LibreCat/Catmandu/wiki/Fixes> for a complete
overview of the Fix language.

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
