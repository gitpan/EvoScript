### Script::Tags::Detail provides a two-column record table layout for records

### Interface
  # [detail record=#x]
  # $text = $detailtag->interpret();

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-06-01 Changed record_edit 'required' to $field->{'require'} eq 'yes'.  -Piglet
  # 1998-05-27 Changed asterisk.jpeg to asterisk.jpg to be consistant with
  #            our other image files.  -EJM
  # 1998-05-27 Restored searchhints. -Simon
  # 1998-05-22 Left comlumn width no longer defaults to 160. -Dan
  # 1998-05-22 Changed usage of required field indicator. -Dan
  # 1998-05-18 Fields can now override their layout for edit forms by defining  
  #            a row_edit method; used by Field::Compound::Postal.  -EJM
  # 1998-05-05 Added $RequiredIndicator.
  # 1998-05-03 Changed left column width default to 160.
  # 1998-04-23 Added support for Field::Compound's $field->edit_title method 
  # 1998-03-19 Use new editable method to avoid editing calculated fields. -Del
  # 1998-03-11 Inline POD added.
  # 1998-02-01 Added compact_edit.
  # 1998-01-25 Use of field definition for field detail. 
  # 1997-12-04 Expanded field detail support into its own subclass.
  # 1997-12-02 Initial support for field detail.
  # 1997-11-26 Some reorganization, half-hearted support for field-details.
  # 1997-11-25 Added support for search mode -- maybe should subclass?
  # 1997-11-19 Added support for edit mode, error messages
  # 1997-11-10 Created. -Simon

package Script::Tags::Detail;

$VERSION = 4.00_1998_03_11;

use Script::HTML::Tables;

use Script::Tag;
@ISA = qw( Script::Tag );
use Err::Debug;

use Script::HTML::Styles;

# [detail record=#x]
Script::Tags::Detail->register_subclass_name();
sub subclass_name { 'detail' }

%ArgumentDefinitions = (
  'record' =>  {'dref' => 'optional', 'required'=>'anything'},
  'mode' =>  {'dref' => 'optional', 'default'=>'display',
  					 'required'=>'string_or_nothing'},
  'compacttitle' =>  {'dref' => 'optional', 'required'=>'anything'},
  'compactappend' =>  {'dref' => 'optional', 'required'=>'anything'},
);

# $text = $htmlmacro->interpret();
sub interpret {
  my $detail = shift;
  return $detail->expand->interpret;
}

# $html_table = $detailtag->expand();
sub expand {
  my $detail = shift;
    
  local $detail->{'rows'} = $detail->make_rows;
  
  return $detail->build_table();
}

### HTML Generation

# $html_table = $detailtag->build_table( );
sub build_table {
  my $detail = shift;
  my $table = Script::HTML::Table->new({'cellpadding'=>0, 'cellspacing'=>2});

  my $row;
  my $contains_required;
  foreach $row ( @{$detail->{'rows'}} ) {
    my $display = stylize('normal', $row->{'display'} );
    
    my $rower = $row->{'wide'} ? \&add_wide_row : \&add_normal_row;
    
    &$rower($table, $row->{'title'}, $display, $row->{'required'} );
    &$rower($table, '', stylize('hint', $row->{'hint'}) ) if $row->{'hint'};
    if ( $row->{'errors'} and scalar @{$row->{'errors'}} ) {
      &$rower($table, '', stylize('alert', join('<br>', @{$row->{'errors'}})));
    }
    $contains_required = 1 if ( $row->{'required'} );
  }

if ( $contains_required ) {
  $table->prepend(row({}, cell({'colspan'=>3}, stylize ('normal', '<img src=' . $WebApp::Handler::SiteHandler::Site->asset_url('images', 'asterisk.jpg'). '> indicates required field.'))));
}

  return $table;
}

# add_normal_row( $table, $label, $value );
sub add_normal_row {
  my ($table, $label, $value, $require) = @_;

  $table->new_row( 
    cell(
      { 'nowrap'=>1, 'valign'=>'top', 'align'=>'right'}, 
	( $label ? stylize('label', $label) : '' ) ),

    cell( 
      { 'valign'=>'top', 'align'=>'left', 'width'=>2 },
        ( $require ? $RequiredIndicator : '&nbsp;' ) ),

    cell({ 'valign'=>'top' }, $value )
  );
}

