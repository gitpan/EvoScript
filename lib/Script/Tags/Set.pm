### Script::Set provides a basic assignment operation for EvoScript

### Interface
  # [set target=dref asdref escape=fromtext|html|url...] ... [/set]
  # $emptystring = $settag->interpret();

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-11 Inline POD added.
  # 1997-10-29 Updated to four-oh stylee.
  # 1997-03-11 Split from script.tags.pm -Simon
  # 1996-08-01 Initial creation of the set tag.

package Script::Tags::Set;

$VERSION = 4.00_1998_03_11;

use Script::Container;
@ISA = qw( Script::Container );

use Text::Words qw( string2list);
use Data::DRef;

# [set target=dref asdref escape=fromtext|html|url...] ... [/set]
Script::Tags::Set->register_subclass_name();
sub subclass_name { 'set' }

%ArgumentDefinitions = (
  'target' => {'dref' => 'target', 'required'=>'non_empty_string'},
  'asdref' => {'dref'=>'no', 'required'=>'flag'},
  'wordsof' => {'dref'=>'no', 'required'=>'flag'},
  'escape' => {'dref'=>'no', 'required'=> 'oneof_or_nothing ' .
					    join(' ', Text::Escape::names()) },
);

# $emptystring = $settag->interpret();
sub interpret {
  my $tag = shift;
  my $args = $tag->get_args;
  
  my $value = $tag->interpret_contents();
  $value = getData($value) if ($args->{'asdref'});
  $value = [ string2list($value) ] if ($args->{'wordsof'});
  $value = escape($args->{'escape'}, $value) if ( $args->{'escape'} );
  
  setData($args->{'target'}, $value);
  return '';
}

1;

__END__

=head1 Set

Evaluates its contents and sets the target dref to the result.

    [set target=my.string]
      The time is [print value=#server.timestamp]
    [/set]

=over 4

=item target

The DRef at which to store the value. Required argument. 

=item asdref

Optional flag. Stores the value found by calling getData with the tag contents.

=item wordsof

Optional flag. Stores a reference to an array of phrases returned by calling string2list with the tag contents.

=item escape

Optional. An escape specifier to be handled by L<Text::Escape>. Multiple escape specifiers may be separated with spaces and quoted.

=back

=cut