### Script::Tags::Grid iterates over a collection, building table cells

### Interface
  # [grid values=dref (direction=across|down border,width=n)] ... [/grid]
  # $html_table = $gridtag->interpret();

### Caveats and Things Left Undone
  # - Use Script::HTML::Tables
  # - Subclass Script::Tags::ForEach?

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-05-19 Support record-based sorting of grids. -Del
  # 1998-04-17 Updated to use new Data::Sorting interface.
  # 1998-03-11 Inline POD added.
  # 1997-11-24 Updated to four-oh. -Simon
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-07 Split grid and table -Jeremy
  # 1997-03-23 Added switch for grid order (across or down).
  # 1997-03-22 Turned grid into a container.
  # 1997-03-22 Improved exception handling.
  # 1997-03-19 Created grid  -Piglet

package Script::Tags::Grid;

$VERSION = 4.00_1998_03_11;

use Script::Container;
@ISA = qw( Script::Container );

use Data::DRef;
use Data::Sorting qw( sort_in_place );
use Script::HTML::Styles;

# [grid values=dref (direction=across|down border,width=n)] ... [/grid]
Script::Tags::Grid->register_subclass_name();
sub subclass_name { 'grid' }

%ArgumentDefinitions = (
  'values' => {'dref'=>'optional', 'required'=>'list'},
  
  'sortorder' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
  
  'numcols' => {'dref'=>'optional', 'required'=>'number'},
  'direction' => {'dref'=>'optional', 'default'=>'down', 
					    'required'=>'oneof across down'},
  'border' => {'dref'=>'optional', 'default' => 0, 
					    'required'=>'number'},
  'width' => {'dref'=>'optional', 'default' => 0, 
					    'required'=>'string_or_nothing'},
  'style' => {'dref'=>'optional', 'default'=>'normal', 
					    'required'=>'string_or_nothing'},
);

# $html_table = $gridtag->interpret();
sub interpret {
  my $gridtag = shift;
  my $args = $gridtag->get_args;
  
  my $values = $args->{'values'};
  
  map { $_ = "readable." . $_ } @{$args->{'sortorder'}}
      if UNIVERSAL::isa($values->[0], 'Record');
  
  # Make a copy of the list so we don't alter the sort order of the original
  sort_in_place( $values=[@$values], @{$args->{'sortorder'}})
						    if ($args->{'sortorder'});
  
  my $numberofcols = $args->{'numcols'};
  my $numrows = int(.99 + scalar(@$values) / $numberofcols);  # -filled- rows
  my $width = $args->{'width'};
  my $cellwidth = $width ? int ($width / $numberofcols) : 0;
  
  my $html = "<table width=$width cellspacing=0 cellpadding=0 " . 
	"border=$args->{'border'}>\n";
  
  $gridtag->{'outer'} = $Root->{'loop'};
  local $Data::DRef::Root->{'loop'} = $gridtag;
  
  my($row, $col);
  foreach $row (0 .. ($numrows - 1)) {
    $gridtag->{'row'} = $row;
    $html .= '<tr>';
    for $col (0 .. ($numberofcols - 1)) {
      $gridtag->{'col'} = $col;
      $gridtag->{'n'} = ($args->{'direction'} eq 'across') 
		    ? $gridtag->{'col'} + ($gridtag->{'row'} * $numberofcols) 
		    : $gridtag->{'row'} + ($gridtag->{'col'} * $numrows);
      next if ($gridtag->{'n'} > $#{$values});
      $html .= "<td valign=top align=left" . 
      				($cellwidth ? "width=$cellwidth" : '' ) . ">";
      $gridtag->{'value'} = $values->[$gridtag->{'n'}];
      my $value = $gridtag->interpret_contents();
      $value = stylize($args->{'style'}, $value) if ($args->{'style'});  
      $html .= $value;
      $html .= '</td>' . "\n";
    }
    $html .= '</tr>' . "\n";
  }
    
  $html .= "</table>\n";
  
  return $html;
}

1;

__END__

=head1 Grid

Iterates over a series of items, evaluating its contents for each one, and placing each one in a cell of an HTML table.

    [grid values="One Two Three" numcols=2 direction=across]
      [print value=#loop.value]
    [/grid]

During each iteration, the value for this pass, along with the row and col position, are exposed in the DRefs #loop.value, #loop.row, and #loop.col. Within a nested loop you can use the loop's 'outer' attribute to refer to the enclosing loop. 

=over 4

=item values

A list of items to iterate over. Use '#' for DRefs. Required argument. 

=item numcols

The number of columns to use in the table. Use '#' for DRefs. Required argument. 

=item direction

The order in which to fill the table, either across or down. Defaults to down. Use '#' for DRefs. 

=item sortorder

Optional. A list of keys to sort the values by. Use '#' for DRefs. 

=item border

Optional. The border size for the table. Defaults to 0. Use '#' for DRefs. 

=item width

Optional. The overall width in pixels for the table. If provided, this amount is divided by the numcols and used as the width for each cell. Use '#' for DRefs. 

=item style

Optional. The font style to apply to the contents of each cell. Defaults to normal. Use '#' for DRefs. 

=back

=cut
