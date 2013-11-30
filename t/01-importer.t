#!/usr/bin/perl

use strict;
use warnings;

use Catmandu::Importer::MARC;
use MARC::File::USMARC;
use Test::Simple tests => 8;

my $importer = Catmandu::Importer::MARC->new(
    file => 't/camel.usmarc',
    type => "USMARC"
);
my $records = $importer->to_array();

ok( scalar keys $records == 10,                           'got all records' );
ok( $records->[0]->{'_id'} eq 'fol05731351 ',             'got _id' );
ok( $records->[0]->{'record'}->[1][-1] eq 'fol05731351 ', 'got subfield' );
ok( $records->[0]->{'_id'} eq $records->[0]->{'record'}->[1][-1],
    '_id matches record id' );

my $file = MARC::File::USMARC->in('t/camel.usmarc');
my @marc_objects;
while ( my $marc = $file->next() ) {
    push( @marc_objects, $marc );
}
$file->close();
undef $file;
$importer = Catmandu::Importer::MARC->new( records => \@marc_objects );
$records = $importer->to_array();

ok( scalar keys $records == 10,                           'got all records' );
ok( $records->[0]->{'_id'} eq 'fol05731351 ',             'got _id' );
ok( $records->[0]->{'record'}->[1][-1] eq 'fol05731351 ', 'got subfield' );
ok( $records->[0]->{'_id'} eq $records->[0]->{'record'}->[1][-1],
    '_id matches record id' );
