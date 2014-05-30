#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;

use Catmandu::Importer::MARC;
use Catmandu::Fix;

my $fixer = Catmandu::Fix->new(fixes => [q|marc_set('LDR/0-3','XXX')|,q|marc_map('LDR','leader')|]);
my $importer = Catmandu::Importer::MARC->new( file => 't/camel.usmarc', type => "USMARC" );
my $record = $fixer->fix($importer->first);

like $record->{leader}, qr/^XXX/, q|fix: marc_set('LDR/0-3','XXX');|;

#---

$fixer = Catmandu::Fix->new(fixes => [q|marc_set('100x','XXX')|,q|marc_map('100x','test')|]);
$importer = Catmandu::Importer::MARC->new( file => 't/camel.usmarc', type => "USMARC" );
$record = $fixer->fix($importer->first);

like $record->{test}, qr/^XXX$/, q|fix: marc_set('100x','XXX');|;

#---

$fixer = Catmandu::Fix->new(fixes => [q|marc_set('100[3]a','XXX')|,q|marc_map('100a','test')|]);
$importer = Catmandu::Importer::MARC->new( file => 't/camel.usmarc', type => "USMARC" );
$record = $fixer->fix($importer->first);

like $record->{test}, qr/^Martinsson, Tobias,$/, q|fix: marc_set('100[3]a','XXX');|;

done_testing 3;
