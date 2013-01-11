#!/usr/bin/perl

use utf8;
use v5.12; 
use strict;
use warnings;
use warnings  qw(FATAL utf8); 
use open      qw(:std :utf8);
use charnames qw(:full :short); 

use Data::Dumper;
use Catmandu::Importer::MARC;
use Catmandu::Fix;
use Test::Simple tests => 3;

my $fixer = Catmandu::Fix->new(fixes => ['t/append.fix']);
my $importer = Catmandu::Importer::MARC->new( file => 't/camel.usmarc', type => "USMARC" );
my $records = $fixer->fix($importer)->to_array();

ok( $records->[0]->{'my'}->{'id'} eq 'fol05731351 ', 'fix: marc_map(\'001\',\'my.id\');' );
ok( $records->[0]->{'my'}->{'title'} eq 'ActivePerl with ASP and ADO /', 'fix: marc_map(\'245a\',\'my.title\');' );

# field 666 does not exist in camel.usmarc
# the '$append' fix creates $my->{'references'} hash key with empty array ref as value
ok( !$records->[0]->{'my'}->{'references'}, 'fix: marc_map(\'666\', \'my.references.$append\');' );
