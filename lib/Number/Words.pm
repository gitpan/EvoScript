### Number::Words - Localizable words for numbers and ordinals
  # These routines were developed for english but with an eye towards eventual
  # internationalization; Romance languages shouldn't be a big problem.

### Interface
  # @ones, @tens, @thousands - Words to be localized
  # use_english();		
  # $value = aswords($number)
  # $nth = nth($integer)

### Usage Examples
  # aswords('45326') eq 'fourty five thousand three hundred twenty six'
  # nth('1')   eq '1st'
  # nth('45')  eq '45th'
  # nth('103') eq '103rd'

### Caveats and To Do:
  # Add a rank($number) function, eg: rank('102') eq 'one hundred and second'

### Copyright 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1997-11-17 Split into a subpackage; added use_language hooks. -Simon
  # 1997-06-23 Created original numbers package -JGB

package Number::Words;

use vars qw( $VERSION );
$VERSION = 1.00_1998_03_11;

# Export on demand: aswords nth
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( aswords nth );

# @ones, @tens, @thousands - Words to be localized
use vars qw( $negative $commasep $andsep @ones @tens @thousands @oneths );

use_english(); # english is the default (and currently only) language supported

# use_english();
  # set up english words
sub use_english {
  $negative = 'negative';
  $commasep = ', ';
  $andsep = ' and ';
  @ones = qw( zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen );
  @tens = qw( - ten twenty thirty fourty fifty sixty seventy eighty ninty hundred );
  @places = qw( - thousand million billion trillion quadrillion quintillion sextillion septillion octillion zillion gazillion );
  @oneths = qw( - first second third fourth fifth sixth seventh eighth ninth );
}

# $value = aswords($number);
sub aswords {
  my $number = shift;
  $number += 0;
  
  return $ones[0] if ($number == 0);
  return $negative . ' ' . aswords($number * -1) if ($number < 0);
  
  my $result = '';
  my $use_and = 0;
  my $place = 0;
  my @split_number = split('', $number);
  while (scalar @split_number) {
    my $one = pop(@split_number);
    my $ten = pop(@split_number) || 0;
    my $hundred = pop(@split_number) || 0;
    
    $one += $ten * 10 if ( $one + $ten * 10 < $#ones );
    
    my @words;
    push @words, $ones[ $hundred ], $tens[10]  if ( $hundred );
    push @words, $tens[ $ten ]                 if ( $ten );
    push @words, $ones[ $one ]                 if ( $one );
    
    my $clause = join(' ', @words);
    
    $clause .= ' ' . $places[ $place ] if ($clause and $place);
    my $separator = ($use_and ? $andsep : $commasep);
    if ($clause) {
      $clause .= $separator if ( $result );
      $result = $clause . $result;
      $use_and = ( $place ? 0 : 1 );
    }
    $place++;
  }
  return $result;
}

# $nth = nth($number);
sub nth {
  my $rank = shift;
  if ($rank =~ /\A1\Z|[^1]1\Z/) {
    return $rank . 'st';
  } elsif ($rank =~ /\A2\Z|[^2]2\Z/) {
    return $rank . 'nd';
  } elsif ($rank =~ /\A3\Z|[^3]3\Z/) {
    return $rank . 'rd';
  }
  return $rank . 'th';
}

1;

=pod

=head1 Number::Words

Words for numbers and localized ordinals

=head1 Synopsis

    use Number::Words qw( aswords nth );

    aswords('45326') eq 'fourty five thousand three hundred twenty six';
    nth('1')   eq '1st';
    nth('45')  eq '45th';
    nth('103') eq '103rd';

=head1 Reference

=over 4

=item aswords($number) : $value

Returns a textual equivalent of an integer.

=item nth($number) : $nth

Returns an integer with the correct suffix ( st, nd, rd, th );,.

=item @ones, @tens, @thousands

Package variables containing text to be associated with numbers.

=item use_english()

Select english as the language to display the words in (this is the only currently supported language, so this function doesn't actually do anything).

=back

=head1 Caveats and Upcoming Changes

These routines were developed for english but with an eye towards eventual
internationalization; Romance languages shouldn't be a big problem. Eventually we'd like to have a mechanism for registration of additional languages at runtime and a function: use_language( $lang ) to access them all.

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut