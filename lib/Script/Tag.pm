### Script::Tag is the superclass for square bracketed dynamic tags.

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-03 Parser streamlining.
  # 1998-03-04 Changed get_arg failures from die to croak.
  # 1998-03-03 Replaced $r->class with ref($r)
  # 1998-01-30 s/each %$key_def/foreach keys/ to fix re-entry problem.
  # 1997-09-** Forked and refactored. -Simon

package Script::Tag;

$VERSION = 4.00_1998_03_03;

use Script::Element;
@ISA = qw( Script::Element );

use Carp;
use Err::Debug;

use Data::DRef;
use Text::Words qw( string2list string2hash hash2string );

### Parser Syntax Class

# $leader_regex = Script::Tag->stopregex();
sub stopregex { '\['; }

# $source_refex = Script::Tag->parse_regex();
sub parse_regex () { '\\[((?:[^\\[\\]\\\\]|\\\\.)*)\\]' };

# Script::Tag->parse( $parser );
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

# $tag = Script::Tag->new_from_source($source_string);
sub new_from_source {
  my ($package, $text) = @_;
  
  $text =~ s/\A\[(.*)\]\Z/$1/s;
  my ($name, @args) = string2list( $text );
  
  my $subclass = $package->subclass_by_name( $name )
  		or warn "use of undefined tag '$name'\n", return;
  
  my %args;
  foreach ( @args ) {
    my ($key, $sep, $val) = (/\A(.*?)(?:(\=)(.*))?\Z/);
    $args{ lc($key) } = $val;
  }
  
  my $tag = $subclass->new(%args);
  $tag->{'name'} = $name;
  # $tag->check_tag_args();
  return $tag;
}

# $scripttext = $tag->source();
sub source {
  my $tag = shift;
  return $tag->open_tag();
}

# $htmltag = $tag->open_tag();
sub open_tag {
  my $tag = shift;
  '[' . $tag->{'name'} . 
	( %{ $tag->{'args'} } ? ' ' . hash2string($tag->{'args'}) : '' ) . ']';
}

### Instantiation

# $tag = Script::*TagClass*->new( %args );
sub new {
  my $package = shift;
  my $tag = { 'name' => $package->subclass_name, 'args' => { @_ } };
  bless $tag, $package;
}

# Uses Class::NamedFactory 
use Class::NamedFactory;
push @ISA, qw( Class::NamedFactory );

# %Tags: Hash of known concrete subclasses by tag name
use vars qw( %Tags );
sub subclasses_by_name { \%Tags; }

# $classname = $package->subclass_by_name( $name );
  # override the default behaviour to force lowercase and handle closers
sub subclass_by_name {
  my $package = shift;
  my $name = lc( shift );
  return 'Script::Closer' if ( $name =~ /\A\/\w/ );
  return $package->SUPER::subclass_by_name( $name );
}

### Argument Definition and Interpretation

# $argdef_hash_ref = $tag->arg_defn();
sub arg_defn {
  my $tag = shift;
  my $varname = ref($tag) . '::ArgumentDefinitions';
  my $args = \%$varname;
  return $args;
}

# $tag->check_tag_args();
sub check_tag_args {
  my $tag = shift;
  my $arg_def = $tag->arg_defn;
  my $args = $tag->{'args'};
  # Parse Error: unsupported arguments
  foreach $key (keys %$args) {
    warn "unsupported argument $key=$args->{$key}" unless ($arg_def->{$key});
  }
}

