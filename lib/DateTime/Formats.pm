### DateTime::Formats provides a Text::Format intrface to date and time values.
  # 
  # Uses the following classes, defined other DateTime::* packages.
  # Duration - a length of time, measured in seconds
  # Times - a particular hour, minute, and second in a standard 24 hour day.
  # Dates - a particular year, month, and day, specifying a historical day
  # Moment - a particular time on a particular date
  # Periods - an earlier moment and a later moment
  # 
  # All of our numerical dow/moy indexes are 1 based.

### Formatter functions
  # $formatted = astime($value, $style);
  # Styles: hash	reference to hash with keys 'hour', 'minute', 'second'
  #         timestamp	890457284
  #         full	21:00:00
  #         24hr	21:00
  #         ampm	9:00pm
  #         short	9pm
  #
  # $formatted = asdate($value, $style);
  # Styles: hash	reference to hash with keys 'day', 'month', 'year'
  #         timestamp	890457284
  #         ymd 	19970101
  #         full	01/01/1997
  #         short	1/1/97
  #         long 	January 1, 1997
  #         complete 	Monday, January 1, 1997

### To Do
  # Use Class::Struct. Maybe use Time::tm.
  # Should remove limitations (by Unix datestamps) to the period 1970 - 2038.
  # Should create a moment which is a UDT, spawns date and time as needed.
  # Similarly, make date and time classes which are stored as a padded string

### Obsolete
  # @months = ( DateTime::Date->months );
  # @mons = ( DateTime::Date->mons );
  # @daynames = ( DateTime::Date->daysofweek) ;
  # sub num_days_in_month { DateTime::Date::days_in_month( @_ ); }
  # sub day_of_week { DateTime::Date::new_date_from_ymd( @_ )->dayofweek; }

### Copyright 1997 Evolution Online Systems, Inc.
  # M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 1998-01-22 Added complete format for dates.
  # 1998-01-06 Renamed this package DateTime::Formats; now uses Text::Format -S 
  # 1997-12-10 Moved to new source tree. -Jeremy
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-11 Working to integrate OOP code here.
  # 1997-06-10 Created OOP version.
  # 1997-03-27 Fixed a message that reported a time error instead of date.
  # 1997-02-01 Documentation cleanup, new two-year format for short years.
  # 1997-01-13 Created module from earlier date parsing/printing code. -Simon

package DateTime::Formats;

use Time::ParseDate;
use Time::Local;

use Text::PropertyList;

require Exporter;
@ISA = ('Exporter');
@EXPORT = qw[ asdate astime ];

use Text::Format;
Text::Format::add( 'asdate',   \&asdate );
Text::Format::add( 'astime',   \&astime );

use DateTime::Date;
use DateTime::Time;

# use datetime::duration;
# use datetime::moment;
# use datetime::period;

### Dates

sub asdate {
  my ($value, $style) = @_;
  
  my $date = DateTime::Date::new_date_from_value( $value );
  
  if ($date->isbogus) {
    warn "invalid date " . printablestring($value);
    return; 
  }
  
  # return $date if (not $style or $style =~ /hash/i);
  $style ||= 'short';
  
  return $date->short if ($style =~ /short/i);
  return $date->full if ($style =~ /full/i);
  return $date->yyyymmdd if ($style =~ /ymd/i);
  return $date->long if ($style =~ /long/i);
  return $date->complete if ($style =~ /complete/i);
  return $date->udt if ($style =~ /timestamp/i);
  
  warn "Date error: unknown date style " . &printablestring($style) . 
  return $date->full;
}

### Times

sub astime {
  my ($value, $style) = @_;
  
  my $time = DateTime::Time::new_time_from_value( $value );
  if ($time->isbogus) {
    warn "invalid time " . printablestring($value) . "\n";
    return; 
  }
  
  return $time if (not $style or $style =~ /hash/i);
  
  return $time->full if ($style =~ /full/i);
  return $time->military if ($style =~ /24hr/i);
  return $time->ampm if ($style =~ /ampm/i);
  return $time->short if ($style =~ /short/i);
  return $time->udt if ($style =~ /timestamp/i);
  
  warn "astime called with unknown time style " . printablestring($style);
  return $time->full;
}

1;