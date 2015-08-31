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
		if marc_match("***d",'DLC')
			add_field(has_dlc,true)
		end
		if marc_match("300",'.*')
			reject()
		end
	end
	marc_map("300",test)
|]);

my $importer = Catmandu::Importer::MARC->new( file => 't/camel.usmarc', type => "USMARC" );
my $record = $fixer->fix($importer->first);

ok exists $record->{record}, 'created a marc record';
is $record->{has_dlc}, 'true', 'created has_dlc tag';
ok ! exists $record->{test} , 'field 300 deleted';

done_testing 5;