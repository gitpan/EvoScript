### WebApp::Request::FastCGI extends the CGI class to work with FCGI.

### Change History
  # 1998-05-15 Included clearing of HTTP_REFERER and PATH_TRANSLATED from 1.01.
  # 1998-05-14 Now PATH_INFO is cleared after each request. -Del
  # 1998-02-24 Partial integration with Err::LogFile.
  # 1998-02-17 Now CONTENT_TYPE is cleared after each request.
  # 1998-02-03 Experimented with Err::LogFile::stop_log/start_log.
  # 1997-10-20 Touch.
  # 1997-10-05 Created. -Simon

package WebApp::Request::FastCGI;

$VERSION = 4.00_02;

use WebApp::Request::CGI;
@WebApp::Request::FastCGI::ISA = qw( WebApp::Request::CGI );

use FCGI;
use Err::Debug;
use Err::LogFile;

$MaxRequests = 100;

# WebApp::Request::FastCGI->startup;
sub startup {
  while (($ignore) = each %ENV) { }; # Empty initial ENV hack
}

# $flag = WebApp::Request::FastCGI->request_available;
sub request_available {
  if ( ++ $Counter > $MaxRequests ) {
    debug 'fcgi', "server rollong over after $MaxRequests requests";
    return 0;
  }
  
  #!# Might be nice to wrap a timeout around the FCGI::accept call to reap
    # idle processes for dynamic FCGI.
  
  debug 'fcgi', "pausing for next request";
  
  Err::LogFile::stop_log if $Err::LogFile::Logger;
  
  my $rc = ( FCGI::accept() >= 0 );
  
  Err::LogFile::start_log if $Err::LogFile::Logger;
  
  if ( $rc ) {
    debug 'fcgi', "received fcgi request";
    return 1;
  } else {
    debug 'fcgi', "fcgi accept() failed!";
    return 0;
  }
}

sub done_with_request {
  my $request = shift;
  
  # FCGI v1 on NT fails to clear these if empty on the following request.
  $ENV{'CONTENT_TYPE'} = ''; 
  $ENV{'HTTP_REFERER'} = '';
  $ENV{'PATH_INFO'} = ''; 
  $ENV{'PATH_TRANSLATED'} = '';
  $ENV{'QUERY_STRING'} = ''; 
}

# WebApp::Request::FastCGI->at_end()
sub at_end {
  debug 'fcgi', "calling fcgi finish()";
  FCGI::finish();
}

1;

__END__

=head1 WebApp::Request::FastCGI

Extends Request::CGI to work with FCGI 

=over 4

=item WebApp::Request::FastCGI->startup

Cycles through the environment arguments to prevent the FCGI "empty initial args" problem.

=item WebApp::Request::FastCGI->request_available : $flag

Waits for FCGI::accept to deliver a request.

=item WebApp::Request::FastCGI->at_end

Calls FCGI::finish after the last request.

=back

=cut
