### field::time.pm - way cool warez
  # Iz Magics.

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-05-19 Refactored edit method to use editvalue hook. 
  # 19970924 IntraNetics97 Version 1.00.000
  # 19970717 Made short the default display style. -Simon
  # 19970617 Rebuilt with text entry and new time libraries. - JGB
  # 19970317 Refactored & standardized; added standard header. -Simon

package Field::Time;

use Field;
@ISA = qw[ Field ];
Field::Time->add_subclass_by_name( 'time' );

use DateTime::Time;
use Data::DRef;

# $field->sql_datatype
sub sql_datatype {
  return 'text 10';
}

# $field->init
sub init {
  my ($field) = @_;
  
  $field->{'ifempty'} ||= '';
  $field->{'formsize'} = 20 unless defined( $field->{'formsize'} );
  $field->SUPER::init();
  return;
}

### OPTION HANDLING

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

# $value = $field->readable($record, %options)
sub readable {
  my ($field, $record, %options) = @_;
  my $time = $field->value( $record ) or return( $field->{'ifempty'} );
  my $format = $options{'format'} || 'ampm';
  die "bad time format '$format'" unless ( $time->can( $format ) );
  return $time->$format();
}

### Persistance interface

# $field->flatten($record, %$target);
sub flatten {
  my ($field, $record, $target) = @_;
  my $time = $field->value( $record ) or return '';
  $target->{ $field->{'name'} } = $time->full();
  return();
}

# $field->unflatten( $record, %$flatvalues );
sub unflatten {
  my( $field, $record, $flatvalues ) = @_;
  $record->{ $field->name() } =
    DateTime::Time::new_time_from_value($flatvalues->{ $field->name() })
      if ( $flatvalues->{ $field->name() } );
  return;
}

### HTML Forms interface

# $html = $field->editvalue($record);
sub editvalue {
  my ($field, $record) = @_;
  my $time = $field->value( $record );
  
  my $value;
  if    ( ! $time )          { $value = '' }
  elsif ( $time->isbogus() ) { $value = $time->bogus_time() }
  else                       { $value = $time->ampm()  }
  
  return $value;
}

# $field->update( $record, %$updates );
sub update {
  my( $field, $record, $updates ) = @_;
  $record->{ $field->name() } =
    DateTime::Time::new_time_from_value( $updates->{ $field->name() } )
      if ( $updates->{ $field->name() } );
  return;
}

### Validation

# ($level, $msgs) = $field->validate($record)
sub validate {
  my($field, $record) = @_;
  my $time = $field->value( $record ) or return ('none', []);
  
  return ('error', ['Unrecognized time format.'])  if ( $time->isbogus() );
  return ('error', ['Time values out of bounds.']) if ( $time->{'wrapped'} );
  return ('none',  []);
}

1;