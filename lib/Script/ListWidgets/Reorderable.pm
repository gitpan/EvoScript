### Script::HTML::Lists displays HTML selects for lists

### Example Usage:
  # html_tag('single', { 
  #   'title' => 'Available Views',
  #   'pool' => $datastore->{'displays'},
  #   'id' => 'id', 
  #   'display' => 'label',
  # } )->interpret;

### General Reorderable-List Interface
  # Pass in the starting pool of items and allow the user to reorder them.
  # Additional arguments specify the DRefs to use to generate an unique id and 
  # a readable label for each item.

### HTML Implementation Notes
  # - We track the current order in an set of instance.n=id arguments.
  # - On each submission, we collect the values from the previous submission
  # then apply the ordering.

### Init and Retrieve Values
  # $picker->init;
  # $picker->reorder( @id_values );
  # $picker->reorderbyvalue( @display_strings );

### HTML Generation
  # $text = $picker->interpret()
  # $htmltags = $htmlmacro->expand()
  # $picker->build_select
  # $picker->build_reorder_buttons
  # $picker->build_hidden

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-05-20 Refactored.
  # 1997-11-26 Added primitive ddlc, rudimentary javascript methods.
  # 1997-11-25 Created sldd. -Simon

package Script::ListWidgets::Reorderable;

use Script::HTML::Tag;
@ISA = qw( Script::HTML::Tag );

sub subclass_name { 'single' };
Script::ListWidgets::Reorderable->register_subclass_name;

use Script::HTML::Forms;
use Script::HTML::Tables;
use Script::HTML::Escape;
use Script::HTML::Styles;

use Err::Debug;
use Data::DRef;
# Requres new Collection library.
use Data::Collection qw( uniqueindexby valuesof matching_keys intersperse );

use vars qw( @MoveCommands %MoveCommands );
@MoveCommands = ( 'first', 'prev', 'next', 'last' );
%MoveCommands = ( 'first' => ' First ', 'prev' => '  Up  ', 
		  'next'  => 'Down',    'last' => ' Last ' );

# $html_select_name = $picker->hidden_name;
  # Used to track the ordered values in HTML hidden arguments
sub hidden_name {
  my $picker = shift;
  'instance' .
  	( $picker->{'args'}{'prefix'} ? "\.$picker->{'args'}{'prefix'}" : '');
}

# $html_select_name = $picker->picker_name;
  # Name for the HTML select control
sub picker_name {
  my $picker = shift;
  'picker' .
  	( $picker->{'args'}{'prefix'} ? "\.$picker->{'args'}{'prefix'}" : '');
}

### Init and Retrieve Values

# $picker->init;
   # Fetch the arguments from the previous incarnation and reorder the values.
sub init {
  my $picker = shift;
  my $init_source = $picker->{'init_from_args'} || getData('request.args');
  $picker->take_values_from_request_args( $init_source );
}

# $picker->take_values_from_request_args( $request_args_hash );
sub take_values_from_request_args {
  my ($picker, $req_args) = @_;
  
  # If we've got an ordered list of ID's, reorder our values based on them.
  my $ordered_ids = getDRef($req_args, $picker->hidden_name);
  if ($ordered_ids) {
    $picker->select_by_keys($picker->{'args'}{'id'}, valuesof($ordered_ids));
  } else {
    $picker->{'values'} = [ @{ $picker->{'args'}{'pool'} } ];
  }
  
  # These are the items in the list that were selected before.
  $picker->set_picked( getDRef($req_args, $picker->picker_name) );
  
  # If one of our submit buttons was pressed, identify the relevant command
  my $command_arg = getDRef($req_args, 'command');
  
  $picker->check_for_reorder_button($command_arg);
}

# $picker->set_picked( $args );
sub set_picked {
  my ($picker, $picker_args) = @_;     
  $picker_args = [] unless ( defined $picker_args );
  $picker->{'picked'} = [valuesof($picker_args)];
}

# $picker->select_by_keys( $dref, @values );
sub select_by_keys {
  my ($picker, $dref, @values) = @_;     
  debug 'list-widget', 'Selecting by', $dref, 'for values', @values;
  my $id_index = uniqueindexby($picker->{'args'}{'pool'}, $dref);
  $picker->{'values'} = 
		    [ grep { defined $_ } map { $id_index->{ $_ } } @values ];
  debug 'list-widget', "Matching values are", $picker->{'values'};
}

# $picker->append_unselected;
  # Ensure that the picker has all items selected, by appending any unselected
  # items to the end of the values list. Useful if you want to ensure that
  # the items are reordered, but not omitted.
sub append_unselected {
  my $picker = shift;
  push @{$picker->{'values'}}, $picker->unselected_items;
}

# $picker->check_for_reorder_button( $command );
  # Reorders the widget's values based on the command and selections
sub check_for_reorder_button {
  my ($picker, $command_arg) = @_;     
  
  debug 'list-widget', 'Handling move', $command_arg, 'for ids', $picker->{'picked'};
  
  return unless ( $command_arg and scalar @{ $picker->{'picked'} } );
  
  my $command = matching_keys(\%MoveCommands, undef, $command_arg)
    or return;
    
  # Get a list of all the ordinal positions of the selected items
  my @picked_keys;
  my $index;
  foreach $index ( 0 .. $#{$picker->{'values'}} ) {
    my $item = $picker->{'values'}->[ $index ] || die "ack! $index";
    my $id = getDRef($item, $picker->{'args'}{'id'});
    push @picked_keys, $index if ( grep { $_ eq $id } @{$picker->{'picked'}} );
  }
  # die 'count mismatch' unless (scalar @{$picker->{'picked'}} == scalar @picked_keys);
  
  debug 'list-widget', 'Move operation:', $command, 'for lines', @picked_keys;
  
  # Pull the items out of the list.
  my @items;
  foreach $index ( reverse @picked_keys ) {
    unshift @items, splice @{$picker->{'values'}}, $index, 1;
  }
  
  # Determine based on the selected command where we'll re-insert them
  my $target_index;
  if ( $command eq 'first' ) {
    $target_index = 0;
  } elsif ( $command eq 'prev' ) {
    my $first_key = $picked_keys[0];
    $target_index = $first_key ? $first_key - 1 : 0;
  } elsif ( $command eq 'next' ) {
    my $last_key = $picked_keys[$#picked_keys];
    $target_index = $last_key + 1 - $#picked_keys;
  } elsif ( $command eq 'last' ) {
    $target_index = $#{$picker->{'values'}} + 1;
  } else {
    die "unrecognized command";
  }
  splice @{$picker->{'values'}}, $target_index, 0, @items;
  
  debug 'list-widget', "After moving, values are ", $picker->{'values'};
}

# @ids = $picker->ordered_ids;
sub ordered_ids {
  my $picker = shift;
  map { getDRef($_, $picker->{'args'}{'id'}) } @{$picker->{'values'}}
}

# @items = $picker->unselected_items;
sub unselected_items {
  my $picker = shift;
  my @actives = $picker->ordered_ids;
  my %picked = map { $_, 1 } @actives;
  grep { ! $picked{ getDRef($_, $picker->{'args'}{'id'}) } } 
						  @{$picker->{'args'}{'pool'}};
}

### HTML Generation

# $text = $picker->interpret()
sub interpret {
  my $picker = shift;
  $picker->expand->interpret;
}

# $htmltags = $htmlmacro->expand()
sub expand {
  my $picker = shift;
  
  Script::Sequence->new( 
    $picker->build_hidden(),
    table('', row({}, (
      cell({'valign' => 'top'},
	stylize('label', $picker->{'args'}{'title'}), 
	'<br>',
	$picker->build_select()
      ),
      cell({ 'align' => 'center', 'valign' => 'middle'}, 
	$picker->build_reorder_buttons()
      )
    ))),
  );
}

# $picker->build_hidden
sub build_hidden {
  my $picker = shift;
  
  my $hiddenname = $picker->hidden_name;
  my @hidden;
  
  foreach $i (0 .. $#{$picker->{'values'}}) {
    push @hidden, html_tag('input', { 
      'type' => 'hidden', 
      'name' => "$hiddenname.$i", 
      'value' => getDRef($picker->{'values'}[$i], $picker->{'args'}{'id'})
    });
  }
  return @hidden; 
}			    

# $picker->build_select
sub build_select {
  my $picker = shift;
  
  my ($select_value) = @{$picker->{'picked'}};
  
  html_tag('select', { 'multiple'=>undef,
      'name' => $picker->picker_name, 'size' => 8, 'current' => $select_value 
    }, 
    $picker->build_options($picker->{'values'})
  );
}

# @html_tags = $picker->build_options($values);
sub build_options {
  my ($picker, $values) = @_;
  
  map {
    html_tag('option', {
      'value' => getDRef($_, $picker->{'args'}{'id'}),
      'label' => getDRef($_, $picker->{'args'}{'display'}), 
    } ); 
  } @$values;
}

# $picker->build_reorder_buttons
sub build_reorder_buttons {
  intersperse '<br>', map {
    html_tag('input', {
      'type' => 'submit', 'name' => 'command', 'value' => $MoveCommands{ $_ }
    })
  } @MoveCommands;
}

1;