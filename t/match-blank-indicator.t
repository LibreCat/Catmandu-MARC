#!perl

use strict;
use warnings;
use Test::More;
use Catmandu qw(importer);

my $mrc = <<'MRC';
<?xml version="1.0" encoding="UTF-8"?>
<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim">
    <marc:record>
        <marc:datafield ind1=" " ind2=" " tag="300">
            <marc:subfield code="a">__</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1="1" ind2=" " tag="300">
            <marc:subfield code="a">1_</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2="1" tag="300">
            <marc:subfield code="a">_1</marc:subfield>
        </marc:datafield>
    </marc:record>
</marc:collection>
MRC

my $fix = <<'FIX';
marc_map("003[,]",test.0)
marc_map("003[ ,]",test.1)
marc_map("003[, ]",test.2)
marc_map("003[ , ]",test.3)
retain_field(test)
FIX

my $importer = importer( 'MARC', file => \$mrc, type => 'XML', fix => $fix );
my $record = $importer->first;
note explain $record;

is_deeply $record->{test},
  [ [ "__", "1_", "_1" ], [ "__", "_1" ], [ "__", "1_" ], ["__"] ],
  "match blank indicators";

done_testing;
