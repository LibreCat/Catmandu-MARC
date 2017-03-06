package Catmandu::MARC;

use Catmandu::Sane;
use Catmandu::Util;
use Catmandu::Exporter::MARC::XML;
use MARC::Spec;
use Memoize;
use Carp;
use Moo;
with 'MooX::Singleton';

memoize('compile_marc_path');
memoize('parse_marc_spec');
memoize('get_index_range');

our $VERSION = '1.08';

sub marc_map {
    my $self      = $_[0];

    # $_[2] : marc_path
    my $context        = ref($_[2]) ?
                            $_[2] :
                            $self->compile_marc_path($_[2], subfield_wildcard => 1);

    confess "invalid marc path" unless $context;

    # $_[1] : data record
    my $record         = $_[1]->{'record'};

    return wantarray ? () : undef unless (defined $record && ref($record) eq 'ARRAY');

    # $_[3] : opts
    my $split          = $_[3]->{'-split'} // 0;
    my $join_char      = $_[3]->{'-join'}  // '';
    my $pluck          = $_[3]->{'-pluck'} // 0;
    my $value_set      = $_[3]->{'-value'} // undef;
    my $nested_arrays  = $_[3]->{'-nested_arrays'} // 0;
    my $append         = $_[3]->{'-append'} // undef;

    my $vals;

    for my $field (@$record) {
        next if (
            ($context->{is_regex_field} == 0 && $field->[0] ne $context->{field} )
            ||
            (defined $context->{ind1} && (!defined $field->[1] || $field->[1] ne $context->{ind1}))
            ||
            (defined $context->{ind2} && (!defined $field->[2] || $field->[2] ne $context->{ind2}))
            ||
            ($context->{is_regex_field} == 1 && $field->[0] !~ $context->{field_regex} )
        );

        my $v;

        if ($value_set) {
            for (my $i = 3; $i < @{$field}; $i += 2) {
                my $subfield_regex = $context->{subfield_regex};
                if ($field->[$i] =~ $subfield_regex) {
                    $v = $value_set;
                    last;
                }
            }
        }
        else {
            $v = [];

            if ($pluck) {
                # Treat the subfield as a hash index
                my $_h = {};
                for (my $i = $context->{start}; $i < @{$field}; $i += 2) {
                    push @{ $_h->{ $field->[$i] } } , $field->[$i + 1];
                }
                my $subfield = $context->{subfield};
                $subfield =~ s{[^a-zA-Z0-9]}{}g;
                for my $c (split('',$subfield)) {
                    my $val = $_h->{$c} // [undef];
                    push @$v , @{ $val } ;
                }
            }
            else {
                for (my $i = $context->{start}; $i < @{$field}; $i += 2) {
                    my $subfield_regex = $context->{subfield_regex};
                    if ($field->[$i] =~ $subfield_regex) {
                        push(@$v, $field->[$i + 1]);
                    }
                }
            }

            if (@$v) {
                if (!$split) {
                    my @defined_values = grep {defined($_)} @$v;
                    $v = join $join_char, @defined_values;
                }

                if (defined(my $off = $context->{from})) {
                    if (ref $v eq 'ARRAY') {
                        my @defined_values = grep {defined($_)} @$v;
                        $v = join $join_char, @defined_values;
                    }
                    my $len = $context->{len};
                    if (length(${v}) > $off) {
                        $v = substr($v, $off, $len);
                    } else {
                        $v = undef;
                    }
                }
            }
            else {
                $v = undef;
            }
        }

        if (defined $v) {
            if ($split) {
                $v = [ $v ] unless (defined($v) && ref($v) eq 'ARRAY');
                if (defined($vals) && ref($vals) eq 'ARRAY') {
                    # With the nested arrays option a split will
                    # always return an array of array of values.
                    # This was the old behavior of Inline marc_map functions
                    if ($nested_arrays == 1) {
                        push @$vals , $v;
                    }
                    else {
                        push @$vals , @$v;
                    }
                }
                else {
                    if ($nested_arrays == 1) {
                        $vals = [$v];
                    }
                    else {
                        $vals = [ @$v ];
                    }
                }
            }
            else {
                push @$vals , $v;
            }
        }
    }

    if ($split) {
        $vals = [ $vals ];
    }
    elsif ($append) {
        # we got a $append
    }
    elsif (defined $vals) {
        $vals = join $join_char , @$vals;
    }
    else {
        # no result
    }

    $vals;
}

sub marc_add {
    my ($self,$data,$marc_path,@subfields) = @_;

    my %subfields  = @subfields;
    my $marc       = $data->{'record'} // [];

    if ($marc_path =~ /^\w{3}$/) {
        my @field = ();
        push @field , $marc_path;
        push @field , $subfields{ind1} // ' ';
        push @field , $subfields{ind2} // ' ';


        for (my $i = 0 ; $i < @subfields ; $i += 2) {
            my $code  = $subfields[$i];
            next unless length $code == 1;
            my $value = $subfields[$i+1];

            if ($value =~ /^\$\.(\S+)$/) {
                my $path = $1;
                $value = Catmandu::Util::data_at($path,$data);
            }

            if (Catmandu::Util::is_array_ref $value) {
                for (@$value) {
                    push @field , $code;
                    push @field , $_;
                }
            }
            elsif (Catmandu::Util::is_hash_ref $value) {
                for (keys %$value) {
                    push @field , $code;
                    push @field , $value->{$_};
                }
            }
            elsif (Catmandu::Util::is_value($value) && length($value) > 0) {
                push @field , $code;
                push @field , $value;
            }
        }

        push @{ $marc } , \@field if @field > 3;
    }

    $data->{'record'} = $marc;

    $data;
}

sub marc_set {
    my ($self,$data,$marc_path,$value,%opts) = @_;
    my $record = $data->{'record'};

    return $data unless defined $record;

    if ($value =~ /^\$\.(\S+)/) {
        my $path = $1;
        $value = Catmandu::Util::data_at($path,$data);
    }

    if (Catmandu::Util::is_array_ref $value) {
        $value = $value->[-1];
    }
    elsif (Catmandu::Util::is_hash_ref $value) {
        my $last;
        for (keys %$value) {
            $last = $value->{$_};
        }
        $value = $last;
    }

    my $context = $self->compile_marc_path($marc_path, subfield_default => 1);

    confess "invalid marc path" unless $context;

    for my $field (@$record) {
        my ($tag, $ind1, $ind2, @subfields) = @$field;

        if ($context->{is_regex_field}) {
            next unless $tag =~ $context->{field_regex};
        }
        else {
            next unless $tag eq $context->{field};
        }

        if (defined $context->{ind1}) {
            if (!defined $ind1 || $ind1 ne $context->{ind1}) {
                next;
            }
        }
        if (defined $context->{ind2}) {
            if (!defined $ind2 || $ind2 ne $context->{ind2}) {
                next;
            }
        }

        my $found = 0;
        for (my $i = 0; $i < @subfields; $i += 2) {
            if ($subfields[$i] eq $context->{subfield}) {
                if (defined $context->{from}) {
                    substr($field->[$i + 4], $context->{from}, $context->{len}) = $value;
                }
                else {
                    $field->[$i + 4] = $value;
                }
                $found = 1;
            }
        }

        if ($found == 0) {
            push(@$field,$context->{subfield},$value);
        }
    }

    $data;
}

sub marc_remove {
    my ($self,$data, $marc_path,%opts) = @_;
    my $record = $data->{'record'};

    my $new_record;

    my $context = $self->compile_marc_path($marc_path);

    confess "invalid marc path" unless $context;

    for my $field (@$record) {
        my $field_size = int(@$field);

        if (
            ($context->{is_regex_field} == 0 && $field->[0] eq $context->{field})
            ||
            ($context->{is_regex_field} == 1 && $field->[0] =~ $context->{field_regex})
            ) {

            my $ind_match = undef;

            if (defined $context->{ind1} && defined $context->{ind2}) {
                $ind_match = 1 if (defined $field->[1] && $field->[1] eq $context->{ind1} &&
                                   defined $field->[2] && $field->[2] eq $context->{ind2});
            }
            elsif (defined $context->{ind1}) {
                $ind_match = 1 if (defined $field->[1] && $field->[1] eq $context->{ind1});
            }
            elsif (defined $context->{ind2}) {
                $ind_match = 1 if (defined $field->[2] && $field->[2] eq $context->{ind2});
            }
            else {
                $ind_match = 1;
            }

            if ($ind_match && ! defined $context->{subfield_regex}) {
                next;
            }

            if (defined $context->{subfield_regex}) {
                my $subfield_regex = $context->{subfield_regex};
                my $new_subf = [];
                for (my $i = $context->{start}; $i < $field_size; $i += 2) {
                    unless ($field->[$i] =~ $subfield_regex) {
                        push @$new_subf , $field->[$i];
                        push @$new_subf , $field->[$i+1];
                    }
                }

                splice @$field , $context->{start} , int(@$field), @$new_subf if $ind_match;
            }
        }

        push @$new_record , $field;
    }

    $data->{'record'} = $new_record;

    return $data;
}

sub marc_spec {
    my $self            = $_[0];
    # $_[1] : data record
    my $data            = $_[1]->{'record'};

    # $_[2] : spec
    my $ms              = ref($_[2]) ?
                            $_[2] :
                            $self->parse_marc_spec( $self->spec );

    # $_[3] : opts
    my $split          = $_[3]->{'-split'} // 0;
    my $join_char      = $_[3]->{'-join'}  // '';
    my $pluck          = $_[3]->{'-pluck'} // 0;
    my $value_set      = $_[3]->{'-value'} // undef;
    my $invert         = $_[3]->{'-invert'} // 0;
    my $append         = $_[3]->{'-append'} // undef;

    my $vals;

    # filter by tag
    my @fields     = ();
    my $field_spec = $ms->field;
    my $tag        = $field_spec->tag;
    $tag           = qr/$tag/;
    unless ( @fields =
        grep { $_->[0] =~ /$tag/ } @{ $data } )
    {
        return $vals;
    }

    if (defined $field_spec->indicator1) {
        my $indicator1 = $field_spec->indicator1;
        $indicator1    = qr/$indicator1/;
        unless( @fields =
            grep { defined $_->[1] && $_->[1] =~ /$indicator1/ } @fields)
        {
            return $vals;
        }
    }
    if (defined $field_spec->indicator2) {
        my $indicator2 = $field_spec->indicator2;
        $indicator2    = qr/$indicator2/;
        unless( @fields =
            grep { defined $_->[2] && $_->[2] =~ /$indicator2/ } @fields)
        {
            return $vals;
        }
    }

    # filter by index
    if ( -1 != $field_spec->index_length ) {    # index is requested
        my $index_range = $self->get_index_range( $field_spec, scalar @fields );
        my $prevTag     = q{};
        my $index       = 0;
        my $tag;
        my @filtered = ();
        for my $pos ( 0 .. $#fields ) {
            $tag = $fields[$pos][0];
            $index = ( $prevTag eq $tag or q{} eq $prevTag ) ? $index : 0;
            if ( Catmandu::Util::array_includes( $index_range, $index ) ) {
                push @filtered, $fields[$pos];
            }
            $index++;
            $prevTag = $tag;
        }
        unless (@filtered) { return $vals }
        @fields = @filtered;
    }

    # return $value_set ASAP
    if ( $value_set && !defined $ms->subfields ) {
        return $value_set;
    }

    if ( defined $ms->subfields ) {    # now we dealing with subfields
        # set the order of subfields
        my @sf_spec = map { $_ } @{ $ms->subfields };
        unless ( $pluck ) {
            @sf_spec = sort { $a->code cmp $b->code } @sf_spec;
        }

        # set invert level default
        my $invert_level = 4;
        my $codes;
        if ( $invert ) {
            $codes = '[^';
            $codes .= join '', map { $_->code } @sf_spec;
            $codes .= ']';
        }

        my ( @subfields, @subfield );
        my $invert_chars = sub {
            my ( $str, $start, $length ) = @_;
            for ( substr $str, $start, $length ) {
                $_ = '';
            }
            return $str;
        };

        for my $field (@fields) {
            my $start = 3;

            my @sf_results;

            for my $sf (@sf_spec) {
                # set invert level
                if ( $invert ) {
                    if ( -1 == $sf->index_length
                        && !defined $sf->char_start )
                    {    # todo add subspec check
                        next
                          if ( $invert_level == 3 )
                          ;    # skip subfield spec it's already covered
                        $invert_level = 3;
                    }
                    elsif ( !defined $sf->char_start )
                    {          # todo add subspec check
                        $invert_level = 2;
                    }
                    else {     # todo add subspec check
                        $invert_level = 1;
                    }
                }

                @subfield = ();
                my $code  =
                  ( $invert_level == 3 ) ? $codes : $sf->code;
                $code     = qr/$code/;
                for ( my $i = $start ; $i < @$field ; $i += 2 ) {
                    if ( $field->[$i] =~ /$code/ ) {
                        push( @subfield, $field->[ $i + 1 ] );
                    }
                }

                if ( $invert_level == 3 ) {
                    if (@subfield) { push @sf_results, @subfield }

                    # return $value_set ASAP
                    if ( @sf_results && $value_set ) {
                        return $value_set;
                    }
                    next;
                }
                next unless (@subfield);

                # filter by index
                if ( -1 != $sf->index_length ) {
                    my $sf_range = $self->get_index_range( $sf, scalar @subfield );
                    if ( $invert_level == 2 ) {    # inverted
                        @subfield = map {
                            Catmandu::Util::array_includes( $sf_range, $_ )
                              ? ()
                              : $subfield[$_]
                        } 0 .. $#subfield;
                    }
                    else {    # without invert
                        @subfield =
                          map { defined $subfield[$_] ? $subfield[$_] : () }
                          @$sf_range;
                    }
                    next unless (@subfield);
                }

                # return $value_set ASAP
                if ( $value_set ) { return $value_set }

                # get substring
                my $char_start = $sf->char_start;
                if ( defined $char_start ) {
                    my $char_start =
                      ( '#' eq $char_start )
                      ? $sf->char_length * -1
                      : $char_start;
                    if ( $invert_level == 1 ) {    # inverted
                        @subfield = map {
                            $invert_chars->( $_, $char_start, $sf->char_length )
                        } @subfield;
                    }
                    else {
                        @subfield =
                          map { substr $_, $char_start, $sf->char_length }
                          @subfield;
                    }
                }

                push @sf_results, @subfield;
            }

            if ($split) {
                push @subfields, @sf_results;
            }
            else {
                push @subfields, join($join_char,@sf_results);
            }
        }

        unless (@subfields) { return $vals }

        if ($split) {
            $vals = [[@subfields]];
        }
        elsif ($append) {
            $vals = [@subfields];
        }
        elsif (@subfields) {
            $vals = join( $join_char, @subfields );
        }
        else {
            $vals = undef;
        }
    }
    else {    # no particular subfields requested

        my $char_start = $field_spec->char_start;
        if ( defined $char_start ) {
            $char_start =
              ( '#' eq $char_start )
              ? $field_spec->char_length * -1
              : $char_start;
        }

        my @mapped = ();
        for my $field (@fields) {
            my $start = 4;

            my @subfields = ();
            for ( my $i = $start ; $i < @$field ; $i += 2 ) {
                    push( @subfields, $field->[$i] );
            }
            next unless (@subfields);

            # get substring
            if ( defined $char_start ) {
                @subfields =
                  map { substr $_, $char_start, $field_spec->char_length }
                    @subfields;
            }

            if ($split) {
                push @mapped, @subfields;
            }
            else {
                push @mapped, join($join_char,@subfields);
            }
        }

        unless (@mapped) {
            return $vals
        }

        if ($split) {
            $vals = [[@mapped]];
        }
        elsif ($append) {
            $vals = [ @mapped ];
        }
        elsif (@mapped) {
            $vals = join $join_char, @mapped;
        }
        else {
            $vals = undef;
        }
    }

    return $vals;
}

sub parse_marc_spec {
    my ( $self, $marc_spec ) = @_;
    my $ms = MARC::Spec->parse( $marc_spec );
}

sub get_index_range {
        my ( $self, $spec, $total ) = @_;

        my $last_index  = $total - 1;
        my $index_start = $spec->index_start;
        my $index_end   = $spec->index_end;

        if ( '#' eq $index_start ) {
            if ( '#' eq $index_end or 0 eq $index_end ) { return [$last_index] }
            $index_start = $last_index;
            $index_end   = $last_index - $index_end;
            if ( 0 > $index_end ) { $index_end = 0 }
        }
        else {
            if ( $last_index < $index_start ) {
                return [$index_start];
            }    # this will result to no hits
        }

        if ( '#' eq $index_end or $index_end > $last_index ) {
            $index_end = $last_index;
        }

        my $range =
            ( $index_start <= $index_end )
          ? [ $index_start .. $index_end ]
          : [ $index_end .. $index_start ];
        return $range;
}

sub marc_xml {
    my ($self,$data) = @_;

    my $xml;
    my $exporter = Catmandu::Exporter::MARC::XML->new(file => \$xml , xml_declaration => 0 , collection => 0);
    $exporter->add($data);
    $exporter->commit;

    $xml;
}

sub marc_record_to_json {
    my ($self,$data,%opts) = @_;

    if (my $marc = delete $data->{'record'}) {
        for my $field (@$marc) {
            my ($tag, $ind1, $ind2, @subfields) = @$field;

            if ($tag eq 'LDR') {
               shift @subfields;
               $data->{leader} = join "", @subfields;
            }
            elsif ($tag eq 'FMT' || substr($tag, 0, 2) eq '00') {
               shift @subfields;
               push @{$data->{fields} ||= []} , { $tag => join "" , @subfields };
            }
            else {
               my @sf;
               my $start = !defined($subfields[0]) || $subfields[0] eq '_' ? 2 : 0;
               for (my $i = $start; $i < @subfields; $i += 2) {
                   push @sf, { $subfields[$i] => $subfields[$i+1] };
               }
               push @{$data->{fields} ||= []} , { $tag => {
                   subfields => \@sf,
                   ind1 => $ind1,
                   ind2 => $ind2 } };
            }
        }
    }

    $data;
}

sub marc_json_to_record {
    my ($self,$data,%opts) = @_;

    my $record = [];

    if (Catmandu::Util::is_string($data->{leader})) {
        push @$record , [ 'LDR', undef, undef, '_', $data->{leader} ],
    }

    if (Catmandu::Util::is_array_ref($data->{fields})) {
        for my $field (@{$data->{fields}}) {
            next unless Catmandu::Util::is_hash_ref($field);

            my ($tag) = keys %$field;
            my $val   = $field->{$tag};

            if ($tag eq 'FMT' || substr($tag, 0, 2) eq '00') {
               push @$record , [ $tag, undef, undef, '_', $val ],
            }
            elsif (Catmandu::Util::is_hash_ref($val)) {
               my $ind1 = $val->{ind1};
               my $ind2 = $val->{ind2};
               next unless Catmandu::Util::is_array_ref($val->{subfields});

               my $sfs = [ '_' , ''];
               for my $sf (@{ $val->{subfields} }) {
                   next unless Catmandu::Util::is_hash_ref($sf);

                   my ($code) = keys %$sf;
                   my $sval   = $sf->{$code};

                   push @$sfs , [ $code , $sval];
               }

               push @$record , [ $tag , $ind1 , $ind2 , @$sfs];
            }
        }
    }

    if (@$record > 0) {
      delete $data->{fields};
      delete $data->{leader};
      $data->{'record'} = $record;
    }

    $data;
}

sub marc_decode_dollar_subfields {
    my ($self,$data,%opts) = @_;
    my $old_record = $data->{'record'};
    my $new_record = [];

    for my $field (@$old_record) {
        my ($tag,$ind1,$ind2,@subfields) = @$field;

        my $fixed_field = [$tag,$ind1,$ind2];

        for (my $i = 0 ; $i < @subfields ; $i += 2) {
            my $code  = $subfields[$i];
            my $value = $subfields[$i+1];

            # If a subfield contains fields coded like: data$xmore$yevenmore
            # chunks = (data,x,y,evenmore)
            my @chunks = split( /\$([a-z])/, $value );

            my $real_value = shift @chunks;

            push @$fixed_field , ( $code, $real_value);

            while (@chunks) {
                push  @$fixed_field , ( splice @chunks, 0, 2 );
            }
        }

        push @$new_record , $fixed_field;
    }

    $data->{'record'} = $new_record;

    $data;
}

sub compile_marc_path {
    my ($self,$marc_path,%opts) = @_;

    my ($field,$field_regex,$ind1,$ind2,
        $subfield,$subfield_regex,$from,$to,$len,$is_regex_field);

    my $MARC_PATH_REGEX = qr/(\S{1,3})(\[([^,])?,?([^,])?\])?([\$_a-z0-9^]+)?(\/(\d+)(-(\d+))?)?/;
    if ($marc_path =~ $MARC_PATH_REGEX) {
        $field          = $1;
        $ind1           = $3;
        $ind2           = $4;
        $subfield       = $5;
        $field = "0" x (3 - length($field)) . $field; # fixing 020 treated as 20 bug
        if (defined($subfield)) {
            $subfield =~ s{\$}{}g;
            unless ($subfield =~ /^[a-zA-Z0-9]$/) {
                $subfield = "[$subfield]";
            }
        }
        elsif ($opts{subfield_default}) {
            $subfield = $field =~ /^0|LDR/ ? '_' : 'a';
        }
        elsif ($opts{subfield_wildcard}) {
            $subfield = '[a-z0-9_]';
        }
        if (defined($subfield)) {
            $subfield_regex = qr/^(?:${subfield})$/;
        }
        $from           = $7;
        $to             = $9;
        $len = defined $to ? $to - $from + 1 : 1;
    }
    else {
        return undef;
    }

    if ($field =~ /[\*\.]/) {
        $field_regex    = $field;
        $field_regex    =~ s/[\*\.]/(?:[A-Z0-9])/g;
        $is_regex_field = 1;
        $field_regex    = qr/^$field_regex$/;
    }
    else {
        $is_regex_field = 0;
    }

    return {
        field           => $field ,
        field_regex     => $field_regex ,
        is_regex_field  => $is_regex_field ,
        subfield        => $subfield ,
        subfield_regex  => $subfield_regex ,
        ind1            => $ind1 ,
        ind2            => $ind2 ,
        start           => 3,
        from            => $from ,
        to              => $to ,
        len             => $len
    };
}

1;

__END__

=head1 NAME

Catmandu::MARC - Catmandu modules for working with MARC data

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-MARC.svg?branch=master)](https://travis-ci.org/LibreCat/Catmandu-MARC)
[![Coverage](https://coveralls.io/repos/LibreCat/Catmandu-MARC/badge.png?branch=master)](https://coveralls.io/r/LibreCat/Catmandu-MARC)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Catmandu-MARC.png)](http://cpants.cpanauthors.org/dist/Catmandu-MARC)

=end markdown

=head1 SYNOPSIS

 # On the command line

 $ catmandu convert MARC to JSON < data.mrc

 $ catmandu convert MARC --type MiJ to YAML < data.marc_in_json

 $ catmandu convert MARC --fix "marc_map(245,title)" < data.mrc

 $ catmandu convert MARC --fix myfixes.txt < data.mrc

 myfixes:

 marc_map("245a", title)
 marc_map("5**", note.$append)
 marc_map('710','my.authors.$append')
 marc_map('008_/35-35','my.language')
 remove_field(record)
 add_field(my.funny.field,'test123')

 $ catmandu import MARC --fix myfixes.txt to ElasticSearch --index_name 'catmandu' < data.marc

 # In perl
 use Catmandu;

 my $importer = Catmandu->importer('MARC', file => 'data.mrc' );
 my $fixer    = Catmandu->fixer('myfixes.txt');
 my $store    = Catmandu->store('ElasticSearch', index_name => 'catmandu');

 $store->add_many(
 	$fixer->fix($importer)
 );

=head1 MODULES

=over

=item * L<Catmandu::Importer::MARC>

=item * L<Catmandu::Exporter::MARC>

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

=item * L<Catmandu::Fix::Inline::marc_map>

=item * L<Catmandu::Fix::Inline::marc_add>

=item * L<Catmandu::Fix::Inline::marc_remove>

=back

=head1 DESCRIPTION

With Catmandu, LibreCat tools abstract digital library and research services as data
warehouse processes. As stores we reuse MongoDB or ElasticSearch providing us with
developer friendly APIs. Catmandu works with international library standards such as
MARC, MODS and Dublin Core, protocols such as OAI-PMH, SRU and open repositories such
as DSpace and Fedora. And, of course, we speak the evolving Semantic Web.

Follow us on L<http://librecat.org> and read an introduction into Catmandu data
processing at L<https://github.com/LibreCat/Catmandu/wiki>.

=head1 SEE ALSO

L<Catmandu>,
L<Catmandu::Importer>,
L<Catmandu::Fix>,
L<Catmandu::Store>,
L<MARC::Spec>

=head1 AUTHOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=head1 CONTRIBUTORS

=over

=item * Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=item * Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=item * Johann Rolschewski, C<< jorol at cpan.org >>

=item * Chris Cormack

=item * Robin Sheat

=item * Carsten Klee, C<< klee at cpan.org >>

=back

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
