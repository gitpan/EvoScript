### WebApp::Request - Superclass for HTTP-request interfaces

### Change History
  # 1998-06-12 Use of new WebApp::Browser package.
  # 1998-06-12 Revised parse_multipart_args for a 10-15% speed gain. -Simon
  # 1998-06-04 Use File::Name::Temp for uploaded file data, and
  #            save the original filename for use by Field::File. -Del
  # 1998-05-29 Multipart optimization with index and substr, not regexes. -Bala
  # 1998-05-07 New, non-binmode get_contents call
  # 1998-05-07 File uploads written to disk. -Simon
  # 1998-04-30 Corrected improper default content-type in send_file method
  # 1998-04-21 Re-added get_contents binmode flag until it settles down -Del
  # 1998-04-15 Made reply method a wrapper around subclass' send_reply
  # 1998-04-14 Added query_string_from_args function
  # 1998-03-20 Portions of CGI subclass abstracted up to here. 
  # 1998-01-27 Added send_file method.
  # 1997-10-?? Refactored. -Simon

package WebApp::Request;

$VERSION = 1.03;

use strict;
use Carp;

use Err::Debug;
use Data::DRef qw( getDRef setDRef );
use Data::Collection qw( scalarkeysof );

use WebApp::Browser;

use Script::HTML::Escape qw( url_escape );
use File::Name;

use vars qw( $DefaultMediaType $GenericMediaType );
$DefaultMediaType = 'text/html';
$GenericMediaType = 'application/octet-stream';

# WebApp::Request->startup() 				// NO-OP
sub startup { return }

# WebApp::Request->at_end() 				// NO-OP
sub at_end { return }

### Receving Requests

# $request = WebApp::Request->new;
sub new {
  my $class = shift;
  
  return unless $class->request_available;
  
  my $request = { };
  bless $request, $class;	
  
  $request->init();
  $request->get_request_info();
  
  return $request;
}

# $flag = WebApp::Request->request_available()		// ABSTRACT
sub request_available { croak "abstract request_available called on $_[0]"; }

# $request->init;
sub init {
  my $request = shift;
  $request->{'response_headers'} = {
    'content-type'=>$DefaultMediaType, 
    'pragma'=>'no-cache',
    # 'expires' => 0,		# equivalent to no-cache?
  };
  return;
}

# $request->set_browser_from_ua( $user_agent_string );
sub set_browser_from_ua {
  my $request = shift;
  my $ua = shift;
  $request->{'client'}{'browser'} = $ua;
  $request->{'browser'} = WebApp::Browser->new_from_ua( $ua );
  $request->{'client'}{'browser_id_v'} = $request->{'browser'}->id_v;
  debug 'request', "Browser is:", $request->{'browser'}->id_v;
}

# $browser = $request->browser;
sub browser {
  my $request = shift;
  $request->{'browser'};
}

# $request->get_request_info;
sub get_request_info {
  my $request = shift;
  
  $request->{'timestamp'} = time;
  $request->read_headers;
  $request->read_arg_data;
  $request->parse_arg_data;
  
  debug 'request-verbose', "CGI Request is:", $request;
  
  return $request; 
}

# $request->read_headers;				// ABSTRACT
sub read_headers { croak "abstract read_headers called on $_[0]"; }

# $request->read_arg_data;				// ABSTRACT
sub read_arg_data { croak "abstract read_arg_data called on $_[0]"; }

# $request->set_method_and_type( $method, $content_type );
sub set_method_and_type {
  my $request = shift;
  
  $request->{'method'} = shift || 'GET';
  $request->{'content_type'} = shift || 'application/x-www-form-urlencoded';
  
  # Patch for IE3, which doesn't clear content_type when it gets a redirect.
  if ( $request->{'method'} eq 'GET' and 
  	$request->{'content_type'} =~ /multipart\/form-data/ ) {
    $request->{'content_type'} = 'application/x-www-form-urlencoded';
    debug 'request', 'Overriding bogus multipart encoding for GET request.';
  }
}

