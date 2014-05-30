package Catmandu::Fix::marc_remove;

use Catmandu::Sane;
use Carp qw(confess);
use Moo;
use Catmandu::Fix::Has;

has marc_path => (fix_arg => 1);
has record    => (fix_opt => 1);

sub emit {
    my ($self,$fixer) = @_;
    my $record_key  = $fixer->emit_string($self->record // 'record');
    my $marc_path   = $self->marc_path;

    my $field_regex;
    my ($field,$ind1,$ind2,$subfield_regex,$from,$to,$len);

    if ($marc_path =~ /(\S{3})(\[(.)?,?(.)?\])?([_a-z0-9^]+)?(\/(\d+)(-(\d+))?)?/) {
        $field          = $1;
        $ind1           = $3;
        $ind2           = $4;
        $subfield_regex = defined $5 ? "[$5]" : undef;
        $from           = $7;
        $to             = $9;
    }
    else {
        confess "invalid marc path";
    }

    $field_regex = $field;
    $field_regex =~ s/\*/./g;

    my $var        = $fixer->var;
    my $new_record = $fixer->generate_var;
    my $perl       = $fixer->emit_declare_vars($new_record,[]);

    $perl .= $fixer->emit_foreach("${var}->{${record_key}}", sub {
        my $var  = shift;
        my $perl = "";

        $perl .= "if (${var}->[0] =~ /${field_regex}/) { ";

        if (defined $ind1) {
            $perl .= "next if (defined ${var}->[1] && ${var}->[1] eq '${ind1}');";
        }

        if (defined $ind2) {
            $perl .= "next if (defined ${var}->[2] && ${var}->[2] eq '${ind2}');";
        }   

        unless (defined $ind1 || defined $ind2 || defined $subfield_regex) {
            $perl .= "next;";
        }

        $perl .= "}";

        my $i = $fixer->generate_var;
        
        my $new_subf = $fixer->generate_var;
        $perl   .= $fixer->emit_declare_vars($new_subf,'[]');

        my $del_subfields = sub {
                my $start    = shift;
                my $perl     =<<EOF;
${new_subf} = [];
for (my ${i} = ${start}; ${i} < \@{${var}}; ${i} += 2) {
    unless (${var}->[${i}] =~ /${subfield_regex}/) {
         push \@{${new_subf}} , ${var}->[${i}]; 
         push \@{${new_subf}} , ${var}->[${i}+1];                       
    }
}
splice \@{${var}} , ${start} , int(\@{${var}}), \@{${new_subf}};
EOF
                $perl;
        };

        if (defined $subfield_regex) {
            $perl .= "if ( ${var}->[0] =~ /${field_regex}/) {";
                $perl .= "if (${var}->[0] =~ /^LDR|^00/) {";
                $perl .= $del_subfields->(3);

                # Old Catmandu::MARC contained a bug/feature to allow
                # for '_' subfields in non-control elements ..for backwards
                # compatibility we ignore them
                $perl .= "} elsif (defined ${var}->[5] && ${var}->[5] eq '_') {";
                $perl .= $del_subfields->(5);
                $perl .= "} else {";
                    
                $perl .= $del_subfields->(3);
                $perl .= "}";
            $perl .= "}";
        }
        
        $perl .= "push \@${new_record} , ${var} ";

        $perl;
    });

    $perl .= "${var}->{${record_key}} = ${new_record};";

    $perl;
}

=head1 NAME

Catmandu::Fix::marc_remove - remove marc (sub)fields

=head1 SYNOPSIS

    # remove all marc 600 fields
    marc_remove('600')

    # remove the 245-a subfield
    marc_remove('245a')

    # the same with the marc fields in 'record2'
    marc_remove('600', '-record', 'record2')

=head1 DESCRIPTION

Read our Wiki pages at L<https://github.com/LibreCat/Catmandu/wiki/Fixes> for a complete
overview of the Fix language.

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
