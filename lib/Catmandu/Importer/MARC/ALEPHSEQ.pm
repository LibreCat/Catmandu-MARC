=head1 NAME

Catmandu::Importer::MARC::ALEPHSEQ - Package that imports Ex Libris' Aleph sequential MARC records

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert MARC --type ALEPHSEQ --fix "marc_map('245a','title')" < /foo/usm01.txt

    # From perl
    use Catmandu;

    # import records from file
    my $importer = Catmandu->importer('MARC',file => '/foo/usm01.txt' , type => 'ALEPHSEQ');
    my $fixer    = Catmandu->fixer("marc_map('245a','title')");

    $importer->each(sub {
        my $item = shift;
        ...
    });

    # or using the fixer

    $fixer->fix($importer)->each(sub {
        my $item = shift;
        printf "title: %s\n" , $item->{title};
    });

=head1 METHODS

=head2 new(file => $file , fh => $fh)

Parse a file or a filehandle into a L<Catmandu::Iterable>.

=head1 INHERTED METHODS

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. 

=cut
package Catmandu::Importer::MARC::ALEPHSEQ;
use Catmandu::Sane;
use Moo;

with 'Catmandu::Importer';

sub generator {
    my $self = shift;

    sub {
        state $fh = $self->fh;
        state $prev_id;
        state $record = [];

        while(<$fh>) {
           chop;
           next unless (length $_ >= 18);

           my ($sysid,$s1,$tag,$ind1,$ind2,$s2,$char,$s3,$data) = unpack("A9A1A3A1A1A1A1A1U0A*",$_);
           unless ($tag =~ m{^[0-9A-Z]+}) {
               warn "skipping $sysid $tag unknown tag";
               next;
           }
           unless ($ind1 =~ m{[A-Za-z0-9]}) {
               $ind1 = " ";
           }
           unless ($ind2 =~ m{[A-Za-z0-9]}) {
               $ind2 = " ";
           }
           unless (utf8::decode($data)) {
               warn "skipping $sysid $tag unknown data";
               next;
           }
           if ($tag eq 'LDR') {
               $data =~ s/\^/ /g;
           }
           my @parts = ('_' , split(/\$\$(.)/, $data) );

           # All control-fields contain an underscore field containing the data
           # all other fields not.
           unless ($tag =~ /FMT|LDR|00./o) {
              shift @parts;
              shift @parts;
           }

           # If we have an empty subfield at the end, then we need to add a implicit empty value
           push(@parts,'') unless int(@parts) % 2 == 0;

           if (@$record > 0 && $tag eq 'FMT') {
               my $result = { _id => $prev_id , record => [ @$record ] };
               $record  = [[$tag, $ind1, $ind2, @parts]];
               $prev_id = $sysid;
               return $result;
           }

           push @$record, [$tag, $ind1, $ind2, @parts];

           $prev_id = $sysid;
        }

        if (@$record > 0) {
           my $result = { _id => $prev_id , record => [ @$record ] };
           $record = [];
           return $result;
        }
        else {
           return;
        }
    };
}


1;