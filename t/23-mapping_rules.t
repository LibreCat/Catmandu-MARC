use strict;
use warnings;
use Test::More;
use Catmandu;
use DDP;

my $mrc = <<'MRC';
<?xml version="1.0" encoding="UTF-8"?>
<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim">
    <marc:record>
        <marc:datafield ind1=" " ind2=" " tag="245">
            <marc:subfield code="a">Title / </marc:subfield>
            <marc:subfield code="c">Name</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="500">
            <marc:subfield code="a">A</marc:subfield>
            <marc:subfield code="a">B</marc:subfield>
            <marc:subfield code="a">C</marc:subfield>
            <marc:subfield code="x">D</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="650">
            <marc:subfield code="a">Alpha</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="650">
            <marc:subfield code="a">Beta</marc:subfield>
        </marc:datafield>
        <marc:datafield ind1=" " ind2=" " tag="650">
            <marc:subfield code="a">Gamma</marc:subfield>
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

note 'marc_map(245,title)     title: "Title / Name"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(245,title); retain_field(title)'
    );
    my $record = $importer->first;
    is $record->{title}, 'Title / Name', 'marc_map(245,title)';
    p $record;
}

note 'marc_map(245a,title)    title: "Title / "';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(245a,title); retain_field(title)'
    );
    my $record = $importer->first;
    is $record->{title}, 'Title / ', 'marc_map(245a,title)';
    p $record;
}

note 'marc_map(245,title.$append)     title: [ "Title / Name" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(245.$append,title); retain_field(title)'
    );
    my $record = $importer->first;
    is $record->{title}, ['Title / Name'], 'marc_map(245.$append,title)';
    p $record;
}

note 'marc_map(245a,title.$append)    title: [ "Title / " ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(245a.$append,title); retain_field(title)'
    );
    my $record = $importer->first;
    is $record->{title}, ['Title / '], 'marc_map(245a.$append,title)';
    p $record;
}

note 'marc_map(245,title, split:1)    title: [ "Title / ", "Name" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(245,title, split:1); retain_field(title)'
    );
    my $record = $importer->first;
    is $record->{title}, [ 'Title / ', 'Name' ],
        'marc_map(245,title, split:1)';
    p $record;
}

note
    'marc_map(245, title, split:1, nested_arrays:1)  title: [[ "Title / ", "Name" ]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix =>
            'marc_map(245, title, split:1, nested_arrays:1); retain_field(title)'
    );
    my $record = $importer->first;
    is $record->{title}, [ [ 'Title / ', 'Name' ] ],
        'marc_map(245, title, split:1, nested_arrays:1)';
    p $record;
}

note 'marc_map(500,note)  note: "ABCD"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(500,note); retain_field(note)'
    );
    my $record = $importer->first;
    is $record->{note}, 'ABCD', 'marc_map(500,note)';
    p $record;
}

note 'marc_map(500a,note)     note: "ABC"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(500a,note); retain_field(note)'
    );
    my $record = $importer->first;
    is $record->{note}, 'ABC', 'marc_map(500a,note)';
    p $record;
}

note 'marc_map(500,note.$append)  note: [ "ABCD" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => ' marc_map(500,note.$append); retain_field(note)'
    );
    my $record = $importer->first;
    is $record->{note}, ['ABCD'], ' marc_map(500,note.$append)';
    p $record;
}

note 'marc_map(500a,note.$append)     note: [ "ABC" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => ' marc_map(500a,note.$append); retain_field(note)'
    );
    my $record = $importer->first;
    is $record->{note}, ['ABC'], ' marc_map(500a,note.$append)';
    p $record;
}

note 'marc_map(500,note, split:1)     note: [ "A" , "B" , "C" , "D" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(500,note, split:1); retain_field(note)'
    );
    my $record = $importer->first;
    is $record->{note}, [ 'A', 'B', 'C', 'D' ], 'marc_map(500,note, split:1)';
    p $record;
}

note 'marc_map(500a,note, split:1)    note: [ "A" , "B" , "C" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(500a,note, split:1); retain_field(note)'
    );
    my $record = $importer->first;
    is $record->{note}, [ 'A', 'B', 'C' ], 'marc_map(500a,note, split:1)';
    p $record;
}

note
    'marc_map(500a,note, split:1, nested_arrays:1)   note: [[ "A" , "B" , "C" ]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix =>
            'marc_map(500,note, split:1, nested_arrays:1); retain_field(note)'
    );
    my $record = $importer->first;
    is $record->{note}, [ [ 'A', 'B', 'C', 'D' ] ],
        'marc_map(500,note, split:1, nested_arrays:1)';
    p $record;
}

note 'marc_map(500a,note.$append, split:1)    note : [[ "A" , "B" , "C" ]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(500a,note.$append, split:1); retain_field(note)'
    );
    my $record = $importer->first;
    is $record->{note}, [ [ 'A', 'B', 'C' ] ],
        'marc_map(500a,note.$append, split:1)';
    p $record;
}

note
    'marc_map(500a,note.$append, split:1, nested_arrays: 1)  note : [[[ "A" , "B" , "C" ]]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix =>
            'marc_map(500a,note.$append, split:1, nested_arrays: 1) ; retain_field(note)'
    );
    my $record = $importer->first;
    is $record->{note}, [ [ [ 'A', 'B', 'C' ] ] ],
        'marc_map(500a,note.$append, split:1, nested_arrays: 1)';
    p $record;
}

note 'marc_map(650,subject)   subject: "AlphaBetaGamma"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(650,subject); retain_field(title)'
    );
    my $record = $importer->first;
    is $record->{subject}, 'AlphaBetaGamma', 'marc_map(650,subject)';
    p $record;
}

note 'marc_map(650a,subject)  subject: "AlphaBetaGamma"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(650a,subject) ; retain_field(subject)'
    );
    my $record = $importer->first;
    is $record->{subject}, 'AlphaBetaGamma', 'marc_map(650a,subject)';
    p $record;
}

note 'marc_map(650a,subject.$append)  subject: [ "Alpha", "Beta" , "Gamma" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(650a,subject.$append); retain_field(subject)'
    );
    my $record = $importer->first;
    is $record->{subject}, [ 'Alpha', 'Beta', 'Gamma' ],
        'marc_map(650a,subject.$append)';
    p $record;
}

note
    'marc_map(650a,subject, split:1)     subject: [ "Alpha", "Beta" , "Gamma" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(650a,subject, split:1); retain_field(subject)'
    );
    my $record = $importer->first;
    is $record->{subject}, [ 'Alpha', 'Beta', 'Gamma' ],
        'marc_map(650a,subject, split:1)';
    p $record;
}

note
    'marc_map(650a,subject.$append, split:1)     subject: [[ "Alpha" , "Beta" , "Gamma" ]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix =>
            'marc_map(650a,subject.$append, split:1) ; retain_field(subject)'
    );
    my $record = $importer->first;
    is $record->{subject}, [ [ 'Alpha', 'Beta', 'Gamma' ] ],
        'marc_map(650a,subject.$append, split:1) ';
    p $record;
}

note
    'marc_map(650a,subject, split:1, nested_arrays:1)    subject: [["Alpha"], ["Beta"] , ["Gamma"]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix =>
            'marc_map(650a,subject, split:1, nested_arrays:1); retain_field(subject)'
    );
    my $record = $importer->first;
    is $record->{subject}, [ ['Alpha'], ['Beta'], ['Gamma'] ],
        'marc_map(650a,subject, split:1, nested_arrays:1)';
    p $record;
}

note
    'marc_map(650a,subject.$append, split:1, nested_arrays:1)    subject: [[["Alpha"], ["Beta"] , ["Gamma"]]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix =>
            'marc_map(650a,subject.$append, split:1, nested_arrays:1); retain_field(subject)'
    );
    my $record = $importer->first;
    is $record->{subject}, [ [ ['Alpha'], ['Beta'], ['Gamma'] ] ],
        'marc_map(650a,subject.$append, split:1, nested_arrays:1)';
    p $record;
}

note 'marc_map(999,local)     local: "XYZ"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(999,local); retain_field(local)'
    );
    my $record = $importer->first;
    is $record->{local}, 'XYZ', 'marc_map(999,local)';
    p $record;
}

note 'marc_map(999a,local)    local: "XYZ"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(999a,local); retain_field(local)'
    );
    my $record = $importer->first;
    is $record->{local}, 'XYZ', 'marc_map(999a,local)';
    p $record;
}

note 'marc_map(999a,local.$append)    local: [ "XY", "Z" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(999a,local.$append); retain_field(local)'
    );
    my $record = $importer->first;
    is $record->{local}, [ 'XY', 'Z' ], 'marc_map(999a,local.$append)';
    p $record;
}

note 'marc_map(999a,local, split:1)   local: [ "X" , "Y", "Z" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(999a,local, split:1); retain_field(local)'
    );
    my $record = $importer->first;
    is $record->{local}, [ 'X', 'Y', 'Z' ], 'marc_map(999a,local, split:1)';
    p $record;
}

note 'marc_map(999a,local.$append, split:1)   local: [[ "X" , "Y", "Z" ]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(999a,local.$append, split:1); retain_field(local)'
    );
    my $record = $importer->first;
    is $record->{local}, [ [ 'X', 'Y', 'Z' ] ],
        'marc_map(999a,local.$append, split:1)';
    p $record;
}

note
    'marc_map(999a,local, split:1, nested_arrays:1)  local: [ ["X" , "Y"] , ["Z"] ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix =>
            'marc_map(999a,local, split:1, nested_arrays:1); retain_field(local)'
    );
    my $record = $importer->first;
    is $record->{local}, [ [ 'X', 'Y' ], ['Z'] ],
        'marc_map(999a,local, split:1, nested_arrays:1) ';
    p $record;
}

note
    'marc_map(999a,local.$append, split:1, nested_arrays:1)  local: [[ ["X" , "Y"] , ["Z"] ]]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix =>
            'marc_map(650a,local.$append, split:1, nested_arrays:1); retain_field(local)'
    );
    my $record = $importer->first;
    is $record->{local}, [ [ ['Alpha'], ['Beta'], ['Gamma'] ] ],
        'marc_map(650a,local.$append, split:1, nested_arrays:1)';
    p $record;
}

note 'marc_map(***,all)   all: "Title / NameABCDAlphaBetaGammaXYZ"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix =>
            'marc_map(***,all); retain_field(all)'
    );
    my $record = $importer->first;
    is $record->{all}, 'Title / NameABCDAlphaBetaGammaXYZ',
        'marc_map(***,all)';
    p $record;
}

note 'marc_map(***a,all)  all: "Title / ABCAlphaBetaGammaXYZ"';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(***a,all); retain_field(all)'
    );
    my $record = $importer->first;
    is $record->{all}, 'Title / ABCAlphaBetaGammaXYZ', 'marc_map(***a,all)';
    p $record;
}

note
    'marc_map(***a,all.$append)  all: [ "Title / " , "ABC", "Alpha" , "Beta" , "Gamma" , "XY", "Z" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(***a,all.$append); retain_field(all)'
    );
    my $record = $importer->first;
    is $record->{all},
        ['Title / ABCAlphaBetaGammaXYZ'],
        'marc_map(***a,all.$append)';
    p $record;
}

note
    'marc_map(***a,all, split:1)     all: [ "Title / " , "A" , "B" , "C", "Alpha" , "Beta" , "Gamma" , "X" , "Y", "Z" ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix  => 'marc_map(***a,all, split:1); retain_field(all)'
    );
    my $record = $importer->first;
    is $record->{all},
        [ 'Title / ', 'A', 'B', 'C', 'Alpha', 'Beta', 'Gamma', 'X', 'Y',
        'Z' ], 'marc_map(***a,all, split:1)';
    p $record;
}

note
    'marc_map(***a,all, split:1, nested_arrays:1)    all: [ ["Title / "] , ["A" , "B" , "C"], ["Alpha"] , ["Beta"] , ["Gamma"] , ["X" , "Y"], ["Z"] ]';
{
    my $importer = Catmandu->importer(
        'MARC',
        file => \$mrc,
        type => 'XML',
        fix =>
            'marc_map(***a,all, split:1, nested_arrays:1); retain_field(all)'
    );
    my $record = $importer->first;
    is $record->{all},
        [
        ['Title / '], [ 'A', 'B', 'C' ], ['Alpha'], ['Beta'],
        ['Gamma'], [ 'X', 'Y' ], ['Z']
        ],
        'marc_map(***a,all, split:1, nested_arrays:1)';
    p $record;
}

done_testing;
