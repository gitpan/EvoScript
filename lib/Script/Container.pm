### Script::Container provides Tag classes with open and close forms.

### A Script::Container is a Tag with a contained sequence of tags
  # $container->add_to_parse_tree($parser);

### A Script::Closer is the dangly bit at the end of a container [/exmpl]
  # $closer->add_to_parse_tree($parser);

### A Script::TextContainer is a tag with non-script contents
  # $textcntr->add_to_parse_tree($parser);

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-08 Typo fixed in add_to_parse_tree().
  # 1998-04-03 Streamlining of parser interface.
  # 1997-10-27 Added TextContainer.
  # 1997-10-27 Folded Closer and Container into the same file.
  # 1997-10-25 Mods
  # 1997-??-?? Refactored script.pm

use Script::Tag;

### A Script::Container is a Tag with a contained sequence of tags

package Script::Container;

use Script::Tag;
push @ISA, qw( Script::Tag );

use Script::Sequence;
push @ISA, qw( Script::Sequence );

# $container->add_to_parse_tree($parser);
  # When we've been parsed, we make ourselves the parser's current item;
  # a following closer tag, defined below, will hopefully mark our expiration.
sub add_to_parse_tree {
  my $container = shift;
  my $parser = shift;
  $parser->current->add($container);
  $parser->push($container);
}

# $script_text = $tag->source()
sub source {
  my $tag = shift;
  $tag->SUPER::source . $tag->source_contents . $tag->Script::Closer::source;
}

### A Script::Closer is the dangly bit at the end of a container [/exmpl]

package Script::Closer;

push @ISA, qw( Script::Tag );

# $closer->add_to_parse_tree($parser);
  # We don't actually add ourselves to the parse tree in this case; instead,
  # we pop our matching container off of the parser stack.
sub add_to_parse_tree {
  my $closer = shift;
  my $parser = shift;
  
  my $name = $closer->{'name'};
  $name =~ s/\A\///;
  $parser->pop( $closer->subclass_by_name( $name ) );
}

# $closetagtext = $tag->source();
sub source {
  my $tag = shift;
  return '[/' . $tag->{'name'} . ']';
}

sub subclass_name { '' }

### A Script::TextContainer is a tag with non-script contents

package Script::TextContainer;

push @ISA, qw( Script::Tag );

use Text::Excerpt qw( printablestring );

# $textcntr->add_to_parse_tree($parser);
  # when we've been parsed, we go grab some additional text from the parser
sub add_to_parse_tree {
  my $textcntr = shift;
  my $parser = shift;
  
  my $contents = $parser->get_text('.+?\\[\\/' . $textcntr->{'name'} . '\\]');
  die "couldn't find end of '$textcntr->{'name'}' tag.\n" . $parser->{'text'} unless $contents;
  
  $contents =~ s/\[\/\Q$textcntr->{'name'}\E\]\Z//;
  $textcntr->{'contents'} = $contents;
  
  $parser->current->add($textcntr);
}

# $scripttext = $tag->source()
sub source {
  my $tag = shift;
  $tag->SUPER::source . $tag->{'contents'} . $tag->Script::Closer::source;
}

1;