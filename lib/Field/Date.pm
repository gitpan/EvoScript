### Field::Date.pm - way cool warez

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Overview
  # Iz Magics.

### Change History
  # 1998-06-11 Now using $field->value($record, $new_value) interface.
  # 1998-01-05 Refactored edit method into new editvalue hook. -Simon
  # 1997-12-11 Internally, dates are always date objects.
  # 1997-12-06 Move to v4 libraries
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-09-03 Tweaks to default two-digit years to around 2000, error on wrap.
  # 1997-08-31 Changed to full format for edits.
  # 1997-06-17 Rebuilt with text entry and new time libraries. - JGB
  # 1997-03-17 Refactored & standardized; added standard header. -Simon

package Field::Date;

use Field;
@ISA = qw[ Field ];
Field::Date->add_subclass_by_name( 'date' );
use DateTime::Date qw( new_date_from_value );
use Data::DRef;
use Text::PropertyList;

# $field->sql_datatype
sub sql_datatype {
  return 'text 10';
}

# $field->init
sub init {
  my ($field) = @_;
  
  $field->{'ifempty'} ||= '- no date -';
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
  my $date = $field->value( $record );
  return( $field->{'ifempty'} ) unless ( $date and ref $date );
  my $format = $options{'format'} || 'long';
  die "bad date format '$format'" unless ( UNIVERSAL::can($date, $format) );
  return $date->$format();
}

# $field->default($record)
sub default {
  my ($field, $record) = @_;
  
  return if ( defined $field->value($record) );  
  
  my $value = '';
  $value = Script::runscript( $field->{'default'} )
		  if ( $field->{'default'} and length $field->{'default'} );
  
  $field->value($record, new_date_from_value($value)) if $value;
  
  return;
}


### Persistance interface

# $field->flatten($record, %$target);
sub flatten {
  my ($field, $record, $target) = @_;
  my $date = $field->value( $record ) or return '';
  $target->{ $field->{'name'} } = $date->yyyymmdd();
  return();
}

# $field->unflatten( $record, %$flatvalues );
sub unflatten {
  my( $field, $record, $flatvalues ) = @_;
  $field->value($record, new_date_from_value( $flatvalues->{ $field->name } ) )
    					  if ( $flatvalues->{ $field->name } );
}

### HTML Forms interface

# $html = $field->editvalue($record);
sub editvalue {
  my ($field, $record) = @_;
  
  my $date = $field->value( $record );
  
  my $value;
  if    ( ! $date )          { $value = '' }
  elsif ( $date->isbogus() ) { $value = $date->bogus_date() }
  else                       { $value = $date->full()  }
  
  return $value
}

# $field->update( $record, %$updates );
sub update {
  my( $field, $record, $updates ) = @_;
  $field->value($record, new_date_from_value( $updates->{ $field->name } ) )
    					  if ( $updates->{ $field->name } );
}

### Validation

# ($level, $msgs) = $field->validate($record)
sub validate {
  my($field, $record) = @_;
  my $date = $field->value( $record ) or return ('none', []);
  
  return ('error', ['Unrecognized date format.'])  if ( $date->isbogus() );
  return ('error', ['Date values out of bounds.']) if ( $date->{'wrapped'} );
  return ('none',  []);
}

1;