### Script::HTML::Colors provides a named color registry for HTML macros

### Change History
  # 1998-01-25 Created. -Simon

package Script::HTML::Colors;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( color_by_name %Colors );

use vars qw( %Colors );

%Colors = (
  'bgcolor' => '#ffffff',
  'link' => '#bb0000',
  'alink' => '#ff0000',
  'vlink' => '#880088',
);

sub color_by_name {
  my $color_val = shift;
  return $Colors{ $color_val } || $color_val;
}

1;