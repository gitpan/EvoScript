### TIME - a time of day

### Create / Init
  # $time = DateTime::time->new();
  # $equivalent_time = $time->clone;
  # $time = current_time();
  # $time->set_current();
  # $time = new_time_from_value( $value );
  # $time->set_from_scalar( $value ); where value is just about anything timish

### Value Access
  # $hour = $time->hour; or pass ($hour) to set it
  # $minute = $time->minute; or pass ($minute) to set it
  # $second = $time->second; or pass ($second) to set it
  # ($hour, $minute, $second) = $time->hms; or pass ($hour, $minute, $second)
  # ($twelvehour, $ampm) = $time->twelvehour; or pass ($twelvehour, $ampm)
  # ($hour, $minute, $second, $ampm) = $time->hms_ampm; or pass the same to set
  # $udt = $time->udt; or pass ($udt) to set it

### Display
  # $zero_padded_string = $time->zero_padded( $value, $field_size || 2 );
  # $two_digit_hours = $time->hh;
  # $two_digit_minutes = $time->mm;
  # $two_digit_seconds = $time->ss;
  # $hh:mm:ss = $time->full;
  # $hh:mm(:ss) = $time->military;
  # $h:mm(:ss)a/p = $time->ampm;
  # $h(:mm:ss)a/p = $time->short;

### Spinoffs
  # $duration = $time->duration_to_time($other_time);

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon	   M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 1998-05-20 set_from_scalar now rejects minutes higher than 59. -Dan
  # 1998-05-05 set_from_scalar modified to accept single or double digit
  #            entries. -Dan
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-11 Cleanup.
  # 1997-06-10 Created module. -Simon

package DateTime::Time;

use integer;
use Time::ParseDate;
use Time::Local;

use Exporter;
push @ISA, qw( Exporter );
@EXPORT = qw[ current_time new_time_from_value ];

### Create / Init

# $time = DateTime::Time->new();
sub new {
  my ($package) = @_;
  my $time = { 'hour' => 0, 'minute' => 0, 'second' => 0 };
  bless $time, $package;
}

# $equivalent_time = $time->clone;
sub clone {
  my $time = shift;
  my $package = ref $time;
  my $clone = $package->new;
  $clone->hms( $time->hms );
}

# $time = current_time();
sub current_time {
  my $time = DateTime::Time->new;
  $time->set_current;
  return $time;
}

# $time->set_current();
sub set_current {
  my $time = shift;
  $time->udt( time() );
}

# $time = new_time_from_value( $value );
  # $value can be just about any time format
sub new_time_from_value {
  my ($value) = @_;
  my $time = DateTime::Time->new;
  $time->set_from_scalar($value);
  return $time;
}

# $time->set_from_scalar( $value ); where $value is just about anything timish
sub set_from_scalar {
  my ($time, $value) = @_;
  
  if ( ! $value) {
    $time->isbogus(1);
  } elsif ( ref $value eq 'HASH' ) {
    $time->hms( $value->{'hour'}, $value->{'minute'}, $value->{'second'} );
  } elsif ($value =~ /\A\s*(\d{2})\D(\d{2})\D(\d{2})\s*\Z/i) {
    $time->hms($1, $2, $3);
  } elsif ($value =~ /\A\s*(\d{1,2})\D(\d{1,2})(?:\D(\d{1,2}))?(?:\s*(am?|pm?))\s*\Z/i) {
    $time->hms_ampm($1, $2, $3, $4);
  } elsif ($value =~ /^\s*(\d{2})(\d{2})(\d{2})?(?:\s*(am?|pm?))?\s*$/i) {
    $time->hms_ampm($1, $2, $3, $4);
  } elsif ($value =~ /^\s*(\d{9,10})\s*$/i) {
    $time->udt($value);
  } elsif ($value =~ /^\s*(\d{1,2})\s*(am?|pm?)?\s*$/i) {
    my ($h, $ampm) = ($1, $2);
    $time->hms_ampm($h,0,0,$ampm);
  } else {
    my $udt = Time::ParseDate::parsedate($value, 'TIME_REQUIRED' => 1);
    # warn "UDT is $udt \n";
    if ($udt) {   
      $time->udt($udt);
    } else {
      $time->isbogus(1);
    }
  }
  if ( $time->{'wrapped'} ) {
    $time->isbogus(1);
    warn 'WRAPPED.  TIME IS BOGUS';
  }
  $time->bogus_time( $value ) if $time->isbogus();
  return;
}

sub bogus_time {
  my $time = shift;
  $time->{'bogus_time'} = shift if (scalar @_ );
  return $time->{'bogus_time'};
}

sub isbogus {
  my $time = shift;
  $time->{'isbogus'} = shift if (scalar @_);
  return $time->{'isbogus'};
}

### Value Access

# $hour = $time->hour; or pass ($hour) to set it
sub hour {
  my $time = shift;
  if (scalar @_) {
    my $value = shift;
    if ( $value < 0 or $value > 23) {
      warn "invalid hour $value";
      $value = 0;
    }
    $time->{'hour'} = $value;
  }
  return $time->{'hour'};
}

# $minute = $time->minute; or pass ($minute) to set it
sub minute {
  my $time = shift;
  if (scalar @_) {
    my $value = shift;
    if ( $value < 0 ) {
      $time->hour( $time->hour - 1 );
      $time->minute( 60 + $value );
      $time->{'wrapped'} = 1;
    } elsif( $value > 59) {
      $time->hour( $time->hour + 1 );
      $time->minute( $value - 60 );
      $time->{'wrapped'} = 1;
      warn 'time was wrapped';
    } else{
      $time->{'minute'} = $value;
    }
  }
  return $time->{'minute'} - 0;
}

# $second = $time->second; or pass ($second) to set it
sub second {
  my $time = shift;
  if (scalar @_) {
    my $value = shift;
    if ( $value < 0 ) {
      $time->minute( $time->minute - 1 );
      $time->second( 60 + $value );
      $time->{'wrapped'} = 1;
    } elsif( $value > 59) {
      $time->minute( $time->minute + 1 );
      $time->second( $value - 60 );
      $time->{'wrapped'} = 1;
    } else{
      $time->{'second'} = $value;
    }
  }
  return $time->{'second'} - 0;
}

# ($hour, $minute, $second) = $time->hms; or pass ($hour, $minute, $second)
sub hms {
  my $time = shift;
  if (scalar @_) {    
    $time->hour ( shift );
    $time->minute ( shift );
    $time->second ( shift );
  }
  return ( $time->hour, $time->minute, $time->second );
}

# ($twelvehour, $ampm) = $time->twelvehour; or pass ($twelvehour, $ampm) to set
sub twelvehour {
  my $time = shift;
  
  if (scalar @_) {
    my ($hour, $ampm) = @_;
    $hour += 12 if ($ampm =~ /p/i && $hour <= 11);
    $hour -= 12 if ($ampm =~ /a/i && $hour > 11);
    $time->hour($hour) 
  }
  
  my $hour = $time->hour;
  my $ampm;
  if ($hour < 12) {
    $hour = (($hour - 0) or '12');
    $ampm = 'am';
  } else {
    $hour = (($hour - 12) or '12') ;
    $ampm = 'pm';
  }
  return ($hour, $ampm)
}

# ($hour, $minute, $second, $ampm) = $time->hms_ampm; or pass ($h, $m, $s, $ap)
sub hms_ampm {
  my $time = shift;
  if (scalar @_) {
    my ($hour, $minute, $second, $ampm) = @_;
    # warn "setting time to $hour, $minute, $second, $ampm \n";
    if ( ! $ampm ) {
      if (( $hour != 0 and $hour < 8 ) or ( $hour == 12 )) {
        $ampm = 'pm';
        warn 'Ambiguous time entry assumed to be PM';
      } elsif ( $hour >= 8 and $hour < 12 ) {
        $ampm = 'am';
        warn 'Ambiguous time entry assumed to be AM';
      } elsif ( $hour == 0 ) {
        $hour = 12;
        $ampm = 'am';
        warn 'Military time entry assigned meridian AM';
      } elsif ( $hour > 12 and $hour <= 24 ) {
        $hour = ( $hour - 12 );
        $ampm = 'pm';
        warn 'Military time entry assigned meridian PM';
      } else {
        $time->isbogus(1);
      }
    }
    $time->twelvehour($hour, $ampm);
    $time->minute($minute);
    $time->second($second);
  }
  my ($hour, $ampm) = $time->twelvehour;
  return ($hour, $time->minute, $time->second, $ampm)
  
}

# $udt = $time->udt; or pass ($udt) to set it
sub udt {
  my $time = shift;
  
  if (scalar @_) {
    my ($second, $minute, $hour, $undef, $undef, $undef) = localtime( shift );
    $time->hms($hour, $minute, $second);
  }
  
  my ($hour, $minute, $second) = $time->hms;
  return timelocal($second, $minute, $hour, 1, 0, 0);
}

### Display

# $zero_padded_string = $time->zero_padded( $value, $field_size || 2 );
sub zero_padded {
  my ($time, $value, $field_size) = @_;
  $value += 0;
  return '0' x ( $field_size || 2 - length( $value ) ) . $value;
}

# $two_digit_hours = $time->hh;
sub hh {
  my $time = shift;
  return $time->zero_padded( $time->hour );
}

# $two_digit_minutes = $time->mm;
sub mm {
  my $time = shift;
  return $time->zero_padded( $time->minute );
}

# $two_digit_seconds = $time->ss;
sub ss {
  my $time = shift;
  return $time->zero_padded( $time->second );
}

# $hh:mm:ss = $time->full;
sub full {
  my $time = shift;
  return $time->hh . ':' . $time->mm . ':' . $time->ss;
}

# $hh:mm(:ss) = $time->military;
sub military {
  my $time = shift;
  my($result) =  $time->hour .':'. $time->minute;
  $result .= ':'. $time->second if ($time->second > 0);
  return $result;
}

# $h:mm(:ss)a/p = $time->ampm;
sub ampm {
  my $time = shift;
  my ($hour, $minute, $second , $ampm) = $time->hms_ampm;
  my($result) =  $hour .':'. $time->mm;
  $result .= ':'. $time->ss if ($time->ss > 0);
  $result .= $ampm;
  return $result;
}

# $h(:mm:ss)a/p = $time->short;
sub short {
  my $time = shift;
  my ($hour, $minute, $second , $ampm) = $time->hms_ampm;
  my($result) =  $hour ;
  $result .= ':'. $minute if ($minute > 0 or $second > 0);
  $result .= ':'. $second if ($second > 0);
  $result .= $ampm;
  return $result;
}

### Spinoffs

# $duration = $time->duration_to_time($other_time);
sub duration_to_time {
  my ($time, $other_time) = @_;
  
  my ($seconds);
  $seconds = 3600 * ( $timea->hour - $timeb->hour);
  $seconds += 60 * ( $timea->minute - $timeb->minute);
  $seconds += ( $timea->second - $timeb->second);
  
  return DateTime::Duration->new_from_seconds($seconds);
}

1;
