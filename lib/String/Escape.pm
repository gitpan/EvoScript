### String::Escape - backslash, quoting, and general escape/unescape functions
  # 
  # We provide a by-name escaping function and a collection of simple escapers.
  # Each escaper takes a single simple scalar argument and returns its 
  # escaped (or unescaped) equivalent.

### Generic by-name interface
  # %Escapes - escaper function references by name
  # String::Escape::add( $name, $subroutine );
  # @defined_escapes = String::Escape::names();
  # $escaped = escape($escapes, $value); 
  # @escaped = escape($escapes, @values);

### Unix-style Backslash Escaping: printable(), unprintable()

### Quoted Escaping: qescape(), unqescape()

### Double Quoting: quote(), unquote(), quote_non_words()

### Change History
  # 1998-03-16 Avoid modify-constant warnings by using lexical rather than $_
  # 1998-02-25 Version 1.00 - String::Escape
  # 1998-02-25 Moved to String:: and @EXPORT_OK for CPAN distribution - jeremy
  # 1998-02-19 Started removal of sub add calls throughout Evo::Script
  # 1997-10-28 Created generic by-name interface; renamed printable
  # 1997-10-21 Altered quote_non_words algorithm to accept '-', '/', and '.'
  # 1997-08-17 Created this package from functions in dictionary.pm. -Simon

package String::Escape;

use vars qw( $VERSION );
$VERSION = 1.00;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( escape printable unprintable qprintable unqprintable quote_non_words );

use Carp;
use strict;

### Generic by-name interface

# %Escapes - escaper function references by name
use vars qw( %Escapes );

$Escapes{'none'} = sub { return $_[0]; };

$Escapes{'printable'} = \&printable;
$Escapes{'unprintable'} = \&unprintable;
$Escapes{'qprintable'} = \&qprintable;
$Escapes{'unqprintable'} = \&unqprintable;
$Escapes{'quote'} = \&quote;
$Escapes{'unquote'} = \&unquote;
$Escapes{'quote_non_words'} = \&quote_non_words;

# String::Escape::add( $name, $subroutine );
sub add ($$) { $Escapes{ shift(@_) } = shift(@_); }

# @defined_escapes = String::Escape::names();
sub names () { keys(%Escapes); }

# $escaped = escape($escapes, $value); 
# @escaped = escape($escapes, @values);
sub escape ($@) {
  my ($escapes, @values) = @_;
  
  croak "escape called with multiple values but in scalar context"
					      if ($#values > 0 && ! wantarray);
  
  my ($value, $name);
  foreach $value ( @values ) {
    foreach $name ( split(/\s+/, $escapes) ) {
      my $escaper = $Escapes{ $name } or 
	    croak "escape called with undefined escaping style '$name'";
      $value = &$escaper( $value );
    }
  }
  
  return wantarray ? @values : $values[0];
}

### Unix-style Backslash Escaping: Handles return, newline, tab, unprintable characters, and backslash itself.

sub printable ($) {
  my $value = shift;
  $value = '' unless (defined $value);
  $value =~ s/\\/\\\\/g;
  $value =~ s/\r/\\r/g;
  $value =~ s/\n/\\n/g;
  $value =~ s/\t/\\t/g;
  $value =~ s/([\x00-\x1f\x7F-\xFF])/'\\'.unpack("H2", $1)/gxe;
  return $value;
}

sub unprintable ($) {
  my $value = shift;
  $value = '' unless (defined $value);
  $value =~ s/\\\\/\\/g;
  $value =~ s/\\r/\r/g;
  $value =~ s/\\n/\n/g;
  $value =~ s/\\t/\t/g;
  $value =~ s/\\"/\"/g;
  $value =~ s/\\([\da-fA-F][\da-fA-F])/pack("H2", $1)/geo;
  return $value;
}

### Quoted Printable Escaping: Backslash escaping with quotes around empty, punctuated, & multiword values.  Note that this is *not* MIME quoted-printable encoding. 

sub qprintable ($) {
  my $value = shift;
  $value = '' unless (defined $value);
  $value =~ s/\\/\\\\/g;
  $value =~ s/\"/\\"/g;
  $value =~ s/\r/\\r/g;
  $value =~ s/\n/\\n/g;
  $value =~ s/\t/\\t/g;
  $value =~ s/([\x00-\x1f\x7F-\xFF])/'\\'.unpack("H2", $1)/gxe;
  $value = '"'.$value.'"' if (/[^\w\-\/\.\#\_]/ or ! length $value);
  return $value;
}

sub unqprintable ($) {
  my $value = shift;
  $value = '' unless (defined $value);
  $value =~ s/\A\"(.*)\"\Z/$1/;
  $value =~ s/\\\\/\\/g;
  $value =~ s/\\"/\"/g;
  $value =~ s/\\r/\r/g;
  $value =~ s/\\n/\n/g;
  $value =~ s/\\t/\t/g;
  $value =~ s/\\([\da-fA-F][\da-fA-F])/pack("H2", $1)/geo;
  return $value;
}

### Double Quoting: Add and remove double quotes from around a string. quote_non_words only quotes empty, punctuated, and multiword values

sub quote ($) {
  return '"' . (shift) . '"';
}

sub quote_non_words ($) {
  my $value = shift;
  $value = '"'.$value.'"' if (/[^\w\-\/\.\#\_]/ or ! length $value);
  return $value;
}

sub unquote ($) {
  my $value = shift;
  $value =~ s/\A\"(.*)\"\Z/$1/;
  return $value;
}

1;

=pod

=head1 String::Escape

String::Escape implements backslash, quoting, and general escape/unescape functions. It also provides a calling and registration mechanism for additional escaping functions. If you're bright, it's the only interface for escaping that you'll ever need.

=head1 Synopsis

  use String::Escape qw( escape );

  $String::Escape::Escapes{ $escape_name } = \&escape_function;

  $escaped_value = escape( $escape_name, $unescaped_values );
  @escaped_values = escape( $escape_name, @unescaped_values );

=head1 Reference

=over 4

=item escape($escapes, $value or @values) : $escaped or @escaped

Escapes $value or @values with the escape or escapes specified. $escapes is split on whitespace to allow multiple escape styles. 

=item String::Escape::names() : @defined_escapes

Returns a list of defined escape styles.

=item $String::Escape::Escapes{ $escape_name } = \&escape_function

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