### Data::Sorting provides utility functions for sorting data structures.

### Sample Usage
  # sort_inplace( $list, \&sort_by_drefs, 'name.last', 'name.first' );
  # @list = sortbycalculation( $hashref, sub { $_[0] % 42 } );
  # sort_inplace( $list, \&sort_with_text_values, sub { $_[0]->name } );

### Interface
  # sort_inplace($listref, &$sorter_function, @args);
  # @items = sortbycalculation($collection, @functions)
  # @items = sort_by_drefs($collection, @subkeys)
  # @items = sort_with_text_values($collection, @functions)
  # $mangled_text = text_sort_value( $original_text );

### Caveats and Things Left Undone
  # - Need better control over raw vs. text vs. numeric comparisons #!#
  # - Note that this function doesn't currently handle sorting scalars directly
  # - Perhaps merge with Collection.pm?

### Change History
  # 1998-04-18 Refactored to single-function interface.
  # 1997-11-23 Made sortbycalculation always use text_sort_value.
  # 1997-11-13 Refactored sortbycalculation, added new sort_inplace function.
  # 1997-11-04 Yanked these out of the old dataops.pm library into Data::*.
  # 1997-05-09 Added sortbycalculation.
  # 1997-01-11 Version 3 forked for use with IWAE.
  # 1996-11-13 Version 2.00 of dataops adds sorting wrapper. -Simon
  # 1996-06-24 First version of dataops.pm created. -Simon

package Data::Sorting;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( sort_in_place );

use Data::DRef qw( getDRef );
use Carp;

use vars qw( $PseudoLocale );
$PseudoLocale = 1;

# sort_in_place($array_ref, $dref, ..., &$sorter_func, ...);
  # Old comment:
  # Sort the contents of a referenced array using an input sorting function
  # Return the sorted items in a collection based on the evaluator functions.
  # The comparisons are alphanumeric; the leftmost function takes precedence.
sub sort_in_place ($;@) {
  my $list = shift;
  unless ( UNIVERSAL::isa($list,'ARRAY') ) {
    carp "Sorting error: sort_inplace operates on lists only, not '$list'"; 
    return;
  }
  
  local @value_arrays;
  unless ( scalar @_ ) {
    push @value_arrays, [ @$list ];
  }
  foreach $sort_rule ( @_ ) {
    my @values;
    if ( ! ref $sort_rule ) {
      my $item;
      foreach $item (@$list) {
	my $value = getDRef($item, $sort_rule);
	$value = '' unless (defined $value);
	push @values, $value;
      }
    } elsif ( ref $sort_rule eq 'CODE' ) {
      my $item;
      foreach $item (@$list) {
	my $value = &$sort_rule($item);
	$value = '' unless (defined $value);
	push @values, $value;
      }
    } else {
      croak "Unknown type of sorting rule: $sort_rule";
    }
    # warn "Sorting values for $sort_rule: " . join(', ', @values);
    push @value_arrays, \@values;
  }
  
  @$list = @{$list}[ sort _sip_comparison ( 0 .. $#$list ) ];
}

# $comparison = _sip_comparison (implicit $a, $b);
  # Compare two array indexes by looking at the results stored in each of the 
  # local value arrays computed above.
sub _sip_comparison {
  # warn "sorting $a and $b\n";
  my ($rc, $calculation);
  foreach $calculation ( @value_arrays ) {
    # If both items are numeric, use numeric comparison
    return $rc if (
         $calculation->[$a] =~ /\A\-?\d+(?:\.\d+)?\Z/ and
	 $calculation->[$b] =~ /\A\-?\d+(?:\.\d+)?\Z/ and 
	 $rc = $calculation->[$a] <=> $calculation->[$b]
      );
    
    # If PseudoLocale is enabled, compare a mangled form of each
    return $rc if (
        $PseudoLocale and
        $rc = mangle($calculation->[$a]) cmp mangle($calculation->[$b])
      );
    
    return $rc if ($rc = $calculation->[$a] cmp $calculation->[$b]);
  }
  # If we haven't been able to distinguish between them, leave them in order.
  return $a <=> $b;
}

# $mangled_text = mangle( $original_text );
  # Lower-case, alphanumeric-only version of a string for textual comparisons
sub mangle { my $t = lc(shift); $t=~tr/0-9a-z/ /cs; $t=~s/\A\s+//; return $t; }

1;

__END__

### OLD CODE

push @EXPORT, qw( sort_inplace sort_by_drefs sort_with_text_values );
push @EXPORT_OK, qw( sort_inplace sort_by_drefs );

# sort_inplace($listref, &$sorter_function, @args);
  # Sort the contents of a referenced array using an input sorting function
sub sort_inplace ($$;@) {
  my $listref = shift;
  unless ( UNIVERSAL::isa($listref,'ARRAY') ) {
    carp "Sorting error: sort_inplace operates on lists only, not '$listref'"; 
    return;
  }
  
  my $sorter = shift;
  @$listref = &$sorter($listref, @_);
}

# @items = sortbycalculation($collection, @functions)
  # Return the sorted items in a collection based on the evaluator functions.
  # The comparisons are alphanumeric; the leftmost function takes precedence.
sub sortbycalculation ($;@) {
  my $collection = shift;
  
  my @items = @$collection;
  # warn "sorting values " . join(', ', @items) . "\n";
  
  local @value_arrays;
  foreach $function ( @_ ) {
    my @values;
    # This could be done with a map block, but then it'd be unreadable. -S
    foreach $item (@items) {
      my $value = &$function($item);
      $value = text_sort_value( $value ); #!# Text-friendly sorting
      push @values, $value;
    }
    # warn "built value array " . join(', ', @values) . "\n";
    push @value_arrays, \@values;
  }
  
  # warn "values " . join(', ', @items) . "\n";
  # warn "id order " . join(', ', sort calcvaluesort ( 0 .. $#items ) ) . "\n";
  return @{items}[ sort calcvaluesort ( 0 .. $#items ) ];
}

sub calcvaluesort {
  # warn "sorting $a and $b\n";
  my ($rc, $array_of_values);
  foreach $array_of_values ( @value_arrays ) {
    # how can we make this use the natural (eg, string or number) comparsion?
    if ( $array_of_values->[$a] =~ /\A\d+(?:\.\d+)?\Z/ and
	 $array_of_values->[$b] =~ /\A\d+(?:\.\d+)?\Z/ ) {
      return $rc if ($rc = $array_of_values->[$a] <=> $array_of_values->[$b]);
    } else {
      return $rc if ($rc = $array_of_values->[$a] cmp $array_of_values->[$b]);
    }
  }
  return $a <=> $b;
}

# $mangled_text = text_sort_value( $original_text );
sub text_sort_value ($) {
  $_ = shift;
  $_ = '' unless (defined $_);
  tr/A-Z/a-z/;
  tr/0-9a-z/ /cs;
  s/\A\s//;
  return $_;
}

# @items = sort_by_drefs($collection, @subkeys)
  # Return sorted items based on values found at a series of specified drefs
sub sort_by_drefs {
  my $collection = shift;
  
  my @closures;
  
  my $dref;
  foreach $dref ( @_ ) {
    # make an anonymous function that calls get on its argument with this $dref
    push @closures, sub { getDRef( $_[0], $dref)  };
    # warn "adding sorter for $dref\n";
  }
  
  sortbycalculation $collection, @closures;
}

# @items = sort_with_text_values($collection, @functions)
  # Friendly alpha sort, implemented as wrappers around your valuator functions
sub sort_with_text_values {
  my $collection = shift;
  
  my @closures;
  
  my $function;
  foreach $function ( @_ ) {
    push @closures, sub { text_sort_value( &$function($_[0]) ) };
  }
  
  sortbycalculation $collection, @closures;
}

__END__

=head1 Data::Sorting

Data::Sorting provides utility functions for sorting data structures.

=head1 Synopsis

    use Data::Sorting;
    
    sort_inplace($listref, &$sorter_function, @args);
    @items = sortbycalculation($collection, @functions)
    @items = sort_by_drefs($collection, @subkeys)
    @items = sort_with_text_values($collection, @functions)
    $mangled_text = text_sort_value( $original_text );

=head1 Description

=head2 Sample Usage

    sort_inplace( $list, \&sort_by_drefs, 'name.last', 'name.first' );
    @list = sortbycalculation( $hashref, sub { $_[0] % 42 } );
    sort_inplace( $list, \&sort_with_text_values, sub { $_[0]->name } );

=head1 Reference

=head2 Sorting Syntax

=over 4

=item sort_inplace( $listref, &$sorter_function, @args )

Sorts the contents of a referenced array using an input sorting function and its associated arguments.

=item sortbycalculation( $collection, @functions ) : @items

Returns the items in a collection, sorted based on the evaluator functions.
The comparisons are alphanumeric; the leftmost function takes precedence.

=item sort_by_drefs( $collection, @subkeys ) : @items

Returns sorted items based on values found at a series of specified drefs.

=item sort_with_text_values( $collection, @functions ) : @items

Friendly alphanumeric sort, implemented as wrappers around the input valuator functions.

=back

=head1 Caveats and Upcoming Changes

Need better control over raw vs. text vs. numeric comparisons.
Note that this function doesn't currently handle sorting scalars directly.

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut
