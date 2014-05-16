#!perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Catmandu::Importer::MARC';
    use_ok 'Catmandu::Exporter::MARC';
    use_ok 'Catmandu::Fix::marc_map';
    use_ok 'Catmandu::Fix::marc_xml';
    use_ok 'Catmandu::Fix::marc_in_json';
    use_ok 'Catmandu::Fix::Condition::marc_match';
}

done_testing 6;