# add_wide_row( $table, $label, $value );
sub add_wide_row {
  my ($table, $label, $value, $require) = @_;
  
  $table->new_row( 
    cell({ 'colspan'=>3, 'valign'=>'top', 'align'=>'left'}, 
	( $label ? stylize('label', $label) . 
	( $require ? $RequiredIndicator : '&nbsp;' ) . '<br>' : '' ) . $value),
  );
}

### Record Interface

use vars qw( %display_functions );
%display_functions = (
  'sparse' => \&record_sparse_display,
  'display' => \&record_display,
  'edit' => \&record_edit,
  'search' => \&record_search,
  'compactedit' => \&record_compact_edit,
);

use vars qw( $RequiredIndicator );
$RequiredIndicator ||= '<font color=red>*</font>';

# %@$rows = $detailtag->make_rows();
sub make_rows {
  local $detail = shift;
  
  my $args = $detail->get_args;
  
  my $displayer = $display_functions{ $args->{'mode'} };
  die "unknown detail mode '$args->{'mode'}'\n" unless $displayer;
  
  my @rows;
  push @rows, &$displayer( $args->{'record'} );
  
  return \@rows;
}

# %@rows = record_sparse_display( $record );
sub record_sparse_display {
  my @rows;
  my $record = shift;
  my $fieldname;
  foreach $fieldname ( $record->fieldnames ) {
    next if $record->prefer_silent( $fieldname );
    
    my $display = $record->display( $fieldname );
    debug 'detail', 'Detail display:', $fieldname, '-', $display;
    next unless ( length $display );
    
    push @rows, { 
      'title' => $record->title( $fieldname ) .':',
      'display' => $display,
      'wide' => $record->prefer_wide_row( $fieldname ),
    };
  }
  return @rows;
}

# %@rows = record_display( $record );
sub record_display {
  my @rows;
  my $record = shift;
  my $fieldname;
  foreach $fieldname ( $record->fieldnames ) {
    next if $record->prefer_silent( $fieldname );
   push @rows, { 
      'title' => $record->title( $fieldname ) .':',
      'display' => $record->display( $fieldname ),
      'wide' => $record->prefer_wide_row( $fieldname ),
    };
  }
  return @rows;
}

# %@rows = record_edit( $record );
sub record_edit {
  my @rows;
  my $record = shift;
  my $fieldname;
  foreach $fieldname ( $record->fieldnames ) {
    # next if $record->prefer_silent( $fieldname );
    next unless $record->editable( $fieldname );
    my $field = $record->field( $fieldname );

    # See if there is an row_edit method for this field.  If so, we will 
    # do our processing there as we need to break out the subfields onto
    # individual lines.

    if ( $field->can('row_edit') ) {
       $field->row_edit ( $record, \@rows, 'prefix'=>'record' );
       }
    else {
       my $title = $field->can('edit_title') ? $field->edit_title( $record ) 
   					   : $record->title( $fieldname ) .':';
         
       push @rows, { 
         'title' => $title,
         'display' => $record->edit( $fieldname, 'prefix'=>'record' ),
         'wide' => $record->prefer_wide_row( $fieldname ),
         'errors' => $record->errors->{ $fieldname },
         'hint' => $field->{'hint'},
         'required' => (exists $field->{'require'} and $field->{'require'} eq 'yes'),
       };
    }
  }
  return @rows;
}

