### WebApp::Resource::PropertyList - resources defined in property list files.

### Change History
  # 1998-04-26 Modified write_source to skip '-.*' keys.
  # 1998-02-01 Fixed destructive shift on $resource->page_methods->{$name}.
  # 1998-01-16 Factored out of Resource superclass and existing subclasses. -S.

package WebApp::Resource::PropertyList;

use WebApp::Resource;
push @ISA, qw( WebApp::Resource );

use Text::PropertyList qw( astext fromtext );

### File Format

# $resource->read_source( $propertylist_text );
sub read_source {
  my $resource = shift;
  my $definition = fromtext( shift );
  foreach $key ( keys %$definition ) {
    next if ( $key =~ /\A\-/ );
    $resource->{ $key } = $definition->{ $key };
  }
  return;
}

# $propertylist_text = $resource->write_source;
sub write_source { 
  my $resource = shift;
  my %clean = map {$_, $resource->{$_}} grep {$_ !~ /\A\-/} keys %$resource;
  return astext( \%clean );
}

### Page Generation

# $rc = $resource->send_page_for_request( $request );
sub send_page_for_request {
  my $resource = shift;
  my $request = shift;
  
  my $pagename = $request->{'path'}{'names'}[1];
  $pagename = '-default' unless ( defined $pagename and length $pagename );
  
  my $page = $resource->page_for_request( $pagename );
  return 0 unless ( $page );
  
  $request->reply( $page->interpret );
  return 1;
}

# $page = $resource->page_for_request( $pagename );
sub page_for_request {
  my $resource = shift;
  my $pagename = shift;
  
  my $page;
  $page ||= $resource->scripted_page_by_name( $pagename );
  $page ||= $resource->page_by_name( $pagename );
  
  return $page;
}

# $method_hash = $resource->page_methods();
sub page_methods { return {}; }

# $page = $resource->page_by_name( $pagename );
sub page_by_name {
  my $resource = shift;
  my $pagename = shift;
  
  my $pagemethod = $resource->page_methods->{ $pagename };
  
  return unless $pagemethod;
  
  my $page;
  if ( ! ref $pagemethod ) {
    $page = $resource->$pagemethod();
  } else {
    my @args = @$pagemethod;
    my $methodname = shift @args;
    $page = $resource->$methodname( @args );
  }
  
  return $page;
}

# $page = $resource->scripted_page_by_name( $pagename );
sub scripted_page_by_name {
  my $resource = shift;
  my $pagename = shift;
  
  return unless ( $resource->{'pages'}{ $pagename } );

  $page = Script::Parser->new->parse( $resource->{'pages'}{ $pagename } );
  return $page;
}

1;

__END__

=head1 WebApp::Resource::PropertyList

Superclass for resources defined in property list files.

=head2 File Format

=over 4

=item $resource->read_source( $propertylist_text )

Parses the input as a L<Text::PropertyList> hash, then overwrites the contents of the resource with those key-value pairs. Keys begining with '-' are ignored.

=item $resource->write_source : $propertylist_text

Writes the resource's contents out as a L<Text::PropertyList> hash. Keys begining with '-' are ignored.

=back


=head2 Page Generation

=over 4

=item $resource->send_page_for_request( $request ) : $rc

=item $resource->page_for_request( $pagename ) : $page

=item $resource->page_methods : $method_hash

=item $resource->page_by_name( $pagename ) : $page

=item $resource->scripted_page_by_name( $pagename ) : $page

=back

=cut
