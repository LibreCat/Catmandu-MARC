package Catmandu::Fix::Inline::marc_add;

use Clone qw(clone);
use Carp;
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(marc_add);
%EXPORT_TAGS = (all => [qw(marc_add)]);

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
        push @field , $code;
        push @field , $value;
    }

    push @{ $ret->{record} } , \@field;

    return $ret;
}

=head1 NAME

Catmandu::Fix::Inline::marc_map - A marc_map-er for Perl scripts

=head1 SYNOPSIS

 use Catmandu::Fix::Inline::marc_add qw(:all);

 my $data  = marc_add($data,'245',  a => 'value' );

=head1 SEE ALSO

L<Catmandu::Fix::Inline::marc_map> , L<Catmandu::Fix::Inline::marc_remove> 

=cut

1;