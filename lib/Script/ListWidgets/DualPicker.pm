package Script::ListWidgets::DualPicker;

### <dual title=x values=list current=list>

use Script::HTML::Tag;
@ISA = qw( Script::HTML::Tag );

use Script::ListWidgets::Reorderable;
@ISA = qw( Script::ListWidgets::Reorderable );

sub subclass_name { 'dual' };
Script::ListWidgets::DualPicker->register_subclass_name;

use Script::HTML::Tables;
use Script::HTML::Escape;
use Script::HTML::Styles;

use Data::DRef;
use Err::Debug;
use Data::Collection qw( uniqueindexby keysof valuesof matching_keys intersperse );

use vars qw( @AddDropCommands %AddDropCommands );
@AddDropCommands = ( 'add', 'drop' );
%AddDropCommands = ( 'add' => ' Add ->', 'drop' => '<- Drop' );

# $html_select_name = $picker->pool_name;
sub pool_name {
  my $picker = shift;
  'pool'.($picker->{'args'}{'prefix'} ? ".$picker->{'args'}{'prefix'}" : '');
}

### Init and Retrieve Values

# $picker->take_values_from_request_args( $request_args_hash );
sub take_values_from_request_args {
  my ($picker, $req_args) = @_;
  
  # If we've got an ordered list of ID's, reorder our values based on them.
  my $hidden_ids = getDRef($req_args, $picker->hidden_name);
  if ($hidden_ids) {
    $picker->select_by_keys($picker->{'args'}{'id'}, valuesof($hidden_ids));
  } else {
    $picker->{'values'} = [ @{ $picker->{'args'}{'pool'} } ];
  }
  
  # These are the items in the list that were selected before.
  $picker->set_picked( getDRef($req_args, $picker->picker_name) );
  $picker->set_pool_picked( getDRef($req_args, $picker->pool_name) );
  
  # If one of our submit buttons was pressed, identify the relevant command
  my $command_arg = getDRef($req_args, 'command');
  
  $picker->check_for_reorder_button( $command_arg );
  $picker->check_for_add_drop_button( $command_arg );
}

# $picker->set_pool_picked( $args );
sub set_pool_picked {
  my ($picker, $picker_args) = @_;     
  $picker_args = [] unless ( defined $picker_args );
  $picker->{'pool_picked'} = [valuesof($picker_args)];
}

# $picker->check_for_add_drop_button( $command );
sub check_for_add_drop_button {
  my ($picker, $command_arg) = @_;     
  
  debug 'list-widget', 'Handling add-drop', $command_arg;

  return unless ( $command_arg );
  
  my $add_drop = matching_keys(\%AddDropCommands, undef, $command_arg)
    or return;
  
  if ($add_drop eq 'drop') {
    @{$picker->{'values'}} = grep {
      my $id = getDRef($_, $picker->{'args'}{'id'});
      ! grep { $id eq $_ } @{$picker->{'picked'}};
    } @{$picker->{'values'}};
  } elsif ($add_drop eq 'add') {
    push @{$picker->{'values'}}, grep {
      my $id = getDRef($_, $picker->{'args'}{'id'});
      grep { $id eq $_ } @{$picker->{'pool_picked'}};
    } @{$picker->{'args'}{'pool'}};
  }
}

### HTML Generation

# $htmltags = $picker->expand()
sub expand {
  my $picker = shift;
  
  return Script::Sequence->new(
    $picker->build_hidden(),
    table('', row({}, 
      cell({'valign' => 'top'}, 
	stylize('label', $picker->{'args'}{'title'}),
	'<br>', $picker->build_pool_select()
      ),
      cell({ 'align' => 'center', 'valign' => 'middle'},
	$picker->build_add_drop_buttons()
      ),
      cell({'valign' => 'top'}, 
	stylize('label', $picker->{'args'}{'subtitle'}),
	'<br>', 
	$picker->build_select()
      ),
      cell({ 'align' => 'center', 'valign' => 'middle'}, 
	$picker->build_reorder_buttons()
      )
    )), 
  );
}

# $htmltags = $picker->build_pool_select()
sub build_pool_select {
  my $picker = shift;
  
  my ($select_value) = @{$picker->{'pool_picked'}};
 
  html_tag('select', { 'multiple'=>undef,
      'name' => $picker->pool_name, 'size' => 8, 'current' => $select_value 
    },
    $picker->build_options([$picker->unselected_items])
  );
}

# $picker->build_add_drop_buttons
sub build_add_drop_buttons {
  intersperse '<br>', map {
    html_tag('input', {
      'type'=>'submit', 'name'=>'command', 'value'=>$AddDropCommands{ $_ }
    })
  } @AddDropCommands;
}

1;
