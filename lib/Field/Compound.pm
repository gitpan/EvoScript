### Field::Compound.pm - Abstract superclass for compound fields

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-04-23 Added edit_title method for compound edits.
  # 1997-11-26 Added methods to support searching: edit_criteria, criterion -S.
  # 1997-11-06 implemented VALIDATION methods
  # 1997-11-04 implemented subfield OPTION HANDLING and VIEW methods
  # 1997-11-04 Started to move to v4 lib
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-12 replaced fieldorder and the like with a fieldset object - JGB
  # 1997-06-07 Switched back to _ between subfields for underlying fieldnames.
  # 1997-06-07 Overhaul. -Simon
  # 1997-06-01 Chaned criteria generation to skip empty fields.
  # 1997-05-?? Added criteria.
  # 1997-03-17 Refactored & standardized; added standard header. -Simon
  # 1997-03-16 not a lame .pm. -Jeremy

package Field::Compound;
use Text::PropertyList;
use Field;
@ISA = qw[ Field ];


### INSTANTIATION

# $field->init
sub init {
  my($field) = @_;
  $field->create_subfields();
  $field->SUPER::init();
  return;
}

### OPTION HANDLING

# $field->next_option( @$path, %$options )
sub next_option {
  my($field, $path, $options) = @_;

  my $item = shift( @$path );
  
  if ( $item eq 'subfield' ) {
    $options->{'subfield'} = $field->subfield( shift( @$path ) );    
    my $subpath = Data::DRef::joindref( @$path );
    my %suboptions = $options->{'subfield'}->options( $subpath );
    $options->{'subfield_options'} = \%suboptions;
    # warn "subpath = '$subpath'\n";
    # warn "\$path = \n" . astext( $path );
    # warn "Options = \n" . astext( $options );
    while (@$path) { shift @$path };
  } else {
    unshift( @$path, $item );
    $field->SUPER::next_option( $path, $options ); 
  }
  
  return;
}

### VIEW

# $html = $field->title($record, %options);
sub title {
  my ($field, $record, %options) = @_;

  if ( exists $options{'subfield'} ) {
    return $options{'subfield'}->title(  %{ $options{'subfield_options'} } );
  }

  return $field->SUPER::title( %options );
}

# $flag = $field->has_value($record, %options)
sub has_value {
  my ($field, $record, %options) = @_;

  if ( exists $options{'subfield'} ) {
    my $subfield = $options{'subfield'};
    my %suboptions = %{ $options{'subfield_options'} };
    return $subfield->has_value($record, %suboptions);
  }

  my $subfield;
  foreach $subfield ( @{ $field->subfieldorder() } ) {
    return 1 if $subfield->has_value($record);
  }

  return;
}

# @values = $field->value($record, %options)
sub value {
  my($field, $record, %options) = @_;
  
  if ( exists $options{'subfield'} ) {
    my $subfield = $options{'subfield'};
    my %suboptions = %{ $options{'subfield_options'} };
    return $subfield->value($record, %suboptions);
  }
  
  my @value;
  my $subfield;
  foreach $subfield ( @{ $field->subfieldorder() } ) {
    my $value = $subfield->value($record);
    $value ||= '';
    push( @value, $value );
  }
  return @value;
}

# $text = $field->readable($record, %options);
sub readable {
  my($field, $record, %options) = @_;

  if ( exists $options{'subfield'} ) {
    my $subfield = $options{'subfield'};
    my %suboptions = %{ $options{'subfield_options'} };
    return $subfield->readable($record, %suboptions);
  }

  return $field->compound_readable( $record, %options );
}

# $text = $field->compound_readable($record, %options);
sub compound_readable {
  die( '$field->compound_readable called on abstract superclass' );
}

# $html = $field->display($record, %options)
sub display {
  my($field, $record, %options) = @_;
  
  if ( exists $options{'subfield'} ) {
    my $subfield = $options{'subfield'};
    my %suboptions = %{ $options{'subfield_options'} };
    return $subfield->display($record, %suboptions);
  }
  
  return $field->compound_display( $record, %options );
}

# $text = $field->compound_display($record, %options);
sub compound_display {
  die( '$field->compound_display called on abstract superclass' );
}

# $html = $field->edit($record, %options)
sub edit {
  my($field, $record, %options) = @_;

  if ( exists $options{'subfield'} ) {
    my $subfield = $options{'subfield'};
    my %suboptions = %{ $options{'subfield_options'} };
    return $subfield->edit($record, %suboptions);
  }

  return $field->compound_edit( $record, %options );
}

# $text = $field->compound_edit($record, %options);
sub compound_edit {
  die( '$field->compound_edit called on abstract superclass' );
}

# $html = $field->edit_title($record, %options);
sub edit_title {
  my ($field, $record, %options) = @_;
  $field->title( $record, %options ) . ':';
}

# $html = $field->search($record, %options)
sub search {
  my($field, $record, %options) = @_;
  
  if ( exists $options{'subfield'} ) {
    my $subfield = $options{'subfield'};
    my %suboptions = %{ $options{'subfield_options'} };
    return $subfield->search($record, %suboptions);
  }
  
  return $field->compound_search( $record, %options );
}

# $text = $field->compound_search($record, %options);
sub compound_search {
  die( '$field->compound_search called on abstract superclass' );
}

# %@criteria = $field->criterion( $crit_args );
sub criterion {
  my ($field, $crit_args) = @_;
  
  my $value = $crit_args->{ $field->{'name'} };
  
  $value ||= runscript( $field->{'criteria_default'} ) 
  			if ( $field->{'criteria_default'} );
  
  $value = join(' ',  valuesof $value) if (ref $value);
  
  return unless ( defined $value and length $value );
  
  my $criterion = Data::Criteria->new_from_def( {
    'key' => join(' ', map { $_->{'name'} } @{ $field->subfieldorder() }),
    'match' => $field->{'criteria_match'} || 'multimatch',
    'value' => $value,
  } );
  
  return $criterion;
}


### DATA PERSISTENCE

# $field->flatten($record, $target)
sub flatten {
  my ($field, $record, $target) = @_;

  my $subfield;  
  foreach $subfield ( @{ $field->subfieldorder() } ) {
    $subfield->flatten($record, $target);
  }
  return;
}

# $field->flatten($record, $row)
sub unflatten {
  my ($field, $record, $row) = @_;

  my $subfield;
  foreach $subfield ( @{ $field->subfieldorder() } ) {
    $subfield->unflatten($record, $row);
  }
  return;
}

# $flat_field or @flat_fields = $field->flat_fields()
sub flat_fields {
  my ($field) = @_;
  
  my @flat_fields;
  my $subfield;
  foreach $subfield ( @{ $field->subfieldorder() } ) {
    push( @flat_fields, $subfield->flat_fields );
  }
  
  return @flat_fields;
}

# $field->sql_datatype
sub sql_datatype {
  die( '$field->sql_datatype called on abstract superclass' );
}

### EFFIGY HANDLING

#$field->default($record)
sub default {
  my ($field, $record) = @_;
  my $subfield;
  foreach $subfield ( @{ $field->subfieldorder() } ) {
    $subfield->default( $record );
  }
  return;
}

# $field->update($master_record, $updates);
sub update {
  my ($field, $record, $updates) = @_;
  
  my $subfield;
  foreach $subfield ( @{ $field->subfieldorder() } ) {
    $subfield->update( $record, $updates );
  }
  return;
}

### VALIDATION

# ($level, $msgs) = $field->require($record)
sub require {
  my ($field, $record) = @_;
  my $subfield;
  foreach $subfield ( @{ $field->subfieldorder() } ) {
    my($level, $msg) = $subfield->require( $record );
    return ($level, $msg) if ($level eq 'none');
  }
  my $msg = ($field->title() ? $field->title : 'Field') . ' requires a value';
  return ('error', [ $msg ]);
}

# ($level, $msgs) = $field->validate($record)
sub validate {
  my($field, $record) = @_;
  my($level, $msgs) = ('none', []);

  my $subfield;
  foreach $subfield ( @{ $field->subfieldorder() } ) {
    my($sublev, $submsgs) = $subfield->validate( $record );
    ($level, $msgs) = $field->totalvalidate($level, $msgs, $sublev, $submsgs);
  }

  return ($level, $msgs);
}

### This shit has to change
#
# # ($level, $msgs) = $field->unique($record)
# sub unique {
#   my ($field, $record) = @_;
#   return ('none', []);
# }

### SUBFIELD INSTANTIATION

# $field->create_subfields()
sub create_subfields {
  my($field) = @_;
  my $subfieldorder;
  my $subfields;

  my $definition;
  foreach $definition ( @{ $field->subfield_definitions } ) {
    my $name = $definition->{'name'};
    $definition->{'record_class'} = $field->{'record_class'};
    $definition->{'name'} = $field->{'name'} . '_' . $name;
    $definition->{'-name'} = $name;
    my $subfield = Field->newfromdefinition( $definition );
    push( @$subfieldorder, $subfield );
    $subfields->{ $name } = $subfield;
  }

  $field->{'subfieldorder'} = $subfieldorder;
  $field->{'subfields'} = $subfields;
  return;
}

# %@$subfield_definitions = $field->subfield_definitions();
sub subfield_definitions {
  die( '$field->subfield_definitions called on abstract superclass' );
}


### SUBFIELD ACCESS

# @$subfieldorder = $field->subfieldorder()
sub subfieldorder {
  return $_[0]->{'subfieldorder'}; 
}

# $subfield = $field->subfield( $name );
sub subfield {
  my($field, $name) = @_;

  return $field->{'subfields'}{ $name }
    if ( exists $field->{'subfields'}{ $name } );

  Carp::confess( "Bad subfield name '$name'" );
}

# %$subfields = $field->subfields();
sub subfields {
  return $_[0]->{'subfields'};
}

1;