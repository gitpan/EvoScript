### An Script::Parser builds a tree of elements embedded in a text stream

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-08 Moved some optional warnings into debug 'parser' statements.
  # 1998-03-26 Added support for $p->pop($class_name); removed $p->add($elem)
  # 1997-10-23 Touchups.
  # 1997-08-26 Forked version 4

package Script::Parser;

use Script::Sequence;

use Carp;
use Err::Debug;

use strict;

use Text::Excerpt qw( elide );

### Syntax Registry

# @Syntaxes - known syntax classes
use vars qw( @Syntaxes );

# Script::Parser->add_syntax( $syntax_package_name );
sub add_syntax {
  my $package = shift;
  push @Syntaxes, @_;
}

### Parser client interface

# $parser = Script::Parser->new();
sub new {
  my $package = shift;
  my $parser = {};
  $parser->{'syntaxes'} = [ @Syntaxes ];
  
  bless $parser, $package;  
    
  return $parser;
}

# $sequence = $parser->parse( $script_string );
sub parse {
  my $parser = shift;
  
  my $sequence = Script::Sequence->new();
  $parser->push( $sequence );
  
  $parser->{'text'} = shift;
  
  debug 'parser', 'Source is', $parser->{'text'};
  
  TOKEN: while ( length $parser->{'text'} ) {
    # Allow each of the syntax classes to try matching against the text 
    my $syntax;
    foreach $syntax ( @{$parser->{'syntaxes'}} ) {
      next TOKEN if $syntax->parse($parser);
    }
    
    # Fallback behaviour to ensure that we don't loop infinitely 
    warn "Script Parser syntax hiccup at: " . elide($parser->{'text'}) . "\n";
    Script::Literal->new($parser->get_text('.'))->add_to_parse_tree($parser);
  }
  
  debug 'parser', 'Result is', $sequence;
  
  $parser->pop( $sequence );
  
  return $sequence;
}

### Text extraction functions used to parse text out of the source

# $text = $parser->get_text( $regex );
sub get_text { 
  my $parser = shift;
  my $regex = shift;
  
  return unless (length $parser->{'text'} and length $regex);
  
  debug 'parser', "looking for '$regex' at ", elide($parser->{'text'});
  $parser->{'text'} =~ s/\A($regex)//s or return '';
  
  debug 'parser', "matched: ", elide($1);
  return $1;
}

# $text = $parser->get_unspecial_string();
sub get_unspecial_string { 
  my $parser = shift;
  
  return unless (length $parser->{'text'});
  
  # Take out everything upto the next occurance of the stopex
  my $exp = $parser->stopex;
  return $1 if ( length $exp and $parser->{'text'} =~ s/\A(.*?)($exp)/$2/s );
  
  # Else we didn't find the stopex; it all looks unspecial, so take it all.
  my $string = $parser->{'text'};
  $parser->{'text'} = '';
  return $string;
}

# $parser->stopex();
sub stopex {
  my $parser = shift;
  
  # The stopex only changes if you change Syntax classes, so cache the result
  $parser->buildstopex() unless ( exists $parser->{'stopex'} );
  
  return $parser->{'stopex'};
}

# $parser->buildstopex();
sub buildstopex {
  my $parser = shift;
  
  my ($syntax, @stopex);
  foreach $syntax (@{$parser->{'syntaxes'}}) {
    my $stop = $syntax->stopregex();
    push @stopex, $stop if (length $stop);
  }
  
  $parser->{'stopex'} = join '|', @stopex;
}

### Parser Context Stack.

# $current_item = $parser->current();
sub current {
  my $parser = shift;
  return $parser->{'stack'}[0] || croak "no item is current";
}

# $parser->push( $element );
sub push {
  my $parser = shift;
  my $target = shift;
  
  unshift @{$parser->{'stack'}}, $target;
}

# $element = $parser->pop( );
# $element = $parser->pop( $class_name );
# $element = $parser->pop( $element_reference );
# $element = $parser->pop( $test_function_ref );
  # Pop until we hit this item, or an item for which &$coderef($item) == true  
sub pop {
  my $parser = shift;
  my $popper = shift;
  
  my $n;
  foreach $n (0 .. $#{$parser->{'stack'}} ) { 
    my $item = $parser->{'stack'}->[$n];
    
    if ( ! $popper ? 1 
	   : (! ref $popper) ? UNIVERSAL::isa($item, $popper) 
	     : (ref $popper eq 'CODE') ? &$popper($item) 
		: $popper eq $item 				) {
      # pop the first $n -1 of 'em with warnings
      warn "Script Parser warning: closing '$popper' truncates " . 
      			@{$parser->{'stack'}}[ 0 .. $n -1 ] . "\n" if ( $n );
      foreach ( 1 .. $n ) { shift @{$parser->{'stack'}}; }
      return shift @{$parser->{'stack'}};
    }
  }
  
  warn "Script Parser error: unable to satisfy pop request for '$popper' \n";
}

1;

__END__

=head1 Script::Parser

We keep offering all of our known syntax classes a chance to pull text
off of the script string. If they are successful, they use parser methods
to add themselves to the syntax tree; if not they exit and we iterate.
Pickier classes should come first, eg test <%=, <%, and then <.

Text that doesn't match any other syntax class becomes Literals.
We build a regex of stopchars to optimize parsing literals.

=head2 Syntax Registry

=over 4

=item @Syntaxes - known syntax classes

=item Script::Parser->add_syntax( $syntax_package_name )

=back


=head2 Client Interface

=over 4

=item Script::Parser->new : $parser

Create a parser object.

=item $parser->parse( $script_string ) : $sequence

Parse the provided string and return a sequence containing the Elements found in it.

=back


=head2 Text Extraction

Functions used to parse text out of the source stored in $parser->{'text'}.

=over 4

=item $parser->get_text( $regex ) : $text

Strip any text matching this regex off of the front of the script text.

=item $parser->get_unspecial_string : $text

Get a run of text that doesn't look special. Stops at stopex, see below

=item $parser->stopex

Returns the regexes the parser's syntax classes might find interesting

=item $parser->buildstopex

Updates the parser's stopex to reflect the current syntax classes.

=back


=head2 Enclosure Stack

=over 4

=item $parser->current : $current_item

The topmost element on the stack.

=item $parser->push( $element )

Push this element onto the stack

=item $parser->pop : $element

Remove the topmost element from the stack and return it.

=item $parser->pop( $class_name ) : $element

Remove elements from the stack until it finds one of this class and return it.

=item $parser->pop( $element_reference ) : $element

Remove elements from the stack until it finds this one and return it.

=item $parser->pop( $test_function_ref ) : $element

Remove elements from the stack until it finds one for which this function returns true.

=back


=head2 On being multiply-syntaxed

Need to be able to add syntaxes, use some custom syntax for a while, etc.

It seems there's a range of vaugely-related Net-endorsed or Evo-designed 
syntaxes for embedding "rich" content, platform-independant markup, 
"dynamic behaviour," and so forth, into Web-ready text files, such as:

  EvoScript
  - script tags          [print value=#x] 
  - script containers    [foreach values=#list]...[/foreach]
  - language statements  [perl]...[/perl]
  
  Various literals and escape sequences:
  - literals		 .*?
  - backslashed escapes  \\.
  - false end of line	 \\\n\s* or //\n\s*
  
  ASP, ePerl, LiveWire
  - language statements  <% ... %>, <perl>...</perl>, <script>...</script>
  
  SSI
  - server side includes <!--#tag args-->
  
  HTML
  - html tags		 <br>
  - html containers	 <b>...</b>
  - html escapes	 &\w+\; &\d\d --?
  
  XML
  - xml tags		 <br/>
  - xml containers	 <b>...</b>

What regexes might current or future syntax classes want to stop at?
  [			EvoScript tags
  \			Escaped literals
  <			HTML tags
  <%, <%=		Active Server Pages scripts
  <script>		LiveWire scripts
  <!--#			Server Side Includes			
  [\x00-\x1f\x7F-\xFF]	Unprintable chars translated to HTML escapes?

=head2 Bugs and Things To Do

Should be able to specify which parsing rules are supported.

For example, html tag parsing may not be desireable in many cases.

Additionally, should provide hooks at tag level, for example: 
<tr>'s contents may only be <td> and whitespace literals; 
opening a new <td> should close the last one (same with <p>, etc); and
<input type=checkbox> must be able to find others of same name.

=cut
