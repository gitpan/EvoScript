### Script::OutlineOrder.pm
  # 
  # [outline records=#source key=super-id-key] ... tags ... [/outline]
  # tree::node class (has a reference to a record, and a list of child nodes)
  # tabulation hash (not yet blessed; holds column count and array of row strs)
  # tree::iterator class

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 19971027 Changed it's to its throughout.  -Piglet
  # 19970930 Added an extra row of empty, non-colspanning cells to calm IE3.02. 
  # 19970924 IntraNetics97 Version 1.00.000
  # 19970530 Split in outline::*.
  # 19970501 Built. -Simon

package Script::OutlineOrder;

use Script::Tag;
@ISA = qw( Script::Tag );

use Script::Outline::Node;
use Script::Outline::Iterator;

### TAG INTERFACE

Script::OutlineOrder->register_subclass_name();
sub subclass_name { 'outline_order' }

%ArgumentDefinitions = (
  'records' => { 'dref'=>'optional', required=>'list' },
  'key' => { 'dref'=>'optional', 'required'=>'non_empty_string' },
  'id_key' => { 'dref'=>'optional', 'default'=>'id', 'required'=>'non_empty_string' },
);

# [outline_order style=display-type records=#source key=super-id-key]
  # Should distinguish between things that are explicitly at the top and
  # items that are just free floating.
  
sub interpret {
  my $tag = shift;
  my $args = $tag->get_args; 
    
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
  
  my $order = build_order ( $top_node, $args->{'id_key'} );
  
  my $order_by_id = {};
  foreach $n (1 .. scalar @$order) {
    $order_by_id->{ $order->[$n] } = $n;
  }
  
  sort_numbers_bycalculation($args->{'records'}, (
    sub { $order_by_id->{ $_[0]->{ $args->{'id_key'} } } }
  ));
}


sub build_order {
  my $node = shift;
  my $id_key = shift;
  my $order = shift || [];
  
  my $record = $node->record();
  my $record_id = $record->{ $id_key } if (ref $record);
  push @$order, $record_id if (defined $record_id);
  
  foreach $child ( @{$node->children} ) {
    build_order( $child, $id_key, $order);
  }
  return $order;
}

1;