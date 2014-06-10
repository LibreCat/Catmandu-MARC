package Catmandu::Fix::marc_set;

use Catmandu::Sane;
use Carp qw(confess);
use Moo;
use Catmandu::Fix::Has;

has marc_path      => (fix_arg => 1);
has value          => (fix_arg => 1);
has record         => (fix_opt => 1);

sub emit {
    my ($self,$fixer) = @_;
    my $record_key  = $fixer->emit_string($self->record // 'record');
    my $value       = $fixer->emit_string($self->value);
    my $marc_path   = $self->marc_path;

    my $field_regex;
    my ($field,$ind1,$ind2,$subfield_regex,$from,$to,$len);

    if ($marc_path =~ /(\S{3})(\[(.)?,?(.)?\])?([_a-z0-9])?(\/(\d+)(-(\d+))?)?/) {
        $field          = $1;
        $ind1           = $3;
        $ind2           = $4;
        if (defined $5) {
            $subfield_regex = "$5";
        }
        else {
            $subfield_regex = ($field =~ /^LDR|^00/) ? "_" : "a";
        }
        $from           = $7;
        $to             = $9;
        $len = defined $to ? $to - $from + 1 : 1;
    }
    else {
        confess "invalid marc path";
    }

    $field_regex = $field;
    $field_regex =~ s/\*/./g;

    my $var  = $fixer->var;
    my $perl = "";

    $perl .= $fixer->emit_foreach("${var}->{${record_key}}", sub {
        my $var  = shift;
        my $perl = "";

        $perl .= "next if ${var}->[0] !~ /${field_regex}/;";

        if (defined $ind1) {
            $perl .= "next if (!defined ${var}->[1] || ${var}->[1] ne '${ind1}');";
        }
        if (defined $ind2) {
            $perl .= "next if (!defined ${var}->[2] || ${var}->[2] ne '${ind2}');";
        }

        my $i = $fixer->generate_var;
        my $set_subfields = sub {
                my $start = shift;
                my $found = $fixer->generate_var;
                my $perl  = "my ${found} = 0;".
                            "for (my ${i} = ${start}; ${i} < \@{${var}}; ${i} += 2) {".
                                "if (${var}->[${i}] eq '${subfield_regex}') {";
                if (defined $from) {
                    $perl  .=        "substr(${var}->[${i}+1],$from,$len) = ${value};";
                }
                else {
                    $perl  .=        "${var}->[${i}+1] = ${value};";
                } 
                                
                $perl .=             "${found} = 1;";
                $perl .=        "}".
                            "}";
                $perl .=    "if (${found} == 0) {".
                                "push(\@${var},'${subfield_regex}',${value});".
                            "}";
                $perl;
        };

        $perl .= "if (${var}->[0] =~ /^LDR|^00/) {";
        $perl .= $set_subfields->(3);

        # Old Catmandu::MARC contained a bug/feature to allow
        # for '_' subfields in non-control elements ..for backwards
        # compatibility we ignore them
        $perl .= "} elsif (defined ${var}->[5] && ${var}->[5] eq '_') {";
        $perl .= $set_subfields->(5);
        $perl .= "} else {";
            
        $perl .= $set_subfields->(3);
        $perl .= "}";

        $perl;
    });

    $perl;
}

=head1 NAME

Catmandu::Fix::marc_set - set a marc value of one (sub)field to a new value

=head1 SYNOPSIS

    # Set a field in the leader
    if marc_match('LDR/6','c')
        marc_set('LDR/6','p')
    end

    # Set all the 650-p fields to 'test'
    marc_set('650p','test')

    # Set the 100-a subfield where indicator-1 is 3
    marc_set('100[3]a','Farquhar family.')

=head1 DESCRIPTION

Read our Wiki pages at L<https://github.com/LibreCat/Catmandu/wiki/Fixes> for a complete
overview of the Fix language.

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;