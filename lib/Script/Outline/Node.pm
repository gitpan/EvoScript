### Script::Outline::Node.pm
  # An outline node represents a single record strung into a tree.
  #   (node object has a reference to a record, and a list of child nodes)
  #
  # $node = Script::Outline::Node->new($record);
  # $record = $node->record();
  # $node->add_child(@nodes);
  # $count = $node->child_count();
  # $count = $node->leaf_count();

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 19970924 IntraNetics97 Version 1.00.000
  # 19970530 Split into outline::*. 
  # 19970501 Built. -Simon

package Script::Outline::Node;

# $node = Script::Outline::Node->new($record);
sub new {
  my ($package, $record) = @_;
  my $node = { 'record' => $record, 'subs' => [] };
  bless $node, $package;
}

# %%$nodes = new_nodes_by_id($records, $id_key);
  # Makes a new, disconnected outline node object for each record. Returns a 
  # hash of nodes by record->{id_key}.
  
sub new_nodes_by_id {
  my ($package, $records, $id_key) = @_;
  my $nodes = {};
  foreach $record ( valuesof($records) ) {
    $nodes->{ $record->{ $id_key } } = $package->new($record);
  }
  return $nodes;
}

# $record = $node->record();
sub record {
  my ($node) = @_;
  return $node->{'record'};    
}

# @$nodes = $node->children();
sub children {
  my ($node) = @_;
  return ( $node->{'subs'} || [] );
}

# $node->add_child(@nodes);
sub add_child {
  my ($node, @children) = @_;
  
  foreach $child (@children) {
    # make sure that the same node isn't added if it's already there.
    push @{$node->{'subs'}}, $child
			  unless ( grep { $_ eq $child } @{$node->{'subs'}} );
  }
  
  # invalidate cached data (even if no unique items were added -- just in case)
  delete $node->{'cache'}; 
}

# $count = $node->child_count();
sub child_count {
  my ($node) = @_;
  return scalar @{ $node->children };
}

# $count = $node->leaf_count();
  # Caching wrapper for count_leaves();
sub leaf_count {
  my ($node) = @_;
  
  return ( $node->{'cache'}{'leaf_count'} ||= $node->count_leaves );
}

# $count = $node->count_leaves();
sub count_leaves {
  my ($node) = @_;
  
  my $children = $node->children;
  return 1 unless (scalar @$children);
  
  my $count = 0;
  foreach $child ( @$children ) {
    $count += $child->leaf_count;
  }
  return $count;
}

1;