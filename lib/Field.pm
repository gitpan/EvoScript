### Field.pm - abstract superclass for field types.

### Copyright 1997. 1998 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-06-11 Added support for $field->value($record, $new_value).
  # 1998-06-04 Changed criterion_title to use 'contains' instead of 'is'.
  # 1998-05-29 Switched to use of Script::Evaluate instead of Script. -Simon
  # 1998-05-20 Changed colon to ' is ' in criterion title.
  # 1998-05-20 Specified format for text input in sub edit. -Dan
  # 1998-05-18 If there are error messages already reported from the 
  #            update, don't loose them in scrutinize.  -EJM
  # 1998-04-23 Modified link() to use Record methods.
  # 1998-04-17 Updated to use new Data::Sorting interface.
  # 1998-03-18 Patched flat_fields to skip column without a data type.
  # 1998-03-04 Added formsize option for edit_criteria().
  # 1998-03-04 Modified link() to return unless $record. -Simon
  # 1998-03-03 Added link() methods. -Piglet
  # 1998-01-05 Refactored edit method to use editvalue hook. -Simon
  # 1997-12-11 The return of the readable_value method.
  # 1997-11-26 Added methods to support searching: edit_criteria, criterion -S.
  # 1997-11-** Numerous changes
  # 1997-10-30 Moved to ver 4 lib, started fold in -Jeremy
  # 1997-09-27 Code cleanup on the default method.
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-07 Overhaul. -Simon
  # 1997-04-16 Moved field tag here.
  # 1997-03-29 Made value($record) method throw exception on non-hash records
  # 1997-03-?? JEREMY -- Log your changes, darnit. -Simon
  # 1997-03-08 Some functionality added. -JGB (what a lame comment)
  # 1997-03-06 Created package. -Simon

package Field;

$VERSION = 2.00_1998_03_04;

use vars qw[ %known_subclasses ];

use Script::Evaluate qw( runscript );
use Script::HTML::Styles;
use Err::Debug;
use Data::DRef;
use Carp;
use Text::PropertyList;
use Data::Collection;
use Data::Sorting qw( sort_in_place );
use Text::Words qw( string2list );

### Subclass Factory Methods

# Field->add_subclass_by_name( $type )
sub add_subclass_by_name {
  my ($package, $type) = @_;
  
  $known_subclasses{ $type } = $package;
}

# $package = Field->get_subclass_by_name( $type )
sub get_subclass_by_name {
  my ($package, $type) = @_;
  
  my $subclass = $known_subclasses{ $type };
  
  return $subclass;
}

# Load each package and let them register their field types

### Instantiation

# $field = Field->new;
sub new {
  my($package, $field) = @_;
  
  die("bad field definition ref ='". ref($field) . "' :\n" . astext($field) )
    unless( ref($field) eq 'HASH' || UNIVERSAL::isa($field, 'Field') and $field->{'name'} );
  
  bless $field, $package;
  $field->init;
  return $field;
}

# $field->init
sub init {
  my($field) = @_;
  $field->{'show'} = 1 unless (exists $field->{'show'});
  $field->{'align'} = 'left' unless (exists $field->{'align'});
  return;
}

# $field = field->newfromdefinition ($definition);
 #  Instantiate a new field by type name,
 #  with type-specific field properties.
  
sub newfromdefinition {
  my($package, $definition) = @_;
  
  my $subclass = $package->get_subclass_by_name( $definition->{'type'} );
   
  return $subclass->new($definition) if ($subclass);
  
  die "could not create field from definition: unknown type '$definition->{'type'}'";
}


### Option Handling

# %options = $field->options($string)
sub options {
  my ($field, $string) = @_;
  
  return () unless ( $string );
  
  my $path = [ Data::DRef::splitdref( $string ) ];
  my $options = {};
  
  while ( scalar(@$path) ) {
    $field->next_option( $path, $options );
  }
  
  return %{ $options };
}

sub format {
  my $field = shift;
  return $field->{'format'};
}

# $field->next_option( @$path, %$options )
sub next_option {
  my($field, $path, $options) = @_;
  
  my $item = shift( @$path );
  
  if ( $item eq 'escape' ) {
    $options->{'escape'} = shift( @$path );
  } elsif ( $item eq 'prefix' ) {
    $options->{'prefix'} = shift( @$path );
  } elsif ( $item eq 'formsize' ) {
    $options->{'formsize'} = shift( @$path );
  } else {
    
    # In subclasses, this conditional should:
    #
    # unshift( @$path, $item );
    # $field->SUPER::next_option( $path, $options ); 
    
    confess( "Bad field option '$item' for field '$field->{'name'}'" );
  }
  
  return;
}

### Outut

# $html = $field->title($record, %options);
sub title {
  my ($field, $record, %options) = @_;
  return $field->escape( $options{'escape'}, $field->{'title'} );
}

# $flag = $field->has_value($record)
sub has_value {
  my ($field, $record) = @_;
  my $value = $field->value($record);
  return $value =~ /\S/ if ($value);
  return;
}

# $value = $field->value($record);
# $field->value($record, $value);
sub value {
  my($field, $record) = (shift, shift);
  $record->{ $field->{'name'} } = shift if (scalar @_ and defined $_[0]);
  return $record->{ $field->{'name'} };
}

# $text = $field->readable($record, %options);
sub readable {
  my ($field, $record, %options) = @_;
  $field->value($record);
}

# $html = $field->display($record, %options)
sub display {
  my($field, $record, %options) = @_;
  return $field->escape( 
    $options{'escape'},
    $field->readable($record, %options)
  );
}

# $html = $field->link($record, %options)
sub link {
  my($field, $record, %options) = @_;
  return unless $record;
  # warn "DL: \$f->link for $field->{'name'}\n";
  return $record->detail_link( $field->display($record, %options) );
}

# $html = $field->edit($record, %options)
sub edit {
  my ($field, $record, %options) = @_;
  
  return stylize('input', 
    Script::HTML::Forms::Input->new( {
      'name' => ( $options{'prefix'} ? joindref( $options{'prefix'}, $field->{'name'} ) : $field->{'name'} ),
      'type' => 'text',
      'size' => ( $options{'formsize'} || $field->{'formsize'} ),
      'value' => $field->editvalue($record)
    } )->interpret
  );
}

# $html = $field->editvalue($record);
sub editvalue {
  my ($field, $record) = @_;
  $field->value($record);
}

# $escaped_value = $field->escape( $escape_style, $value );
sub escape {
  my($field, $escape, $text) = @_;
  $escape ||= $field->{'escape'} || 'html';  
  
  return $text if ($escape eq 'no');
  
  return Text::Escape::escape( $escape, $text );
}

# $align = $field->align()
sub align {
  return $_[0]->{'align'}
}

# $name = $field->name()
sub name {
  return $_[0]->{'name'}
}

# $pixels = $field->colwidth()
sub colwidth {
  my($field, $record, %options) = @_;
  #!# Not clear on whether the record argument is needed/appropriate.
  return $options{'width'} || $field->{'colwidth'} || '';
}

# @drefs_to_sort_records_by = $field->sorters()
sub sorters {
  my ($field) = @_;
  return joindref( 'field', 'readable', $field->{'name'});
}

### DBAdaptor Interface

# $field->flatten($record, $target)
sub flatten {
  my ($field, $record, $target) = @_;
  $target->{ $field->{'name'} } = $field->value($record);
}

# $field->unflatten($record, $row)
sub unflatten {
  my($field, $record, $row) = @_;
  $record->{ $field->name() } = $row->{ $field->name() };
  return;
} 

# @%$flat_field = $field->flat_fields()
sub flat_fields {
  my ($field) = @_;
  my $type = $field->sql_datatype;
  return () unless $type;
  return {
    'name' => $field->{'name'},
    'type' => $type
  };
}

# $field->sql_datatype
sub sql_datatype {
  return '';
}

# $field->deleteprep($record)
sub deleteprep {
  return 1;
}

# $field->cleanup($record);
  # Called after the record has been flattened; last pass of the update cycle.
sub cleanup {
  my ($field, $record) = @_;
  return;
}

### Updates and Validation

# $field->default($record)
sub default {
  my ($field, $record) = @_;
  
  return if ( defined $field->value($record) );  
  
  $field->value($record, 
   length( $field->{'default'} ) ? runscript( $field->{'default'} ) : ''
  );
}

# $field->update($master_record, $updates);
sub update {
  my ($field, $record, $updates) = @_;
  $field->value($record, $updates->{ $field->{'name'} })
			if ( exists $updates->{ $field->{'name'} } );
}

# ($level, $msgs) = $field->scrutinize($record, level)
  # Error handling occurs in the folowing format: ($level, $messages)
  # $level = 'none'|'warn'|'error'
  # $messages = a reference to a list of errormessages
sub scrutinize {
  my($field, $record) = @_;
  
  my $level;
  my $messages;
  
  # Check to see if the field reported any errors already in the 
  # update routine.  If so, get them out of the record so we don't 
  # loose them.
  if ( defined $record->{'-errors'}{ $field->name } ) {
    $messages = $record->{'-errors'}{ $field->name };
    $level = 'error';
  } else {
    # Otherwise, no error yet, check for other things.
    $messages = [];
    $level = 'none';
    ($level, $messages) = $field->require($record)
	  if (exists $field->{'require'} and $field->{'require'} eq 'yes');
    ($level, $messages) = $field->unique($record)
	  if ($level eq 'none' and $field->{'unique'});
    ($level, $messages) = $field->validate($record)
	    if ($level eq 'none' and $field->has_value($record) );
  }
  
  $record->raise_errorlevel( $level );
  $record->{'-errors'}{$field->name()} = $messages;
  # push @{ $record->{'-errors'}{$field->name()} }, @$messages;
  
  return;
}

# ($level, @$messages) = $field->require( $record )
sub require {
  my ($field, $record) = @_;
  return ('none', []) if ( $field->has_value($record) );
  return ('error', [$field->title . ' requires a value.'])
}

# ($level, $msgs) = $field->validate($record)
sub validate {
  my($field, $record) = @_;
  return ('none', []);
}

# ($level, $msgs) = $field->unique($record)
sub unique {
  my ($field, $record) = @_;
  my $datastore = $theData->{'datastore'}{ $field->{'unique'} };
  my $criteria = [  { 'field' => $field->{'name'}, 
		      'value' => $field->value($record) }  ];
  
  # my @records = $datastore->{'dbadaptor'}->fetch($criteria);
  if (scalar @records and $records[0]->{'id'} ne $record->{'id'}) {
    return ('error', ["There is already an entry for " . $field->readable($record) . "." ]);
  }
  return ('none', []);
}

# ($level, $msgs) = $field->totalvalidate($level, $msgs, $level2, $msgs2)
 #  totalvalidate resolves two possibly different sets of error level/errormsg,
 #  returning the higest error level and all corresesponding messages.
sub totalvalidate {
  my ($field) = shift; 
  my ($level, $messages, $other_level, $other_messages) = @_;
  
  $level = $other_level if (($level eq 'none') or ($other_level eq 'error'));
  
  push @$messages, @$other_messages;
  
  return ($level, $messages);
}

# $flag = $field->has_errors( $record )
sub has_errors {
 my($field, $record) = @_;
 return scalar( @{ $record->errors->{ $field->{'name'} } });
}

### Searching

# $html = $field->edit_criteria($crit_args, %options);
sub edit_criteria {
  my ($field, $crit_args, %options) = @_;
  
  $options{'formsize'} ||= 40;
  $options{'prefix'} ||= 'criteria';
  return stylize('input',
    Script::HTML::Forms::Input->new( {
      'name' => ( ! $options{'prefix'} ? $field->{'name'} :
			   joindref( $options{'prefix'}, $field->{'name'} ) ),
      'type' => 'text',
      'size' => $options{'formsize'},
      'value' => $field->value($record),
    } )->interpret
  );
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
    'key' => $field->{'name'},
    'match' => $field->{'criteria_match'} || 'multimatch',
    'value' => $value,
  } );
  
  return $criterion;
}

# @descriptions = $field->criterion_title( $crit_args );
sub criterion_title {
  my ($field, $crit_args) = @_;
  
  my $value = $crit_args->{ $field->{'name'} };
  
  $value = [ string2list( $value ) ] if (! ref $value);
  $value = join(' or ',  valuesof $value) if (ref $value);
  
  return unless (defined $value and length $value);
  
  debug 'criteria', 'Field', $field->{'name'}, 'criteria:', $value;
  
  return $field->{'title'} . ' contains ' . $value;
}

### Sorting and Grouping

# $field->sortrecords($listref, %options)
sub sortrecords {
  my($field, $records, %options) = @_;
  sort_in_place($records, sub { $field->readable($_[0], %options) } );
  return;
}

# $groups = $field->grouprecords($records, %options);
sub grouprecords {
  my($field, $records, %options) = @_;
  $field->sortrecords($records, %options);  
  my $group_hash = {};
  my $groups = [];
  foreach $record (@$records){
    my $readable = $field->readable($record);
    $readable = 'Miscellaneous' unless length($readable);
    if ( exists($group_hash->{ $readable }) ) {
      push @{ $group_hash->{ $readable }{'records'} }, $record;
    } else {
      my $new_group = {};
      $new_group->{'readable'} = $readable;
      $new_group->{'value'} = '';
      $new_group->{'records'} = [ $record ];
      push @$groups, $new_group;
      $group_hash->{$readable} = $new_group;
    }
  }
  return $groups;
}

### Configuration Fields

sub option_list {
  my $field = shift;
  return ( $field->name() ); 
}

sub option_title {
  my ( $field, %options ) = @_;
  return $field->title() || $field->name();
}

=head1 Field

Field provides an object oriented interface to L<Record|Record> fields. Field is an abstract superclass.

=head1 Synopsis

=head1 Reference

=head2 Subclass Factory Methods

These methods should be removed. The correct interface would be a through package variable or using the L<Class|Class> package.

=over 4

=item Field->add_subclass_by_name( $type )

Register concrete subclasses by type.

  Field::Text->add_subclass_by_name( 'text' );

=item Field->get_subclass_by_name( $type ) : $package

Returns a package name of the given type.

=back

=head2 Instantiation

=over 4

=item Field->new : $field

Returns a new field.

=item $field->init

Preforms initialization of field object. Fields must be initialized when they're created as other methods assume that this has happened.

=item Field->newfromdefinition ($definition) : $field

Returns a field as specified in %$definition. %$definition must specify the type of field.

=back

=head2 Option Handling

Many field methods accept a hash, %options, to specify their behavior. The Option Handling methods translate field specific drefs to an option hash. This is primarily an interface for L<Record|Record's> implementation of the 'get' method. See individual Field methods for supported options and drefs. For general information on DRefs, see L<Data::DReF>.

=over 4

=item $field->options($string) : %options

Converts field specific drefs to option hashes. 

  %options = $field->options( 'length.20.formsize.55' );
  $html = $field->edit( $record, %options );

=item $field->next_option( @$path, %$options )

This method is a private method called by option in a template relationship for subclassing. As a general rule, a subclass will handle the next option in the path, making the appropriate changes to both the path and %$options, or call its superclass's next_option method.

=back

=head2 View

The View methods use L<Script::Html|Script::HTML> to generate HTML output.

=over 4

=item $field->title($record, %options) : $html

Returns the title of $field.

=item $field->has_value($record) : $flag

Returns true if $record contains data assosciated with $field.

=item $field->value($record) : $value
=item $field->value($record, $value)

Returns the value for $field from $record; if a value is provided, the record is updated first. This is primarily a private interface.

=item $field->readable($record, %options) : $text

Returns user readable text corresponding to the value for $field in $record.

=item $field->display($record, %options) : $html

Returns HTML corresponding to the value for $field in $record.

=item $field->edit($record, %options) : $html

Returns an HTML <input type=text> tag.

Supported %options include:

=over 4

=item formsize

Specifies the size of the HTML input form returned. As a dref, the item after formsize in will be taken as a value.

  formsize.10

=item prefix

Sets a prefix to the name attribute of the HTML input tag. When L<WebApp::Request::CGI> parses the posted HTML form, The prefix will be used to determine the location of the submitted data in $theData (see L<Data::Dref>). 'request.args' is the root of all form submissions. the data for an edit form with a prefix of 'record', will be accesable at the dref "request.args.record.$fieldname". When passing a prefix to a field using the $field->option() method, the item immediately after 'prefix' is taken as a value.

  prefix.record

When passing a nested dref, backslash escape the dref separators.

  prefix.record\.1

=back

=item $field->editvalue($record) : $html

This function is called by the edit function to supply a value for the form from $record.

=item $field->escape( $escape_style, $value ) : $escaped_value

This method is a proxy for the escape function in the package L<Text::Escape>.

=item $field->align() : $align

Returns 'right', 'left' or 'center', indicating the proper alignment for data when displayed in a tablular format.

=item $field->colwidth() : $pixels

Returns a column width, in pixles for displaying $field's data in a tablular conttext.

=item $field->sorters() : @drefs_to_sort_records_by

Returns a list of drefs to be passed to L<Record>'s get method. The values of these drefs are used to sort records. By default "field.readable.$fieldname"
is the only item in the list.

=back

=head2 Data Persistence

=over 4

=item $field->flatten($record, $target)

Sets simple (non-nested) keys and values for the value of $field in $record into $target to form a flat record, conceptually similar to a row in a table.

=item $field->unflatten($record, $row)

Sets values for $field in $record from a flattened $row.

=item $field->flat_fields() : @%$flat_fields

Returns a list of hash refs needed to commit flattened data to a L<DBAdaptor>. Flat field hashes contain the following keys:

=over 4

=item name

The name of a column in a storage table. The default behavior is to use $field->{'name'}.

=item type

The type of $field's data.

=back

=item $field->sql_datatype

Returns the type of $fields data. Called by $field->flat_fields.

=item $field->deleteprep($record)

Called by L<Record> before deleting $record allowing $field to make necssesary preparations.

=item $field->cleanup($record)

Called by L<Record> after deleting $record.

=back

=head2 Record Data Modification

=over 4

=item $field->default($record)

Sets a default value in $record for $field by interpreting $field->{'default'} as L<Script>.

=item $field->update($master_record, $updates);

Updates $record with user data, $updates. This function is tightly bound to the edit method.

=back

=head2 User Data Validation 

Thes methods return $level, a string, either 'none' or 'error', and a reference to a list of error messages.

=over 4

=item $field->scrutinize($record, level) : ($level, $msgs)

Calls the require method if $field->{'require'} is set to 'yes'. Calls the validate method. Returns the higher of the two error levels and all of the messages.

=item $field->require( $record ) : ($level, @$messages)

Checks to see that required data exists for $field in $record. This method is called by scrutinize.

=item $field->validate($record) : ($level, $msgs)

Checks to see that user data is valid. This method is called by scrutinize.

=item $field->totalvalidate($level, $msgs, $level2, $msgs2) : ($level, $msgs)

Resolves two sets of error level and messages. 

=item $field->has_errors( $record ) : $flag

Returns true if $field has errors associated with $record.

=back

=head1 Caveats and Upcoming Changes

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut

### Field::Definition - Editable field definition objects

### Change History
  # 1998-01-23 Build - Jeremy

package Field::Definition;

