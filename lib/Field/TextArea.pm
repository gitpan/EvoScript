### Field::TextArea.pm
  # A long text field

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-05-20 Specified format for text input in sub edit. -Dan
  # 1998-05-19 Uncommented the \r\n fix.
  # 1998-04-29 Set default escape back to htmltext.
  # 1998-03-18 Added default 'wide' attribute.
  # 1997-11-17 Moved to v4 libs
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-08-12 Added CRLF patch.
  # 1997-06-07 Overhaul. -Simon
  # 1997-05-25 Changed this back to a two-column format.
  # 1997-03-17 Refactored & standardized; added standard header. -Simon

package Field::TextArea;

use Field;
@ISA = qw[ Field::Text ];

use Script::HTML::Styles;
use Script::HTML::Forms;
use Data::DRef;

use Script::HTML::Escape;

Field::TextArea->add_subclass_by_name( 'textarea' );

### INSTANTIATION

# $field->init
sub init {
  my ($field) = @_;
  $field->{'length'} ||= 8192;
  $field->{'wide'} ||= 1;
  $field->{'escape'} ||= 'htmltext';
  $field->{'formsize'} ||= 57;
  $field->SUPER::init();
}

### OPTION HANDLING

# $field->next_option( @$path, %$options )
sub next_option {
  my($field, $path, $options) = @_;

  my $item = shift( @$path );

  if ( $item eq 'formrows' ) {
    $options->{'formrows'} = shift( @$path );    
  } else {
    unshift( @$path, $item );
    $field->SUPER::next_option( $path, $options ); 
  }

  return;
}

### VIEW

# $html = $field->edit($record, %options)
sub edit {
  my ($field, $record, %options) = @_;
  
  $value =~ s/\r\n/\n/g; # What to do with this CRLF patch -- keep it!
  
  return stylize('input',
    Script::HTML::Forms::TextArea->new( {
      'cols' => $options{'formsize'} || $field->{'formsize'} || 57,
      'rows' => $options{'formrows'} || $field->{'editrows'} || 8,
      'name' => joindref( $options{'prefix'}, $field->{'name'} ),
      'wrap' => 'virtual'
    }, html_escape($field->value($record)))->interpret()
  );
}

1;