### Field::Currency.pm

### Copyright 1998 IntraNetics, Inc.
  # Del      G. Del Merritt      dmerritt@intranetics.com

### Overview
  # Support field instances of the Number package.  Currency is stored as an 
  # integer to avoid loss of precision during arithmetic operations.  This 
  # package provides UI translations.

### Change History
  # 1998-06-05 Modified to support "format.blah" field options; default for
  #            field.readable is Number::Currency::pennies, while field.display
  #            default is Number::Currency::cents_to_dollars.  Any function in 
  #            Number::Currency that can take a "raw" number can be used. -Del
  # 1998-03-25 Created as glue to existing Number::Currency.  It's simple now 
  #            to get back to 1.01 functionality. -Del

package Field::Currency;

use Field::Integer;
@ISA = qw[ Field::Integer ];
Field::Currency->add_subclass_by_name( 'currency' );

use Number::Currency qw( pennies dollars_to_cents );
use Err::Debug;

# $value = $field->display($record, %options)
sub display {
  my ($field, $record, %options) = @_;
  $options{'format'} ||= 'cents_to_dollars';
  return $field->SUPER::display( $record, %options );
}

# $value = $field->readable($record, %options)
sub readable {
  my ($field, $record, %options) = @_;
  my $format = $options{'format'} || 'pennies';
  my $format_sub = "Number::Currency::$format" ;
  die "bad date format '$format'" unless ( defined &$format_sub );
  return &$format_sub( $field->value( $record ) );
}

# $html = $field->editvalue($record);
sub editvalue {
  my ($field, $record) = @_;
  pennies( $field->value( $record ) );
}

# $field->update( $record, %$updates );
sub update {
  my( $field, $record, $updates ) = @_;
  $record->{$field->name} = dollars_to_cents( $updates->{$field->name} )
			  if ( defined $updates->{ $field->name } );
}

sub next_option {
  my($field, $path, $options) = @_;
  
  my $item = shift( @$path );
  if ( $item eq 'format' ) {
    $options->{'format'} = shift( @$path );
  } else {
    unshift( @$path, $item );
    $field->SUPER::next_option( $path, $options ); 
  }
  return;
}

1;
