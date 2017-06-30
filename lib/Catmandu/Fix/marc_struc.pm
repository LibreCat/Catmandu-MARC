package Catmandu::Fix::marc_struc;

use Catmandu::Sane;
use Catmandu::MARC;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

our $VERSION = '1.13';

has marc_path      => (fix_arg => 1);
has path           => (fix_arg => 1);

sub emit {
    my ($self,$fixer) = @_;
    my $path         = $fixer->split_path($self->path);
    my $key          = $path->[-1];
    my $marc_obj     = Catmandu::MARC->instance;

    # Precompile the marc_path to gain some speed
    my $marc_context = $marc_obj->compile_marc_path($self->marc_path);
    my $marc         = $fixer->capture($marc_obj);
    my $marc_path    = $fixer->capture($marc_context);

    my $var           = $fixer->var;
    my $result        = $fixer->generate_var;
    my $current_value = $fixer->generate_var;

    my $perl = "";
    $perl .= $fixer->emit_declare_vars($current_value, "[]");
    $perl .=<<EOF;
if (my ${result} = ${marc}->marc_struc(
            ${var},
            ${marc_path}) ) {
    ${result} = ref(${result}) ? ${result} : [${result}];
    for ${current_value} (\@{${result}}) {
EOF

    $perl .= $fixer->emit_create_path(
            $var,
            $path,
            sub {
                my $var2 = shift;
                "${var2} = ${current_value}"
            }
    );

    $perl .=<<EOF;
    }
}
EOF
    $perl;
}

1;

__END__

=head1 NAME

Catmandu::Fix::marc_struc - copy marc data in a structured way to a new field

=head1 SYNOPSIS

    # fixed field
    marc_struc(001, fixed001)

may result into

    fixed001 : [
        {
            "tag": "001",
            "ind1": null,
            "ind2": null,
            "content": "fol05882032 "
        }
    ]

And

    # variable field
    marc_struc(650, subjects)

may result into

    subjects:[
        {
            "subfields" : [
                {
                    "a" : "Perl (Computer program language)"
                }
            ],
            "ind1" : " ",
            "ind2" : "0",
            "tag" : "650"
      },
      {
            "ind1" : " ",
            "subfields" : [
                {
                    "a" : "Web servers."
                }
            ],
            "tag" : "650",
            "ind2" : "0"
      }
    ]


=head1 DESCRIPTION

Copy MARC data referred by MARC_TAG in a structured way to JSON path.

In contrast to L<Catmandu::Fix::marc_map> and L<Catmandu::Fix::marc_spec> 
marc_struc will not only copy data content (values) but also all data elements 
like tag, indicators and subfield codes into a nested data structure. 

=head1 METHODS

=head2 marc_struc(MARC_TAG, JSON_PATH)

Copy this data referred by a MARC_TAG to a JSON_PATH.

MARC_TAG (meaning the field tag) is the first segment of MARC_PATH.

Using a MARC_PATH with subfield codes, indicators or substring will cause a 
warning and these segments will be ignored when referring the data.

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_struc as => 'marc_struc';

    my $data = { record => ['650', ' ', 0, 'a', 'Perl'] };

    $data = marc_struc($data,'650','subject');

    print $data->{subject}->[0]->{tag} , "\n"; # '650'
    print $data->{subject}->[0]->{ind1} , "\n"; # ' '
    print $data->{subject}->[0]->{ind2} , "\n"; # 0
    print $data->{subject}->[0]->{subfields}->[0]->{a} , "\n"; # 'Perl'

=head1 SEE ALSO

=over

=item * L<Catmandu::Fix>

=item * L<Catmandu::Fix::marc_map>

=item * L<Catmandu::Fix::marc_spec>

=item * L<Catmandu::Fix::marc_add>

=item * L<Catmandu::Fix::marc_remove>

=item * L<Catmandu::Fix::marc_xml>

=item * L<Catmandu::Fix::marc_in_json>

=item * L<Catmandu::Fix::marc_decode_dollar_subfields>

=item * L<Catmandu::Fix::marc_set>

=item * L<Catmandu::Fix::Bind::marc_each>

=item * L<Catmandu::Fix::Condition::marc_match>

=item * L<Catmandu::Fix::Condition::marc_has>

=item * L<Catmandu::Fix::Condition::marc_has_many>

=item * L<Catmandu::Fix::Condition::marc_has_ref>

=back

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
