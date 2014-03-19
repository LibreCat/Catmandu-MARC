#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;

use Catmandu::Importer::MARC;
use Catmandu::Fix;

my $fixer = Catmandu::Fix->new(fixes => [q|marc_add('999', ind1 => 4 , ind2 => 1 , a => 'test')|]);
my $record = $fixer->fix({});

ok exists $record->{record}, 'created a marc record';
is $record->{record}->[0]->[0] , '999', 'created 999 tag';
is $record->{record}->[0]->[1] , '4', 'created 999 ind1';
is $record->{record}->[0]->[2] , '1', 'created 999 ind2';
is $record->{record}->[0]->[3] , 'a', 'created 999 subfield a';
is $record->{record}->[0]->[4] , 'test', 'created 999 subfield a value';

done_testing 6;

