### Err::Debug provides keyword-based log filtering and output escaping

### Interface
  # add_logging( @dbg_label );
  # drop_logging( @dbg_label );
  # debug( $label, @values );

### Change History
  # 1998-03-04 Added 'always'.
  # 1998-01-29 Added $ShowLabels variable and associated output. Nicer, eh?
  # 1998-01-29 s/foreach(@_)/while-shift/ to fix side-effect, but no such luck.
  # 1998-01-06 Created. -Simon

package Err::Debug;

use Text::Escape;
use Text::PropertyList;

# Exports: debug()
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( debug );

use strict;

use vars qw( %Level $ShowLabels $LastLabel );
%Level = ( 'always' => 1 );
$ShowLabels = 1;
$LastLabel = '';

# Functions

# add_logging( @dbg_label );
sub add_logging (@)  { foreach ( @_ ) { $Level{ $_ } ++ } }

# drop_logging( @dbg_label );
sub drop_logging (@) { foreach ( @_ ) { $Level{ $_ } -- } }

# debug( $label, @values );
sub debug ($;@) {
  my $dbg_label = shift;
  return unless $Level{ $dbg_label };
  
  if ( $ShowLabels and $dbg_label ne $LastLabel ) {
    warn '### ' . $dbg_label . "\n";
    $LastLabel = $dbg_label;
  }
  
  my @items;
  while ( scalar @_ ) {
    my $item = shift;
    push @items, ( ref $item or ! defined $item ) ? astext($item, 0) 
						  : printable $item;
    push @items, ' ';
  }
  warn @items, "\n";
} 

1;

__END__

=head1 Err::Debug 

Provides log filtering and text escaping.

=head1 Synopsis

    sh> cat debug.t
    use Err::Debug;
    Err::Debug::add_logging split(' ', shift @ARGV);
    debug 'Process', 'starting at time', time();
    while ( $x = <> ) { debug 'Item', 'got line', $x; }
    debug 'Process', 'done';
    
    sh> hostname | perl debug.t 
    
    sh> hostname | perl debug.t Process
    ### Process
    starting at time 888381566 
    done 
    
    sh> hostname | perl debug.t Process Item
    ### Process
    starting at time 888381566 
    ### Item
    got line multiweb\n 
    ### Process
    done 

=head1 Exports

=over 4

=item debug( $label, @values )

Common debug logging function.

=back

=head1 Functions

=over 4

=item add_logging( @labels )

Increments the logging level for the specified labels

=item drop_logging( @labels )

Decrements the logging level for the specified labels

=item debug( $label, @values )

If the logging level for this label is set, warns the supplied values. 

Debug statements with the same label will be preceeded by an separator line unless $ShowLabels is explicitly turned off.

The label 'always' is turned on by default.

=back

=head1 Caveats and Things Undone

=over 4

=item *

We wouldn't need to import everywhere if this code was invoked on warn(). The complication would be to ensure that pre-existing warns don't break.

=item *

It'd be nice if we printed a separator before any non-debug warns.

=item *

In one case, I saw a side-effect from invoking debug (in FieldSet::get), whereas an equivalent warn had no such effect. Doesn't seem to happen anywhere else though...

=cut