#!/usr/bin/env perl

use Catmandu;

my $file     = shift;

die "usage: $0 fix_file" unless $file;

my $importer = Catmandu->importer('MARC', type => 'ALEPHSEQ', file => 't/rug01.aleph');
my $fixer    = Catmandu->fixer($file);
my $exporter = Catmandu->exporter('Null');

$exporter->add_many($fixer->fix($importer));
$exporter->commit;
