#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Exporter::MARC;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Exporter::MARC::ISO';
    use_ok $pkg;
}

require_ok $pkg;

my $marciso = undef;

my $exporter = Catmandu::Exporter::MARC->new(file => \$marciso, type=> 'ISO');

ok $exporter , 'got an MARC/ISO exporter';

ok $exporter->add({
  _id => '1' ,
  record => [
            ['FMT', undef, undef, '_', 'BK'],
            ['001', undef, undef, '_', 'rec001'],
            ['100', ' ', ' ', 'a', 'Davis, Miles' , 'c' , 'Test'],
            ['245', ' ', ' ',
                'a', 'Sketches in Blue' ,
            ],
            ['500', ' ', ' ', 'a', undef],
            ['501', ' ', ' ' ],
            ['502', ' ', ' ', 'a', undef, 'b' , 'ok'],
            ['503', ' ', ' ', 'a', ''],
            ['CAT', ' ', ' ', 'a', 'test'],
        ]
}) , 'add';

ok $exporter->commit , 'commit';

ok length($marciso) >= 127 , 'got iso';

done_testing;
