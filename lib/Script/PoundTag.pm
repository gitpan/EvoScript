### Script::PoundTags are square brackets around a pound, method, and args.

### Change History
  # 1998-04-07 Added DRef-only syntax for non-method based invokation.
  # 1998-03-17 Created. -Simon

package Script::PoundTag;

$VERSION = 4.00_1998_03_17;

use Script::Element;
@ISA = qw( Script::Element );

use Carp;
use Data::DRef;
use Err::Debug;
use Text::Words qw( string2list );
use Text::Escape qw( qprintable );
use Text::PropertyList qw( astext );

### Parser Syntax Class

# $leader_regex = Script::PoundTag->stopregex();
sub stopregex () { '\[(?:\-)\#'; }

# $source_refex = Script::PoundTag->parse_regex();
sub parse_regex () { '\\[(?:\\-)?\\#((?:[^\\[\\]\\\\]|\\\\.)*)\\]' };

# Script::PoundTag->parse( $parser );
sub parse {
  my $package = shift;
  my $parser = shift;
  
  my $text = $parser->get_text( $package->parse_regex ) 
	    or return; # nothing to match
  
  my $tag = $package->new_from_source( $text )
	    or die "$package: unable to parse '$text'\n";
  
  # sucessful match
  $tag->add_to_parse_tree( $parser );
  return 1; 
}

### Source Format

# $tag = Script::PoundTag->new_from_source( $source_string );
sub new_from_source {
  my $package = shift;
  my $tag_text = shift;
  
  $tag_text =~ s/\A\[(.*)\]\Z/$1/s;
  my $silently = ( $tag_text =~ s/\A\-// );
  my ($dref, $method, @args) = string2list( $tag_text );
  $dref =~ s/\A#//;
  
  $package->new($dref, $silently, $method, @args);
}

# $source_string = $tag->source()
sub source {
  my $tag = shift;
  
  '[' . 
    ( $tag->{'silently'} ? '-' : '' ) . 
    '#' . $tag->{'dref'} . 
    list2string($tag->{'method'},  @{$tag->{'args'}}) . 
  ']';
}

### Instantiation

# $tag = Script::PoundTag->new($dref, $silent_flag)
# $tag = Script::PoundTag->new($dref, $silent_flag, $method, @args)
sub new {
  my $package = shift;
  my ($dref, $silent_flag, $method, @args) = @_;
  my $tag = {
    'dref' => $dref,
    'method' => $method,
    'silent' => $silently,
    'args' => [ @args ],
  };
  bless $tag, $package;
}

### Interpretation

# $tag->interpret();
sub interpret {
  my $tag = shift;
  
  my $base = getData( $tag->{'dref'} );
  
  my $method = $tag->{'method'};
  
  my @args = @{$tag->{'args'}};
  foreach ( @args ) { $_ = getData( $_ ) if ( s/^\#// ) }
  
  my $value = $method ? $base->$method( @args ) : $base;
  
  return $tag->{'silently'} ? '' : $value;
}

1;

__END__

=head1 Script::PoundTag

Simple square-bracketed dynamic element for DRef access.

Tag syntax for object-method calls; hyphen for silence, object DRef first, then method name and any arguments for the call.

  [#record status]
  [-#request redirect_and_end http://www.eff.org]
  [#my.record display name.first]
  [-#my.record save]

=head2 Parser Syntax Class

=over 4

=item Script::PoundTag->stopregex : $leader_regex

=item Script::PoundTag->parse( $parser )

=back


=head2 Instantiation

=over 4

=item Script::PoundTag->new_from_string($name_and_args_without_brackets) : $tag

=back


=head2 Output

=over 4

=item $tag->description : $readable_object_info

=item $tag->source : $scripttext

=back


=head2 Argument Definition and Interpretation

=over 4

=item $tag->interpret

=back

=head1 Caveats and Things Undone

This package is very poorly named.

Should be better integrated with the Script::PoundTag class.

=cut
