### WebApp::Resource::ScriptedPage

### File Format
  # $page->read_source( $propertylist_text );
  # $propertylist_text = $page->write_source;

### Page Generation
  # $page = $page->scripted_page_by_name( $pagename );
  # $page = $page->page_by_name( $pagename );
  # $page = $page->page_for_request( $pagename );
  # $rc = $page->send_page_for_request( $pagename );

### Change History
  # 1998-05-29 Switched to use of Script::Evaluate package instead of Script.
  # 1998-02-24 Created. -Simon

package WebApp::Resource::ScriptedPage;

$VERSION = 4.00_01;

use WebApp::Resource;
push @ISA, qw( WebApp::Resource );

WebApp::Resource::ScriptedPage->register_subclass_name;
sub subclass_name { 'page' }

use Script::Parser;
use Data::DRef qw( $Root );

### File Format

# $page->read_source( $script_text );
sub read_source {
  my $page = shift;
  $page->{'elements'} = Script::Parser->new->parse( shift );
}

# $script_text = $page->write_source;
sub write_source { 
  my $page = shift;
  return $page->{'elements'}->source;
}

### Request Handling

# $rc = $page->handle_request( $request );
sub handle_request {
  my $page = shift;
  my $request = shift;
  
  local $Root->{'request'} = $request;
  $request->reply( $page->{'elements'}->interpret );
}

1;