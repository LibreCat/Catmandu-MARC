package Catmandu::Exporter::MARC;

use Catmandu::Sane;
use Catmandu::Util qw(xml_escape is_different);
use Moo;

with 'Catmandu::Exporter';

has type => (is => 'ro', default => sub { 'XML' });
has xml_declaration => (is => 'ro');
has collection => (is => 'ro');
has record_format => (is => 'ro', default => sub { 'raw' });
has record => (is => 'ro', lazy => 1, default => sub { 'record' });

sub add {
    my ($self, $data) = @_;
    my @out;
    if (!$self->count) {
        if ($self->xml_declaration) {
            push @out, Catmandu::Util::xml_declaration;
        }
        if ($self->collection) {
            push @out, qq(<marc:collection xmlns="http://www.loc.gov/MARC21/slim">);
        }
    }
    push @out, $self->collection ? '<marc:record>' : qq(<marc:record xmlns="http://www.loc.gov/MARC21/slim">);

    if ($self->record_format eq 'raw') { # raw MARC array
        for my $field (@{$data->{$self->record}}) {
            my ($tag, $ind1, $ind2, @data) = @$field;

            if ($tag eq 'LDR') {
                push @out, '<marc:leader>', xml_escape($data[1]), '</marc:leader>';
            }
            elsif ($tag =~ /^00/) {
                push @out, '<marc:controlfield tag="', xml_escape($tag),'">', xml_escape($data[1]), '</marc:controlfield>';
            }
            elsif ($tag !~ /^00.|FMT|LDR/) {
                push @out, '<marc:datafield tag="', xml_escape($tag), '" ind1="', $ind1,'" ind2="', $ind2, '">';
                while (@data) {
                    my ($code, $val) = splice(@data, 0, 2);
                    next unless $code =~ /[A-Za-z0-9]/;
                    push @out, '<marc:subfield code="', $code, '">', xml_escape($val), '</marc:subfield>';
                }
                push @out, '</marc:datafield>';
            }
        }
    }
    else { # MARC-in-JSON
        push @out, '<marc:leader>', xml_escape($data->{leader}), '</marc:leader>';
        for my $field (@{$data->{fields}}) {
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
    }

    $self->fh->print(join "", @out, '</marc:record>');
}

sub commit {
    my ($self) = @_;
    if ($self->collection) {
        $self->fh->print('</marc:collection>');
    }
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

=cut

1;
