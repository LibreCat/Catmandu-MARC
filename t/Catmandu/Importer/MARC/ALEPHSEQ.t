#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::MARC;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Importer::MARC::ALEPHSEQ';
    use_ok $pkg;
}

require_ok $pkg;

my $importer = Catmandu::Importer::MARC->new( file => 't/rug01.aleph', type => "ALEPHSEQ" );

ok $importer , 'got an MARC/ALEPHSEQ importer';

my @records;

my $n = $importer->each(
    sub {
        push( @records, $_[0] );
    }
);

ok(@records == 1);

ok($records[0]->{record}->[1]->[0] eq 'LDR');

ok($records[0]->{record}->[1]->[-1] !~ /\^/);

done_testing;
