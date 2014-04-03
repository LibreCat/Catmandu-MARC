use strict;
use warnings;

use Test::More tests => 8;

use Catmandu::Fix::Inline::marc_map qw(marc_map);
use Catmandu::Fix::Inline::marc_add qw(marc_add);
use Catmandu::Fix::Inline::marc_remove qw(marc_remove);
use Catmandu::Importer::JSON;
use Data::Dumper;

my $importer = Catmandu::Importer::JSON->new( file => 't/old_new.json' );
my $records = $importer->to_array;

ok(@$records == 2 , "Found 2 records");

is scalar marc_map($records->[0],'245a'), q|ActivePerl with ASP and ADO /|, q|marc_map(245a)|;
is scalar marc_map($records->[0],'001') , q|fol05731351 | , q|marc_map(001)|;
ok ! defined(scalar marc_map($records->[0],'191')) , q|marc_map(191) not defined|;
ok ! defined(scalar marc_map($records->[0],'245x')) , q|marc_map(245x) not defined|;

my @res = marc_map($records->[0],'630');
ok(@res == 2 , q|marc_map(630)|);

my $rec = marc_add($records->[0],'900', a => 'test');
is scalar marc_map($rec,'900a'), q|test|, q|marc_add(900)|;

my $rec2 = marc_remove($records->[0],'900');
ok ! defined scalar marc_map($rec2,'900a') , q|marc_map(900) removed|;