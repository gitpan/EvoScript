### DATE - a day in history

### Creators
  # $date = DateTime::Date->new();
  # $equivalent_date = $date->clone;
  # $date = current_date();
  # $date->set_current();
  # $date = new_date_from_ymd( $year, $month, $day );
  # $date = new_date_from_value( $value );
  # $date->set_from_scalar( $value )

### Value Access
  # $year = $date->year; or pass ($year) to set it
  # $month = $date->month; or pass ($month) to set it
  # $day = $date->day; or pass ($day) to set it
  # ($year, $month, $day) = $date->ymd; or pass ($year, $month, $day) to set
  # $udt = $date->udt; or pass ($udt) to set it; UDT means Unix DateTime

### Calendar Features
  # $daysinmonth = $date->num_days_in_month;
  # $date->make_day_valid;
  # $flag = $date->check_day_bounds;
  # $dow_from_one_to_seven = $date->dayofweek; #!# or pass ($flag), opt -1/0/+1
  # $weekofyear = $date->weekofyear; #!# or pass ($weekofyear) to set
  # $holidayname_or_zero = $date->isholiday;  #!# Need to build a holiday table
  # $flag = $date->isweekend;  #!# or pass ($flag), add -1/0/+1 for direction
  # $flag = $date->isbusinessday; #!# or pass ($flag), add -1/0/+1 for directn
  # ($nth, $dayofweek) = $date->nthweekday; or pass ($nth, $dayofweek) to set
  # $flag = $date->firstdayofmonth; or pass ($flag) to set it
  # $flag = $date->lastdayofmonth; or pass ($flag) to set it

### Display Output
  # $month = $date->month_name;
  # @names_of_months = months();
  # $short_name_for_month = $date->mon;
  # @short_names_of_months = mons();
  # $dayofweek = $date->dayofweek;
  # @daysofweek = daysofweek();
  # $zero_padded_string = $date->zero_padded( $value, $field_size || 2 );
  # $four_digit_year = $date->yyyy;
  # $two_digit_month = $date->mm;
  # $two_digit_day = $date->dd;
  # $yyyymmdd = $date->yyyymmdd;
  # $m/d/year = $date->full;
  # $m/d/yy = $date->short;
  # $monthdaycommayear = $date->long;
  # $dowcommamonthdaycommayear = $date->complete;

### Spinoffs
  # $duration = $date->duration_to_date($other_date);
  # $julianday = $date->julianday; or pass ($julianday) to set
  #   A julian day is represented as a number of actual historical days since
  #   some very long ago day. Therefore, you can add a number of days and get
  #   back the correct day, compensating for leap years, Gregorianism, etc.

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon	   M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 1998-05-14 Added expressions to set_from_scalar to accept formats
  #            "dd Month yy", "Mon yyyy dd", and "yyyy Mon dd". -Dan
  # 1998-05-14 Modified set_from_scalar to accept date format yyyy mm dd. -Dan
  # 1998-01-22 Added complete format for dates.
  # 1997-12-10 Moved to new source tree. -Jeremy
  # 19970930 Fixed parsing of m/yy dates (we pick the first day of that month).
  # 19970924 IntraNetics97 Version 1.00.000
  # 19970611 Cleanup.
  # 19970610 Created module. -Simon

package DateTime::Date;

use integer;

use Time::ParseDate;
use Time::Local;
use Time::JulianDay;

use Exporter;
push @ISA, qw( Exporter );
@EXPORT = qw( current_date new_date_from_value );

### Creators

# $date = DateTime::Date->new();
sub new {
  my ($package) = @_;
  my $date = { 'year' => 1970, 'month' => 1, 'day' => 1 };
  bless $date, $package;
}

# $equivalent_date = $date->clone;
sub clone {
  my $date = shift;
  my $package = ref $date;
  my $clone = $package->new;
  $clone->ymd( $date->ymd );
  return $clone;
}

# $date = current_date();
sub current_date {
  my $date = DateTime::Date->new;
  $date->set_current;
  return $date;
}

# $date->set_current();
sub set_current {
  my $date = shift;
  $date->udt( time() );
}

# $date = new_date_from_ymd( $year, $month, $day );
sub new_date_from_ymd {
  my $date = DateTime::Date->new;
  $date->ymd( @_ );
  return $date;
}

# $date = new_date_from_value( $value );
sub new_date_from_value {
  my $date = DateTime::Date->new;
  $date->set_from_scalar( @_ );
  return $date;
}

# $date->set_from_scalar( $value )
  # $value can be just about any date format
sub set_from_scalar {
  my ($date, $value) = @_;
  my %months = qw(
    january	1
    february	2
    march	3
    april	4
    june	6
    july	7
    august	8
    september	9
    october	10
    november	11
    december	12
  );
  my %short_months = qw(
    jan	1
    feb	2
    mar	3
    apr	4
    may	5
    jun	6
    jul	7
    aug	8
    sep	9
    oct	10
    nov	11
    dec	12
  );

  # warn "scalar is '$value'"; 
  if ( ref $value eq 'HASH' ) {
    $date->ymd($value->{'year'},$value->{'month'},$value->{'day'});
  } elsif ($value =~ /^\s*(\d{1,2})\D(\d{1,2})\s*$/) {
    my ($month, $day) = ($1, $2);
    $date->set_current;
    my $year = $date->year;
    # Fix for mm/yy format
    if ( $day > 50 ) { $year = $day + 1900; $day = 1; }
    $date->ymd( $year, $month, $day );
  } elsif ($value =~ /^\s*(\d{1,2})\D(\d{1,2})\D(\d{2})\s*$/) {
    my ($year, $month, $day) = ( $3, $1, $2 );
    $year += 1900;
    $year += 100 if ( $year < 1950 );
    $date->ymd($year, $month, $day);
  } elsif ($value =~ /^\s*(\d{1,2})\D(\d{1,2})\D(\d{4})\s*$/) {
    my ($year, $month, $day) = ( $3, $1, $2 );
    $date->ymd($year, $month, $day);
  } elsif ($value =~ /^\s*(?=1|2)(\d{4})\D?(\d{2})\D?(\d{2})\s*$/) {
    my ($year, $month, $day) = ($1, $2, $3);
    $date->ymd($year, $month, $day);
  } elsif ($value =~ /^\s*(\d{4})[\D\W]?(\w{3})[\D\W]?(\d{1,2})\s*$/){
    my ($year, $day) = ($1, $3);
    my $month = $short_months{lc($2)} if $short_months{lc($2)};
    $date->ymd($year, $month, $day);
  } elsif ($value =~ /^\s*(\w{3})[\D\W]?(\d{4})[\D\W]?(\d{1,2})\s*$/) {
    my ($year, $day) = ($2, $3);
    my $month = $short_months{lc($1)} if $short_months{lc($1)};
    $date->ymd($year, $month, $day);
  } elsif ($value =~ /^\s*(\d{1,2})[\D\W]?(\w{4}\w*)[\D\W]?(\d{2})\s*$/) {
    my ($year, $day) = ($3, $1);
    my $month = $months{lc($2)} if $months{lc($2)};
    $year += 1900;
    $year += 100 if ( $year < 1950 );
    $date->ymd($year, $month, $day);
  } elsif ($value =~ /^\s*(\d{9,10})\s*$/i) {
    $date->udt($value);
  } elsif ($value =~ /today/i) {
    $date->set_current;
  } else {
    my $udt = Time::ParseDate::parsedate($value, 'DATE_REQUIRED' => 1);
    if ($udt) {   
      $date->udt($udt);
    } else {
      $date->isbogus(1);
    }
  }
  $date->bogus_date( $value ) if $date->isbogus();
  return;
}

sub bogus_date {
  my $date = shift;
  $date->{'bogus_date'} = shift if (scalar @_ ) ;
  return $date->{'bogus_date'};
}

sub isbogus {
  my $date = shift;
  $date->{'isbogus'} = shift if (scalar @_);
  return $date->{'isbogus'};
}

### Value Access

# $year = $date->year; or pass ($year) to set it
sub year {
  my $date = shift;
  if (scalar @_) {
    my $value = shift;
    if ( $value < 1000 or $value > 3000) {
      warn "invalid year $value";
      $value = 1900;
    }
    $date->{'year'} = $value;
    $date->make_day_valid;
  }
  return $date->{'year'} - 0;
}

# $month = $date->month; or pass ($month) to set it
sub month {
  my $date = shift;
  if (scalar @_) {
    my $value = shift;
    if ( $value < 1 ) {
      $date->year( $date->year - 1 );
      $date->month( 12 + $value );
      $date->{'wrapped'} = 1;
    } elsif( $value > 12) {
      $date->year( $date->year + 1 );
      $date->month( $value - 12 );
      $date->{'wrapped'} = 1;
    } else{
      $date->{'month'} = $value;
      $date->make_day_valid;
    }
  }
  return $date->{'month'} - 0;
}

# $day = $date->day; or pass ($day) to set it
sub day {
  my $date = shift;
  if (scalar @_) {
    my $value = shift;
    if ( $value < 1 ) {
      $date->month( $date->month - 1 );
      $date->day( $date->num_days_in_month + $value );
      $date->{'wrapped'} = 1;
    } elsif ($value > $date->num_days_in_month) {
      $value = $value - $date->num_days_in_month ;
      $date->month( $date->month + 1 );
      $date->day( $value );
      $date->{'wrapped'} = 1;
    } else{
      $date->{'day'} = $value;
    }
  }
  return $date->{'day'} - 0;
}

# ($year, $month, $day) = $date->ymd; or pass ($year, $month, $day) to set 'em
sub ymd {
  my $date = shift;
  if (scalar @_) {
    $date->year ( shift );
    $date->month ( shift );
    $date->day ( shift );
  } 
  return ( $date->year, $date->month, $date->day );
}

# $udt = $date->udt; or pass ($udt) to set it, oh, and udt means Unix DateTime
sub udt {
  my $date = shift;
  if (scalar @_) {
    my $udt = shift;
    my ($x, $y, $z, $day, $month, $year) = localtime($udt);
    $month ++;
    $year += 1900;
    $date->ymd($year, $month, $day);
  }
  my ($year, $month, $day) = $date->ymd;
  $month --;
  $year -= 1900;
  return timelocal(0, 0, 0, $day, $month, $year);
}

### Calendar Features

# $daysinmonth = $date->num_days_in_month;
sub num_days_in_month {
  my $date = shift;
  
  my ($year, $month, $day) = $date->ymd;
  return days_in_month($year, $month);
}

sub days_in_month {
  my ($year, $month) = @_;
  if ($month == 2) {
    # Maybe this matches the english better?
    # unless (($year % 4 != 0) || ($year % 100 == 0 && $year % 400 != 0)) {
    # if (($year % 4 == 0) && ! ($year % 100 == 0 && $year % 400 != 0)) {
    if (($year % 4 == 0) && ($year % 400 == 0 || $year % 100 != 0)) {
      return 29;
    } else {
      return 28;
    }
  } else {
    my @maxdays = (0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    return $maxdays[$month];
  }
}

# $date->make_day_valid;
sub make_day_valid {
  my $date = shift;
  $date->day( $date->num_days_in_month ) if $date->day_out_of_bounds;
}

# $flag = $date->check_day_bounds;
sub day_out_of_bounds {
  my $date = shift;
  return ($date->day > $date->num_days_in_month) ? 1 : 0;
}

# $dow_from_one_to_seven = $date->dayofweek; #!# or pass ($flag), opt -1/0/+1
sub dayofweek {
  my $date = shift;
  return (localtime($date->udt))[6] || 7;
}

# $weekofyear = $date->weekofyear; #!# or pass ($weekofyear) to set
sub weekofyear {
  my $date = shift;
  # !
}

# $holidayname_or_zero = $date->isholiday;  #!# Need to build a holiday table
sub isholiday {
  my $date = shift;
  return 0;
}

# $flag = $date->isweekend;  #!# or pass ($flag), add -1/0/+1 for direction
sub isweekend {
  my $date = shift;
  return ( $date->dow == 6 or $date->dow == 7 ) ? 1 : 0;
}

# $flag = $date->isbusinessday; #!# or pass ($flag), add -1/0/+1 for direction
sub isbusinessday {
  my $date = shift;
  return ! ( $date->isweekend or $date->isholiday );
}

# ($nth, $dayofweek) = $date->nthweekday; or pass ($nth, $dayofweek) to set
sub nthweekday {
  my $date = shift;
  
  if (scalar @_) {
    my ($nth, $dayofweek) = @_;
    $date->day( 1 + (7 * $nth) );
    $date->dayofweek( $dayofweek, 1 );
  }
  
  my $nth = ( $date->day / 7 ) + 1;
  my $dayofweek = $date->dayofweek;
  return ($nth, $dayofweek);
}

# $flag = $date->firstdayofmonth; or pass ($flag) to set it
sub firstdayofmonth {
  my $date = shift;
  if (scalar @_) {
    if (shift) {
      $date->day(1);
    } else {
      $date->day(2) if ( $date->day == 1 );
    }
  }
  return ( $date->day == 1 ) ? 1 : 0;
}

# $flag = $date->lastdayofmonth; or pass ($flag) to set it
sub lastdayofmonth {
  my $date = shift;
  my $daysinmonth = $date->num_days_in_month;
  if (scalar @_) {
    if (shift) {
      $date->day( $daysinmonth );
    } else {
      $date->day($daysinmonth - 1) if ( $date->day == $daysinmonth );
    }
  }
  return ( $date->day == $daysinmonth ) ? 1 : 0;
}

### Offsets

# $prev_date = $date->prev_day;
sub prev_day {
  my $date = shift;
  my $clone = $date->clone;
  $clone->day( $date->day - 1 );
  return $clone;
}

# $next_date = $date->next_day;
sub next_day {
  my $date = shift;
  my $clone = $date->clone;
  $clone->day( $date->day + 1 );
  return $clone;
}

# $newday = $date->first_day_in_month;
sub first_day_in_month {
  my $date = shift;
  my $clone = $date->clone;
  $clone->day( 1 );
  return $clone;
}

# $newday = $date->last_day_in_month;
sub last_day_in_month {
  my $date = shift;
  my $clone = $date->clone;
  $clone->day( $date->num_days_in_month );
  return $clone;
}

### Display Output

# $month = $date->month_name;
sub month_name {
  my $date = shift;
  return ( $date->months )[ $date->month ];
}

# @names_of_months = months();
sub months {
  return ( undef, qw[ January February March April May June 
		      July August September October November December ] );
}

# $short_name_for_month = $date->mon;
sub mon {
  my $date = shift;
  return ( $date->mons )[ $date->month ];
}

# @short_names_of_months = mons();
sub mons {
  return ( undef, qw[ Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ] );
}

# $dayofweek = $date->nameofweekday;
sub nameofweekday {
  my $date = shift;
  return ( $date->daysofweek )[ $date->dayofweek ];
}

# @daysofweek = daysofweek();
sub daysofweek {
  return (undef, qw[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]);
}

# $zero_padded_string = $date->zero_padded( $value, $field_size || 2 );
sub zero_padded {
  my ($date, $value, $field_size) = @_;
  $value += 0;
  $field_size ||= 2;
  return '0' x ($field_size - length( $value ) ) . $value;
}

# $four_digit_year = $date->yyyy;
sub yyyy {
  my $date = shift;
  return $date->zero_padded( $date->year, 4 );
}

# $two_digit_month = $date->mm;
sub mm {
  my $date = shift;
  return $date->zero_padded( $date->month );
}

# $two_digit_day = $date->dd;
sub dd {
  my $date = shift;
  return $date->zero_padded( $date->day );
}

# $yyyymmdd = $date->yyyymmdd;
sub yyyymmdd {
  my $date = shift;
  return $date->yyyy . $date->mm . $date->dd ;
}

# $m/d/year = $date->full;
sub full {
  my $date = shift;
  return $date->month . '/' . $date->day . '/' . $date->year;
}

# $m/$d/yy = $date->short;
sub short {
  my $date = shift;
  my ($year, $month, $day) = $date->ymd;
  $year = substr($year,2,4) if ($year > 1950 and $year < 2050);
  return "$month/$day/$year";
}

# $monthdaycommayear = $date->long;
sub long {
  my $date = shift;
  return $date->month_name . ' ' . $date->day . ', ' . $date->year;
}

# $dowcommamonthdaycommayear = $date->complete;
sub complete {
  my $date = shift;
  
  return $date->nameofweekday . ', ' . 
		    $date->month_name . ' ' . $date->day . ', ' . $date->year;
}


### Spinoffs

# $duration = $date->duration_to_date($other_date);
sub duration_to_date {
  my ($date, $other_date) = @_;
  
  my $days = $other_date->julian_day -  $date->julian_day;
  
  return DateTime::Duration->new_from_days($days);
}

# $julianday = $date->julianday; or pass ($julianday) to set 
  # A julian day is represented as a number of actual historical days since
  # some very long ago day. Therefore, you can add a number of days and get
  # back the correct day, compensating for leap years, Gregorianism, etc.
sub julianday {
  my $date = shift;
  $date->ymd( inverse_julian_day( shift ) ) if (scalar @_);
  return julian_day( $date->ymd );
}

1;
=pod

=head1 DateTime::Date

An OO implementation of dates.

=head1 Synopsis

  use DateTime::Date qw( new_date_from_value new_date_from_ymd );
  
  $date = new_date_from_value( 'today' );


=head1 Reference

=head2 Creators

=over 4

=item DateTime::Date->new() : $date

Returns a date object with a value of January 1st, 1970.

=item $date->clone : $equivalent_date

Creates an identical date object

=item current_date() : $current_date

Creates a date object with a value of current date.

=item $date->set_current();

Sets the value of a date object to current date.

=item $date = new_date_from_ymd( $year, $month, $day );

A date object from year month and day values.

=item $date = new_date_from_value( $value );

creates a date object from a string in any of a number of possible date formats, including: mm/dd (year is set to current), mm/yy (day is set to 1), mm/dd/yy(yy), Unix Timestamp, text based values as implemented by Time::ParseDate. A reference to a hash of year, month and day will also be accepted.

=item $date->set_from_scalar( $value )

Set a date from a value (parsed as above).

=back

=head2 Value Access

=over 4

=item $date->year() : $year

Returns the year value. Pass $year to set value.

=item $date->month : $month

Returns the month value. Pass $month to set value.

=item $date->day : $day

Returns day value. Pass $day to set value

=item $date->ymd : ($year, $month, $day)

Returns a list of year, month and day values. Pass a list to set.

=item $date->udt : $unix_date_time

Retuns a date value in seconds since 1970. Pass a timestamp to set.

=back

=head2 Calendar Features

=over 4

=item $daysinmonth = $date->num_days_in_month;

The number of days in $date's month.

=item $date->make_day_valid;

Handle invalid day values. September 31st becomes October 1st.

=item $date->day_out_of_bounds : $flag

Returns a true value if the value of day exceeds the total days in the month.

=item $date->dayofweek : $dow_from_one_to_seven

Returns the day of the week numerically where Monday = 1, Tuesday = 2, etc.

=item $date->isweekend : $flag

Returns a true value if the date falls on a weekend (Sat,Sun).

=item $date->isbusinessday : $flag

Returns a true value if the date is a business day (Mon-Fri).

=item $date->nthweekday : ($nth, $dayofweek)

Returns a list of $nth ( the ammount of times the day of the week has occured in the current month) and $dayofweek (as per the function of the same name). Pass ( $nth, $dayofweek ) to set; Example:

  $date->( 3, 1 );

Sets $date to the third monday of it's month.

=item $date->firstdayofmonth : $flag

Returns true if the date is the day is the first of the month. Pass a flag to set date to the first day of the month;

=item $date->lastdayofmonth : $flag

Returns true if the date is the day is the last of the month. Pass a flag to set date to the last day of the month;

=back

=head2 Display Output

=over 4

=item $month = $date->month_name;

Returns the name of the month.

=item @names_of_months = months();

Returns a list of month names

=item $short_name_for_month = $date->mon;

Returns the short name for the current month. e.g. "Mar" for "March".

=item @short_names_of_months = mons();

Returns a list of Jan, Feb, Mar, etc. 

=item $dayofweek = $date->nameofweekday;

Returns the name of the day of the week that date falls on.

=item @daysofweek = daysofweek();

Returns a list of week day names, starting with Monday.

=item $four_digit_year = $date->yyyy;

e.g. '1977'

=item $two_digit_month = $date->mm;

e.g. '05'

=item $two_digit_day = $date->dd;

e.g. '30'

=item $yyyymmdd = $date->yyyymmdd;

e.g. '19770530'

=item $m/d/year = $date->full;

e.g. '5/30/1977'

=item $m/d/yy = $date->short;

e.g. '5/30/77'

=item $monthdaycommayear = $date->long;

e.g. 'May 30, 1977'

=back

=head1 Caveats and Upcoming Changes

Year 2038 bug - Some calculations rely on the system clock and hte thirtytwo bit date/time format.

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut