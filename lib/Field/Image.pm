### Field::Image.pm
  # a field associating files with database records

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License
  #
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Del      G. Del Merritt      (dmerritt@intranetics.com)
  # EJM      E.J. McGowan        (ejmcgowan@intranetics.com)

### Change History
  # 1998-06-03 Added "display_link" attribute a la Field::Relation, which
  #	       defaults to 1.  Added support for height and display_link 
  #	       options.  A "maxheight" option might be useful.  Added pod. -Del
  # 1998-05-22 Change parameter to valid_image to be the result of 
  #            the name method, not the filehandle.  -EJM.
  # 1998-05-18 Removed references to 'filename' off of 'uploaded_file' as 
  #            'uploaded_file' is now a scaler.  EJM
  # 1998-04-02 Corrected update method. -Del
  # 1997-12-17 Moved to v4 library, now package with File::Name code

package Field::Image;

push @ISA, qw( Field::File );

Field::Image->add_subclass_by_name( 'image' );

use File::Name;
use Data::DRef;
use Carp;
use Script::HTML::Tag;

sub update {
  my ($field, $record, $updates ) = @_;

  my $value = $field->value( $updates );
  my $uploaded_file = $value->{'uploaded_file'};

  my $filename = $updates->{ $field->name() }{'uploaded_file'}
    if ( defined $updates->{ $field->name() }{'uploaded_file'} );

  return $field->SUPER::update( $record, $updates )
    unless( $filename && ! $field->valid_image( $filename->name ) );

  # We have had an error, raise the error condition, don't bother with
  # the file name because we can't stuff it back into the control anyway.
    
  $record->raise_errorlevel( 'error' );

  push @{ $record->{'-errors'}{$field->name()} },
    "Uploaded file is not of a recognizable image type";

  return;
}

sub display {
  my ( $field, $record, %options ) = @_;

  my %args;
  $args{'border'} = 1;
  $args{'border'} = $field->{'border'} if ( defined $field->{'border'} );
  $args{'border'} = $options{'border'} if ( defined $options{'border'} );
  
  $args{'height'} = $field->{'height'} if ( defined $field->{'height'} );
  $args{'height'} = $options{'height'} if ( defined $options{'height'} );
  
  $args{'width'} = $field->{'width'} if ( defined $field->{'width'} );
  $args{'width'} = $options{'width'} if ( defined $options{'width'} );
  
  my $url = $record->datastore->self_url()
	  . '/' . 'download'
	  . '/' . $record->value('id')
	  . '/' . $field->name() . '/';
	  
  # warn "url $url\n"
  # warn "files" . join(', ',  . "\n"

  my @images = map {
      (!defined ($field->{'display_link'}) or $field->{'display_link'}) ? 
	  html_tag( 'a', {'href' => $url . $_->name()},
	      html_tag('img', {'src' => $url . $_->name, %args}) )->interpret 
        : html_tag('img', {'src' => $url . $_->name, %args})->interpret
  } $field->files($record);
  
  return join( $field->joiner, @images )
      || ($field->single() ? 'no file' : 'no files');
}

sub next_option {
  my($field, $path, $options) = @_;
  
  my $item = shift( @$path );
  if ( $item eq 'height' or $item eq 'display_link') {
    $field->{$item} = shift( @$path );
  } else {
    unshift( @$path, $item );
    $field->SUPER::next_option( $path, $options ); 
  }
  return;
}

sub joiner { return '<br>' }

# 0|1 = $field->valid_image( $filename );
sub valid_image {
  return $_[1] =~ /\.(jpg|jpeg|jpe|gif|bmp)$/i;
}

1;

=pod

=head1 Field::Image

Field::Image, a subclass of L<Field::File>, provides an interface to images.

=head1 Synopsis

=head1 Reference

The following methods are provided:

=over 4

=item Field::Image->update( $record, $updates ) : 

=item Field::Image->display( $record, %options ) :

=item Field::Image->next_option( @$path, $options ) : 

=item Field::Image->joiner( ) :

Currently returns the br tag.

=item Field::Image->valid_image( $filename ) : 0|1

=back

The following field attributes are supported in addition to those supported by
L<Field::File>:

=over 4

=item border = size-in-pixels ;

Put a border of size-in-pixels (browser dependent) around the image.  Defaults
to 1.

=item display_link = 0|1 ;

Boolean (0|1); when true (1), the img tag is embedded in an href'd anchor by
the field's display method.  When false (0), just the img tag is presented.
True (1) by default (this provides prior-version behavior).

=item height = size-in-pixels ;

When specified, it is added as-is to the img tag.

=item width = size-in-pixels ;

When specified, it is added as-is to the img tag.

=back

The following field options are supported in addition to those supported by
L<Field::Definition>:

=over 4

=item height.size-in-pixels

When specified, it is added as-is to the img tag.  E.g.,
   [print value=#-record.display.image1.height.69]

results in a tag like:
   <img src="http://pointer-to-the-image" height=69>

=item display_link.0|1

When specified, it affects whether or not the image will be embedded in an
href anchor to itself.  E.g.,
   [print value=#-record.display.image1.display_link.1]

will allow the user to click on the image.  This may override the field's
default display_link attribute.  See the field attributes above.

=back

=head1 Caveats and Upcoming Changes

A maxheight field option would be handy.

=cut