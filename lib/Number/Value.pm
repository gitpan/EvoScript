### Number::Value objects hold a numeric value and provide access methods

### OOP Interface
  # $number = number( $nval );
  # $nval = $number->value;
  # $text = $number->roman
  # $text = $number->bytes
  # $text = $number->pretty

### Usage Examples
  # number( 52441260 )->pretty eq '52,441,260'

### To Do:
  # figure out why english won't work for values one quadrillion and above
  # resolve 'and' vs. comma issue
  # support decimal places and fractions
  # check input for commaseparated

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Development by
  # M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-01-06 Renamed OOP package to Number::Value.
  # 1997-11-17 Split into sub-packages; new Text::Format and OOP interfaces -S.
  # 1997-06-23 Created original numbers package -JGB

package Number::Value;

use vars qw( $VERSION );
$VERSION = 1.00_1998_03_11;

use Number::Bytes 1.0;
use Number::Roman 1.0;
use Number::Words 1.0;

# Export: number
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( number );

### OOP Interface

# $number = number( $nval );
sub number {
  my $nval = shift;
  my $number = \$nval;
  bless $number, Number;
}

# $nval = $number->value;
sub value {
  my $number = shift;
  return $$number;
}

# $text = $number->roman
sub roman {
  my $number = shift;
  Number::Roman::roman( $number->value );
}

# $text = $number->bytes
sub bytes {
  my $number = shift;
  Number::Bytes::byte_format( $number->value );
}

# $text = $number->pretty
sub pretty {
  my $number = shift;
  Number::Separated::separated( $number->value );
}

1;  