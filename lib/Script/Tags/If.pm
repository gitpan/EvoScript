### Script::Tags::If provides the basic conditional tag of EvoScript

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-29 Fixed 'isequal' test to work with a value of 0.
  # 1998-03-23 Added isgreater and islesser tests.
  # 1998-03-13 Fixed isstring comparison.
  # 1998-03-11 Inline POD added.
  # 1998-03-11 Added orif tag.
  # 1998-03-02 Fixed isstring test.
  # 1997-10-28 Refactored; created else, elsif, andif tags
  # 1997-09-?? Forked for four.
  # 1997-08-03 Changed the isempty test again; this is killing me.
  # 1997-08-02 Changed the isempty test again, to consider whitespace empty.
  # 1997-04-14 Fixed isempty test.
  # 1997-03-23 Improved exception handling.
  # 1997-03-11 Split from script.tags.pm -Simon
  # 1996-09-08 Initial creation of the if tag.

package Script::Tags::If;

$VERSION = 4.00_1998_03_11;

use Script::Container;
@ISA = qw( Script::Container );

Script::Tags::If->register_subclass_name();
sub subclass_name { 'if' }

# [if value=#x (not) (isequal=#n isstring=#x istrue isempty ...)] ... [/if]
%ArgumentDefinitions = (
  'value' => {'dref' => 'optional', 'required'=>'anything'},
  
  'not' => {'dref'=>'no', 'required'=>'flag'},
  
  'isstring' => {'dref'=>'optional', 'required'=>'string_or_nothing'},
  'isequal' =>  {'dref'=>'optional', 'required'=>'string_or_nothing'},
  'isgreater' => {'dref'=>'optional', 'required'=>'string_or_nothing'},
  'islesser' => {'dref'=>'optional', 'required'=>'string_or_nothing'},
  
  'isdefined' =>{'dref'=>'no', 'required'=>'flag'},
  'istrue' =>   {'dref'=>'no', 'required'=>'flag'},
  'isempty' =>  {'dref'=>'no', 'required'=>'flag'},
  
  'regex' =>  {'dref'=>'no', 'required'=>'string_or_nothing'},
  'isinlist' => {'dref'=>'no', 'required'=>'list_or_nothing'},
);

# $text = $iftag->interpret();
sub interpret {
  my $tag = shift;
  
  $tag->setflag( $tag->checkvalue() );
  
  return $tag->interpret_contents();
}

# $flag = $iftag->checkvalue();
sub checkvalue {
  my $tag = shift;
  my $args = $tag->get_args;
  # warn "If args: " . Text::PropertyList::astext($args) . "\n";
  
  my $value = $args->{'value'};
  
  my $flag = 1; # return contents unless we fail one of the provided tests
  
  $flag = 0 if (
       ($args->{'isdefined'} &&		(! defined $value)) 
    or ($args->{'istrue'} &&		(not $value)) 
    or ($args->{'isstring'} &&		($value ne $args->{'isstring'}) ) 
    or (length($args->{'isequal'}) &&	($value != $args->{'isequal'})  ) 
    or ($args->{'isgreater'} &&	        ($value <= $args->{'isgreater'})  ) 
    or ($args->{'islesser'} &&	        ($value >= $args->{'islesser'})  ) 
    or ($args->{'regex'} &&		($value !~ /$args->{'regex'}/)	) 
    or ($args->{'isdref'} &&		($value ne getDRef($args->{'isdref'}))  )
  );
  
  if ($args->{'isempty'}) {
    if (! ref $value) {
      $flag = 0 if ($value =~ /\w/);
    } elsif (ref ($value) eq 'ARRAY') {
      $flag = 0 if (scalar(@$value));
    } elsif (ref ($value) eq 'HASH') {
      $flag = 0 if (scalar(%$value));
    } else {
      die "IF TAG DIED BECAUSE OF ISEMPTY FALLTHROUGH\n";
    }
  }
  
  # warn " !!! [if] test: istrue '$value' = '$flag'\n" if ($args->{'istrue'});
  
  # Which of the below lines should we be using? Surely not all three? -Simon
  if (defined $args->{'isinlist'}) {
    $flag = 0 if (
    	(! &get($args->{'isinlist'})) or
     (! ref(&get($args->{'isinlist'}))) && (&get($args->{'isinlist'}) ne $value) or
      ref(&get($args->{'isinlist'})) && (! grep(($_ eq $value), @{&get($script->{'context'}, $args->{'isinlist'})}))
    );
  }
  
  $flag = ! ($flag || 0) if ($args->{'not'});
  
  return $flag;
}

### Conditional Script Sequence

use vars qw( $current );

# $conditional = current_conditional();
sub current_conditional {
  return $current;
}

# $stringvalue = $conditional->interpret_contents();
sub interpret_contents {
  my $conditional = shift;
  
  local $current = $conditional;
  
  my $value = '';
  $conditional->{'done'} = 0;
  foreach $item ( $conditional->elements ) {
    $value .= $item->interpret() 
	if ( $conditional->flag or $item->isa('Script::Tags::If::Else') );
    last if ( $conditional->{'done'} );
  }
  return $value;
}

# $flag = $conditional->flag();
sub flag ($) {
  my $conditional = shift;
  return $conditional->{'flag'};
}

# $conditional->setflag($flag);
sub setflag ($$) {
  my $conditional = shift;
  $conditional->{'flag'} = shift;
}

# $conditional->else();
sub else {
  my $conditional = shift;
  if ( $conditional->flag ) {
    $conditional->{'done'} = 1;
  } else {
    $conditional->setflag( 1 );
  }
  return '';
}

