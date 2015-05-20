package Catmandu::Fix::marc_in_json;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Moo;
use Catmandu::Fix::Has;

has record  => (fix_opt => 1);
has reverse => (fix_opt => 1);

# Transform a raw MARC array into MARC-in-JSON
# See Ross Singer work at:
#  http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/
sub fix {
    my ($self, $data) = @_;

    $self->reverse ?  $self->_json_record($data) :  $self->_record_json($data);
}

sub _json_record {
    my ($self, $data) = @_;
    my $marc_pointer = $self->record // 'record';

    my $record = [];

    if (is_string($data->{leader})) {
        push @$record , [ 'LDR', undef, undef, '_', $data->{leader} ],
    }

    if (is_array_ref($data->{fields})) {
        for my $field (@{$data->{fields}}) {
            next unless is_hash_ref($field);

            my ($tag) = keys %$field;
            my $val   = $field->{$tag}; 

            if ($tag eq 'FMT' || substr($tag, 0, 2) eq '00') {
               push @$record , [ $tag, undef, undef, '_', $val ],
            }
            elsif (is_hash_ref($val)) {
               my $ind1 = $val->{ind1};
               my $ind2 = $val->{ind2};
               next unless is_array_ref($val->{subfields});

               my $sfs = [ '_' , ''];
               for my $sf (@{ $val->{subfields} }) {
                   next unless is_hash_ref($sf);

                   my ($code) = keys %$sf;
                   my $sval   = $sf->{$code};

                   push @$sfs , [ $code , $sval];
               }

               push @$record , [ $tag , $ind1 , $ind2 , @$sfs];
            }
        }
    }

    if (@$record > 0) {
      delete $data->{fields};
      delete $data->{leader};
      $data->{$marc_pointer} = $record;
    }

    $data;
}

sub _record_json {
    my ($self, $data) = @_;
    my $marc_pointer = $self->record // 'record';

    if (my $marc = delete $data->{$marc_pointer}) {
        for my $field (@$marc) {
            my ($tag, $ind1, $ind2, @subfields) = @$field;

            if ($tag eq 'LDR') {
               shift @subfields;
               $data->{leader} = join "", @subfields;
            }
            elsif ($tag eq 'FMT' || substr($tag, 0, 2) eq '00') {
               shift @subfields;
               push @{$data->{fields} ||= []} , { $tag => join "" , @subfields };
            }
            else {
               my @sf;
               my $start = !defined($subfields[0]) || $subfields[0] eq '_' ? 2 : 0;
               for (my $i = $start; $i < @subfields; $i += 2) {
                   push @sf, { $subfields[$i] => $subfields[$i+1] };
               }
               push @{$data->{fields} ||= []} , { $tag => {
                   subfields => \@sf,
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

   # Transform a Catmandu MARC 'record' into a MARC-in-JSON record
   marc_in_json()

   # Optionally provide a pointer to the marc record
   marc_in_json(-record => 'record')

   # Reverse, transform a MARC-in-JSON record into a Catmandu MARC record
   marc_in_json(-reverse => 1)

=head1 DESCRIPTION

Read our Wiki pages at L<https://github.com/LibreCat/Catmandu/wiki/Fixes> for a complete
overview of the Fix language.

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
