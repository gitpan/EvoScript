### Field::Relation
  # Foreign-key relational fields

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-04-23 Changed link logic in $field->display.
  # 1998-04-23 Added ifempty handling to replace readableifempty.
  # 1998-04-17 Updated to use new Data::Sorting interface.
  # 1998-04-13 Added edit_criteria method.
  # 1997-12-11 The return of the readable_value method. -Simon
  # 1997-11-20 Implemented in v4 w/ Association mixin -Jeremy
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-09-16 Added readableifempty.
  # 1997-06-25 get_field_options now uses dot options as subfield name
  # 1997-06-07 Overhaul.
  # 1997-04-20 Touchups.
  # 1997-04-?? Built. -Simon

package Field::Relation;

use Field;
use Field::Association;
@ISA = qw[ Field::Association Field ];
Field::Relation->add_subclass_by_name( 'relation' );

use Err::Debug;
use Text::Words qw( string2list );
use Data::DRef;
use Data::Collection;
use Data::Sorting qw( sort_in_place );

use strict;

### INSTANTIATION

sub init {
  my($field) = @_;
  $field->init_related_record_class();
  $field->SUPER::init();
  return;
}

# $data = $field->sql_datatype
  # Should really ask the related record class for its ID's datatype
sub sql_datatype { return "int"; }

### OPTION HANDLING

sub next_option {
  my($field, $path, $options) = @_;
  
  my $item = shift( @$path );
  if ( $item eq 'related_field' ) {
    $options->{'related_field'} = joindref( @$path );
    @$path = ();
  } else {
    unshift( @$path, $item );
    $field->SUPER::next_option( $path, $options ); 
  }
  return;
}

### VIEW

# $whatever = $field->related_view( $method, $record, %options)
sub related_view {
  my($field, $method, $record, %options) = @_;
  
  my $related_record = $field->related_record( $record );
  
  return $field->{'ifempty'} if ( ! $related_record and $field->{'ifempty'} );
  defined( $options{'related_field'} ) or $options{'related_field'} = '';
  
  my($rel_field, %rel_opts) = $field->related_field($options{'related_field'});
  
  die("Can't call method '$method' on '$rel_field'\n") 
				  unless ( $rel_field->can($method) );
  
  return $rel_field->$method( $related_record, %rel_opts );
}

# $text = $field->readable( $record, %options )
sub readable {
  my($field, $record, %options) = @_;
  return $field->related_view( 'readable', $record, %options );
}

# $readable = $field->readable_for_id( $id );
sub readable_for_id {
  my ($field, $id) = @_;
  my $related_record = $field->related_record_class->record_by_id( $id );
  return $field->{'ifempty'} if ( ! $related_record and $field->{'ifempty'} );
  my ($rel_field, %rel_opts) = $field->related_field();
  return $rel_field->readable( $related_record, %rel_opts );
}

# $display = $field->display( $record, %options )
sub display {
  my($field, $record, %options) = @_;
  $field->related_view( ($field->{'display_link'} ? 'link' : 'display'), 
  			$record, %options );
}

### Updates

# $form = $field->edit( $record, %options )
sub edit {
  my($field, $record, %options) = @_;
  
  my $related_records = $field->related_records();
  
  my $related_fieldname =
      $field->related_fieldname( $options{'related_fieldname'} );
   
  my @options;
  my $current_value = $field->value($record);
  my $found_selected_option = 0;
  my $related_record;
  foreach $related_record ( sort_in_place([@$related_records], 
  				'field.readable.'.$related_fieldname) ) {
    my $option_value = $related_record->value('id');
    my $args = {
	'value' => $option_value,
	'label' => $related_record->readable( $related_fieldname )
    };
    if ( (! $found_selected_option) && ( $current_value eq $option_value ) ) {
      $found_selected_option = 1;
      $args->{'selected'} = undef;
    }
    push( @options, Script::HTML::Forms::Option->new($args) );
  }
  
  my $default = ($field->{'require'} ? 'Select One:' 
				    : $field->{'ifempty'} ? $field->{'ifempty'}
							  : '- None -' );
  
  unshift @options, Script::HTML::Forms::Option->new(
		  { 'label' => $default,'value' => '' }
		 );
  
  my $name;  
  if ($options{'prefix'}) {
    $name = joindref($options{'prefix'}, $field->{'name'} );
  } else {
    $name = $field->{'name'};
  }
  
  return Script::HTML::Forms::Select->new( { 'name'=>$name }, @options )->interpret();
}

### Searching

# $html = $field->edit_criteria($crit_args, %options);
sub edit_criteria {
  my ($field, $crit_args, %options) = @_;
  
  $options{'prefix'} ||= 'criteria';
  my $name = ( ! $options{'prefix'} ? $field->{'name'} :
			    joindref( $options{'prefix'}, $field->{'name'} ) );
  
  my $related_records = $field->related_records();
  my $related_fieldname =
	    $field->related_fieldname( $options{'related_fieldname'} );
  
  my @related_records = ( sort_in_place([@$related_records], 
  				'field.readable.'.$related_fieldname) );
  
  my $current = $crit_args->{ $field->{'name'} } || '';
  my @currents = ( ref $current eq 'ARRAY' ? @$current : () );
  
  my $sequence = Script::Sequence->new();
  
  my $related_record;
  foreach $related_record (@related_records) {
    $sequence->add( 
      Script::HTML::Forms::Input->new({
	'name' => $name,
	'type' => 'checkbox',
	'value' => $related_record->value('id')
      }),
      ' ',
      $related_record->readable( $related_fieldname ), 
      '<br>',
    );
  }
  return $sequence->interpret;
}

# %@criteria = $field->criterion( $crit_args );
sub criterion {
  my ($field, $crit_args) = @_;
  
  my $value = $crit_args->{ $field->{'name'} };
  
  $value ||= Script::runscript( $field->{'criteria_default'} ) 
  			if ( $field->{'criteria_default'} );
  
  # $value = join(' ',  valuesof $value) if (ref $value);
  
  return unless ( defined $value and length $value );
  
  my $criterion = Data::Criteria->new_from_def( {
    'key' => $field->{'name'},
    'match' => $field->{'criteria_match'} || 'isstringinlist',
    'value' => $value,
  } );
  
  return $criterion;
}

# $description = $field->criterion_title($value);
sub criterion_title {
  my ($field, $crit_args) = @_;
  
  my $values = $crit_args->{ $field->{'name'} };
  return unless $values;
  $values = [ string2list( $values ) ] if (! ref $values);
  $values = array_by_hash_key( $values ) if (UNIVERSAL::isa($values,'HASH'));
  
  debug 'criteria', 'Field', $field->{'name'}, 'relation criteria:', @$values;
  
  $values = join(' or ',  map { $field->readable_for_id( $_ ) } @$values );
  
  return unless (defined $values and length $values);
  
  return $field->{'title'} . ' is ' . $values;
}

### Field::Relation::Definition

package Field::Relation::Definition;

use Field;
@Field::Relation::Definition::ISA = qw[ Field::Definition ];

use vars qw[ $fields $fieldorder $init];

Field::Relation::Definition->add_subclass_by_name('relation');

sub init {
  return if ( $init ++ );
  Field::Relation::Definition->set_fields_from_def([
    {
      'name' => 'title',
      'type' => 'text',
      'title' => 'Title',
      'hint' => '',
    },
    {
      'name' => 'align',
      'type' => 'text',
      # 'type' => 'select',
      'list' => [ 'right', 'left' ],
      'title' => 'Display Alignment',
      'default' => 'left',
      'hint' => '',
    },
    {
      'name' => 'show',
      'type' => 'text',
      # 'type' => 'flag',
      'default' => 0,
      'title' => 'Show in Detail View',
    },
    {
      'name' => 'relation_to',
      'type' => 'text',
      # 'type' => 'select',
      'default' => 0,
      'title' => 'Related Datastore',
    },
  ]);
}

1;