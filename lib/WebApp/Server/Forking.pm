### WebApp::Server::Forking - 

# fork after receving a request; child responds and dies
# parent looks for next request.

package WebApp::Server::Forking;

$VERSION = 1.02_00;

use WebApp::Server;
@ISA = WebApp::Server;

require 5.002;
use strict;

use Carp;
use Err::Debug;
use File::Name;

use vars qw( $PID_file_name );
$PID_file_name ||= '../logs/webapp.pid';

$SIG{'CHLD'} = sub { wait() };

# $server->startup;
sub startup {
  my $server = shift;
  $server->SUPER::startup;
  $server->run_standalone;
  $server->log_pid;
}

# $server->run_standalone;
  # Fork and run as child without STDIO.
sub run_standalone {
  my $server = shift;
  
  $server->fork_child or exit(0);
  
  # redirect STDIN and STDOUT
  open (STDIN, "</dev/null") || die "Could not redirect STDIN\n";
  open (STDOUT, ">/dev/null") || die "Could not redirect STDOUT\n";
}

# $server->log_pid;
  # Write our process ID to a file.
sub log_pid {
  my $server = shift;
  File::Name->new( $PID_file_name )->writer->print( $$ ) if ( $PID_file_name );
}

# $server->respond_to_request( $request );
sub respond_to_request {
  my ($server, $request) = @_;
  
  if ( $server->fork_child ) {
    $server->SUPER::respond_to_request( $request );
    exit 0;
  }
}

# $is_child_flag = $server->fork_child;
sub fork_child {
  my $server = shift;
  
  FORK: {
    my $pid = fork();
    
    warn "--- Forked!" if ( $pid == 0 );
    return 1 if ( $pid == 0 );     # child
    
    return 0 if ( defined $pid );  # server
    
    sleep 5, redo FORK if ( $! =~ /No more process/ );
    
    die "Can't fork: $!\n";
  }
}

1;

__END__

### Signal noise
# use POSIX ":sys_wait_h";
# use vars qw( %child );
# $SIG{'CHLD'} = sub { while ($_ = waitpid(-1,WNOHANG)) { $child{$_} = $?; } }
# and in fork_child, mark the child PID opened in the same hash.
# 
# In parent, to pass to children;
# $SIG{'HUP'} = sub { local $SIG{'HUP'} = 'IGNORE'; kill('HUP', -$$); };

