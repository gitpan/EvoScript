# Directory handler

### Interface
  # $flag = $handler->can_handle_file( $fn );
  # $reply = $handler->send_file( $fn );

### Change History
  # 1997-12-06 Made into a subclass of FileHandler.
  # 1997-11-04 Revised interface to match changes in FileHandler.
  # 1997-10-21 Created this handler. 

package WebApp::Handler::DirectoryHandler;

use WebApp::Handler::FileHandler;
unshift @ISA, qw( WebApp::Handler::FileHandler );

use strict;

# $flag = $handler->can_handle_file( $fn );
sub can_handle_file {
  my $handler = shift;
  my $fn = shift;
  return ( $fn->isdir );
}

# $reply = $handler->send_file( $request, $fn );
sub send_file {
  my $handler = shift;
  my $request = shift;
  my $fn = shift;
  
  my $message = "<html><head><title>Directory Listing</title></head>\n" . 
  		"<body bgcolor=white>\n" . 
  		"Directory information for " . $fn->path . "\n";
  
  my $child;
  foreach $child ( $fn->children ) {
    my $link = $child->name;
    $message .= "<br><a href=$link>" . $child->name . "</a>";
  }
  $message .= "</body></html>\n";
  
  $request->reply( $message );
}

1;