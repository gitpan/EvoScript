### TOPDOWN "TREE" ITERATOR
  # $grid = $iter->add_cell_content_to_grid($grid, $contents);
  # $iter->add_interchild_spacing( $grid );
  # $iter->join_child_and_pad( $child_grid, $spacer );
  # $iter->add_child_to_grid( $grid, $padded_child_grid );
  # $padding_grid = $iter->spacer_for_child_grid( $child_grid );
  # $padding_grid = $iter->spacer_for_first_child_grid( $child_grid );
  # $padding_grid = $iter->spacer_for_last_child_grid( $child_grid );
  # $padding_grid = $iter->spacer_for_only_child_grid( $child_grid );

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 1998-06-11  Added valign=top, align=center to content cells.
  # 1998-03-29  Now uses Script::HTML::Tables; fixed add_cell_content_to_grid.  -Piglet
  # 19970924 IntraNetics97 Version 1.00.000
  # 19970914 Fixed last/only child padding, was adding multiple blanks, now 1
  # 19970701 Moved here from base iterator pm. -Simon

package Script::Outline::TopDown;
use Script::Outline::GridGenerator;
@ISA = qw[ Script::Outline::GridGenerator];

use Script::HTML::Tables;

# $grid = $iter->add_cell_content_to_grid($grid, $contents);
sub add_cell_content_to_grid {
  my ($iter, $grid, $content) = @_;
    
  my %bgcolor;
  %bgcolor = ('bgcolor'=>Script::HTML::Colors::color_by_name($iter->{'cellbackground'}))
					  if ($iter->{'cellbackground'});
  
  my @cells = cell({ 'width' => 120, 'valign' => 'top', 'align' => 'center', %bgcolor }, $content);
  
  my $leftovers = $grid->colspan - 1;
  push @cells, cell( { 'colspan' => $leftovers }, '') if $leftovers > 0;
  $grid->add_table_to_top( table('', row('', @cells )) );
  
  return;
}

# $iter->add_interchild_spacing( $grid );
sub add_interchild_spacing {
  my ($iter, $grid) = @_;
  $grid->add_table_to_right(
    table('', row('', cell( { 'width' => 20 }, 
    '<img src=' . $WebApp::Handler::SiteHandler::Site->asset_url('orgchart', 'sm.rl.gif') .'>', 
    )))
  );
}

# $iter->join_child_and_pad( $child_grid, $spacer );
sub join_child_and_pad {
  my ($iter, $child_grid, $spacer) = @_;
  $spacer->add_table_to_bottom( $child_grid );
  return $spacer;
}

# $iter->add_child_to_grid( $grid, $padded_child_grid );
sub add_child_to_grid {
  my ($iter, $grid, $child_grid) = @_;
  $grid->add_table_to_right( $iter->padded_child( $child_grid ) );
}

# $padding_grid = $iter->spacer_for_child_grid( $child_grid );
sub spacer_for_child_grid {
  my ($iter, $child_grid) = @_;
  my $spacer = table('', '');
  my $site = $WebApp::Handler::SiteHandler::Site;
  
  $spacer->add( row('', 
    cell ( { 'width' => 20 }, 
      '<img src=' . $site->asset_url('orgchart', 'rld.gif') .'>' ) 
  ));
  
  foreach $i ( 2 .. $child_grid->colspan ) {
    if ( $i % 2 ) {
      $spacer->elements->[0]->add( 
	cell ( { 'width' => 120 }, 
	  '<img src=' . $site->asset_url('orgchart', 'rl.gif') . '>' ) 
      );
    } else {
      $spacer->elements->[0]->add( 
	cell ( { 'width' => 20 }, 
	  '<img src=' . $site->asset_url('orgchart', 'sm.rl.gif') . '>' ) 
      );
    }
  }
  
  return $spacer;
}

# $padding_grid = $iter->spacer_for_first_child_grid( $child_grid );
sub spacer_for_first_child_grid {
  my ($iter, $child_grid) = @_;
  my $spacer = table('', '');
  my $site = $WebApp::Handler::SiteHandler::Site;
  
  $spacer->add( row('', 
    cell ( { 'width' => 120 }, 
      '<img src=' . $site->asset_url('orgchart', 'urd.gif') . '>' )
  ));
  
  foreach $i ( 2 .. $child_grid->colspan ) {
    if ( $i % 2 ) {
      $spacer->elements->[0]->add( 
	cell ( { 'width' => 120 }, 
	  '<img src=' . $site->asset_url('orgchart', 'rl.gif') . '>' ) 
      );
    } else {
      $spacer->elements->[0]->add( 
	cell ( { 'width' => 20 }, 
	  '<img src=' . $site->asset_url('orgchart', 'sm.rl.gif') . '>' ) 
      );
    }
  }
  
  return $spacer;
}

# $padding_grid = $iter->spacer_for_last_child_grid( $child_grid );
sub spacer_for_last_child_grid {
  my ($iter, $child_grid) = @_;
  my $spacer = table('', '');
  
  $spacer->add( row('', 
    cell ( { 'width' => 20 }, 
      '<img src=' . $WebApp::Handler::SiteHandler::Site->asset_url('orgchart', 'ld.gif') . '>' )
  ));
    
  return $spacer;
}

# $padding_grid = $iter->spacer_for_only_child_grid( $child_grid );
sub spacer_for_only_child_grid {
  my ($iter, $child_grid) = @_;
  my $spacer = table('', '');
  
  $spacer->add( row('', 
    cell ( { 'width' => 20 }, 
      '<img src=' . $WebApp::Handler::SiteHandler::Site->asset_url('orgchart', 'ud.gif') . '>' )
  ));
  
  return $spacer;
}

### Subclass: center items over children

package Script::Outline::centeredtree;
@ISA = qw[ Script::Outline::TopDown ];

use integer;

# $padding_grid = $iter->spacer_for_only_child_grid( $child_grid );
sub spacer_for_only_child_grid {
  my ($iter, $child_grid) = @_;
  my $spacer = table('', '');
  my $site = $WebApp::Handler::SiteHandler::Site;
  
  my $childcolspan = $child_grid->colspan;
  
  my $intcenter = $childcolspan / 2;
  
  foreach $i ( 1 .. $intcenter ) {
    $spacer->elements->[0]->add( 
      cell ( { 'width' => 20 }, 
	'<img src=' . $site->asset_url('orgchart', 'sm.n.gif') . '>' ) 
    );
  }
  
  $spacer->add( row('', 
    cell ( { 'width' => 20 }, 
      '<img src=' . $site->asset_url('orgchart', 'ud.gif') . '>' )
  ));
  
  foreach $i ( $intcenter + 1 .. $childcolspan ) {
    $spacer->elements->[0]->add( 
      cell ( { 'width' => 20 }, 
	'<img src=' . $site->asset_url('orgchart', 'sm.n.gif') . '>' ) 
    );
  }
  
  return $spacer;
}

1;