use FieldSet;
@ISA = qw[ FieldSet ];

use vars qw[ %known_subclasses $fields $fieldorder $init ];
use Carp;
use Ref;

# Field::Definition->add_subclass_by_name( $type )
sub add_subclass_by_name {
  my ( $package, $type ) = @_;
  $known_subclasses{ $type } = $package;
  return;
}

# @$field_definitions = Field::Definition->new_from_fields( @$fields );
sub new_from_fields {
  my ( $package, $fields ) = @_;
  my $field_defs = [];
  my $field;
  foreach $field (@$fields) {
    push @$definitions, $package->new_from_field( $field );
  }
  return $field_defs;
}

# $field_definition = Field::Definition->new_from_field( $field );
sub new_from_field {
  my ( $package, $field ) = @_;
  my $definition = copyref( $field );
  return $package->new_from_definiton( $definition );
}

# $field_definition = Field::Definition->new_from_definition( %$definition );
sub new_from_definition {
  my ( $package, $definition ) = @_;
  
  my $subclass = $known_subclasses{ $definition->{'type'} };
  $subclass ||= Field::Definition;
  
  die "Bad field definition type '$definition->{'type'}'\n" unless $subclass;
  $subclass->init();
  return $subclass->new( %$definition );
}

# $field_definition = $concrete_subclass->new( %definition );
sub new {
  my $package = shift;
  my $definition = { @_ };
  return bless $definition, $package;
}

sub init {
  return if ( $init ++ );
  Field::Definition->set_fields_from_def([
    {
      'name' => 'title',
      'type' => 'text',
      'title' => 'Title',
      'hint' => ''
    },
    {
      'name' => 'align',
      'type' => 'select',
      'list' => [ 'right', 'left' ],
      'title' => 'Alignment',
      'default' => 'right',
      'hint' => ''
    },
    {
      'name' => 'hint',
      'type' => 'text',
      'title' => 'Hint'
    },
    {
      'name' => 'searchhint',
      'type' => 'text',
      'title' => 'Search Hint'
    },
    {
      'name' => 'length',
      'type' => 'text',
      'type' => 'integer',
      'minimum' => 1,
      'default' => 64,
      'title' => 'Length'
    },
    {
      'name' => 'require',
      'type' => 'select',
      'list' => [ 'yes', 'no' ],
      'title' => 'Require Input'
    },
    {
      'name' => 'show',
      'type' => 'select',
      'list' => [ 'yes', 'no' ],
      'title' => 'Show in Detail View'
    },
    {
      'name' => 'unique',
      'type' => 'select',
      'list' => [ 'yes', 'no' ],
      'title' => 'Require Unique Value'
    }
  ]);
}

1;

=pod

=head1 Field::Definition

Field::Definition, a subclass of L<Record>, provides an interface to field object definitions. The Field::Definition class hierarchy has a one to one relationship with the L<Field> hierarchy. By convention, each field package has a subpackage, Definition ( e.g. The package for definitions of L<Field::Text> objects is L<Feild::Text::Definition> ).

=head1 Synopsis

=head1 Reference

=over 4

=item Field::Definition->add_subclass_by_name( $type )

Register concrete subclasses by type.

  Field::Text::Definition->add_subclass_by_name( 'text' );

=item Field::Definition->new_from_field( $field ) : $field_definition

Returns a field definition for the L<Field> object passed to it. Note, the field definition is made from a copy if the field; Modifying values in the field definition will not effect the behavior of the L<field> object from which it was spawned. 

=item Field::Definition->new_from_fields( @$fields ) : @$field_definitions

Returns a list of field definitions from a list of fields.

=item Field::Definition->new_from_definition(%$definition) : $field_definition

Accepts a hash reference, blesses it into the appropriate subclass. note, the definition must have an entry for type.

=item $concrete_subclass->new( %definition ) : $field_definition

$concrete_subclass is a package name. Returns a field definition.

=back

=head1 Caveats and Upcoming Changes

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut