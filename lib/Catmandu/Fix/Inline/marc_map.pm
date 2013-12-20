=head1 NAME

Catmandu::Fix::Inline::marc_map - A marc_map-er for Perl scripts

=head1 SYNOPSIS

 use Catmandu::Fix::Inline::marc_map qw(:all);

 my $title   = marc_map($data,'245a');
 my @authors = marc_map($data,'100ab');

 # Get all 245 in an array
 @arr = marc_map($data,'245');

 # Or as a string
 $str = marc_map($data,'245');

 # str joined by a semi-colon
 $f245 = marc_map($data, '245', -join , ';');

 # Get the 245-$a$b$c subfields 
 $str = marc_map($data,'245abc');

 # Get the 008 characters 35-35 
 $str = marc_map($data,'008_/35-35');

 # Get all 100 subfields except the digits
 $str = marc_map($data,'100^0123456789');

 # The $data should be a Catmandu-style MARC hash
 { record => [
    ['field', 'ind1' , 'ind2' , 'subfieldcode or underscore' , 'data' , 'subfield' , 'data' , ...] ,
     ...
 ]};

 # Example
 $data = { record => [
    ['001' , ' ', ' ' , '_' , 'myrecord-001' ] ,
    ['020' , ' ', ' ' , 'a' , '978-1449303587' ] ,
    ['245' , ' ', ' ' , 'a' , 'Learning Per' , 'c', '/ by Randal L. Schwartz'],
 ]};

=head1 SEE ALSO

Catmandu::Fix::marc_map

=cut

package Catmandu::Fix::Inline::marc_map;

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(marc_map);
%EXPORT_TAGS = (all => [qw(marc_map)]);

sub marc_map {
    my ($data,$marc_path,%opts) = @_;

    return unless exists $data->{'record'};

    my $record = $data->{'record'};

    unless (defined $record && ref $record eq 'ARRAY') {
        return wantarray ? () : undef;
    }

    my $split     = $opts{'-split'};
    my $join_char = $opts{'-join'} // '';
    my $attrs     = {};

    if ($marc_path =~ /(\S{3})(\[(.)?,?(.)?\])?([_a-z0-9^]+)?(\/(\d+)(-(\d+))?)?/) {
        $attrs->{field}          = $1;
        $attrs->{ind1}           = $3;
        $attrs->{ind2}           = $4;
        $attrs->{subfield_regex} = defined $5 ? "[$5]" : "[a-z0-9_]";
        $attrs->{from}           = $7;
        $attrs->{to}             = $9;
    } else {
        return wantarray ? () : undef;
    }

    $attrs->{field_regex} = $attrs->{field};
    $attrs->{field_regex} =~ s/\*/./g;

    my $add_subfields = sub {
        my $var   = shift;
        my $start = shift;

        my @v = ();

        for (my $i = $start; $i < @$var; $i += 2) {
            if ($var->[$i] =~ /$attrs->{subfield_regex}/) {
                push(@v, $var->[$i + 1]);
            }
        }

        return \@v;
    };

    my @vals = ();

    for my $var (@$record) {
    	next if $var->[0] !~ /$attrs->{field_regex}/;
    	next if defined $attrs->{ind1} && $var->[1] ne $attrs->{ind1};
    	next if defined $attrs->{ind2} && $var->[2] ne $attrs->{ind2};

    	my $v;

    	if ($var->[0] =~ /LDR|00./) {
    		$v = $add_subfields->($var,3);
    	}
    	elsif (defined $var->[5] && $var->[5] eq '_') {
    		$v = $add_subfields->($var,5);
    	}
    	else {
    		$v = $add_subfields->($var,3);
    	}

    	if (@$v) {
    		if (!$split) {
    			$v = join $join_char, @$v;

    			if (defined(my $off = $attrs->{from})) {
    				my $len = defined $attrs->{to} ? $attrs->{to} - $off + 1 : 1;
    				$v = substr($v,$off,$len);
    			}
    		}
    	}

    	push (@vals,$v) if ( (ref $v eq 'ARRAY' && @$v) || (ref $v eq '' && length $v ));
    }

    if (wantarray) {
        return @vals;
    }
    elsif (@vals > 0) {
        return join $join_char , @vals;
    }
    else {
        return undef;
    }
}

1;
