### PERIOD - two moments

### Creators
  # $period = Evo::datetime::period->new();
  # $period = Evo::datetime::period->new_from_moments( $start, $end );
  # $equivalent_period = $period->clone;

### Member Access
  # $start = $moment->start;
  # $end = $moment->end;

### Create Spinoffs
  # $duration = $period->duration;

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon	   M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 19970924 IntraNetics97 Version 1.00.000
  # 19970611 Cleanup.
  # 19970610 Created module. -Simon

package Evo::datetime::period;

use integer;
use Evo::exception;

### Creators

# $period = Evo::datetime::period->new();
sub new {
  my ($package) = @_;
  $package->new_from_moments( Evo::datetime::moment->new, 
			      Evo::datetime::moment->new );
}

# $period = Evo::datetime::period->new_from_moments( $start, $end );
sub new_from_moments {
  my ($package, $start, $end) = @_;
  my $period = { 'start' => $start, 'end' => $end };
  bless $period, $package;
}

# $equivalent_period = $period->clone;
sub clone {
  my $period = shift;
  my $package = ref $period;
  return $package->new_from_moments ( $moment->start->clone,
					    $moment->end->clone );
}

### Member Access

# $start = $moment->start;
sub start {
  my ($moment, $value) = @_;
  if ($value) {
    $moment->{'start'} = $value;
  }
  return $moment->{'start'};
}

# $end = $moment->end;
sub end {
  my ($moment, $value) = @_;
  if ($value) {
    $moment->{'end'} = $value;
  }
  return $moment->{'end'};
}

### Create Spinoffs

# $duration = $period->duration;
sub duration {
  my ($period) = @_;
  
  return $period->start->duration_to_moment($period->end);
}

1;
