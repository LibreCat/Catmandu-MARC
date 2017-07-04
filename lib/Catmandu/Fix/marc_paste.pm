package Catmandu::Fix::marc_paste;

use Catmandu::Sane;
use Catmandu::MARC;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Inlineable';

our $VERSION = '1.15';

has path   => (fix_arg => 1);

sub fix {
    my ($self, $data) = @_;
    my $path = $self->path;
    return Catmandu::MARC->instance->marc_paste($data,$path);
}

1;

__END__

=head1 NAME

Catmandu::Fix::marc_paste - paste a MARC structured field back into the MARC record

=head1 SYNOPSIS

    # Copy a field field
    marc_struc(001, fixed001)

    # Change it
    set_fieldfixed001.0.tag,002)

    # Paste it back into the record
    marc_paste(fixed001)


=head1 DESCRIPTION

Paste a MARC stucture created by L<Catmandu::Fix::marc_struc> back at the end of
a MARC record.

=head1 METHODS

=head2 marc_paste(JSON_PATH)

Paste a MARC struct PATH back in the MARC record

=head1 INLINE

This Fix can be used inline in a Perl script:

    use Catmandu::Fix::marc_struc as => 'marc_struc';
    use Catmandu::Fix::marc_paste as => 'marc_paste';

    my $data = { record => ['650', ' ', 0, 'a', 'Perl'] };

    $data = marc_struc($data,'650','subject');
    $data = marc_paste($data,'subject');


=head1 SEE ALSO

=over

=item * L<Catmandu::Fix::marc_struc>

=back

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
