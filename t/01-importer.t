#!/usr/bin/perl

use strict;
use warnings;

use Catmandu::Importer::MARC;
use Test::Simple tests => 3;

my $importer = Catmandu::Importer::MARC->new( file => 't/camel.usmarc', type => "USMARC" );

my @records;

my $n = $importer->each(
    sub {
        push( @records, $_[0] );
    }
);

ok( $records[0]->{'_id'} eq 'fol05731351 ', 'importer: $hashref->{\'_id\'}' );
ok( $records[0]->{'record'}->[1][-1] eq 'fol05731351 ',
    'importer: $hashref->{\'record\'}->[1][-1]'
);
ok( $records[0]->{'_id'} eq $records[0]->{'record'}->[1][-1],
    'importer: $hashref->{\'_id\'} eq $hashref->{\'record\'}->[1][-1]'
);
