### The Scripted Handler looks for scripts to run on notifications

### Interface
  # $handler->init();

### Change History
  # 1998-05-07 Switched from get_contents to get_text_contents.
  # 1998-03-21 Created. -Simon

package WebApp::Handler::Scripted;

use WebApp::Handler;
unshift @ISA, qw( WebApp::Handler );

use strict;
use Err::Debug;

use File::Name;
use Script::Evaluate qw( runscript );

# $handler->init;
sub init {
  my $handler = shift;
  $handler->{'dir'} ||= File::Name->current;
}

# $handler->run_script_by_name( $script_name );
sub run_script_by_name {
  my $handler = shift;
  my $name = shift;
  
  my $config_file = $handler->{'dir'}->child("$name.script");
  runscript($config_file->get_text_contents) if $config_file->exists;
}

# $handler->startup;
sub startup {
  my $handler = shift;
  $handler->run_script_by_name( 'startup' );
}

# $handler->starting_request;
sub starting_request {
  my $handler = shift;
  $handler->run_script_by_name( 'before' );
}

# $handler->done_with_request;
sub done_with_request {
  my $handler = shift;
  $handler->run_script_by_name( 'after' );
}

# $handler->shutdown;
sub shutdown {
  my $handler = shift;
  $handler->run_script_by_name( 'shutdown' );
}

1;
