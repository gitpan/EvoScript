### Field::Compound::Name.pm - First, Middle, Last name compound field

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-05-22 Changed usage of required field indicators. -Dan
  # 1998-05-15 Swapped the variables from the return of field->value
  #            in compound_readable.  They were wrong.
  #            Added row_edit method to display the subfields of
  #            this field on separate lines. -EJM
  # 1998-04-23 Added edit_title method for compound edits.
  # 1998-03-27 Added length properties to all the subfields.  -EJM
  # 1998-03-18 Changed layout.
  # 1998-03-13 Changed fieldnames. -Simon
  # 1997-11-07 Rebuilt in v4 libraries - Nine Doose
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-07 Overhaul. -Simon
  # 1997-04-20 Moved compound fields into field::compound::*
  # 1997-03-17 Refactored & standardized; added standard header. -Simon
  # 1997-03-16 not a lame .pm. -Jeremy

package Field::Compound::Postal;

use Field::Compound;
@ISA = qw[ Field::Compound ];
Field::Compound::Postal->add_subclass_by_name( 'postal' );

use Script::HTML::Tag;
use Data::DRef;

### OPTION HANDLING

# $field->next_option( @$path, %$options )
sub next_option {
  my($field, $path, $options) = @_;

  my $item = shift( @$path );

  if ( $item eq 'order' ) {
    $options->{'order'} = shift( @$path );    
  } else {
    unshift( @$path, $item );
    $field->SUPER::next_option( $path, $options ); 
  }

  return;
}

sub option_list {
  my $field = shift;
  my $name = $field->name();
  my @options = ( $name );
  my $subfieldname;
  foreach $subfieldname ( keys %{ $field->{'subfields'} } ) {
    push @options, joindref( $name, 'subfield', $subfieldname );
  }
  return @options;
}

sub option_title {
  my ($field, %options) = @_;
  $field->title();
}

### VIEW

# $text = $field->compound_readable($record, %options);
sub compound_readable {
  my($field, $record, %options) = @_;
  
  my($street, $city, $state, $zip, $country) = $field->value($record);
  
  my $text = $street . "\n" . 
	     $city . (length $city && length $state ? ', ':'') . 
	     $state . ' ' . $zip . "\n" .
	     $country . "\n";
  
  $text =~ s/\n(?=\n|\Z)//g;
  
  return $text;
}

# $text = $field->compound_display($record, %options);
sub compound_display {
  my($field, $record, %options) = @_;
  my $postal = $field->compound_readable($record, %options);
  warn "postal $postal\n";
  return $field->escape('htmltext', $postal);
  # maybe we make a link to the mapping module here?
}


# 
# These routines are not called anymore from the detail 
# page.  They have been replaced by the routine, row_edit
# below that breaks out the subfields onto separate rows
# within the HTML table display.
# 
# $html = $field->edit_title($record, %options);
sub edit_title {
  my ($field, $record, %options) = @_;
  $field->SUPER::edit_title($record, %options) . '<br>' .
  $field->subfield('street')->title . '<br>' .  
  $field->subfield('city')->title . ', ' . 
  $field->subfield('state')->title . ', ' . 
  $field->subfield('zip')->title . '<br>' . 
  $field->subfield('country')->title;
}

# $text = $field->compound_edit($record, %options);
sub compound_edit {
  my($field, $record, %options) = @_;
  return(
      $field->subfield('street')->edit($record, 'prefix'=>$options{'prefix'})
    . html_tag('br', {})->interpret
    . $field->subfield('city')->edit($record, 'prefix'=>$options{'prefix'})
    . Script::HTML::Escape::nonbreakingspace()
    . $field->subfield('state')->edit($record, 'prefix'=>$options{'prefix'})
    . Script::HTML::Escape::nonbreakingspace()
    . $field->subfield('zip')->edit($record, 'prefix'=>$options{'prefix'})
    . html_tag('br', {})->interpret
    . $field->subfield('country')->edit($record, 'prefix'=>$options{'prefix'})
  );
}

# $text = $field->compound_search($record, %options);
sub compound_search {
  my($field, $record, %options) = @_;
  return $field->compound_edit( $record, %options );
}


# $field->row_edit($record, @rows, %options);
sub row_edit {
  my ($field, $record, $rows, %options) = @_;

  # Get some of the common pieces into temporary variables
  # to save some time.

  my $fieldname = $field->name;
  my $prefer_wide = $record->prefer_wide_row ( $fieldname );
  my $hint = $field->{'hint'};
  
  # First push the label for the address field.

  push @$rows, {
     'title' => $field->title . ':',
     'wide' => $prefer_wide,
     'hint' => $hint,
     'required' => $field->{'require'},
     };

  # Now, cycle through the subfields and put them in the proper rows.
  # Street

  push @$rows, {
     'title' => $field->subfield('street')->title . ': ',
     'wide' => $prefer_wide,
     'display' => $field->subfield('street')->edit($record, 'prefix'=>$options{'prefix'}),
     'errors' => $record->errors->{ $fieldname },
     'hint' => $hint,
     };

  # City
  push @$rows, {
     'title' => $field->subfield('city')->title . ': ',
     'wide' => $prefer_wide,
     'display' => $field->subfield('city')->edit($record, 'prefix'=>$options{'prefix'}),
     'errors' => $record->errors->{ $fieldname },
     'hint' => $hint,
     };

  # State/Province
  push @$rows, {
     'title' => $field->subfield('state')->title . ': ',
     'wide' => $prefer_wide,
     'display' => $field->subfield('state')->edit($record, 'prefix'=>$options{'prefix'}),
     'errors' => $record->errors->{ $fieldname },
     'hint' => $hint,
     };

  # Zip
  push @$rows, {
     'title' => $field->subfield('zip')->title . ': ',
     'wide' => $prefer_wide,
     'display' => $field->subfield('zip')->edit($record, 'prefix'=>$options{'prefix'}),
     'errors' => $record->errors->{ $fieldname },
     'hint' => $hint,
     };

  # Country
  push @$rows, {
     'title' => $field->subfield('country')->title . ': ',
     'wide' => $prefer_wide,
     'display' => $field->subfield('country')->edit($record, 'prefix'=>$options{'prefix'}),
     'errors' => $record->errors->{ $fieldname },
     'hint' => $hint,
     };

}

### SUBFIELD INSTANTIATION

# %@$subfield_definitions = $field->subfield_definitions();
sub subfield_definitions {
  return( [
    {
      'name' => 'street',
      'type' => 'textarea',
      'editrows' => 2,
      'formsize' => 37,
      'title' => 'Street',
      'length' => 64,
    },
    {
      'name' => 'city',
      'type' => 'text',
      'title' => 'City',
      'formsize' => 18,
      'length' => 32,
    },
    {
      'name' => 'state',
      'type' => 'text',
      'title' => 'State/Province',
      'formsize' => 8,
      'length' => 32,

    },
    {
      'name' => 'zip',
      'type' => 'text',
      'title' => 'ZIP/Postal Code',
      'formsize' => 10,
      'length' => 16,
    },
    {
      'name' => 'country',
      'type' => 'text',
      'title' => 'Country',
      'length' => 16,
},
  ] );
}
### VALIDATION

# # ($level, $msgs) = $field->require($record)
# sub require {
#   my ($field, $record) = @_;
#   my($first, $middle, $last) = $field->value($record);
# 
#   return('error', [$field->title . ' requires a value'])
#     if(($middle && !($first && $last)) || !($first || $middle || $last));
# 
#   return('none',[]);
# }

1;