### The Plugins Handler looks for Perl Modules to load at startup. 

### Interface
  # $handler->init();

### Change History
  # 1998-05-07 Switched from get_contents to get_text_contents.
  # 1998-02-27 Fixed.
  # 1998-01-06 Created. -Simon

package WebApp::Handler::Plugins;

use WebApp::Handler;
unshift @ISA, qw( WebApp::Handler );

use strict;
use Err::Debug;
use File::Name;

# $handler->init;
sub init {
  my $handler = shift;
  my $dir = $handler->{'dir'} || File::Name->current->relative( '../plugins' );
  
  return unless ( $dir->exists );
  
  # Load Perl Modules
  unshift(@INC, $dir->absolute->path);
  my $module;
  foreach $module ( $dir->descendents( '*.pm' ) ) {
    debug 'plugins', 'Loading plugin from', $module->path;
    eval "package main;\n" . 
	 # "$INC{'" . $module->base_name . "'} = '" . $module->path . "';\n" . 
	 $module->get_text_contents;
  }
  shift(@INC);
}

1;
