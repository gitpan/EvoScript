### Field::Id

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 19971125 Removed the empty blocks for display, title; added to prefer_silent
  # 19971124 Changed flatten() to update the non-flattened version as well.
  # 19971122 Moved to v4 library, now package Field::Id -Jeremy

package Field::Id;

use Field;
push @ISA, qw( Field );

Field::Id->add_subclass_by_name( 'id' );

# $field->init
sub init {
  my ($field) = @_;
  
  $field->{'title'} ||= 'ID';
  $field->{'show'} = 0;
  $field->{'default'} ||= 'new';
  
  $field->SUPER::init();
}

# $field->flatten($record, $target)
sub flatten {
  my ($field, $record, $target) = @_;
  my $fieldname = $field->{'name'};
  
  $record->{ $fieldname } = $field->make_id if 
  					( $record->{ $fieldname } eq 'new' );
  
  $target->{ $fieldname } = $record->{ $fieldname };
  
  return;
}

sub make_id { return time(); }

# $data = $field->sql_datatype
sub sql_datatype { return "int"; }

# ($level, @$messages) = $field->validate( $record )
sub validate     { return ('none', []); }

sub option_list { return (); }


### Field::Id::Definition

package Field::Id::Definition;

use Field;
@ISA = qw[ Field::Definition ];

use vars qw[ $fields $fieldorder $init];

Field::Id::Definition->Field::Definition::add_subclass_by_name( 'id' );

sub init {
  return if ( $init ++ );
  Field::Id::Definition->set_fields_from_def([
    {
      'name' => 'title',
      'type' => 'text',
      'title' => 'Title',
      'hint' => '',
      'default' => 'Record ID',
    },
  ]);
}

1;