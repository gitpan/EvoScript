### Script::Element is the abstract base class for all EvoScript objects

### Default Behaviour 
  # $element->add_to_parse_tree($parser);

### Abstract methods to be implemented by subclasses
  # Script::Element->new();				
  # Script::Element->add();				
  # Script::Element->parse();			
  # Script::Element->source();			
  # $specialchars = Script::Element->stopregex();	
  # $result = $element->interpret();			

### Should add some methods to allow various depth-first traversals, including:
  # $e->call_on_self_and_contents($method, @args);
  # $e->call_with_self_and_contents($code_ref, @other_args);

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-26 Changed add_to_parse_tree to call $parser->current->add directly
  # 1998-03-06 Added inline POD.
  # 1998-01-29 Added default do-nothing exapnd method.
  # 1997-09-02 Split from primary Script package and refactored. -Simon

package Script::Element;

use Carp;

### Default Behaviour 

# $element->add_to_parse_tree($parser);
sub add_to_parse_tree {
  my $element = shift;
  my $parser = shift;
  $parser->current->add($element);
}

# $element = $element->expand;
sub expand { shift }

### Abstract methods to be implemented by subclasses

# Script::Element->new();				
# Script::Element->add();				
# Script::Element->parse();			
# Script::Element->source();			
# $specialchars = Script::Element->stopregex();	
# $result = $element->interpret();			

1;

__END__

=head1 Evo::Script::Element

Evo::Script::Element is the abstract base class for all EvoScript objects

=head1 Reference

=over 4

=item $element->add_to_parse_tree($parser)

Calls $parser->add to add this element to the parse tree. Exposed as a subclass hook.

=item Evo::Script::Element::CLASS->parse

Abstract. Provide script parsing for the source code of this class.

=item Evo::Script::Element::CLASS->stopregex

Abstract. Provide an expression denoting the start of a candidate source string. 

=item Evo::Script::Element::CLASS->new( @args ) : $element

Abstract. Create a new element of the specified class.

=item $element->add( $sub )

Abstract. Attempt to add items as contents of the current item.

=item $element->interpret : $output_text

Abstract. Provide a source code expression for the element.

=item $element->source : $source_text

Abstract. Provide a source code expression for the element.

=back

=head1 Caveats and Upcoming Changes

There are no major interface changes anticipated for this module.

=head1 See Also

L<Evo::Script>, L<Evo::Script::Literal>, L<Evo::Script::Sequence>, L<Evo::Script::Tag>, L<Evo::HTML::Tag>

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc. (http://www.evolution.com)

You can use this software under the same terms as Perl itself.

Part of the EvoScript Web Application Framework (http://www.evoscript.com)

=cut
