### WebApp::Resource::Config models configuration files

### Inherits
  # $resource = WebApp::Resource->new_from_definition( $hashref );
  # $resource = WebApp::Resource->new_from_text( $propertylist_text );

### Resource Subclass (registered as "conf")

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1997-11-10 Created.

package WebApp::Resource::Config;

### Resource Subclass (registered as "conf")

use WebApp::Resource;
unshift @ISA, qw( WebApp::Resource );

WebApp::Resource::Config->register_subclass_name;
sub subclass_name { 'conf' }

1;