# %@rows = record_compact_edit( $record );
sub record_compact_edit {
  my @rows;
  my $record = shift;
  my $fieldname;
  $rows[0] = { 'wide' => 1, 'title'=> $detail->{'args'}{'compacttitle'}.':' };
  foreach $fieldname ( $record->fieldnames ) {
    my $field = $record->field( $fieldname );
    next unless $field->{'compact'};
    next unless $record->editable( $fieldname );
    #!# This isn't really general-purpose at the moment. -Simon
    
    if ( ! $record->prefer_wide_row( $fieldname ) ) {
      $rows[0]->{'display'} .= ' on ' if ( $rows[0]->{'display'} );
      $rows[0]->{'display'} .= $record->edit( $fieldname, 'prefix'=>'record' );
      push @{$rows[0]->{'errors'}}, @{$record->errors->{ $fieldname }};
      $rows[0]->{'hint'} .= $field->{'hint'};
    } else {
      my $title = $record->title( $fieldname ) .':';
      $title .= $RequiredIndicator if ( $field->{'require'} eq 'yes' );
      push @rows, { 
	'title' => $title,
	'display' => $record->edit( $fieldname, 'prefix'=>'record' ),
	'wide' => 1,
	'errors' => $record->errors->{ $fieldname },
	'hint' => $record->field( $fieldname )->{'hint'},
      };
    }
  }
  $rows[0]->{'display'} .= $detail->{'args'}{'compactappend'};
  
  return @rows;
}

# %@rows = record_search( $record );
sub record_search {
  my @rows;
  my $record = shift;
  my $fieldname;
  foreach $fieldname ( $record->searchfields ) {
    next if $record->prefer_silent( $fieldname );
    my $field = $record->field( $fieldname );
    
    push @rows, {
      'title' => $record->title( $fieldname ) .':',
      'display' => $record->edit_criteria({},$fieldname, 'prefix'=>'criteria'),
      'hint' => $field->{'searchhint'},
    };
  }
  return @rows;
}

### Field Interface

package Script::Tags::FieldDetail;

use Script::Tags::Detail;
@ISA = qw( Script::Tags::Detail );

# [fielddetail field=#fielddef step=n]
Script::Tags::FieldDetail->register_subclass_name();
sub subclass_name { 'fielddetail' }

%ArgumentDefinitions = (
  'field' =>  {'dref' => 'optional', 'required'=>'anything'},
  'step' =>  {'dref' => 'optional', 'required'=>'string_or_nothing'},
);

# %@$rows = $detailtag->make_rows();
sub make_rows {
  my $detail = shift;
  
  my $args = $detail->get_args;
  my $f_def = $args->{'field'};
  
  my $prefix = 'instance';
  my @rows;
  if ( $args->{'step'} eq 'type' ) {
    push @rows, { 'title' => 'Name:', 
		  'display' => $f_def->edit( 'title', 'prefix'=>$prefix ) };
    push @rows, { 'title' => 'Type:',
		  'display' => Script::HTML::Forms::Select->new(
		      { 'name'=>"$prefix.type", 'current'=>$f_def->{'type'} },
		      map { 
			Script::HTML::Forms::Option->new({'value' => $_,
							  'label' => "\u$_" }) 
		      } sort keys %Field::known_subclasses
		    )->interpret };
    
  } elsif ( $args->{'step'} eq 'options' ) {
    my $fieldname;
    foreach $fieldname ( $f_def->fieldnames ) {
      next if ( $fieldname eq 'title' or $f_def->prefer_silent($fieldname) );
      push @rows, { 
	'title' => $f_def->title( $fieldname ) .':',
	'display' => $f_def->edit( $fieldname, 'prefix' => $prefix ),
	'wide' => $f_def->prefer_wide_row( $fieldname ),
	'errors' => $f_def->errors->{ $fieldname },
	'hint' => $f_def->field( $fieldname )->{'hint'},
      };
    }
  } else {
    die "unsupported step '$args->{'step'}'";
  }
  
  return \@rows;
}

1;

__END__

=head1 Detail

Generate an HTML table showing fields from a Record object. 

    [detail record=#my.record mode=display]

=over 4

=item record

The record to display. Use '#' for DRefs. Required argument. 

=item mode 

The type of detail display view to generate. Use '#' for DRefs. Defaults to display. Supported values are as follows:

=over 4

=item display

Display each field and its value, unless the field prefers_silent (via the show=0 attribute). 

=item sparse

Display each field for which the record has a value. 

=item edit

Display each field and HTML form elements that will allow the current values of the record to be updated. 

=item compactedit

Attempts to generate a short edit form. This mode is still B<incomplete>.

=item search

Display each field that has its searchable flag set, along with HTML form elements that allow the user to specify search criteria for this class of record. 

=back

=item compacttitle, compactappend

Workaround arguments for the B<incomplete> compactedit mode; these are expected to change.

=back

=cut

