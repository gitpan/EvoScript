### PropertyList.pm - turn data structures into text and back again.

### Usage
  # $string = astext($referenceorvalue);
  # $datastructure = fromtext($string);

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License
  # 
  # Development by:
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Piglet   Eleanor J. Evans (piglet@evolution.com)
  # Eric     Eric Schneider (roark@evolution.com)
  # Jeremy   Jeremy G. Bishop (jeremy@evolution.com)

### Change History
  # 1998-03-03 Replaced $r->class with ref($r) -Simon
  # 1998-02-25 Version 1.00 - String::PropertyList
  # 1998-02-25 Moved to String:: and @EXPORT_OK for CPAN distribution - jeremy
  # 1998-01-28 Fixed variable name typo in arrayfromtext.
  # 1998-01-11 Added rudimentary support for comments: full-line comments only
  # 1998-01-02 Renamed package Data::PropertyList to Text::PropertyList -Simon
  # 1997-12-08 Removed package Data::Types, use UNIVERSAL::isa instead. -Piglet
  # 1997-11-19 Added loopback handling to astext; now shown as REF TO <DREF>
  # 1997-10-28 Updated to use new Text::Escape interface.
  # 1997-10-21 Documentation cleanup.
  # 1997-08-17 Moved string escape/unescape code into new Text::Escape. -Simon
  # 1997-01-2? New fromDictionary parser -Eric
  # 1997-01-14 New asDictionary function provides closer match to NeXT style.
  # 1997-01-11 Cloned & cleaned for Inetics; moved I/O to file.pm. V3.0 -Simon
  # 1996-10-29 Added append flag and trailing \n to write. -Piglet
  # 1996-08-06 Partial fix for blessed data; treat as basic type. V2.05 -Simon
  # 1996-07-13 Cleaned up flow, fixed headers.
  # 1996-06-25 Wrote &write. V2.04 -EJ
  # 1996-06-23 Converted from Perl 4 library to Perl 5 package. V2.03
  # 1996-06-18 Iterative line parsing replaces raw recursion. V2.02
  # 1996-06-15 Clean start with support for nested data structures. V2.01
  # 1996-05-26 Support for =<< multiline values.
  # 1996-05-08 Parse key-value pairs into a flat hash. Version 1. -Simon


package String::PropertyList;

use vars qw( $VERSION );
$VERSION = 1.00;

use String::Escape 1.00, qw( qprintable unprintable );
$String::Escape::Escapes{'astext'} = \&astext;
$String::Escape::Escapes{'fromtext'} = \&fromtext;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( astext fromtext );

use vars qw( $Separator );
$Separator = '.';

# This isn't strict-friendly yet. damn.
# use strict;

### Writer

# $string = astext($referenceorvalue);
  # Write out an object graph in NeXT property list format 
  # Numerous variables are localized, then we recurse.
sub astext {
  my $target = shift;
  local %drefs = ();
  local %shown = ();
  local %suppressed = ();
  local $dref = '';  
  local $level = 0;  
  local $verbose = 0;  
  local $pretty = 1;  
  build_text( $target )
}

# $string = build_text($referenceorvalue);
sub build_text {
  my $target = shift;
  
  return '/* UNDEFINED */' if (not defined $target);
  
  return qprintable( $target ) if ( ! ref($target) ); 
  
  return '/* XREF TO '.( length($drefs{$target})?$drefs{$target}:'ROOT') .' */'
    if ( exists $drefs{$target} and $shown{$target} || $suppressed{$target} );
  $drefs{$target} = $dref if ( not exists $drefs{$target});
  $shown{$target} ++ ;
  
  my $result = '';
  
  $result .= "/* DREF $dref */ " if ( $verbose and length $dref );
  
  local $dref = $dref . $Separator if ( length $dref );
  
  $result .= "/* CLASS " . ref($target) . " */ " if ($verbose and ref($target) and (ref($target) !~ /\A(ARRAY|HASH|SCALAR|REF|CODE)\Z/));
  
  if ( UNIVERSAL::isa($target, 'HASH') ) {
    $result .=  "{ " if ($level);
    $result .= "\n" if ($result); 
    my $key;
    if ( $pretty ) {
      foreach $key (sort keys %{$target}) {
        next unless (ref $target->{$key});
	$drefs{ $target->{$key} } ||= $dref . $key;
	$suppressed{ $target->{$key} } ++;
      }
    };
    foreach $key (sort keys %{$target}) {
      $result .= ' ' x ($level*2); 
      local $level = $level + 1;
      local $dref = $dref . $key;
      $suppressed{$target->{$key}} -- if ( $pretty and ref $target->{$key} );
      $result .= build_text($key) . ' = ' . build_text($target->{$key}) .";\n";
    }
    $result .= ' 'x(($level-1)*2) . "}" if ($level);
    return $result;
  } 
  
  if ( UNIVERSAL::isa($target, 'ARRAY') ) {
    $result .=  "( " if ($level);
    $result .= "\n" if ($result); 
    my $key;
    if ( $pretty ) {
      foreach $key (0 .. $#{$target}) {
	$drefs{ $target->[$key] } ||= $dref . $key if (ref $target->[$key]);
	$suppressed{$target->[$key]} ++;
      }
    };
    foreach $key (0 .. $#{$target}) {
      $result .= ' ' x ($level * 2);
      local $level = $level + 1;
      local $dref = $dref . $key;
      $suppressed{$target->[$key]} -- if ( $pretty and ref $target->[$key] );
      $result .= build_text($target->[$key]) . ",\n";
    }
    $result .= ' 'x(($level-1)*2) . ")" if ($level);
    return $result;
  }
  
  if ( UNIVERSAL::isa($target, 'REF') || UNIVERSAL::isa($target, 'SCALAR') ) {
    $result .= '/* REFERENCE */ ' if ( $verbose );
    local $level = $level + 1;
    local $dref = $dref . $Separator . 0;
    $result .= build_text($$target);
    return $result;
  }
  
  return "/* REFERENCE TO $target */";
}

### Reader

# $datastructure = fromtext($string);
  # &fromtext - reconstruct an object graph from a NeXT property list.
  
sub fromtext {
  local @dict_text_lines = @_;
  local $current_line_number = 0;
  
  my $dictionary_text = shift(@_);
  if ($dictionary_text) {
    @dict_text_lines = split("\n", $dictionary_text);
    $current_line_number = 0;
  }
  
  my($hash) = &hashfromtext();
       
  return $hash;
}

sub fromtextError {
  my $message = shift;
  
  warn 'Syntax error in Dictionary file (' . $message . ') at line ' . 
  		$current_line_number  . "\n";
}

