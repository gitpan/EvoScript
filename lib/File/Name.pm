### The File::Name class provides file path objects and related operations.
  # Primarily an OOP wrapper for functionality from FileHandle, Basename, Cwd.

### Caveats and Things To Do
  # - Simple_wildcard_to_regex is pretty general purpose; maybe split it out,
  # or use one of the pre-existing modules (KGlobRE?) to do the same thing.
  # - Perhaps re-export the Fcntl O_ constants.

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # This is free software; you can use it under the same terms as Perl itself.
  # Portions based on File::PathConvert, (c) 1996, 1997, 1998 Shigio Yamaguchi.
  # Temp directory logic based on CGI.pm. Copyright 1995-1997 Lincoln D. Stein.

### Change History
  # 1998-06-12 Added new_typed_filled_temp method. -Simon
  # 1998-06-04 Added Temp subclass; it's only concrete method is a DESTROY that
  #            ensures the underlying file, if it still exists, is deleted when
  #            the filename goes out of scope.  Typical usage would be to bless
  #            an existing File::Name object into File::Name::Temp. -Del
  # 1998-05-29 Added append and text_lines methods.
  # 1998-05-07 Added temp_dir and new_temp methods.
  # 1998-04-22 Added non-binmode *_text_* and low-level sys_* methods.
  # 1998-04-13 Made use of binmode universal; commented out sysread/write code
  # 1998-04-06 Added explicit import from Data::DRef. -Simon
  # 1998-04-02 Use sysread/syswrite in place of read/print (performance). 
  # 1998-03-31 Added binmode logic. 
  # 1998-03-31 Corrected test in ensure_is_dir(); corrected move_to_dir. -Del
  # 1998-03-26 Added O_TRUNC to the open_writer FileHandle/Fcntl mode.
  # 1998-03-20 Added descendents method.
  # 1998-02-26 Mucked with permits method.
  # 1998-02-25 Added absolute and make_absolute methods.
  # 1998-02-22 Worked on relatives; split out File::SystemType package. -Simon
  # 1998-02-?? Added create_path, can_create_path, other functions. -Jeremy
  # 1998-02-01 Added ext_for_mediatype.
  # 1998-01-26 Added move_to_dir and ensure_is_dir method for directories.
  # 1998-01-21 Switched to Fcntl constants for FileHandle open modes.
  # 1998-01-21 Instruct File::Basename to use MSDOS rules when we're on Win32.
  # 1997-12-15 Added preliminary unique_variation method.
  # 1997-12-02 Added base_name.
  # 1997-10-06 Created File::Name package based on version 3 of Evo::file.
  # 1997-09-25 Minor change to regularize warning
  # 1997-08-08 Working on regularize to handling differing dirseps.
  # 1997-08-07 Forced immediate close on filehandles in getFile.
  # 1997-08-03 Argh! More binmode madness.
  # 1997-03-23 Improved exception handling.
  # 1997-03-** Minor updates.
  # 1997-01-13 Created Evo::file module. -Simon

package File::Name;

use vars qw( $VERSION );
$VERSION = 1.00_03;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( filename current_directory );

use strict;
use Carp;

use Fcntl;
use FileHandle;
use Cwd;
use File::Basename;
fileparse_set_fstype('MSDOS') if ( $^O =~ /Win32/ );

use File::SystemType;
use vars qw( $SL );
$SL = File::SystemType->directory_separator;

use Data::DRef qw( shiftdref );
use Err::Debug;

# $regex = simple_wildcard_to_regex( $simple_wildcard_with_stars );
  # Protect all meta characters, then convert * and ? to their Perl equivalents
sub simple_wildcard_to_regex {
  my $filemask = shift;
  $filemask = quotemeta ($filemask);
  $filemask =~ s/\\\*/\.\*/;
  $filemask =~ s/\\\?/\./;
  return $filemask;
}

### Instantiation

# $fn = filename($path);
sub filename ($) { File::Name->new(@_); }

# $fn = current_directory();
sub current_directory () { File::Name->current(); }

# $fn = File::Name->new( @path_name_elements ); 
  # pass series of relative path elements
sub new ($$) {
  my $referent = shift;
  my $class = ref $referent || $referent;
  
  my $path = '';
  my $fn = \$path;
  bless $fn, $class;
  
  my $base = shift;
  $fn->path( ref $base ? ($base)->path : $base );
  $fn->regularize();
  
  while ( scalar @_ ) {
    $fn = $fn->relative( shift );
  }
  
  return $fn;
}

# $fn = File::Name->current();
sub current ($) {
  my $class = shift;
  my $path = cwd;
  my $fn = \$path;
  bless $fn, $class;
}

# $fn_str = regularize( $fn_str );
sub regularize ($) {
  my $fn = shift;
  
  my $fn_str = $fn->path;
  
  my $original = $fn_str;
  
  # forward and back slashes forced to local dialect
  $fn_str =~ s/[\/\\]/$SL/g;
  
  # initial /../  -> /
  $fn_str =~ s/\A\Q$SL\E\.\.\Q$SL\E/$SL/g;
  
  # initial /./   -> /
  $fn_str =~ s/\A\Q$SL\E\.\Q$SL\E/$SL/g;
  
  # multiple ///  -> /
  $fn_str =~ s/(?:\Q$SL\E)+/$SL/g;
  
  # dirname/../    -> removed
  $fn_str =~ s/(\Q$SL\E|\A)[^\Q$SL\E]+\Q$SL\E\.\.(\Q$SL\E|\Z)/$1/g;
  
  # 1998-03-05 This is a bit of a beast. Must avoid discarding '../..' paths.
  #!!!# Not sure why /g isn't enough, but multiple uses are needed.
  # do { $_ = ($fn_str =~ s/(\Q$SL\E|\A)(?:[^\.\Q$S\E]|[^\.\Q$S\E][^\Q$S\E]|[^\Q$S\E][^\.\Q$S\E])[^\Q$SL\E]*\Q$SL\E\.\.(\Q$SL\E|\Z)/$1/g) } while ( $_ );
  
  # trailing /.    -> /
  $fn_str =~ s/\Q$SL\E\.\Z/$SL/;
  
  # trailing /    -> removed
  $fn_str =~ s/(.)\Q$SL\E\Z/$1/;
  
  unless ($original eq $fn_str) {
    debug 'filename', "Regularized filename", $original;
    debug 'filename', "         name is now", $fn_str;
  }
  
  $fn->path( $fn_str );
}

### Relatives

# $fn = $root_fn->relative( $partial_path );
sub relative($;$) {
  my $fn = shift;
  my $offset = File::Name->new( shift );
  return $offset if $offset->is_absolute;
  return $fn->new( $fn->path . $SL . $offset->path );
}

# $flag = $fn->is_absolute();
sub is_absolute {
  my $fn = shift;
  my $fs_type = File::SystemType::file_system_type;  
  if ( $fs_type eq 'Win32' or $fs_type eq 'MSDOS' ) {
    return 1 if ( $fn->path =~ /\A(\w\:)?[\/\\]/ );
  } else {
    return 1 if ( $fn->path =~ /\A\// );
  }
  return 0;
}

# $absolute_fn = $fn->absolute;
sub absolute {
  my $fn = shift;
  return $fn if $fn->is_absolute;
  File::Name->current->relative( $fn );
}

# $fn->make_absolute;
  # Against current directory.
sub make_absolute {
  my $fn = shift;
  return if $fn->is_absolute;
  $fn->path( cwd() . $SL . $fn->path );
  $fn->regularize();
}

### Path and Name

# $fn->path($path);
# $path = $fn->path; 
sub path {
  my $fn = shift;
  $$fn = shift if ( scalar @_ );
  carp "path is empty" unless (defined $$fn and length $$fn);
  return $$fn;
}

# $name = $fn->name;
sub name {
  my $fn = shift;
  my ($name, $parent) = fileparse($fn->path);
  return $name;
}

# $name = $fn->base_name;
sub base_name {
  my $fn = shift;
  my ($name, $parent) = (fileparse($fn->path, '\\.\\w+'))[0];
  return $name;
}

# $flag = $fn->hasextension( $extn );
sub hasextension {
  my $fn = shift;
  my $ext = shift;
  my ($name, $parent, $match) = fileparse($fn->path, "(?i)\\.\Q$ext\E");
  return length($match) ? 1 : 0;
}

# $extension = $fn->extension;
sub extension {
  my $fn = shift;
  my ($name, $parent, $ext) = fileparse($fn->path, '\\.\\w+');
  $ext =~ s/\A\.//; # or die "what happened to the period?";
  return $ext;
}

# $similar_but_nonexistant_fn = $fn->unique_variation;
sub unique_variation {
  my $fn = shift;
  
  my $candidate = $fn->new( $fn->path );
  my ($name, $parent, $extention) = (fileparse($fn->path, '\\.\\w+'));
  my $base = $parent . $name;
  my $n = 0;
  while ( ++ $n < 1000 ) {
    return $candidate unless $candidate->exists;
    #!# We should really fileparse(), then reassemble "$name\.$n\.$ext"
    $$candidate = $base . '.' . $n . $extention;
  }
  die "couldn't produce a unique variation on " . $fn->path . 
  	", there must be a thousand of them!\n";
}

### Permissions; Updates

# $fn->permits( $permission_bits );	Dies if chmod doesn't succeed
sub permits {
  my $fn = shift;
  my $perms = shift;
  
  croak "file permits called without argument" unless (defined $perms);
  $fn->must_exist;
  
  chmod( $perms, $fn->path )
    or croak "can't set permissions for " . $fn->path;
}

# $fn->delete();
sub delete {
  my $fn = shift;
  return unless $fn->exists();
  if ( $fn->isdir() ) {
    my $child;
    foreach $child ( $fn->children() ) { $child->delete() }
    rmdir $fn->path or die "Can't remove dir '" . $fn->path . "': $_";
  } else {
    unlink $fn->path or die "Can't unlink file '" . $fn->path . "': $_";
  }
  return;
}

### Directories

# $parent_fn = $fn->parent;
sub parent {
  my $fn = shift;
  my $dirname = dirname( $fn->path );
  return $fn->new($dirname);
}

# $child_fn = $fn->child( $name );
sub child {
  my $fn = shift;
  $fn->must_be_dir;
  File::Name->new( $fn->path, shift );
}

# @children = $fn->children;
# @children = $fn->children( $simple_name_regex )
sub children {
  my $fn = shift;
  my $wildcard = shift || '';
  my $regex = (length $wildcard) ? simple_wildcard_to_regex($wildcard) : '';
  
  $fn->must_be_dir;
  wantarray or die "can't call children in a scalar context";
  
  my $path = $fn->path;
  unless ( opendir(DIR, $path) ) {
    warn "Couldn't read files from $path\n";
    return;
  }
  my(@filenames) = readdir(DIR);  closedir(DIR);  
  # Skip . and .. entries
  @filenames = grep { $_ !~ /\A\.\.?\Z/ } @filenames;  
  # Only get matching files
  @filenames = grep( /\A${regex}\Z/i, @filenames) if (length $regex);  
  return map { $fn->child($_) } @filenames;
}

# @directories = $fn->sub_directories;
sub sub_directories {
  my $fn = shift;
  grep { $_->isdir } $fn->children;
}

# @offspring = $fn->descendents;
# @offspring = $fn->descendents( $simple_name_regex )
sub descendents {
  my $fn = shift;
  my $wildcard = shift || '';
  
  return ( 
    $fn->children( $wildcard ), 
    map { $_->descendents($wildcard) } $fn->sub_directories 
  );
}

# $fn->ensure_is_dir			Dies if directory can't be created
sub ensure_is_dir {
  my $fn = shift;
  return if $fn->exists;
  
  mkdir($fn->path, 0777) or die "can't make dir '" . $fn->path . "'\n";
  $fn->permits( 0777 );
}

# $fn->create_path()			Dies if path can't be created
# $fn->create_path( $permission_bits )
sub create_path {
  my ($fn, $perms) = @_;
  
  unless ( $fn->exists() ) {
    until ( $fn->parent->exists() ) { $fn->parent->create_path( $perms ); }
    mkdir( $fn->path, $perms ) or die "can't make dir " . $fn->path . "\n";
    $fn->permits( $perms || 0777 );
  }
  
  return;
}

# $flag = $fn->can_create_path()
sub can_create_path {
  my $fn = shift;
  return $fn->exists ? $fn->writable : $fn->parent->can_create_path;
}

# $fn->move_to_dir( @fn );
sub move_to_dir {
  my $fn = shift;
  $fn->ensure_is_dir;
  my $file;
  foreach $file ( @_ ) {
    rename( $file->path, $fn->relative($file->name)->path ) 
      or die "Couldn't move " . $file->path . " into " .  $fn->path . "\n"; 
  }
  return;
}

### Types and Info

# $flag = $fn->exists();
sub exists {
  my $fn = shift;
  return ( -e $fn->path ) ? 1 : 0;
}

# $fn->must_exist();   				exception unless exists
sub must_exist {
  my $fn = shift;
  $fn->exists() or die "required file '" . $fn->path . "' doesn't exist\n";
  return;
}

# $flag = $fn->isdir();
sub isdir {
  my $fn = shift;
  return ( -d $fn->path ) ? 1 : 0;
}

# $fn->must_be_dir(); 				exception unless isdir
sub must_be_dir {
  my $fn = shift;
  $fn->exists() or die "required directory '".$fn->path."' doesn't exist\n";
  $fn->isdir() or die "required file '".$fn->path."' exists but is not a directory as it should be\n";
  return;
}

# $bytecount = $fn->size();
sub size {
  my $fn = shift;
  return -s $fn->path;
}

# $flag = $fn->readable();
sub readable {
  my $fn = shift;
  return -r $fn->path;
}

# $flag = $fn->writable();
sub writable {
  my $fn = shift;
  return -w $fn->path;
}

# $days = $fn->age_since_change();
sub age_since_change {
  my $fn = shift;
  return -M $fn->path;
}

### Contents and FileHandles 

# $fh = $fn->open_reader();
sub open_reader ($) {
  my $fn = shift;
  my $fh = FileHandle->new( $fn->path, O_RDONLY );
  binmode($fh) if ($fh); 
  return $fh;
}

# $fh = $fn->open_writer();
sub open_writer ($) {
  my $fn = shift;
  my $fh = FileHandle->new( $fn->path, O_CREAT|O_WRONLY|O_TRUNC );
  binmode($fh) if ($fh); 
  return $fh;
}

# $fh = $fn->open_appender();
sub open_appender ($) {
  my $fn = shift;
  my $fh = FileHandle->new( $fn->path, O_CREAT|O_WRONLY|O_APPEND );
  binmode($fh) if ($fh); 
  return $fh;
}

# $fh = $fn->reader(); 
sub reader ($) {
  my $fn = shift;
  my $fh = $fn->open_reader();
  die "couldn't open reader for " . $fn->path . "\n" unless ($fh);
  return $fh;
}

# $fh = $fn->writer(); 
sub writer ($) {
  my $fn = shift;
  my $fh = $fn->open_writer();
  die "couldn't open writer for " . $fn->path . "\n" unless ($fh);
  return $fh;
}

# $fh = $fn->appender(); 
sub appender ($) {
  my $fn = shift;
  my $fh = $fn->open_appender();
  die "couldn't open writer for " . $fn->path . "\n" unless ($fh);
  return $fh;
}

# $contents = $fn->get_contents();
sub get_contents {
  my $fn = shift;
  my $data = '';
  my $length = read($fn->reader(), $data, $fn->size );
  return $data;
}

# $fn->set_contents($contents);
  # Leaves the contents at $_[0] to avoid copying them.
sub set_contents {
  my $fn = shift;
  $fn->writer()->print($_[0]);
  return;
}

# $contents = $fn->sys_get_contents();
sub sys_get_contents {
  my $fn = shift;
  
  my $fh = $fn->reader();
  
  my $data = '';
  my $offset = 0;
  my $blocksize = $fn->size;
  
  my $count;
  do {
    $count = sysread($fh, $data, $blocksize, $offset);
    die "Reading $$fn interupted: $!\n" unless (defined $count);
    $offset += $count;
  } until ( ! $count );
  
  return $data;
}

# $fn->sys_set_contents($contents);
sub sys_set_contents {
  my $fn = shift;
  
  my $fh = $fn->writer();
  
  my $len = length($_[0]);
  my $offset = 0;
  while ( $len ) {
    my $count = syswrite( $fh, $_[0], $len, $offset );
    die "Writing $$fn interupted: $!\n" unless (defined $count);
    $len -= $count;
    $offset += $count;
  }
  
  return;
}

### Text Contents and FileHandles

# $fh = $fn->open_text_reader();
sub open_text_reader ($) {
  my $fn = shift;
  my $fh = FileHandle->new( $fn->path, O_RDONLY );
  return $fh;
}

# $fh = $fn->open_text_writer();
sub open_text_writer ($) {
  my $fn = shift;
  my $fh = FileHandle->new( $fn->path, O_CREAT|O_WRONLY|O_TRUNC );
  return $fh;
}

# $fh = $fn->open_text_appender();
sub open_text_appender ($) {
  my $fn = shift;
  my $fh = FileHandle->new( $fn->path, O_CREAT|O_WRONLY|O_APPEND );
  return $fh;
}

# $fh = $fn->text_reader(); 
sub text_reader ($) {
  my $fn = shift;
  my $fh = $fn->open_text_reader();
  die "couldn't open text reader for " . $fn->path . "\n" unless ($fh);
  return $fh;
}

# $fh = $fn->text_writer(); 
sub text_writer ($) {
  my $fn = shift;
  my $fh = $fn->open_text_writer();
  die "couldn't open text writer for " . $fn->path . "\n" unless ($fh);
  return $fh;
}

# $fh = $fn->text_appender(); 
sub text_appender ($) {
  my $fn = shift;
  my $fh = $fn->open_text_appender();
  die "couldn't open text writer for " . $fn->path . "\n" unless ($fh);
  return $fh;
}

# $contents = $fn->get_text_contents();
sub get_text_contents {
  my $fn = shift;
  my $data = '';
  my $length = read( $fn->text_reader(), $data, $fn->size );
  return $data;
}

# $fn->set_text_contents($contents);
sub set_text_contents {
  my $fn = shift;
  $fn->text_writer()->print( $_[0] );
  return;
}

# $fn->append_text($contents);
sub append_text {
  my $fn = shift;
  $fn->text_appender()->print( $_[0] );
  return;
}

# @lines = $fn->get_text_lines();
sub get_text_lines {
  my $fn = shift;
  my $fh = $fn->text_reader();
  return (<$fh>);
}

# $fn->set_text_lines( @lines );
sub set_text_lines {
  my $fn = shift;
  $fn->set_text_contents(join('', map { $_, "\n" }  @_));
}

# $fn->append_text_lines( @lines );
sub append_text_lines {
  my $fn = shift;
  $fn->append_text(join('', map { $_, "\n" }  @_));
}

### Media Type

use vars qw( %media_type_map );
%media_type_map = (
  'doc' => 'application/msword',
  'ppt' => 'application/vnd.ms-powerpoint',
  'xls' => 'application/vnd.ms-excel',
  'jpg' => 'image/jpeg',
  'gif' => 'image/gif',
  'bmp' => 'image/bmp',
  'zip' => 'application/zip',
  '123' => 'application/vnd.lotus-1-2-3',
  'pre' => 'application/vnd.lotus-freelance',
  'htm' => 'text/html',
  'html' => 'text/html',
  'txt' => 'text/plain',
  'pdf' => 'application/pdf',
  'rtf' => 'application/rtf',
);

# $mediatype = $fn->media_type() 
  # Currently, we just guess this based on the file extension.
sub media_type {
  my $fn = shift;
  type_for_filename( $fn->name );
}

# $mediatype = type_for_filename( $filename );
sub type_for_filename {
  my $filename = shift;
  my $ext = ( $filename =~ /\.(\w{2,7})$/ )[0];
  return $media_type_map{ lc($ext) }
}

# $extension = ext_for_type( $mediatype );
sub ext_for_type {  
  my $expr = lc( shift );
  foreach ( keys %media_type_map ) {
    return $_ if ( $media_type_map{ $_ } eq $expr );
  }
}

# $filename = typed_filename($filename, $mediatype);
sub typed_filename {
  my ($filename, $mediatype) = @_;
  
  unless ( type_for_filename($filename) eq lc($mediatype) ) {
    my $extn = ext_for_type( $mediatype );
    $filename .= '.' . $extn if $extn;
  }
  
  return $filename;
}

### Temp Files

use vars qw( $TempDirectory @TempDirCandidates );
@TempDirCandidates = ('/usr/tmp', '/var/tmp', '/tmp', '/temp', '/Temporary Items', '.');

# $tmp_dir_fn = File::Name->temp_dir;
sub temp_dir {
  my $package = shift;
  unless ( $TempDirectory ) {
    foreach ( @TempDirCandidates ) {
      my $fn = $package->new( $_ );
      next unless ( $fn->isdir and $fn->writable );
      $TempDirectory = $fn;
      return $TempDirectory;
    }
    die "Couldn't find a writable temp directory\n" unless ( $TempDirectory );
  }
  return $TempDirectory;
}

# $tmp_fn = File::Name->new_temp( $filename );
sub new_temp {
  my ($package, $filename) = @_;
  my ($base, $parent) = fileparse($filename);
  return $package->temp_dir->child( $base )->unique_variation;
}

### DRef Interface

# $value = $fn->get($dref);
sub get ($$) {
  my $fn = shift;
  my $dref = shift;
  
  my $key = shiftdref($dref);
  
  my %methods = (
    'contents' => 'get_contents',
    'lastmod' => 'age_since_change',
    'size' => 'size',
    'path' => 'path',
    'name' => 'name',
    'extension' => 'extension',
    'media_type' => 'media_type',
  );
  my $method = $methods{$key};
  
  return $fn->$method() if ( length $method );
  
  # should add navigation to parent, children.
  
  die "unsupported key '$key' in get from filename\n";
}

# $fn->set($dref, $value);
sub set {
  my ($fn, $dref, $value) = @_;
  
  if ( $dref eq 'contents' ) {
    $fn->set_contents($value);
  } else {
    die "unsupported dref '$dref' in set on filename\n";
  }
}

### Debugging

# $fn->check_state($context_name);
sub check_state {
  my $fn = shift;
  my $description = shift || 'File' ;
  
  my $info = $description . " path: '" . $fn->path . "'";
  $info .= " (non-existant)" unless ( $fn->exists() );
  $info .= "\n";
  $info .= "  Directory '" . $fn->parent->path() . "'\n";
  
  warn $info;
}

package File::Name::Temp;	# This type of file deletes itself.  Cool.

@File::Name::Temp::ISA = qw( File::Name );

# $fn = File::Name::Temp->new_typed_filled_temp($name, $type, $contents);
sub new_typed_filled_temp {
  my $package = shift;
  my $fn = File::Name->new_temp( File::Name::typed_filename(shift, shift) );
  $fn->set_contents( @_ );
  bless $fn, $package;
}

sub DESTROY {
  my $fn = shift;
  Err::Debug::debug ('File::Name::Temp', 'Destroying/Deleting', $fn) if $fn->exists;
  $fn->delete;
}

1;

__END__

=head1 File::Name

The File::Name class provides file pathname objects and related operations.
File::Name::Temp is a subclass that ensures the file pointed to by the
filename is deleted if it exists at the time the File::Name::Temp object is
destroyed.

=head1 Synopsis

    use File::Name;
    
    $passwd = File::Name->new( '/etc/passwd' );
    
    $etc = $fn->parent;
    $shadow = $etc->child( '/etc/shadow' );
    $passwd = $shadow if ( ! $passwd->exists and $shadow->exists );
    
    $passwd->must_exist;
    $text = $passwd->get_contents;
    
    foreach $file ( $etc->children ) {
      next if $file->isdir;
      print $file->name . ': ' . $file->size . "\n";
    }

=head1 Description

File::Name objects are blessed filename strings. This is an OOP wrapper around functionality from FileHandle, Basename, and Cwd. 


=head1 Interface

=head2 Interface

These functions create new File::Name objects, returning a reference to a blessed string value.

=over 4

=item File::Name->new( @path_name_elements ) : $fn

Pass a full file path or a a series of relative elements to create a filename object.

=item filename( $path ) : $fn

Same as File::Name->new. This function is exported when you use File::Name.

=item File::Name->current : $fn

Creates a filename object for the current working directory.

=item current_directory : $fn

Same as File::Name->current. This function is exported when you use File::Name.

=back


=head2 Path and Name Methods

=over 4

=item $fn->path : $pathname

Return the full pathname.

=item $fn->name : $filename

Return the filename without the parent directory path

=item $fn->base_name : $shortname

Return the filename with extention stripped off.

=item $fn->extension : $extension

Return the outermost dot-separated extension of the filename.

=item $fn->hasextension( $extn ) : flag

Return a flag indicating if the file has the provided extention.

=back


=head2 Directory Methods

=over 4

=item $fn->parent : $parent_fn

Return a filename object representing the directory the current file is in.

=item $fn->children : @child_fns

=item $fn->children( $pattern ) : @child_fns

Directories only. If no argument is passed, returns a list of filename objects represeting each of the items in the directory. Simple filename expressions can be passed to limit which children you get back, using ? for a single character and * for multiple characters.

=item $fn->child( $name ) : $child_fn

Returns a filename object for a file in the current directory with the specified name. You'll need to check _$child_fn_ -exists> to see if such a file actually exists.

=back


=head2 Attribute Methods

=over 4

=item $fn->exists : flag

Returns a flag indicating whether there actually exists a file with this name.

=item $fn->must_exist

Dies unless the file exists.

=item $fn->isdir : flag

Returns a flag indicating whether the file exists and is a directory.

=item $fn->must_be_dir

Dies unless the file is a directory

=item $fn->size : bytecount

Return the length of the file in bytes.

=item $fn->age_since_change : num_days

Return the age in days since the file was modified, measured from when the current process started.

=item $fn->media_type : mime_type

Attempts to determine the content type based on the filename extention.

=item $fn->delete 

Delete the file.

=back


=head2 Read and Write Methods

=over 4

=item $fn->open_reader : filehandle

Returns a FileHandle object set to read from this filename.

=item $fn->reader : filehandle

Returns a FileHandle object, as above. Dies unless it is successfully opened

=item $fn->open_writer : filehandle

Returns a FileHandle object set to write to this filename.

=item $fn->writer : filehandle

Returns a FileHandle object, as above. Dies unless it is successfully opened

=item $fn->open_appender : filehandle

Returns a FileHandle object set to append to this filename.

=item $fn->appender : filehandle

Returns a FileHandle object, as above. Dies unless it is successfully opened

=item $fn->get_contents : $content_bytes

Reads and returns the contents of the file at this filename.

=item $fn->set_contents( $content_bytes )

Sets the contents of the file at this filename to the value passed in.

=item $fn->sys_get_contents : $content_bytes

=item $fn->sys_set_contents( $content_bytes )

These methods perform the same actions as get_contents and set_contents, but use sysread and syswrite instead of read and print.

=item $fn->open_text_reader : filehandle

=item $fn->text_reader : filehandle

=item $fn->open_text_writer : filehandle

=item $fn->text_writer : filehandle

=item $fn->open_text_appender : $fh

=item $fn->text_appender : $fh

=item $fn->get_text_contents : $content_text

=item $fn->set_text_contents( $content_text )

=item $fn->append_text( $text )

Each of these methods performs the actions of its equivalent non-text method, but does not activate binmode. Although identical on Unix, these methods should be used for Mac, DOS, and Win32 portability.

=item $fn->get_text_lines : @lines

=item $fn->set_text_lines( @lines )

=item $fn->append_text_lines( @lines )

As above, except that contents are handled as a list of text lines. Lines are ended with \n, which will be translated to \r\n under Windows by the non-binmoded filehandle.

=back


=head2 Temp Files

=over 4

=item File::Name->temp_dir : $tmp_dir_fn

Return a File::Name containing the path to a directory that may be used for temporary file storage. To discover this path, we check several possible paths (stored in @TempDirCandidates), then store the result in $TempDirectory. 

=item File::Name->new_temp( $filename ) : $tmp_fn

Returns a File::Name in the temporary directory using a unique variation of the provided filename string.

=back


=head2 Path Manipulation Functions

=over 4

=item simple_wildcard_to_regex( $partial_filename_with_stars ) : $regex

Returns a Perl regular expression equivalent to the simple filename expression provided, where ? matches one character and * matches many.

=back


=head2 DRef Interface

These methods use Data::DRef and provide special access methods for file information.

=over 4

=item $fn->get($dref) : $value

You can retrieve any of the following file attributes via dref: path, name, extension, contents, lastmod, size, media_type.

=item $fn->set($dref, $value)

You can set the following file attributes via dref: contents.

=back


=head2 Debugging

=over 4

=item $fn->check_state($context_name)

Writes some potentially interesting information about this filename to STDERR via warn. Include a unique string in $context_name to differentiate your debugging cases.

=back


=head1 See Also

L<Data::DRef>, L<Cwd>, L<FileHandle>, L<File::Basename>

=head1 This is Free Software

Copyright 1997, 1998 Evolution Online Systems, Inc. (http://www.evolution.com)

You can use this software under the same terms as Perl itself.

Part of the EvoScript Web Application Framework (http://www.evoscript.com)

=cut
