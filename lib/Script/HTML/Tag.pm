### Script::HTML::Tag includes standalone and container tags for HTML.

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-07 Parser streamlining.
  # 1998-03-12 Changed countof to scalar %{} in new.  -P
  # 1998-03-06 Added add_tag_class methods.
  # 1998-02-24 Added generic support for unknown HTML tags.
  # 1997-12-11 Now using Class::NamedFactory instead of our own registry. -S.
  # 1997-12-09 Added call to default_options in Tag->new.  -Piglet
  # 1997-10-?? Refactored along with Script::Tags.  -Simon

package Script::HTML::Tag;

$VERSION = 4.00_04;

use Script::HTML::Escape;
use Script::Parser;
use Text::Words qw( string2list );

use Script::Element;
push @ISA, qw( Script::Element );

use Carp;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( html_tag );

### Subclass Information

# Uses Class::NamedFactory for subclass names

use Class::NamedFactory;
push @ISA, qw( Class::NamedFactory );
use vars qw( %Tags );
sub subclasses_by_name { \%Tags; }

# $classname = $package->subclass_by_name( $name );
  # override the default behaviour to force lowercase and handle closers
sub subclass_by_name {
  my $package = shift;
  my $name = lc( shift );
  
  if ( $name =~ s/\A\/// ) {
    my $subclass = Script::HTML::Tag->subclass_by_name( $name );
    return 'Script::HTML::Closer' 
	      if ( $subclass and $subclass->isa('Script::HTML::Container') );
  }
  
  return $package->SUPER::subclass_by_name( $name );
}

# Script::HTML::Tag->add_tag_classes( $tagname, $classname, ... );
sub add_tag_classes {
  my $class = shift;
  
  while ( scalar @_ ) {
    my ($tagname, $classname) = ( shift, shift );
    $classname = 'Script::HTML::' . $classname;
    
    eval "package $classname; \@ISA = qw( $class ); " . 
	 "sub subclass_name {'$tagname'}; $classname->register_subclass_name;";
  }
}

### Instantiation

# $html_object = html_tag( $name; $args; @contents );
sub html_tag ($;@) {
  my $name = shift;
  
  my $subclass = Script::HTML::Tag->subclass_by_name( $name );
  carp "use of undefined tag '$name'" unless ($subclass);
  
  return $subclass->new_with_name( $name, @_ );
}

# $tag = Script::HTML::Tag->new_with_name( $name, @_ );
sub new_with_name {
  my $package = shift;
  my $name = shift;
  $package->new( @_ );
}

# $tag = Script::HTML::Tag->new( $args );
sub new {
  my $package = shift;
  my $args = shift || {};
  
  carp "Too many arguments to new '$name'  Script::HTML::Tag \n" . 
	"(perhaps you were expecting a Container?)" if ( scalar @_ );
  
  my $tag = {
    'name' => lc( $package->subclass_name ),
    'args' => $args,
  };
  
  bless $tag, $package;
  $tag->default_options if UNIVERSAL::can($tag, 'default_options') 
  			and ! scalar(%{$tag->{'args'}});
  $tag->init if UNIVERSAL::can($tag, 'init');
  return $tag;
}

### Parsing

# $leader_regex = Script::HTML::Tag->stopregex();
sub stopregex { '\<'; }

# $source_regex = Script::Tag->parse_regex();
sub parse_regex () { '\\<((?:[^\\<\\>\\\\]|\\\\.)+)\\>' };

# Script::HTML::Tag->parse( $parser );
sub parse {
  my ($package, $parser) = @_;
  
  my $source = $parser->get_text( $package->parse_regex ) 
		or return; # nothing to match
  
  my $element = $package->new_from_source( $source )
		or die "$package: unable to parse '$source'\n";
  
  $element->add_to_parse_tree( $parser );
  return 1; # sucessful match
}

### Source Format

# $tag = Script::HTML::Tag->new_from_source( $source_string );
sub new_from_source {
  my ($package, $text) = @_;
  
  $text =~ s/\A\<(.*)\>\Z/$1/s;
  my($name, @args) = string2list( $text );
  
  my $subclass = $package->subclass_by_name($name) || 'Script::HTML::Generic';
  
  my $args;
  foreach ( @args ) {
    my ($key, $sep, $val) = (/\A(.*?)(?:(\=)(.*))?\Z/);
    $args->{ lc($key) } = $val;
  }
  
  return $subclass->new_with_name( $name, $args ? $args : () );
}

# $html_source_string = $tag->source()
sub source {
  my $tag = shift;
  
  return $tag->open_tag();
}

# $html_tag_string = $tag->open_tag();
sub open_tag {
  my $tag = shift;
  
  my $args = $tag->get_args;
  
  my $attribs = join '', map { ' ' . qhtml($_) . 
	    (defined $args->{$_} ? '='.qhtml($args->{$_}) : '') } keys %$args;
  
  return '<' . $tag->{'name'} . $attribs . '>';
}

### Dynamic Output

# $html = $tag->interpret()
sub interpret {
  my $tag = shift;
  
  return $tag->open_tag();
}

# %$args = $tag->get_args();
  # Used as subclass hook.
sub get_args {
  my $tag = shift;
  
  return { %{$tag->{'args'}} };
}

### HTML Container are Tags that container others, written <name k=v>...</name>

package Script::HTML::Container;

push @ISA, qw( Script::HTML::Tag );

use Script::Sequence;
push @ISA, qw( Script::Sequence );

# $tag = Script::HTML::Container::SubClass->new( $args, @contents );
sub new {
  my $package = shift;
  my $tag = $package->SUPER::new( shift );
  
  foreach (@_) { $tag->add( $_ ); }
  
  return $tag;
}

# $html = $tag->interpret()
sub interpret {
  my $tag = shift;
  
  $tag->SUPER::interpret . $tag->interpret_contents . $tag->closer;
}

# $html = $tag->source()
sub source {
  my $tag = shift;
  
  $tag->SUPER::source() . $tag->source_contents() . $tag->closer();
}

# $closetagtext = $tag->closer();
sub closer {
  my $tag = shift;
  return '</' . $tag->{'name'} . '>';
}

# $container->add_to_parse_tree($parser);
  # When we've been parsed, we make ourselves the parser's current item;
  # a following closer tag, defined below, will hopefully mark our expiration.
sub add_to_parse_tree {
  my $container = shift;
  my $parser = shift;
  $parser->current->add($container);
  $parser->push($container);
}

### An Script::Closer is the dangly bit at the end of a container </exmpl>

package Script::HTML::Closer;

push @ISA, qw( Script::HTML::Tag );

use Carp;

#!# Script::Parser->add_syntax( Script::Closer );
  # Should make this an independant syntax class somehow; currently we're 
  # specified explicitly in Script::HTML::Tag->subclass_by_name( $tag_name );

# $tag = Script::HTML::Closer->new_with_name( $name );
sub new_with_name {
  my $package = shift;
  my $name = shift;
  
  carp "Too many arguments to new '$name'  Script::HTML::Closer \n" . 
	"(perhaps you were expecting a normal tag?)" if ( scalar @_ );
  
  my $tag = { 'name' => lc( $name ) };
  
  bless $tag, $package;
}

# $closer->add_to_parse_tree($parser);
  # We don't actually add ourselves to the parse tree in this case; instead,
  # we pop our matching container off of the parser stack.
sub add_to_parse_tree {
  my $closer = shift;
  my $parser = shift;
  
  my $name = lc( $closer->{'name'} );
  $name =~ s/\A\///;
  
  # Unshift as necessary to find matching container
  my $opener_class = $closer->subclass_by_name( $name );
  $parser->pop( $opener_class );
}

### HTML::Generic handles html tags that aren't defined elsewhere.

package Script::HTML::Generic;

push @ISA, qw( Script::HTML::Tag );

sub subclass_name { '' };

# $tag = Script::HTML::Generic->new_with_name( $name );
sub new_with_name {
  my $package = shift;
  my $name = shift;
  
  my $tag = $package->SUPER::new( @_ );
  $tag->{'name'} = $name;
  
  return $tag;
}

1;

__END__

=head1 Script::HTML::Tag

HTML Tags are objects with names and attributes, written <name key=value>.

=over 4

=item Uses Class::NamedFactory for subclass names

=item Script::HTML::Tag->add_tag_classes( $tagname, $classname, ... )

=back


=head2 Instantiation

=over 4

=item html_tag( $name; $args; @contents ) : $html_object

=item Script::HTML::Tag->new_with_name( $name, @_ ) : $tag

=item Script::HTML::Tag->new( $args ) : $tag

=item $package->subclass_by_name( $name ) : $classname

=back


=head2 Parsing

=over 4

=item Script::HTML::Tag->stopregex : $leader_regex

=item Script::HTML::Tag->parse( $parser )

=item Script::HTML::Tag->new_from_source($name_and_args_without_brackets) : $tag

=back


=head2 Output Generation

=over 4

=item $tag->interpret : $html

=item $tag->source : $html

=item $tag->open_tag : $htmltag

=item $tag->get_args : %$args

=back


=head2 HTML Container are Tags that container others, written <name k=v>...</name>


=head1 Script::HTML::Container

=over 4

=item Script::HTML::Container::SubClass->new( $args, @contents ) : $tag

=item $tag->interpret : $html

=item $tag->source : $html

=item $tag->closer : $closetagtext

=back


=head2 An Script::Closer is the dangly bit at the end of a container [/exmpl]


=head1 Script::HTML::Closer

=over 4

=item Script::HTML::Closer->new_with_name( $name ) : $tag

=item $closer->add_to_parse_tree($parser)

=back


=head2 HTML::Generic handles html tags that aren't defined elsewhere.


=head1 Script::HTML::Generic

=over 4

=item Script::HTML::Generic->new_with_name( $name ) : $tag

=back

=head1 Caveats and Things To Do



=cut

