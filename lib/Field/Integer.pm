### Field::Integer.pm 
  # standard numeric integer field

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-05-?? Made formsize default to 12; regex now allows negatives -Simon
  # 1998-01-26 Build in v4 libraries - Jeremy
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-07 Overhaul. -Simon
  # 1997-03-17 Refactored & standardized; added standard header. -Simon

package Field::Integer;
@ISA = qw[ Field ];

Field::Integer->add_subclass_by_name( 'integer' );

### BASIC FIELD OPERATIONS: TITLE, VALUE, FLATTEN

sub init {
  my ($field) = @_;
  
  $field->{'align'} ||= 'right';
  $field->{'length'} ||= 64;
  $field->{'formsize'} ||= 12;

  $field->SUPER::init();
}

# $data = $field->sql_datatype
sub sql_datatype {
  return "int";
}

### VALIDATION

sub validate {
  my ($field, $record) = @_;
  
  my ($value) = $field->value($record);
  if (length $value and $value !~ /\-?\d+/ ) {
    return ('error', ["The value of $field->{'title'} is not numeric."]);
  }
  return ('none', []);
}
1;