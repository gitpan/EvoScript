### Script::Tags::Print echoes the provided value with escape & format options 

### Interface
  # [print value=#x (plus=#n ifempty=alt format=fmt-name escape=esc-name)]
  # $text = $printtag->interpret();

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-03 Removed case option, replaced with new escaper functions.
  # 1998-03-11 Inline POD added.
  # 1998-01-11 Check for undefined value argument, substitute empty string.
  # 1997-10-28 Updated to use new Text::Escape interface.
  # 1997-09-?? Forked for four.
  # 1997-03-23 Improved exception handling.
  # 1997-03-11 Split from script.tags.pm
  # 1996-09-28 Name changed to print.
  # 1996-08-01 Initial creation of the value tag. -Simon

package Script::Tags::Print;

$VERSION = 4.00_1998_03_11;

use Script::Tag;
push @ISA, qw( Script::Tag );

use Err::Debug;

use Text::Format qw( formatted );
use DateTime::Formats;
use Number::Formats;

use Text::Escape qw( escape );
$Escapes{'uppercase'} = \&uppercase;
$Escapes{'lowercase'} = \&lowercase;
$Escapes{'initialcase'} = \&initialcase;
sub uppercase ($) { "\U$_[0]\E" }
sub lowercase ($) { "\L$_[0]\E" }
sub initialcase ($) { "\L\u$_[0]\E" }

# [print value=#x (plus=#n ifempty=alt format="fmt-name arg" escape=esc-name)]
Script::Tags::Print->register_subclass_name();
sub subclass_name { 'print' }

# $argdef_hash_ref = $tag->arg_defn();
sub arg_defn () { {
  'value' =>   {'dref' => 'optional', 'required'=>'anything'},
  'plus' =>    {'dref'=>'optional', 'required'=>'number'},
  'ifempty' => {'dref'=>'no', 'required'=>'string_or_nothing'},
  'case' =>    {'dref'=>'no', 'required'=>'oneof_or_nothing upper lower'},
  'format' =>  {'dref'=>'no', 'required'=>'string_or_nothing'},
  'escape' =>  {'dref'=>'no', 'required'=>'string_or_nothing'},
} }

# $text = $tag->interpret();
sub interpret {
  my $tag = shift;
  my $args = $tag->get_args;
  
  my $value = $args->{'value'};
  $value = '' unless ( defined $value );
  
  $value += $args->{'plus'} if ($args->{'plus'});
  $value = formatted($args->{'format'}, $value) if ( $args->{'format'} );
  $value = $args->{'ifempty'} if ($value !~/\S/ && defined $args->{'ifempty'});
  $value = escape($args->{'escape'}, $value) if ( $args->{'escape'} );
  
  return $value;
}

1;

__END__

=head1 Print

Echoes the provided value with escape and format options.

    [print value=#request.args.name]

=over 4

=item value

The value to be printed. Use '#' for DRefs. Required argument. 

=item plus

Optional. A numeric value to add the the value argument. Use '#' for DRefs. 

=item ifempty

Optional. An alternative string to use if value is empty.

=item format

Optional. A format specifier to be handled by L<Text::Format>. If desired, a format option may be appeneded, separated with sapces. For example, format=roman will covert the value to be printed to Roman numerals; format="date short" would attempt to parse the value as a date and display it in month/day/year style.

=item escape

Optional. An escape specifier to be handled by L<Text::Escape>. Multiple escape specifiers may be separated with spaces and quoted. For example, escape=url will protect the value for use in a URL; escape="uppercase quote" will convert the value to be printed to uppercase and enclose it with double-quotes.

=back

=cut