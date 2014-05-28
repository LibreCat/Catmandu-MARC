=head1 NAME

Catmandu::Exporter::MARC::ALEPHSEQ - Exporter for MARC records to Ex Libris' Aleph sequential

=head1 SYNOPSIS

    # From the command line 
    $ catmandu convert MARC to MARC --type ALEPHSEQ < /foo/data.mrc

    # From Perl
    use Catmandu;

    my $importer = Catmandu->importer('MARC', file => "/foo/bar.mrc" , type => 'USMARC');
    my $exporter = Catmandu->exporter('MARC', file => "marc.txt", type => 'ALEPHSEQ' );

    $exporter->add($importer);
    $exporter->commit;

=head1 METHODS

=head2 new(file => $file , %opts)

Create a new L<Catmandu::Exporter> to serialize MARC record into Aleph sequential. Provide the path
of a $file to write exported records to. Optionally the following paramters can be
specified:

	record : the key containing the marc record (default: 'record')
	record_format : optionally set to 'MARC-in-JSON' when the input format is in MARC-in-JSON
	skip_empty_subfields : skip fields which don't contain any data (default: false)

=head1 INHERTED METHODS

=head2 count

=head2 add($hashref)

=head2 add_many($array)

=head2 add_many($iterator)

=head2 add_many(sub {})

=head2 ...

All the L<Catmandu::Exporter> methods are inherited.

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut
package Catmandu::Exporter::MARC::ALEPHSEQ;
use Catmandu::Sane;
use Catmandu::Util qw(xml_escape is_different :array :is);
use Moo;

with 'Catmandu::Exporter', 'Catmandu::Exporter::MARC::Base';

has record               => (is => 'ro' , default => sub { 'record'});
has record_format        => (is => 'ro', default => sub { 'raw'} );
has skip_empty_subfields => (is => 'ro' , default => sub { 1 });

sub add {
    my ($self,$data) = @_;

    if ($self->record_format eq 'MARC-in-JSON') { 
        $data = $self->_json_to_raw($data);
    }

    my $_id    = sprintf("%-9.9d", $data->{_id} // 0);
	my $record = $data->{$self->record};  

    for my $field (@$record) {
    	my($tag,$ind1,$ind2,@data) = @$field;
    
        $ind1 = ' ' unless defined $ind1;
        $ind2 = ' ' unless defined $ind2;

        @data = $self->_clean_raw_data($tag,@data) if $self->skip_empty_subfields;

        next if @data == 0;

        my $seq =  "${_id} ${tag}${ind1}${ind2} L ";
  
        if (array_includes([qw(LDR FMT)],$tag) || $tag =~ /^00/) {
            $seq .= $data[1];
        } 
        else {
            while (@data) {
                my ($code,$val) = splice(@data, 0, 2);
                next unless $code =~ /[A-Za-z0-9]/;
                $seq .= "\$\$${code}${val}";
            }
        }

        $self->fh->print("$seq\n");
    }
}

sub commit {
	my $self = shift;
	$self->fh->flush;
}

1;