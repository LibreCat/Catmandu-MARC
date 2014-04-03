package Catmandu::Fix::Inline::marc_remove;

use Clone qw(clone);
use Carp;
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(marc_remove);
%EXPORT_TAGS = (all => [qw(marc_remove)]);

sub marc_remove {
    my ($data,$marc_path) = @_;
    my $ret = defined $data ? clone($data) : { record => [] };

    $ret->{'record'} = [] unless $ret->{'record'};
    croak "invalid marc path" unless $marc_path =~ /^\w{3}$/;

    my @fields = ();
    for my $field (@{$ret->{record}}) {
    	unless ($field->[0] eq $marc_path) {
    		push @fields , $field;
    	}
    }

    $ret->{record} = \@fields;

    return $ret;
}

=head1 NAME

Catmandu::Fix::Inline::marc_remove - remove marc fields

=head1 SYNOPSIS

 use Catmandu::Fix::Inline::marc_remove qw(:all);

 my $data  = marc_remove($data,'CAT');

=head1 SEE ALSO

L<Catmandu::Fix::Inline::marc_map> , L<Catmandu::Fix::Inline::marc_add> 

=cut

1;