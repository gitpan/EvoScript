### Field::Text.pm
  # standard text field

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-05-29 Cleanup of Definition fields.
  # 1997-11-03 Moved to v4 library, now package Field::Text
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-07 Overhaul. -Simon
  # 1997-04-20 Touchups.
  # 1997-03-17 Refactored & standardized; added standard header. -Simon

package Field::Text;

push @ISA, qw( Field );

Field::Text->add_subclass_by_name( 'text' );

use Data::Sorting;

### BASIC FIELD OPERATIONS: TITLE, VALUE, FLATTEN

# $field->init
sub init {
  my ($field) = @_;
  $field->SUPER::init();
  
  $field->{'length'} = 64 unless defined($field->{'length'});
  $field->{'formsize'} = 40 unless defined($field->{'formsize'});
}

# $data = $field->sql_datatype
sub sql_datatype {
  my ($field) = @_;
  return "text $field->{'length'}";
}

### VALIDATION

# ($level, @$messages) = $field->validate( $record )
sub validate {
  my ($field, $record) = @_;
  my ($level, $messages) = ('none', []);
  my $value = $field->value($record);
  $value = '' unless ( defined $value );
  my $length = length( $value );
  if ( $length > $field->{'length'} ) {
    $level = 'error'; 
    $messages = ["The length of this field may not exceed $field->{'length'} characters (not " . $length . ")."];
  }
  return( $level, $messages );
}

### Field::Text::Definition

package Field::Text::Definition;

use Field;
@ISA = qw[ Field::Definition ];

use vars qw[ $fields $fieldorder $init];

Field::Text::Definition->Field::Definition::add_subclass_by_name( 'text' );

sub init {
  return if ( $init ++ );
  Field::Text::Definition->set_fields_from_def([
    {
      'name' => 'title',
      'type' => 'text',
      'title' => 'Title',
      'hint' => ''
    },
    {
      'name' => 'align',
      'type' => 'select',
      'list' => [ 'left', 'right' ],
      'title' => 'Display Alignment',
      'default' => 'left',
      'require' => 1,
      'hint' => ''
    },
    {
      'name' => 'show',
      'type' => 'select',
      'list' => [ 'yes', 'no' ],
      'default' => 'yes',
      'require' => 1,
      'title' => 'Show in Detail View',
    },
    {
      'name' => 'length',
      'type' => 'integer',
      'minimum' => 1,
      'default' => 64,
      'title' => 'Length',
      'formsize' => 8,
    },
    {
      'title' => 'Entry Field Size',
      'name' => 'formsize',
      'default' => 40,
      'minimum' => 1,
      'type' => 'integer',
      'formsize' => 8,
    },
    {
      'name' => 'require',
      'type' => 'select',
      'list' => [ 'yes', 'no' ],
      'default' => 'yes',
      'require' => 1,
      'title' => 'Entry Required',
    },
    {
      'name' => 'hint',
      'type' => 'text',
      'title' => 'Hint',
    },
    {
      'name' => 'searchable',
      'type' => 'select',
      'list' => [ 'yes', 'no' ],
      'default' => 'yes',
      'require' => 1,
      'title' => 'Show on Search Page'
    },
    {
      'name' => 'searchhint',
      'type' => 'text',
      'title' => 'Search Hint'
    },
  ]);
}

1;