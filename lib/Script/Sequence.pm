### An Script::Sequence is an element containing an array of sub-elements.

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-06-02 Relocated intersperse method.
  # 1998-03-05 Added elements_of_class(), first_element_of_class method.
  # 1997-11-01 Minor fixups; reordered methods
  # 1997-10-31 Added append and prepend methods
  # 1997-09-** Split from primary Script package and refactored. -Simon

package Script::Sequence;

use Script::Element;
push @ISA, qw( Script::Element );

use Carp;
use Err::Debug;

### Instantiation

# $sequence = Script::Sequence->new( @elements );
sub new {
  my $class = shift;
  
  my $sequence = { 'elements' => [], };
  bless $sequence, $class;
  
  foreach ( @_ ) { $sequence->add( $_ ); }
  
  return $sequence;
}

### Element Access

# @elements = $sequence->elements; or @$elements = $sequence->elements;
sub elements {
  my $sequence = shift;
  return wantarray ? @{ $sequence->{'elements'} } : $sequence->{'elements'};
}

# $count = $sequence->elementcount;
sub elementcount {
  my $grid = shift;
  return scalar @{ $grid->elements };
}

# @values = $sequence->call_on_each($method, @args);
sub call_on_each {
  my $sequence = shift;
  my ($method, @args) = @_;
  my @values;
  foreach $element ( $sequence->elements ) {
    debug 'script_sequence', 'Calling', $method, 'on element', "$element";
    croak "can't call method '$method' on element '$element'" 
				unless ( UNIVERSAL::can($element, $method ) );
    push @values, $element->$method(@args);
  }
  return @values;
}

### Element Manipulation

# $sequence->add( @elements );
sub add {
  my $sequence = shift;  
  $sequence->append_elements( @_ );
}

# $sequence->append_elements( @element );
sub append_elements {
  my $sequence = shift;  
  foreach ( @_ ) { $sequence->append( $_ ); }
}

# $ok_flag = $sequence->prepend_elements( @element );
sub prepend_elements {
  my $sequence = shift;  
  foreach ( reverse @_ ) { $sequence->prepend( $_ ); }
}

# $sequence->append( $element );
sub append {
  my $sequence = shift;
  
  my $target = shift;
  $target = Script::Literal->new( $target ) unless ref $target;
  
  return unless ( $sequence->about_to_add( $target ) ); 
  
  push @{$sequence->{'elements'}}, $target;
}

# $sequence->prepend( $element );
sub prepend {
  my $sequence = shift;
  my $target = shift;
  $target = Script::Literal->new( $target ) unless ref $target;
  
  return unless ( $sequence->about_to_add( $target ) ); 
  
  unshift @{$sequence->{'elements'}}, $target;
}

# $sequence->about_to_add( $element );
  # Return 0 to discard contents, or croak if they're unacceptable
sub about_to_add {
  my $sequence = shift;
  my $target = shift;
  
  confess "can't add '$target' to '$sequence', it's not a Script::Element" 
	unless (ref $target and UNIVERSAL::isa($target, 'Script::Element') );
  
  return 1;
}

# $sequence->intersperse( $spacer );
sub intersperse {
  my $sequence = shift;
  my $spacer = shift;
  $spacer = Script::Literal->new( $spacer ) unless ( ref($spacer) );
  
  my $count;
  $sequence->{'elements'} = [ 
      map { $count++ ? ( $spacer, $_ ) : ( $_ ) } @{ $sequence->{'elements'} } 
  ];
  debug 'sequence', "interspersed", $sequence->{'elements'};
}

### Execution

# $stringvalue = $sequence->interpret();
sub interpret {
  my $sequence = shift;
  return $sequence->interpret_contents();
}

# $stringvalue = $sequence->interpret_contents();
sub interpret_contents {
  my $sequence = shift;
  
  debug 'script_sequence', "Interpreting $sequence";
  
  my $value = join('', $sequence->call_on_each('interpret'));
  
  debug 'script_sequence', "Interpretation of $sequence complete";
  debug 'script_sequence', "value is", $value;
  
  return $value;
}

# $stringvalue = $sequence->source();
sub source {
  my $sequence = shift;
  return $sequence->source_contents();
}

# $stringvalue = $sequence->source_contents();
sub source_contents {
  my $sequence = shift;
  
  return join('', $sequence->call_on_each('source'));
}

### Access by Class

# @elements = $sequence->elements_of_class( $classname );
sub elements_of_class {
  my $sequence = shift;
  my $classname = shift;
  
  grep { UNIVERSAL::isa($_, $classname) } $sequence->elements;
}

# $element = $sequence->first_element_of_class( $classname );
sub first_element_of_class {
  my $sequence = shift;
  my $classname = shift;
  
  ($sequence->elements_of_class($classname))[0];
}

# $element = $sequence->ensure_element_of_class( $classname );
sub ensure_element_of_class {
  my $sequence = shift;
  my $classname = shift;
  
  my $element = $sequence->first_element_of_class($classname);
  
  unless ( $element ) {
    $element = $classname->new();
    $sequence->add( $element );
  }
  
  return $element;
}

1;

__END__

=head1 Script::Sequence


=head2 Instantiation

=over 4

=item Script::Sequence->new( @elements ) : $sequence

=back


=head2 Element Access

=over 4

=item $sequence->elements; or @$elements = $sequence->elements : @elements

=item $sequence->elementcount : $count

=item $sequence->call_on_each($method, @args) : @values

=back


=head2 Element Manipulation

=over 4

=item $sequence->add( @elements )

=item $sequence->append_elements( @element )

=item $sequence->prepend_elements( @element ) : $ok_flag

=item $sequence->append( $element )

=item $sequence->prepend( $element )

=item $sequence->about_to_add( $element )

=item $sequence->intersperse( $spacer )

=back


=head2 Execution

=over 4

=item $sequence->interpret : $stringvalue

=item $sequence->interpret_contents : $stringvalue

=item $sequence->source : $stringvalue

=item $sequence->source_contents : $stringvalue

=back


=head2 Access by Class

=over 4

=item $sequence->elements_of_class( $classname ) : @elements

=item $sequence->first_element_of_class( $classname ) : $element

=item $sequence->ensure_element_of_class( $classname ) : $element

=back

=cut
