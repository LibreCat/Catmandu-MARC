package Catmandu::MARC;

use Catmandu::Sane;
use Catmandu::Util;
use Catmandu::Exporter::MARC::XML;
use Memoize;
use Carp;
use Moo;
with 'MooX::Singleton';

memoize('compile_marc_path');

our $VERSION = '1.03';

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
                $subfield =~ s{^[a-zA-Z0-9]}{}g;
                for my $c (split('',$subfield)) {
                    push @$v , @{ $_h->{$c} } if exists $_h->{$c};
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
                    $v = join $join_char, @$v;
                }

                if (defined(my $off = $context->{from})) {
                    $v = join $join_char, @$v if (ref $v eq 'ARRAY');
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
                if (defined($vals) && ref($vals) eq '') {
                    $vals = join $join_char , $vals , $v;
                }
                else {
                    $vals = $v;
                }
            }
        }
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

    my $MARC_PATH_REGEX = qr/(\S{1,3})(\[([^,])?,?([^,])?\])?([_a-z0-9^]+)?(\/(\d+)(-(\d+))?)?/;
    if ($marc_path =~ $MARC_PATH_REGEX) {
        $field          = $1;
        $ind1           = $3;
        $ind2           = $4;
        $subfield       = $5;
        $field = "0" x (3 - length($field)) . $field; # fixing 020 treated as 20 bug
        if (defined($subfield)) {
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

    if ($field =~ /\*/) {
        $field_regex    = $field;
        $field_regex    =~ s/\*/(?:[A-Z0-9])/g;
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
L<Catmandu::Store>

=head1 AUTHOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=head1 CONTRIBUTORS

=over

=item * Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=item * Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=item * Johann Rolschewski, C<< jorol at cpan.org >>

=item * Chris Cormack

=item * Robin Sheat

=back

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
