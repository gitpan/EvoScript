### A WebApp::FileHandler returns files requested in path info

### Interface
  # $rc = $handler->handle_request($request);
  # $flag = $handler->can_handle_file( $fn );
  # $handler->send_file( $request, $fn );

### Caveats and Things To Do
  # - Support configurable document root directory and virtual directories.

### Change History
  # 1998-03-02 Better subclass integration.
  # 1997-12-06 Made DirectoryHandler and ScriptHandler subclasses of this one.
  # 1997-11-04 Refactored with an eye towards adding a superclass
  # 1997-10-21 Started using File::Name and moved media-type detection to there 

package WebApp::Handler::FileHandler;

use File::Name;

use WebApp::Handler;
unshift @ISA, qw( WebApp::Handler );

use strict;

# $rc = $handler->handle_request($request);
sub handle_request {
  my $handler = shift;
  my $request = shift;
  
  my $filepath = $handler->path_for_request($request) or return 0;
  
  my $fn = File::Name->new( $filepath );
  
  return 0 unless ( $fn->exists and $handler->can_handle_file( $fn ) );
  
  $handler->send_file( $request, $fn );
  
  return 1;
}

# $filepath = $handler->path_for_request($request);
sub path_for_request {
  my $handler = shift;
  my $request = shift;
  
  return $request->{'path'}{'filename'} || '';
}

# $flag = $handler->can_handle_file( $fn );
sub can_handle_file {
  my $handler = shift;
  my $fn = shift;
  return ( ! $fn->isdir );
}

# $handler->send_file( $request, $fn );
sub send_file {
  my $handler = shift;
  my $request = shift;
  my $fn = shift;
  
  $request->send_file( $fn );
}

1;