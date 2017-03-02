#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;

use Catmandu::Importer::MARC;
use Catmandu::Fix;

note("marc_map-----------------");

note("t");
{
    my $importer = Catmandu::Importer::MARC->new( file => 't/rug01.aleph', type => "ALEPHSEQ" );
    my $fixer = Catmandu::Fix->new(fixes => ['marc_map(650a,t)']);

    my $result = $fixer->fix($importer);

    my $field = $result->first->{t};

    ok $field , 'got an 650';

    my $joined = join "" , (
       'Semantics.',
       'Proposition (Logic)',
       'Speech acts (Linguistics)',
       'Generative grammar.',
       'Competence and performance (Linguistics)'
    );

    is $field , $joined , '650 is a joined string';
}

note("t.\$append");
{
    my $importer = Catmandu::Importer::MARC->new( file => 't/rug01.aleph', type => "ALEPHSEQ" );
    my $fixer = Catmandu::Fix->new(fixes => ['marc_map(650a,t.$append)']);

    my $result = $fixer->fix($importer);

    my $field = $result->first->{t};

    ok $field , 'got an 650';

    is_deeply $field , [
       'Semantics.',
       'Proposition (Logic)',
       'Speech acts (Linguistics)',
       'Generative grammar.',
       'Competence and performance (Linguistics)'
    ] , '650 is an array of values';
}

note("t, split:1");
{
    my $importer = Catmandu::Importer::MARC->new( file => 't/rug01.aleph', type => "ALEPHSEQ" );
    my $fixer = Catmandu::Fix->new(fixes => ['marc_map(650a,t,split:1)']);

    my $result = $fixer->fix($importer);

    my $field = $result->first->{t};

    ok $field , 'got an 650';

    is_deeply $field , [
       'Semantics.',
       'Proposition (Logic)',
       'Speech acts (Linguistics)',
       'Generative grammar.',
       'Competence and performance (Linguistics)'
    ] , '650 is an array of values';
}

note("t.\$append, split:1");
{
    my $importer = Catmandu::Importer::MARC->new( file => 't/rug01.aleph', type => "ALEPHSEQ" );
    my $fixer = Catmandu::Fix->new(fixes => ['marc_map(650a,t.$append,split:1)']);

    my $result = $fixer->fix($importer);

    my $field = $result->first->{t};

    ok $field , 'got an 650';

    is_deeply $field , [[
       'Semantics.',
       'Proposition (Logic)',
       'Speech acts (Linguistics)',
       'Generative grammar.',
       'Competence and performance (Linguistics)'
    ]] , '650 is an array of array of values';
}

note("marc_spec-----------------");

note("t");
{
    my $importer = Catmandu::Importer::MARC->new( file => 't/rug01.aleph', type => "ALEPHSEQ" );
    my $fixer = Catmandu::Fix->new(fixes => ['marc_spec(650$a,t)']);

    my $result = $fixer->fix($importer);

    my $field = $result->first->{t};

    ok $field , 'got an 650';

    my $joined = join "" , (
       'Semantics.',
       'Proposition (Logic)',
       'Speech acts (Linguistics)',
       'Generative grammar.',
       'Competence and performance (Linguistics)'
    );

    is $field , $joined , '650 is a joined string';
}

note("t.\$append");
{
    my $importer = Catmandu::Importer::MARC->new( file => 't/rug01.aleph', type => "ALEPHSEQ" );
    my $fixer = Catmandu::Fix->new(fixes => ['marc_spec(650$a,t.$append)']);

    my $result = $fixer->fix($importer);

    my $field = $result->first->{t};

    ok $field , 'got an 650';

    is_deeply $field , [
       'Semantics.',
       'Proposition (Logic)',
       'Speech acts (Linguistics)',
       'Generative grammar.',
       'Competence and performance (Linguistics)'
    ] , '650 is an array of values';
}

note("t, split:1");
{
    my $importer = Catmandu::Importer::MARC->new( file => 't/rug01.aleph', type => "ALEPHSEQ" );
    my $fixer = Catmandu::Fix->new(fixes => ['marc_spec(650$a,t,split:1)']);

    my $result = $fixer->fix($importer);

    my $field = $result->first->{t};

    ok $field , 'got an 650';

    is_deeply $field , [
       'Semantics.',
       'Proposition (Logic)',
       'Speech acts (Linguistics)',
       'Generative grammar.',
       'Competence and performance (Linguistics)'
    ] , '650 is an array of values';
}

note("t.\$append, split:1");
{
    my $importer = Catmandu::Importer::MARC->new( file => 't/rug01.aleph', type => "ALEPHSEQ" );
    my $fixer = Catmandu::Fix->new(fixes => ['marc_spec(650$a,t.$append,split:1)']);

    my $result = $fixer->fix($importer);

    my $field = $result->first->{t};

    ok $field , 'got an 650';

    is_deeply $field , [[
       'Semantics.',
       'Proposition (Logic)',
       'Speech acts (Linguistics)',
       'Generative grammar.',
       'Competence and performance (Linguistics)'
    ]] , '650 is an array of array of values';
}

done_testing;
