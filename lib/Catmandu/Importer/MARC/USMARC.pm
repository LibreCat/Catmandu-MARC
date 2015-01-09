=head1 NAME

Catmandu::Importer::MARC::USMARC - Package that imports USMARC records

=head1 SYNOPSIS

    # From the command line (USMARC is the default importer for MARC)
    $ catmandu convert MARC --fix "marc_map('245a','title')" < /foo/data.mrc

    # From perl
    use Catmandu;

    # import records from file
    my $importer = Catmandu->importer('MARC',file => '/foo/data.mrc');
    my $fixer    = Catmandu->fixer("marc_map('245a','title')");

    $importer->each(sub {
        my $item = shift;
        ...
    });

    # or using the fixer

    $fixer->fix($importer)->each(sub {
        my $item = shift;
        printf "title: %s\n" , $item->{title};
    });

=head1 METHODS

=head2 new(file => $file , fh => $fh , id => $field)

Parse a file or a filehandle into a L<Catmandu::Iterable>. Optionally provide an
id attribute specifying the source of the system identifer '_id' field (e.g. '001').

=head1 INHERTED METHODS

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. 

=head1 SEE ALSO

L<MARC::File::USMARC>

=cut
package Catmandu::Importer::MARC::USMARC;
use Catmandu::Sane;
use Moo;
use MARC::File::USMARC;

with 'Catmandu::Importer';

has id        => (is => 'ro' , default => sub { '001' });
has records   => (is => 'rw');

sub generator {
    my ($self) = @_;
    my $file = MARC::File::USMARC->in($self->fh);
    sub  {
      $self->decode_marc($file->next());
    }
}

sub decode_marc {
    my ($self, $record) = @_;
    return unless eval { $record->isa('MARC::Record') };
    my @result = ();

    push @result , [ 'LDR' , undef, undef, '_' , $record->leader ];

    for my $field ($record->fields()) {
        my $tag  = $field->tag;
        my $ind1 = $field->indicator(1);
        my $ind2 = $field->indicator(2);

        my @sf = ();

        if ($field->is_control_field) {
            push @sf , '_', $field->data;
        }

        for my $subfield ($field->subfields) {
            push @sf , @$subfield;
        }

        push @result, [$tag,$ind1,$ind2,@sf];
    }

    my $sysid = undef;
    my $id = $self->id;

    if ($id =~ /^00/ && $record->field($id)) {
        $sysid = $record->field($id)->data();
    }
    elsif ($id =~ /^(\d{3})([\da-zA-Z])$/) {
        my $field = $record->field($1);
        $sysid = $field->subfield($2) if ($field);
    }
    elsif (defined $id  && $record->field($id)) {
        $sysid = $record->field($id)->subfield("a");
    }

    return { _id => $sysid , record => \@result };
}

1;