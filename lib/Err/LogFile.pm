### The Err::LogFile package lets you designate a target for error messages

### Copyright 1997 Evolution Online Systems, Inc.
  # This is free software; you can use it under the same terms as Perl itself.
  #
  # Based on CGI::Carp 1.02 by Lincoln D. Stein <lstein@genome.wi.mit.edu>

### Change History
  # 1998-05-20 Changed 'die' to 'warn' in start_log.  -Piglet
  # 1998-02-24 Attempted to debug problem with STDERR and WebLogFormat.
  # 1998-02-24 Removed line break in error message string.
  # 1998-02-22 Fixed buffering on LOG.
  # 1998-02-03 Separated start_log function, added trivial stop_log().
  # 1998-02-03 Trying LOG rather than STDERR -- Rolled back.
  # 1998-02-03 Tweaked usage of FileHandle methods.
  # 1998-01-29 After redirecting STDERR, use SIG handlers to write to log
  # 1998-01-28 Added select...$|...select dance to flush output.
  # 1997-12-08 New package based on Evo::carp version 3. -Simon

package Err::LogFile;

$VERSION = 4.00_01;

require 5.000;

use FileHandle;

use vars qw( $Logger );

# sub log { print LOG ( web_log_format(@_) ) }

# Err::LogFile->import( $filename );
sub import {
  my $package = shift;
  log_errors_to( shift ) if ( scalar @_ );
}

# log_errors_to( $filehandle_or_filename );
sub log_errors_to {
  $Logger = shift;
  start_log();
}

# start_log;
sub start_log {
  my $fh;
  # If we were called with a filename, open a filehandle to append to it.
  if ( ! ref $Logger and length $Logger ) {
    $fh = FileHandle->new( $Logger, '>>' ) or
		    warn("Can't open file '$Logger' for error log: $!\n");
  } else {
    $fh = $Logger;
  }
  
  my $filenum = $fh->fileno or warn "Invalid LogFile target: $Logger\n";
  
  open(SAVEERR, ">&STDERR");
  open(STDERR, ">&$filenum") or warn "Unable to open LogFile target: $!\n";
  
  open(Err::WebLogFormat::LOG, ">&$filenum") or warn "Unable to open LogFile target: $!\n";
  
  # Make sure we flush STDERR early and often -- mightn't really be needed, eh?
  # select(STDERR);
  select(Err::WebLogFormat::LOG);
  $| = 1;
  select(STDOUT);
}

# stop_log;
sub stop_log {
  open(STDERR, ">&SAVEERR");
  close(SAVEERR);
}

1;

__END__

=head1 Err::LogFile

The Err::LogFile package lets you direct error messages to a file.

=head1 Synopsis
    
    sh> cat myapp.pl
    use Err::LogFile;
    log_errors_to( 'myapp.log' );
    
    warn "gack!";
    
    sh> perl myapp.pl
    sh> tail -1 myapp.log 
    gack! at myapp.pl line 4

=head1 Description

Automated tasks and CGI scripts may want to send errors and debugging 
messages somewhere other than the default STDERR target; this package
provides a function to direct warn and die messages to a file or pipe.

=over 4

=item log_errors_to( $filehandle_or_filename )
Designates the target filehandler or name of a file to append to.

=back

You only need to use Err::WebLogFormat once in your program. This code should interoperate just fine with Carp's carp/croak functions.

=head1 Caveats and Upcoming Changes

The integration with Err::WebLogFormat and Err::Debug leaves something to be desired.

This package is relatively new, so its interface is open to change.

=head1 See Also

L<Carp>, L<Err::WebLogFormat>

=head1 This is Free Software

Copyright 1997, 1998 Evolution Online Systems, Inc. (http://www.evolution.com)

You can use this software under the same terms as Perl itself.

Part of the EvoScript Web Application Framework (http://www.evoscript.com)

Based on CGI::Carp 1.02 by Lincoln D. Stein <lstein@genome.wi.mit.edu>

=cut