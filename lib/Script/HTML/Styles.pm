### Script::HTML::Styles provides font-styling HTML tags

### <style name=> ... </style>
  # $html_text = stylize( $stylename, $contents );
  # $html_objects = decorate( $stylename, $contents );

### <font face=x size=n color=#cf> ... </font>
### <b> ... </b>
### <i> ... </i>

### Supported styleset options
  # 'bold' => {'dref'=>'optional', 'default'=>'0', 'required'=>'flag'},
  # 'italic' => {'dref'=>'optional', 'default'=>'0', 'required'=>'flag'},
  # 'tt' => {'dref'=>'optional', 'default'=>'0', 'required'=>'flag'},
  #
  # 'size' => {'dref'=>'optional', 'required'=>'number'},
  # 'big' => {'dref'=>'optional', 'default'=>'0', 'required'=>'flag'},
  # 'small' => {'dref'=>'optional', 'default'=>'0', 'required'=>'flag'},
  #
  # 'sans' => {'dref'=>'optional', 'default'=>'0', 'required'=>'flag'},
  #
  # 'red' => {'dref'=>'optional', 'default'=>'0', 'required'=>'flag'},
  # 'blue' => {'dref'=>'optional', 'default'=>'0', 'required'=>'flag'},
  # 'gray' => {'dref'=>'optional', 'default'=>'0', 'required'=>'flag'},
  # 'white' => {'dref'=>'optional', 'default'=>'0', 'required'=>'flag'},
  # 'lightgray' => {'dref'=>'optional', 'default'=>'0','required'=>'flag'},

### Caveats and things to do
  # Need to get back the flexibility of arbitrary style words.

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-05-20 Added support for monospace font face
  # 1998-03-06 Now using add_tag_class().
  # 1998-01-22 Moved IntraNetics style set definitions to iwae.cgi.
  # 1997-11-19 Fixed stylizing a literal with no options => !ref problem
  # 1997-11-15 Changed so stylize takes *only* the style name. -Simon
  # 1997-10-31 added group1-3   piglet
  # 1997-10-31 Refactored based on new Script::HTML::Tag superclass. -Simon
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-03-23 Added direct access function for non-tag use.
  # 1997-03-17 Updated to only produce a single <font>...</font> pair -Simon
  # 1997-03-16 Added blue, gray -Piglet
  # 1997-03-12 HTML is our friend. -Simon

### <style> ... </style>

package Script::HTML::Styles;

use Script::HTML::Tag;
push @ISA, qw( Script::HTML::Container );

sub subclass_name { 'style' };
Script::HTML::Styles->register_subclass_name;

use Text::Words qw( string2hash );
use Text::PropertyList qw( astext );
use Script::Literal;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( stylize );

use vars qw( %StyleSets );

%Arguments = (
  'name' => {'dref'=>'optional', 'required'=>'non_empty_string'},
);

sub interpret {
  my $tag = shift;
  return $tag->expand->interpret;
}

sub expand {
  my $tag = shift;
  return decorate($tag->get_args->{'name'}, $tag->interpret_contents)
}

# $html_text = stylize( $style, $contents );
sub stylize {
  decorate(shift, shift)->interpret;
}

# $html_objects = decorate( $style, $contents );
sub decorate {
  my ($stylename, $content) = @_;
  
  my $styleargs = { string2hash( $StyleSets{ $stylename } ) };
  # warn "style '$stylename' is " . astext( $styleargs );
  
  my (%font);
  $font{'face'} = 'Arial, Helvetica, Swiss' if (exists $styleargs->{'sans'}); 
  $font{'face'} = 'monospace' if (exists $styleargs->{'monospace'}); 
  
  $font{'size'} = $styleargs->{'size'}	if (exists $styleargs->{'size'} );
  $font{'size'} = '+1' 			if (exists $styleargs->{'big'}); 
  $font{'size'} = '-1'			if (exists $styleargs->{'small'}); 
  
  $font{'color'} = '#ff0000'		if (exists $styleargs->{'red'}); 
  $font{'color'} = '#000088'		if (exists $styleargs->{'blue'}); 
  $font{'color'} = '#ffffff'		if (exists $styleargs->{'white'}); 
  $font{'color'} = '#666666'		if (exists $styleargs->{'gray'}); 
  $font{'color'} = '#bbbbbb'		if (exists $styleargs->{'lightgray'}); 
  
  $content = Script::HTML::Styles::Bold->new( {}, $content)
		  			if (exists $styleargs->{'bold'});
  
  $content = Script::HTML::Styles::Italic->new( {}, $content)
		  			if (exists $styleargs->{'italic'});
  
  $content = Script::HTML::Styles::Teletype->new({}, $content)
		  			if (exists $styleargs->{'tt'});
  
  $content = Script::HTML::Styles::Font->new(\%font, $content)
  					if (scalar %font);
  
  $content = Script::Literal->new( $content ) unless (ref $content);
  
  return $content;
}

### HTML Style Tags
  # <font> ... </font>
  # <b> ... </b>
  # <em> ... </em>
  # <strong> ... </strong>
  # <i> ... </i>
  # <tt> ... </tt>

Script::HTML::Container->add_tag_classes(
  'font'   => 'Styles::Font',
  'b'      => 'Styles::Bold', 
  'em'     => 'Styles::Emphasis',
  'strong' => 'Styles::Strong',
  'i'      => 'Styles::Italic',
  'tt'     => 'Styles::Teletype',
);

1;