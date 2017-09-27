#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Exporter::MARC;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Exporter::MARC::ALEPHSEQ';
    use_ok $pkg;
}

require_ok $pkg;

my $xml = undef;

my $exporter = Catmandu::Exporter::MARC->new(file => \$xml, type=> 'ALEPHSEQ' , skip_empty_subfields => 1);

ok $exporter , 'got an MARC/ALEPHSEQ exporter';

ok $exporter->add({
  _id => '1' ,
  record => [
            ['001', undef, undef, '_', 'rec001'],
            ['100', ' ', ' ', 'a', 'Davis, Miles' , 'c' , 'Test'],
            ['245', ' ', ' ',
                'a', 'Sketches in Blue' ,
            ],
            ['500', ' ', ' ', 'a', undef],
            ['501', ' ', ' ' ],
            ['502', ' ', ' ', 'a', undef, 'b' , 'ok'],
            ['503'. ' ', ' ', 'a', ''],
        ]
});

ok $exporter->commit;

ok($xml =~ /^000000001/, 'test id');
ok($xml =~ /000000001 100   L \$\$aDavis, Miles\$\$cTest/, 'test subfields');
ok($xml !~ /000000001 500/, 'test skip empty subfields');

$xml = '';
$exporter = Catmandu::Exporter::MARC->new(
                  file => \$xml,
                  type=> 'ALEPHSEQ',
                  record_format => 'MARC-in-JSON',
                  skip_empty_subfields => 1
);

ok($exporter, "create exporter ALEPHSEQ for MARC-in-JSON");

$exporter->add({
  _id => '1',
  fields => [
    { '001' => 'rec001' } ,
    { '100' => { 'subfields' => [ { 'a' => 'Davis, Miles'} , { 'c' => 'Test'}], 'ind1' => ' ', 'ind2' => ' '}} ,
    { '245' => { 'subfields' => [ { 'a' => 'Sketches in Blue'}], 'ind1' => ' ', 'ind2' => ' '}} ,
    { '500' => { 'subfields' => [ { 'a' => undef }] , 'ind1' => ' ', 'ind2' => ' '}} ,
    { '501' => { 'ind1' => ' ', 'ind2' => ' ' }} ,
    { '502' => { 'subfields' => [ { 'a' => undef} , { 'b' , 'ok' } ] , 'ind1' => ' ', 'ind2' => ' ' } } ,
    { '503' => { 'subfields' => [ { 'a' => '' }] , 'ind1' => ' ', 'ind2' => ' '}} ,
    { '540' => { 'subfields' => [ { 'a' => "\nabcd\n" }] , 'ind1' => ' ', 'ind2' => ' '}}
  ]
});

ok($xml =~ /^000000001/, 'test id');
ok($xml =~ /000000001 100   L \$\$aDavis, Miles\$\$cTest/, 'test subfields');
ok($xml !~ /000000001 500/, 'test skip empty subfields');
ok($xml =~ /000000001 540   L \$\$aabcd/, 'test skip newlines');

done_testing;
