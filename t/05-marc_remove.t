#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;

use Catmandu::Importer::MARC;
use Catmandu::Fix;

my $fixer = Catmandu::Fix->new(fixes => [q|marc_remove('245')|]);
my $importer = Catmandu::Importer::MARC->new( file => 't/camel.usmarc', type => "USMARC" );
my $record = $importer->first;

is scalar(@{$record->{record}}),
   scalar(@{$fixer->fix($record)->{record}}) + 1,
   q|marc_remove('245')|;

done_testing 1;

