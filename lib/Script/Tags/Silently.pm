### Script::Tags::Silently allows you to run script tags without seeing results

### Interface
  # [silently] ... [/silently]
  # $emptystring = $tag->interpret();

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-11 Inline POD added.
  # 1997-11-17 Brought up to four-oh.

package Script::Tags::Silently;

$VERSION = 4.00_1998_03_11;

use Script::Container;
@ISA = qw( Script::Container );

Script::Tags::Silently->register_subclass_name();
sub subclass_name { 'silently' }

# [silently] ... [/silently]
%ArgumentDefinitions = (
);

# $emptystring = $tag->interpret();
sub interpret {
  my $tag = shift;
  my $args = $tag->get_args;
  
  $tag->interpret_contents();
  
  return '';
}

1;

__END__

=head1 Silently

Executes the contained script without returning its results.  

    [silently]
      [print value=5]
    [/silently]

There are no arguments for this tag.

=cut