### If::Else reverses the flag of a conditional sequence: [if]...[else]...[/if] 

package Script::Tags::If::Else;
@ISA = qw( Script::Tag );

# [else]
Script::Tags::If::Else->register_subclass_name();
sub subclass_name { 'else' }

%ArgumentDefinitions = ( );

# $elsetag->interpret();
sub interpret {
  my $tag = shift;
  
  my $conditional = Script::Tags::If::current_conditional();
  die "the " . $tag->{'name'} . " tag must be used within a " . 
      "conditional container like [if]" 		unless ($conditional);
  
  $tag->update_conditional( $conditional );
  return '';
}

# $elsetag->update_conditional( $conditional );
  # Flip the flag on our current (most deeply nested) conditional.
sub update_conditional {
  my $tag = shift;
  my $conditional = shift;
  $conditional->else;
}

### If::ElsIf is a subclass of Else, which replicates the arguments of If. 

package Script::Tags::If::ElsIf;
@ISA = qw( Script::Tags::If::Else );

# [elsif value=#x (not) (tests ... ) ]
Script::Tags::If::ElsIf->register_subclass_name();
sub subclass_name { 'elsif' }

# import the argument syntax of the if tag.
%ArgumentDefinitions = %Script::Tags::If::ArgumentDefinitions;
sub checkvalue { &Script::Tags::If::checkvalue }

# $elsif->update_conditional( $conditional );
sub update_conditional {
  my $tag = shift;
  my $conditional = shift;
  if ( $conditional->flag ) {
    $conditional->else();
  } else {
    $conditional->setflag( $tag->checkvalue );
  }
}

### If::AndIf is like ElsIf, but is designed to create stricter conditions 

package Script::Tags::If::AndIf;
@ISA = qw( Script::Tags::If::ElsIf );

# [andif value=#x (not) (tests ... ) ]
Script::Tags::If::AndIf->register_subclass_name();
sub subclass_name { 'andif' }

%ArgumentDefinitions = %Script::Tags::ElsIf::ArgumentDefinitions;

# $andif->update_conditional( $conditional );
sub update_conditional {
  my $tag = shift;
  my $conditional = shift;
  if ( $conditional->flag and ! $tag->checkvalue ) {
    $conditional->else();
  }
}

### If::OrIf is like ElsIf, but is designed to allow multiple conditions 

package Script::Tags::If::OrIf;
@ISA = qw( Script::Tags::If::ElsIf );

# [orif value=#x (not) (tests ... ) ]
Script::Tags::If::OrIf->register_subclass_name();
sub subclass_name { 'orif' }

%ArgumentDefinitions = %Script::Tags::ElsIf::ArgumentDefinitions;

# $andif->update_conditional( $conditional );
sub update_conditional {
  my $tag = shift;
  my $conditional = shift;
  $conditional->setflag( $conditional->flag || $tag->checkvalue );
}

1;

=head1 If

Selectively evaluates its contents based on a series of tests. If any of the tests fail, none of the contents are displayed until an else or elsif tag.

    [if value=#request.args.command isstring=Save]
      You clicked the Save button.
    [/if]

=over 4

=item value

The value to be tested. Use '#' for DRefs. Required argument. 

=item not

Optional flag. Reverses the outcome of the tests.

=item isstring

Optional. A string which the value must be equal to. Use '#' for DRefs.

=item isequal

Optional. A number which the value must be equal to. Use '#' for DRefs.

=item isgreater

Optional. A number which the value must be greater than. Use '#' for DRefs.

=item islesser

Optional. A number which the value must be less than. Use '#' for DRefs.

=item isdefined

Optional flag. The value must be defined.

=item isdefined

Optional flag. The value must be true (not undefined, zero, or the empty string).

=item isempty

Optional flag. The value must be an empty string, or a reference to an empty hash or array.

=item regex

Optional. A Perl regular expression the value must match.

=item isinlist

Optional. A quoted sequnce of space separated words, one of which must be the same as the value.

=back

=head2 Else

The else tag reverses the test success value of the inner-most If block.

    Thank you for purchasing [if value=#n isqual=1] 
      a gift.
    [else]
      [print value=#n] gifts.
    [/if]

There are no arguments for this tag.

This tag can only be used within the immediate scope of an If tag.

=head2 ElsIf

The elsif tag allows you to test for a different condition within an If block.

    Thank you for purchasing [if value=#n isqual=1] 
      a gift.
    [elsif value=#n istrue]
      [print value=#n] gifts.
    [else]
      nothing, you cheapskate.
    [/if]

This tag has the same arguments as L</If>, above.

This tag can only be used within the immediate scope of an If tag.

=head2 AndIf

The andif tag allows you to compound multiple conditions.

    [if value=#request.client.addr isstring="208.39.12.23"]
    [andif value=#request.user.login isstring=joe]
    [andif value=#request.browser.name not regex="{?i)mozilla"]
      Hello joe from 208.39.12.23 -- you're not using Netscape!
    [/if]

This tag has the same arguments as L</If>, above.

This tag can only be used within the immediate scope of an If tag.

=head2 OrIf

The orif tag allows you to accept any of multiple conditions.

    [if value=#request.client.addr regex=(?i)microsoft\.com]
    [orif value=#request.user.login isstring=billg]
      [warn]Flee in terror![/warn].
    [/if]

This tag has the same arguments as L</If>, above.

This tag can only be used within the immediate scope of an If tag.

=cut