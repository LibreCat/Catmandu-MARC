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

- [Catmandu::Importer::MARC](https://metacpan.org/pod/Catmandu::Importer::MARC)
- [Catmandu::Exporter::MARC](https://metacpan.org/pod/Catmandu::Exporter::MARC)
- [Catmandu::Fix::marc\_map](https://metacpan.org/pod/Catmandu::Fix::marc_map)
- [Catmandu::Fix::marc\_add](https://metacpan.org/pod/Catmandu::Fix::marc_add)
- [Catmandu::Fix::marc\_remove](https://metacpan.org/pod/Catmandu::Fix::marc_remove)
- [Catmandu::Fix::marc\_xml](https://metacpan.org/pod/Catmandu::Fix::marc_xml)
- [Catmandu::Fix::marc\_in\_json](https://metacpan.org/pod/Catmandu::Fix::marc_in_json)
- [Catmandu::Fix::marc\_set](https://metacpan.org/pod/Catmandu::Fix::marc_set)
- [Catmandu::Fix::Bind::marc\_each](https://metacpan.org/pod/Catmandu::Fix::Bind::marc_each)
- [Catmandu::Fix::Condition::marc\_match](https://metacpan.org/pod/Catmandu::Fix::Condition::marc_match)
- [Catmandu::Fix::Inline::marc\_map](https://metacpan.org/pod/Catmandu::Fix::Inline::marc_map)
- [Catmandu::Fix::Inline::marc\_add](https://metacpan.org/pod/Catmandu::Fix::Inline::marc_add)
- [Catmandu::Fix::Inline::marc\_remove](https://metacpan.org/pod/Catmandu::Fix::Inline::marc_remove)

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
[Catmandu::Importer](https://metacpan.org/pod/Catmandu::Importer),
[Catmandu::Fix](https://metacpan.org/pod/Catmandu::Fix),
[Catmandu::Store](https://metacpan.org/pod/Catmandu::Store)

# AUTHOR

Patrick Hochstenbach, `<patrick.hochstenbach at ugent.be>`

# CONTRIBUTORS

- Nicolas Steenlant, `<nicolas.steenlant at ugent.be>`
- Nicolas Franck, `<nicolas.franck at ugent.be>`
- Johann Rolschewski, `jorol at cpan.org`
- Chris Cormack
- Robin Sheat

# LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
