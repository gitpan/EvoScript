### WebApp::Server - Provides a framework for Perl web applications

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-10 Replaced do_request_safely with UNIVERSAL::TRY mechanism.
  # 1998-04-09 Added message() infrastructure.
  # 1998-04-06 Minor changes to support new subclasses.
  # 1998-03-02 Changed error message.
  # 1998-02-22 Added current $server->{'request'} throughout scope of run().
  # 1998-02-17 Moved WebApp.pm functionality into distinct Server package.
  # 1998-02-17 Changed do_request_safely to avoid failure message on redirect.
  # 1998-02-03 Commented out alarm due to NT failure.
  # 1998-01-28 Added tryto_do_request.
  # 1997-10-20 Minor changes.
  # 1997-10-05 Version 4 forked; Evo::request.pm is now WebApp/*

package WebApp::Server;

$VERSION = 1.01_00;

require 5.000;
use strict;

use Carp;
use Err::Debug;
use Err::Exception;
use Data::DRef qw( $Root );

### Instantiation and Configuration

# $RequestTimeout - Number of seconds per-request; zero value sets no limit.
use vars qw( $RequestTimeout $DeathTrap );
$RequestTimeout = 30 unless ($^O =~ /Win32/); # alarm not safe in win32

# $server = WebApp::Server->new();
# $server = WebApp::Server->new($request_class, @handler_classes);
sub new {
  my $package = shift;
  my $server = { };
  bless $server, $package;
  $server->request_class(shift) if (scalar @_);
  while (scalar @_) { $server->add_handler(shift->new) ;}
  return $server;
}

# $request_class = $server->request_class();
# $server->request_class($request_class);
sub request_class {
  my $server = shift;
  $server->{'request_class'} = shift if (scalar @_);
  return $server->{'request_class'};
}

# $server->add_handler( $handler );
sub add_handler {
  my $server = shift;
  push @{$server->{'handlers'}}, shift; 
}

# $server->notify_handlers( $method, @args );
sub notify_handlers {
  my ( $server, $method, @args) = @_;
  my $handler;
  foreach $handler ( @{$server->{'handlers'}} ) { $handler->$method(@args); }
}

# $handler = $server->find_one_handler( $method, @args );
sub find_one_handler {
  my ($server, $method, @args) = @_;
  
  my $handler;
  foreach $handler ( @{$server->{'handlers'}} ) {
    return $handler if $handler->$method(@args);
  }
}

### Server Lifecycle

# $server->run();
sub run {
  my $server = shift;
  
  $server->startup;
  while ( $server->{'request'} = $server->request_class->new ) { 
    $server->do_request( $server->{'request'} );
    delete $server->{'request'};
  }
  $server->shutdown;
}

# $server->startup;
sub startup {
  my $server = shift;
  
  debug 'server', 'Starting up.';
  $server->notify_handlers('startup');
  $server->request_class->startup();
  debug 'server', 'Startup complete.';
  debug 'server-v', 'Server is:', $server;
}

# $server->do_request( $request );
sub do_request {
  my ($server, $request) = @_;
  
  debug 'server-v', 'Received request:', $request;
  debug 'server', 'Starting to respond to the request.';
  
  $server->TRY(['respond_to_request', $request], 
    'TIMEOUT' => $RequestTimeout,
    # 'DIE' => 'STACKTRACE',
    'ANY' => ['warn', 'Request Terminated: $_'],
    'Unable to connect to MySQL.*' => 
	      ['method', 'redirect_to_page', $request, 'dberror.page'],
    'No Tables' => ['method', 'redirect_to_page', $request, 'welcome.page'],
    'ODBC connection' => 
	['method', 'redirect_to_page', $request, 'dberror.page', 'msg'=>'$_'],
    'banned' => ['method', 'send_message', $request, 'banned'],
    'redirected' => 'IGNORE',
    'ANY' => ['method', 'send_message', $request, 'failure'],
  );
  
  $server->send_message($request, 'request_not_handled') 
			    unless ( $request->{'has_replied'} );
  
  $server->notify_handlers('done_with_request', $request);
  
  $request->done_with_request();
  debug 'server', 'Done with request.';
}

# $server->respond_to_request( $request );
sub respond_to_request {
  my ($server, $request) = @_;
  
  $server->TRY(['notify_handlers', 'starting_request', $request], 
    'redirected' => 'IGNORE',
  );
  
  local $Root->{'my'} = {};
  
  $server->TRY(['find_one_handler', 'handle_request', $request], 
    'redirected' => 'IGNORE',
  ) unless ( $request->{'has_replied'} );
}

# $server->shutdown;
sub shutdown {
  my $server = shift;
  debug 'server', 'Shutting down.';
  $server->request_class->at_end();
  $server->notify_handlers('shutdown');
  debug 'server', 'Shutdown complete.';
}

### Messages and Other Replies

# $server->redirect_to_page($request, $page_name, %info);
sub redirect_to_page {
  my ($server, $request, $page_name, %info) = @_;
  
  $request->redirect_and_end(
    $request->{'site'}{'url'} . $request->{'links'}{'script'} . 
    "/" . $page_name . '?' . WebApp::Request::query_string_from_args(\%info)
  );
}

# $html_page_string = $server->message($message, %info);
sub message {
  my ($server, $message, %info) = @_;
  
  my ($severity, $title, $error, $description);
  if ( $message eq 'banned' ) {
    $severity = 'Permission Exception';
    $title = 'Request Refused';
    $error = "Sorry, you don't have permission to see this page."
  } elsif ( $message eq 'request_not_handled' ) {
    $severity = 'Application Server Error';
    $title = 'Request Not Handled';
    $error = 'Sorry, the server was unable to handle your request.'
  } elsif ( $message eq 'failure' ) {
    $severity = 'Application Server Error';
    $title = 'Error';
    $error = 'Sorry, there was a fatal error while trying to handle your request.';
  } else {
    $severity = 'Application Server Error';
    $title = 'Unknown Exception';
    $error = 'Sorry, there was a fatal error while trying to handle your request.';
  }
  $server->message_page($severity, $title, $error, $description || '');
}

# $html_page_string = $server->message_page($severity, $title, $error, $desc);
sub message_page {
  my ($server, $severity, $title, $error, $description) = @_;
  
  return $server->custom_message_page($severity, $title, $error, $description)
  					if $server->can('custom_message_page');
  
  return "<html><head><title>$severity: $title</title></head>\n" . 
	"<body bgcolor=white><h1>$title</h1>\n" . 
	  "<p>$error\n<p>$description</body></html>\n";
}

# $server->send_message($request, $message, %info);
sub send_message {
  my ($server, $request, $message, %info) = @_;
  debug 'server', 'Sending message:', $message, (scalar %info ? (\%info):());
  $request->reply( $server->message( $message, %info ) );
}

### DRef interface

use Data::DRef;

# $value = get($server, $dref);
sub get {
  my ($server, $dref) = @_;
  
  return time() if ( $dref eq 'timestamp' );
  
  Data::DRef::get( $server, $dref );
}

1;

__END__

=head1 WebApp::Server

Provides request-response application framework.

=head2 Create, Configure, and Execute

=over 4

=item WebApp::Server->new() : $server

Creates a new, empty Server.

=item $server->request_class : $request_class

=item $server->request_class($request_class)

Get or set the name of the class to use for incoming requests.

=item $server->add_handler( $handler );

Add the provided WebApp::Handler to the array this server will use on incoming requests. Each handler gets the startup/shutdown and starting_request/done_with_request notification pairs, but the handlers added first have precedence for actually generating the page to be returned.

=item $server->run()

The main event loop of the application server. When this function returns, the server is ready to quit.

=back


=head2 Execution Internals

=over 4

=item $server->notify_handlers( $method, @args )

Invokes the specified method on each of the server's handlers, passing any other arguments provided.

=item $server->do_request_safely($request)

Calls do_request within an eval, to catch exceptions, and with a timeout, to catch runaway recursion.

=item $RequestTimeout

Number of seconds per-request; zero value sets no limit.

=item $server->do_request($request)

Calls handle_request each of the handlers in order until one of them responds with a true value, indicating that they have satisfactorily responded to this request (generally by calling $request->reply).

=item $server->default_page($request)

Sends a request-unhandled message to the browser. 

=back


=head2 DRef interface

=over 4

=item $server->get($dref) : $value

Returns the current time if dref is 'timestamp'; otherwise it performs a standard Data::DRef get().

=back

=cut
