### Vertical.pm - vertical outline iterator
  # $grid = $iter->add_cell_content_to_grid($grid, $contents);
  # $iter->add_interchild_spacing( $grid );
  # $iter->add_child_to_grid( $grid, $child_grid );
  # $iter->join_child_and_pad( $child_grid, $spacer );
  # $padding_grid = $iter->spacer_for_child_grid( $child_grid );
  # $padding_grid = $iter->spacer_for_first_child_grid( $child_grid );
  # $padding_grid = $iter->spacer_for_last_child_grid( $child_grid );
  # $padding_grid = $iter->spacer_for_only_child_grid( $child_grid );

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 19980410 Changed occurences of hard coded path to the image directory
  #          to use the $WebApp::Handler::SiteHandler::Site->asset_url call.
  # 19970924 IntraNetics97 Version 1.00.000
  # 19970701 Moved here from base iterator pm. -Simon

package Script::Outline::Vertical;
use Script::Outline::GridGenerator;
@ISA = qw[ Script::Outline::GridGenerator];

use Script::HTML::Tables;

# $grid = $iter->add_cell_content_to_grid($grid, $contents);
sub add_cell_content_to_grid {
  my ($iter, $grid, $content) = @_;
  
  my $cell = cell( { 'align' => 'left',
		  'colspan' => ( $iter->{'max'} - $iter->{'depth'} + 1 ) },
		  $content);
  # warn "adding cell with content: $content\n";
  
  $grid->prepend( row('', $cell ) );
  
  return;
}

# $iter->add_interchild_spacing( $grid );
sub add_interchild_spacing {
  my ($iter, $grid) = @_;
}

# $iter->add_child_to_grid( $grid, $child_grid );
sub add_child_to_grid {
  my ($iter, $grid, $child_grid) = @_;
  $grid->add_table_to_bottom( $iter->padded_child( $child_grid ) );
}

# $iter->join_child_and_pad( $child_grid, $spacer );
sub join_child_and_pad {
  my ($iter, $child_grid, $spacer) = @_;
  $spacer->add_table_to_right( $child_grid );
  return $spacer;
}

# $padding_grid = $iter->spacer_for_child_grid( $child_grid );
sub spacer_for_child_grid {
  my ($iter, $child_grid) = @_;
  my $spacer = table('', '');
  
  $spacer->add(row( '', 
    cell( { 'width' => 20 },
      '<img src=' . $WebApp::Handler::SiteHandler::Site->asset_url('outline', 'blank.gif') . '>'
    ))
  );
  
  return $spacer;
}

# $padding_grid = $iter->spacer_for_first_child_grid( $child_grid );
sub spacer_for_first_child_grid {
  my ($iter, $child_grid) = @_;
  return $iter->spacer_for_child_grid( $child_grid );
}

# $padding_grid = $iter->spacer_for_last_child_grid( $child_grid );
sub spacer_for_last_child_grid {
  my ($iter, $child_grid) = @_;
  return $iter->spacer_for_child_grid( $child_grid );
}

# $padding_grid = $iter->spacer_for_only_child_grid( $child_grid );
sub spacer_for_only_child_grid {
  my ($iter, $child_grid) = @_;
  return $iter->spacer_for_child_grid( $child_grid );
}

### Subclass: with lines

package Script::Outline::Vertical_with_lines;
@ISA = qw[ Script::Outline::Vertical];

use Script::HTML::Tables;

# $padding_grid = $iter->spacer_for_child_grid( $child_grid );
sub spacer_for_child_grid {
  my ($iter, $child_grid) = @_;
  my $spacer = table('', '');
  
  $spacer->add(row( '',
    cell( { 'width' => 20 },
      '<img src=' . $WebApp::Handler::SiteHandler::Site->asset_url('outline', 'item.gif') . '>'
    ))
  );
  
  foreach $i ( 2 .. $child_grid->rowspan ) {
    $spacer->add(row( '',
    cell( { 'width' => 20 },
	'<img src=' . $WebApp::Handler::SiteHandler::Site->asset_url('outline', 'skip.gif') . '>'
      ))
    );
  }
  
  return $spacer;
}

# $padding_grid = $iter->spacer_for_first_child_grid( $child_grid );
sub spacer_for_first_child_grid {
  my ($iter, $child_grid) = @_;
  return $iter->spacer_for_child_grid( $child_grid );
}

# $padding_grid = $iter->spacer_for_last_child_grid( $child_grid );
sub spacer_for_last_child_grid {
  my ($iter, $child_grid) = @_;
  my $spacer = table('', '');
  $spacer->add(row( '',
    cell( { 'width' => 20 },
      '<img src=' . $WebApp::Handler::SiteHandler::Site->asset_url('outline', 'last.gif') . '>'
    ))
  );
  return $spacer;
}

# $padding_grid = $iter->spacer_for_only_child_grid( $child_grid );
sub spacer_for_only_child_grid {
  my ($iter, $child_grid) = @_;
  return $iter->spacer_for_last_child_grid( $child_grid );
}

1;