### Err::WebLogFormat reformats Perl warnings for web server error logs.

### Synopsis
  #   use Err::WebLogFormat;
  #   
  #   warn "gack!";
  #
  # sh> myapp.pl 
  # [Mon Dec  8 18:02:42 1997] myapp.pl: gack! at myapp.pl line 3

### Description
  # Messages written to STDERR by a CGI script are commonly appended to 
  # an error log. WebLogFormat overrides Perl's default warn & die signal
  # handlers to use a format appropriate for standard httpd error logs.
  # 
  # Two package flags are used to control the output: set them directly, or
  # use the equivalent import flags in your use statement:
  # 
  # - use Err::WebLogFormat qw(stamp_every_line);
  # Sets $Show_PID to nonzero to show the process ID in parentheses
  # next to the program name, which can be useful if multiple instances
  # of a script are logging to the same stream simultaneously.
  # 
  # - use Err::WebLogFormat qw(show_pid);
  # Sets $Stamp_Every_Line to change the layout of multi-line messages
  # to repeat the datestamp rather than the default whitesapce padding.
  # 
  # - $Script_Name
  # You can override the name by setting $Err::WebLogFormat::program_name.
  # 
  # You only need to use Err::WebLogFormat once in your program.
  # This code should interoperate just fine with Carp's carp/croak functions.

### Copyright 1997 Evolution Online Systems, Inc.
  # This is free software; you can use it under the same terms as Perl itself.
  #
  # Based on CGI::Carp 1.02 by Lincoln D. Stein <lstein@genome.wi.mit.edu>

### Change History
  # 1998-03-02 Script name now defaults to $0 basename, not first caller file.
  # 1998-02-03 Trying LOG rather than STDERR -- Rolled back.
  # 1998-01-22 Added import wrapper for config flags.
  # 1998-01-02 Added $Stamp_Every_Line flag.
  # 1997-12-08 Some cleanup and documentation.
  # 1997-10-03 New package, Err::WebLogFormat, based on Evo::carp -Simon

package Err::WebLogFormat;

require 5.000;

use strict;

# Overrides the default warn and die signal handlers to apply logging format
open(LOG, ">&STDERR");
$main::SIG{__WARN__} = sub { print LOG ( web_log_format(@_) );           };
$main::SIG{__DIE__}  = sub { print LOG ( web_log_format(@_) ); die "\n"; };

use vars qw( $Script_Name $Show_PID $Stamp_Every_Line );

# Err::WebLogFormat->import( 'show_pid' );
sub import {
  my $package = shift;
  foreach ( @_ ) {
    if ( m/show_pid/i ) {
      $Show_PID = 1;
    } elsif ( m/stamp_every_line/i ) {
      $Stamp_Every_Line = 1;
    } else {
      die "unkown import";
    }
  }
}

# $formatted = web_log_format( @text );
  # Convert error messages to look like web server logs, with date and process
  # name at the begining of each line. 
sub web_log_format {
  my $message = join('', @_);
  
  unless ( $message =~ /\n\Z/ ) {
    my ($pack, $file, $line, $sub) = caller(1);
    $message .= " at $file line $line.\n";
  }
  
  $Script_Name ||= ( $0 =~ m/([^\/\\\:]+)\Z/ )[0];
    
  my $stamp = '[' . scalar(localtime) . '] ' . 
	      ($Script_Name) . ( $Show_PID ? ' ('.$$.')' :'' ) . ': ';
  
  if ( $Stamp_Every_Line ) {
    $message =~ s/^/$stamp/gm;
  } else {
    my $spacer = ' ' x length($stamp);
    $message =~ s/^/$spacer/gm;
    $message =~ s/\A$spacer/$stamp/m;
  }
  
  return $message;
} 

1;

__END__

=head1 Err::WebLogFormat

Err::WebLogFormat reformats Perl warnings for web server error logs.

=head1 Synopsis

    use Err::WebLogFormat;
    
    warn "gack!";
    
    ...
    
    sh> perl myapp.pl 
    [Mon Dec  8 18:02:42 1997] myapp.pl: gack! at myapp.pl line 3
    
=head1 Description

Messages written to STDERR by a CGI script are commonly appended to 
an error log. WebLogFormat overrides Perl's default warn & die signal
handlers to use a format appropriate for standard httpd error logs.

=over 4

=item $Script_Name

You can override the program name written on each line by setting this variable

=item $Show_PID

If multiple instances of the script are logging simultaneously, set this variable to nonzero to show the process ID in parentheses next to the program name. 

=back

You only need to use Err::WebLogFormat once in your program. This code should interoperate just fine with Carp's carp/croak functions.

=head1 Caveats and Upcoming Changes

This package is relatively new, so its interface is open to change. And boy, is that name clunky.

The $Show_PID variable is used in calculating the default value for $Script_Name, so changing that will override this, and setting this option after sending output for the first time won't have any effect. In a future version of this package, this might change to an import flag.

=head1 See Also

L<Err::LogFile>

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc. (http://www.evolution.com)

You can use this software under the same terms as Perl itself.

Part of the EvoScript Web Application Framework (http://www.evoscript.com)

Based on CGI::Carp 1.02 by Lincoln D. Stein <lstein@genome.wi.mit.edu>

=cut