package Catmandu::Fix::marc_decode_dollar_subfields;

use Moo;
use Data::Dumper;

our $VERSION = '0.217';

sub fix {
	my ($self,$data) = @_;

	my $old_record = $data->{record};
	my $new_record = [];

	for my $field (@$old_record) {
		my ($field,$ind1,$ind2,@subfields) = @$field;

		my $fixed_field = [$field,$ind1,$ind2];

		for (my $i = 0 ; $i < @subfields ; $i += 2) {
			my $code  = $subfields[$i];
			my $value = $subfields[$i+1];

			# If a subfield contains fields coded like: data$xmore$yevenmore
			# chunks = (data,x,y,evenmore)
			my @chunks = split( /\$([a-z])/, $value );

			my $real_value = shift @chunks;

			push @$fixed_field , ( $code, $real_value);

			while (@chunks) {
				push  @$fixed_field , ( splice @chunks, 0, 2 );
			}
		}

		push @$new_record , $fixed_field;
	}

	$data->{record} = $new_record;

	$data;
}

=head1 NAME

Catmandu::Fix::marc_decode_dollar_subfields - decode double encoded dollar subfields

=head1 SYNOPSIS

    marc_decode_dollar_subfields()

=head1 DESCRIPTION

In some environments MARC subfields can contain data values that can be interpreted
as subfields itself. E.g. when the 245-$a subfield contains the data:

   My Title $h subsubfield

then the $h = subsubfield will not be accessible with normal MARC processing tools.
Use the 'marc_decode_dollar_subfields()' fix to re-evaluate all the MARC subfields
for these hidden data.

=head1 USAGE

  catmandu convert MARC --type RAW --fix 'marc_decode_dollar_subfields()' < data.mrc

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;