# $request->parse_arg_data;
sub parse_arg_data {
  my $request = shift;
  
  # Hash to store the parsed version of the arguments.
  $request->{'args'} = {};
  
  warn "content type $request->{'content_type'}\n";
  if ($request->{'content_type'} =~ /multipart\/form-data/) {
    debug 'request', "Parsing multipart request arguments";
    my $boundary = '--'.( $request->{'content_type'} =~ /boundary=(.*)$/ )[0];
    $request->parse_multipart_args($boundary);
  } else {
    # application/x-www-form-urlencoded
    debug 'request', "Parsing request arguments";
    $request->parse_urlencoded_args;
  }
  delete $request->{'data'};
  
  debug 'request', "Done parsing request arguments";
  return;
}

# $request->parse_urlencoded_args;
sub parse_urlencoded_args {
  my $request = shift;
  debug 'request-args-verbose', "URL-encoded data is:", $request->{'data'};
  foreach ( split(/[&;]/, $request->{'data'}) ) {
    $_ =~ s/\+/ /g;
    my($key, $val) = split(/=/, $_, 2); 
    next unless ( defined $key and length $key );
    $key =~ s/%([\dA-Fa-f]{2})/chr(hex($1))/ge;
    $val =~ s/%([\dA-Fa-f]{2})/chr(hex($1))/ge if ( defined $val );
    $request->add_argument($key, $val);
  }
}

# $request->parse_multipart_args( $boundary );
  # BOUNDARY
  # HEADERS
  # 
  # OPAQUE-DATA
  # BOUNDARY
  # HEADERS
  # 
  # OPAQUE-DATA
  # BOUNDARY--
  
sub parse_multipart_args {
  my ($request, $boundary) = @_;
  
  debug 'request-args', 'Multipart argument data is', 
	  length($request->{'data'}), 'bytes', 'separated by', $boundary;
  debug 'request-args-verbose', "Multipart content:", $request->{'data'};
  
  my $boundary_length = length($boundary);
  my ($pos, $index) = (0, 0);
  
  while ( 1 ) {
    # Advance position to after the end of the boundary and CRLF
    $pos += $boundary_length + 2;
    
    # Check if we're on the last boundary, with its '--' ending.
    last if substr($request->{'data'}, $pos -2, 4) eq "--\015\012";
    
    # Extract header information
    my %header;
    while ( 1 ) {
      # Look for the next line; if none, we're done.
      $index = index($request->{'data'}, "\015\012", $pos);
      croak "can't find end of header line\n" if ($index == -1);
      
      # Extract the header line and move postion indicator to the end of it.
      my $header = substr($request->{'data'}, $pos, $index - $pos);
      $pos = $index + 2;
      
      # If the line is blank, we're at the end of the header section.
      last if ( $header eq '' );
      
      # Parse the header; force names lowercase for consistency
      my ($name, $value) = split(': ', $header, 2);
      $header{ lc($name) } = $value;
    }
    
    # Determine the argument name
    my $arg_name = ($header{'content-disposition'} =~ / name="([^"]*)"/)[0];
    warn "multipart arg received without name.\n" unless ( length $arg_name );
    
    # Look for the next CRLF-boundary line.
    $index = index($request->{'data'}, "\015\012" . $boundary, $pos);
    croak "can't find end of multipart argument data\n" if ($index == -1);
    
    # Extract the data and move position indicator to start of next boundary.
    my $data = substr($request->{'data'}, $pos, $index - $pos );
    $pos = $index + 2;
    
    # Check if the value is being sent as a file upload. If it is, save it
    # into a temp file and use that File::Name object as the argument value.
    if ($header{'content-disposition'} =~ / filename="(.+)"/) {
      my $filename = $1;
      $data = File::Name::Temp->new_typed_filled_temp($filename, 
      					$header{'content-type'}, $data);
      # I'm not 100% sold on this original_name mechanism... -Simon
      $request->add_argument($arg_name.'_original_name', $filename);
    }
    
    $request->add_argument($arg_name, $data);
  }
}

# $request->add_argument($key, $val);
  # if we get the same argument more than once, we make an array of 'em.
sub add_argument {
  my($request, $key, $val) = @_;
  
  debug 'request-args-verbose', "Argument", $key, "Value", $val;
  
  my $current = getDRef($request->{'args'}, $key);
  if ( ! defined $current ) {
    setDRef($request->{'args'}, $key, $val);
  } elsif ( ref $current eq 'ARRAY' ) {
    push @$current, $val;
  } else {
    debug 'request-args-verbose', 'Building array of arguments named', $key;
    setDRef($request->{'args'}, $key, [ $current, $val ] );
  }
}

# $url = $request->repeat_url;
sub repeat_url {
  my $request = shift;
  $request->{'site'}{'url'} . $request->{'links'}{'script'} . 
    $request->{'path'}{'info'} . '?' . $request->query_string;
}

# $query_string = $request->query_string;
sub query_string {
  my $request = shift;
  query_string_from_args( $request->{'args'} );
}

# $query_string = query_string_from_args( $args );
sub query_string_from_args {
  my $args = shift;
  
  my @args;
  
  debug 'qs_from_args', 'source:', $args;
  
  #!# Algorithm needs to be modified to properly encode arrays of scalars
  # as a sequence of arguments with the same name, rather than name.0, name.1.
  
  my $key;
  foreach $key ( scalarkeysof( $args ) ) {
    my $val = getDRef($args, $key);
    if ( ref($val) ) {
      debug 'qs_from_args', 'empty item', $key, '=', $val;
      next;
    }
    my $arg = url_escape($key);
    $arg .= '=' . url_escape($val) if (defined $val);
    push (@args, $arg);
  }
  debug 'qs_from_args', 'args:', @args;
  
  my $qstr = join('&', @args);
  debug 'qs_from_args', 'string:', $qstr;
  
  return $qstr;
}

### Responding to Requests

# $request->reply( $page_or_file );
sub reply {
  my $request = shift;
  # Maybe support nph operation -- send "HTTP/1.0 200 OK" status line first?
  $request->{'response_headers'}{'content-length'} = length( $_[0] );
  $request->send_reply( $_[0] );
  ++ $request->{'has_replied'};
}

# $request->send_reply( $content );  			// ABSTRACT
sub send_reply { croak "abstract send_reply called on $_[0]"; }

# $request->done_with_request;  			// NO-OP
sub done_with_request { return }

# $request->send_file( $fn );
sub send_file {
  my $request = shift;
  my $fn = File::Name->new( shift(@_) );
  
  my $headers = $request->{'response_headers'};
  delete $headers->{'pragma'};	# Pragma: no-cache isn't desirable here
  $headers->{'content-type'} = $fn->media_type || $GenericMediaType;
  $headers->{'content-disposition'} = "attachment; filename=" . $fn->name 
  		    if ($headers->{'content-type'} eq $GenericMediaType);
  
  $request->reply( $fn->get_contents );
}

# $request->redirect( $location );
sub redirect {
  my $request = shift;
  my $location = shift;
  
  $request->{'response_headers'}{'content-type'} = 'text/html';
  $request->{'response_headers'}{'location'} = $location;
  
  $request->reply( "<a href=$location>Click here for your document.</a>" );
}

# $request->redirect_and_end( $url );
sub redirect_and_end {
  my $request = shift;
  my $url = shift;
  $request->redirect( $url );
  die "redirected\n";
}

# $request->redirect_via_refresh( $location );
  # Send an HTML page with a refresh 
sub redirect_via_refresh {
  my $request = shift;
  my $location = shift;
  
  $request->{'response_headers'}{'content-type'} = 'text/html';
  
  $location = html_escape( $location );
  
  $request->reply( "<meta http-equiv=refresh content=\"0;url=$location\">" . 
		   "<a href=$location>Click here for your document.</a>"   );
}

1;

__END__

=head1 WebApp::Request

WebApp::Request is the abstract superclass for web server request-response interfaces. Subclasses are responsible for accepting incoming requests from clients and returning the resulting page. 

The currently available concrete subclasses are:

=over 4

=item CGI

Standard one-shot CGI request from a local HTTPD-equivalent web server.

=item FastCGI

Interface for freeware (nee OpenMarket) FCGI package. Requires SFIO patch to Perl executable. CGI Bridge or FCGI-compatible web server required. Terminates after $WebApp::Request::FastCGI::MaxRequests.

=back

The following two subclasses have been developed but are not thouroughly tested:

=over 4

=item Apache

For use with mod_perl.

=item HTTPD

Standalone web server accepting requests on a high port.

=back

=head2 Package Init

=over 4

=item WebApp::Request->startup

Hook to allow subclasses to configure themselves. Superclass does nothing.

=item WebApp::Request->at_end

Hook to allow subclasses to wrap up before closing. Superclass does nothing.

=back


=head2 Request Lifecycle

=over 4

=item WebApp::Request->new : $request

Retreive an incoming request. Returns nothing if there are no more requests to process. Calls request_available, init, and get_request_info methods.

=item $request->reply( $content )

Abstract. Send the provided content data to the client. 

Reply, or one of the specialized replies below, should be called once on every request received.

=item $request->done_with_request

Hook to allow subclasses to finalize the request before discarding it. Superclass does nothing.

=back


=head2 Specialized Replies

Each of these methods calls reply.

=over 4

=item $request->send_file( $fn )

Replies with the contents of the named file, using File::Name. Adds the media_type of the file as the response content-type header. 

=item $request->redirect( $url )

Sends a minimal HTTP redirect message instructing the client to load the provided fully-qualified URL. 

=item $request->redirect_and_end( $url )

Sends a redirect message and then dies.

=item $request->redirect_via_refresh( $url )

Sends a minimal HTML page containing a refresh message instructing the client to load the provided URL. Generally, the redirect method is preferable.

=back


=head2 Instantiation Hooks

=over 4

=item WebApp::Request->request_available : $flag

Abstract. Return a flag indicating whether another request is available.

=item $request->init

=item $request->get_request_info

=item $request->read_headers

Abstract. Read HTTP headers, environment variables, or the equivalent.

=item $request->read_arg_data

Abstract. Read query string, POST-ed STDIN, or the equivalent. The argument data should be stored in $request->{'data'}.

=item $request->parse_arg_data

Based on the request's content-type header, invokes either parse_urlencoded_args or parse_multipart_args. All data in $request->{'data'} is  $request->{'args'}

=item $request->parse_urlencoded_args

=item $request->parse_multipart_args( $boundary )

=item $request->add_argument($key, $val)

If multiple arguments with the same name are received from the client, an array is formed of each of those values. For example, a query string of 

    user=jsmith&user=bobh&user=sbrown 

would result in a request args hash equivalent to the following:

    'user' => [ 'jsmith', 'bobh', 'sbrown' ]

Dot characters in argument names are used to construct nested hashes. (See Data::DRef for details.) For example, a query string of 

    user.login=jsmith&user.name=Joe+Smith 

would result in a request args hash equivalent to the following:

    'user' => { 
      'login'=>'jsmith', 
      'name'=>'Joe Smith'
    }

=back

=head2 Caveats and Things Undone

Need to more clearly deliniate the data to be gathered and exposed by subclasses. Some of the more esoteric CGI ENV vars, for example, are never used. 

Perhaps the startup, at_end, and done_with_request methods should be replaced with BEGIN, END, and DESTROY.

Perhaps add an auto-detect request package that checks relevant info (eg $ENV{GATEWAY_INTERFACE}) to detect the class of request we should actually be accepting. 

=cut
