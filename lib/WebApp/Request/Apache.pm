### Apache mod_perl interface

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License.
  #
  # Cribbed from CGI::Apache, originally by Doug MacEachern <dougm@osf.org>, 
  # hacked over by Andreas König <a.koenig@mind.de>, modified by Lincoln Stein 
  # <lstein@genome.wi.mit.edu>

### Caveats and Things To Do
  #!# Needs to be better integrated with the CGI code

### Change History
  # 1998-02-06 Brief review.
  # 1998-01-30 Created. -Simon

package WebApp::Request::Apache;

use WebApp::Request::CGI;
@WebApp::Request::Apache::ISA = qw( WebApp::Request::CGI );

use Apache;
use Err::Debug;

$MaxRequests = 100;

# $flag = WebApp::Request::FastCGI->request_available;
sub request_available {
  my $package = shift;
  %ENV = Apache->request->cgi_env; 
  return 1;
}

# $req->send_reply( $page_or_file );
sub send_reply {
  my $req = shift;
  
  my $apache = Apache->request;
  $apache->basic_http_header;
  
  my $key;
  foreach $key (keys %{$req->{'response_headers'}} ) {
    $apache->print( $key . ': ' . $req->{'response_headers'}{$key} . "\n" );
  }
  
  $apache->print( "\n", $_[0] );
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
    Apache->request->read($req->{'data'}, $ENV{'CONTENT_LENGTH'});
  } else {
    die "unknown CGI Request method '$req->{'method'}'";
  }
} 

1;
