### WebApp::Handler::Available includes any locally available Handler classes.

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-22 Cloned from similar module in DBAdaptor.
  # 1998-01-20 Added eval around require list, new compatibility note.
  # 1997-11-17 Created. -Simon

package WebApp::Handler::Available;

use Err::Debug;

use vars qw( @Candidates );
@Candidates = qw( 
  WebApp::Handler::FileBrowser
  WebApp::Handler::FileHandler
  WebApp::Handler::DirectoryHandler
  WebApp::Handler::ScriptHandler
  WebApp::Handler::LoggingHandler
  WebApp::Handler::ResourceHandler
  WebApp::Handler::Scripted
  WebApp::Handler::Plugins
);

sub load_available {
  local ($pckgnm, $n);
  foreach $pckgnm ( @Candidates ) {
    my $fname = $pckgnm;
    $fname =~ s/\:\:/\//g;
    $fname .= '.pm';
    debug 'avail', "Attempting to load Handler", $pckgnm;
    eval { 
      require $fname;
      $n ++;
      debug 'avail', "Loaded Handler", $pckgnm;
    };
  }
  return $n;
}

load_available;

__END__

=head1 WebApp::Handler::Available

Loads any locally available WebApp::Handler subclasses.

=head1 Description

This package loops through a list of WebApp::Handler subclasses that might (or
might not) be available, attempting to load each of them inside of an eval.

=head1 Caveats and Upcoming Changes

There are no major interface changes anticipated for this module.

This module attempts to load modules at run time, so it won't work with Devel::PreProcessor.

=head1 Copyright

Copyright 1997, 1998 Evolution Online Systems, Inc. 
Contact us at info@evolution.com or through http://www.evolution.com/.

You may use this software for free under the terms of the Artistic License.

The latest version of this and other portions of the EvoScript web application framework is available from http://www.evoscript.com/.

=cut
