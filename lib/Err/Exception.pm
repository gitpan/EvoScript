### Err::Exception provides simple exception handling based on eval.

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # Developed by M. Simon Cavalletto (simonm@evolution.com)
  # Basic try and catch code from <cite>Programming Perl</cite>.
  # Additional inspiration from Organic Online's Exceptions.pm.

### Change History
  # 1998-04-23 Added DIE => BACKTRACE pragma.
  # 1998-04-17 Tweaked.
  # 1998-04-10 Replaced with new UNIVERSAL::TRY.
  # 1998-01-28 Moved try-related functions, but not throw/assert, to Err::Try.
  # 1997-03-23 Added assert function 
  # 1997-03-23 Started change log (couple of untracked weeks in there) -Simon

package Err::Exception;

use Err::Debug;

sub UNIVERSAL::TRY {
  my ($self, $catch, @catchers) = @_;
  
  debug 'exceptions', "Attempting", "$catch", "on $self";
  
  my $wantarray = wantarray();
  
  local $pragmas = { 'TIMEOUT' => 0, 'DIE' => '' };
  while ( scalar @catchers and exists $pragmas->{ $catchers[0] } ) {
    my ($pragma, $value) = ( shift(@catchers), shift(@catchers) );
    debug 'exceptions', "Pragma", $pragma, 'is being set to', $value;
    if ( $pragma eq 'DIE' and $value eq 'STACKTRACE' ) {
      $value = sub {
	warn Carp::longmess "Exception backtrace:\n"; # Carp::cluck
	CORE::die @_;
      };	
    }
    $pragmas->{ $pragma } = $value;
  }
  
  my @results;
  eval {
    local $SIG{'__DIE__'} = $pragmas->{'DIE'} if ( $pragmas->{'DIE'} );
    warn "PRAGMA DIE $pragmas->{'DIE'}\n" if ( $pragmas->{'DIE'} );
    local $SIG{'ALRM'} = sub { die "timeout"; }, alarm $pragmas->{'TIMEOUT'} 
						  if ($pragmas->{'TIMEOUT'});
    
    my ($method, @args) = ( ref $catch eq 'ARRAY' ? @$catch : ($catch) );
    @results = ( $wantarray ? $self->$method(@args) 
			    : scalar($self->$method(@args)) );
  };
  alarm 0 if ( $pragmas->{'TIMEOUT'} );
  
  return ( $wantarray ? @results : $results[0] ) unless ( $@ );
  
  my $error = $@;
  debug 'exceptions', "Exception:", $error;
  
  while ( scalar @catchers ) {
    my ($pattern, $handler) = ( shift(@catchers), shift(@catchers) );
    # debug 'exceptions', "Checking catcher", $pattern, "against", $error;
    if ( $pattern eq 'ANY' or $error =~ /\A\s*$pattern\s*\Z/is ) {
      debug 'exceptions', "Catching", $pattern, 'with', "$handler";
      if ( $handler eq 'IGNORE' ) {
	return;
      } elsif ( ref $handler eq 'ARRAY' and $handler->[0] eq 'warn' ) {
        $_ = $error;
        my $msg = eval "\"$handler->[1]\"";
	warn $msg . ( substr($msg, -1) eq "\n" ? '' : "\n" );
      } elsif ( ref $handler eq 'ARRAY' and $handler->[0] eq 'method' ) {
	$self->TRY( [ @{$handler}[1..$#$handler] ], @catchers);
	return;
      } elsif ( ref $handler eq 'ARRAY' and $handler->[0] eq 'eval' ) {
	TRY( [ @{$handler}[1..$#$handler] ], @catchers);
	return;
      } else {
	die 'Unknown exception recovery option $pattern - $handler; unable to catch $error';
      }
    }
  }
  die $error;
}

1;

