### Number::Bytes provides formatting for byte and bit counts.

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-23 Fixed typo.
  # 1997-11-17 Split this into several packages, added bit_format. -Simon
  # 1997-06-23 Created original numbers package -JGB

package Number::Bytes;

use vars qw( $VERSION );
$VERSION = 1.00_1998_03_23;

# Export on demand: byte_format bit_format
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( byte_format bit_format );

# @byte_scales, @bit_scales - text labels for powers of two-to-the-tenth
use vars qw( @byte_scales @bit_scales );
@byte_scales = qw( Bytes KB MB GB TB );
@bit_scales = qw( bits Kb Mb Gb Tb );

# $value = byte_format($number)
  # Show no more than one decimal place, followed by scale label
sub byte_format {
  my $value = shift;
  my $options = shift;
  
  my $scale;
  foreach $scale (@byte_scales) {
    return ( (int($value * 10 + 0.5)/10) . $scale ) if ($value < 1024); 
    $value = $value / 1024;
  }
  warn "huge value";
}

# $value = bit_format($number)
  # Show no more than one decimal place, followed by scale label
sub bit_format {
  my $value = shift;
  my $options = shift;
  
  return byte_format($value / 8) if ( $options =~ /bytes/i );
  
  my $scale;
  foreach $scale (@bit_scales) {
    return ( (int($value * 10 + 0.5)/10) . $scale ) if ($value < 1024); 
    $value = $value / 1024;
  }
  warn "huge value";
}

1;

=pod

=head1 Number::Bytes 

Formatting for byte and bit counts.

=head1 Synopsis

    use Number::Bytes qw( byte_format bit_format );

    byte_format( 27 ) eq '27Bytes'
    byte_format( 1024 ) eq '1KB'
    byte_format( 1536 ) eq '1.5KB'

    bit_format( 1024 ) eq '1Kb'
    bit_format( 1024, 'bytes' ) eq '128Bytes'


=head1 Reference

=over 4

=item byte_format( $bytes ) : $value

Returns an annotated value for $bytes.

=item bit_format( $bits ) or bit_format( $bits, 'bytes' ) : $value

Returns an annotated bit value for the value supplied or, with a second argument 'bytes', returns an annotated byte count of the bit value.

=item @byte_scales, @bit_scales 

Package variables conatining text labels for powers of two-to-the-tenth.

=back

=head1 Caveats and Upcoming Changes

Some additional output flexibility might be added, but no major changes are anticipated for this module.

=head1 This is Free Software

Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut
