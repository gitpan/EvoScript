### Number::Currency provides currency-appropriate formatting for numbers

### Interface
  # @ones, @tens, @thousands - Words to be localized
  # use_dollars();
  # $formatted_currency = pretty_dollars( $value_with_decimal_point );
  # $formatted_currency = cents_to_dollars( $pennies );
  # $formatted_currency = display($dollars, $cents);
  # $pennies = dollars_to_cents( $value_with_decimal_point );
  # ($dollars, $cents) = split_dollar($value_with_decimal_point)
  # ($dollars, $cents) = split_pennies( $pennies );
  # $value_with_decimal_point = pennies( $pennies );

### Change History
  # 1998-04-18 Added POD. -Jeremy
  # 1998-03-24 Corrected typos; most functions are not methods. -Del
  # 1998-03-17 Corrected typo in method call. -Del
  # 1997-11-17 Preliminary revised version. -Simon

package Number::Currency;

# Export on demand: roman unroman isroman
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( pretty_dollars pennies dollars_to_cents );

use Err::Debug;

# @ones, @tens, @thousands - Words to be localized
use vars qw( $places $symbol $separator );

use_dollars(); # US Dollars are the default (currently only) supported currency

# use_dollars();
sub use_dollars {
  $places = 2;
  $symbol = '$';
  $separator = '.';
}

# $formatted_currency = pretty_dollars( $value_with_decimal_point );
sub pretty_dollars {
  my $value = shift;
  $value =~ s/[^\d\.]//g;

  debug 'currency', 'pretty_dollars: $value =', $value;

  return display(split_dollar( $value ));
}

# $formatted_currency = cents_to_dollars( $pennies );
sub cents_to_dollars {
  my($value) = @_;
  $value = int($value);

  debug 'currency', 'cents_to_dollars: $value =', $value;
  
  return display(split_pennies( $value ));
}

# $formatted_currency = display($dollars, $cents);
sub display {
  my ($dollars, $cents) = @_;
  debug 'currency', 'display: $dollars =', $dollars, '$cents =', $cents;
  return ($symbol . Number::Separated::separated($dollars) . $separator . $cents);
}

# ($dollars, $cents) = split_dollar($value_with_decimal_point)
sub split_dollar {
  my $value = shift;
  my ($dollars, $cents) = split(/\./, $value, 2);
  $cents = substr($cents, 0, $places) . ('0' x ($places - length($cents)));
  $dollars ||= '0';

  debug 'currency', 'split_dollar: $value =', $value, '$dollars =', $dollars, '$cents =', $cents;

  return ($dollars, $cents);
}

# ($dollars, $cents) = split_pennies( $pennies );
sub split_pennies {
  my $value = shift;
  my($dollars, $cents) =
      (length("$value") > $places) ?
	  ( $value =~ /\A(?:(\d*)(\d{$places}))\Z/ ) : ( 0, $value );
  $cents = sprintf("%0${places}d", $cents) if (length($cents) < $places);
  ($dollars > 0) || ($dollars = '0');

  return ($dollars, $cents);
}

# $pennies = dollars_to_cents( $value_with_decimal_point );
sub dollars_to_cents {
  my $value = shift;
  $value =~ s/[^\d\.]//g;
  return join('', split_dollar($value) );
}

# $value_with_decimal_point = pennies( $pennies );
sub pennies {
  my($value) = @_;
  $value = int($value);
  return '0.00' unless ($value > 0);
  $value = ( ('0' x (3 - length($value))) . $value )
				      if(3 > length($value));
  $value =~ s/(..)$/.$1/;
  return $value;
}

1;

=pod

=head1 Number::Currency

Currency-appropriate formatting for numbers

=head1 Synopsis

  use Number::Currency qw( pretty_dollars );

  pretty_dollars( '12345.6' ) eq '$12,345.60';

=head1 Reference

=over 4

=item pretty_dollars( $value_with_decimal_point ) : $formatted_currency 

Returns a value with a dollar sign, comma separated groups and appropriate decimal values.

=item cents_to_dollars( $pennies ):  $formatted_currency

As above, but converts argument from an integer number of pennies.

=item display($dollars, $cents) : $formatted_currency

As above, but accepts a list of dollars and cents.

=item split_dollar($value_with_decimal_point) : ($dollars, $cents)

Accepts a dollar value (formatted or not) and returns a list of dollars and cents.

=item split_pennies( $pennies ) : ($dollars, $cents)

Accepts an integer ammount of pennies and returns a list of dollars and cents.

=item dollars_to_cents( $value_with_decimal_point ) : $pennies

Accepts a dollar value and returns an integer ammount of pennies.

=item pennies( $pennies ) : $value_with_decimal_point

=back

=head1 Caveats and Upcoming Changes

This module is fairly disorganized at the moment; the interface is likely to change in future versions.

=head1 This is Free Software

Copyright 1997, 1998 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut
