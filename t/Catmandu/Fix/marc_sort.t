#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::MARC;
use Catmandu::Fix;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::marc_sort';
    use_ok $pkg;
}

require_ok $pkg;

my $record = {
    _id    => '000000002',
    record => [
        [ '001', ' ', ' ', '_', '000000002' ],
        [ 'LDR', ' ', ' ', '_', '00209nam a2200097 i 4500' ],
        [ '022', ' ', ' ', 'a', '1940-5758' ],
        [ '245', '1', '0', 'a', 'Catmandu Test' ],
        [ '650', ' ', '0', 'a', 'RegEx' ],
        [ '008', ' ', ' ', '_', '050601s1921    xx |||||||||||||| ||dut  ' ],
        [ '650', ' ', '0', 'a', 'Perl' ]
    ]
};

my $record_sorted = {
    _id    => '000000002',
    record => [
        [ 'LDR', ' ', ' ', '_', '00209nam a2200097 i 4500' ],
        [ '001', ' ', ' ', '_', '000000002' ],
        [ '008', ' ', ' ', '_', '050601s1921    xx |||||||||||||| ||dut  ' ],
        [ '022', ' ', ' ', 'a', '1940-5758' ],
        [ '245', '1', '0', 'a', 'Catmandu Test' ],
        [ '650', ' ', '0', 'a', 'RegEx' ],
        [ '650', ' ', '0', 'a', 'Perl' ]
    ]
};

my $fixer = Catmandu::Fix->new( fixes => [q|marc_sort()|] );
$record = $fixer->fix($record);

is_deeply $record, $record_sorted, 'record sorted';

done_testing;
