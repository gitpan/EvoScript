### A WebApp::LoggingHandler manages server event and diagnostic logging.

### Interface
  # warn( $message );
  # $handler->startup();
  # $handler->starting_request($request);
  # $handler->got_request($request);
  # $zero = $handler->handle_request($request);
  # $handler->done_with_request($request);

### Caveats and Things To Do
  # - Provide a mechanism for temporarily setting Err::Debug::Level by passing
  # request argument, then replace the {'args'}{'debug'} code below with debug.

### Change History
  # 1998-04-02 Args are logged under "requestargs" instead of "request". -Del
  # 1998-03-02 Added request resolved-by logging.
  # 1998-01-29 Changed warns to debugs.
  # 1998-01-02 Moved uses of Err::WebLogFormat and Err::LogFile to WebApp.cgi
  # 1998-01-02 New logging output for request args debug=env, request, or data.
  # 1997-12-04 Added use of Err::LogFile::log_errors_to.
  # 1997-11-20 Added use of Err::WebLogFormat.
  # 1997-11-03 Cleaned up header
  # 1997-10-?? Four-oh fork. -Simon

package WebApp::Handler::LoggingHandler;

use WebApp::Handler;
unshift @ISA, qw( WebApp::Handler );

use strict;
use vars qw( $count $time_request );

use Err::Debug;
use Text::PropertyList qw( astext );

# $handler->startup();
sub startup {
  my $handler = shift;
  debug 'times', "- WebApp ready after ", (time - $main::Start), "second(s) starting up" if ($main::Start) ;
}

# $handler->starting_request($request);
sub starting_request {
  my $handler = shift;
  my $request = shift;
  
  $time_request = time();
  
  my $client = $ENV{REMOTE_HOST} || '';
  my $page = $ENV{PATH_INFO} || 'the home page';
  
  ++$count;
  warn "--- Request number $count, from $client for $page\n";
  
  my $val;
  
  debug 'request', "- Request is for", $request->{'file_url'};
  
  debug 'request', "- Request arguments are", $request->{'args'};
  
  debug 'request', "- Referred from", $val
				    if ($val = $request->{'referer'});
  
  warn "- Environment variables are " . astext( \%ENV ) 
    if ($request->{'args'}{'debug'} && $request->{'args'}{'debug'} =~ /env/i);
  			    
  warn "- Request structure is " . astext( $request ) 
    if ($request->{'args'}{'debug'} && $request->{'args'}{'debug'} =~ /req/i);
  
  return;
}

# $handler->done_with_request($request);
sub done_with_request {
  my $handler = shift;
  my $request = shift;
   
  my $elapsed = time - $time_request;
  if ($elapsed) {
    $elapsed .= ' second' . ($elapsed > 1 ? 's' :'');
  } else {
    $elapsed = 'under 1 second';
  }
  my $page = $ENV{PATH_INFO} || 'the home page';
  debug 'times', "- Completed $page in $elapsed";
  
  warn "- Post-request data structures are " . astext( $Data::DRef::Root ) 
    if ($request->{'args'}{'debug'} && $request->{'args'}{'debug'} =~ /data/i);
  
}

1;
