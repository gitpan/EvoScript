### WebApp::Resource is the superclass for file-based application objects.

### Instantiation
  # $resource = WebApp::Resource::SUBCLASS->new;

### Request Handling
  # $rc = $site->handle_request( $request );		Abstract

### SearchPath By-Name Access
  # $resource = WebApp::Resource->new_from_full_name( $name_with_extension );
  # $resource = WebApp::Resource::SUBCLASS->new_from_name( $short_name );
  # @resources = WebApp::Resource->resources_by_type( $file_extension );
  # @resources = WebApp::Resource::SUBCLASS->resources();

### File I/O
  # $resource = WebApp::Resource->new_from_file( $filename );
  # $resource->load_from_file;
  # $resource->reload_if_needed;
  # $flag = $resource->disk_has_changed;
  # $resource->write_to_file;

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-05-07 Switched from (g|s)et_contents to (g|s)et_text_contents.
  # 1998-04-28 Added object_for_file with filename-based cache.
  # 1998-03-05 Set file info before read_source to allow init-time behaviour.
  # 1998-02-27 Added resources() method.
  # 1998-02-24 Fixed typo in error message.
  # 1998-01-16 Moved path-list management into new File::SearchPath package.
  # 1997-12-02 Overhaul of file-access methods; improved site path mapping.
  # 1997-11-05 Added site-specific path list.
  # 1997-11-04 Added new_from_name, new_from_file, add_path, path_list().
  # 1997-11-04 Refactored factory methods into SubclassFactory.pm.
  # 1997-11-03 Created.

package WebApp::Resource;

$VERSION = 1.02_00;

use Carp;
use Err::Debug;

use Class::NamedFactory;
push @ISA, qw( Class::NamedFactory );
use vars qw( %ResourceClasses );
sub subclasses_by_name { \%ResourceClasses; }

use File::SearchPath;
use vars qw( $SearchPath );
sub search_path { $SearchPath ||= File::SearchPath->new('.') }

use strict;

### Instantiation

# $resource = WebApp::Resource::SUBCLASS->new;
sub new {
  my $package = shift;
  my $resource = {};
  bless $resource, $package;
  debug('resources', "Creating resource $resource");
  return $resource;
}

sub DESTROY {
  my $resource = shift;
  debug('resources', "Destroying resource $resource");
}

### Request Handling

# $rc = $site->handle_request( $request );		Abstract
sub handle_request { die "abstract method" }

### SearchPath By-Name Access

# $resource = WebApp::Resource->new_from_full_name( $name_with_extension );
sub new_from_full_name {
  my $package = shift;
  my $name = shift;
  debug('resources', 'Looking for resource named', $name);
  my $file = $package->search_path->file_by_name( $name );  
  return unless ( $file and $file->exists );
  $package->object_for_file( $file );
}

# $resource = WebApp::Resource::SUBCLASS->new_from_name( $short_name );
sub new_from_name {
  my $package = shift;
  WebApp::Resource->new_from_full_name($_[0] . '.' . $package->subclass_name); 
}

# @resources = WebApp::Resource->resources_by_type( $file_extension );
sub resources_by_type {
  my $package = shift;
  my $extension = shift;
  return map { $package->object_for_file($_) } 
		( $package->search_path->all_files("*.$extension") );
}

# @resources = WebApp::Resource::SUBCLASS->resources();
sub resources {
  my $package = shift;
  WebApp::Resource->resources_by_type($package->subclass_name); 
}

### File I/O

use vars qw( %Cache );

# WebApp::Resource->empty_cache
sub empty_cache { %Cache = (); }

# $resource = WebApp::Resource->object_for_file( $filename );
sub object_for_file {
  my $package = shift;
  my $fn = shift;
  
  if ( $Cache{ $$fn } ) {
    $Cache{ $$fn }->reload_if_needed;
  } else { 
    $Cache{ $$fn } = $package->new_from_file( $fn );
  }
  return $Cache{ $$fn };
}

# $resource = WebApp::Resource->new_from_file( $filename );
sub new_from_file {
  my $package = shift;
  my $fn = shift;
  
  debug 'resources', "Loading resource from" , $fn->path ;
  
  my $subclass = $package->subclass_by_name( $fn->extension ) 
	      or croak "Couldn't find Resource class to handle " . $fn->path;
  
  my $resource = $subclass->new;
  $resource->{'-filename'} = $fn;
  $resource->load_from_file;
  
  return $resource;
}

# $resource->load_from_file;
sub load_from_file {
  my $resource = shift;
  
  my $fn = $resource->{'-filename'};
  debug 'resources', 'loading resource', "$resource", 'from', $fn;
  
  $resource->{'-filename'} = $fn;
  $resource->{'-name'} = $fn->base_name;
  $resource->{'-loadage'} = $fn->age_since_change;
  
  $resource->read_source( $fn->get_text_contents );
}

# $resource->reload_if_needed;
sub reload_if_needed {
  my $resource = shift;
  if ( $resource->disk_has_changed ) {
    debug 'resources', 'reloading resource', "$resource";
    $resource->load_from_file;
  } else {
    debug 'resources', 'resource', "$resource", 'hasn\'t changed.';
  }
}

# $flag = $resource->disk_has_changed;
sub disk_has_changed {
  my $resource = shift;
  my $d = $resource->{'-loadage'} - $resource->{'-filename'}->age_since_change;
  debug 'resources', 'file changed', $d, 'days ago' if ( $d );
  return $d;
}

# $resource->write_to_file;
sub write_to_file {
  my $resource = shift;

  my $fn = $resource->{'-filename'};
  
  # 1998-01-19 When saving, sometimes the filename is just a string;
  #            not clear why, but for now, we'll rebless it if needed. -Simon
  $fn = File::Name->new( $fn ) if ( defined $fn and length $fn and ! ref $fn );
  
  # local $resource->{'-name'};
  # local $resource->{'-filename'};
  # local $resource->{'-loadage'};
  
  $fn->set_text_contents( $resource->write_source );
}

1;

__END__




=head2 WebApp::Resource

Resources are persistant application objects defined in files. The filename extension is used to determine which Resource subclass to associate it with.

=over 4

=item WebApp::Resource->search_path

Returns the File::SearchPath object the tracks the directories to be scanned for resource files. All file access is provided via the file_by_name and all_files methods on this object. As a result, directories earlier in the search_path mask files in the later directories.

=item WebApp::Resource->new_from_full_name( $name_dot_extention )

=item WebApp::Resource::SubClass->new_from_name( $name_only )

Search for a file with the provided name and extention, or the extension associated with this subclass, and if it's found, return its resource object.

=item WebApp::Resource->resources_by_type( $file_extension )

Returns all of the resources of this type that can be found in the search path.

=item $resource->handle_request( $request )

Called when a page has been requested from this resource. This is generally set up as a switch based on the second item in the URL path info.

=back

The currently available concrete subclasses are:

=over 4

=item ScriptedPage

Text file to be parsed and interpreted using the Script framework.

=item Site

A site configuration file.

=item Records

A database table and assocatiated pages.

=back

