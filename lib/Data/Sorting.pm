### Data::Sorting provides a function for sorting data structures.

### Caveats and Things Undone
  # - Reverse-order (or "descending") sorting -- fairly urgent, eh?
  # - Jeremy's sorting model:
  #   Split each the string into runs of alpha, numeric, and other characters, 
  #   then compare each item in order; bob2 comes before bob11


### Change History
  # 1998-04-21 Revision of sorting rules for non-alphanumeric items
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

use Carp;
use Data::DRef qw( getDRef );

use vars qw( $ComparisonStyle );
$ComparisonStyle = 'simpletext';
# $ComparisonStyle = 'locale';

# sort_in_place($array_ref, $dref, &$sorter_func, ...);
sub sort_in_place ($;@) {
  my $list = shift;
  unless ( UNIVERSAL::isa($list,'ARRAY') ) {
    carp "Sorting error: sort_inplace operates on lists only, not '$list'"; 
    return;
  }
  
  local @value_arrays;
  unless ( scalar @_ ) {
    push @value_arrays, [ map { defined $_ ? $_ : '' } @$list ];
  }
  foreach $sort_rule ( @_ ) {
    my @values;
    if ( defined $sort_rule and ! ref $sort_rule ) {
      my $item;
      foreach $item (@$list) {
	my $value = getDRef($item, $sort_rule);
	$value = '' unless (defined $value);
	# Should do something about references.
	push @values, $value;
      }
    } elsif ( ref $sort_rule eq 'CODE' ) {
      my $item;
      foreach $item (@$list) {
	my $value = &$sort_rule($item);
	$value = '' unless (defined $value);
	# Should do something about references.
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
    # warn "comparing $calculation->[$a] and $calculation->[$b]\n";
    
    # Compare non-alphanumeric elements strictly
    if ( $ComparisonStyle eq 'simpletext' ) {
      my $a_alpha = ( $calculation->[$a] =~ /\w/ );
      my $b_alpha = ( $calculation->[$b] =~ /\w/ );
      # If both items are non-alphanumeric
      return $rc if ( ! $a_alpha and ! $b_alpha and 
	$rc = $calculation->[$a] cmp $calculation->[$b]
      );
      return $rc if ( $rc = $a_alpha <=> $b_alpha );
    }
    
    # If both items are numeric, use numeric comparison
    my $a_numer = ( $calculation->[$a] =~ /\A\-?\d+(?:\.\d+)?\Z/ );
    my $b_numer = ( $calculation->[$b] =~ /\A\-?\d+(?:\.\d+)?\Z/ );
    return $rc if (
      $a_numer and $b_numer and 
      $rc = $calculation->[$a] <=> $calculation->[$b]
    );
    return $rc if ( 
      $rc = $b_numer <=> $a_numer
    );
    
    # Compare textual items
    if ( $ComparisonStyle eq 'simpletext' ) {
      $rc = mangle($calculation->[$a]) cmp mangle($calculation->[$b])
    # } elsif ( $ComparisonStyle eq 'locale' ) {
    #   use locale;
    #   use POSIX qw(strcoll);
    #   $rc = strcoll(lc($calculation->[$a]), lc($calculation->[$b]));
    } else {
      $rc = $calculation->[$a] cmp $calculation->[$b];
    };
    return $rc if ( $rc );
  }
  
  # If we haven't been able to distinguish between them, leave them in order.
  return $a <=> $b;
}

# $mangled_text = mangle( $original_text );
  # Lower-case, alphanumeric-only version of a string for textual comparisons
sub mangle { my $t = lc(shift); $t=~tr/0-9a-z/ /cs; $t=~s/\A\s+//; return $t; }

1;

__END__

=head1 Data::Sorting

Data::Sorting provides utility functions for sorting data structures.

=head1 Synopsis

    use Data::Sorting;
    
    $ary_ref = [ 18, 23, 5, 43, 56, 91, 64 ];
    sort_in_place( $ary_ref, sub { $_[0] % 42 } );
    
    $ary_ref = [ { 'rec_id'=>1, 'name'=>{'first'=>'Bob', 'last'=>'Jones'} },
    		 { 'rec_id'=>2, 'name'=>{'first'=>'Sue', 'last'=>'jones'} },
    		 { 'rec_id'=>3, 'name'=>{'first'=>'Al', 'last'=>'Macy'}   } ];
    sort_in_place( $ary_ref, 'name.last', 'name.first' );
    
    $Data::Sorting::ComparisonStyle = 'locale';
    sort_in_place( $ary_ref, 'name.last', 'name.first' );
    
    $Data::Sorting::ComparisonStyle = 'raw';
    sort_in_place( $ary_ref, 'name.last', 'name.first' );

=head1 Description

=head2 Sorting Syntax

=over 4

=item $ComparisonStyle

Should be one of 'simpletext', 'locale', or 'raw'.

=item sort_in_place( $array_ref, @sort_rules )

Sorts the contents of a referenced array using a list of sorting rules. Each rule should be either a DRef to get from each item, (L<Data::DRef>) or a function to be called on each item. If no sorting rules are provided, the values in the array are sorted on their own.

=back

=head1 This is Free Software

Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut
