### Script::HTML::Links provides HTML link tags

### <a href=x> ... </a>

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-10 Now using add_tag_class()
  # 1997-10-31 Created. -Simon

package Script::HTML::Links;

use Script::HTML::Tag;

# <a href=url> ... </a>
Script::HTML::Container->add_tag_classes(
  'a'   => 'Link::Anchor',
);

# <img src=url>
Script::HTML::Tag->add_tag_classes(
  'img'   => 'Link::InlineImage',
);

1;