### File::SearchPath provides by-name file access across a group of directories
  # Two bonus packages, SearchPathSet and SearchPathProxy, are also included.

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-30 Changed add_paths() to avoid "Modification of a read-only value"
  # 1998-03-26 Inline POD added.
  # 1998-01-16 Created this package. -Simon

package File::SearchPath;

use File::Name qw( filename current_directory );

use Err::Debug;

### Instantiation

# $spath = File::SearchPath->new( @dir_filenames );
sub new {
  my $package = shift;
  
  my $spath = [];
  bless $spath, $package;
  debug('searchpath', "Creating SearchPath $spath");
  
  $spath->add_paths( @_ );
  
  return $spath;
}

sub DESTROY {
  debug('searchpath', "Destroying SearchPath $_[0]");
}

### Fetch/Store Dir path list

# $spath->add_paths( @dir_filenames );
sub add_paths {
  my $spath = shift;
  my @filenames = @_;
  my $fn;
  foreach $fn ( @filenames ) {
    debug 'searchpath', "Adding SearchPath files for $spath:", $fn;
    $fn = File::Name->current if ( $fn eq '.' );
    $fn = File::Name->new($fn) unless ( ref $fn );
    $fn->must_be_dir;
    unshift @$spath, $fn;
  }
}

# @paths = $spath->list_paths;
sub list_paths {
  my $spath = shift;
  return @$spath;
}

### Matching Files

# $file = $spath->file_by_name( $name );
sub file_by_name {
  my $spath = shift;
  my $name = shift;
  
  debug 'searchpath', "Looking for file named", $name;
  my $path;
  foreach $path ( $spath->list_paths ) {
    my $file = $path->child( $name );
    if ( $file->exists ) {
      debug 'searchpath', "Found file", $name, "in", $path->path;
      return $file;
    }
    debug 'searchpath', "Couldn't find file", $name, "in", $path->path;
  }
  debug 'searchpath', "Couldn't find file named", $name, "in search path";
  return 0;
}

# @files = $spath->all_files( $simple_wildcard_or_nothing );
sub all_files {
  my $spath = shift;
  my $pattern = shift;
  debug('searchpath', "Looking for file pattern", $pattern) if ( $pattern );
  
  my ( $file, %names, @results );
  my $path;
  foreach $path ( $spath->list_paths ) {
    debug 'searchpath', "Looking for files in", $path->path;
    foreach $file ( $path->children( $pattern ) ) {
      next if ( $names{ $file->name } ++ );
      push @results, $file;
    }
  }
  return @results;
}

### File::SearchPathSet provides a SearchPath interface for a set of SerchPaths

package File::SearchPathSet;

# $spathset = File::SearchPathSet->new( @dir_filenames );
sub new {
  my $package = shift;
  my $spathset = [];
  bless $spathset, $package;
  
  $spath->add_pathssets( @_ );
}

### Fetch/Store Dir path list

# $spathset->add_pathssets( @SearchPaths );
sub add_pathssets {
  my $spathset = shift;
  my $sp;
  foreach $sp ( @_ ) {
    unshift @$spathset, $sp;
  }
}

# $spathset->add_paths( @dir_filenames );
sub add_paths {
  my $spathset = shift;
  my $sp = ( $spathset->[0] ||= File::SearchPath->new );
  $sp->add_paths(@_);
}

# @paths = $spathset->list_paths;
sub list_paths {
  my $spathset = shift;
  my @paths;
  my $sp;
  foreach $sp ( @$spathset ) {
    push @paths, $sp->list_paths;
  }
  return @paths;
}

### Matching Files

# $file = $spathset->file_by_name( $name );
sub file_by_name {
  my $spathset = shift;
  my $name = shift;
  
  my $sp;
  foreach $sp ( @$spathset ) {
    my $fn = $sp->file_by_name( $name );
    return $fn if $fn;
  }
  return 0;
}

# @files = $spathset->all_files( $simple_wildcard );
sub all_files {
  my $spathset = shift;
  my $pattern = shift;
  
  my ( $file, %names, @results );
  my $sp;
  foreach $sp ( @$spathset ) {
    foreach $file ( $sp->all_files( $pattern ) ) {
      next if ( $names{ $file->name } ++ );
      push @results, $file;
    }
  }
  return @results;
}

### File::SearchPathProxy is a hash-based delegating proxy mixin class.

### Interface
  # $spath = $self->search_path;
  # Provides proxy methods that delegate to our private SearchPath

package File::SearchPathProxy;

# $spath = $self->search_path;
sub search_path  { (shift)->{'-search_path'} ||= File::SearchPath->new; }

# Provide proxy methods that delegate to our private SearchPath
sub add_paths    { (shift)->search_path->add_paths   ( @_ ); }
sub list_paths   { (shift)->search_path->list_paths  ( @_ ); }
sub file_by_name { (shift)->search_path->file_by_name( @_ ); }
sub all_files    { (shift)->search_path->all_files   ( @_ ); }

1;

__END__

=head1 File::SearchPath


=head2 Instantiation

=over 4

=item File::SearchPath->new( @dir_filenames ) : $spath

=back


=head2 Fetch/Store Dir path list

=over 4

=item $spath->add_paths( @dir_filenames )

Add the provided directory filenames to those held in this search path.

=item $spath->list_paths : @paths

Return a list of directory filename objects held in this search path.

=back


=head2 Matching Files

=over 4

=item $spath->file_by_name( $name ) : $file

Find the first file named $file in the $spath's directories.

=item $spath->all_files( $simple_wildcard_or_nothing ) : @files

Returns a list of all files found in the search path, or only those that 
match the provided wildcard pattern. If files with the same names exist
in multiple directories along the search path, only the first is returned.

=back


=head2 File::SearchPathSet 

Provides a SearchPath interface for a set of SerchPaths


=head2 Instantiation


=head2 Fetch/Store Dir path list


=head2 Matching Files


=head1 File::SearchPathSet

=over 4

=item File::SearchPathSet->new( @dir_filenames ) : $spathset

=back


=head2 Fetch/Store Dir path list

=over 4

=item $spathset->add_pathssets( @SearchPaths )

Add the provided directory filenames to those held in this search path

=item $spathset->add_paths( @dir_filenames )

Add the directories to our first searchpath, or make a new one to hold 'em.

=item $spathset->list_paths : @paths

Return a list of directory filename objects held in this search path

=back


=head2 Matching Files

=over 4

=item $spathset->file_by_name( $name ) : $file

Find the first file named $file in the $spath's directories.

=item $spathset->all_files( $simple_wildcard ) : @files

Returns a list of all files found in the search path, or only those that 
match the provided wildcard pattern. If files with the same names exist
in multiple directories along the search path, only the first is returned.

=back


=head1 File::SearchPathProxy

A hash-based delegating proxy mixin class.

=over 4

=item $self->search_path : $spath

=back

=cut
