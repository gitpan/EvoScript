### Number::Separated - Comma separated integers.

### Interface
  # Export on demand: separated
  # $commasep - comma separator
  # $value = separated($value)

### Usage Examples
  # separated('45326') eq '45,326'

### Copyright 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1997-11-24 Extracted from base Number package and exported back.

package Number::Separated;

use vars qw( $VERSION );
$VERSION = 1.00_1998_03_11;

# Export on demand: separated
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( separated );

# $commasep - comma separator
use vars qw( $commasep );
$commasep = ',';

# $value = separated($value)
  # Comma-separated integers - doesn't handle floats yet.
sub separated {
  my $nval = shift;
  return reverse join($commasep, reverse($nval) =~ m/(\d{1,3})/g);
}

1;

=pod

=head1 Number::Separated

Comma separated integers

=head1 Synopsis

    use Number::Separated qw( separated );

    separated( 987654321 ) eq "987,654,321";

=head1 Reference

=over 4

=item separated($value) : $comma_sep_value

Returns $value with commas appropriately placed.

=item $commasep

Package variable containing a delimiter for separation.

=back

=head1 Caveats and Upcoming Changes

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut