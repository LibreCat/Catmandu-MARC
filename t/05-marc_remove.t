#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;

use Catmandu::Importer::MARC;
use Catmandu::Fix;
use Catmandu::Fix::Inline::marc_map qw(:all);

my $fixer = Catmandu::Fix->new(fixes => [q|marc_remove('245')|,q|marc_remove('100a')|]);
my $importer = Catmandu::Importer::MARC->new( file => 't/camel.usmarc', type => "USMARC" );
my $record = $importer->first;

my $title  = marc_map($record,'245');
my $author = marc_map($record,'100');

ok  $title, 'got a title';
like $author , qr/^Martinsson, Tobias,1976-$/ , 'got an author';

my $fixed_record = $fixer->fix($record);

my $title2  = marc_map($fixed_record,'245');
my $author2 = marc_map($fixed_record,'100');

ok (!defined $title2, 'deleted the title');

like $author2 , qr/^1976-$/ , 'removed 100-a';

done_testing 4;

