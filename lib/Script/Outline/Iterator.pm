### Script::Outline::Iterator.pm
  # Iterators that walk an outline and return html.

### FACTORY METHODS
  # $iter = Script::Outline::Iterator->new_by_type($type, $topnd, $draw, %opts)
  # %$subclasses = Script::Outline::Iterator->class_types();

### ITERATOR BASICS
  # $iter = Script::Outline::Iterator->new(%@$outline, &$closure, %options);
  # $contents = $iter->evaluate_contents
  # $node = $iter->currentnode(); or pass ($node) to make that one current
  # $iter->visit_node($node);

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 1998-03-03 Debuging. -Simon
  # 1998-01-06 Revised. -Piglet
  # 19970924 IntraNetics97 Version 1.00.000
  # 19970701 Moved tree and vertical outline iterators into separate files
  # 19970621 Significant refactoring of grid-generating iterator classes
  # 19970619 Moved table-handling code to new table::* packages.
  # 19970530 Split into outline::*.
  # 19970501 Built. -Simon

package Script::Outline::Iterator;

### FACTORY METHODS

use Script::Outline::TopDown;
use Script::Outline::Vertical;

# %$subclasses = Script::Outline::Iterator->class_types();
sub class_types {
  return {
    'indented' => 'Script::Outline::Vertical',
    'normal' => 'Script::Outline::Vertical_with_lines',
    'topdown' => 'Script::Outline::TopDown',
  };
}

# $iter = Script::Outline::Iterator->new_by_type($type, $topnode, $draw, %opts)
  # new_by_type is a factory method that instantiates the appropriate subclass
sub new_by_type {
  my ($package, $typename, @args) = @_;
  return $package->class_types->{$typename}->new(@args);
}

### ITERATOR BASICS

# $iter = Script::Outline::Iterator->new(%@$outline, &$closure, %options);
sub new {
  my ($class, $outline, $closure, %options) = @_;
  my $iter = \%options;
  bless $iter, $class;
  $iter->currentnode( $outline );
  $iter->{'drawcontents'} = $closure;
  $iter->{'depth'} = 0;
  $iter->{'max'} ||= 3;
  return $iter;
}

# $contents = $iter->evaluate_contents
sub evaluate_contents {
  my ($iter) = @_;
  return &{ $iter->{'drawcontents'} };
}

# $node = $iter->currentnode(); or pass ($node) to make that one current
sub currentnode {
  my $iter = shift @_;
  
  if ( scalar @_ ) {
    my $node = shift;
    # warn "setting current node to $node \n";
    $iter->{'node'} = $node;
    $iter->{'record'} = ( $node ? $node->record : undef );
  }
  
  return $iter->{'node'};
}

# $iter->visit_node($node);
  # make this node current and increment our visit totals (n, peer_n, etc).
sub visit_node {
  my ($iter, $node) = @_;
  $iter->currentnode($node);
  $iter->{'n'} ++;
  $iter->{'peer_n'} ++;
  return;
}


1;