### WebApp::Handler provides a superclass for bundles of server functionality

### Change History
  # 1998-04-?? Doc added; init call moved to new; reference to server dropped.
  # 1998-02-04 Added shutdown method.
  # 1998-01-28 Added init method.
  # 1997-11-03 Added inline comments
  # 1997-10-** Created this package.

package WebApp::Handler;

$VERSION = 1.02_00;

use strict;

### Instantiation

# $handler = WebApp::Handler::SUBCLASS->new();
sub new {
  my $class = shift;
  my $handler = { };
  bless $handler, $class;
  $handler->init;
  return $handler;
}

# WebApp::Handler::SUBCLASS->add_new( $server );
sub add_new {
  my $class = shift;
  my $server = shift;
  my $handler = $class->new;
  $server->add_handler( $handler );
}

### Subclass Hooks

# $handler->init();
sub init 		{    }

# $handler->startup();
# $handler->shutdown();
sub startup 		{    }
sub shutdown 		{    }

# $handler->starting_request( $request );
# $handler->done_with_request( $request );
sub starting_request	{    }
sub done_with_request	{    }

# $zero = $handler->handle_request( $request );
sub handle_request { return 0; }

1;

__END__

=head1 WebApp::Handler

Handlers provide bundles of server functionality. 

Each handler will be notified when an incoming request is received, when we're attempting to reply to the request, and after the request has been replied to. This gives the handlers the opportunity to modify the request, generate pages, and so on.


The currently available concrete subclasses are:

=over 4

=item FileHandler

Checks for a file matching the requested URL and returns it if present.

=item DirectoryHandler

Checks for a directory matching the requested URL and returns a minimalist file listing in HTML.

=item ScriptHandler

Checks for a script file and executes and returns it if present.

=item ResourceHandler

Attempts to find a resource based on the first item in the URL path info, and if present, asks it to handle the current request. 

=item SiteHandler

Before each request, the SiteHandler selects a WebApp::Resource::Site based on the current host name and informs it that it has_focus(); at the end of the request it sends lost_focus(). This allows for per-site configuration. The SiteHandler also hands off requests with no URL path info to the current site.

=item LoggingHandler

Responsible for writing out information about each request to the log file.

=back

Future subclasses might include:

=over 4

=item Proxy

Delegates to another web server.

=item CGI

Spawns an external CGI process.

=item SSI

Runs a script containing server-side include tags.

=back


=head2 Instantiation

=over 4

=item WebApp::Handler::SUBCLASS->new : $handler

Creates a new handler of the specified class.

=item WebApp::Handler::SUBCLASS->add_new( $server )

Adds a new handler to this server.

=back


=head2 Subclass Hooks

Each of these methods is empty in the superclass.  

=over 4

=item $handler->init

Called at creation.

=item $handler->startup

Startup notification sent when the server is ready to start accepting requests.

=item $handler->starting_request( $request )

Sent to every handler upon receiving a request.

=item $handler->handle_request( $request ) : $flag

Called to generate a reply to this request. Handlers should return false if this request is not for them, or reply to this request and return true.

=item $handler->done_with_request( $request )

Sent to every handler after the request has been handled.

=item $handler->shutdown

Notification sent when there are no more incoming requests and the server is terminating.

=back

=head2 Caveats and Things Undone

As we've yet to come up with a case in which you'd want to use more than one handler of the same class at the same time, we should consider using package names alone for some handler instances.

=cut
