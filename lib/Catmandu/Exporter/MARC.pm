package Catmandu::Exporter::MARC;

use Catmandu::Sane;
use Catmandu::Util qw(xml_escape is_different);
use Moo;

with 'Catmandu::Exporter';

has type => (is => 'ro', default => sub { 'XML' });
has xml_declaration => (is => 'ro');
has collection    => (is => 'ro');
has record_format => (is => 'ro', default => sub { 'raw' });
has record        => (is => 'ro', lazy => 1, default => sub { 'record' });

sub add {
    my ($self, $data) = @_;
    my @out;
    if (!$self->count) {
        if ($self->xml_declaration) {
            push @out, Catmandu::Util::xml_declaration;
        }
        if ($self->collection) {
            push @out, qq(<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim">);
        }
    }

    if ($self->record_format eq 'raw') { # raw MARC array
        push @out, $self->marc_raw_to_marc_xml($data->{$self->record}, collection => $self->collection);
    }
    else { # MARC-in-JSON
        push @out, $self->marc_in_json_to_marc_xml($data, collection => $self->collection);
    }

    $self->fh->print(join("", @out));
}

sub commit {
    my ($self) = @_;
    if ($self->collection) {
        $self->fh->print('</marc:collection>');
    }
}

sub marc_raw_to_marc_xml {
    my ($class, $rec, %opts) = @_;
    my @out;

    push @out, $opts{collection} ? '<marc:record>' : qq(<marc:record xmlns:marc="http://www.loc.gov/MARC21/slim">);

    for my $field (@$rec) {
        my ($tag, $ind1, $ind2, @data) = @$field;

        next if $tag eq 'FMT';

        if ($tag eq 'LDR') {
            push @out, '<marc:leader>', xml_escape($data[1]), '</marc:leader>';
        }
        elsif ($tag =~ /^00/) {
            push @out, '<marc:controlfield tag="', xml_escape($tag),'">', xml_escape($data[1]), '</marc:controlfield>';
        }
        else {
            push @out, '<marc:datafield tag="', xml_escape($tag), '" ind1="', $ind1,'" ind2="', $ind2, '">';
            while (@data) {
                my ($code, $val) = splice(@data, 0, 2);
                next unless $code =~ /[A-Za-z0-9]/;
                push @out, '<marc:subfield code="', $code, '">', xml_escape($val), '</marc:subfield>';
            }
            push @out, '</marc:datafield>';
        }
    }

    join('', @out, '</marc:record>');
}

sub marc_in_json_to_marc_xml {
    my ($class, $rec, %opts) = @_;
    my @out;

    push @out, $opts{collection} ? '<marc:record>' : qq(<marc:record xmlns:marc="http://www.loc.gov/MARC21/slim">);

    push @out, '<marc:leader>', xml_escape($rec->{leader}), '</marc:leader>';

    for my $field (@{$rec->{fields}}) {
        my ($tag) = keys %$field;
        my $val = $field->{$tag};
        if (ref $val) {
            push @out, '<marc:datafield tag="', xml_escape($tag), '" ind1="', $val->{ind1},'" ind2="', $val->{ind2}, '">';
            for my $subfield (@{$val->{subfields}}) {
                my ($code) = keys %$subfield;
                push @out, '<marc:subfield code="', $code,'">', xml_escape($subfield->{$code}), '</marc:subfield>';
            }
            push @out, '</marc:datafield>';
        } else {
            push @out, '<marc:controlfield tag="', xml_escape($tag),'">', xml_escape($val), '</marc:controlfield>';
        }
    }

    join('', @out, '</marc:record>');
}

=head1 NAME

Catmandu::Exporter::MARC - serialize parsed MARC data

=head1 SYNOPSIS

    use Catmandu::Exporter::MARC;

    my $exporter = Catmandu::Exporter::MARC->new(file => "marc.xml", type => "XML");
    my $data = {
     record => [
        ...
        [245, '1', '0', 'a', 'Cross-platform Perl /', 'c', 'Eric F. Johnson.'],
        ...
        ],
    };

    $exporter->add($data);
    $exporter->commit;

    # to serialize MARC-in-JSON:
    my $exporter = Catmandu::Exporter::MARC->new(record_format => "MARC-in-JSON");

=head1 METHODS

=head2 new(file => $file, %options)

Create a new Catmandu MARC exports which serializes into a $file. Optionally 
provide xml_declaration => 0|1 to in/exclude a XML declaration and, collection => 0|1
to include a MARC collection header. 

=cut

1;
