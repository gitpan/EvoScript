### Script::Tags::Warn allows you to write messages to the server error log

### Interface
  # [warn] ... [/warn]
  # $emptystring = $tag->interpret();

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License.

### Change History
  # 1998-03-11 Inline POD added.
  # 1997-11-17 Brought up to four-oh.

package Script::Tags::Warn;

$VERSION = 4.00_1998_03_11;

use Script::Container;
@ISA = qw( Script::Container );

Script::Tags::Warn->register_subclass_name();
sub subclass_name { 'warn' }

# [warn] ... [/warn]
%ArgumentDefinitions = ();

# $emptystring = $tag->interpret();
sub interpret {
  my $tag = shift;
  warn $tag->interpret_contents . "\n";
  return '';
}

1;

__END__

=head1 Warn

Evaluates its contents and logs them using Perl's warn statement.  

    [warn]I'm melting![/warn]

There are no arguments for this tag.

=cut