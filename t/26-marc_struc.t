use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Warn;
use Catmandu;

my $mrc = <<'MRC';
<?xml version="1.0" encoding="UTF-8"?>
<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim">
    <marc:record>
        <marc:controlfield tag="001">   92005291 </marc:controlfield>
        <marc:datafield ind1="1" ind2="0" tag="245">
            <marc:subfield code="a">Title / </marc:subfield>
            <marc:subfield code="c">Name</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="999">
            <marc:subfield code="a">X</marc:subfield>
            <marc:subfield code="a">Y</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="999">
            <marc:subfield code="a">Z</marc:subfield>
        </marc:datafield>
    </marc:record>
</marc:collection>
MRC

note 'marc_struc(001,cntrl)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_struc(001,cntrl); retain_field(cntrl)'
    );
    my $record = $importer->first;
    is_deeply $record->{cntrl},
        [
            {
                tag => '001',
                ind1 => undef,
                ind2 => undef,
                content => "   92005291 "
            }
        ], 'marc_struc(001,cntrl)';
}

note 'marc_struc(245,title)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_struc(245,title); retain_field(title)'
    );
    my $record = $importer->first;
    is_deeply $record->{title},
        [
            {
                tag => '245',
                ind1 => '1',
                ind2 => '0',
                subfields => [
                    { a => 'Title / '},
                    { c => 'Name' },
                ]
            }
        ], 'marc_map(245,title)';
}

note 'marc_struc(001/0-3,substr)';
{
    warnings_like { Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_struc(001/0-3,substr)'
    )->first} [{carped => qr/^path segments.+/},{carped => qr/^path segments.+/}], "warn on substring usage";
}

note 'marc_struc(245[,0],title)';
{
    warnings_like { Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_struc("245[,0]",title)'
    )->first} [{carped => qr/^path segments.+/},{carped => qr/^path segments.+/}], "warn on substring usage";
}


note 'marc_struc(245[1],title)';
{
    warnings_like { Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_struc(245[1],title)'
    )->first} [{carped => qr/^path segments.+/},{carped => qr/^path segments.+/}], "warn on substring usage";
}

note 'marc_struc(245a,title)';
{
    warnings_like { Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_struc(245a,title)'
    )->first} [{carped => qr/^path segments.+/},{carped => qr/^path segments.+/}], "warn on substring usage";
}

note 'marc_struc(999,local)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_struc(999,local); retain_field(local)'
    );
    my $record = $importer->first;
    is_deeply $record->{local},
        [
            {
                tag => '999',
                ind1 => ' ',
                ind2 => ' ',
                subfields => [
                    { a => 'X'},
                    { a => 'Y'}
                ]
            },
            {
                tag => '999',
                ind1 => ' ',
                ind2 => ' ',
                subfields => [
                    { a => 'Z'}
                ]
            }
        ], 'marc_struc(999,local)';
}

note 'marc_struc(...,all)';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_struc(...,all); retain_field(all)'
    );
    my $record = $importer->first;
    is_deeply $record->{all},
        [
            {
                tag => 'LDR',
                ind1 => undef,
                ind2 => undef,
                content => "                        "
            },
            {
                tag => '001',
                ind1 => undef,
                ind2 => undef,
                content => "   92005291 "
            },
            {
                tag => '245',
                ind1 => '1',
                ind2 => '0',
                subfields => [
                    { a => 'Title / '},
                    { c => 'Name' },
                ]
            },
            {
                tag => '999',
                ind1 => ' ',
                ind2 => ' ',
                subfields => [
                    { a => 'X'},
                    { a => 'Y'}
                ]
            },
            {
                tag => '999',
                ind1 => ' ',
                ind2 => ' ',
                subfields => [
                    { a => 'Z'}
                ]
            }
        ], 'marc_struc(...,all)';
}


done_testing;
