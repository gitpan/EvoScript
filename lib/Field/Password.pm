### field::text::password.pm

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)
  # Simon    M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 1998-06-04 Revised.
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-07 Overhaul. -Simon
  # 1997-03-17 Refactored & standardized; added standard header. -Simon
  # 1997-03-15 A subclass with class of it's own! -Jeremy

package Field::Password;

use Field::Text;
@ISA = qw[ Field::Text ];

Field::Password->add_subclass_by_name( 'password' );

use Data::DRef qw( joindref );
use Script::HTML::Styles qw( stylize );
use Script::HTML::Tag;

### Instantiation

# $field->init
sub init {
  my ($field) = @_;
  $field->{'hint'} ||= 'Enter password twice for verification.';
  $field->SUPER::init();
  return;
}

### Output Generation

# $html = $field->readable($record, %options)
sub readable {
  my ($field, $record, %options) = @_;
  return '******' if $field->value($record);
  return '- no password -';
}

# $html = $field->edit($record, %options)
sub edit {
  my ($field, $record, %options) = @_;
  
  my $html_fieldname = $options{'prefix'} ?
  	 joindref( $options{'prefix'}, $field->{'name'} ) : $field->{'name'};
  
  stylize('input', 
    Script::Sequence->new(
      Script::HTML::Forms::Input->new( {
	'name' => $html_fieldname . '.a',
	'type' => 'password',
	'size' => ( $options{'formsize'} || $field->{'formsize'} ),
	'value' => $record->{ $field->{'name'} }{'a'}
      } ),
      '<br>',
      Script::HTML::Forms::Input->new( {
	'name' => $html_fieldname . '.b',
	'type' => 'password',
	'size' => ( $options{'formsize'} || $field->{'formsize'} ),
	'value' => $record->{ $field->{'name'} }{'b'}
      } ),
    )->interpret
  );
}

# $field->update($master_record, $updates);
sub update {
  my ($field, $record, $updates) = @_;
  $record->{ $field->{'name'} }{'a'} = $updates->{ $field->{'name'} }{'a'} 
			    if ( exists $updates->{ $field->{'name'} }{'a'} );
  $record->{ $field->{'name'} }{'b'} = $updates->{ $field->{'name'} }{'b'} 
			    if ( exists $updates->{ $field->{'name'} }{'b'} );
  return;
}

# ($level, $msgs) = $field->validate($record)
sub validate {
  my($field, $record) = @_;
    
  return ('none', []) unless exists($record->{ $field->{'name'} }{'a'});
  
  return ('error', ['Passwords must be at least five characters long.'])
    unless( length( $record->{ $field->{'name'} }{'a'} ) > 4);
  
  if ( $record->{$field->{'name'}}{'a'} eq $record->{$field->{'name'}}{'b'} ) {
    $record->{ $field->{'name'} } = $record->{ $field->{'name'} }{'a'};
    return ('none', []);
  }
  
  delete($record->{ $field->{'name'} });
  
  return ('error', ['Password entry missmatch']);
}

1;