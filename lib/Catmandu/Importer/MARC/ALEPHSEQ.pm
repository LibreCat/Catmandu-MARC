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