### WebApp::ScriptHandler provides EvoScript execution for .page files

### Interface
  # $flag = $handler->can_handle_file( $fn );
  # $handler->send_file( $request, $fn );

### Change History
  # 1998-05-29 Switched to use of Script::Evaluate package instead of Script.
  # 1998-05-07 Switched from get_contents to get_text_contents.
  # 1997-12-06 Made into a subclass of FileHandler.
  # 1997-10-28 Updated to use new Text::Escape interface.
  # 1997-10-23 Wow, it sorta works now...

package WebApp::Handler::ScriptHandler;

use WebApp::Handler::FileHandler;
unshift @ISA, qw( WebApp::Handler::FileHandler );

use Script::Evaluate qw( runscript );
use Data::DRef;

use Text::Escape qw( escape );
use Text::PropertyList qw( astext );
use Script::HTML::Escape;

# $flag = $handler->can_handle_file( $fn );
sub can_handle_file {
  my $handler = shift;
  my $fn = shift;
  return ( $fn->exists and $fn->hasextension('page') );
}

# $handler->send_file( $request, $fn );
sub send_file {
  my $handler = shift;
  my $request = shift;
  my $fn = shift;
  
  # should this be localized to here, or made available at other times?
  setData('request', $request);
  
  $request->reply( runscript( $fn->get_text_contents ) );
  
  return 1;
}

1;