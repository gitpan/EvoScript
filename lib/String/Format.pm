### String::Format.pm - formatting routines for numbers, dates, and such like

### Change History
  # 1998-02-25 Version 1.00 - String::Format
  # 1998-02-25 Moved to String:: and @EXPORT_OK for CPAN distribution - jeremy
  # 1997-11-17 Created this package from code in Tags/Print etc. -Simon

package String::Format;

use vars qw( $VERSION );
$VERSION = 1.00;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( formatted );

use Carp;
use strict;

### Generic by-name interface

# %Formats - formatter function references by name
use vars qw( %Formats );

# String::Format::add( $name, $subroutine );
sub add ($$) { $Formats{ shift } = shift; }

# @defined_formats = String::Format::names();
sub names () { keys(%Formats); }

# Passthrough formatter
add('none', sub { return $_[0]; } );

# $formatted = formatted($format, $value); 
# @formatted = formatted($format, @values);
sub formatted ($@) {
  my ($format, @values) = @_;
  croak "formatted called with multiple values but in scalar context"
					      if ($#values > 0 && ! wantarray);
  
  my ($name, $args) = split(/\s+/, $format, 2);
  my $formatter = $Formats{ $name } or
	    croak "format called with undefined formatting style '$name'";
  
  # warn "formatting $name ($args) for values @values \n";
  
  my $value;
  foreach $value ( @values ) {
    $value = &$formatter( $value, $args );
  }
  # warn "formatted result values are @values \n";
  
  return wantarray ? @values : $values[0];
}

1;

=pod

=head1 String::Format

String::Format provides a by-name formatting function. Each formatter takes a single simple scalar value and some optional arguments to control the output, and returns another simple scalar.

=head1 Synopsis

    use String::Format( formatted );
    
    $String::Format::Formats{ $format_name } = \&formatting_function;
    
    $formatted_text = formatted( $format_name, $value );
    @formatted_text = formatted( $format_name, @values );
    $formatted_text = formatted( "$format_name $param", $value );

=head1 Reference

=over 4

=item formatted($format, $value or @values) : $formatted or @formatted

$format is split on whitespace. The first word is the format name; Remaining words will be passed to the formatting subroutine as arguments.

=item @defined_formats = String::Format::names();

Returns a list of defined formats.

=item $String::Format::Formats{ $format_name } = &\formatting_function

Facility for adding additional named formatting functions.

=back

=head1 This is Free Software

Copyright 1997, 1998 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut