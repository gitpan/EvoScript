### Text::Format.pm - formatting routines for numbers, dates, and such like
  # 
  # We provide a by-name formatting function and some basic type handlers.
  # Each formatter takes a single simple scalar value and some optional
  # arguments to control the output, and returns another simple scalar.

### Change History
  # 1997-11-17 Created this package from code in Tags/Print etc. -Simon

package Text::Format;

use Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( formatted );

use Carp;
use strict;

### Generic by-name interface

# %Formats - formatter function references by name
use vars qw( %Formats );

# Text::Format::add( $name, $subroutine );
sub add ($$) {
  my $name = shift;
  my $subroutine = shift;
  $Formats{ $name } = $subroutine;
}

# @defined_formats = Text::Format::names();
sub names () {
  return keys(%Formats);
}

# $formatted = formatted($format, $value); 
# @formatted = formatted($format, @values);
sub formatted ($@) {
  my $format = shift;
  my ($name, $args) = split(/\s+/, $format, 2);
  
  # warn "formatting $name $args \n";
  
  my @values = @_;
  croak "format called with multiple values but in scalar context"
					      if ($#values > 0 && ! wantarray);
  # warn "format values are @values \n";
  
  my $formatter = $Formats{ $name };
  croak "format called with undefined formatting style '$name'" 
						unless( $formatter );
  
  my $value;
  foreach $value ( @values ) {
    $value = &$formatter( $value, $args );
  }
  # warn "now values are @values \n";
  
  return wantarray ? @values : $values[0];
}

1;

=pod

=head1 Text::Format

Text::Format provides a by-name formatting function and some basic type handlers. Each formatter takes a single simple scalar value and some option. arguments to control the output, and returns another simple scalar.

=head1 Synopsis

    use Text::Format( formatted );
    
    $Text::Format::Formats{ $format_name } = \&formatting_function;
    
    $formatted_text = formatted( $format_name, $value );
    @formatted_text = formatted( $format_name, @values );

=head1 Reference

=over 4

=item formatted($format, $value or @values) : $formatted or @formatted

$format is split on whitespace. The first word is the format name; Remaining words will be passed to the formatting subroutine as arguments.

=item @defined_formats = Text::Format::names();

Returns a list of defined formats.

=item $Text::Format::Formats{ $format_name } = &\formatting_function

Facility for adding additional named formatting functions.

=back

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut