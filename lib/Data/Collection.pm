### Data::Collection provides nested datastructure functions based on DRef. 

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # This is free software; you can use it under the same terms as Perl itself.

### Change History
  # 1998-05-21 Added undef behavior in matching_keys and matching_values.
  # 1998-05-07 Replaced map with foreach in a few places.
  # 1998-04-17 Updated to use new Data::Sorting interface.
  # 1998-04-10 Added hash_by_array_key.
  # 1998-04-09 Fixed single-item problem with scalarkeysof algorithm. -Simon
  # 1998-03-12 Changed keysof to protect the dref separator.
  # 1998-02-24 Changed valuesof to return value of non-ref arguments.  -Piglet
  # 1998-01-30 Added array_by_hash_key($) and intersperse($@) -Simon
  # 1997-12-08 Removed package Data::Types, replaced with UNIVERSAL isa.
  # 1997-12-07 Exported uniqueindexby.  -Piglet
  # 1997-11-24 Finished orderedindexby.
  # 1997-11-13 Added orderedindexby, but it still needs a bit of work. -S.
  # 1997-09-05 Package split from the original dataops.pm into Data::*. -Simon
  # 1997-04-08 Added getbysubkeys, now called matching_values
  # 1997-01-21 Added scalarsof.
  # 1997-01-21 Failure for keysof, valuesof now returns () rather than undef.
  # 1997-01-11 Cloned and cleaned for IWAE.
  # 1996-11-18 Moved v2 code into production, additional cleanup. -Simon
  # 1996-11-13 Major overhaul. (Version 2.00)
  # 1997-04-18 Cleaned up documentation a smidge.
  # 1997-01-28 Possible fix to recurring "keysof operates on containers" error.
  # 1997-01-26 Catch bad argument types for sortby, indexby.
  # 1996-06-24 First version of dataops.pm created. -Simon

package Data::Collection;

$VERSION = 4.00_01;

# Dependencies
use Data::DRef qw( getData setData getDRef setDRef joindref shiftdref $Root $Separator );
use Data::Sorting qw( sort_in_place );
use Text::PropertyList;

# Exports and Overrides
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( valuesof keysof scalarkeysof scalarkeysandvalues  
	           matching_values matching_keys array_by_hash_key
		   indexby uniqueindexby orderedindexby intersperse );

use strict;

### Collection Basics: keysof and valuesof.
  # Move to DRef.pm !!

# @keys = keysof($collection)
  # Returns a list of keys (numeric or string) in a referenced hash or list
  
sub keysof {
  my $collection = shift;
  if ( UNIVERSAL::isa($collection,'HASH') ) {
    my @keys = keys %$collection;
    foreach ( @keys ) { s/(\Q$Separator\E)/\\$1/g; } 
    return @keys;
  } elsif ( UNIVERSAL::isa($collection,'ARRAY') ) {
    return (0 .. $#{$collection}) 
  } else {
    return ();
  }
}

# move keysof and valuesof into DRef.pm

# @values = valuesof($collection)
  # Returns a list of scalar values in a referenced hash or list
  
sub valuesof {
  my $collection = shift;
  return ($collection) if (! ref($collection));
  return (@$collection) if ( UNIVERSAL::isa($collection,'ARRAY') );
  return (values %$collection) if ( UNIVERSAL::isa($collection,'HASH') );
  return (); 
}

### DRefs to leaf nodes

# @drefs = scalarkeysof($collection);
  # Returns a list of drefs for non-ref leaves in a referenced structure
  
sub scalarkeysof ($) {
  my $collection = shift;
  my @keys = keysof( $collection );
  my $i;
  # warn "scalar keys are " . join(', ', @keys) . "\n";
  for ( $i = 0; $i <= $#keys; $i++) {
    my $key = $keys[$i];
    my $val = getDRef($collection, $key);
    next unless (ref $val);
    my @drefs = keysof( $val );
    if (scalar @drefs) {
      foreach ( @drefs ) { $_ = joindref($key, $_) };
      splice (@keys, $i, 1, @drefs);
      $i--;
    }
    # warn "                " . join(', ', @keys) . "\n";
  }
  # warn "                " . join(', ', @keys) . "\n";
  return @keys;
}

# %$flat_hash = scalarkeysandvalues( $collection )
  
sub scalarkeysandvalues ($) {
  my $collection = shift;
  my %hash;
  foreach ( scalarkeysof( $collection ) ) {
    $hash{ $_ } = getDRef($collection, $_);
  }
  # warn "scalar keys and values are " . join(', ', %hash) . "\n";
  return \%hash;
}

### Index by DRefs 

# $index = indexby($collection, @drefs)
  # needs to handle count keys > 3
sub indexby {
  my($collection, @drefs) = @_;
  
  my $item;
  my $index = {};
  if (scalar @drefs == 1) {
    foreach $item (valuesof ($collection)) {
      push (@{$index->{ getDRef($item,$drefs[0]) }}, $item );
    }
  } 
  elsif (scalar @drefs == 2) {
    foreach $item (valuesof ($collection)) {
      push (@{$index->{ getDRef($item,$drefs[0]) }->{ 
      	getDRef($item,$drefs[1]) }}, $item );
    }
  } 
  elsif (scalar @drefs == 3) {
    foreach $item (valuesof ($collection)) {
      push (@{$index->{ getDRef($item,$drefs[0]) }->{ 
      	getDRef($item,$drefs[1]) }->{ getDRef($item,$drefs[2]) }}, $item );
    }
  }
    
  return $index;
}

# $index = uniqueindexby($collection, @drefs)
  # needs to handle multiple keys
sub uniqueindexby {
  my($collection, @drefs) = @_;
  my $index = {};
  
  my $item;
  foreach $item (valuesof($collection)) {
    $index->{ getDRef($item, $drefs[0]) } = $item;
  }
  
  return $index;
}

# %@$groups = orderedindexby( @$items, $grouper, @sorters );
sub orderedindexby {
  my($collection, $grouper, @sorters) = @_;
  
  my $index = {};
  my $order = [];
  
  my $item;
  foreach $item (sort_in_place([ valuesof $collection ], @sorters )) {
    
    # Err::Debug::debug( 'Field::Compound::SectionSorter', 
    #   ['orderedindexby'],
    #   $item
    # );
    
    my $value = getDRef($item, $grouper);
    $value = '' unless (defined $value);
    push @$order, ( $index->{$value} = { 'value' => $value, 'items' => [] } )
					unless ( exists($index->{ $value }) );
    push @{ $index->{ $value }{'items'} }, $item;
  }
  return $order;
}

### Select by DRefs

# $item or @items = matching_values($collection, %kvp_criteria);
sub matching_values {
  my($collection, %kvp_criteria) = @_;
  my($item, $dref, @items);
  ITEM: foreach $item (valuesof $collection) {
    foreach $dref (keys %kvp_criteria) {
      next ITEM unless $kvp_criteria{$dref} eq 
      			( defined $dref ? getDRef($item, $dref) : $item )  
    }
    return $item unless (wantarray);
    push @items, $item;
  }
  return @items;
}

# $dref or @keys = matching_keys($collection, %kvp_criteria);
sub matching_keys {
  my($collection, %kvp_criteria) = @_;
  return unless ($collection and scalar %kvp_criteria);
  my ($majorkey, $dref, @keys);
  ITEM: foreach $majorkey (keysof $collection) {
    my $item = getDRef($collection,$majorkey);
    foreach $dref (keys %kvp_criteria) {
      next ITEM unless $kvp_criteria{$dref} eq 
	      ( defined $dref && length $dref ? getDRef($item, $dref) : $item )  
    }
    return $majorkey unless (wantarray);
    push @keys, $majorkey;
  }
  return @keys;
}

### Conversions

# @$items = array_by_hash_key( %$items );
sub array_by_hash_key ($) {
  my $hashref = shift;
  return $hashref if (UNIVERSAL::isa($hashref, 'ARRAY'));
  my $arrayref = [];
  my $key;
  foreach $key ( keys %$hashref ) {
    $arrayref->[ $key + 0 ] = $hashref->{ $key };
  }
  return $arrayref;
}

# %$items = hash_by_array_key( @$items );
sub hash_by_array_key ($) {
  my $arrayref = shift;
  return $arrayref if (UNIVERSAL::isa($arrayref, 'HASH'));
  my $hashref = {};
  my $key;
  foreach $key ( 0 .. $#$arrayref ) {
    $hashref->{ $key } = $arrayref->[ $key ];
  }
  return $hashref;
}

# %$items = hash_of_array_key( @$items );
sub hash_of_array_key ($) {
  my $arrayref = shift;
  return { map { $arrayref->[$_], $_ } (0 .. $#$arrayref) };
}

### Utilities

# @items_with_seps = intersperse( $spacer, @items );
sub intersperse ($@) {
  my $item = shift;
  my $count;
  map { $count++ ? ( $item, $_ ) : ( $_ ) } @_;
}

1;

__END__

=head1 Data::Collection

Data::Collection provides functions to manipulate and examine the contents of collections (keys&values) independently of whether they are typed as Arrays or Hashes.  Includes basic collection info (keys and values, etc.), as well as functions to extract lists of matching values and create indices into collections.

=head1 Synopsis

    use Data::Collection;
    
    $collection = [ ... ] or { ... };
    
    @keys = keysof( $collection );
    @values = valuesof( $collection );
    @drefs = scalarkeysof( $collection );
    $flat_hash = scalarkeysandvalues( $collection );

    @items = matching_values( $collection, %kvp_criteria );
    @keys = matching_keys( $collection, %kvp_criteria );

    $index = indexby( $collection, @drefs );
    $index = uniqueindexby( $collection, @drefs );
    $groups = orderedindexby( @$items, $grouper, @sorters );

=head1 Description

Data::Collection provides a type-independent interface for manipulating and examining key/value pairs within Perl data structures. These data structures may be arrays or hashes, either "raw" or blessed.

=head1 Reference

=head2 Collection Basics

=over 4

=item keysof( $collection ) : @keys

Returns a list of keys in a collection; returns an empty list if input is not a collection.

=item valuesof( $collection ) : @values

Returns a list of values in a collection; returns an empty list if input is not a collection.

=item scalarkeysof( $collection ) : @drefs

Returns a list of drefs (delimited key-strings into nested data structures; see L<Data::DRef> for more info. on drefs) for non-ref leaves in a collection

=item scalarkeysandvalues( $collection ) : %$flat_hash

Returns a flattened hash of key-value pairs, where the keys are drefs and the values the current values, for non-ref leaves in a collection

=back

=head2 Matching Values

=over 4

=item matching_values( $collection, %kvp_criteria ) : $item or @items

Extracts and returns a list of values that match the input key => value criteria pairs.  If called in a scalar context, will return the first value that matches all of the input criteria.  Criteria are comprised of a DRef and a value to match against (string comparison).

    my @text_fields = matching_values($columns, 'type' => 'text');

Returns a list of all fields of type text (hashes with a key named type whose value is text) in the input collection $columns.

    my $show = matching_values($display_styles, 'label' => $show_arg);

Returns the first hash reference in the array $display_styles whose label is $show_arg (or undef if there aren't any).

=item matching_keys( $collection, $dref, $comp_value, ... ) : $key or @keys

Extracts a list of keys (or the first key, in scalar contexts) for collection contents that return the comparison value for the provided dref. If you pass undef as the second argument, the function will return keys whose values match the third argument.

    perl -e 'print matching_keys({"foo"=>"bar", "baz"=>"bang"}, undef, "bar")'
    foo

=back

=head2 Indexing

=over 4

=item indexby( $collection, @drefs ) : $index

Indexes the input collection by the list of input drefs (delimited key-strings representing paths to leaves or nodes in the collection).  Only handles up to 3 drefs, at the moment.  Returns a hash of key-value pairs whose keys are the values found at the index drefs and whose values are lists of elements of the input collection.

    $produce_info = [ { 'category' => 'fruit', 'name' => 'apples' },
                      { 'category' => 'fruit', 'name' => 'oranges' },
                      { 'category' => 'tubers', 'name' => 'potatoes' } ]
    my $groups = indexby($produce_info, 'category');

The value of $groups is now:

    { 'fruit' =>  [ { 'category' => 'fruit', 'name' => 'apples' },
                    { 'category' => 'fruit', 'name' => 'oranges' } ],
      'tubers' => [ { 'category' => 'tubers', 'name' => 'potatoes' } ] }

Now let's try it again, with multiple keys in the index:

    $produce_info = 
      [ { 'category' => 'fruit', 'name' => 'apples', 'color' => 'red' },
        { 'category' => 'fruit', 'name' => 'oranges', 'color' => 'orange' },
        { 'category' => 'tubers', 'name' => 'potatoes', 'color' => 'red' } ]
    $groups = indexby($produce_info, 'color', 'category');


The value of $groups is now:

     { 'red' => { 'fruit' => [ { 'category' => 'fruit', 
	                         'name' => 'apples', 
                                 'color' => 'red' } ],
                  'tubers' => [ { 'category' => 'tubers', 
                                  'name' => 'potatoes', 
                                  'color' => 'red' } ] },
       'orange' => { 'fruit' => [ { 'category' => 'fruit', 
                                    'name' => 'oranges', 
				    'color' => 'orange' } ] } }

=item uniqueindexby( $collection, $dref ) : $index

Returns a single value for each index.  (Uniqueindexby overwrites where indexby pushes onto a list.)  One level only for now; could easily support indexing on multiple input drefs.

    my $groups = uniqueindexby($produce_info, 'category');

The value of $groups is now:

    { 'fruit' =>  { 'category' => 'fruit', 'name' => 'oranges' },
      'tubers' => { 'category' => 'tubers', 'name' => 'potatoes' } }

=item orderedindexby( @$items, $grouper, @sorters ) : %@$groups

Orderedindexby differs from indexby in that only the first dref is used for indexing; any additional input drefs are used to sort the indexed groups.

  $contacts = [ { 'category' => 'family', 'name' => { 'first' => 'Bertha', 
                                                           'mi' => 'C', 
						           'last' => 'James' } },
                { 'category' => 'work', 'name' => { 'first' => 'Bob', 
		                                    'mi' => 'M', 
						    'last' => 'White' } },
		{ 'category' => 'family', 'name' => { 'first' => 'Bonnie', 
                                                      'mi' => 'C', 
						      'last' => 'James' } },
                { 'category' => 'work', 'name' => { 'first' => 'Harold', 
		                                    'mi' => 'N', 
						    'last' => 'Maude' } } ]
  my $phonebook = orderedindexby($contacts, 'category', 'name.last', 'name.first');

Note the use of drefs in this example to sort by sub-keys ('first' and 'last') of a hash (the value of the key 'name') within the input collection.  The value of $phonebook is now:

    { 'family' =>  [ { 'category' => 'family', 'name' => { 'first' => 'Bertha', 
                                                           'mi' => 'C', 
						           'last' => 'James' } },
		     { 'category' => 'family', 'name' => { 'first' => 'Bonnie', 
                                                           'mi' => 'C', 
						           'last' => 'James' } } ],
      'work' => [ { 'category' => 'work', 'name' => { 'first' => 'Harold', 
		                                      'mi' => 'N', 
						      'last' => 'Maude' } },
                  { 'category' => 'work', 'name' => { 'first' => 'Bob', 
		                                      'mi' => 'M', 
						      'last' => 'White' } } ] }

=back

=head1 Caveats and Upcoming Changes

Would be nice if we supported special collection classes.  

Indexby should support indexing by more than 3 keys; uniqueindexby perhaps should similarly support indexing by more than 1 key.

=head1 This is Free Software

Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut