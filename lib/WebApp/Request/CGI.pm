### WebApp::Request::CGI implements the basic CGI request/response protocol

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License
  # Distantly descended from code by s.e.brenner@bioc.cam.ac.uk
  # 
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Piglet   E.J. Evans (piglet@evolution.com)
  # Eric     Eric Schneider (roark@evolution.com)

### Change History
  # 1998-06-10 Added client:browser:is:IE3 in read_headers.  -Piglet
  # 1998-04-15 Made reply method a wrapper around subclass' send_reply
  # 1998-03-20 Portions moved to superclass, general cleanup, added inline POD. 
  # 1998-02-22 Added check for argument with empty name in parse_url_encoded.
  # 1998-02-18 Changed scoping of request data buffer from lexical to object.
  # 1998-02-18 Patch for IE3's bogus GET-multipart requests after redirect.
  # 1998-02-17 Fixed typo in error message.
  # 1998-02-01 Further mucking with parse_multipart_args.
  # 1998-01-25 Updated HTTPS detection logic based on INetics 1.01.
  # 1997-11-17 New nested arg handling to replace set(append) functionality
  # 1997-10-21 Folded remaining comments in from stripped 3.0 libraries. 
  # 1997-10-05 Version 4 forked; Evo::CGI moved to WebApp::Request::CGI.
  # 1997-10-15 Version 3.1 lib/Evo libraries archived for distribution
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-09-19 More careful stripping of directory_name out of directory_url
  # 1997-09-16 Changed parse_multipart_args to use it $_[0] in place, not split
  # 1997-08-12 Changed redirect to use CRLF pairs more carefully.
  # 1997-08-09 Changed return to use CRLF pairs more carefully.
  # 1997-08-08 Arg! More binmode suffering! Use of CRLFs in return.
  # 1997-07-11 Strip trailing slash from script_url, reordered parsing steps
  # 1997-06-01 Changed parse_multipart_args to include crlfs
  # 1997-05-27 Changed read to sysread, CRLF to CRLF|CR|LF, for Win32 usage
  # 1997-04-16 Moved debug and message arguments up and out of args hash
  # 1997-04-15 Now query_string for a post is *not* handled.
  # 1997-02-04 Removed script_name, added intranetics_path and intranetics_url
  # 1997-01-21 Cleanup of arg parsing functions.
  # 1997-01-20 Parse now handles multiple arg types (eg query string for posts)
  # 1997-01-11 Version 3 cloned and cleaned for use with IntraNetics.
  # 1996-11-14 Cleanup and styling.
  # 1996-11-12 Version 2 overhaul; method & encoding done in a single pass
  # 1996-08-16 Added cgi:file, cgi:timestamp. -Simon
  # 1996-07-31 Added filename and contenttype to multipart encoded data.
  # 1996-07-18 Added support for multipart/form-data encoding.
  # 1996-07-13 Build a nested argument hash using Evo::dataops::set. -Piglet
  # 1996-06-24 Modified to return hash with args and other data of note.
  # 1996-04-06 Version 1, first Evo build of a cgi library.  -Simon

package WebApp::Request::CGI;

$VERSION = 1.03;

use WebApp::Request;
@WebApp::Request::CGI::ISA = qw( WebApp::Request );

require 5.000;
use strict;

use Err::Debug;
use Script::HTML::Escape;

### Receving Requests

use vars qw( $Counter );

# $flag = WebApp::Request::CGI->request_available()
sub request_available { ! ( $Counter++ ) }

# $req->read_headers;
sub read_headers {
  my $req = shift;
  
  # Request Data						# CGI 1.1
  $req->set_method_and_type( $ENV{'REQUEST_METHOD'}, $ENV{'CONTENT_TYPE'} );
  
  # Referenced File						# CGI 1.1
  $req->{'path'}{'info'} = $ENV{'PATH_INFO'} || '';
  $req->{'path'}{'names'} = [ split(/\//, $req->{'path'}{'info'}) ];
  shift @{$req->{'path'}{'names'}};
  $req->{'path'}{'filename'} = $ENV{'PATH_TRANSLATED'} || '';
  
  # Current Script					 	# CGI 1.1
  $req->{'links'}{'script'} = $ENV{'SCRIPT_NAME'} || '';
  
  # IIS/NT sets path_info to links.script if it was otherwise empty 
  if ($req->{'path'}{'info'} eq $req->{'links'}{'script'}) {
    $req->{'path'}{'info'} = $req->{'file'}{'filename'} = '';
  }
  
  # IIS + SP3 adds SCRIPT_NAME to PATH_INFO and PATH_TRANSLATED
  # This may be fixed with the .dll's that ship with IE4.0
  if ($req->{'path'}{'info'} ne $req->{'links'}{'script'}) {
    $req->{'path'}{'info'} =~ s/\A\Q$req->{'links'}{'script'}\E//;
    $req->{'path'}{'filename'} =~ s/\A\Q$req->{'links'}{'script'}\E//;
  }
  
  # Netscape/NT puts a trailing slash on script_url if file_url ends with one
  $req->{'links'}{'script'} =~ s/[\/\\]\Z//;
  
  # Web Server Software						# CGI 1.1
  $req->{'web_server'}{'httpds'} = 
			[ split(/\s+/, ($ENV{'SERVER_SOFTWARE'} || '')) ];
  $req->{'web_server'}{'gateways'} = 
			[ split(/\//, ($ENV{'GATEWAY_INTERFACE'} || '')) ];
  $req->{'web_server'}{'protocols'} = 
			[ split(/\//, ($ENV{'SERVER_PROTOCOL'} || '')) ];
  $req->{'web_server'}{'secure'} = ( $ENV{'SERVER_PORT_SECURE'} or 
			  $ENV{'HTTPS'} && $ENV{'HTTPS'} =~ /on/i or
			  $req->{'web_server'}{'protocols'}[0] =~ /https/i);
  
  # Web Site							# CGI 1.1
  $req->{'site'}{'addr'} = $ENV{'SERVER_NAME'} || 'localhost';
  $req->{'site'}{'port'} = $ENV{'SERVER_PORT'} || 80;
  if ( $req->{'web_server'}{'secure'} ) {
    $req->{'site'}{'url'} = 'https://' . $req->{'site'}{'addr'} . 
      ($req->{'site'}{'port'} == 443  ? '' : ':'.$req->{'site'}{'port'});
  } else {
    $req->{'site'}{'url'} = 'http://' . $req->{'site'}{'addr'} . 
      ($req->{'site'}{'port'} == 80  ? '' : ':'.$req->{'site'}{'port'});
  }
  
  $req->{'site'}{'path'} = $ENV{'DOCUMENT_ROOT'} || '';		# Apache
  
  # User Authentication						# CGI 1.1
  $req->{'user'}{'authtype'} = $ENV{'AUTH_TYPE'} || 'none';
  $req->{'user'}{'login'} = $ENV{'REMOTE_USER'} || '';
  if ( $ENV{'REMOTE_IDENT'} and ! $req->{'user'}{'login'} ) {
    $req->{'user'}{'authtype'} = 'ident';
    $req->{'user'}{'login'} = $ENV{'REMOTE_IDENT'} || '';	# Not used much
  }
  
  # Client Information						# CGI 1.1
  $req->{'client'}{'hostname'} = $ENV{'REMOTE_HOST'} || '';
  $req->{'client'}{'ipaddr'} = $ENV{'REMOTE_ADDR'} || '';
  $req->{'client'}{'addr'} = $ENV{'REMOTE_HOST'}||$ENV{'REMOTE_ADDR'}||'';
  
  # Browser Information						# HTTP 1.1
  $req->set_browser_from_ua( $ENV{'HTTP_USER_AGENT'} || '' );

  $req->{'client'}{'accepts'} = [ split(/,\s*/, ($ENV{'HTTP_ACCEPT'} || '')) ];
  
  # State Information						# HTTP 1.1
  $req->{'client'}{'cookies'} = [ split /\;\s*/, ($ENV{'HTTP_COOKIE'} || '') ];
  
  $req->{'links'}{'back'} = $ENV{'HTTP_REFERER'} || '';
  
  return;
} 

# $req->read_arg_data;
sub read_arg_data {
  my $req = shift;
  
  # Buffer to read argument data stream into
  $req->{'data'} = '';
  debug 'cgi', "Reading request arguments";
  if ($req->{'method'} eq 'GET') {
    $req->{'data'} = $ENV{'QUERY_STRING'} || '';
  } elsif ($req->{'method'} eq 'POST') {
    binmode STDIN;
    my $len = read(STDIN, $req->{'data'}, $ENV{'CONTENT_LENGTH'});
    debug 'cgi', "Read $len from stdin";
  } else {
    die "unknown CGI Request method '$req->{'method'}'";
  }
} 


### Responding to Requests

# $req->send_reply( $page_or_file );
sub send_reply {
  my $req = shift;
    
  binmode STDOUT;
  
  my $key;
  foreach $key (keys %{$req->{'response_headers'}} ) {
    print $key . ': ' . $req->{'response_headers'}{$key} . "\n";
  }
  
  print "\n", $_[0];
}



1;

__END__

=head1 WebApp::Request::CGI

Requests via the Common Gateway Interface

=head2 Receving Requests

=over 4

=item WebApp::Request::CGI->request_available : $flag

Returns true once. This is plain-vanilla CGI, so we only get one request per execution.

=item $req->get_request_info

Loads all of the available information for the current request by calling $req->read_headers, $req->read_arg_data, and $req->parse_arg_data.

=item $req->read_headers

Examines the CGI environment variables to determine information about the current request.

=item $req->read_arg_data

Reads the arguments from the QUERY_STRING environment variable for GET requests, of from STDIN for POST methods. The argument data string is stored in $req->{'data'}.

=item $req->parse_arg_data

Based on the request's content_type, calls either $req->parse_urlencoded_args or $req->parse_multipart_args. Deletes $req->{'data'} and establishes $req->{'args'}.

=item $req->parse_urlencoded_args

Parses URL-encoded argument data.

=item $req->parse_multipart_args( $boundary )

Parses multipart argument data.

=item $req->query_string_from_args

Calculates a query_string which reflects the arguments we've recieved, whether from get or post.

=back


=head2 Responding to Requests

=over 4

=item $req->reply( $page_or_file )

Writes the response headers and reply body to STDOUT as an HTTP response.

=back

=head2 Contents of a CGI Request

Each request is a hash contains the following keys:

=over 4

=item method

The type of request made, generally GET or POST.

=item content_length

The number of bytes in the argument data.

=item content_type

The encoding of the argument data.

=item links

=over 4

=item script

The root-relative URL of the CGI script.

=item back

The URL of the page from which the current request was made, when available. 

=back

=item path

Any URL path information beyond that of the script.

=over 4

=item info

The path information.

=item names

An array of the slash-separated components in B<info>. For example, requesting http://localhost/webapp.cgi/potato/skins would produce path names of ['potato', 'skins'].

=item filename

The web server's assesment of which file is associated with the provided path info. 

=back

=item args

A hash of arguments received from the client. 

For example, a query string of 

    user=jsmith&date=19980315&command=View

would result in a request args hash equivalent to the following:

    'user' => 'jsmith',
    'date' => 19980315,
    'command' => 'View'

If multiple arguments with the same name are received from the client, an array is formed of each of those values. Dot characters in argument names are used to construct nested hashes. (See WebApp::Request->add_argument for details.)

=item site

Information about the web site we're running on.

=over 4

=item addr

The site host name or numeric IP address.

=item port

The port number the web server is running on, generally 80. 

=item url

An HTTP (or HTTPS) URL for the current site.

=item path

If provided by the web server, the root web document directory for this site. 

=back

=item web_server

Information about the web server that we're talking to

=over 4

=item protocols

An array of words identifying the request protocol. Generally [ 'HTTP', '1.0' ] or [ 'HTTP', '1.1' ].

=item gateways

An array of words identifying the gateway protocol. Generally [ 'CGI', '1.0' ] or [ 'CGI', '1.1' ].

=item httpds

An array of words identifying the gateway protocol. For example, [ 'Apache/1.2.5' ].

=item secure

A flag indicating that HTTPS is being used.

=back


=item client

A hash of information about the client, including:

=over 4

=item addr

The client's hostname, if available, or their IP address.

=item hostname

The client's hostname.

=item ipaddr

The client's numeric IP address.

=item accepts

An array of media types the client is prepared to accept. For example:

    [ 'image/gif', 'image/jpeg', 'image/png', 'image/tiff', '*/*' ]

=item cookies

An array of cookies sent by the client.

=item browser

The client's user-agent description. 

=back

=item user

A hash of information about the user, including:

=over 4

=item authtype

The type of user authentication in place. Generally none or Basic.

=item login

The login name authenticated by the web server.

=item ident

The user name retrieved by ident; generally not used.

=back

=item timestamp

The system time() at which we started reading the request.

=item response_headers

A hash of HTTP headers to include in the response message. Defaults to:

    'content-type' => 'text/html',
    'pragma' => 'no-cache'

=back

=back

=cut
