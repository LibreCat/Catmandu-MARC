package Catmandu::Fix::marc_add;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

our $VERSION = '0.217';

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

            if ($value =~ /^\$\.(\S+)$/) {
                my $path = $1;
                $value = Catmandu::Util::data_at($path,$data);
            }

            if (is_array_ref $value) {
                for (@$value) {
                    push @field , $code;
                    push @field , $_;
                }
            }
            elsif (is_hash_ref $value) {
                for (keys %$value) {
                    push @field , $code;
                    push @field , $value->{$_};
                }
            }
            elsif (is_value($value) && length($value) > 0) {
                push @field , $code;
                push @field , $value;
            }
        }

        push @{ $marc } , \@field if @field > 3;
    }

    $data->{$record_key} = $marc;

    $data;
}

=head1 NAME

Catmandu::Fix::marc_add - add new fields to marc 

=head1 SYNOPSIS

    # Set literal values
    marc_add('900', a, 'test' , 'b', test)
    marc_add('900', ind1 , ' ' , a, 'test' , 'b', test)
    marc_add('900', ind1 , ' ' , a, 'test' , 'b', test , record:record2)

    # Copy data from an other field (when the field value is an array, the
    # subfield will be repeated)
    marc_add('900', a, '$.my.data.field')

=head1 DESCRIPTION

Read our Wiki pages at L<https://github.com/LibreCat/Catmandu/wiki/Fixes> for a complete
overview of the Fix language.

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
