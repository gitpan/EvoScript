### Text::Escape.pm - backslash, quoting, and general escape/unescape functions
  # 
  # We provide a by-name escaping function and a collection of simple escapers.
  # Each escaper takes a single simple scalar argument and returns its 
  # escaped (or unescaped) equivalent.

### Generic by-name interface
  # %Escapes - escaper function references by name
  # Text::Escape::add( $name, $subroutine );
  # @defined_escapes = Text::Escape::names();
  # $escaped = escape($escapes, $value); 
  # @escaped = escape($escapes, @values);

### Unix-style Backslash Escaping: printable(), unprintable()

### Quoted Escaping: qescape(), unqescape()

### Double Quoting: quote(), unquote(), quote_non_words()

### Change History
  # 1998-06-11 Modified printable and unprintable algorithms.
  # 1998-04-27 Anchored regexes in unprintable() to backslash mangling.
  # 1998-03-16 Avoid modify-constant warnings by using lexical rather than $_
  # 1998-02-19 Started removal of sub add calls throughout Evo::Script
  # 1997-10-28 Created generic by-name interface; renamed printable
  # 1997-10-21 Altered quote_non_words algorithm to accept '-', '/', and '.'
  # 1997-08-17 Created this package from functions in dictionary.pm. -Simon

package Text::Escape;

use vars qw( $VERSION );
$VERSION = 4.00;

use Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( escape printable unprintable qprintable unqprintable quote_non_words );

use Carp;
use strict;

### Generic by-name interface

# %Escapes - escaper function references by name
use vars qw( %Escapes );

%Escapes = ( 
  'printable' => \&printable,
  'unprintable' => \&unprintable,
  'qprintable' => \&qprintable,
  'unqprintable' => \&unqprintable,
  'quote' => \&quote,
  'unquote' => \&unquote,
  'quote_non_words' => \&quote_non_words,
  %Escapes,
);

# Text::Escape::add( $name, $subroutine );
sub add ($$) {
  my $name = shift;
  my $subroutine = shift;
  $Escapes{ $name } = $subroutine;
}

# @defined_escapes = Text::Escape::names();
sub names () {
  return keys(%Escapes);
}

# $escaped = escape($escapes, $value); 
# @escaped = escape($escapes, @values);
sub escape ($@) {
  my $escapes = shift;
  my @escapes = split(/\s+/, $escapes);
  
  my @values = @_;
  croak "escape called with multiple values but in scalar context"
					      if ($#values > 0 && ! wantarray);
  
  my ($value, $name);
  foreach $value ( @values ) {
    foreach $name (@escapes) {
      next if ($name =~ /\A\s*no\s*\Z/i);
      my $escaper = $Escapes{ $name };
      croak "escape called with undefined escaping style '$name'" 
						    unless( $escaper );
      $value = &$escaper( $value );
    }
  }
  
  return wantarray ? @values : $values[0];
}

### Unix-style Backslash Escaping: Handles return, newline, tab, unprintable characters, and backslash itself.

use vars qw( %Printable %Unprintable );
%Printable = ( 
  ( map { chr($_), unpack('H2', chr($_)) } ( 0 .. 255 ) ),
  "\\"=>'\\', "\r"=>'r', "\n"=>'n', "\t"=>'t', "\""=>'"' 
);
%Unprintable = ( reverse %Printable );

sub printable ($) {
  my $value = shift;
  $value = '' unless (defined $value);
  $value =~ s/([\r\n\t\"\\\x00-\x1f\x7F-\xFF])/\\$Printable{$1}/g;
  return $value;
}

sub unprintable ($) {
  my $value = shift;
  $value = '' unless (defined $value);
  $value =~ s/((?:\A|\G|[^\\]))\\([rRnNtT\"\\]|[\da-fA-F][\da-fA-F])/
  				$1 . $Unprintable{lc($2)}/ge;
  return $value;
}

### Quoted Printable Escaping: Backslash escaping with quotes around empty, punctuated, & multiword values.  Note that this is *not* MIME quoted-printable encoding. 

sub qprintable ($) {
  my $value = shift;
  $value = '' unless (defined $value);
  $value =~ s/([\r\n\t\"\\\x00-\x1f\x7F-\xFF])/\\$Printable{$1}/g;
  $value = '"'.$value.'"' if ($value =~ /[^\w\-\/\.\#\_]/ or ! length $value);
  return $value;
}

sub unqprintable ($) {
  my $value = shift;
  $value = '' unless (defined $value);
  $value =~ s/\A\"(.*)\"\Z/$1/;
  $value =~ s/((?:\A|\G|[^\\]))\\([rRnNtT\"\\]|[\da-fA-F][\da-fA-F])/
  				$1 . $Unprintable{lc($2)}/ge;
  return $value;
}

### Double Quoting: Add and remove double quotes from around a string. quote_non_words only quotes empty, punctuated, and multiword values

sub quote ($) {
  return '"' . (shift) . '"';
}

sub quote_non_words ($) {
  my $value = shift;
  $value = '"'.$value.'"' if ($value =~ /[^\w\-\/\.\#\_]/ or ! length $value);
  return $value;
}

sub unquote ($) {
  my $value = shift;
  $value =~ s/\A\"(.*)\"\Z/$1/;
  return $value;
}

1;

=pod

=head1 Text::Escape

Text::Escape implements backslash, quoting, and general escape/unescape functions. It also provides a calling and registration mechanism for additional escaping functions. If you're bright, it's the only interface for escaping that you'll ever need.

=head1 Synopsis

  use Text::Escape qw( escape );

  $Text::Escape::Escapes{ $escape_name } = \&escape_function;

  $escaped_value = escape( $escape_name, $unescaped_values );
  @escaped_values = escape( $escape_name, @unescaped_values );

=head1 Reference

=over 4

=item escape($escapes, $value or @values) : $escaped or @escaped

Escapes $value or @values with the escape or escapes specified. $escapes is split on whitespace to allow multiple escape styles. 

=item Text::Escape::names() : @defined_escapes

Returns a list of defined escape styles.

=item $Text::Escape::Escapes{ $escape_name } = \&escape_function

Add a new escape style and corresponding function.

=item escape('printable', $value) : $escaped or printable($value) : $escaped

=item escape('unprintable', $value) : $escaped or unprintable($value) : $escaped

Unix-style Backslash Escaping: Handles return, newline, tab, unprintable characters, and backslash itself.

=item escape('qprintable', $value) : $escaped or qprintable($value) : $escaped

=item escape('unqprintable', $value) : $escaped or unqprintable($value) : $escaped

Quoted Printable Escaping: Backslash escaping with quotes around empty, punctuated, & multiword values.  Note that this is *not* MIME quoted-printable encoding.


=item escape('quote', $value) : $escaped or quote($value) : $escaped

=item escape('unquote', $value) : $escaped or unquote($value) : $escaped

Double Quoting: Add and remove double quotes from around a string.


=item escape('quote_non_words', $value) : $escaped or quote_non_words($value) : $escaped

only quotes empty, punctuated, and multiword values  

=back

=head1 Caveats and Upcoming Changes


=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut