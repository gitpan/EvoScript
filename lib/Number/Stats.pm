### Number::Stats provides basic math manipulations for groups of numbers

### Change History
  # 1997-11-24 Moved into the new Number:: hierachy.
  # 1997-11-0? Created. -Simon

package Number::Stats;

use vars qw( $VERSION );
$VERSION = 1.00_1998_03_11;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( maximum minimum total average );

# $n = maximum( @numbers );
sub maximum {
  my $max = 0;
  foreach ( @_ ) { $max = $_ if ( ! $max or $max < $_ ); } 
  return $max;
}

# $n = minimum( @numbers );
sub minimum {
  my $min = 0;
  foreach ( @_ ) { $min = $_ if ( ! $min or $min > $_ ); } 
  return $min;
}

# $n = total( @numbers );
sub total {
  my $total = 0;
  foreach ( @_ ) { $total += $_  } 
  return $total;
}

# $n = average( @numbers );
sub average {
  return total( @_ ) / scalar(@_);
}

1;

=pod

=head1 Number::Stats

Basic math manipulations for groups of numbers.

=head1 Synopsis

    use Number::Stats( maximum minimum total average );

    @numbers = (1, 2, 3, 4, 5);

    maximum( @numbers ) == 5;
    minimum( @numbers ) == 1;
    average( @numbers ) == 3;
    total( @numbers ) == 15;


=head1 Reference

=over 4

=item maximum( @numbers )  : $n

Returns the highest value in @numbers.

=item minimum( @numbers )  : $n

Returns the lowest value in @numbers.

=item total( @numbers )  : $n

Returns the sum of each value in @numbers

=item average( @numbers )  : $n

Returns the average of all values in @numbers

=back

=head1 Caveats and Upcoming Changes

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut