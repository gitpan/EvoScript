### WebApp::Resource::Site allows you to make things site-specific.

### Class Name
  # $classname = WebApp::Resource::Site->subclass_name();

### Request Handling
  # $rc = $site->handle_request( $request );
  # $self_url = $site->self_url;
  # $site->has_focus;
  # $site->lost_focus;

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-01-11 Added has_focus, lost_focus; moved get_descriptions to INApp.pm
  # 1997-12-02 Updated to use improved Resource functionality.
  # 1997-11-20 Created. -Simon

package WebApp::Resource::Site;

use WebApp::Resource::PropertyList;
push @ISA, qw( WebApp::Resource::PropertyList );

use Data::DRef;
use Data::Collection;
use Carp;

use Script::HTML::Tag;

WebApp::Resource::Site->register_subclass_name;

# $classname = WebApp::Resource::Site->subclass_name();
sub subclass_name { 'site' }

### Request Handling

# $rc = $site->handle_request( $request );
sub handle_request {
  my $site = shift;
  local $Request = shift;
  local $Root->{'request'} = $Request;
  
  $site->send_page_for_request( $Request );
}

# $self_url = $site->self_url;
sub self_url {
  my $site = shift;
  return $Request->{'links'}{'script'} . '/' . 
  	 $site->{'-name'} . '.' . $site->subclass_name;
}

# $site->has_focus;
sub has_focus {
  my $site = shift;
  
  setData('site', $site);
}

# $site->lost_focus;
sub lost_focus {
  setData('site', undef);
}

1;