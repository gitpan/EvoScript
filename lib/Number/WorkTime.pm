### Number::WorkTime - Minutes as hours and workdays.

### Interface
  # Export on demand: ashours
  # $minutesperday - minutes per work day
  # $value = ashours($value)

### Usage Examples
  # ashours('120') eq '2hrs'
  # ashours('420') eq '1wkday'

### Copyright 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1997-12-03 Duplicated from Number::Separated package.

package Number::WorkTime;

use vars qw( $VERSION );
$VERSION = 1.00_1998_03_11;

# Export on demand: ashours
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( ashours );

# $minutesperday - minutes in a standard work day
use vars qw( $minutesperday );
$minutesperday = 420;

# $value = ashours($value)
  # Minutes -> workdays or hours.
sub ashours {
  my $m = shift;
  return '' unless $m;
  my @clauses;
  
  my $wd = int($m / $minutesperday);
  $m -= $minutesperday * $wd;
  push @clauses, $wd . ' wkday' . ( $wd == 1 ? '' : 's') if $wd;
  
  my $h = int($m / 60);
  $m -= 60 * $h;
  push @clauses, $h . ' hr' . ( $h == 1 ? '' : 's') if $h;
  
  push @clauses, $m . ' min' if $m;
  return join(', ', @clauses);
}

1;

=pod

=head1 Number::WorkTime

Minutes as hours and workdays.

=head1 Synopsis

  use Number::WorkTime qw( ashours );

  ashours('120') eq '2hrs'
  ashours('420') eq '1wkday'

=head1 Reference

=over 4

=item ashours( $minutes ) : $value

Returns a value for $minutes with the proper annotation ( min, hr, wkday ).

=item $minutesperday

Package variable containing minutes in a standard work day. Defaults to 480 minutes (8 hours).

=back

=head1 Caveats and Upcoming Changes

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut