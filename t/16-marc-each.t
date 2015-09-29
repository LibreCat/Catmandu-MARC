#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;

use Catmandu::Importer::MARC;
use Catmandu::Fix;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Bind::marc_each';
    use_ok $pkg;
}
require_ok $pkg;

my $fixer = Catmandu::Fix->new(fixes => [q|
	do marc_each()
		if marc_match("***a",'Perl')
			add_field(has_perl,true)
		end
		if marc_match("100",'.*')
			reject()
		end
	end
	marc_map("100",test)
|]);

my $importer = Catmandu::Importer::MARC->new( file => 't/camel.usmarc', type => "USMARC" );

$fixer->fix($importer)->each(sub {
	my $record = $_[0];
	my $id = $record->{_id};

	ok exists $record->{record}, "created a marc record $id";
	is $record->{has_perl}, 'true', "created has_dlc tag $id";
	ok ! exists $record->{test} , "field 300 deleted $id";
});

done_testing;