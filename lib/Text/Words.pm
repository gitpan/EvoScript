### Text::Words.pm
  # Parse words and quoted phrases as simple lists and hashes, or write 'em out
  # 
  # Lists:	one "second item" 3 "four\nlines\nof\ntext"
  # Hashes:	key=value "undefined key" words="the cat in the hat" 
  # 
  # Use Text::PropertyList for complex data; use Text::Words for simple data

### Inteface.
  # $space_sparated_string = list2string( @words );
  # @words = string2list( $space_separated_phrases );
  # %hash = list2hash( @words );
  # @words = hash2list( %hash );
  # $string = hash2string( %hash );
  # %hash = string2hash( $string );

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Piglet   E.J. Evans (piglet@evolution.com)
  #
  # Based on Text::ParseWords by Hal Pomeranz (pomeranz@netcom.com)

### Change History
  # 1998-02-23 Fixed import syntax that was confusing Devel::PreProcessor.
  # 1997-11-10 Moved out of Evo:: namespace.
  # 1997-08-25 Text::Words package created, code refactored and extended.
  # 1997-01-25 Cleanup on splitwords (incl. removing single-quoting support)
  # 1997-01-24 Moved splitwords from IWAE::script to IWAE::dictionary.
  # 1997-01-13 Replaced Text::ParseWords with a local splitwords function.
  # 1996-11-?? Fixed problems in ParseWords where (! $text) chokes on "0"

package Text::Words;

use Carp;
use Text::Escape qw( quote_non_words );

use Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( string2list string2hash list2string list2hash hash2string hash2list );

# $space_sparated_string = list2string( @words );
sub list2string (@) {
  return join ' ', quote_non_words(@_);
}

# @words = string2list( $space_separated_phrases );
  # refactor this; for example, embedded quotes (a@"!a) shouldn't count.
sub string2list ($) {
  my $text = shift;
  
  carp "string2list called with a non-text argument, '$text'" if (ref $text);
  
  my $word = '';
  my @words;
  
  while ( defined $text and length $text ) {
    if ($text =~ s/\A(?: ([^\"\s\\]+) | \\(.) )//mx) {
      $word .= $1;
    } elsif ($text =~ s/\A"((?:[^\"\\]|\\.)*)"//mx) {
      $word .= $1;
    } elsif ($text =~ s/\A\s+//m){
      $word =~ s/\\(.)/$1/g;
      push(@words, $word);
      $word = '';
    } elsif ($text =~ s/\A"//) {
      carp "string2list found an unmatched quote at '$text'"; 
      return;
    } else {
      carp "string2list parse exception at '$text'";
      return;
    }
  }
  $word =~ s/\\(.)/$1/g;
  push(@words, $word);
  
  return @words;
}

# %hash = list2hash( @words );
sub list2hash {
  # sub list2hash (@) {
  my %hash;
  # %hash = map { (/\A(.*?)(?:\=(.*))?\Z/)[0,1] } @_
  foreach (@_) { 
    my ($key, $val) = /\A(.*?)(?:\=(.*))?\Z/;
    $hash{ $key } = $val;
  }
  
  return %hash;
}

# @words = hash2list( %hash );
sub hash2list (%) {
  my %hash = @_;
  return map { 
    quote_non_words($_) . '=' . quote_non_words($hash{$_}) 
  } keys %hash;
}

# $string = hash2string( %hash );
sub hash2string (%) {
  return list2string( hash2list( @_ ) );
}

# %hash = string2hash( $string );
sub string2hash ($) {
  return list2hash( string2list( shift ) );
}

1;

=pod

=head1 Text::Words

Text::Words parses words and quoted phrases as simple lists and hashes, and writes them out.

=head1 Synopsis

    $list = 'one "second item" 3 "four\nlines\nof\ntext"';
    @list = string2list( $list );
    $list[1] eq 'second_item';
    
    @list = ('hello', 'I move next march');
    $list = list2string( @list );
    $list eq 'hello "I move next march"';
  
    $hash = 'key=value "undefined key" words="the cat in the hat"';
    %hash = string2hash( $hash );
    $hash{'words'} eq 'the cat in the hat';
    $hash{'undefined_key'} eq undef;
    
    %hash = ( 'foo' => 'Animal Cities', 'bar' => 'Cheap' );
    $hash = hash2string( %hash );
    $hash = 'foo="Animal Cities" bar=Cheap';

=head1 Reference

=over 4

=item @words = string2list( $space_separated_phrases );

=item $space_sparated_string = list2string( @words );

Converts a space separated string of words to an array;


=item %hash = string2hash( $string );

=item $string = hash2string( %hash );

converts a space separated string of equal sign associated key value pairs into a simple hash.

=item %hash = list2hash( @words );

=item @words = hash2list( %hash );

converts an array of equal sign associated key value strings into a simple hash.

=back

=head1 Caveats and Upcoming Changes

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut