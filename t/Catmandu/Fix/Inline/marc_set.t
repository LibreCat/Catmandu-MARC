#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Inline::marc_set';
    use_ok $pkg;
}

require_ok $pkg;

done_testing;
