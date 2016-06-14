package Catmandu::Fix::Inline::marc_set;

use Clone qw(clone);
use Carp;
use Catmandu::Util qw(:is);
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(marc_set);
%EXPORT_TAGS = (all => [qw(marc_set)]);

our $VERSION = '0.218';

sub marc_set {
    my ($data,$marc_path,$value) = @_;
    my $record      = $data->{record};

    return $data unless defined $record;

    if ($value =~ /^\$\.(\S+)/) {
        my $path = $1;
        $value = Catmandu::Util::data_at($path,$data);
    }

    if (is_array_ref $value) {
        $value = $value->[-1];
    }
    elsif (is_hash_ref $value) {
        my $last;
        for (keys %$value) {
            $last = $value->{$_};
        }
        $value = $last;
    }

    my $field_regex;
    my ($field,$ind1,$ind2,$subfield_regex,$from,$to,$len);

    if ($marc_path =~ /(\S{3})(\[(.)?,?(.)?\])?([_a-z0-9])?(\/(\d+)(-(\d+))?)?/) {
        $field          = $1;
        $ind1           = $3;
        $ind2           = $4;
        if (defined $5) {
            $subfield_regex = "$5";
        }
        else {
            $subfield_regex = ($field =~ /^LDR|^00/) ? "_" : "a";
        }
        $from           = $7;
        $to             = $9;
        $len = defined $to ? $to - $from + 1 : 1;
    }
    else {
        confess "invalid marc path";
    }

    $field_regex = $field;
    $field_regex =~ s/\*/./g;

    for (@$record) {
        if ($_->[0] !~ /$field_regex/) {
            next;
        }

        if (defined $ind1) {
            if (!defined $_->[1] || $_->[1] ne $ind1) {
                next;
            }
        }
        if (defined $ind2) {
            if (!defined $_->[2] || $_->[2] ne $ind2) {
                next;
            }
        }

        my $start;

        if ($_->[0] =~ /^LDR|^00/) {
            $start = 3;
        }
        elsif (defined $_->[5] && $_->[5] eq '_') {
            $start = 5;
        }
        else {
            $start = 3;
        }

        my $found = 0;
        for (my $i = $start; $i < @$_; $i += 2) {

            if ($_->[$i] eq $subfield_regex) {
                if (defined $from) {
                    substr($_->[$i + 1], $from, $len) = $value;
                }
                else {
                    $_->[$i + 1] = $value;
                } 
                                
                $found = 1;
            }
        }
        
        if ($found == 0) {
            push(@$_,$subfield_regex,$value);
        }

    }

    $data;
}

=head1 NAME

Catmandu::Fix::Inline::marc_set - A marc_set-er for Perl scripts

=head1 SYNOPSIS

 use Catmandu::Fix::Inline::marc_set qw(:all);

 # Set to literal value
 my $data  = marc_set($data,'245[1]a', 'value');

 # Set to a copy of a deeply nested JSON path
 my $data  = marc_set($data,'245[1]a', '$.my.deep.field');

=head1 SEE ALSO

L<Catmandu::Fix::Inline::marc_add> ,
L<Catmandu::Fix::Inline::marc_remove> ,
L<Catmandu::Fix::Inline::marc_map> 

=cut

1;
