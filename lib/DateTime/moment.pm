### MOMENT - a time on a day (or, a time und a day)

### Creators
  # $moment = Evo::datetime::moment->new();
  # $equivalent_moment = $moment->clone;
  # $moment = Evo::datetime::moment->new_from_date_and_time($date, $time);
  # $moment = current_moment();
  # $moment->set_current();
  # $moment = new_moment_from_value( $value );

### Member Access
  # $date = $moment->date;
  # $time = $moment->time;

### Spinoffs
  # $duration = $moment->duration_to_moment($other_moment);

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon	   M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 19970924 IntraNetics97 Version 1.00.000
  # 19970611 Cleanup.
  # 19970610 Created module. -Simon

package Evo::datetime::moment;

use integer;
use Evo::exception;

use Exporter;
@EXPORT = qw[ current_moment new_moment_from_value ];

### Creators

# $moment = Evo::datetime::moment->new();
sub new {
  my $package = shift;
  return $package->new_from_date_and_time ( Evo::datetime::date->new,
					    Evo::datetime::time->new );
}

# $moment = Evo::datetime::moment->new_from_date_and_time($date, $time);
sub new_from_date_and_time {
  my ($package, $date, $time) = @_;
  my $moment = { 'date' => $date, 'time' => $time };
  bless $moment, $package;
}

# $equivalent_moment = $moment->clone;
sub clone {
  my $moment = shift;
  my $package = ref $moment;
  return $package->new_from_date_and_time ( $moment->date->clone,
					    $moment->time->clone );
}

# $moment = current_moment();
sub current_moment {
  my $moment = Evo::datetime::moment->new;
  $moment->set_current;
  return $moment;
}

# $moment->set_current();
sub set_current {
  my ($moment) = @_;
  $moment->date->set_current;
  $moment->time->set_current;
}

# $moment = new_moment_from_value( $value );
  # $value can be just about any date and time format
sub new_moment_from_value {
  my ($value) = @_;
  my $moment = Evo::datetime::moment->new;
  
  $moment->date->set_from_scalar($value);
  $moment->time->set_from_scalar($value);
  
  return $moment;
}

### Member Access

# $date = $moment->date;
sub date {
  my ($moment, $value) = @_;
  if ($value) {
    $moment->{'date'} = $value;
  }
  return $moment->{'date'};
}

# $time = $moment->time;
sub time {
  my ($moment, $value) = @_;
  if ($value) {
    $moment->{'time'} = $value;
  }
  return $moment->{'time'};
}

### Spinoffs

# $duration = $moment->duration_to_moment($other_moment);
sub duration_to_moment {
  my ($moment, $other_moment) = @_;
  
  my $duration = $moment->date->duration_to_date($other_moment->date);
  my $timeoffset = $moment->time->duration_to_time($other_moment->time);
  
  $duration->add_duration($timeoffset);
  
  return $duration;
}

1;
