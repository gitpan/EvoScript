### DBAdaptor::Available includes any locally available DBAdaptor subclasses.

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### To Do: Supress "redefined" warnings.

### Change History
  # 1998-01-20 Added eval around require list, new compatibility note.
  # 1997-11-17 Created. -Simon

package DBAdaptor::Available;

use DBAdaptor;

use Err::Debug;

use vars qw( @Candidates );
@Candidates = qw( 
  DBAdaptor::DelimitedText
  DBAdaptor::MySQL
);
# DBAdaptor::Win32ODBC 

sub load_available {
  local ($pckgnm, $n);
  foreach $pckgnm ( @Candidates ) {
    my $fname = $pckgnm;
    $fname =~ s/\:\:/\//g;
    $fname .= '.pm';
    debug 'dba_avail', "Attempting to load DBAdaptor", $pckgnm;
    eval { 
      require $fname;
      $n ++;
      debug 'dba_avail', "Loaded DBAdaptor", $pckgnm;
    };
  }
  return $n;
}

load_available;

__END__

=head1 DBAdaptor::Available

Loads any locally available DBAdaptor subclasses.

=head1 Description

This package loops through a list of DBAdaptor subclasses that might (or
might not) be available, attempting to load each of them inside of an eval.

=head1 Caveats and Upcoming Changes

There are no major interface changes anticipated for this framework.

This method won't work with the Devel::PreProcessor, so you may
need to hard-code the list of DBA packages to use by replacing 
"use DBAdaptor::Available" with, for example in a Win32 evironment, 
"use DBAdaptor::DelimitedText;" and "use DBAdaptor::Win32ODBC;"

=head1 See Also

L<DBAdaptor>

=head1 Copyright

Copyright 1997, 1998 Evolution Online Systems, Inc. 
Contact us at info@evolution.com or through http://www.evolution.com/.

You may use this software for free under the terms of the Artistic License.

The latest version of this and other portions of the EvoScript web application framework is available from http://www.evoscript.com/.

=cut
