### Script::HTML::Tables provides three tag classes for building HTML tables
  #
  # For your html generation pleasure we have....
  # - tables, a list of rows (and some options)
  # - table rows, a list of cells (and ...?)
  # - table cells, a string (and some options)
  #
  # We often build sub-tables and then merge 'em, but that code's a bit rusty

### Interface
  # $table = table( $args, @rows );
  # $row = row( $args, @cells );
  # $cell = cell( $args, @elements );

### Table: <table> <tr>...</tr> ... </table>
  # $tag = Script::HTML::Table->new( $args, @rows );
  # $table->default_options;
  # $table->new_row( @cells );
  # $sequence->add( $element );
  # $stringvalue = $sequence->interpret_contents();
  # $count = $table->rowspan;
  # $count = $table->colspan;
  # $table->add_table_to_right( $other_table );
  # $table->add_table_to_bottom( $other_table );

### Table Row: <tr> <td>...</td> ... </tr>
  # $sequence->add( $element );
  # $tag = Script::HTML::Row->new( $args, @cells );
  # $row = Script::HTML::Table::Row->new_with_new_cell( @_ );
  # $colspan = $row->colspan;

### Table Cell: <td> ... </td>
  # $tag = Script::HTML::Table::Cell->new( $args, @elements );
  # $colspan = $cell->colspan;
  # $cell->default_options;
  # %$args = $tag->get_args();
  # $html_or_nbsp = $cell->interpret_contents();

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-30 removed version number from Number::Stats import lines - bnair
  # 1998-03-29 Added add_table_to_top method. -Simon
  # 1998-03-19 Replaced cell() with Cell->new in add_table_to_right.  -P
  # 1998-01-25 Table cells now use Script::HTML::Colors for bgcolor mapping -S.
  # 1997-12-09 Changed new cell default alignment to left.  -Piglet
  # 1997-11-07 Fixed some lines that were causing "use of undefined" errors
  # 1997-10-31 Refactored for four-oh. -Simon
  # 1997-09-30 Changes to cell->html(); don't show colspan if it's == 1.
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-21 Minor cleanup.
  # 1997-06-19 Created these classes based on existing HTML manipulation code.

package Script::HTML::Tables;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( table row cell );

use Script::HTML::Tag;

# $table = table( $args, @rows );
sub table ($;@) { return Script::HTML::Table->new( shift, @_ );     }

# $row = row( $args, @cells );
sub row ($;@)   { return Script::HTML::Table::Row->new( shift, @_ );  }

# $cell = cell( $args, @elements );
sub cell ($;@)  { return Script::HTML::Table::Cell->new( shift, @_ );}

### Table: <table> <tr>...</tr> ... </table>

package Script::HTML::Table;
@ISA = qw( Script::HTML::Container );

sub subclass_name { 'table' };
Script::HTML::Table->register_subclass_name;

use Number::Stats qw( maximum );
use Carp;

# $table->default_options;
sub default_options {
  my $table = shift;
  $table->{'args'} = { 'border' => 0, 'cellspacing' => 0, 'cellpadding' => 0 };
}

# $table->new_row( @cells );
sub new_row {
  my $table = shift;
  $table->add( Script::HTML::Table::Row->new( {}, @_ ) );
}

# $ok_flag = $sequence->about_to_add( $element );
sub about_to_add {
  my $sequence = shift;
  my $target = shift;
  
  return if ( UNIVERSAL::isa($target, 'Script::Literal')
  						 and $target->iswhitespace());
  
  # Hmm. Do we want to check that it doesn't return anything that's not a
  # a table row? Or...
  confess "can't add '$target' as contents of a table" 
			unless ( UNIVERSAL::isa($target, 'Script::HTML::Table::Row')
				  or UNIVERSAL::isa($target, 'Script::Element') );
  	
  return 1;
}

# $stringvalue = $sequence->interpret_contents();
sub interpret_contents {
  my $sequence = shift;
  
  my $value = '';
  $value .= "\n";
  foreach $item ( $sequence->elements ) {
   $value .= $item->interpret();
    $value .= "\n";
  }
  return $value;
}

# $count = $table->rowspan;
sub rowspan {
  my $table = shift;
  return $table->elementcount;
}

# $count = $table->colspan;
sub colspan {
  my $table = shift;
  return maximum ( $table->call_on_each('colspan') );
}

# $table->add_table_to_right( $other_table );
sub add_table_to_right {
  my ($table, $other_table) = @_;
  
  my $total_cols = $table->colspan + $other_table->colspan;
  
  my $most_rows = maximum( $table->rowspan, $other_table->rowspan );
  
  my $original_table_colspan = $table->colspan;
  foreach $row_n (0 .. $most_rows -1) {
    # warn "adding table, at row $row_n \n";
    unless ( $row_n < $table->rowspan ) {
      # warn "compensating for shortness of table len " . $table->rowspan . "\n";
      my @spacers;
      push @spacers, Script::HTML::Table::Cell->new({ 'colspan' => $original_table_colspan }, '') if ( $original_table_colspan );
      $table->new_row( @spacers );
      # warn "new row is at " . $table->rowspan . "\n";
    }
    
    if ( $row_n < $other_table->rowspan ){
      # warn "adding row \n";
      $table->elements->[ $row_n ]->append_elements( 
      			$other_table->elements->[ $row_n ]->elements );
    } else   {
      # warn "padding row \n";
      my $spacer = Script::HTML::Table::Cell->new();
      $spacer->{'args'}{'colspan'} = $other_table->colspan; 
      $table->elements->[ $row_n ]->append_elements( $spacer );
    }
  }
  $table->{'cols'} = $total_cols;
}

# $table->add_table_to_top( $other_table );
sub add_table_to_top {
  my ($table, $other_table) = @_;
  
  my ($colspan, $other_colspan) = ( $table->colspan, $other_table->colspan );
  my $most_cols = maximum( $colspan, $other_colspan );
  $table->pad_to_column( $most_cols ) if ( $colspan < $most_cols );
  $other_table->pad_to_column($most_cols) if ( $other_colspan < $most_cols );
  
  $table->prepend_elements( @{$other_table->elements()} );
}

# $table->add_table_to_bottom( $other_table );
sub add_table_to_bottom {
  my ($table, $other_table) = @_;
  
  # warn ((caller(0))[1] . ' line ' . (caller(0))[2]);
  # warn "table $table, other_table $other_table\n";
  
  my ( $colspan, $other_colspan ) = ( $table->colspan, $other_table->colspan );
  
  my $most_cols = maximum( $colspan, $other_colspan );
  
  $table->pad_to_column( $most_cols ) if ( $colspan < $most_cols );
  $other_table->pad_to_column( $most_cols ) if ( $other_colspan < $most_cols );
  $table->append_elements( @{$other_table->elements()} );
}

sub pad_to_column {
  my $table = shift;
  my $width = shift;
  foreach $row ( $table->elements ) {
    my $diff = ($width - $row->colspan) || next;
    $row->append_elements( Script::HTML::Table::Cell->new(
			      { 'colspan' => $diff }, '') );
  }
}

### Table Row: <tr> <td>...</td> ... </tr>

package Script::HTML::Table::Row;
@ISA = qw( Script::HTML::Container );

sub subclass_name { 'tr' };
Script::HTML::Table::Row->register_subclass_name;

use Carp;
use Number::Stats qw( total );

# $ok_flag = $sequence->about_to_add( $element );
sub about_to_add {
  my $sequence = shift;
  my $target = shift;
    
  return if ($target->isa('Script::Literal') and $target->iswhitespace());
  
  croak "can't add '$target' as contents of a table row" 
			unless ( $target->isa('Script::HTML::Table::Cell') 
				  or $target->isa('Script::Element') );
  	
  return 1;
}

# $stringvalue = $sequence->interpret_contents();
sub interpret_contents {
  my $sequence = shift;
  
  my $value = '';
  $value .= "\n";
  foreach $item ( $sequence->elements ) {
    $value .= '  ';
    $value .= $item->interpret();
    $value .= "\n";
  }
  return $value;
}

# $row = Script::HTML::Table::Row->new_with_new_cell( @_ );
sub new_with_new_cell {
  my $package = shift;
  return $package->newrow( {}, Script::HTML::Table::Cell->new( @_ ) );
}

# $colspan = $row->colspan;
sub colspan {
  my $row = shift;
  return total( $row->call_on_each('colspan') );
}

### Table Cell: <td> ... </td>

package Script::HTML::Table::Cell;
@ISA = qw( Script::HTML::Container );

sub subclass_name { 'td' };
Script::HTML::Table::Cell->register_subclass_name;

use Carp;
use Script::HTML::Colors qw( color_by_name );

# $colspan = $cell->colspan;
sub colspan {
  my $cell = shift;
  return $cell->{'args'}{'colspan'} || 1;
}

# $cell->default_options;
sub default_options {
  my $cell = shift;
  $cell->{'args'} = { 'align' => 'left', 'valign' => 'top' };
}

# %$args = $tag->get_args();
sub get_args {
  my $tag = shift;
  
  confess "bad tag $tag" unless ( UNIVERSAL::isa($tag->{'args'}, 'HASH' ) );
  my $args = ref $tag->{'args'} ? { %{$tag->{'args'}} } : {};
  
  delete $args->{'colspan'}
	    if ( exists $args->{'colspan'} and $args->{'colspan'} == 1 );
  delete $args->{'rowspan'}
	    if ( exists $args->{'rowspan'} and $args->{'rowspan'} == 1 );
  
  delete $args->{'bgcolor'} 
	    if ( exists $args->{'bgcolor'} and $args->{'bgcolor'} eq '-none' );
  $args->{'bgcolor'} = color_by_name($args->{'bgcolor'})
						  if ( $args->{'bgcolor'} );
  
  return $args;
}

1;