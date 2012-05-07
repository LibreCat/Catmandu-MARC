#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Catmandu::Importer::MARC';
    use_ok 'Catmandu::Fix::marc_map';
    use_ok 'Catmandu::Fix::marc_xml';
    use_ok 'Catmandu::Fix::marc_in_json';
}

require_ok 'Catmandu::Importer::MARC';
require_ok 'Catmandu::Fix::marc_map';
require_ok 'Catmandu::Fix::marc_xml';
require_ok 'Catmandu::Fix::marc_in_json';

done_testing 8;
