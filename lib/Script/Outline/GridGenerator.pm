### GRID GENERATING ITERATOR
  # $grid = $iter->build_grid;
  # $child_grid = $iter->grid_for_children();
  # $padded_child_grid = $iter->padded_child( $child_grid );

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 1998-03-03 Debuging. -Simon
  # 1998-01-06 Revised. -Piglet
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-07-01 Moved GridGenerator iterators into separate file -Simon

package Script::Outline::GridGenerator;
use Script::Outline::Iterator;
@ISA = qw[ Script::Outline::Iterator];

use Script::HTML::Tables;

# $grid = $iter->build_grid;
sub build_grid {
  my ($iter) = @_;
  return unless $iter->currentnode;
  
  local $iter->{'current'} = $iter->currentnode->record;
  my $contents = ($iter->{'current'} ? $iter->evaluate_contents : undef);
  my $grid = $iter->grid_for_children();
  # warn "got $grid from children \n";

  $iter->add_cell_content_to_grid($grid, $contents) if ( defined $contents );
  return $grid;
}

# $child_grid = $iter->grid_for_children();
sub grid_for_children {
  my $iter = shift @_;
  
  my $grid = table('', '');
  
  $iter->{'depth'} ++;
  if ( $iter->{'depth'} <= $iter->{'max'} ) {  
    local $iter->{'peer_n'} = 0;
    local $iter->{'peer_count'} = $iter->currentnode->child_count;
    
    foreach $node ( @{ $iter->currentnode->children } ) {
      $iter->add_interchild_spacing($grid) if ( $iter->{'peer_n'} );
      $iter->visit_node($node);
      $iter->add_child_to_grid( $grid, $iter->build_grid );
    }
    
  } else {
    # draw something to show that there are hidden children?
  }
  $iter->{'depth'} --;
  return $grid;
}

# $padded_child_grid = $iter->padded_child( $child_grid );
sub padded_child {
  my ($iter, $child_grid) = @_;
  my $spacer;
  if ( $iter->{'peer_count'} == 1 ) {
    $spacer = $iter->spacer_for_only_child_grid($child_grid);
  } elsif ( $iter->{'peer_n'} == 1 ) {
    $spacer = $iter->spacer_for_first_child_grid($child_grid);
  } elsif ( $iter->{'peer_n'} ==  $iter->{'peer_count'} ) {
    $spacer = $iter->spacer_for_last_child_grid($child_grid);
  } else {
    $spacer = $iter->spacer_for_child_grid($child_grid);
  }
  return $iter->join_child_and_pad($child_grid, $spacer);
}
