### Script::HTML::Escape 

### Usage
  # $value = html($value);
  # $value = qhtml($value);
  # $escaped = url( $value );
  # $unescaped = unurl( $value );

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-06-15 Added sub expand and changed htmltext_escape to match
  #            characters previously not supported -Dan
  # 1998-05-08 Changed ftp addr recognition to case-insensitive.
  # 1998-05-06 Fixed signed-char unpack used by url_escape, so high-bits are OK
  # 1998-05-05 Tweaked regexes for web address recognition in htmltext_escape()
  # 1998-03-13 Fixed typo in htmltext.
  # 1997-11-07 Added nonbreakingspace.
  # 1997-10-31 Added unurl. -Simon

package Script::HTML::Escape;

# Exports, Defines, and Overrides
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( qhtml html_escape url_escape nonbreakingspace );

$Text::Escape::Escapes{'qhtml'} = \&qhtml;
$Text::Escape::Escapes{'html'} = \&html_escape;
$Text::Escape::Escapes{'url'} = \&url_escape;
$Text::Escape::Escapes{'unurl'} = \&unurl;
$Text::Escape::Escapes{'htmltext'} =  \&htmltext_escape;

# $value = html_escape($value);
  # Escape potentially sensitive HTML characters
sub html_escape {
  my $value = shift;
  $value = '' unless (defined $value and length $value);
  
  $value =~ s/&/&amp;/g;
  $value =~ s/"/&quot;/g;
  $value =~ s/</&lt;/g;
  $value =~ s/>/&gt;/g;
    
  return $value;
}

# $value = htmltext_escape($value);
  # Format ascii for HTML
sub htmltext_escape {
  $_ = shift;
  
  # warn "htmltext $_\n";
  
  $_ = '' unless (defined $_ and length $_);
  
  # HTML escaping
  s/&/&amp;/g;
  s/"/&quot;/g;
  s/</&lt;/g;
  s/>/&gt;/g;
 

  # Matches websites, ftp sites, and email addresses
  s/((?: (?:www\.(?:\S+)\.(?:com|org|net|gov|edu|\w\w)) |
	(?:http:\/\/[\w\-\.\:]+) |
	(?:ftp:\/\/[\w\-\.\:]+) |
	(?:\S+\@[\w\-\.\:]+))(?:\S*)?)

	/expand($1)/gexi;
    
  # Paragraph and line breaks
  s/(\r\n|\r|\n)\s*\1/<p>/gs;
  s/(\r\n|\r|\n)/<br>/gs;

  # warn "-> $_\n";
  return $_;
}

# $link = expand($href);
sub expand {
  my $value = shift;
  my $href;

  if (substr($value, 0, 4) eq 'www.') {
    warn 'Adding http://';
    $href = 'http://' . $value;
  } elsif ($value =~ /(\w+\@\w+\.\w+)/) {
    warn 'Adding mailto:';
    $href = 'mailto:' . $value;
  } else {
    warn 'Adding nothing';
    $href = $value;
  }
  "<a href=\"" . "$href\">$value<\/a>"
}

# $value = qhtml($value);
  # Provide HTML escaping, and add double quotes if appropriate
sub qhtml {
  my $value = shift;
  return '""' unless (defined $value and length $value);
  
  $value =~ s/&/&amp;/g;
  $value =~ s/"/&quot;/g;
  $value =~ s/</&lt;/g;
  $value =~ s/>/&gt;/g;
  
  $value = '"' . $value . '"' if ($value =~ /[^\w\-\/\.\#\_]/);
  
  return $value;
}

# $escaped = url_escape( $value );
  # Escape characters for inclusion in a URL
sub url_escape {
  my $value = shift;
  $value =~ s/([\x00-\x20"#%;<>?=&{}|\\\\^~`\[\]\x7F-\xFF])/
  		sprintf("%%%02X", ord($1))/ge; 
  return $value;
}

# $unescaped = unurl( $value );
  # Escape characters for inclusion in a URL
sub unurl {
  my $value = shift;
  $value =~ s/\+/ /g;
  $value =~ s/%([\dA-Fa-f]{2})/chr(hex($1))/ge;
  return $value;
}

# $nbsp = nonbreakingspace()
sub nonbreakingspace { '&nbsp;' }
