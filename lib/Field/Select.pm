### Field::Select.pm 
  # Text selected from a list of predefined values.

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-04-14 Added search form
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-07 Overhaul.
  # 1997-04-20 Touchups. -Simon
  # 1997-04-?? Built. -Jeremy

package Field::Select;
@ISA = qw[ Field ];
Field::Select->add_subclass_by_name('select');

use Data::DRef;

### BASIC FIELD OPERATIONS: TITLE, VALUE, FLATTEN

# $field->init
sub init {
  my ($field) = @_;
  $field->SUPER::init();
  $field->{'list'} ||= [];
  $field->{'length'} = 64 unless defined($field->{'length'});
  return;
}

# $data = $field->sql_datatype
sub sql_datatype {
  my ($field) = @_;
  return "text $field->{'length'}";
}

# $form = $field->edit( $record, %options )
sub edit {
  my($field, $record, %options) = @_;
  
  my $name;  
  if ($options{'prefix'}) {
    $name = joindref($options{'prefix'}, $field->{'name'} );
  } else {
    $name = $field->{'name'};
  }
  
  my $select = Script::HTML::Forms::Select->new({ 'name'=>$name });
  
  my $current_value = $field->value($record);
  
  foreach $item (@{ $field->{'list'} }) {
    $select->add( Script::HTML::Forms::Option->new( {
    	'value' => $item, 
	'label' => $item,
	( ( $current_value eq $item ) ? ( 'selected' => undef ) : () ),
    }) );
  }
  
  my $default = ( $field->{'require'} ? 'Select One:' : '- None -' );
  $select->prepend( 
	  Script::HTML::Forms::Option->new({'label'=>$default,'value'=>''}) );
  
  $select->interpret();
}

### VALIDATION

sub validate {
  my ($field, $record) = @_;
  my ($value) = $field->value($record);
  
  return ('error', ["You must select a value for ". $field->title  . '.'])
		      if ( (not $value) and ($field->{'require'}) );
   
  return ('error', ["'$value' is not a valid value for this field"])
		      unless (scalar(grep {$_ eq $value} @{$field->{'list'}}));
  
  return $field->SUPER::validate($field, $record);
}

### SEARCHING

# $html = $field->edit_criteria($crit_args, %options);
sub edit_criteria {
  my ($field, $crit_args, %options) = @_;
  
  $options{'prefix'} ||= 'criteria';
  my $name = ( ! $options{'prefix'} ? $field->{'name'} :
			    joindref( $options{'prefix'}, $field->{'name'} ) );
  
  my $sequence = Script::Sequence->new();
  
  my $current = $crit_args->{ $field->{'name'} } || '';
  my @currents = ( ref $current eq 'ARRAY' ? @$current : () );
  
  foreach $item (@{ $field->{'list'} }) {
    $sequence->add( Script::HTML::Forms::Input->new( {
      'name' => $name,
      'type' => 'checkbox',
      'value' => $item
    }) );
    $sequence->add( $item, '<br>' );
  }
  return $sequence->interpret;
}

1;
