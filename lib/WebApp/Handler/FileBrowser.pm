####

### Change History
  # 1998-05-29 Switched to use of Script::Evaluate package instead of Script.
  # 1998-03-02 Resurected.
  # 1996-08-17 Created. -Simon

package WebApp::Handler::FileBrowser;

use Data::DRef;

use WebApp::Handler::FileHandler;
unshift @ISA, qw( WebApp::Handler::FileHandler );

use strict;
use Script::Evaluate qw( runscript );

# $flag = $handler->can_handle_file( $fn );
sub can_handle_file { 1 }

# $reply = $handler->send_file( $request, $fn );
sub send_file {
  my $handler = shift;
  my $request = shift;
  my $fn = shift;
  setData('request', $request);
  
  my $script_url = getData('request.links.script');
  my $path_info = getData('request.path.info');
  my $site_addr = getData('request.site.addr');
  my $file_path = $fn->path;
  
  my $view = $request->{'args'}{'view'} || 'frameset';
  my $message;
  if ( $view eq 'frameset' ) {
    $message = <<SCRIPTEND;
      <html><head>
      <title>Browse $site_addr $file_path</title>
      </head>
      <frameset rows="200,*">
	<frame name=browsers src=$script_url$path_info?view=browser>
	<frame name=content src=$path_info>
      </frameset>
      </html>
SCRIPTEND
    # $message = runscript( $message );
  } 
  elsif ( $view eq 'blank' ) {
    $message = "<html><head><title></title></head>
  <body bgcolor=#aaaaaa text=#000000 link=#000033 alink=#330000 vlink=#000000>
    </body></html";
  } 
  elsif ( $view eq 'dir' ) {
    $message = "<html><head><title></title></head>
  <body bgcolor=#aaaaaa text=#000000 link=#000033 alink=#330000 vlink=#000000>
    <p align=center>
    <img src=/images/fileicons/folder.gif width=48 height=48 border=0>
    <br>".$fn->name."</p><p>";
    
    my $child;
    foreach $child ( sort { lc($$a) cmp lc($$b) } $fn->children ) {
      next if ( $child->name =~ /\A\./ );
      next if ( $child->name =~ /\~\Z/ );
      my $link = $path_info . '/' .$child->name;
      $link =~ s/\/\//\//g;
      my $depth = $#{ $request->{'path'}{'names'} } + 1;
      $depth += 2;
      $message .= "\n<br><a target=content href=$link>" . $child->name . "</a>";
      $message .= "<a target=browser$depth href=\"$script_url$link?view=dir\"><img align=right src=/images/fileicons/dir_indic.gif vspace=0 border=0></a>" if $child->isdir;
    }
    $message .= "</body></html";
  } 
  elsif ( $view eq 'browser' ) {
    my $pane_count = 4;
    my $depth = $#{ $request->{'path'}{'names'} } + 1;
    my $deepest = ($pane_count>($depth)) ? $pane_count : ($depth);
    
    my $cols = ('*,' x $pane_count); chop $cols;
    $message = "<frameset cols=\"$cols\">\n";
    my $col;
    foreach $col (1..$deepest) {
      if ($col + $pane_count < $deepest) {
	next;
      } elsif ($col - 1  > $depth) {
	$message .= ("<frame name=browser$col src=\"$script_url$path_info?view=blank\" marginheight=2 marginwidth=2 scrolling=vertical noresize>\n");
      } else {
	my (@dirpath) = @{ $request->{'path'}{'names'} };
	@dirpath = splice (@dirpath,0,$col);
	my $dirpath = join ('/', @dirpath);
	$message .= "<frame name=browser$col src=\"$script_url$path_info?view=dir\" marginheight=2 marginwidth=2 scrolling=vertical noresize>\n";
	}
    }
    $message .= "</frameset>\n";
    
  } else {
    $message = "unknown view";
  }  
  $request->reply( $message );
}

