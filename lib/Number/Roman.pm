### Number::Roman provides functions to convert to and from roman numerals.

### Interface
  # Export on demand: roman unroman isroman
  # %ones, %fives - Roman characters for 1 and 5 of each scale, 1 .. 1000
  # $formatted = roman( $number );
  # $n = unroman( $roman );
  # $flag = isroman( $value );

### Usage Examples
  # roman( 42 ) eq 'XLII'
  # roman( 42, 'lc' ) eq 'xlii'
  # unroman( 'xlii' ) == 42 

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License
  # Derived from code developed by OZAWA Sakuro and released to CPAN.

### Change History
  # 1997-11-17 Split this into several packages. -Simon
  # 1997-06-23 Created original numbers package -JGB

package Number::Roman;

use vars qw( $VERSION );
$VERSION = 1.00_1998_03_11;

# Export on demand: roman unroman isroman
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( roman unroman isroman );

# %ones, %fives - Roman characters for 1 and 5 of each scale, 1 .. 1000
use vars qw( @scales %ones %fives %unroman );

@scales = ( 1, 10, 100, 1000 );
@ones{ @scales } = ( 'I', 'X', 'C', 'M' );
@fives{ @scales } = ( 'V', 'L', 'D', 'MMMMM' );
%unroman = map { $ones{$_} => $_, $fives{$_} => $_*5 } @scales;

# $formatted = roman( $number );
# $lowercase = roman( $number, 'lc' );
sub roman {
  my $value = shift;
  my $opt = shift;
  warn "in roman $value $opt \n";
  return undef unless ( 0 < $value and $value < 4000 );
  my $roman; 	# value to return
  my $x;	# digit cary
  my $scale;
  foreach $scale (reverse @scales) {
    my $digit = int($value / $scale);
    if (1 <= $digit and $digit <= 3) {
      $roman .= $ones{ $scale } x $digit;
    } elsif ($digit == 4) {
      $roman .= $ones{ $scale } . $fives{ $scale };
    } elsif ($digit == 5) {
      $roman .= $fives{ $scale };
    } elsif (6 <= $digit and $digit <= 8) {
      $roman .= $fives{ $scale } . $ones{ $scale } x ($digit - 5);
    } elsif ($digit == 9) {
      $roman .= $ones{ $scale } . $x;
    }
    $value -= $digit * $scale;
    $x = $ones{ $scale };
  }
  return (defined $opt and $opt =~ /lc/i) ? lc( $roman ) : $roman ;
}

# $n = unroman( $roman );
sub unroman {
  my $value = lc( shift );
  return undef unless ( isroman($value) );
  my $last_digit = $scales[-1];
  my($number, $letter);
  foreach $letter (split(//, uc $value)) {
    my($digit) = $unroman{$letter};
    $number -= 2 * $last_digit if $last_digit < $digit;
    $number += ($last_digit = $digit);
  }
  return $number;
}

# $flag = isroman( $value );
sub isroman {
  my $value = shift;
  $value ne '' and $value =~ /\A(?: M{0,3})
				(?: D?C{0,3} | C[DM])
				(?: L?X{0,3} | X[LC])
				(?: V?I{0,3} | I[VX])\Z/ix;
}

1;

=head1 Number::Roman

Functions to convert to and from Roman Numbers

=head1 Synopsis

    use Number::Roman qw( roman unroman isroman );

    roman( 42 ) eq 'XLII'
    roman( 42, 'lc' ) eq 'xlii'
    unroman( 'xlii' ) == 42 


=head1 Reference

=over 4

=item roman( $number ) : $roman_numerals

Returns the Roman equivalent of an integer. Pass 'lc' as a second argument for lowercase Roman numerals.

=item unroman( $roman ) : $n

Returns a numeric equivalent of a roman numeral.

=item isroman( $value ) : $flag

Returns a true value if $value is a valid roman numeral.

=item %ones, %fives

Package variables containing Roman characters for 1 and 5 of each scale, 1 .. 1000.

=back

=head1 Caveats and Upcoming Changes

This module differs only slightly from Ozawa Sakuro's Roman module. The below declarations should suffice to provide the old interface.

    sub Roman::Roman   { Number::Roman::roman  (shift)       }
    sub Roman::roman   { Number::Roman::roman  (shift, 'lc') }
    sub Roman::arabic  { Number::Roman::unroman(shift)       }
    sub Roman::isroman { Number::Roman::isroman(shift)       }

=head1 This is Free Software

Copyright 1997, 1998 Evolution Online Systems, Inc.
Derived from code developed by Ozawa Sakuro and released to CPAN.

You can use this software under the same terms as Perl itself.

=cut