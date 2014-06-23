=head1 NAME

Catmandu::Exporter::MARC::XML - Exporter for MARC records to MARCXML

=head1 SYNOPSIS

    # From the command line 
    $ catmandu convert MARC to MARC --type XML < /foo/data.mrc

    # From Perl
    use Catmandu;

    my $importer = Catmandu->importer('MARC', file => "/foo/bar.mrc" , type => 'USMARC');
    my $exporter = Catmandu->exporter('MARC', file => "marc.xml", type => 'XML' );

    $exporter->add($importer);
    $exporter->commit;

=head1 METHODS

=head2 new(file => $file , %opts)

Create a new L<Catmandu::Exporter> to serialize MARC record into XML. Provide the path
of a $file to write exported records to. Optionally the following paramters can be
specified:

	record : the key containing the marc record (default: 'record')
	record_format : optionally set to 'MARC-in-JSON' when the input format is in MARC-in-JSON
	collection : add a marc:collection header when true (default: true)
	xml_declaration : add a xml declaration when true (default: true)
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
package Catmandu::Exporter::MARC::XML;
use Catmandu::Sane;
use Catmandu::Util qw(xml_escape is_different :array :is);
use Moo;

with 'Catmandu::Exporter', 'Catmandu::Exporter::MARC::Base';

has record               => (is => 'ro' , default => sub { 'record'});
has record_format        => (is => 'ro' , default => sub { 'raw'} );
has skip_empty_subfields => (is => 'ro' , default => sub { 1 });
has collection           => (is => 'ro' , default => sub { 1 });
has xml_declaration      => (is => 'ro' , default => sub { 1 });
has _n                   => (is => 'rw' , default => sub { 0 });

sub add {
    my ($self, $data) = @_;

 	if ($self->_n == 0) {
    	if ($self->xml_declaration) {
    		$self->fh->print(Catmandu::Util::xml_declaration);
    	}

    	if ($self->collection) {
    		$self->fh->print('<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim">');
    	}

    	$self->_n(1);
    }
 

    if ($self->record_format eq 'MARC-in-JSON') { 
        $data = $self->_json_to_raw($data);
    }

    if ($self->collection) {
    	$self->fh->print('<marc:record>');
    }
    else {
    	$self->fh->print('<marc:record xmlns:marc="http://www.loc.gov/MARC21/slim">');
    }

    my $record = $data->{$self->record};  

    for my $field (@$record) {
        my ($tag, $ind1, $ind2, @data) = @$field;
        
        $ind1 = ' ' unless defined $ind1;
        $ind2 = ' ' unless defined $ind2;

        @data = $self->_clean_raw_data($tag,@data) if $self->skip_empty_subfields;

        next if $tag eq 'FMT';
        next if @data == 0;

        if ($tag eq 'LDR') {
            $self->fh->print('<marc:leader>' . xml_escape($data[1]) . '</marc:leader>');
        }
        elsif ($tag =~ /^00/) {
            $self->fh->print('<marc:controlfield tag="' . xml_escape($tag) . '">' . xml_escape($data[1]) . '</marc:controlfield>');
        }
        else {
            $self->fh->print('<marc:datafield tag="' . xml_escape($tag) . '" ind1="' . $ind1 . '" ind2="' . $ind2 . '">');
            while (@data) {
                my ($code, $val) = splice(@data, 0, 2);
                next unless $code =~ /[A-Za-z0-9]/;
                $self->fh->print('<marc:subfield code="' . $code . '">' . xml_escape($val) . '</marc:subfield>');
            }
            $self->fh->print('</marc:datafield>');
        }
    }

    $self->fh->print('</marc:record>');
}

sub commit {
    my ($self) = @_;

    if($self->collection){
        $self->fh->print('</marc:collection>');
    }

    $self->fh->flush;
}

1;