sub hashfromtext {
  my $hash = {};
  my ($key, $value, $current_line);
  
  while (@dict_text_lines) {
    $current_line = shift(@dict_text_lines) || '';
    $current_line_number++;
    
    next if ( $current_line =~ /^\s*\/\*.*\*\/\s*$/ );
    
    if ( $current_line =~ /^\s*\}[,;]/o ) {
      last;
    } elsif ( $current_line =~ /^\s*$/ ) {
      next;
    } elsif ( $current_line =~ s/^\s*\"(([^\"\\]|\\.)+)\"//o ) {
      $key = unprintable( $1 );
    } elsif ( $current_line =~ s/^\s*(\S+)//o ) {
      $key = $1;
    } else {
      &fromtextError("Key not found");
      last;
    }
    
    unless ( $current_line =~ s/^\s*=\s*//o ) {
      &fromtextError("= not found");
    }
    
    if ( $current_line =~ /^\s*\"\"\s*/o ) {
      $value = "";
    } elsif ( $current_line =~ /^\s*\"(([^\"\\]|\\.)+)\";\s*/o ) {
      $value = unprintable( $1 );
    } elsif ( $current_line =~ /^\s*(\S+);\s*/o ) {
      $value = $1;
    } elsif ( $current_line =~ /^\s*(\/\*.*?\*\/)\s*;\s*/o ) {
      $value = $1;
    } elsif ( $current_line =~ /^\s*\{/o ) {
      $value = &hashfromtext();
    } elsif ( $current_line =~ /^\s*\(/o ) {
      $value = &arrayfromtext();
    } elsif ( $current_line =~ /^\s*\<\<(\w+)/o ) {
      $value = &stringfromtext($1);
    } else {
      &fromtextError("Value not found");
      next;
    }
    
    if ($key) {
      $hash->{$key} = $value;
    }
    next;
  }
  
  return $hash;
}

sub arrayfromtext {
  my $array = [];
  my ($value, $current_line);
  
  while (@dict_text_lines) {
    $current_line = shift(@dict_text_lines);
    $current_line_number++;
  
    next if ( $current_line =~ /^\s*\/\*.*\*\/\s*$/ );
    
    if ( $current_line =~ /^\s*\)[,;]/o ) {
      last;
    } elsif ( $current_line =~ /^\s*\"\",\s*/o ) {
      $value = "";
    } elsif ( $current_line =~ /^\s*$/ ) {
      next;
    } elsif ( $current_line =~ /^\s*\"(([^\"\\]|\\.)+)\",\s*/o ) {
      $value = unprintable( $1 );
    } elsif ( $current_line =~ /^\s*(\S+),\s*/o ) {
      $value = $1;
    } elsif ( $current_line =~ /^\s*(\/\*.*?\*\/)\s*;\s*/o ) {
      $value = undef;
    } elsif ( $current_line =~ /^\s*\{/o ) {
      $value = &hashfromtext();
    } elsif ( $current_line =~ /^\s*\(/o ) {
      $value = &arrayfromtext();
    } elsif ( $current_line =~ /^\s*\<\<(\w+)/o ) {
      $value = &stringfromtext($1);
    } else {
      &fromtextError("Element not found");
      next;
    }
  
    push( @{$array}, $value);
  
    next;
  }
  
  return $array;
}

sub stringfromtext {
  my $string = '';
  
  my ($value, $current_line);
  
  while (@dict_text_lines) {
    $current_line = shift(@dict_text_lines);
    $current_line_number++;
    last if ($current_line =~ $_[0]);
    $value .= $current_line . "\n";
  }
  return $value;
}

1;
=pod

=head1 String::PropertyList

String::Propertylist provides functions that turn data structures of nested references into text and back again.  Uses NeXT's PropertyList format (see Caveats).  Useful for saving and loading data in flat files, and generating error messages in debugging.

=head1 Synopsis

    use String::PropertyList qw(astext fromtext);
	
    $string = astext($referenceorvalue);
    $datastructure = fromtext($string);

=head1 Reference

=head2 PropertyList Syntax

=over 4

=item astext( $referenceorvalue ) : $string

Writes out a nested Perl data structure in NeXT property list format.

  my $produce_info = {
	'red' => { 'fruit' => [ { 'category' => 'fruit', 
				  'name' => 'apples', 
				  'color' => 'red' } ],
		   'tubers' => [ { 'category' => 'tubers', 
				   'name' => 'potatoes', 
				   'color' => 'red' } ] },
	'orange' => { 'fruit' => [ { 'category' => 'fruit', 
				     'name' => 'oranges', 
				     'color' => 'orange' } ] }
  };
  print astext( $produce_info);

Examine STDOUT, et voila!

  orange = { 
    fruit = ( 
      { 
	category = fruit;
	color = orange;
	name = oranges;
      },
    );
  };
  red = { 
    fruit = ( 
      { 
	category = fruit;
	color = red;
	name = apples;
      },
    );
    tubers = ( 
      { 
	category = tubers;
	color = red;
	name = potatoes;
      },
    );
  };

=item fromtext( $string ) : $datastructure

Reconstructs a Perl data structure of nested references and scalars from a NeXT property list.

=back

=head1 Caveats and Upcoming Changes

Currently picky about parsing whitespace, and stilted about printing it.

Blessage is indicated in the output, but not restored when reading.

Doesn't currently parse or write the <FFFF> binary format.

We've added an alternate multiline syntax, <<DELIMITER, which works much as it does in Perl.

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut