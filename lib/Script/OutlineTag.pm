### Script::OutlineTag.pm
  # 
  # [outline records=#source key=super-id-key] ... tags ... [/outline]
  # tree::node class (has a reference to a record, and a list of child nodes)
  # tabulation hash (not yet blessed; holds column count and array of row strs)
  # tree::iterator class

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 1998-06-12 Switched to new request.client.browser_id_v interface. -Simon
  # 1998-06-11 Make sure client.browseris.IE3 before adding empty row. -Piglet
  # 1998-05-13 Changed the default depth to 20 for discussions.  
  # 1998-05-13 Restored nbsp to row of non-colspanning cells.
  # 1997-10-27 Changed "it's" to "its" throughout.  -Piglet
  # 1997-09-30 Added an extra row of empty, no-colspan cells to calm IE3.02 
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-05-30 Split in outline::*.
  # 1997-05-01 Built. -Simon

package Script::OutlineTag;

use Script::Container;
@ISA = qw( Script::Container );

use Script::Outline::Node;
use Script::Outline::Iterator;
use Data::DRef;

### TAG INTERFACE

Script::OutlineTag->register_subclass_name();
sub subclass_name { 'outline' }

%ArgumentDefinitions = (
  'records' => { 'dref'=>'optional', required=>'list' },
  'key' => { 'dref'=>'optional', 'required'=>'non_empty_string' },
  'focus' => { 'dref'=>'optional', 'required'=>'string_or_nothing' },
  'depth' => { 'dref'=>'optional', 'default' => 20, 'required'=>'number'},
  'cellbackground' => { 'dref'=>'optional', 'required'=>'string_or_nothing'},
  'id_key' => { 'dref'=>'optional', 'default'=>'id', 
					  'required'=>'non_empty_string' },
  'style' => { 'dref'=>'optional', 'default'=>'normal', 'required'=>'oneof '.
		    join(' ', keys %{Script::Outline::Iterator->class_types})},
);

# [outline_tag style=display-type records=#source key=super-id-key]
  # Should distinguish between things that are explicitly at the top and
  # items that are just free floating.
  
sub interpret {
  my $tag = shift;
  
  # get tag arguments and turn the content tags into a perl closure
  my ($args) = $tag->get_args; 
  # warn "My tag is " . Text::PropertyList::astext($tag);
  my $draw_contents = sub { $tag->interpret_contents() };
    
  # Build a tree of outline nodes.
  # Do a little extra work to make 'em sorted.
    
  my $nodesbyid = {};
  my $sequence = [];
  foreach $record ( @{$args->{'records'}} ) {
    my $new_node = Script::Outline::Node->new($record);
    $nodesbyid->{ $record->{ $args->{'id_key'} } } = $new_node;
    push @$sequence, $new_node;
  }
  
  my $top_node = Script::Outline::Node->new();
  
  foreach $node ( @$sequence ) {
    my $parent_id = $node->record->{ $args->{'key'} };
    my $parent = ( $parent_id ) ? $nodesbyid->{ $parent_id } : $top_node;
    
    unless ( $parent ) {
      warn "Record ID $node->{'record'}{'id'} is floating to top of outline because its parent (ID $parent_id) could not be found.\n";   #!# changed it's to its
      $parent ||= $top_node;
    }
    $parent->add_child( $node );
  }
  
  $top_node = $nodesbyid->{ $args->{'focus'} } 
  		if ( $args->{'focus'} and $nodesbyid->{ $args->{'focus'} } );
  
  # make an outline iterator by the named type
  my $iter = Script::Outline::Iterator->new_by_type(
		$args->{'style'}, $top_node,  $draw_contents,
		'max' => $args->{'depth'}, 
		'cellbackground' => $args->{'cellbackground'},
	    );
  
  # expose the iterator object for use by contained scripts.
  local $Root->{'-outline'} = $iter;  
  
  # warn "My iter is " . Text::PropertyList::astext($iter);
  # have the iterator walk across the outline and generate an html table.
  # return $iter->build_grid->html;
  my $grid = $iter->build_grid;
  # warn "My grid is " . Text::PropertyList::astext($grid);
  my $html;
  # $grid->{'args'}{'border'} = 1;   # useful for debugging layout problems
  if ($grid and $grid->rowspan() > 0) {
    # Add an additional row of empty, non-aligned, non-colspanning cells.
    # IE3.02 gets very confused otherwise. 
    $grid->add(Script::HTML::Tables::row('',
      map { Script::HTML::Tables::cell('', '&nbsp;') } ( 1 .. $grid->colspan ) 
    )) if ( getData('request.client.browser_id_v') eq 'IE3' );
    $html = $grid->interpret();
  } else {
    $html = Script::HTML::Styles::stylize('name=normal', 'No items in list.');
  }
  return $html;
}



1;