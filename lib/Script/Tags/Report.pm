### Script::Tags::Report generates columnar tables for records and the like

### Caveats and Things To Do
  # - Combine the display and subtotal column structures.

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Piglet   E. J. Evans         (piglet@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-05-29 Switched to use of Script::Evaluate package instead of Script.-S
  # 1998-05-04 Added "if scalar @subtotals" to expand.  -Piglet
  # 1998-04-23 Changed link logic in columns_for_record.
  # 1998-04-20 Changed columns_for_record's map to foreach to avoid $_ problems
  # 1998-04-17 Updated to use new Data::Sorting interface.
  # 1998-03-11 Inline POD added. -Simon
  # 1998-03-11 Improved columns_for_record to set dref to readable or link.
  # 1998-03-10 Changed 'die' in columns_for_record to 'return []'.  -Piglet
  # 1998-03-03 Removed uses of field.group.name drefs; field.readable instead
  # 1998-01-25 Refactored to support non-record items, new cell options. -Simon
  # 1997-12-04 Finished implementing sub-totals behavior.  -Piglet
  # 1997-11-25 Improved column-level information structure.
  # 1997-11-20 Found cell-option scoping problem; bgcolors alternate again. -S.
  # 1997-11-11 Extracted from fieldtags.pm. -Piglet

package Script::Tags::Report;

$VERSION = 4.00_1998_03_11;

use Script::Evaluate qw( runscript );
use Script::Tag;
@ISA = qw( Script::Tag );

use Err::Debug;  

use Data::DRef;
use Data::Collection;
use Data::Sorting qw( sort_in_place );

use Text::Format qw( formatted );
use Script::HTML::Styles;
use Script::HTML::Tables;

Script::Tags::Report->register_subclass_name();
sub subclass_name { 'report' }

%ArgumentDefinitions = (
  'records' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
  
  'display' => {'dref'=>'optional', 'required'=>'hash_or_nothing'},
  
  'columns' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
					    # really, list of hashes
  'fieldorder' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
  'sortorder' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
  'groupby' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
  'grouporder' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
  'subtotals' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
  
  'block' => {'dref'=>'optional', 'required'=>'string_or_nothing' },
  'colheader' => {'dref'=>'no', 'default'=> '1', 'required'=>'flag'},
  'border' => {'dref'=>'no', 'default'=> '0' },
  'width' => {'dref'=>'no', 'default'=> '100%' },
  'nocolor' => {'required' => 'flag'},
);

# $args = $tag->get_args();
  # Allow people to pass in a display argument refering to an options hash.
sub get_args {
  my $tag = shift;
  my $args = $tag->SUPER::get_args();
  
  debug('report', ['$args->{\'grouporder\'} :'], $args->{'grouporder'});

  if ($args->{'display'}) {
    $args->{'sortorder'} ||= $args->{'display'}{'sortorder'};
    $args->{'fieldorder'} ||= $args->{'display'}{'fieldorder'};
    $args->{'block'} ||= $args->{'display'}{'block'};
    $args->{'groupby'} ||= $args->{'display'}{'groupby'};
    $args->{'grouporder'} ||= $args->{'display'}{'grouporder'};
    $args->{'subtotals'} ||= $args->{'display'}{'subtotals'};
  }

  # debug('report', ['$args are:'], $args);
  
  return $args;
}

# $htmltext = $report->interpret;
sub interpret {
  my $report = shift;
  $report->expand->interpret;
}

# $table = $report->expand;
sub expand {
  my $report = shift;
  my $args = $report->get_args;
  
  # Content Items
  local $report->{'items'} = $args->{'records'} || [];
  my $itemzero = $report->{'items'}[0];
  
  # Sorting and Grouping
  local $report->{'sortorder'} = $args->{'sortorder'} || [];
  map { $_ = "field.readable." . $_ } @{$report->{'sortorder'}}
				  if UNIVERSAL::isa($itemzero, 'Record');
  local $report->{'groupby'} = $args->{'groupby'} || [];
  map { $_ = "field.readable." . $_ } @{$report->{'groupby'}}
				  if UNIVERSAL::isa($itemzero, 'Record');
  local $report->{'grouporder'} = $args->{'grouporder'} || [];
  map { $_ = "field.readable." . $_ } @{$report->{'grouporder'}}
				  if UNIVERSAL::isa($itemzero, 'Record');
  
  # Columns
  local $report->{'columns'} = $args->{'columns'} ||
	    $report->columns_for_record($itemzero, @{$args->{'fieldorder'}} );
  debug('report', 'Columns are ', $report->{'columns'});
  
  local $report->{'subtotals'} = 
	    $report->columns_for_record($itemzero, @{$args->{'subtotals'}}  )
	    if scalar @{$args->{'subtotals'}};
  
  local $field2cols = {};
  foreach $i (0..$#{$report->{'columns'}}) { 
    $field2cols->{ $report->{'columns'}[$i]{'fieldname'} } = $i; 
  }
  foreach $field (@{$report->{'subtotals'}}) { 
    $field2cols->{ $field->{'fieldname'} } = scalar(keys %$field2cols)
    				unless $field2cols->{ $field->{'fieldname'} }; 
  }
  debug 'report', "My field2cols hash is", $field2cols;
  
  # Spanning Line
  local $spanning_line = sub { Script::runscript($args->{'block'}) } 
							  if $args->{'block'};
  
  # Styling
  local $nocolor = $args->{'nocolor'};
  
  # Build the Table
  local $target = table( { 'cellspacing' => 0, 'cellpadding' => 2,
		'width' => $args->{'width'}, 'border' => $args->{'border'} });
  
  $target->add($report->columntitles) if ( $args->{'colheader'} );
  
  $report->do_tabulation( $target, {}, $report->{'items'}, 0 );
  
  return $target;
}

### Columns

# %@$columns = $report->columns_for_record($record, @fieldnames);
sub columns_for_record {
  my $report = shift;
  my $record = shift; 	  # UNIVERSAL::isa($record, 'Record')
  return [] unless (ref $record);
  my $count = 0;
  my $links = UNIVERSAL::isa($record, 'Record') && 
		$record->datastore && $record->datastore->user_can('view');
  my $title = $record->default_fieldname;
  
  my $fieldname;
  my @columns;
  foreach $fieldname ( @_ ) {
    my $method = $links && ($fieldname eq $title) ? 'link' : 'display';
    push @columns, {
      'fieldname' => $fieldname,
      'position' => $count++,
      
      'dref' => "field.$method.$fieldname",
      'valref' => "field.value.$fieldname",
      
      'title' => getDRef($record, "field.title.$fieldname") || '',
      'align' => getDRef($record, "field.align.$fieldname") || 'left',
      'format' => getDRef($record, "field.format.$fieldname") || '',
      'width' => getDRef($record, "field.colwidth.$fieldname") || 0,
    }
  }
  return \@columns;
}

# $html_row = $report->columntitles()
sub columntitles {
  my $report = shift;
  my $style = $nocolor ? 'bold' : 'heading';
  my $opts = { 'valign' => 'bottom' };
  $opts->{'bgcolor'} = 'colhead' unless $nocolor;
  my $row = row('');
  my $column;
  foreach $column (@{$report->{'columns'}}) {
    local $opts->{'width'} = $column->{'width'} if ( $column->{'width'} );
    $row->add(cell( {%$opts, 'align' => $column->{'align'}}, 
    		stylize($style, $column->{'title'} || '&nbsp;') ));
  }
  foreach $column (@{$report->{'subtotals'}}) {
    next if ( $field2cols->{ $column->{'fieldname'} } < 
					      scalar(@{$report->{'columns'}}));
    local $opts->{'width'} = $column->{'width'} if ( $column->{'width'} );
    $row->add(cell( {%$opts, 'align' => $column->{'align'}}, 
	      stylize($style, $column->{'title'} || '&nbsp;') )) 
  }
  return $row;
}

### Tabulation

# $report->do_tabulation( $table, $totals, $items, $round )
sub do_tabulation {
  my ($report, $table, $totals, $items, $round) = @_;
  
  my ($subtable, $subtotals) = $report->build_table($items, $round);
  $table->add_table_to_bottom($subtable);
  
  if (scalar @{$report->{'subtotals'}}) {
    $table->add( $report->totals_row($subtotals, 
		  ( $round ? 'Subtotals:  &nbsp;' : 'Totals: &nbsp;' ) ) );
    $report->add_totals( $totals, $subtotals );
  }
}

# ($table, $totals) = $report->build_table( $items, $round );
sub build_table {
  my ($report, $items, $round) = @_;
  
  # No Items In List
  return $report->no_items_in_list if (scalar @$items < 1);
  
  # Break into groups and recurse
  return $report->grouped_table( $items, $round )
				unless (($#{$report->{'groupby'}}) < $round);
  
  # Tabulate
  return $report->table_for_items($items, $round % 2)
}

# ($table, $totals) = $report->no_items_in_list;
sub no_items_in_list {
  my $report = shift;
   
  return table('', row('', cell( { 'colspan' => $target->colspan() }, 
	  stylize('normal', "No items in list.")))), {};
}

# ($table, $totals) = $report->grouped_table( $items, $round );
sub grouped_table {
  my ($report, $items, $round) = @_;
  
  my $group_label = $report->{'groupby'}->[$round];
  my $group_sort = $report->{'grouporder'}->[$round] || $group_label;
  debug('report', ["\$group_label = '$group_label'", "\$group_sort = '$group_sort'"]);
  debug('report', ["\$report->{'grouporder'}", $report->{'grouporder'}]);

  my $groups = orderedindexby($items, $group_label, $group_sort);
  
  my $table = table('', '');
  my $totals = {};
  
  foreach $group (@$groups) {
    $table->new_row( cell( { 'colspan' => $target->colspan }, 
    	stylize('group' . $round, 
	  (length $group->{'value'} ? $group->{'value'} : 'None' ))));
    
    $report->do_tabulation( $table, $totals, $group->{'items'}, $round + 1 );
    
    $table->new_row( cell( { 'colspan' => $target->colspan }, 
			   	 stylize('normal', '&nbsp;'))) unless $round; 
  }
  
  return ($table, $totals);
}

# ($table, $totals) = $report->table_for_items( $items, $even_flag );
sub table_for_items {
  my ($report, $items, $even) = @_;
  my $table = table('', '');
  my $totals = {};

  sort_in_place($items, @{$report->{'sortorder'}} )  
  					if scalar(@{$report->{'sortorder'}});
  
  foreach $item (@$items) {
    $table->add( $report->rows_for_item($item, $even) );
    $report->add_item_to_totals($totals, $item);
    $even = ! $even;
  }
  
  debug 'report', "My totals in table_for_items are", $totals;
  return ($table, $totals);
}

# @rows = $report->rows_for_item($item, $even);
sub rows_for_item {
  my $report = shift;
  my ($item, $even) = @_;
  
  my $args = { 'valign' => 'top' };  
  $args->{'bgcolor'} = ($even ? 'alternate' : 'background') unless $nocolor;
  
  my $row = row('','');
  
  my $column;
  foreach $column (@{$report->{'columns'}}) {
    my $value = getDRef( $item, $column->{'dref'} );
    $value = '&nbsp;' unless (defined $value and length $value);
    $row->add( cell({%$args, 'align' => $column->{'align'}}, 
		    stylize('normal', $value)));
  }
  
  my @rows = ( $row );
  
  # Spanning line
  if ($spanning_line) {
    setData('-record', $item);
    debug 'report', "My item body is", $item->{'body'};
    my $line = &$spanning_line;
    debug 'report', "My line is $line";
    push @rows, row({}, cell( { %$args, 'align' => 'left', 
	    'colspan' => $target->colspan }, stylize('normal', $line)))
							  if ($line =~ /\S/);
  }
  return @rows;
}

### Totals

# $report->add_item_to_totals($totals, $item);
sub add_item_to_totals {
  my $report = shift;
  my ($totals, $item) = @_;
  my $col;
  foreach $col (@{$report->{'subtotals'}}) { 
    $totals->{ $col->{'fieldname'} } ||= 0;
    $totals->{ $col->{'fieldname'} } += getDRef( $item,  $col->{'valref'} ); 
  }
}

# $report->add_totals($base_totals, $totals_to_be_added);
sub add_totals {
  my $report = shift;
  my ($totals, $others) = @_;
  
  foreach $field (@{$report->{'subtotals'}}) { 
    $totals->{ $field->{'fieldname'} } ||= 0; 
    $totals->{ $field->{'fieldname'} } += $others->{$field->{'fieldname'}}; 
  }
}

# $row = $report->totals_row( $totals, $label );
sub totals_row {
  my ($report, $totals, $label) = @_;
  
  debug 'report', "Building subtotal row for totals", $totals;
  
  my @cells = map { cell('') } (1..scalar(keys %$field2cols));
  foreach $field (@{$report->{'subtotals'}}) { 
    my $value = $totals->{$field->{'fieldname'}};
    $value = formatted($field->{'format'}, $value) if $field->{'format'};
    my $cell = $cells[$field2cols->{ $field->{'fieldname'} }];
    $cell->{'args'}{'align'} = $field->{'align'} || 'left';
    $cell->add( stylize('normal', $value) );
  }
  
  $cells[0]->prepend(Script::Literal->new(stylize('label', $label))) 
				  	if (defined $label and length $label);
  
  return row(@cells) ;
};

1;

__END__

=head1 Report

Generate a columnar table showing fields from a set of records.

    [report records=#my.records fieldorder="name email" sortorder=name]

=item records

A reference to an array of records to display. Use '#' for DRefs. Required argument. 

=item display

Optional. If provided, the fieldorder, sortorder, groupby, block, and subtotals arguments will default to the values provided in the similarly named keys in the display hash..

=item columns

Optional. The report tag will use the provided array of column definitions hashes instead of constructing one from the fieldorder and information from the record's fields (title, alignment, etc.). Check the columns_for_record() function for examples if you're intrested in providing your own column definitions

=item fieldorder

The field names to display as columns. Required, unless B<columns> are specified, or a fieldorder is supplied in B<display>.

=item sortorder

Optional. The field names to sort on. 

=item groupby

Optional. The field names to group on. If provided, records with the same values for these fields will be listed below a header showing that value. 

=item subtotals

Optional. The field names for which to calculate totals and subtotals. 

=item block

Optional. Script text to be evaluated for each record. If the script returns any non-whitespace value, it is inserted into a new row, spanning all of the columns. To refer to the current record in this script, use #-record.

=item colheader

Optional flag; defaults to true. If cleared, the column header row will not be generated.

=item border

Border for the HTML table. Defaults to 1.

=item width

Width for the HTML table. Defaults to 100%.

=item nocolor

Optional flag. If set, the table cell background colors will not be set.

=back

=cut