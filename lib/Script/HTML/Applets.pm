### Script::HTML::Applets provides Java applet HTML tags

### Tags
  # <applet> ... </applet>
  #   <param>

### Applets::Applet
  # $applet->add_param( $name => $value, ... );
  # $stringvalue = $sequence->interpret_contents(); // intersperses \n in SUPER

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-06-02 Restored intersperse method in superclass. -Simon
  # 1998-06-01 Removed call to intersperse until it works correctly.  -EJM
  # 1998-05-04 Added 'use Script::HTML::Tag' to Applets::Applet.  -Piglet
  # 1998-03-10 Now using add_tag_class() and intersperse
  # 1998-01-30 Added support for multiple key-value pairs in $applet->add_param
  # 1997-11-26 Created. -Simon

package Script::HTML::Applets;

use Script::HTML::Tag;

# <applet> ... </applet>
Script::HTML::Container->add_tag_classes(
  'applet'   => 'Applets::Applet',
);

# <param>
Script::HTML::Tag->add_tag_classes(
  'param'   => 'Applets::Param',
);

### Applets::Applet

package Script::HTML::Applets::Applet;

use Script::HTML::Tag;

# $applet->add_param( $name => $value, ... );
sub add_param {
  my $applet = shift;
  while ( scalar @_ ) {
    $applet->add( html_tag('param', { 'name' => shift, 'value' => shift } ) );
  }
}

# $stringvalue = $sequence->interpret_contents(); // intersperses \n in SUPER
sub interpret_contents {
  my $sequence = shift;
  $sequence->intersperse( "\n" );
  $sequence->SUPER::interpret_contents();
}

1;
