### Script::Literal provides two classes for literals and escape sequences

### A Script::Literal is a chunk of text
  # $empty = Script::Literal->stopregex();	
  # Script::Literal->parse( $parser );
  # $literal = Script::Literal->new( $stringvalue );
  # $stringvalue = $literal->iswhitespace();
  # $stringvalue = $literal->interpret();
  # $stringvalue = $literal->source();

### An Script::EscapedLiteral is a backslashed sequence of characters.
  # $special_chars = Script::EscapedLiteral->stopregex()
  # Script::EscapedLiteral->parse( $parser );

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1997-10-31 Folded escaped literals into the Literal.pm file.
  # 1997-09-** Split from primary Script package and refactored.

### A Script::Literal is a chunk of text who's output is itself.

package Script::Literal;

use Script::Element;
@ISA = qw( Script::Element );

use Text::Excerpt qw( printablestring );

# $empty = Script::Literal->stopregex();	
sub stopregex { return ''; }

# Script::Literal->parse( $parser );
sub parse {
  my ($package, $parser) = @_;
  
  my $string = $parser->get_unspecial_string();
  
  return unless (defined $string and length $string);  # nothing to match
  
  $package->new( $string )->add_to_parse_tree( $parser );
  
  return 1; # sucessful match
}

# $literal = Script::Literal->new( $stringvalue );
sub new {
  my $package = shift;
  my $value = shift;
  $value = '' if (not defined $value);
  bless \$value, $package;
}

# $stringvalue = $literal->iswhitespace();
sub iswhitespace {
  my $literal = shift;
  return $$literal !~ /\S/ ? 1 : 0 ;
}

# $stringvalue = $literal->interpret();
sub interpret {
  my $literal = shift;
  return $$literal;
}

# $stringvalue = $literal->source();
sub source {
  my $literal = shift;
  return $$literal;
}

### An Script::EscapedLiteral is a backslashed sequence of characters.
  # Only in its parsing does it differ from a Script Literal.

package Script::EscapedLiteral;

use Script::Literal;
@ISA = qw( Script::Literal );

# $special_chars = Script::EscapedLiteral->stopregex()
  # That mess of slashes turns out to match a single backslash character 
sub stopregex { return '\\\\'; }

# Script::EscapedLiteral->parse( $parser );
sub parse {
  my $package = shift;
  my $parser = shift;
  
  return unless ( $parser->get_text('\\\\') );
  
  # backslash newline gets thrown away to allow pretty-print indenting
  return 1 if ( $parser->get_text('\\r?\\n[ \\t]*') );
  
  my $string = '';
  if ( $string = $parser->get_text('[\\da-fA-F][\\da-fA-F]') ) {
    $string = pack("H2", $string); # found a double-digit hex escape
  } else {
    # Unix-style backslash-character escapes
    $string = $parser->get_text('.');
    if ($string eq 'r')    { $string = "\r"; } 
    elsif ($string eq 't') { $string = "\t"; } 
    elsif ($string eq 'n') { $string = "\n"; } 
    # any other character just gets inserted as itself
  }
  
  $package->new( $string )->add_to_parse_tree( $parser );
  
  return 1; # sucessful match
}

1;

__END__

=head1 Script::Literal, Script::EscapedLiteral

These packages provides classes representing literals and escape sequences.

=head1 Description

Any characters not parsed by another Script class are converted into Literal elements. 

Character sequences begining with a backslash are converted into EscapedLiterals. 

=back

=head1 Reference

=over 4

=item Script::Literal->parse( $parser )

Extracts any non-stopex characters from the parser, creates a literal, and adds it to the parse tree.

=item Script::Literal->stopregex

Returns an empty string. There aren't any particularly special characters for literals.

=item Script::Literal->new( $stringvalue ) : $element

Creates a new literal corresponding to the provided string value.

=item $element->interpret : $output_text

Returns the element's string value.

=item $element->source : $source_text

Returns the element's string value.

=item $element->iswhitespace : $flag

Returns true if the element's string value doesn't contain any display characters.

=back

=head2 EscapedLiteral

This subpackage provides parsing rules and objects that represent backslashed sequences of characters. The following backslashed escapes are supported:

=over 4

=item \00 - \FF

Converted to the equivalent character.

=item \n, \r, \t

Converted to CR, LF, and tab characters.

=item \ followed by newline and a run of whitespace

Removed, allowing you to add extra whitespace for formatting in scripts.

=item \ followed by any other character

The suceeding character is inserted as-is. (So \\ is parsed as a single backslash.) Such characters escape consideration as part of some succeding element. For example, one might write \<br> to prevent the string from being parsed as a Script::HTML::Tag.

=back

=over 4

=item Script::Literal->parse( $parser )

Looks for a backslash followed by one of the above escapes..

=item Script::Literal->stopregex

Returns a patern matching the backslash character.

=back

=head1 Caveats and Upcoming Changes

There are no major interface changes anticipated for this module.

EscapedLiterals should re-escape their values when writing out their source.

=head1 See Also

L<Script>, L<Script::Element>, L<Script::Sequence>, L<Script::Tag>, L<Script::HTML::Tag>

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc. (http://www.evolution.com)

You can use this software under the same terms as Perl itself.

Part of the EvoScript Web Application Framework (http://www.evoscript.com)

=cut
