package Catmandu::Fix::marc_map;

use Catmandu::Sane;
use Moo;

has path           => (is => 'ro', required => 1);
has marc_path      => (is => 'ro', required => 1);
has record_key     => (is => 'ro', default => sub { "record" });
has join_char      => (is => 'ro', default => sub { "" });
has value          => (is => 'ro');
has field_regex    => (is => 'ro');
has subfield_regex => (is => 'ro');
has field          => (is => 'ro');
has ind1           => (is => 'ro');
has ind2           => (is => 'ro');
has from           => (is => 'ro');
has to             => (is => 'ro');

around BUILDARGS => sub {
    my ($orig, $class, $marc_path, $path, %opts) = @_;

    my $attrs = {
        marc_path => $marc_path,
        path => $path,
    };
    $attrs->{record_key} = $opts{-record} if defined $opts{-record};
    $attrs->{join_char}  = $opts{-join}   if defined $opts{-join};
    $attrs->{value}      = $opts{-value}  if defined $opts{-value};

    if ($marc_path =~ /(\S{3})(\[(.)?,?(.)?\])?([_a-z0-9]+)?(\/(\d+)(-(\d+))?)?/) {
        $attrs->{field}          = $1;
        $attrs->{ind1}           = $3;
        $attrs->{ind2}           = $4;
        $attrs->{subfield_regex} = $5 ? "[$5]" : "[a-z0-9_]";
        $attrs->{from}           = $7;
        $attrs->{to}             = $9;
    } else {
        confess "invalid marc path";
    }

    $attrs->{field_regex} = $attrs->{field};
    $attrs->{field_regex} =~ s/\*/./g;

    $orig->($class, $attrs);
};

sub emit {
    my ($self, $fixer) = @_;
    my $path = $fixer->split_path($self->path);
    my $record_key = $fixer->emit_string($self->record_key);
    my $join_char = $fixer->emit_string($self->join_char);
    my $field_regex = $self->field_regex;
    my $subfield_regex = $self->subfield_regex;
    my $var = $fixer->var;

    my $vals = $fixer->generate_var;
    my $perl = $fixer->emit_declare_vars($vals, '[]');

    $perl .= $fixer->emit_foreach("${var}->{${record_key}}", sub {
        my $var = shift;
        my $v = $fixer->generate_var;
        my $perl = "";

        $perl .= "next if ${var}->[0] !~ /${field_regex}/;";
        if ($self->value) {
            $perl .= $fixer->emit_declare_vars($v, $fixer->emit_string($self->value));
        } else {
            my $i = $fixer->generate_var;
            my $add_subfields = sub {
                my $start = shift;
                "for (my ${i} = ${start}; ${i} < \@{${var}}; ${i} += 2) {".
                    "if (${var}->[${i}] =~ /${subfield_regex}/) {".
                        "push(\@{${v}}, ${var}->[${i} + 1]);".
                    "}".
                "}";
            };
            $perl .= $fixer->emit_declare_vars($v, "[]");
            $perl .= "if (${var}->[0] eq 'LDR' || substr(${var}->[0], 0, 2) eq '00') {";
            $perl .= $add_subfields->(3);
            $perl .= "} else {";
            $perl .= $add_subfields->(5);
            $perl .= "}";
            $perl .= "if (\@{${v}}) {";
            $perl .= "${v} = join(${join_char}, \@{${v}});";
            if (defined(my $off = $self->from)) {
                my $len = defined $self->to ? $self->to - $off + 1 : 1;
                $perl .= "if (eval { ${v} = substr(${v}, ${off}, ${len}); 1 }) {";
            }
            $perl .= $fixer->emit_create_path($fixer->var, $path, sub {
                my $var = shift;
                "if (is_string(${var})) {".
                    "${var} = join(${join_char}, ${var}, ${v});".
                "} else {".
                    "${var} = ${v};".
                "}";
            });
            if (defined($self->from)) {
                $perl .= "}";
            }
            $perl .= "}";
        }
        $perl;
    });

    $perl;
}

1;

=head1 NAME

Catmandu::Fix::marc_map - copy marc values of one field to a new field

=head1 SYNOPSIS

    # Copy all 245 subfields into the my.title hash
    marc_map('245','my.title');

    # Copy the 245-$a$b$c subfields into the my.title hash
    marc_map('245abc','my.title');

    # Copy the 100 subfields into the my.authors array
    marc_map('100','my.authors.$append');

    # Add the 710 subfields into the my.authors array
    marc_map('710','my.authors.$append');

    # Copy the 600-$x subfields into the my.subjects array while packing each into a genre.text hash
    marc_map('600x','my.subjects.$append.genre.text');

    # Copy the 008 characters 35-35 into the my.language hash
    marc_map('008_/35-35','my.language');

    # Copy all the 600 fields into a my.stringy hash joining them by '; '
    marc_map('600','my.stringy', -join => '; ');

    # When 024 field exists create the my.has024 hash with value 'found'
    marc_map('024','my.has024', -value => 'found');

    # Do the same examples now with the marc fields in 'record2'
    marc_map('245','my.title', -record => 'record2');

=cut
