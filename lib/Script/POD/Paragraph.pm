package Script::POD::Paragraph;

$VERSION = 4.00_1998_03_06;

use Script::Sequence;
push @ISA, qw( Script::Sequence );

### Parsing

# $leader_regex = Script::HTML::Tag->stopregex();
sub stopregex { "\\n" }

# Script::POD::Paragraph->parse( $parser );
sub parse {
  my $package = shift;
  my $parser = shift;
  
  my $para = $parser->get_text('\\n');
  return unless $tag_text;
  
  $tag_text =~ s/\A\<(.*)\>\Z/$1/s;
  # warn "got tag '$tag_text'\n";
  
  my $tag = $package->new_from_string( $tag_text );
  die "unable to parse tag '$tag_text'\n" unless ($tag);
  
  $tag->add_to_parse_tree( $parser );
  
  return 1; # sucessful match
}
