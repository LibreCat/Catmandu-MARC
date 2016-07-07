package Catmandu::Fix::marc_map;

use Catmandu::Sane;
use Catmandu::MARC;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

our $VERSION = '0.219';

has marc_path      => (fix_arg => 1);
has path           => (fix_arg => 1);
has record         => (fix_opt => 1);
has split          => (fix_opt => 1);
has join           => (fix_opt => 1);
has value          => (fix_opt => 1);
has pluck          => (fix_opt => 1);
has nested_arrays  => (fix_opt => 1);

sub emit {
    my ($self,$fixer) = @_;
    my $path        = $fixer->split_path($self->path);

    my $marc_path   = $fixer->emit_string($self->marc_path);
    my $record_opt  = $fixer->emit_string($self->record // 'record');
    my $join_opt    = $fixer->emit_string($self->join // '');
    my $split_opt   = $fixer->emit_string($self->split // 0);
    my $pluck_opt   = $fixer->emit_string($self->pluck // 0);
    my $nested_arrays_opt = $fixer->emit_string($self->nested_arrays // 0);

    my $value_opt   = $self->value ?
                        $fixer->emit_string($self->value) : 'undef';
    my $var         = $fixer->var;
    my $result      = $fixer->generate_var;

    my $perl =<<EOF;
if (my ${result} = Catmandu::MARC::marc_map(
            ${var},
            ${marc_path},
            -split => ${split_opt},
            -join  => ${join_opt},
            -pluck => ${pluck_opt},
            -nested_arrays => ${nested_arrays_opt} ,
            -value => ${value_opt}) ) {
EOF
    $perl .= $fixer->emit_create_path(
            $var,
            $path,
            sub {
                my $var2 = shift;
                "${var2} = ${result}"
            }
    );

    $perl .=<<EOF;
}
EOF
    $perl;
}

1;

=head1 NAME

Catmandu::Fix::marc_map - copy marc values of one field to a new field

=head1 SYNOPSIS

    # Append all 245 subfields to my.title field the values are joined into one string
    marc_map('245','my.title')

    # Append al 245 subfields to the my.title keeping all subfields as an array
    marc_map('245','my.title', split:1)

    # Copy the 245-$a$b$c subfields into the my.title hash in the order provided in the record
    marc_map('245abc','my.title')

    # Copy the 245-$c$b$a subfields into the my.title hash in the order c,b,a
    marc_map('245cba','my.title', pluck:1)

    # Copy the 100 subfields into the my.authors array
    marc_map('100','my.authors.$append')

    # Add the 710 subfields into the my.authors array
    marc_map('710','my.authors.$append')

    # Copy the 600-$x subfields into the my.subjects array while packing each into a genre.text hash
    marc_map('600x','my.subjects.$append.genre.text')

    # Copy the 008 characters 35-35 into the my.language hash
    marc_map('008/35-35','my.language')

    # Copy all the 600 fields into a my.stringy hash joining them by '; '
    marc_map('600','my.stringy', join:'; ')

    # When 024 field exists create the my.has024 hash with value 'found'
    marc_map('024','my.has024', value:found)

    # When 260c field exists create the my.has260c hash with value 'found'
    marc_map('260c','my.has260c', value:found)

    # Do the same examples now with the marc fields in 'record2'
    marc_map('245','my.title', record:record2)

    # Copy all 100 subfields except the digits to the 'author' field
    marc_map('100^0123456789','author')

    # Map all the 500 - 599 fields to my.notes
    marc_map('5**','my.motes')

    # Map the 100-a field where indicator-1 is 3
    marc_map('100[3]a','name.family')

    # Map the 245-a field where indicator-2 is 0
    marc_map('245[,0]a','title')

    # Map the 245-a field where indicator-1 is 1 and indicator-2 is 0
    marc_map('245[1,0]a','title')

=head1 DESCRIPTION

Copy data from a MARC record to a field.

=head1 SEE ALSO

L<Catmandu::Fix>

For a more extensive MARC path language please take a look at Casten Klee's MARCSpec module:

L<Catmandu::Fix::marc_spec>

=cut
