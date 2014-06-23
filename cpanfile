requires 'perl', 'v5.10.1';

on 'test', sub {
  requires 'Test::Simple', '1.001003';
  requires 'Test::More', '1.001003';
  requires 'XML::XPath', '1.13';
};

requires 'Catmandu', '0.9202';
requires 'JSON::XS', '2.3';
requires 'YAML::XS', '0.34';
requires 'MARC::File::XML', '0.93';
requires 'MARC::File::MARCMaker', '0.05';
requires 'MARC::File::MiJ' , '0.04';
requires 'MARC::Record', '2.0.6';
requires 'MARC::Parser::RAW', '0';
requires 'Moo', '1.0';