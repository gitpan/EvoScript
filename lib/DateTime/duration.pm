### DURATION - a length of time, in seconds

### Creators
  # $duration = Evo::datetime::duration->new;
  # $duration = Evo::datetime::duration->new_from_seconds($plusorminus_secs);
  # $duration = Evo::datetime::duration->new_from_days($days);
  # $equivalent_duration = $duration->clone;

### Value Access
  # $numberofseconds = $duration->seconds; or pass ($seconds) to set
  # $numberofdays = $duration->days; or pass ($days) to set
  # ($years, $days, $hours, $minutes, $seconds, $backwards) = $duration->ydhms;
  # $duration->add_duration($other_duration);

### Display
  # $readable_string = $duration->english;
  # $item,item,anditem = join_with_commas_and_and( @items );

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon	   M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 19970924 IntraNetics97 Version 1.00.000
  # 19970611 Cleanup.
  # 19970610 Created module. -Simon

package Evo::datetime::duration;

use integer;

### Creators

# $duration = Evo::datetime::duration->new;
sub new {
  my ($package) = @_;
  my $duration = 0;
  bless \$duration, $package;
}

# $equivalent_duration = $duration->clone;
sub clone {
  my $duration = shift;
  my $package = ref $duration;
  my $clone = $package->new;
  $clone->seconds( $duration->seconds );
}

# $duration = Evo::datetime::duration->new_from_seconds($plusorminus_secs);
sub new_from_seconds {
  my ($package, $seconds) = @_;
  my $duration = $package->new;
  $duration->seconds($seconds);
}

# $duration = Evo::datetime::duration->new_from_days($days);
sub new_from_days {
  my ($package, $days) = @_;
  my $duration = $package->new;
  $duration->days($seconds);
}

### Value Access

# $numberofseconds = $duration->seconds; or pass ($seconds) to set
sub seconds {
  my ($duration, $value) = @_;
  $$duration = $value if (defined $value);
  return $$duration;
}

# $numberofdays = $duration->days; or pass ($days) to set
sub days {
  my ($duration, $value) = @_;
  $$duration = ($value * 86400) if (defined $value);
  return $$duration / 86400;
}

# ($years, $days, $hours, $minutes, $seconds, $backwards) = $duration->ydhms;
sub ydhms {
  my ($duration) = @_;
  
  my $seconds = $duration->seconds;
  
  my $backwards;
  if ( $seconds < 0 ) {
    $backwards ++;
    $seconds *= -1; 
  }
  
  my $years = $seconds / 31536000;
  $seconds -= $years * 31536000;
  
  my $days = $seconds / 86400;
  $seconds -= $days * 86400;
  
  my $hours = $seconds / 3600;
  $seconds -= $hours * 3600;
  
  my $minutes = $seconds / 60;
  $seconds -= $hours * 3600;
  
  return ($years, $days, $hours, $minutes, $seconds, $backwards);
}

# $duration->add_duration($other_duration);
sub add_duration {
  my ($duration, $other_duration) = @_;
  $duration->seconds( $duration->seconds + $other_duration->seconds );
}

### Display

# $readable_string = $duration->english;
sub english {
  my ($duration) = @_;
  
  my ($years, $days, $hours, $minutes, $seconds, $back) = $duration->ydhms;
  
  my @results;
  push @results, "$years years" if ($years);
  push @results, "$days days" if ($days);
  push @results, "$hours hours" if ($hours);
  push @results, "$minutes minutes" if ($minutes);
  push @results, "$seconds seconds" if ($seconds or not scalar @results);
  
  return join_with_commas_and_and(@results) . ( $back ? ' in the past' : '' );
}

# $item,item,anditem = join_with_commas_and_and( @items );
sub join_with_commas_and_and {
  my (@items) = @_;
  
  my $count = scalar @items;
  if ( ! $count ) {
    return;
  } elsif ( $count == 1 ) {
    return $items[0];
  } elsif ( $count == 2 ) {
    return $items[0] . ' and ' . $items[1];
  } else {
    my $final_element = pop @results;
    my $results = join ', ', @results;
    return $results . ', and ' . $final_element;
  }
}

1;
