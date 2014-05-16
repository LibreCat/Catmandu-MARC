use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Catmandu::MARC',
    license => 'perl',
    dist_author => [
        'Patrick Hochstenbach <patrick.hochstenbach@ugent.be>',
        'Nicolas Steenlant <nicolas.steenlant@ugent.be>'
    ],
    dist_version_from => 'lib/Catmandu/MARC.pm',
    build_requires => {
        'Test::Exception' => 0,
        'Test::More' => 0,
        'XML::XPath' => 0,
    },
    requires => {
        'perl' => '5.10.1',
        'Catmandu' => '0.9',
        'MARC::File::XML' => '0.93',
        'MARC::Record' => '2.0.3',
        'Moo' => '1.0',
    },
    add_to_cleanup => [qw(
        Catmandu-MARC-*
    )],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script;

