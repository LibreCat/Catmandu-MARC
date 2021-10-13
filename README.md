# NAME

Catmandu::MARC - Catmandu modules for working with MARC data

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-MARC.svg?branch=master)](https://travis-ci.org/LibreCat/Catmandu-MARC)
[![Coverage](https://coveralls.io/repos/LibreCat/Catmandu-MARC/badge.png?branch=master)](https://coveralls.io/r/LibreCat/Catmandu-MARC)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Catmandu-MARC.png)](http://cpants.cpanauthors.org/dist/Catmandu-MARC)

# SYNOPSIS

    # On the command line

    $ catmandu convert MARC to JSON < data.mrc

    $ catmandu convert MARC --type MiJ to YAML < data.marc_in_json

    $ catmandu convert MARC --fix "marc_map(245,title)" < data.mrc

    $ catmandu convert MARC --fix myfixes.txt < data.mrc

    myfixes:

    marc_map("245a", title)
    marc_map("5**", note.$append)
    marc_map('710','my.authors.$append')
    marc_map('008_/35-35','my.language')
    remove_field(record)
    add_field(my.funny.field,'test123')

    $ catmandu import MARC --fix myfixes.txt to ElasticSearch --index_name 'catmandu' < data.marc

    # In perl
    use Catmandu;

    my $importer = Catmandu->importer('MARC', file => 'data.mrc' );
    my $fixer    = Catmandu->fixer('myfixes.txt');
    my $store    = Catmandu->store('ElasticSearch', index_name => 'catmandu');

    $store->add_many(
       $fixer->fix($importer)
    );

# MODULES

- [Catmandu::MARC::Tutorial](https://metacpan.org/pod/Catmandu%3A%3AMARC%3A%3ATutorial)
- [Catmandu::Importer::MARC](https://metacpan.org/pod/Catmandu%3A%3AImporter%3A%3AMARC)
- [Catmandu::Exporter::MARC](https://metacpan.org/pod/Catmandu%3A%3AExporter%3A%3AMARC)
- [Catmandu::Fix::marc\_map](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Amarc_map)
- [Catmandu::Fix::marc\_spec](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Amarc_spec)
- [Catmandu::Fix::marc\_add](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Amarc_add)
- [Catmandu::Fix::marc\_append](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Amarc_append)
- [Catmandu::Fix::marc\_replace\_all](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Amarc_replace_all)
- [Catmandu::Fix::marc\_remove](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Amarc_remove)
- [Catmandu::Fix::marc\_xml](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Amarc_xml)
- [Catmandu::Fix::marc\_in\_json](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Amarc_in_json)
- [Catmandu::Fix::marc\_decode\_dollar\_subfields](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Amarc_decode_dollar_subfields)
- [Catmandu::Fix::marc\_set](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Amarc_set)
- [Catmandu::Fix::marc\_copy](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Amarc_copy)
- [Catmandu::Fix::marc\_cut](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Amarc_cut)
- [Catmandu::Fix::marc\_paste](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Amarc_paste)
- [Catmandu::Fix::marc\_sort](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3Amarc_sort)
- [Catmandu::Fix::Bind::marc\_each](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3ABind%3A%3Amarc_each)
- [Catmandu::Fix::Condition::marc\_match](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3ACondition%3A%3Amarc_match)
- [Catmandu::Fix::Condition::marc\_has](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3ACondition%3A%3Amarc_has)
- [Catmandu::Fix::Condition::marc\_has\_many](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3ACondition%3A%3Amarc_has_many)
- [Catmandu::Fix::Condition::marc\_spec\_has](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3ACondition%3A%3Amarc_spec_has)
- [Catmandu::Fix::Inline::marc\_map](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3AInline%3A%3Amarc_map)
- [Catmandu::Fix::Inline::marc\_add](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3AInline%3A%3Amarc_add)
- [Catmandu::Fix::Inline::marc\_remove](https://metacpan.org/pod/Catmandu%3A%3AFix%3A%3AInline%3A%3Amarc_remove)

# DESCRIPTION

With Catmandu, LibreCat tools abstract digital library and research services as data
warehouse processes. As stores we reuse MongoDB or ElasticSearch providing us with
developer friendly APIs. Catmandu works with international library standards such as
MARC, MODS and Dublin Core, protocols such as OAI-PMH, SRU and open repositories such
as DSpace and Fedora. And, of course, we speak the evolving Semantic Web.

Follow us on [http://librecat.org](http://librecat.org) and read an introduction into Catmandu data
processing at [https://github.com/LibreCat/Catmandu/wiki](https://github.com/LibreCat/Catmandu/wiki).

# SEE ALSO

[Catmandu](https://metacpan.org/pod/Catmandu),
[Catmandu::Importer](https://metacpan.org/pod/Catmandu%3A%3AImporter),
[Catmandu::Fix](https://metacpan.org/pod/Catmandu%3A%3AFix),
[Catmandu::Store](https://metacpan.org/pod/Catmandu%3A%3AStore),
[MARC::Spec](https://metacpan.org/pod/MARC%3A%3ASpec)

# AUTHOR

Patrick Hochstenbach, `<patrick.hochstenbach at ugent.be>`

# CONTRIBUTORS

- Nicolas Steenlant, `<nicolas.steenlant at ugent.be>`
- Nicolas Franck, `<nicolas.franck at ugent.be>`
- Johann Rolschewski, `jorol at cpan.org`
- Chris Cormack
- Robin Sheat
- Carsten Klee, `klee at cpan.org`

# COPYRIGHT 

Copyright 2012- Patrick Hochstenbach

# LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
