### WebApp::ResourceHandler provides access to IntraNetics applications

### Interface
  # $rc = $handler->handle_request($request);

### Change History
  # 1998-04-28 Added empty-cache method on done_with_request.
  # 1998-01-02 Moved debug tracing code to logging handler.
  # 1997-11-04 Moved Resource functionality into new package.
  # 1997-11-01 Created.

package WebApp::Handler::ResourceHandler;

use WebApp::Handler;
unshift @ISA, qw( WebApp::Handler );

use Err::Debug;

use File::Name;
use WebApp::Resource;

# $rc = $handler->handle_request($request);
sub handle_request {
  my $handler = shift;
  my $request = shift;
  
  my $name = $request->{'path'}{'names'}[0];
  
  debug 'resource-handler', 'Checking for a resource named', $name;
  
  return 0 unless ( $name );
  my $resource = WebApp::Resource->new_from_full_name( $name );
  return 0 unless ( $resource );
  
  debug 'resource-handler', 'Delegating handle_request to', "$resource";
  
  $resource->handle_request( $request );
}

# $handler->done_with_request($request);
sub done_with_request {
  my $handler = shift;
  my $request = shift;
  
  debug 'resource-handler', 'Emptying resource cache';
  WebApp::Resource->empty_cache;
  
  return;
}

1;