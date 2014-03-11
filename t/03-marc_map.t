#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;

use Catmandu::Importer::MARC;
use Catmandu::Fix;

my $fixer = Catmandu::Fix->new(fixes => ['t/test.fix']);
my $importer = Catmandu::Importer::MARC->new( file => 't/camel.usmarc', type => "USMARC" );
my $records = $fixer->fix($importer)->to_array;

is $records->[0]->{my}{id}, 'fol05731351 ', q|fix: marc_map('001','my.id');|;

is $records->[0]->{my}{title}, 'ActivePerl with ASP and ADO /', q|fix: marc_map('245a','my.title');|;

is_deeply
    $records->[0]->{my}{split_title},
    [['ActivePerl with ASP and ADO /', 'Tobias Martinsson.']],
    q|fix: marc_map('245','my.split.title','-split', 1);|;

# field 666 does not exist in camel.usmarc
# the '$append' fix creates $my->{'references'} hash key with empty array ref as value
ok !$records->[0]->{'my'}{'references'}, q|fix: marc_map('666', 'my.references.$append');|;

is $records->[0]->{my}{substr_id}, "057";

ok !exists $records->[0]->{my}{failed_substr_id};

ok $records->[0]->{record} =~ /marc:datafield/ , "marcxml";

done_testing 7;

