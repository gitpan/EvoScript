### String::Excerpt - Truncate strings with elipses

### Interface
  # $elided_string = truncate($string, $length);
  # $escaped_elided_string = printablestring($string, $length);
  # $elided_words = shortenstring($string, $length);

### Change History
  # 1998-02-25 Version 1.00 - String::Excerpt
  # 1998-02-25 Moved to String:: and @EXPORT_OK for CPAN distribution - jeremy
  # 1997-11-13 Changed truncate's name to elide -- looks like it's special -S.

package String::Excerpt;

use vars qw( $VERSION );
$VERSION = 1.00;

use String::Escape 1.00, qw( printable );

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( elide printablestring );

# $elided_string = elide($string, $length);
  # Return a single-quoted, shortened version of the string, with ellipsis
sub elide ($;$) {
  my ($text, $length) = @_;
  
  $length ||= 40;
  $text = substr($text, 0, $length - 3) .'...' if ($length < length($text));
  
  return "'" . $text . "'";
}

# $escaped_elided_string = printablestring($string, $length);
  # Truncate the string as above, but first backslash escape any unprintables.
sub printablestring ($;$) { elide(printable(shift), shift); }

# $elided_words = shortenstring($string, $length);
  # Truncate the string at nearest word boundary.
sub shortenstring {
  my ($text, $length) = @_;
  $length ||= 40;
  
  my $textlen = length($text);
  # ($text =~ /^(.{$length}\S*)/)[0] .'...'
  $text = ($text =~ /^(.{0,$length})(?:\s|\Z)/)[0];
  
  return $text . ( length($text) < $textlen ? '...' : '' );
}

1;

=pod

=head1 String::Excerpt

Exctract a small excerpt of text from a larger string.

=head1 Synopsis

  use String::Excerpt qw( elide printablestring );

  $string = 'foo bar foo bar foo bar';
  
  $elided_string = elide( $string, 10 );
  $elided_string eq 'foo bar fo...'
  
  $elided_words = shortenstring( $string, 10 );
  $elided_words eq 'foo bar...'
  
  $unprintable_string = "Joe\tFoo\nSusan\tbar\n";
  $printablestring = printablestring( $unprintable_string, 10 );
  $printablestring eq 'Joe\t\nFoo...';

=head1 Reference

=over 4

=item elide($string, $length) : $elided_string

Return a single-quoted, shortened version of the string, with ellipsis

=item printablestring($string, $length) : $escaped_elided_string

Truncate the string as above, but first backslash escape any unprintables.

=item shortenstring($string, $length) : $elided_words

Truncate the string at nearest word boundary.

=back

=head1 Caveats and Upcoming Changes

These function names could be a lot better.

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut