### WebApp::Resource::SiteHandler loads information about the current site.

### Interface
  # $handler->starting_request($request);
  # $rc = $handler->handle_request($request);
  # $handler->done_with_request($request);

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-01-11 Support for simple regexes in hostname => site_id mapping.
  # 1997-11-28 New handle_request maps no-path requests to the site resource
  # 1997-11-23 Created. -Simon

package WebApp::Handler::SiteHandler;

use WebApp::Handler;
push @ISA, qw( WebApp::Handler );

use File::Name;
use WebApp::Resource;
use Err::Debug;
use Data::DRef;

use vars qw( $Site %Sites );

# $handler->starting_request($request);
sub starting_request {
  my $handler = shift;
  my $request = shift;
  
  my $addr = $request->{'site'}{'addr'};
  my $site_id = $handler->siteid_by_addr( $addr );
  debug('site', 'Site address is', $addr, '('.($site_id || 'UNKNOWN').')' );
  
  $Site = WebApp::Resource->new_from_full_name( $site_id . '.site' );
  
  debug('site', "Site focus is now $Site");
  
  $Site->has_focus;
  
  return;
}

# $siteid = $handler->siteid_by_addr( $hostname )
sub siteid_by_addr {
  my $handler = shift;
  my $hostname = shift;
  
  my $site_id;
    
  my $name;
  foreach $name ( sort { length $b <=> length $a } keys %Sites ) {
    next if ($name =~ /\Adefault\Z/i);
    
    # Based on File::Name::simple_wildcard_to_regex();
    my $regex = quotemeta ($name);
    $regex =~ s/\\\*/\.\*/;
    $regex =~ s/\\\?/\./;
    
    if ( $hostname =~ /\A$regex\Z/i ) {
      $site_id = $Sites{ $name };
      last;
    }
  }
  
  $site_id ||= $Sites{'default'} if ( defined $Sites{'default'} );
  
  return $site_id;
}

# $rc = $handler->handle_request($request);
sub handle_request {
  my $handler = shift;
  my $request = shift;
  
  return 0 if ( length ( $request->{'path'}{'names'}[0] || '' ) );
  
  $Site->handle_request( $request );
}

# $handler->done_with_request($request);
sub done_with_request {
  my $handler = shift;
  my $request = shift;
  
  $Site->lost_focus;
  
  undef $Site;
  
  return;
}

1;