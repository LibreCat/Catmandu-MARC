package Catmandu::Fix::marc_map;

use Catmandu::Sane;
use Carp qw(confess);
use Moo;
use Catmandu::Fix::Has;

has marc_path      => (fix_arg => 1);
has path           => (fix_arg => 1);
has record         => (fix_opt => 1);
has split          => (fix_opt => 1);
has join           => (fix_opt => 1);
has value          => (fix_opt => 1);
has pluck          => (fix_opt => 1);

sub emit {
    my ($self,$fixer) = @_;
    my $path        = $fixer->split_path($self->path);
    my $record_key  = $fixer->emit_string($self->record // 'record');
    my $join_char   = $fixer->emit_string($self->join // '');
    my $marc_path   = $self->marc_path;

    my $field_regex;
    my ($field,$ind1,$ind2,$subfield_regex,$from,$to);

    if ($marc_path =~ /(\S{3})(\[(.)?,?(.)?\])?([_a-z0-9^]+)?(\/(\d+)(-(\d+))?)?/) {
        $field          = $1;
        $ind1           = $3;
        $ind2           = $4;
        $subfield_regex = defined $5 ? "[$5]" : "[a-z0-9_]";
        $from           = $7;
        $to             = $9;
    }
    else {
        confess "invalid marc path";
    }

    $field_regex = $field;
    $field_regex =~ s/\*/./g;

    my $var  = $fixer->var;
    my $vals = $fixer->generate_var;
    my $perl = $fixer->emit_declare_vars($vals, '[]');


    $perl .= $fixer->emit_foreach("${var}->{${record_key}}", sub {
        my $var  = shift;
        my $v    = $fixer->generate_var;
        my $perl = "";

        $perl .= "next if ${var}->[0] !~ /${field_regex}/;";

        if (defined $ind1) {
            $perl .= "next if (!defined ${var}->[1] || ${var}->[1] ne '${ind1}');";
        }
        if (defined $ind2) {
            $perl .= "next if (!defined ${var}->[2] || ${var}->[2] ne '${ind2}');";
        }

        if ($self->value) {
            $perl .= $fixer->emit_declare_vars($v, $fixer->emit_string($self->value));
        } else {
            my $i = $fixer->generate_var;
            my $add_subfields = sub {
                my $start = shift;
                if ($self->pluck) {
                    # Treat the subfield_regex as a hash index
                    my $pluck = $fixer->generate_var;
                    return 
                    "my ${pluck}  = {};" .
                    "for (my ${i} = ${start}; ${i} < \@{${var}}; ${i} += 2) {".
                        "push(\@{ ${pluck}->{ ${var}->[${i}] } }, ${var}->[${i} + 1]);" .
                    "}" .
                    "for my ${i} (split('','${subfield_regex}')) { " .
                        "push(\@{${v}}, \@{ ${pluck}->{${i}} }) if exists ${pluck}->{${i}};" .
                    "}";
                }
                else {
                    # Treat the subfield_regex as regex that needs to match the subfields
                    return 
                    "for (my ${i} = ${start}; ${i} < \@{${var}}; ${i} += 2) {".
                        "if (${var}->[${i}] =~ /${subfield_regex}/) {".
                            "push(\@{${v}}, ${var}->[${i} + 1]);".
                        "}".
                    "}";
                }
            };
            $perl .= $fixer->emit_declare_vars($v, "[]");
            $perl .= "if (${var}->[0] =~ /^LDR|^00/) {";
            $perl .= $add_subfields->(3);
            # Old Catmandu::MARC contained a bug/feature to allow
            # for '_' subfields in non-control elements ..for beackwards
            # compatibility we ignore them
            $perl .= "} elsif (defined ${var}->[5] && ${var}->[5] eq '_') {";
            $perl .= $add_subfields->(5);
            $perl .= "} else {";
            $perl .= $add_subfields->(3);
            $perl .= "}";
            $perl .= "if (\@{${v}}) {";
            if (!$self->split) {
                $perl .= "${v} = join(${join_char}, \@{${v}});";
                if (defined(my $off = $from)) {
                    my $len = defined $to ? $to - $off + 1 : 1;
                    $perl .= "if (eval { ${v} = substr(${v}, ${off}, ${len}); 1 }) {";
                }
            }
            $perl .= $fixer->emit_create_path($fixer->var, $path, sub {
                my $var = shift;
                if ($self->split) {
                    "if (is_array_ref(${var})) {".
                        "push \@{${var}}, ${v};".
                    "} else {".
                        "${var} = [${v}];".
                    "}";
                } else {
                    "if (is_string(${var})) {".
                        "${var} = join(${join_char}, ${var}, ${v});".
                    "} else {".
                        "${var} = ${v};".
                    "}";
                }
            });
            if (defined($from)) {
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

    # Append all 245 subfields to my.title
    marc_map('245','my.title')

    # Append an array of 245 subfields to the my.title array
    marc_map('245','my.title', -split => 1)

    # Copy the 245-$a$b$c subfields into the my.title hash in the order provided in the record
    marc_map('245abc','my.title')

    # Copy the 245-$c$b$a subfields into the my.title hash in the order c,b,a
    marc_map('245cba','my.title', -pluck => 1)

    # Copy the 100 subfields into the my.authors array
    marc_map('100','my.authors.$append')

    # Add the 710 subfields into the my.authors array
    marc_map('710','my.authors.$append')

    # Copy the 600-$x subfields into the my.subjects array while packing each into a genre.text hash
    marc_map('600x','my.subjects.$append.genre.text')

    # Copy the 008 characters 35-35 into the my.language hash
    marc_map('008_/35-35','my.language')

    # Copy all the 600 fields into a my.stringy hash joining them by '; '
    marc_map('600','my.stringy', -join => '; ')

    # When 024 field exists create the my.has024 hash with value 'found'
    marc_map('024','my.has024', -value => 'found')

    # Do the same examples now with the marc fields in 'record2'
    marc_map('245','my.title', -record => 'record2')

    # Copy all 100 subfields except the digits to the 'author' field
    marc_map('100^0123456789','author')

    # Map all the 500 - 599 fields to my.notes
    marc_map('5**','my.motes')

    # Map the 100-a field where indicator-1 is 3
    marc_map('100[3]a','name.family')

=head1 DESCRIPTION

Read our Wiki pages at L<https://github.com/LibreCat/Catmandu/wiki/Fixes> for a complete
overview of the Fix language.

=head1 SEE ALSO

L<Catmandu::Fix>

=cut
