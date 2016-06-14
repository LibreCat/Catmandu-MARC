package Catmandu::Fix::Inline::marc_add;

use Clone qw(clone);
use Carp;
use Catmandu::Util qw(:is);
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(marc_add);
%EXPORT_TAGS = (all => [qw(marc_add)]);

our $VERSION = '0.217';

sub marc_add {
    my ($data,$marc_path,@subfields) = @_;
    my (%subfields) = @subfields;
    my $ret = defined $data ? clone($data) : { record => [] };

    $ret->{'record'} = [] unless $ret->{'record'};
    croak "invalid marc path" unless $marc_path =~ /^\w{3}$/;

    my @field = ();
    push @field , $marc_path;
    push @field , $subfields{ind1} // ' ';
    push @field , $subfields{ind2} // ' ';
    for (my $i = 0 ; $i < @subfields ; $i += 2) {
        my $code  = $subfields[$i];
        next unless length $code == 1;
        my $value = $subfields[$i+1];

        if ($value =~ /^\$\.(\S+)/) {
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

    push @{ $ret->{record} } , \@field;

    return $ret;
}

=head1 NAME

Catmandu::Fix::Inline::marc_add- A marc_add-er for Perl scripts

=head1 SYNOPSIS

 use Catmandu::Fix::Inline::marc_add qw(:all);

 # Set to a literal value
 my $data  = marc_add($data, '245',  a => 'value');

 # Set to a copy of a deeply nested JSON path
 my $data  = marc_add($data, '245',  a => '$.my.deep.field');

=head1 SEE ALSO

L<Catmandu::Fix::Inline::marc_set> , 
L<Catmandu::Fix::Inline::marc_map> , 
L<Catmandu::Fix::Inline::marc_remove> 

=cut

1;