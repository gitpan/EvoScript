### A FieldSet class provides access to its members' contents via field objects

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### To Do:
  # We should store all fields in a hash by name, and their names in order.

### Change History
  # 1998-06-11 Changed errorlevel method to never empty the level attribute.
  # 1998-06-04 Removed comma from criteria_title. -Simon
  # 1998-06-03 Added lastfield function to act like the field function
  #            but handle subfields as well.  -EJM
  # 1998-05-28 Added show=no handling for fields
  # 1998-05-08 Added Action to the list of uneditable types. -Simon
  # 1998-03-19 Added editable method.
  # 1998-03-18 Changed prefer_silent and prefer_wide_row to ignore class. -Del
  # 1998-03-10 Added unsaved status.
  # 1998-03-04 Support for wide fields. -Simon
  # 1998-02-25 Modified so that show=0 is honored by prefer_silent() -Del
  # 1998-02-23 Changed fall-through on get to allow raw DRef access. -Simon
  # 1997-12-04 Moved get and error handling methods here -Jeremy
  # 1997-12-04 Extracted from Record.pm.

package FieldSet;

$VERSION = 4.00_03;

use Text::PropertyList;

use Field::Available;
use Data::DRef;
use Err::Debug;

use strict;
use Carp;

### Class Data Access
  # Override these methods if the fieldset is record, not class-specific, etc.

# %$fields = $package->fields() or %%$fields = $widget->fields()
  # or pass a value to set it
sub fields {
  my $widget = shift;
  my $package = ( ref($widget) || $widget );
  if ( scalar @_ ) {
    my $fields = shift;
    # warn "setting fields for $widget to $fields";
    eval '$' . $package . '::fields = $fields';
  }
  # warn "fields for $widget are " . eval( '$' . $package . '::fields' );
  return eval( '$' . $package . '::fields' );
}

# @$fieldorder = $package->fieldorder() or @$fldordr = $widget->fieldorder()
sub fieldorder {
  my $widget = shift;
  my $package = ( ref($widget) || $widget );
  if ( scalar @_ ) {
    my $fieldorder = shift;
    eval '$' . $package . '::fieldorder = $fieldorder';
  }
  return eval( '$' . $package . '::fieldorder' );
}

### Field Definitions

# $package->set_fields_from_def( %@$field_def_list );
sub set_fields_from_def {
  my ($package, $field_def_list) = @_;
  
  my ($fields, $fieldorder);
  
  my $field_def;
  foreach $field_def (@$field_def_list) {
    my $field = Field->newfromdefinition($field_def);
    push(@$fieldorder, $field);
    $fields->{ $field->{'name'} } = $field;
    
    $field->{'fieldset_class'} = $package;
  }
  
  $package->fields( $fields );
  $package->fieldorder( $fieldorder );
  
  return;
}

### Calling Methods on All of the Fields

# @vals = $widget->call_on_each_field( $method, @args );
sub call_on_each_field {
  my $widget = shift;
  my $method = shift;
  
  my @values;
  
  my $field;
  foreach $field ( @{ $widget->fieldorder() } ) {
    push @values, $field->$method( @_ );
  }
  
  return @values;
}

# @vals = $widget->call_on_each_field_with_self( $method, @args );
sub call_on_each_field_with_self {
  my $widget = shift;
  my $method = shift;
  
  my @values;
  
  my $field;
  foreach $field ( @{ $widget->fieldorder() } ) {
    push @values, $field->$method( $widget, @_ );
  }
  
  return @values;
}

### Fields By Name

# $field = $widget->field( $name ); 
# ($field, %options) = $widget->field( $name_with_dot_options );
sub field {
  my($widget, $name) = @_;
  
  my $first = shiftdref( $name );
  
  my $field;
  $field = $widget->fields->{ $first } if ( exists $widget->fields->{$first} );
  die "Bad field name '$first' for '$widget'\n" unless ( $field );
  
  my %options = $field->options( $name ) if ( defined $name and length $name );
  
  return ( wantarray ? ($field, %options) : $field );
}

# @fieldnames = $package->fieldnames(); @$fieldorder = $widget->fieldnames();
sub fieldnames {
  my $widget = shift;
  return $widget->call_on_each_field( 'name' );
}

# @$field_options = $field->field_options();
sub field_options {
  my $widget = shift;
  return [ $widget->call_on_each_field( 'option_list' ) ];
  
  my $list = [];
  my $field;
  foreach $field (@{ $widget->fieldorder() }) {
    push @$list, $field->option_list();
  }
  
  # warn "FIELD NAMES FROM SUB FIELD OPTIONS\n";
  # my $fieldname;
  # foreach $fieldname ( @$list ) {
  #   warn "  '$fieldname'\n";
  # }
  
  return $list;
}

# $somehash = $widget->getfieldprops( $name ); 
sub getfieldprops {
  my($widget, $name) = @_;
  my ($field, %field_options) = $widget->field( $name );

  if ( defined $field_options{'subfield'} ) {
     my $subfield = $field_options{'subfield'};
     return { 'name' => $subfield->{'name'}, 
              'type' => $subfield->{'type'} };
  }

  return { 'name' => $field->{'name'}, 
           'type' => $field->{'type'} };

}

### Calling Methods on Fields By Name

# copy_hash_keys( \%source, \%target );
sub copy_hash_keys {
  my $source = shift;
  my $target = shift;
  my $key;
  foreach $key ( keys %$source ) {
    $target->{ $key } = $source->{ $key };
  }
}

# $val = $widget->call_field_method_by_name($fieldname, $method, %options);
sub call_field_method_by_name {
  my ( $widget, $fieldname, $method, %options ) = @_;
  
  croak "field method called without fieldname" unless (length $fieldname);
  my ($field, %field_options) = $widget->field( $fieldname );
  copy_hash_keys( \%options, \%field_options );
  
  return $field->$method( %field_options );
}

# $val = $widget->call_field_method_with_args($fieldname, $method, @$args, %options);
sub call_field_method_with_args {
  my ( $widget, $fieldname, $method, $args, %options ) = @_;
  
  $args ||= [];
  
  my ($field, %field_options) = $widget->field( $fieldname );
  copy_hash_keys( \%options, \%field_options );
  
  return $field->$method( @$args, %field_options );
}

# $val = $widget->call_field_method_with_self($fieldname, $method, %options);
sub call_field_method_with_self {
  my ( $widget, $fieldname, $method, %options ) = @_;
  $widget->call_field_method_with_args(
				  $fieldname, $method, [$widget], %options);
}

### Display and Access of Values

# $text = $widget->title( $fieldname, %options );
sub title {
  my($widget, $fieldname, %options) = @_;
  return $widget->call_field_method_by_name($fieldname, 'title', %options);
}

# $text = $widget->option_title( $fieldname, %options );
sub option_title {
  my($widget, $fieldname, %options) = @_;
  
  # warn "finding option title for fieldname '$fieldname'\n";
  
  return $widget->call_field_method_by_name($fieldname, 'option_title', %options);
}

# $value = $widget->value( $fieldname, $options );
sub value {
  my($widget, $fieldname, %options) = @_;
  $widget->call_field_method_with_self( $fieldname, 'value', %options);
}

# $flag = $widget->has_value( $fieldname, %options );
sub has_value {
  my($widget, $fieldname, %options) = @_;
  $widget->call_field_method_with_self( $fieldname, 'has_value', %options);
}

# $text = $widget->readable( $fieldname, %options );
sub readable {
  my($widget, $fieldname, %options) = @_;
  $widget->call_field_method_with_self( $fieldname, 'readable', %options);
}

# $html_text = $widget->display( $fieldname, %options );
sub display {
  my($widget, $fieldname, %options) = @_;
  $widget->call_field_method_with_self( $fieldname, 'display', %options);
}

### Generating Edit Forms

# $html_input_text = $widget->edit( $fieldname, %options );
sub edit {
  my($widget, $fieldname, %options) = @_;
  $widget->call_field_method_with_self( $fieldname, 'edit', %options);
}

# $html_input_text = Class->edit_criteria($criteria, $fieldname, %options);
sub edit_criteria {
  my ( $class, $criteria, $fieldname, %options ) = @_;
  $class->call_field_method_with_args($fieldname, 'edit_criteria', [$criteria], %options);
}

### Searching

# $criteria_object = $widget->criteria( %$crit_args );
sub criteria {
  my($class, $crit_args) = @_;
   
  my @crits = grep { $_ } $class->call_on_each_field('criterion', $crit_args);
  
  return unless scalar @crits;
  
  my $criteria = Data::Criteria::And->new_empty();
  foreach ( @crits ) { $criteria->add_sub( $_ ); }
  
  return $criteria;
}

use vars qw[ $CriteriaReadableJoin ];
$CriteriaReadableJoin = ' and ';

# $readabledescription = $widget->criteria_title( %$crit_args );
sub criteria_title {
  my($class, $crit_args) = @_;
  
  debug 'criteria', "$class", 'criteria_title', $crit_args;
  my @clauses = grep { $_ } 
		  $class->call_on_each_field( 'criterion_title', $crit_args );
  
  return join($CriteriaReadableJoin, @clauses);
}

### Layout Information

# $flag = $widget->prefer_wide_row( $fieldname );
sub prefer_wide_row {
  my($widget, $fieldname) = @_;
  my($field, %field_options) = $widget->field( $fieldname );
  return 1 if ( $field->{'wide'} );
  return 0;
}

# $flag = $widget->prefer_silent( $fieldname );
sub prefer_silent {
  my($widget, $fieldname) = @_;
  my($field, %field_options) = $widget->field( $fieldname );
  return 1 if ( (defined $field->{'show'} and (! $field->{'show'} or $field->{'show'} =~ /no/i)) );
  return 0;
}

# $flag = $widget->editable( $fieldname );
sub editable {
  my($widget, $fieldname) = @_;
  my($field, %field_options) = $widget->field( $fieldname );

  # Exclude calculated fields from editing.
  return 0 if ( $field->isa( 'Field::Calculation' ) 
             or $field->isa( 'Field::Compound::Action' ) 
             or $field->isa( 'Field::Id' ) );

  # default is editable if it's not an id or calculated field.
  return 1 if ( (defined $field->{'edit'}) ? ($field->{'edit'}) : 1 );

  return 0;
}


### Flatten

# $record->unflatten( $row );
sub unflatten {
  my($record, $row) = @_;
  $record->call_on_each_field_with_self( 'unflatten', $row );
  return;
}

# $row = $record->flatten;
sub flatten {
  my($record) = @_;
  my $flat_values = {};
  $record->call_on_each_field_with_self( 'flatten', $flat_values );
  return $flat_values;
}

### UPDATING AND ERROR HANDLING

# $widget->default();
sub default {
  my $widget = shift;
  $widget->call_on_each_field_with_self( 'default' );
}

# $record->update( %$updates )
sub update {
  my($record, $updates) = @_;
  
  # warn "about to update " . join(' ', %$record) . "\n";
  $record->call_on_each_field_with_self( 'update', $updates );
  
  $record->{'-errors'} ||= { };
  
  $record->call_on_each_field_with_self( 'scrutinize' );
  
  if ( $record->status eq 'new' or $record->status eq 'unsaved' ) {
    $record->status('unsaved');
  } else {
    $record->status('updated');
  }
  # warn "having updated " . join(' ', %$record) . "\n";
  
  return;
}

# $status = $widget->status( $status )
sub status {
  my $widget = shift;
  $widget->{'-status'} = shift if ( scalar @_ );
  return $widget->{'-status'};
}

# $errors = $widget->errors or $widget->errors( $errors )
sub errors {
  my $widget = shift;
  $widget->{'-errors'} = shift if ( scalar @_ );
  $widget->{'-errors'} ||= {};
  return $widget->{'-errors'};
}

# $errorlevel = $widget->errorlevel or $widget->errorlevel( $errorlevel )
sub errorlevel {
  my $widget = shift;
  $widget->{'-errorlevel'} ||= 'none';
  $widget->{'-errorlevel'} = shift if ( scalar @_ and length $_[0] );
  return $widget->{'-errorlevel'};
}

# $widget->raise_errorlevel( $level );
sub raise_errorlevel {
  my $widget = shift;
  my $level = shift;
  $widget->{'-errorlevel'} = $level
      unless ($widget->{'-errorlevel'} eq 'error' or $level eq 'none');
  return;
}

# $widget->clear_errors;
sub clear_errors {
  my $widget = shift;
  $widget->{'-errorlevel'} = 'none';
  $widget->{'-errors'} = {};
}

### GET
  # Currently handles field.$method.$fieldname.@dotoptions
  # 
  # Perhaps this should be:
  # 
  # Get a raw field value
  #   $fieldname		// direct hash fetch
  #   value.$fieldname		// value method, handles dot options
  # 
  #   fieldtitle.$fieldname
  #
  # Display a field value
  #   readable.$fieldname
  #   display.$fieldname	HTML
  # 
  # Get a reference to a particular field.
  #   field.$fieldname
  #   fieldorder.$n

sub get {
  my($widget, $dref) = @_;
  
  debug 'drefs', "FieldSet lookup", $dref, "from", "$widget";
  
  my $item = Data::DRef::shiftdref( $dref );
  
  if ( $item eq 'field' ) {
    my $method = Data::DRef::shiftdref( $dref );
    return $widget->call_field_method_with_self($dref, $method);
  }
  
  return $widget->$item( $dref ) if ($widget->can($item));
  
  # return $widget->{$dref} if ($item eq '-direct');
  
  return $dref ? Data::DRef::get( $widget->{$item} || {}, $dref ) : $widget->{$item};
}

1;

__END__

=head1 FieldSet

A FieldSet class provides access to its members' contents via field objects

=head2 Class Data Access
=over 4
=item %$fields = $package->fields() 
=item %%$fields = $widget->fields()
=item @$fieldorder = $package->fieldorder() 
=item @$fldordr = $widget->fieldorder()
=back

=head2 Field Definitions
=over 4
=item $package->set_fields_from_def( %@$field_def_list );
=back

=head2 Calling Methods on All of the Fields
=over 4
=item @vals = $widget->call_on_each_field( $method, @args );
=item @vals = $widget->call_on_each_field_with_self( $method, @args );
=back

=head2 Fields By Name
=over 4
=item $field = $widget->field( $name ); 
=item ($field, %options) = $widget->field( $name_with_dot_options );
=item @fieldnames = $package->fieldnames(); 
=item @$fieldorder = $widget->fieldnames();
=item @$field_options = $field->field_options();
=back

=head2 Calling Methods on Fields By Name
=over 4
=item copy_hash_keys( \%source, \%target );
=item $val = $widget->call_field_method_by_name($fieldname, $method, %options);
=item $val = $widget->call_field_method_with_args($fieldname, $method, @$args, %options);
=item $val = $widget->call_field_method_with_self($fieldname, $method, %options);
=back

=head2 Display and Access of Values
=over 4
=item $text = $widget->title( $fieldname, %options );
=item $text = $widget->option_title( $fieldname, %options );
=item $value = $widget->value( $fieldname, $options );
=item $flag = $widget->has_value( $fieldname, %options );
=item $text = $widget->readable( $fieldname, %options );
=item $html_text = $widget->display( $fieldname, %options );
=back

=head2 Generating Edit Forms
=over 4
=item $html_input_text = $widget->edit( $fieldname, %options );
=item $html_input_text = Class->edit_criteria($criteria, $fieldname, %options);
=back

=head2 Searching
=over 4
=item $criteria_object = $widget->criteria( %$crit_args );
=item $readabledescription = $widget->criteria_title( %$crit_args );
=back

=head2 Layout Information
=over 4
=item $flag = $widget->prefer_wide_row( $fieldname );
=item $flag = $widget->prefer_silent( $fieldname );
=back

=head2 Flatten
=over 4
=item $record->unflatten( $row );
=item $row = $record->flatten;
=back

=head2 UPDATING AND ERROR HANDLING
=over 4
=item $widget->default();
=item $record->update( %$updates )

=item $status = $widget->status( $status )
This method returns a list of error messages in a plain text format corresponding to the supplied field name.

=item $errors = $widget->errors or $widget->errors( $errors )
=item $errorlevel = $widget->errorlevel or $widget->errorlevel( $errorlevel )
=item $widget->raise_errorlevel( $level );
=item $widget->clear_errors;
=back

=cut