=head1 NAME

Catmandu::Importer::MARC::Record - Package that imports an array of MARC::Record  

=head1 SYNOPSIS

    # From perl
    use Catmandu;
    use MARC::Record;

    my $record = MARC::Record->new();
    my $field = MARC::Field->new('245','','','a' => 'My title.');
    $record->append_fields($field);

    # import records from file
    my $importer = Catmandu->importer('MARC',file => '/foo/data.mrc' , records => [$record]);
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

=head2 new(records => [ <Marc::Record> , ... ] , id => $field)

Parse an array of L<MARC::Record> into a L<Catmandu::Iterable>. Optionally provide an
id attribute specifying the source of the system identifer '_id' field (e.g. '001').

=head1 INHERTED METHODS

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. 

=head1 SEE ALSO

L<MARC::Record>

=cut
package Catmandu::Importer::MARC::Record;
use Catmandu::Sane;
use Moo;

with 'Catmandu::Importer';

has id        => (is => 'ro' , default => sub { '001' });
has records   => (is => 'rw');

sub generator {
    my ($self) = @_;
    my @records = @{$self->records};

    sub  {
      $self->decode_marc(shift @records);
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