# $args = $tag->get_args();  
sub get_args {
  my $tag = shift;
  
  my $result = {};
  my $key_def = $tag->arg_defn;
  
  my $key;
  foreach $key ( keys %$key_def ) {
    my $parse = $key_def->{ $key };
    my $value = $tag->{'args'}->{$key};
    
    $value = 1 if ( $parse->{'required'} eq 'flag' and 
		    not defined $value and exists $tag->{'args'}->{$key} );
    
    my $dref_style = $parse->{'dref'} || '';
    
    if (! defined $value or ! $dref_style or $dref_style eq 'no') {
      # do nothing
    } 
    elsif ($dref_style eq 'target') {
      $value =~ s/^\#//;
    } 
    elsif ($dref_style eq 'optional') {
      $value = getData( $value ) if ( $value =~ s/^\#// );
    } 
    elsif ($dref_style eq 'yes') {
      $value =~ s/^\#//;
      $value = getData( $value );
    } 
    else {
      warn "unknown dreferencing method: '$dref_style' in $tag\n";
    }
    
    $value = $parse->{'default'} 
	  	    if (! defined $value and exists $parse->{'default'});
    
    my $required = $parse->{'required'} || '';
    if (!$required || $required eq 'anything') {
      # do nothing
    } 
    elsif ($required eq 'flag') {
      $value = ( $value and $value !~ /no/i ) ? 1 : 0;
    } 
    elsif ($required eq 'number_or_nothing') {
      croak "argument '$key' is not a number in $tag\n"
		      unless ((not defined($value)) or $value == ($value - 0));
    } 
    elsif ($required eq 'number') {
      $value = 0 unless (defined $value and length $value);
      croak "argument '$key' is not a number in $tag\n"
					  unless ($value == ($value - 0));
    } 
    elsif ($required eq 'string_or_nothing') {
      $value = '' unless (defined $value);
      croak "argument '$key' is a reference in $tag\n" unless (! ref $value);
    } 
    elsif ($required eq 'non_empty_string') {
      croak "argument '$key' is empty in $tag\n"
				    unless (! ref $value && length($value) );
    }
    elsif ($required =~ /^oneof_or_nothing/i) {
      $value ||= '';
      my @values = string2list($required);
      shift @values; # throw away the one_of... string
      croak "argument '$key' is '$value', not one of '$required'"
			  unless (! $value or grep ($value eq $_, @values));
    } 
    elsif ($required =~ /^oneof/i) {
      my @values = string2list($required);
      shift @values; # throw away the one_of... string
      croak "argument '$key' is '$value', not one of '$required'" 
				    unless ( grep(($_ eq $value), @values) );
    } 
    elsif ($required eq 'hash_ref') {
      croak "argument '$key' is  '$value', not a hash"
				      unless (UNIVERSAL::isa($value, 'HASH'));
    } 
    elsif ($required eq 'hash') {
      $value = string2hash($value) if ($value && ! ref $value);
      croak "argument '$key' is '$value', not a hash"
				      unless (UNIVERSAL::isa($value, 'HASH') );
    } 
    elsif ($required eq 'hash_or_nothing') {
      $value = string2hash($value) if (defined $value && ! ref $value);
      croak "argument '$key' is '$value', not a hash"
		  if (defined $value and ! UNIVERSAL::isa($value, 'HASH'));
    } 
    elsif ($required eq 'list_ref') {
      croak "argument '$key' is not a list"
      				unless ( UNIVERSAL::isa($value, 'ARRAY') );
    } 
    elsif ($required eq 'list') {
      $value = [ string2list($value) ] if (defined $value && ! ref $value);
      croak "argument '$key' is not a list"
      			unless ( UNIVERSAL::isa($value, 'ARRAY') );
    } 
    elsif ($required eq 'list_or_nothing') {
      $value = [ string2list($value) ] if (defined $value && ! ref $value);
      croak "argument '$key' is '$value', not a list"
			    if ($value and ! UNIVERSAL::isa($value, 'ARRAY'));
    } 
    # elsif ($required eq 'list_or_hash') {
    # croak "argument '$key' is a $value, not a list or hash"
    # unless (UNIVERSAL::isa($value,'ARRAY') or UNIVERSAL::isa($value,'HASH'));
    # } 
    else {
      warn "Tag definition error: unknown argument requirement '$required'\n";
    }
    
    $result->{$key} = $value;
  }
  
  return $result;
}

1;

__END__

=head1 Script::Tag


=head2 Parser Syntax Class

=over 4

=item Script::Tag->stopregex : $leader_regex

=item Script::Tag->parse( $parser )

=back


=head2 Instantiation

Uses Class::NamedFactory

=over 4

=item Script::Tag->new_from_string($name_and_args_without_brackets) : $tag

=item Script::*TagClass*->new( %args ) : $tag

=item %Tags

Hash of known concrete subclasses by tag name

=item $package->subclass_by_name( $name ) : $classname

=back


=head2 Output

=over 4

=item $tag->source : $scripttext

=item $tag->open_tag : $htmltag

=back


=head2 Argument Definition and Interpretation

=over 4

=item $tag->arg_defn

Returns a hash of supported argument names, with each value a reference to a hash with the following three keys:
  dref => no | yes | optional (with #)
  default => default value
  required => value constraints (some cases just require that we got the right type, in other cases we attempt to coerce the value into that type)

=item $tag->get_args : $args

Make a parsed copy of the args.

dref_style may be one of:
  false, or 'no'	literal only, no dereferencing
  'target'		same as 'no', except it implies that it'll be set later
  'optional'		literal or #dref
  'yes'			straightforward dref
 
$required may be one of:
  false, or 'anything'	no requirements or coersion
  'string_or_nothing'	scalar
  'non_empty_string'	scalar with length
  'oneof a b c'		one of the provided space-separated strings
  'list_ref'		must be an list reference (uncoerced)
  'list'		list ref, or text to be parsed with string2list
  'list_or_nothing'	as above, but allows undef
  'hash_ref'		must be an hash reference (uncoerced)
  'hash'		hash ref, or text to be parsed with string2hash
  'hash_or_nothing'	as above, but allows undef


=item $tag->check_tag_args

=back

=head2 Caveats and Things To Do

=over 4

=item *

Should supplement $tag->get_args() with $tag->get_arg($argname);

=item *

Support additional require styles, like "class Record" 

=item *

Support an indirect-object style syntax for tags; first argument is
a the reference or primary value for the function call, eg: 

    [print #my:value]

=item *

It would be convenient for debugging if we cought unknown tag arguments.

=item *

Perhaps we should count line numbers in the source file and store them in
each tag for error reporting

=item *

Default tag argument values should support the same DRef options as the normal values.

=back

=cut
