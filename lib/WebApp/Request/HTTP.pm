### WebApp::Request::HTTP listens for HTTP requests.

### Copyright 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License.
  # Based in part on Kirves 0.22, Copyright 1996 Göran Thyni

### Change History
  # 1998-04-09 Further testing; 
  # 1998-03-23 Created.

package WebApp::Request::HTTP;

$VERSION = 1.01_00;

use WebApp::Request;
push @ISA, qw( WebApp::Request );

use Carp;
use Err::Debug;

use HTTP::Daemon;
use Net::Domain qw(hostfqdn);

require 5.000;
use strict;

use vars qw( $HTTP_Daemon $HTTP_Socket $PortNumber );
$PortNumber ||= 8000;

# WebApp::Request::HTTP->import( 'port' => number );
sub import {
  my $package = shift;
  while ( $_ = shift ) {
    if ( $_ eq 'port' ) {
      $PortNumber = shift;
    } else {
      die "unknown import";
    }
  }
}

# WebApp::Request::HTTP->startup;
sub startup {
  my $class = shift;
  
  $HTTP_Daemon = HTTP::Daemon->new( 'LocalPort'=>$PortNumber );
  #		 		'LocalAddr'=>'www.evolution.com');
  die "Unable to start daemon on $PortNumber" unless $HTTP_Daemon;
  warn "Starting HTTP Daemon $HTTP_Daemon on port $PortNumber\n";
}

# $flag = WebApp::Request::FastCGI->request_available;
sub request_available { 
  my $class = shift;
  
  # $HTTP_Daemon->close if it's open.
  $HTTP_Socket = $HTTP_Daemon->accept;
  
  return 0 unless $HTTP_Socket;
  
  $HTTP_Socket->autoflush(1);
}

sub done_with_request {
  my $class = shift;
  $HTTP_Socket->close;
}

END {
  $HTTP_Daemon->close if $HTTP_Daemon;
}

# $request->read_headers;
sub read_headers {
  my $request = shift;
  
  my $http_request = $HTTP_Socket->get_request;
  $request->{'http_req'} = $http_request;
  
  $request->{'method'} = $http_request->method;
  $request->{'content_type'} = $http_request->content_type ||
				      'application/x-www-form-urlencoded';
  
  $request->{'path'}{'info'} = $http_request->url->epath();
  
  $request->{'path'}{'names'} = [ split(/\//, $request->{'path'}{'info'}) ];
  shift @{$request->{'path'}{'names'}};
  
  # Base on root directory and above name; look for matches.
  # $request->{'path'}{'filename'} = $ENV{'PATH_TRANSLATED'} || '';
  
  $request->{'client'}{'ipaddr'} = $HTTP_Socket->peerhost();
  $request->{'client'}{'hostname'} = 
			  gethostbyaddr($HTTP_Socket->sockaddr(), AF_INET);
  
  $request->{'site'}{'addr'} = hostfqdn() || 'localhost';
  $request->{'site'}{'port'} = $PortNumber;
}

# $request->read_arg_data;
sub read_arg_data { 
  my $request = shift;
  
  # Buffer to read argument data stream into
  $request->{'data'} = '';
  debug 'http', "Reading request arguments";
  
  if ($request->{'method'} eq 'GET') {
    $request->{'data'} = $request->{'http_req'}->url->equery || '';
  } elsif ($request->{'method'} eq 'POST') {
    $request->{'data'} = $request->{'http_req'}->content;
    debug 'http', "Read " . length($request->{'data'}) . " from client";
  } else {
    die "unknown Request method '$request->{'method'}'";
  }
}

# $req->send_reply( $page_or_file );
sub send_reply {
  my $request = shift;
  
  my $status = 200;
  my $http_response = HTTP::Response->new($status);
    
  my $key;
  foreach $key (keys %{$request->{'response_headers'}} ) {
    $http_response->push_header($key, $request->{'response_headers'}{$key});
  }
  
  $http_response->add_content( $_[0] );
  $HTTP_Socket->send_response($http_response);
}


1;
