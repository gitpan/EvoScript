### Script::HTML::Pages provides page-related HTML tags

### Tags
  # <html> ... </html>
  # <head> ... </head>
  # <title> text ... </title>
  # <meta>
  # <body> ... </body>
  # <p> ... </p>
  # <br>
  # <hr>
  # <script> ... </script>
  # <blockquote> ... </blockquote>

### Pages::HTML
  # $head_tag = $html_tag->head();
  # $body_tag = $html_tag->body();

### Pages::Head
  # $title_tag = $html_tag->title();

### Pages::Paragraph
  # $value = $para->interpret;		// prepends newline to SUPER

### Pages::Break
  # %$args = $tag->get_args();		// supress the newline=0 flag
  # $value = $para->interpret;		// prepends newline to SUPER

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-13 Added list elements to add_tag_class blocks.
  # 1998-03-26 Added support for html lists (ol, ul, dl) and their items. -Del
  # 1998-03-10 Now using add_tag_class()
  # 1998-03-06 Added $html->head, $html->body, and $head->title methods.
  # 1997-12-03 Added newline=0 option for <br> tags to override that \n.
  # 1997-11-25 Added \n's before <p> and <br> tags so there's a bit of \s+
  # 1997-10-31 Created. -Simon

package Script::HTML::Pages;

use Script::HTML::Tag;

# <html> ... </html>
Script::HTML::Container->add_tag_classes(
  'html'	=> 'Pages::HTML',
  'head'	=> 'Pages::Head',
  'title'	=> 'Pages::Title',
  'body'	=> 'Pages::Body',
  'p'		=> 'Pages::Paragraph',
  'script'	=> 'Pages::Script',
  'blockquote'	=> 'Pages::BlockQuote', 
  'ul'		=> 'Pages::List::Unordered',
  'ol'		=> 'Pages::List::Ordered',
  'dl'		=> 'Pages::List::Definition',
);

# <param>
Script::HTML::Tag->add_tag_classes(
  'meta'	=> 'Pages::Meta',
  'hr'		=> 'Pages::Rule',
  'br'		=> 'Pages::Break',
  'li'		=> 'Pages::List::Item',
  'dt'		=> 'Pages::List::Definition::Def',
  'dl'		=> 'Pages::List::Definition::Term',
);

### Pages::HTML

package Script::HTML::Pages::HTML;

# $head_tag = $html_tag->head();
sub head { (shift)->ensure_element_of_class('Script::HTML::Pages::Head') }

# $body_tag = $html_tag->body();
sub body { (shift)->ensure_element_of_class('Script::HTML::Pages::Body') }

### Pages::Head

package Script::HTML::Pages::Head;

# $title_tag = $html_tag->title();
sub title { (shift)->ensure_element_of_class('Script::HTML::Pages::Title') }

### Pages::Paragraph

package Script::HTML::Pages::Paragraph;

# $value = $para->interpret;		// prepends newline to SUPER
sub interpret { "\n" . $_[0]->SUPER::interpret(); }

### Pages::Break

package Script::HTML::Pages::Break;

# %$args = $tag->get_args();		// supress the newline=0 flag
sub get_args {
  my $tag = shift;
  my $args = { %{$tag->{'args'}} };
  delete $args->{'newline'};
  return $args;
}

# $value = $para->interpret;		// prepends newline to SUPER
sub interpret { 
  my $brtag = shift;
  my $whitespace = exists $brtag->{'args'}{'newline'} ? 
  					$brtag->{'args'}{'newline'} : 1;
  return ( $whitespace ? "\n" : '') . $brtag->SUPER::interpret(); 
}


1;