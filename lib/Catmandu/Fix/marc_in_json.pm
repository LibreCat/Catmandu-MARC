package Catmandu::Fix::marc_in_json;

use Catmandu::Sane;
use Moo;

has opts => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, %opts) = @_;
    $opts{-record} ||= 'record';
    $orig->($class, opts => \%opts);
};

# Transform a raw MARC array into MARC-in-JSON
# See Ross Singer work at:
#  http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/
sub fix {
    my ($self, $data) = @_;

    my $marc_pointer = $self->opts->{-record};

    if (my $marc = delete $data->{$marc_pointer}) {
        for my $field (@$marc) {
            my ($tag, $ind1, $ind2, @data) = @$field;

            if ($tag eq 'LDR') {
               $data->{leader} = join "", @data;
            }
            elsif ($tag eq 'FMT' || substr($tag, 0, 2) eq '00') {
               shift @data;
               push @{$data->{fields} ||= []} , { $tag => join "" , @data };
            }
            else {
               my @subfields;
               for (my $i = 2; $i < @data; $i += 2) {
                   push @subfields, { $data[$i] => $data[$i+1] };
               }
               push @{$data->{fields} ||= []} , { $tag => {
                   subfields => \@subfields,
                   ind1 => $ind1,
                   ind2 => $ind2 } };
            }
        }
    }

    $data;
}

=head1 NAME

Catmandu::Fix::marc_in_json - transform a Catmandu MARC record into MARC-in-JSON

=head1 SYNOPSIS

   # Create a deeply nested key
   marc_in_json();

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
