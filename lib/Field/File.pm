### Field::File.pm
  # a field associating files with database records

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License
  # 
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)
  # Del      G. Del Merritt      (dmerritt@intranetics.com)

### Change History
  # 1998-05-20 Specified format for 'file' text input in sub edit. -Dan & Del
  # 1998-05-07 Changed update method to reflect new handling of
  #            multipart/form-data in WebApp::Request -Jeremy
  # 1998-05-06 Modified temp_id method to correctly handle case where no
  #            value is present in record -Jeremy 
  # 1998-05-05 Rewrote update method with error checking -Jeremy
  # 1998-05-05 Corrected temp_id preservation in edit form -Jeremy
  # 1998-04-27 Made $field->path ensure that the path's directory exists. -Del
  # 1998-04-06 Corrected uploaded file logic. -Del
  # 1998-04-02 Inserted missing "my" and correct path handling in update;
  #            experiment with minimal copying. -Del
  # 1998-03-31 Fixed typos in file attachment; correct update method; cleaned
  #            up edit UI; modified cleanup. -Del
  # 1998-03-23 Minimal subfield fixes.
  # 1998-03-23 Added ensure_is_dir to temp_path.
  # 1998-03-18 Fixed error in cleanup.
  # 1998-02-24 Fixed "undefined value as a HASH reference" bug in cleanup().
  # 1998-02-23 Provided default base directory.
  # 1998-02-22 Added support for relative path names. -Simon
  # 1997-12-17 Moved to v4 library, now package with File::Name code

package Field::File;

$VERSION = 4.00_03;
use Field;
push @ISA, qw( Field );

Field::File->add_subclass_by_name( 'file' );

use File::Name qw( filename current_directory );

use Carp;
use Err::Debug;
use Data::DRef;

use Number::Bytes;
use Script::HTML::Styles;

use vars qw( $base_directory );
$base_directory ||= File::Name->current;

# $field->init()
sub init {
  my $field = shift;
  
  $field->{'path'} = File::Name->new( $field->{'path'} );
  
  $field->{'path'} = $base_directory->relative( $field->{'path'} ) 
  					unless $field->{'path'}->is_absolute;
  
  debug 'fileattachments', 'File attachment directory for ', $field->title, 
	 	  'is', $field->{'path'}->path ;
  
  warn 'File attachment directory for '. $field->title. 'field doesn\'t' . 
  		' exist at'. $field->{'path'}->path . "\n"
   				unless ($field->{'path'}->exists);
  
  return;
}

sub next_option {
  my($field, $path, $options) = @_;
  
  my $item = shift( @$path );
  if ( $item eq 'name' or $item eq 'type' or $item eq 'size' ) {
    $options->{'display_element'} = $item;
  } else {
    unshift( @$path, $item );
    $field->SUPER::next_option( $path, $options ); 
  }
  return;
}

# $html = $field->title($record, %options);
sub title {
  my ($field, $record, %options) = @_;
  if ( $options{'display_element'} ) {
    return "\u$options{'display_element'}";
  }
  return $field->SUPER::title( %options );
}

# $text = $field->readable( $record, %options );
sub readable {
  my ( $field, $record, %options ) = @_;
  
  my $method = $options{'display_element'} || 'name';
  if ( $method eq 'type' ) { $method = 'media_type'; }
  my $text = join( ', ', map($_->$method(), $field->files($record)) );
  $text = Number::Bytes::byte_format( $text ) if ($method eq 'size');
  $text ||= 'unknown' if ($method eq 'media_type');
  $text ||= 'no file' . ($field->single() ? '' : 's') if ($method eq 'name');
  return $text;
}

# $html = $field->display( $record, %options );
sub display {
  my ( $field, $record, %options ) = @_;
  my $url = $record->datastore->self_url()
	  . '/' . 'download'
	  . '/' . $record->value('id')
	  . '/' . $field->name() . '/';
  my @links = map {
    Script::HTML::Link::Anchor->new( { 'href' => $url . $_->name() },
				    $_->name()
#      $field->readable( $record, %options )
    )->interpret();
  } $field->files( $record );
  return join('<br>', @links) || ($field->single() ? 'no file' : 'no files');
}

# $form = $field->edit( $record, %options ); 
sub edit {
  my ( $field, $record, %options ) = @_;

  debug 'Field::File', ['$record in edit method:'], $record;
  my $value = $field->value( $record );
  my $temp_id = $value->{'temp_id'} if ( $value->{'temp_id'} );

  my $prefix = ( $options{'prefix'} ? joindref( $options{'prefix'}, $field->name() ) : $field->name() );
  my $form = '';
  
  # List of current files with checkbox remove controls
  my @files;
  if ( $field->temp_files( $record ) ) {
    @files = $field->temp_files( $record );
  } else {
    @files = $field->files( $record );
  }

  # Create list of existing files and the checkbox option to remove each.
  if ( scalar( @files ) ) {
    my $file;
    foreach $file (@files) {
      $form .= 'Remove'
	    .  Script::HTML::Escape::nonbreakingspace()
	    .  Script::HTML::Forms::Input->new({
		  'type' => 'checkbox',
		  'name' => joindref( $prefix, 'remove', $file->name() )
		})->interpret()
	    .  Script::HTML::Escape::nonbreakingspace()
	    .  $file->name() . '<br>';
    } 
    $form .= '<hr>';		# give some separation from the Attach box.

  } else {
    $form .= '<em>no file' .($field->single() ? 's' : ''). ' attached</em><br>';
  }
  
  # File upload form element
  $form .= 'Attach&nbsp;new&nbsp;file:&nbsp;';
  $form .= stylize('input',
    Script::HTML::Forms::Input->new({
      'type' => 'file',
      'size' => '12,1',
      'name' => joindref( $prefix, 'uploaded_file' )
    })->interpret()
  );
  
  # "More Files" button ( multiple file field only )
  $form .= '&nbsp;<input type="submit" name="command" value="More Files">'
    unless ( $field->single() );
  
  # debug 'Field::File', ['$foo in edit, before hidden input'], $foo;
  # warn "$value -- $value->{'temp_id'} -- " . ref($value) . "\n";

  # Hidden Input for temp id of new records
  $form .= Script::HTML::Forms::Input->new({
    'type' => 'hidden',
    'value' => $temp_id,
    'name' => joindref( $prefix, 'temp_id' ),
    'size' => 12,
  })->interpret() if ( $temp_id );
  
  return $form;
}

# $field->update( $record, %$updates );
sub update {
  my( $field, $record, $updates ) = @_;
  
  debug 'Field::File', ['$updates in before update:'], $updates;

  my $value = $updates->{ $field->{'name'} };

  # Remove the key from the %$updates hash now, since this hash doesn't go out
  # of scope until all fields have updated and we don't want to carry around
  # the potentially large amount of file data past the end of this function.

  delete( $updates->{ $field->{'name'} } );

  # Currently, 'temp_id' is the only value passed along in the update method
  # as saving and deleting files is now completed here. There exists a problem
  # with multi-file fields when the field is required. The deletion of files 
  # occurs before the edit cycle is complete and commited. 

  $record->{ $field->{'name'} } = { 'temp_id' => $value->{'temp_id'} }
    if ( exists $value->{'temp_id'} );

  # The method is finished unless there are files to save or delete

  return unless( $value->{'uploaded_file'} or $value->{'remove'} );

  # Set an appropriate path

  my $path;
  if ( $record->value('id') eq 'new' ) {
    $path = $field->temp_path( $record )
  } else {
    $path = $field->path( $record )
  }

  $path->ensure_is_dir;

  # File Removal

  if ( scalar( keys %{ $value->{'remove'} } ) ) {

      #!# This is a hack - the correct solution to the problem of file name
      #   preservation as a single word in a DRef needs to be made in
      #   Data::DRef. The corresponding change in this package would be in the
      #   edit method, where the names for the removal checkboxes are generated

      my @remove_files = Data::Collection::scalarkeysof($value->{'remove'});

      my $filename;
      foreach $filename (@remove_files) {
	  my $file = $path->child( $filename );
	  $file->delete;
      }
  }

  # Handle Uploaded File

  my $uploaded_file = $value->{'uploaded_file'};
  if ( $uploaded_file ) {
    debug 'always', "upload:", 'x', $uploaded_file, 'x';
    
    die "uploaded file value is not a File::Name object!\n"
		      unless (UNIVERSAL::isa($uploaded_file, 'File::Name'));
    
    # Ensure that uploaded file has data
    unless ( $uploaded_file->size() ) {
      push @{ $record->errors()->{ $field->{'name'} } },
	"Uploaded file, '" . $uploaded_file->name() . "' contains no data";
      $record->raise_errorlevel( 'error' );
      $uploaded_file->delete(); 
      return;
    }
    
    # Remove current file or files ( single file field only )
    if ( $field->single() ) {
      my @files;
      if ( $record->{'id'} eq 'new' ) {
	@files = $field->temp_files( $record );
      } else {
	@files = $field->files( $record );
      }
      my $file;
      foreach $file (@files) { 
	  debug 'gdm', 'deleting single(?) file: ', $file;
	  $file->delete(); 
      }
    }
    
    #!# At this point we will overwrite a file of the same name, if there is
    #   one in the target directory

    $path->move_to_dir( $uploaded_file );

  }

  debug 'Field::File', ['$record in after update:'], $record;

  return;
}

# $field->deleteprep($record)
sub deleteprep {
  my($field, $record) = @_;
  foreach $file ( $field->files( $record ) ) { $file->delete() }
  $field->path( $record )->delete;
  return;
}

# $field->flatten($record);
sub flatten {}

# $field->cleanup($record);
sub cleanup {
  my ($field, $record) = @_;
  my $path = $field->path( $record );
  if ( $field->temp_files($record) ) {
    $field->path( $record )->move_to_dir( $field->temp_files($record) );
    $field->temp_path( $record )->delete();
  }

  # File Removal now in update method
  
  #   my $removes = ( $field->value($record) || {} )->{'remove'} || {};
  #   foreach $file ( $field->files( $record ) ) {
  #     $file->delete() if $removes->{ $file->name() };
  #   }

  return();
}

# $field->create_datasource()
sub create_datasource {
  my $field = shift;
  my $path = $field->{'path'};
  $path->ensure_is_dir;
  $path->child('new')->ensure_is_dir;
  return;
}

# $field->destroy_datasource()
sub destroy_datasource {
  my $field = shift;
  my $path = $field->{'path'};
  $path->delete() if ( $path->exists() );
  return;
}


### FILE FIELD METHODS

# $path = $field->path( $record );
sub path {
  my($field, $record) = @_;
  my $id = $record->{'id'};
  confess "No \$record->{'id'} for \$field->path()" unless( $id and $id ne 'new' );
  $field->{'path'}->ensure_is_dir; # all TLD's are forced into existance.
  return $field->{'path'}->child( $id );
}

# @files = $field->files( $record );
sub files {
  my( $field, $record ) = @_;
  
  return () unless $record;
  return () if ( $record->value('id') eq 'new' );
  
  my $path = $field->path( $record ) ;
  return () unless $path->exists();
  
  my @files = $path->children();
  return wantarray ? @files : scalar( @files ); 
}

# $id = $field->temp_id( $record );
sub temp_id {
  my($field, $record) = @_;
  my $value = $field->value( $record );
  my $id;
  if ( $value and ref( $value ) and $value->{'temp_id'} ) {
    $id = $value->{'temp_id'};
  } else {
    $id = time();
    $record->{ $field->{'name'} } = {}
      unless ref( $record ) eq 'HASH';
    $record->{ $field->{'name'} }{'temp_id'} = $id;
  }  
  debug 'Field::File', ['$record after temp_id method'], $record;
  return $id;
}

# $path = $field->temp_path( $record );
sub temp_path {
  my($field, $record) = @_;
  my $id = $field->temp_id( $record );
  $field->{'path'}->child('new')->ensure_is_dir;
  $field->{'path'}->child('new')->child( $id )->ensure_is_dir;
  return $field->{'path'}->child('new')->child( $id );
}

# @files = $field->temp_files( $record )
sub temp_files {
  my($field, $record) = @_;
  my $value = $field->value( $record );
  return unless ( exists($value->{'temp_id'}) and $value->{'temp_id'} );
  my @files = $field->temp_path( $record )->children();
  return wantarray ? @files : scalar( @files ); 
}

# $fn = $field->file_from_id_and_name( $id, $name );
sub file_from_id_and_name {
  my( $field, $id, $name ) = @_;
  my $path = $field->path({'id' => $id});
  my $fn = $path->child( $name );
  return ( $fn->exists ? $fn : undef );
}

# 0|1 = $field->single()
sub single { return ( $_[0]->{'single_file'} ? 1 : 0 ) }

1;