#!/usr/bin/perl

### EvoScript.cgi - Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # Perl source code for the EvoScript Web Application Framework 
  # is freely available under the artistic license at http://www.evoscript.com/

### Configuration Variables ###

# Resource Directory Path
my $Resource_Path = '/sites/evoscript/examples';

# Declare library paths

###############################

# Init process globals
BEGIN { $VERSION = 4.00_03; };
BEGIN { $Start = time();    };

# Log process startup and exit
BEGIN { 
$INC{'Err::WebLogFormat'} = 'lib/Err/WebLogFormat.pm';
eval {
### Err::WebLogFormat reformats Perl warnings for web server error logs.

### Synopsis
  #   use Err::WebLogFormat;
  #   
  #   warn "gack!";
  #
  # sh> myapp.pl 
  # [Mon Dec  8 18:02:42 1997] myapp.pl: gack! at myapp.pl line 3

### Description
  # Messages written to STDERR by a CGI script are commonly appended to 
  # an error log. WebLogFormat overrides Perl's default warn & die signal
  # handlers to use a format appropriate for standard httpd error logs.
  # 
  # Two package flags are used to control the output: set them directly, or
  # use the equivalent import flags in your use statement:
  # 
  # - use Err::WebLogFormat qw(stamp_every_line);
  # Sets $Show_PID to nonzero to show the process ID in parentheses
  # next to the program name, which can be useful if multiple instances
  # of a script are logging to the same stream simultaneously.
  # 
  # - use Err::WebLogFormat qw(show_pid);
  # Sets $Stamp_Every_Line to change the layout of multi-line messages
  # to repeat the datestamp rather than the default whitesapce padding.
  # 
  # - $Script_Name
  # You can override the name by setting $Err::WebLogFormat::program_name.
  # 
  # You only need to use Err::WebLogFormat once in your program.
  # This code should interoperate just fine with Carp's carp/croak functions.

### Copyright 1997 Evolution Online Systems, Inc.
  # This is free software; you can use it under the same terms as Perl itself.
  #
  # Based on CGI::Carp 1.02 by Lincoln D. Stein <lstein@genome.wi.mit.edu>

### Change History
  # 1998-03-02 Script name now defaults to $0 basename, not first caller file.
  # 1998-02-03 Trying LOG rather than STDERR -- Rolled back.
  # 1998-01-22 Added import wrapper for config flags.
  # 1998-01-02 Added $Stamp_Every_Line flag.
  # 1997-12-08 Some cleanup and documentation.
  # 1997-10-03 New package, Err::WebLogFormat, based on Evo::carp -Simon

package Err::WebLogFormat;

require 5.000;


# Overrides the default warn and die signal handlers to apply logging format
open(LOG, ">&STDERR");
$main::SIG{__WARN__} = sub { print LOG ( web_log_format(@_) );           };
$main::SIG{__DIE__}  = sub { print LOG ( web_log_format(@_) ); die "\n"; };

use vars qw( $Script_Name $Show_PID $Stamp_Every_Line );

# Err::WebLogFormat->import( 'show_pid' );
sub import {
  my $package = shift;
  foreach ( @_ ) {
    if ( m/show_pid/i ) {
      $Show_PID = 1;
    } elsif ( m/stamp_every_line/i ) {
      $Stamp_Every_Line = 1;
    } else {
      die "unkown import";
    }
  }
}

# $formatted = web_log_format( @text );
  # Convert error messages to look like web server logs, with date and process
  # name at the begining of each line. 
sub web_log_format {
  my $message = join('', @_);
  
  unless ( $message =~ /\n\Z/ ) {
    my ($pack, $file, $line, $sub) = caller(1);
    $message .= " at $file line $line.\n";
  }
  
  $Script_Name ||= ( $0 =~ m/([^\/\\\:]+)\Z/ )[0];
    
  my $stamp = '[' . scalar(localtime) . '] ' . 
	      ($Script_Name) . ( $Show_PID ? ' ('.$$.')' :'' ) . ': ';
  
  if ( $Stamp_Every_Line ) {
    $message =~ s/^/$stamp/gm;
  } else {
    my $spacer = ' ' x length($stamp);
    $message =~ s/^/$spacer/gm;
    $message =~ s/\A$spacer/$stamp/m;
  }
  
  return $message;
} 

1;


};
Err::WebLogFormat->import();
}
BEGIN { warn "--- Starting WebApp (Version $main::VERSION)\n"; }
END   { warn "--- Stopping WebApp\n"; }


# Supporting Libraries

BEGIN { 
$INC{'Data::DRef'} = 'lib/Data/DRef.pm';
eval {
### Data::DRef uses delimited keys to get and set values in nested structures

### DRef Syntax
  # $Separator - Multiple-key delimiter character
  # @keys = splitdref( $dref );
  # $dref = joindref( @keys );
  # $key = shiftdref( $dref );

### Multiple-Key Get and Set
  # $value = get($target, $dref);
  # set($target, $dref, $value);

### Functions with method overloading
  # $value = getDRef($item, $dref)
  # setDRef($item, $dref, $value)

### Shared Data Graph
  # $Root - Data graph entry point
  # $value = getData($dref)
  # $value = setData($dref, $value)
  # $dref = resolveparens( $dref_with_embedded_parens );

### Caveats and Things To Do
  # - Should escape and unescape drefs for printability, protect $Separators

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # This is free software; you can use it under the same terms as Perl itself.

### Change History
  # 1998-03-12 Patched dref manipulation functions to escape separator. -Piglet
  # 1997-11-19 Renamed removekey function to shiftdref at Jeremy's suggestion.
  # 1997-11-14 Added resolveparens behaviour to standard syntax.
  # 1997-11-14 Added getDRef, setDRef functions as can() wrappers for get, set
  # 1997-10-29 Add'l modifications; replaced recursion with iteration in get()
  # 1997-10-25 Revisions; separator changed from colon to period.
  # 1997-10-03 Refactored get and set operations
  # 1997-09-05 Package split from the original dataops.pm into Data::*.
  # 1997-04-18 Cleaned up documentation a smidge.
  # 1997-01-29 Altered set to create hashes even for numerics
  # 1997-01-11 Cloned and cleaned for IWAE; removed asdf code to dictionary.pm.
  # 1996-11-18 Moved v2 code into production, additional cleanup. -Simon
  # 1996-11-13 Version 2.00, major overhaul. 
  # 1996-10-29 Fixed set to handle '0' items. -Piglet
  # 1996-09-09 Various changes, esp. fixing get to handle '0' items. -Simon
  # 1996-07-24 Wrote copy, getString, added 'append' to set.
  # 1996-07-18 Wrote setData, fixed headers.  -Piglet
  # 1996-07-18 Additional Exporter fudging.
  # 1996-07-17 Globalized theData. -Simon
  # 1996-07-13 Simplified getData into get; wrote set. -Piglet
  # 1996-06-25 Various tweaks.
  # 1996-06-24 First version of dataops.pm created. -Simon

package Data::DRef;

use vars qw( $VERSION );
$VERSION = 4.00_01;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( getData setData getDRef setDRef joindref shiftdref $Root );
push @EXPORT_OK, qw( get set $Separator splitdref );

use Carp;

use vars qw( $Root $Separator );

### DRef Syntax

# $Separator - Multiple-key delimiter character
$Separator = '.';

# @keys = splitdref( $dref );
  # Return a series of key strings extracted from a dref
sub splitdref ($) {
  my $string = shift;
  my @keys;
  while (length $string) {
    push(@keys, shiftdref($string));
  }
  return @keys;
}

# $dref = joindref( @keys );
  # Return a dref composed of a list of $Separator-protected keys 
sub joindref (@) {
  my @keys = @_;
  return join ($Separator, @keys);
}

# $key = shiftdref( $dref );
  # Removes first key from dref
sub shiftdref {
  return $1 if ( $_[0] =~ s/^(([^.\\]|\\\Q$Separator\E|\\(?!\Q$Separator\E))+|([^.]+))(\Q$Separator\E|$)// );
  # character classes in above regexp assume that $Separator is .
  
  my $temp = $_[0]; $_[0] = '';
  return $temp;
}

### Multiple-Key Get and Set

# $value = get($target, $dref);
sub get ($$) {
  my $target = shift;
  croak "get called without target \n" unless (defined $target);
  
  my $dref = shift;
  croak "get called with empty dref \n" unless (length $dref);
  
  my $key;
  while ( length($key = shiftdref($dref)) ) {
    $key =~ s/\\(\Q$Separator\E)/$1/g;
    my $result;
    if ( UNIVERSAL::isa($target,'HASH') ) {
      $result = $target->{$key} if (exists $target->{$key});
    } elsif ( UNIVERSAL::isa($target,'ARRAY') ) {
      # warn about non-integer keys
      # unless ( $key eq '0' or $key == $key +0 ) {
      #   confess "get called on array with string key '$key'\n";
      #   return;
      # }
      $result = $target->[$key] if ($key >= 0 and $key < scalar @$target);
    } else {
      # We do not natively support get() on anything else.
      carp "get failure on '$key' from '$target'\n";
    }
    
    # If there aren't any more keys, we're done
    return $result unless (length $dref);
    
    # We've got keys remaining, but we can't keep going
    #   carp "can't get '$dref' because '$key' is " . 
    #          (defined($result) ? "a scalar value '$result'" : 'undefined') ;
    return undef unless (ref $result);
    
    # If we've got keys remaining, use the appropriate get method...
    return $result->get($dref) if UNIVERSAL::can($result, 'get');
    
    # ... or select the target and iterate through another key
    $target = $result;
  }
}

# set($target, $dref, $value);
sub set {
  my ($target, $dref, $value) = @_;
  
  croak "set called without target \n" unless (defined $target);
  croak "set called with empty dref \n" unless (length $dref);
  
  # warn "- setting '$dref' in '$target' \n";
  
  my $key = shiftdref($dref);
  
  if (length $dref) {
    my $next_node = get($target, $key);
    
    unless (defined $next_node and ref $next_node) {
      $next_node = {};
      set($target, $key, $next_node);
    }
    
    return UNIVERSAL::can($next_node, 'set') ? $next_node->set($dref, $value) 
				  : set($next_node, $dref, $value) ;
  }
    
  # We're at the end of the line
  $key =~ s/\\(\Q$Separator\E)/$1/g;
  if ( UNIVERSAL::isa($target,'HASH') ) {
    $target->{$key} = $value;
  } elsif ( UNIVERSAL::isa($target,'ARRAY') ) {
    # warn about non-integer keys
    $target->[$key] = $value;
  } else {
    # We do not natively support set() on anything else.
    #!# Need to consider this -- perhaps throw an exception?
    croak "set failure on '$key' from '$target'\n";
  }
  return;
}

### Functions with method overloading
  # 
  # Anything that wants to provide custom dref-like behaviour should 
  # provide their own get and set methods; callers use these functions
  # to allow this behaviour to kick in.

# $value = getDRef($item, $dref);
sub getDRef ($$) {
  my ($item, $dref) = @_;
  UNIVERSAL::can($item, 'get') ? $item->get($dref) 
			       : get( $item, $dref );
}

# setDRef($item, $dref, $value);
sub setDRef ($$$) {
  my ($item, $dref, $value) = @_;
  UNIVERSAL::can($item, 'set') ? $item->set($dref, $value) 
			       : set($item, $dref, $value);
}

### Shared Data Graph

# $Root - Data graph entry point
$Root = {};

# $value = getData($dref);
sub getData ($) {
  croak "getData called with empty dref\n" unless (length $_[0]);
  get($Root, resolveparens( shift ) );
}

# $value = setData($dref, $value);
sub setData ($$) {
  croak "setData called with empty dref\n" unless (length $_[0]);
  set($Root, resolveparens( shift ), shift );
}

# $dref = resolveparens( $dref_with_embedded_parens );
  # Jeremy's syntax extension for expressions like "#cgi.args.(my.argname)"
sub resolveparens ($) {
  my $path = shift;
  while( $path =~ s/\(([^\(\)]+)\)/getData($1)/e ) { };
  return $path;
}

1;


};
Data::DRef->import();
}

BEGIN { 
$INC{'Script'} = 'lib/Script.pm';
eval {

#!# THIS PACKAGE IS ARCHAIC - PLEASE USE Script::Evalutate INSTEAD

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

package Script;

require 5.000;

BEGIN { 
$INC{'Script::Parser'} = 'lib/Script/Parser.pm';
eval {
### An Script::Parser builds a tree of elements embedded in a text stream

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-08 Moved some optional warnings into debug 'parser' statements.
  # 1998-03-26 Added support for $p->pop($class_name); removed $p->add($elem)
  # 1997-10-23 Touchups.
  # 1997-08-26 Forked version 4

package Script::Parser;

BEGIN { 
$INC{'Script::Sequence'} = 'lib/Script/Sequence.pm';
eval {
### An Script::Sequence is an element containing an array of sub-elements.

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-06-02 Relocated intersperse method.
  # 1998-03-05 Added elements_of_class(), first_element_of_class method.
  # 1997-11-01 Minor fixups; reordered methods
  # 1997-10-31 Added append and prepend methods
  # 1997-09-** Split from primary Script package and refactored. -Simon

package Script::Sequence;

BEGIN { 
$INC{'Script::Element'} = 'lib/Script/Element.pm';
eval {
### Script::Element is the abstract base class for all EvoScript objects

### Default Behaviour 
  # $element->add_to_parse_tree($parser);

### Abstract methods to be implemented by subclasses
  # Script::Element->new();				
  # Script::Element->add();				
  # Script::Element->parse();			
  # Script::Element->source();			
  # $specialchars = Script::Element->stopregex();	
  # $result = $element->interpret();			

### Should add some methods to allow various depth-first traversals, including:
  # $e->call_on_self_and_contents($method, @args);
  # $e->call_with_self_and_contents($code_ref, @other_args);

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-26 Changed add_to_parse_tree to call $parser->current->add directly
  # 1998-03-06 Added inline POD.
  # 1998-01-29 Added default do-nothing exapnd method.
  # 1997-09-02 Split from primary Script package and refactored. -Simon

package Script::Element;

use Carp;

### Default Behaviour 

# $element->add_to_parse_tree($parser);
sub add_to_parse_tree {
  my $element = shift;
  my $parser = shift;
  $parser->current->add($element);
}

# $element = $element->expand;
sub expand { shift }

### Abstract methods to be implemented by subclasses

# Script::Element->new();				
# Script::Element->add();				
# Script::Element->parse();			
# Script::Element->source();			
# $specialchars = Script::Element->stopregex();	
# $result = $element->interpret();			

1;


};
Script::Element->import();
}
push @ISA, qw( Script::Element );

use Carp;
BEGIN { 
$INC{'Err::Debug'} = 'lib/Err/Debug.pm';
eval {
### Err::Debug provides keyword-based log filtering and output escaping

### Interface
  # add_logging( @dbg_label );
  # drop_logging( @dbg_label );
  # debug( $label, @values );

### Change History
  # 1998-03-04 Added 'always'.
  # 1998-01-29 Added $ShowLabels variable and associated output. Nicer, eh?
  # 1998-01-29 s/foreach(@_)/while-shift/ to fix side-effect, but no such luck.
  # 1998-01-06 Created. -Simon

package Err::Debug;

BEGIN { 
$INC{'Text::Escape'} = 'lib/Text/Escape.pm';
eval {
### Text::Escape.pm - backslash, quoting, and general escape/unescape functions
  # 
  # We provide a by-name escaping function and a collection of simple escapers.
  # Each escaper takes a single simple scalar argument and returns its 
  # escaped (or unescaped) equivalent.

### Generic by-name interface
  # %Escapes - escaper function references by name
  # Text::Escape::add( $name, $subroutine );
  # @defined_escapes = Text::Escape::names();
  # $escaped = escape($escapes, $value); 
  # @escaped = escape($escapes, @values);

### Unix-style Backslash Escaping: printable(), unprintable()

### Quoted Escaping: qescape(), unqescape()

### Double Quoting: quote(), unquote(), quote_non_words()

### Change History
  # 1998-06-11 Modified printable and unprintable algorithms.
  # 1998-04-27 Anchored regexes in unprintable() to backslash mangling.
  # 1998-03-16 Avoid modify-constant warnings by using lexical rather than $_
  # 1998-02-19 Started removal of sub add calls throughout Evo::Script
  # 1997-10-28 Created generic by-name interface; renamed printable
  # 1997-10-21 Altered quote_non_words algorithm to accept '-', '/', and '.'
  # 1997-08-17 Created this package from functions in dictionary.pm. -Simon

package Text::Escape;

use vars qw( $VERSION );
$VERSION = 4.00;

use Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( escape printable unprintable qprintable unqprintable quote_non_words );

use Carp;

### Generic by-name interface

# %Escapes - escaper function references by name
use vars qw( %Escapes );

%Escapes = ( 
  'printable' => \&printable,
  'unprintable' => \&unprintable,
  'qprintable' => \&qprintable,
  'unqprintable' => \&unqprintable,
  'quote' => \&quote,
  'unquote' => \&unquote,
  'quote_non_words' => \&quote_non_words,
  %Escapes,
);

# Text::Escape::add( $name, $subroutine );
sub add ($$) {
  my $name = shift;
  my $subroutine = shift;
  $Escapes{ $name } = $subroutine;
}

# @defined_escapes = Text::Escape::names();
sub names () {
  return keys(%Escapes);
}

# $escaped = escape($escapes, $value); 
# @escaped = escape($escapes, @values);
sub escape ($@) {
  my $escapes = shift;
  my @escapes = split(/\s+/, $escapes);
  
  my @values = @_;
  croak "escape called with multiple values but in scalar context"
					      if ($#values > 0 && ! wantarray);
  
  my ($value, $name);
  foreach $value ( @values ) {
    foreach $name (@escapes) {
      next if ($name =~ /\A\s*no\s*\Z/i);
      my $escaper = $Escapes{ $name };
      croak "escape called with undefined escaping style '$name'" 
						    unless( $escaper );
      $value = &$escaper( $value );
    }
  }
  
  return wantarray ? @values : $values[0];
}

### Unix-style Backslash Escaping: Handles return, newline, tab, unprintable characters, and backslash itself.

use vars qw( %Printable %Unprintable );
%Printable = ( 
  ( map { chr($_), unpack('H2', chr($_)) } ( 0 .. 255 ) ),
  "\\"=>'\\', "\r"=>'r', "\n"=>'n', "\t"=>'t', "\""=>'"' 
);
%Unprintable = ( reverse %Printable );

sub printable ($) {
  my $value = shift;
  $value = '' unless (defined $value);
  $value =~ s/([\r\n\t\"\\\x00-\x1f\x7F-\xFF])/\\$Printable{$1}/g;
  return $value;
}

sub unprintable ($) {
  my $value = shift;
  $value = '' unless (defined $value);
  $value =~ s/((?:\A|\G|[^\\]))\\([rRnNtT\"\\]|[\da-fA-F][\da-fA-F])/
  				$1 . $Unprintable{lc($2)}/ge;
  return $value;
}

### Quoted Printable Escaping: Backslash escaping with quotes around empty, punctuated, & multiword values.  Note that this is *not* MIME quoted-printable encoding. 

sub qprintable ($) {
  my $value = shift;
  $value = '' unless (defined $value);
  $value =~ s/([\r\n\t\"\\\x00-\x1f\x7F-\xFF])/\\$Printable{$1}/g;
  $value = '"'.$value.'"' if ($value =~ /[^\w\-\/\.\#\_]/ or ! length $value);
  return $value;
}

sub unqprintable ($) {
  my $value = shift;
  $value = '' unless (defined $value);
  $value =~ s/\A\"(.*)\"\Z/$1/;
  $value =~ s/((?:\A|\G|[^\\]))\\([rRnNtT\"\\]|[\da-fA-F][\da-fA-F])/
  				$1 . $Unprintable{lc($2)}/ge;
  return $value;
}

### Double Quoting: Add and remove double quotes from around a string. quote_non_words only quotes empty, punctuated, and multiword values

sub quote ($) {
  return '"' . (shift) . '"';
}

sub quote_non_words ($) {
  my $value = shift;
  $value = '"'.$value.'"' if ($value =~ /[^\w\-\/\.\#\_]/ or ! length $value);
  return $value;
}

sub unquote ($) {
  my $value = shift;
  $value =~ s/\A\"(.*)\"\Z/$1/;
  return $value;
}

1;


};
Text::Escape->import();
}
BEGIN { 
$INC{'Text::PropertyList'} = 'lib/Text/PropertyList.pm';
eval {
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
  # 1998-06-11 Improved support for <<HERE strings.
  # 1998-05-07 Fixed problem with reading "0 = ..." lines in hashes.
  # 1998-04-21 Fixed use-of-undef warning in arrays.
  # 1998-02-28 Initialized stringfromtext() $value to '' to run clean under -w.
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

#!# Maybe this really belongs under the Text::* hierarchy?

package Text::PropertyList;
use vars qw( $VERSION );
$VERSION = 4.00;

BEGIN { 
Text::Escape->import();
}
$Text::Escape::Escapes{'astext'} = \&astext;
$Text::Escape::Escapes{'fromtext'} = \&fromtext;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( astext fromtext );

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
  local $verbose = shift;  
  local $pretty = 1;  
  build_text( $target )
}

# $string = build_text($referenceorvalue);
sub build_text {
  my $target = shift;
  
  return '/* UNDEFINED */' if (not defined $target);
  
  if ( ! ref($target) ) {
    return "<<END_OF_TEXT_DELIMITER\n$target" . ($target =~ /\n\Z/ ?'':"\n") . 
    	"  END_OF_TEXT_DELIMITER" 	if ($target =~ /\n.*?\n/ ); 
    return qprintable( $target )
  }
  
  return '/* XREF TO '.( length($drefs{$target})?$drefs{$target}:'ROOT') .' */'
    if ( exists $drefs{$target} and $shown{$target} || $suppressed{$target} );
  $drefs{$target} = $dref if ( not exists $drefs{$target});
  $shown{$target} ++ ;
  
  my $result = '';
  
  $result .= "/* DREF $dref */ " if ( $verbose and length $dref );
  
  local $dref = $dref . $Separator if ( length $dref );
  
  $result .= "/* CLASS " . ref($target) . " */ " if ($verbose and ref($target) and (ref($target) !~ /\A(ARRAY|HASH|SCALAR|REF|CODE)\Z/));
  
  if ( UNIVERSAL::isa($target, 'HASH') ) {
    $result .=  "{" if ($level);
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
    $result .=  "(" if ($level);
    $result .= "\n" if ($result); 
    my $key;
    if ( $pretty ) {
      foreach $key (0 .. $#{$target}) {
        next unless (ref $target->[$key]);
	$drefs{ $target->[$key] } ||= $dref . $key;
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
  
  warn 'PropertyList Syntax error,', $message, ' at line', $current_line_number;
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
    
    if (defined $key) {
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
  
  my $value = '';
  my $current_line;
  
  while (@dict_text_lines) {
    $current_line = shift(@dict_text_lines);
    $current_line_number++;
    last if ($current_line =~ /^\s*\Q$_[0]\E[\;\,]?\s*$/);
    $value .= $current_line . "\n";
  }
  return $value;
}

1;

};
Text::PropertyList->import();
}

# Exports: debug()
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( debug );


use vars qw( %Level $ShowLabels $LastLabel );
%Level = ( 'always' => 1 );
$ShowLabels = 1;
$LastLabel = '';

# Functions

# add_logging( @dbg_label );
sub add_logging (@)  { foreach ( @_ ) { $Level{ $_ } ++ } }

# drop_logging( @dbg_label );
sub drop_logging (@) { foreach ( @_ ) { $Level{ $_ } -- } }

# debug( $label, @values );
sub debug ($;@) {
  my $dbg_label = shift;
  return unless $Level{ $dbg_label };
  
  if ( $ShowLabels and $dbg_label ne $LastLabel ) {
    warn '### ' . $dbg_label . "\n";
    $LastLabel = $dbg_label;
  }
  
  my @items;
  while ( scalar @_ ) {
    my $item = shift;
    push @items, ( ref $item or ! defined $item ) ? astext($item, 0) 
						  : printable $item;
    push @items, ' ';
  }
  warn @items, "\n";
} 

1;


};
Err::Debug->import();
}

### Instantiation

# $sequence = Script::Sequence->new( @elements );
sub new {
  my $class = shift;
  
  my $sequence = { 'elements' => [], };
  bless $sequence, $class;
  
  foreach ( @_ ) { $sequence->add( $_ ); }
  
  return $sequence;
}

### Element Access

# @elements = $sequence->elements; or @$elements = $sequence->elements;
sub elements {
  my $sequence = shift;
  return wantarray ? @{ $sequence->{'elements'} } : $sequence->{'elements'};
}

# $count = $sequence->elementcount;
sub elementcount {
  my $grid = shift;
  return scalar @{ $grid->elements };
}

# @values = $sequence->call_on_each($method, @args);
sub call_on_each {
  my $sequence = shift;
  my ($method, @args) = @_;
  my @values;
  foreach $element ( $sequence->elements ) {
    debug 'script_sequence', 'Calling', $method, 'on element', "$element";
    croak "can't call method '$method' on element '$element'" 
				unless ( UNIVERSAL::can($element, $method ) );
    push @values, $element->$method(@args);
  }
  return @values;
}

### Element Manipulation

# $sequence->add( @elements );
sub add {
  my $sequence = shift;  
  $sequence->append_elements( @_ );
}

# $sequence->append_elements( @element );
sub append_elements {
  my $sequence = shift;  
  foreach ( @_ ) { $sequence->append( $_ ); }
}

# $ok_flag = $sequence->prepend_elements( @element );
sub prepend_elements {
  my $sequence = shift;  
  foreach ( reverse @_ ) { $sequence->prepend( $_ ); }
}

# $sequence->append( $element );
sub append {
  my $sequence = shift;
  
  my $target = shift;
  $target = Script::Literal->new( $target ) unless ref $target;
  
  return unless ( $sequence->about_to_add( $target ) ); 
  
  push @{$sequence->{'elements'}}, $target;
}

# $sequence->prepend( $element );
sub prepend {
  my $sequence = shift;
  my $target = shift;
  $target = Script::Literal->new( $target ) unless ref $target;
  
  return unless ( $sequence->about_to_add( $target ) ); 
  
  unshift @{$sequence->{'elements'}}, $target;
}

# $sequence->about_to_add( $element );
  # Return 0 to discard contents, or croak if they're unacceptable
sub about_to_add {
  my $sequence = shift;
  my $target = shift;
  
  confess "can't add '$target' to '$sequence', it's not a Script::Element" 
	unless (ref $target and UNIVERSAL::isa($target, 'Script::Element') );
  
  return 1;
}

# $sequence->intersperse( $spacer );
sub intersperse {
  my $sequence = shift;
  my $spacer = shift;
  $spacer = Script::Literal->new( $spacer ) unless ( ref($spacer) );
  
  my $count;
  $sequence->{'elements'} = [ 
      map { $count++ ? ( $spacer, $_ ) : ( $_ ) } @{ $sequence->{'elements'} } 
  ];
  debug 'sequence', "interspersed", $sequence->{'elements'};
}

### Execution

# $stringvalue = $sequence->interpret();
sub interpret {
  my $sequence = shift;
  return $sequence->interpret_contents();
}

# $stringvalue = $sequence->interpret_contents();
sub interpret_contents {
  my $sequence = shift;
  
  debug 'script_sequence', "Interpreting $sequence";
  
  my $value = join('', $sequence->call_on_each('interpret'));
  
  debug 'script_sequence', "Interpretation of $sequence complete";
  debug 'script_sequence', "value is", $value;
  
  return $value;
}

# $stringvalue = $sequence->source();
sub source {
  my $sequence = shift;
  return $sequence->source_contents();
}

# $stringvalue = $sequence->source_contents();
sub source_contents {
  my $sequence = shift;
  
  return join('', $sequence->call_on_each('source'));
}

### Access by Class

# @elements = $sequence->elements_of_class( $classname );
sub elements_of_class {
  my $sequence = shift;
  my $classname = shift;
  
  grep { UNIVERSAL::isa($_, $classname) } $sequence->elements;
}

# $element = $sequence->first_element_of_class( $classname );
sub first_element_of_class {
  my $sequence = shift;
  my $classname = shift;
  
  ($sequence->elements_of_class($classname))[0];
}

# $element = $sequence->ensure_element_of_class( $classname );
sub ensure_element_of_class {
  my $sequence = shift;
  my $classname = shift;
  
  my $element = $sequence->first_element_of_class($classname);
  
  unless ( $element ) {
    $element = $classname->new();
    $sequence->add( $element );
  }
  
  return $element;
}

1;


};
Script::Sequence->import();
}

use Carp;
BEGIN { 
Err::Debug->import();
}


BEGIN { 
$INC{'Text::Excerpt'} = 'lib/Text/Excerpt.pm';
eval {
### Text::Excerpt - Truncate strings with elipses

### Interface
  # $elided_string = truncate($string, $length);
  # $escaped_elided_string = printablestring($string, $length);
  # $elided_words = shortenstring($string, $length);

### Change History
  # 1997-11-13 Changed truncate's name to elide -- looks like it's special -S.

package Text::Excerpt;

BEGIN { 
Text::Escape->import(qw( printable ));
}

use Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( elide printablestring );

# $elided_string = elide($string, $length);
  # Return a single-quoted, shortened version of the string, with ellipsis
sub elide ($;$) {
  my ($text, $length) = @_;
  
  $length ||= 40;
  $text = substr($text, 0, $length - 3) .'...' if ($length < length($text));
  
  return "'" . $text . "'";
}

# $escaped_elided_string = printablestring($string, $length);
  # Truncate the string as above, but first backslash escape any unprintables.
sub printablestring ($;$) { elide(printable(shift), shift); }

# $elided_words = shortenstring($string, $length);
  # Truncate the string at nearest word boundary.
sub shortenstring {
  my ($text, $length) = @_;
  $length ||= 40;
  
  my $textlen = length($text);
  # ($text =~ /^(.{$length}\S*)/)[0] .'...'
  $text = ($text =~ /^(.{0,$length})(?:\s|\Z)/)[0];
  
  return $text . ( length($text) < $textlen ? '...' : '' );
}

1;


};
Text::Excerpt->import(qw( elide ));
}

### Syntax Registry

# @Syntaxes - known syntax classes
use vars qw( @Syntaxes );

# Script::Parser->add_syntax( $syntax_package_name );
sub add_syntax {
  my $package = shift;
  push @Syntaxes, @_;
}

### Parser client interface

# $parser = Script::Parser->new();
sub new {
  my $package = shift;
  my $parser = {};
  $parser->{'syntaxes'} = [ @Syntaxes ];
  
  bless $parser, $package;  
    
  return $parser;
}

# $sequence = $parser->parse( $script_string );
sub parse {
  my $parser = shift;
  
  my $sequence = Script::Sequence->new();
  $parser->push( $sequence );
  
  $parser->{'text'} = shift;
  
  debug 'parser', 'Source is', $parser->{'text'};
  
  TOKEN: while ( length $parser->{'text'} ) {
    # Allow each of the syntax classes to try matching against the text 
    my $syntax;
    foreach $syntax ( @{$parser->{'syntaxes'}} ) {
      next TOKEN if $syntax->parse($parser);
    }
    
    # Fallback behaviour to ensure that we don't loop infinitely 
    warn "Script Parser syntax hiccup at: " . elide($parser->{'text'}) . "\n";
    Script::Literal->new($parser->get_text('.'))->add_to_parse_tree($parser);
  }
  
  debug 'parser', 'Result is', $sequence;
  
  $parser->pop( $sequence );
  
  return $sequence;
}

### Text extraction functions used to parse text out of the source

# $text = $parser->get_text( $regex );
sub get_text { 
  my $parser = shift;
  my $regex = shift;
  
  return unless (length $parser->{'text'} and length $regex);
  
  debug 'parser', "looking for '$regex' at ", elide($parser->{'text'});
  $parser->{'text'} =~ s/\A($regex)//s or return '';
  
  debug 'parser', "matched: ", elide($1);
  return $1;
}

# $text = $parser->get_unspecial_string();
sub get_unspecial_string { 
  my $parser = shift;
  
  return unless (length $parser->{'text'});
  
  # Take out everything upto the next occurance of the stopex
  my $exp = $parser->stopex;
  return $1 if ( length $exp and $parser->{'text'} =~ s/\A(.*?)($exp)/$2/s );
  
  # Else we didn't find the stopex; it all looks unspecial, so take it all.
  my $string = $parser->{'text'};
  $parser->{'text'} = '';
  return $string;
}

# $parser->stopex();
sub stopex {
  my $parser = shift;
  
  # The stopex only changes if you change Syntax classes, so cache the result
  $parser->buildstopex() unless ( exists $parser->{'stopex'} );
  
  return $parser->{'stopex'};
}

# $parser->buildstopex();
sub buildstopex {
  my $parser = shift;
  
  my ($syntax, @stopex);
  foreach $syntax (@{$parser->{'syntaxes'}}) {
    my $stop = $syntax->stopregex();
    push @stopex, $stop if (length $stop);
  }
  
  $parser->{'stopex'} = join '|', @stopex;
}

### Parser Context Stack.

# $current_item = $parser->current();
sub current {
  my $parser = shift;
  return $parser->{'stack'}[0] || croak "no item is current";
}

# $parser->push( $element );
sub push {
  my $parser = shift;
  my $target = shift;
  
  unshift @{$parser->{'stack'}}, $target;
}

# $element = $parser->pop( );
# $element = $parser->pop( $class_name );
# $element = $parser->pop( $element_reference );
# $element = $parser->pop( $test_function_ref );
  # Pop until we hit this item, or an item for which &$coderef($item) == true  
sub pop {
  my $parser = shift;
  my $popper = shift;
  
  my $n;
  foreach $n (0 .. $#{$parser->{'stack'}} ) { 
    my $item = $parser->{'stack'}->[$n];
    
    if ( ! $popper ? 1 
	   : (! ref $popper) ? UNIVERSAL::isa($item, $popper) 
	     : (ref $popper eq 'CODE') ? &$popper($item) 
		: $popper eq $item 				) {
      # pop the first $n -1 of 'em with warnings
      warn "Script Parser warning: closing '$popper' truncates " . 
      			@{$parser->{'stack'}}[ 0 .. $n -1 ] . "\n" if ( $n );
      foreach ( 1 .. $n ) { shift @{$parser->{'stack'}}; }
      return shift @{$parser->{'stack'}};
    }
  }
  
  warn "Script Parser error: unable to satisfy pop request for '$popper' \n";
}

1;


};
Script::Parser->import();
}

# Include Syntax Classes
BEGIN { 
$INC{'Script::Literal'} = 'lib/Script/Literal.pm';
eval {
### Script::Literal provides two classes for literals and escape sequences

### A Script::Literal is a chunk of text
  # $empty = Script::Literal->stopregex();	
  # Script::Literal->parse( $parser );
  # $literal = Script::Literal->new( $stringvalue );
  # $stringvalue = $literal->iswhitespace();
  # $stringvalue = $literal->interpret();
  # $stringvalue = $literal->source();

### An Script::EscapedLiteral is a backslashed sequence of characters.
  # $special_chars = Script::EscapedLiteral->stopregex()
  # Script::EscapedLiteral->parse( $parser );

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1997-10-31 Folded escaped literals into the Literal.pm file.
  # 1997-09-** Split from primary Script package and refactored.

### A Script::Literal is a chunk of text who's output is itself.

package Script::Literal;

BEGIN { 
Script::Element->import();
}
@ISA = qw( Script::Element );

BEGIN { 
Text::Excerpt->import(qw( printablestring ));
}

# $empty = Script::Literal->stopregex();	
sub stopregex { return ''; }

# Script::Literal->parse( $parser );
sub parse {
  my ($package, $parser) = @_;
  
  my $string = $parser->get_unspecial_string();
  
  return unless (defined $string and length $string);  # nothing to match
  
  $package->new( $string )->add_to_parse_tree( $parser );
  
  return 1; # sucessful match
}

# $literal = Script::Literal->new( $stringvalue );
sub new {
  my $package = shift;
  my $value = shift;
  $value = '' if (not defined $value);
  bless \$value, $package;
}

# $stringvalue = $literal->iswhitespace();
sub iswhitespace {
  my $literal = shift;
  return $$literal !~ /\S/ ? 1 : 0 ;
}

# $stringvalue = $literal->interpret();
sub interpret {
  my $literal = shift;
  return $$literal;
}

# $stringvalue = $literal->source();
sub source {
  my $literal = shift;
  return $$literal;
}

### An Script::EscapedLiteral is a backslashed sequence of characters.
  # Only in its parsing does it differ from a Script Literal.

package Script::EscapedLiteral;

BEGIN { 
Script::Literal->import();
}
@ISA = qw( Script::Literal );

# $special_chars = Script::EscapedLiteral->stopregex()
  # That mess of slashes turns out to match a single backslash character 
sub stopregex { return '\\\\'; }

# Script::EscapedLiteral->parse( $parser );
sub parse {
  my $package = shift;
  my $parser = shift;
  
  return unless ( $parser->get_text('\\\\') );
  
  # backslash newline gets thrown away to allow pretty-print indenting
  return 1 if ( $parser->get_text('\\r?\\n[ \\t]*') );
  
  my $string = '';
  if ( $string = $parser->get_text('[\\da-fA-F][\\da-fA-F]') ) {
    $string = pack("H2", $string); # found a double-digit hex escape
  } else {
    # Unix-style backslash-character escapes
    $string = $parser->get_text('.');
    if ($string eq 'r')    { $string = "\r"; } 
    elsif ($string eq 't') { $string = "\t"; } 
    elsif ($string eq 'n') { $string = "\n"; } 
    # any other character just gets inserted as itself
  }
  
  $package->new( $string )->add_to_parse_tree( $parser );
  
  return 1; # sucessful match
}

1;


};
Script::Literal->import();
}
Script::Parser->add_syntax( Script::EscapedLiteral );
Script::Parser->add_syntax( Script::Literal );

BEGIN { 
$INC{'Script::PoundTag'} = 'lib/Script/PoundTag.pm';
eval {
### Script::PoundTags are square brackets around a pound, method, and args.

### Change History
  # 1998-04-07 Added DRef-only syntax for non-method based invokation.
  # 1998-03-17 Created. -Simon

package Script::PoundTag;

$VERSION = 4.00_1998_03_17;

BEGIN { 
Script::Element->import();
}
@ISA = qw( Script::Element );

use Carp;
BEGIN { 
Data::DRef->import();
}
BEGIN { 
Err::Debug->import();
}
BEGIN { 
$INC{'Text::Words'} = 'lib/Text/Words.pm';
eval {
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
BEGIN { 
Text::Escape->import(qw( quote_non_words ));
}

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


};
Text::Words->import(qw( string2list ));
}
BEGIN { 
Text::Escape->import(qw( qprintable ));
}
BEGIN { 
Text::PropertyList->import(qw( astext ));
}

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


};
Script::PoundTag->import();
}
Script::Parser->add_syntax( Script::PoundTag );

# Enable script parsing for EvoScript tags: [tag arg=value]
BEGIN { 
$INC{'Script::Tag'} = 'lib/Script/Tag.pm';
eval {
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

BEGIN { 
Script::Element->import();
}
@ISA = qw( Script::Element );

use Carp;
BEGIN { 
Err::Debug->import();
}

BEGIN { 
Data::DRef->import();
}
BEGIN { 
Text::Words->import(qw( string2list string2hash hash2string ));
}

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
BEGIN { 
$INC{'Class::NamedFactory'} = 'lib/Class/NamedFactory.pm';
eval {
### Class::NamedFactory 
  # Provides class registration and by-name lookup methods

### Base Class Environment
  # $hashref = BASECLASS->subclasses_by_name();
  # @names = BASECLASS->subclass_names();
  # $SUBCLASS = BASECLASS->subclass_by_name( $name );

### SUBCLASS Registration
  # SUBCLASS->register_subclass_name();
  # $classname = SUBCLASS->subclass_name();

### Change History
  # 1998-02-25 Minor doc updates
  # 1997-11-24 Moved into the Class::* hierarchy, renamed to NamedFactory.
  # 1997-11-04 Created as Evo::SubclassFactory.

package Class::NamedFactory;

use Carp;

### Base Class Environment

# $hashref = BASECLASS->subclasses_by_name();
sub subclasses_by_name { croak "abstract" }	

# @names = BASECLASS->subclass_names();
sub subclass_names {
  my $package = shift;
  return keys %{ $package->subclasses_by_name };
}

# $SUBCLASS = BASECLASS->subclass_by_name( $name );
sub subclass_by_name {
  my $package = shift;
  my $name = shift;
  return $package->subclasses_by_name->{ $name };
}

### Subclass Registration

# SUBCLASS->register_subclass_name();
sub register_subclass_name {
  my $package = shift;
  $package->subclasses_by_name->{ $package->subclass_name } = $package;
}

# $classname = SUBCLASS->subclass_name();
sub subclass_name { croak "abstract" }

1;


};
Class::NamedFactory->import();
}
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


};
Script::Tag->import();
}
BEGIN { 
$INC{'Script::Container'} = 'lib/Script/Container.pm';
eval {
### Script::Container provides Tag classes with open and close forms.

### A Script::Container is a Tag with a contained sequence of tags
  # $container->add_to_parse_tree($parser);

### A Script::Closer is the dangly bit at the end of a container [/exmpl]
  # $closer->add_to_parse_tree($parser);

### A Script::TextContainer is a tag with non-script contents
  # $textcntr->add_to_parse_tree($parser);

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-08 Typo fixed in add_to_parse_tree().
  # 1998-04-03 Streamlining of parser interface.
  # 1997-10-27 Added TextContainer.
  # 1997-10-27 Folded Closer and Container into the same file.
  # 1997-10-25 Mods
  # 1997-??-?? Refactored script.pm

BEGIN { 
Script::Tag->import();
}

### A Script::Container is a Tag with a contained sequence of tags

package Script::Container;

BEGIN { 
Script::Tag->import();
}
push @ISA, qw( Script::Tag );

BEGIN { 
Script::Sequence->import();
}
push @ISA, qw( Script::Sequence );

# $container->add_to_parse_tree($parser);
  # When we've been parsed, we make ourselves the parser's current item;
  # a following closer tag, defined below, will hopefully mark our expiration.
sub add_to_parse_tree {
  my $container = shift;
  my $parser = shift;
  $parser->current->add($container);
  $parser->push($container);
}

# $script_text = $tag->source()
sub source {
  my $tag = shift;
  $tag->SUPER::source . $tag->source_contents . $tag->Script::Closer::source;
}

### A Script::Closer is the dangly bit at the end of a container [/exmpl]

package Script::Closer;

push @ISA, qw( Script::Tag );

# $closer->add_to_parse_tree($parser);
  # We don't actually add ourselves to the parse tree in this case; instead,
  # we pop our matching container off of the parser stack.
sub add_to_parse_tree {
  my $closer = shift;
  my $parser = shift;
  
  my $name = $closer->{'name'};
  $name =~ s/\A\///;
  $parser->pop( $closer->subclass_by_name( $name ) );
}

# $closetagtext = $tag->source();
sub source {
  my $tag = shift;
  return '[/' . $tag->{'name'} . ']';
}

sub subclass_name { '' }

### A Script::TextContainer is a tag with non-script contents

package Script::TextContainer;

push @ISA, qw( Script::Tag );

BEGIN { 
Text::Excerpt->import(qw( printablestring ));
}

# $textcntr->add_to_parse_tree($parser);
  # when we've been parsed, we go grab some additional text from the parser
sub add_to_parse_tree {
  my $textcntr = shift;
  my $parser = shift;
  
  my $contents = $parser->get_text('.+?\\[\\/' . $textcntr->{'name'} . '\\]');
  die "couldn't find end of '$textcntr->{'name'}' tag.\n" . $parser->{'text'} unless $contents;
  
  $contents =~ s/\[\/\Q$textcntr->{'name'}\E\]\Z//;
  $textcntr->{'contents'} = $contents;
  
  $parser->current->add($textcntr);
}

# $scripttext = $tag->source()
sub source {
  my $tag = shift;
  $tag->SUPER::source . $tag->{'contents'} . $tag->Script::Closer::source;
}

1;
};
Script::Container->import();
}
Script::Parser->add_syntax( Script::Tag );

# Get any defined tags
BEGIN { 
$INC{'Script::Tags::Available'} = 'lib/Script/Tags/Available.pm';
eval {
### Script::Tags::Available provides access to locally known tag classes

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-06-01 Added Random. -Dan
  # 1997-11-26 Created. -Simon

package Script::Tags::Available;

# Include EvoScript Tags
BEGIN { 
$INC{'Script::Tags::Print'} = 'lib/Script/Tags/Print.pm';
eval {
### Script::Tags::Print echoes the provided value with escape & format options 

### Interface
  # [print value=#x (plus=#n ifempty=alt format=fmt-name escape=esc-name)]
  # $text = $printtag->interpret();

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-03 Removed case option, replaced with new escaper functions.
  # 1998-03-11 Inline POD added.
  # 1998-01-11 Check for undefined value argument, substitute empty string.
  # 1997-10-28 Updated to use new Text::Escape interface.
  # 1997-09-?? Forked for four.
  # 1997-03-23 Improved exception handling.
  # 1997-03-11 Split from script.tags.pm
  # 1996-09-28 Name changed to print.
  # 1996-08-01 Initial creation of the value tag. -Simon

package Script::Tags::Print;

$VERSION = 4.00_1998_03_11;

BEGIN { 
Script::Tag->import();
}
push @ISA, qw( Script::Tag );

BEGIN { 
Err::Debug->import();
}

BEGIN { 
$INC{'Text::Format'} = 'lib/Text/Format.pm';
eval {
### Text::Format.pm - formatting routines for numbers, dates, and such like
  # 
  # We provide a by-name formatting function and some basic type handlers.
  # Each formatter takes a single simple scalar value and some optional
  # arguments to control the output, and returns another simple scalar.

### Change History
  # 1997-11-17 Created this package from code in Tags/Print etc. -Simon

package Text::Format;

use Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( formatted );

use Carp;

### Generic by-name interface

# %Formats - formatter function references by name
use vars qw( %Formats );

# Text::Format::add( $name, $subroutine );
sub add ($$) {
  my $name = shift;
  my $subroutine = shift;
  $Formats{ $name } = $subroutine;
}

# @defined_formats = Text::Format::names();
sub names () {
  return keys(%Formats);
}

# $formatted = formatted($format, $value); 
# @formatted = formatted($format, @values);
sub formatted ($@) {
  my $format = shift;
  my ($name, $args) = split(/\s+/, $format, 2);
  
  # warn "formatting $name $args \n";
  
  my @values = @_;
  croak "format called with multiple values but in scalar context"
					      if ($#values > 0 && ! wantarray);
  # warn "format values are @values \n";
  
  my $formatter = $Formats{ $name };
  croak "format called with undefined formatting style '$name'" 
						unless( $formatter );
  
  my $value;
  foreach $value ( @values ) {
    $value = &$formatter( $value, $args );
  }
  # warn "now values are @values \n";
  
  return wantarray ? @values : $values[0];
}

1;


};
Text::Format->import(qw( formatted ));
}
BEGIN { 
$INC{'DateTime::Formats'} = 'lib/DateTime/Formats.pm';
eval {
### DateTime::Formats provides a Text::Format intrface to date and time values.
  # 
  # Uses the following classes, defined other DateTime::* packages.
  # Duration - a length of time, measured in seconds
  # Times - a particular hour, minute, and second in a standard 24 hour day.
  # Dates - a particular year, month, and day, specifying a historical day
  # Moment - a particular time on a particular date
  # Periods - an earlier moment and a later moment
  # 
  # All of our numerical dow/moy indexes are 1 based.

### Formatter functions
  # $formatted = astime($value, $style);
  # Styles: hash	reference to hash with keys 'hour', 'minute', 'second'
  #         timestamp	890457284
  #         full	21:00:00
  #         24hr	21:00
  #         ampm	9:00pm
  #         short	9pm
  #
  # $formatted = asdate($value, $style);
  # Styles: hash	reference to hash with keys 'day', 'month', 'year'
  #         timestamp	890457284
  #         ymd 	19970101
  #         full	01/01/1997
  #         short	1/1/97
  #         long 	January 1, 1997
  #         complete 	Monday, January 1, 1997

### To Do
  # Use Class::Struct. Maybe use Time::tm.
  # Should remove limitations (by Unix datestamps) to the period 1970 - 2038.
  # Should create a moment which is a UDT, spawns date and time as needed.
  # Similarly, make date and time classes which are stored as a padded string

### Obsolete
  # @months = ( DateTime::Date->months );
  # @mons = ( DateTime::Date->mons );
  # @daynames = ( DateTime::Date->daysofweek) ;
  # sub num_days_in_month { DateTime::Date::days_in_month( @_ ); }
  # sub day_of_week { DateTime::Date::new_date_from_ymd( @_ )->dayofweek; }

### Copyright 1997 Evolution Online Systems, Inc.
  # M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 1998-01-22 Added complete format for dates.
  # 1998-01-06 Renamed this package DateTime::Formats; now uses Text::Format -S 
  # 1997-12-10 Moved to new source tree. -Jeremy
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-11 Working to integrate OOP code here.
  # 1997-06-10 Created OOP version.
  # 1997-03-27 Fixed a message that reported a time error instead of date.
  # 1997-02-01 Documentation cleanup, new two-year format for short years.
  # 1997-01-13 Created module from earlier date parsing/printing code. -Simon

package DateTime::Formats;

BEGIN { 
$INC{'Time::ParseDate'} = 'cpan-libs/Time/ParseDate.pm';
eval {

package Time::ParseDate;

require 5.000;

use Carp;
BEGIN { 
$INC{'Time::Timezone'} = 'cpan-libs/Time/Timezone.pm';
eval {

package Time::Timezone;

require 5.002;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(tz2zone tz_local_offset tz_offset tz_name);
@EXPORT_OK = qw();

use Carp;

# Parts stolen from code by Paul Foley <paul@ascent.com>

use vars qw($VERSION);

$VERSION = 97.011701;

sub tz2zone
{
	my($TZ, $time, $isdst) = @_;

	use vars qw(%tzn_cache);

	$TZ = defined($ENV{'TZ'}) ? ( $ENV{'TZ'} ? $ENV{'TZ'} : 'GMT' ) : ''
	    unless $TZ;

	# Hack to deal with 'PST8PDT' format of TZ
	# Note that this can't deal with all the esoteric forms, but it
	# does recognize the most common: [:]STDoff[DST[off][,rule]]

	if (! defined $isdst) {
		my $j;
		$time = time() unless $time;
		($j, $j, $j, $j, $j, $j, $j, $j, $isdst) = localtime($time);
	}

	if (defined $tzn_cache{$TZ}->[$isdst]) {
		return $tzn_cache{$TZ}->[$isdst];
	}
      
	if ($TZ =~ /^
		    ( [^:\d+\-,] {3,} )
		    ( [+-] ?
		      \d {1,2}
		      ( : \d {1,2} ) {0,2} 
		    )
		    ( [^\d+\-,] {3,} )?
		    /x
	    ) {
		$TZ = $isdst ? $4 : $1;
		$tzn_cache{$TZ} = [ $1, $4 ];
	} else {
		$tzn_cache{$TZ} = [ $TZ, $TZ ];
	}
	return $TZ;
}

sub tz_local_offset
{
	my ($time) = @_;

	$time = time() unless $time;
	my (@l) = localtime($time);
	my $isdst = $l[8];

	if (defined($Timezone::tz_local[$isdst])) {
		return $Timezone::tz_local[$isdst];
	}

	$Timezone::tz_local[$isdst] = &calc_off($time);

	return $Timezone::tz_local[$isdst];
}

sub calc_off
{
	my ($time) = @_;

	my (@l) = localtime($time);
	my (@g) = gmtime($time);

	my $off;

	$off =     $l[0] - $g[0]
		+ ($l[1] - $g[1]) * 60
		+ ($l[2] - $g[2]) * 3600;

	# subscript 7 is yday.

	if ($l[7] == $g[7]) {
		# done
	} elsif ($l[7] == $g[7] + 1) {
		$off += 86400;
	} elsif ($l[7] == $g[7] - 1) {
		$off -= 86400;
	} elsif ($l[7] < $g[7]) {
		# crossed over a year boundry!
		# localtime is beginning of year, gmt is end
		# therefore local is ahead
		$off += 86400;
	} else {
		$off -= 86400;
	}

	return $off;
}

# constants
# The rest of the file comes from Graham Barr <bodg@tiuk.ti.com>

CONFIG: {
	use vars qw(%dstZone %zoneOff %dstZoneOff %Zone);

	%dstZone = (
	#   "ndt"  =>   -2*3600-1800,	 # Newfoundland Daylight   
	    "adt"  =>   -3*3600,  	 # Atlantic Daylight   
	    "edt"  =>   -4*3600,  	 # Eastern Daylight
	    "cdt"  =>   -5*3600,  	 # Central Daylight
	    "mdt"  =>   -6*3600,  	 # Mountain Daylight
	    "pdt"  =>   -7*3600,  	 # Pacific Daylight
	    "ydt"  =>   -8*3600,  	 # Yukon Daylight
	    "hdt"  =>   -9*3600,  	 # Hawaii Daylight
	    "bst"  =>   +1*3600,  	 # British Summer   
	    "mest" =>   +2*3600,  	 # Middle European Summer   
	    "sst"  =>   +2*3600,  	 # Swedish Summer
	    "fst"  =>   +2*3600,  	 # French Summer
	    "wadt" =>   +8*3600,  	 # West Australian Daylight
	#   "cadt" =>  +10*3600+1800,	 # Central Australian Daylight
	    "eadt" =>  +11*3600,  	 # Eastern Australian Daylight
	    "nzdt" =>  +13*3600,  	 # New Zealand Daylight   
	);

	%Zone = (
	    "gmt"	=>   0,  	 # Greenwich Mean
	    "ut"        =>   0,  	 # Universal (Coordinated)
	    "utc"       =>   0,
	    "wet"       =>   0,  	 # Western European
	    "wat"       =>  -1*3600,	 # West Africa
	    "at"        =>  -2*3600,	 # Azores
	# For completeness.  BST is also British Summer, and GST is also Guam Standard.
	#   "bst"       =>  -3*3600,	 # Brazil Standard
	#   "gst"       =>  -3*3600,	 # Greenland Standard
	#   "nft"       =>  -3*3600-1800,# Newfoundland
	#   "nst"       =>  -3*3600-1800,# Newfoundland Standard
	    "ast"       =>  -4*3600,	 # Atlantic Standard
	    "est"       =>  -5*3600,	 # Eastern Standard
	    "cst"       =>  -6*3600,	 # Central Standard
	    "mst"       =>  -7*3600,	 # Mountain Standard
	    "pst"       =>  -8*3600,	 # Pacific Standard
	    "yst"	=>  -9*3600,	 # Yukon Standard
	    "hst"	=> -10*3600,	 # Hawaii Standard
	    "cat"	=> -10*3600,	 # Central Alaska
	    "ahst"	=> -10*3600,	 # Alaska-Hawaii Standard
	    "nt"	=> -11*3600,	 # Nome
	    "idlw"	=> -12*3600,	 # International Date Line West
	    "cet"	=>  +1*3600, 	 # Central European
	    "met"	=>  +1*3600, 	 # Middle European
	    "mewt"	=>  +1*3600, 	 # Middle European Winter
	    "swt"	=>  +1*3600, 	 # Swedish Winter
	    "fwt"	=>  +1*3600, 	 # French Winter
	    "eet"	=>  +2*3600, 	 # Eastern Europe, USSR Zone 1
	    "bt"	=>  +3*3600, 	 # Baghdad, USSR Zone 2
	#   "it"	=>  +3*3600+1800,# Iran
	    "zp4"	=>  +4*3600, 	 # USSR Zone 3
	    "zp5"	=>  +5*3600, 	 # USSR Zone 4
	#   "ist"	=>  +5*3600+1800,# Indian Standard
	    "zp6"	=>  +6*3600, 	 # USSR Zone 5
	# For completeness.  NST is also Newfoundland Stanard, and SST is also Swedish Summer.
	#   "nst"	=>  +6*3600+1800,# North Sumatra
	#   "sst"	=>  +7*3600, 	 # South Sumatra, USSR Zone 6
	    "wast"	=>  +7*3600, 	 # West Australian Standard
	#   "jt"	=>  +7*3600+1800,# Java (3pm in Cronusland!)
	    "cct"	=>  +8*3600, 	 # China Coast, USSR Zone 7
	    "jst"	=>  +9*3600,	 # Japan Standard, USSR Zone 8
	#   "cast"	=>  +9*3600+1800,# Central Australian Standard
	    "east"	=> +10*3600,	 # Eastern Australian Standard
	    "gst"	=> +10*3600,	 # Guam Standard, USSR Zone 9
	    "nzt"	=> +12*3600,	 # New Zealand
	    "nzst"	=> +12*3600,	 # New Zealand Standard
	    "idle"	=> +12*3600,	 # International Date Line East
	);

	%zoneOff = reverse(%Zone);
	%dstZoneOff = reverse(%dstZone);

	# Preferences

	$zoneOff{0}       = 'gmt';
	$dstZoneOff{3600} = 'bst';

}

sub tz_offset
{
	my ($zone, $time) = @_;

	return &tz_local_offset() unless($zone);

	$time = time() unless $time;
	my(@l) = localtime($time);
	my $dst = $l[8];

	$zone = lc $zone;

	if ($zone =~ /^([\-\+]\d{3,4})$/) {
		my $v = 0 + $1;
		return int($v / 100) * 60 + ($v % 100);
	} elsif (exists $dstZone{$zone} && ($dst || !exists $Zone{$zone})) {
		return $dstZone{$zone};
	} elsif(exists $Zone{$zone}) {
		return $Zone{$zone};
	}
	undef;
}

sub tz_name
{
	my ($off, $time) = @_;

	$time = time() unless $time;
	my(@l) = localtime($time);
	my $dst = $l[8];

	if (exists $dstZoneOff{$off} && ($dst || !exists $zoneOff{$off})) {
		return $dstZoneOff{$off};
	} elsif (exists $zoneOff{$off}) {
		return $zoneOff{$off};
	}
	sprintf("%+05d", int($off / 60) * 100 + $off % 60);
}

1;


};
Time::Timezone->import();
}
BEGIN { 
$INC{'Time::JulianDay'} = 'cpan-libs/Time/JulianDay.pm';
eval {
package Time::JulianDay;

require 5.000;

use Carp;
BEGIN { 
Time::Timezone->import();
}

@ISA = qw(Exporter);
@EXPORT = qw(julian_day inverse_julian_day day_of_week 
	jd_secondsgm jd_secondslocal 
	jd_timegm jd_timelocal 
	gm_julian_day local_julian_day 
	);
@EXPORT_OK = qw($brit_jd);

use integer;

# constants
use vars qw($brit_jd $jd_1970_1_1 $VERSION);

$VERSION = 96.032702;

# calculate the julian day, given $year, $month and $day
sub julian_day
{
    my($year, $month, $day) = @_;
    my($tmp);
    my($secs);

    use Carp;
#    confess() unless defined $day;

    $tmp = $day - 32075
      + 1461 * ( $year + 4800 - ( 14 - $month ) / 12 )/4
      + 367 * ( $month - 2 + ( ( 14 - $month ) / 12 ) * 12 ) / 12
      - 3 * ( ( $year + 4900 - ( 14 - $month ) / 12 ) / 100 ) / 4
      ;

    return($tmp);

}

sub gm_julian_day
{
    my($secs) = @_;
    my($sec, $min, $hour, $mon, $year, $day, $month);
    ($sec, $min, $hour, $day, $mon, $year) = gmtime($secs);
    $month = $mon + 1;
    $year += 100 if $year < 70;
    $year += 1900 if $year < 171;
    return julian_day($year, $month, $day)
}

sub local_julian_day
{
    my($secs) = @_;
    my($sec, $min, $hour, $mon, $year, $day, $month);
    ($sec, $min, $hour, $day, $mon, $year) = localtime($secs);
    $month = $mon + 1;
    $year += 100 if $year < 70;
    $year += 1900 if $year < 171;
    return julian_day($year, $month, $day)
}

sub day_of_week
{
	my ($jd) = @_;
        return (($jd + 1) % 7);       # calculate weekday (0=Sun,6=Sat)
}


# The following defines the first day that the Gregorian calendar was used
# in the British Empire (Sep 14, 1752).  The previous day was Sep 2, 1752
# by the Julian Calendar.  The year began at March 25th before this date.

$brit_jd = 2361222;

# Usage:  ($year,$month,$day) = &inverse_julian_day($julian_day)
sub inverse_julian_day
{
        my($jd) = @_;
        my($jdate_tmp);
        my($m,$d,$y);

        carp("warning: julian date $jd pre-dates British use of Gregorian calendar\n")
                if ($jd < $brit_jd);

        $jdate_tmp = $jd - 1721119;
        $y = (4 * $jdate_tmp - 1)/146097;
        $jdate_tmp = 4 * $jdate_tmp - 1 - 146097 * $y;
        $d = $jdate_tmp/4;
        $jdate_tmp = (4 * $d + 3)/1461;
        $d = 4 * $d + 3 - 1461 * $jdate_tmp;
        $d = ($d + 4)/4;
        $m = (5 * $d - 3)/153;
        $d = 5 * $d - 3 - 153 * $m;
        $d = ($d + 5) / 5;
        $y = 100 * $y + $jdate_tmp;
        if($m < 10) {
                $m += 3;
        } else {
                $m -= 9;
                ++$y;
        }
        return ($y, $m, $d);
}

$jd_1970_1_1 = 2440588;

sub jd_secondsgm
{
	my($jd, $hr, $min, $sec) = @_;

	return (($jd - $jd_1970_1_1) * 86400 + $hr * 3600 + $min * 60 + $sec);
}

sub jd_secondslocal
{
	my($jd, $hr, $min, $sec) = @_;
	my $jds = jd_secondsgm($jd, $hr, $min, $sec);
	return $jds - tz_local_offset($jds);
}

# this uses a 0-11 month to correctly reverse localtime()
sub jd_timelocal
{
	my ($sec,$min,$hours,$mday,$mon,$year) = @_;
	$year += 100 if $year < 70;
	$year += 1900 if $year < 1900;
	my $jd = julian_day($year, $mon+1, $mday);
	my $jds = jd_secondsgm($jd, $hours, $min, $sec);
	return $jds - tz_local_offset($jds);
}

# this uses a 0-11 month to correctly reverse gmtime()
sub jd_timegm
{
	my ($sec,$min,$hours,$mday,$mon,$year) = @_;
	$year += 100 if $year < 70;
	$year += 1900 if $year < 1900;
	my $jd = julian_day($year, $mon+1, $mday);
	return jd_secondsgm($jd, $hours, $min, $sec);
}

1;


};
Time::JulianDay->import();
}
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(parsedate);
@EXPORT_OK = qw(pd_raw %mtable %umult %wdays);

use integer;

# constants
use vars qw(%mtable %umult %wdays $VERSION);

$VERSION = 96.11_08_01;

# globals
use vars qw($debug); 

# dynamically-scoped
use vars qw($parse);

CONFIG:	{

	%mtable = qw(
		Jan 1  January 1
		Feb 2  February 2
		Mar 3  March 3
		Apr 4  April 4
		May 5 
		Jun 6  June 6 
		Jul 7  July 7 
		Aug 8  August 8 
		Sep 9  September 9 
		Oct 10 October 10 
		Nov 11 November 11 
		Dec 12 December 12 );
	%umult = qw(
		sec 1 second 1
		min 60 minute 60
		hour 3600
		day 86400
		week 604800 );
	%wdays = qw(
		sun 0 sunday 0
		mon 1 monday 1
		tue 2 tuesday 2
		wed 3 wednesday 3
		thu 4 thursday 4
		fri 5 friday 5
		sat 6 saturday 6
		);
}

sub parsedate
{
	my ($t, %options) = @_;

	my ($y, $m, $d);	# year, month - 1..12, day
	my ($H, $M, $S);	# hour, minute, second
	my $tz;		 	# timezone
	my $tzo;		# timezone offset
	my ($rd, $rs);		# relative days, relative seconds

	my $rel; 		# time&|date is relative

	my $isspec;
	my $now = $options{NOW} || time;
	my $passes = 0;
	my $uk = defined($options{UK})?$options{UK}:0;

	local $parse = '';  # will be dynamically scoped.

	if ($t =~ s#^   ([ \d]\d) 
			/ (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)
			/ (\d\d\d\d)
			: (\d\d)
			: (\d\d)
			: (\d\d)
			(?:
			 [ ]
			 ([-+] \d\d\d\d)
			  (?: \("?(?:(?:[A-Z]{1,4}[TCW56])|IDLE)\))?
			 )?
			##xi) { #"emacs
		# [ \d]/Mon/yyyy:hh:mm:ss [-+]\d\d\d\d
		# This is the format for www server logging.

		($d, $m, $y, $H, $M, $S, $tzo) = ($1, $mtable{"\u\L$2"}, $3, $4, $5, $6, $7 ? &mkoff($7) : ($tzo || undef));
		$parse .= " ".__LINE__ if $debug;
	} elsif ($t =~ s#^(\d\d)/(\d\d)/(\d\d)\.(\d\d)\:(\d\d)(\s+|$)##) {
		# yy/mm/dd.hh:mm
		# I support this format because it's used by wbak/rbak
		# on Apollo Domain OS.  Silly, but historical.

		($y, $m, $d, $H, $M, $S) = ($1, $2, $3, $4, $5, 0);
		$parse .= " ".__LINE__ if $debug;
	} else {
		while(1) {
			if (! defined $m and ! defined $rd and ! defined $y
				and ! ($passes == 0 and $options{'TIMEFIRST'}))
			{
				# no month defined.
				if (&parse_date_only(\$t, \$y, \$m, \$d, $uk)) {
					$parse .= " ".__LINE__ if $debug;
					next;
				}
			}
			if (! defined $H and ! defined $rs) {
				if (&parse_time_only(\$t, \$H, \$M, \$S, 
					\$tz, %options)) 
				{
					$parse .= " ".__LINE__ if $debug;
					next;
				}
			}
			next if $passes == 0 and $options{'TIMEFIRST'};
			if (! defined $y) {
				if (&parse_year_only(\$t, \$y)) {
					$parse .= " ".__LINE__ if $debug;
					next;
				}
			}
			if (! defined $tz and ! defined $tzo and ! defined $rs 
				and (defined $m or defined $H)) 
			{
				if (&parse_tz_only(\$t, \$tz, \$tzo)) {
					$parse .= " ".__LINE__ if $debug;
					next;
				}
			}
			if (! defined $H and ! defined $rs) {
				if (&parse_time_offset(\$t, \$rs, %options)) {
					$rel = 1;
					$parse .= " ".__LINE__ if $debug;
					next;
				}
			}
			if (! defined $m and ! defined $rd and ! defined $y) {
				if (&parse_date_offset(\$t, $now, \$y, 
					\$m, \$d, \$rd, \$rs, %options)) 
				{
					$rel = 1;
					$parse .= " ".__LINE__ if $debug;
					next;
				}
			}
			if (defined $M or defined $rd) {
				if ($t =~ s/^\s*(?:at|\+)\s*(\s+|$)//x) {
					$rel = 1;
					$parse .= " ".__LINE__ if $debug;
					next;
				}
			}
			last;
		} continue {
			print "context$parse remaider = $t.\n" if $debug;
			$passes++;
		}

		if ($passes == 0) {
			print "nothing matched\n" if $debug;
			return undef;
		}
	}

	if ($debug) {
		print "t: $t.\n";
		print defined($tz) ? "tz: $tz.\n" : "no tz\n";
		print defined($tzo) ? "tzo: $tzo.\n" : "no tzo\n";
		print "HMS: ";
		print defined($H) ? "$H, " : "no H, ";
		print defined($M) ? "$M, " : "no M, ";
		print defined($S) ? "$S\n" : "no S.\n";
		print "mdy: ";
		print defined($m) ? "$m, " : "no m, ";
		print defined($d) ? "$d, " : "no d, ";
		print defined($y) ? "$y\n" : "no y.\n";
		print defined($rs) ? "rs: $rs.\n" : "no rs\n";
		print defined($rd) ? "rs: $rd.\n" : "no rd\n";
		print "parse:$parse\n";
		print "passes: $passes\n";
	}

	$t =~ s/^\s+//;

	if ($t ne '') {
		# we didn't manage to eat the string
		print "NOT WHOLE\n" if $debug;
		return undef if $options{WHOLE};
	}

	# define a date if there isn't one already

	if (! defined $y and ! defined $m and ! defined $rd) {
		print "no date defined, trying to find one." if $debug;
		if (defined $rs or defined $H) {
			# we do have a time.
			return undef if $options{DATE_REQUIRED};
			if (defined $rs) {
				print "simple offset: $rs\n" if $debug;
				return $now + $rs 
			}
			$rd = 0;
		} else {
			print "no time either!\n" if $debug;
			return undef;
		}
	}


	return undef if $options{TIME_REQUIRED} && ! defined($rs) 
		&& ! defined($H) && ! defined($rd);

	my $secs;
	my $jd;

	if (defined $rd) {
		if (defined $rs) {
			print "fully relative\n" if $debug;
			my ($j, $in, $it);
			my ($isdst_now, $isdst_then);
			my $r = $now + $rd * 86400 + $rs;
			#
			# It's possible that there was a timezone shift 
			# during the time specified.  If so, keep the
			# hours the "same".
			#
			$isdst_now = (localtime($r))[8];
			$isdst_then = (localtime($now))[8];
			return $r if ($isdst_now == $isdst_then) || $options{GMT};
			print "localtime changed DST during time period!\n" if $debug;
		}

		print "relative date\n" if $debug;
		$jd = local_julian_day($now);
		print "jd($now) = $jd\n" if $debug;
		$jd += $rd;
	} else {
		unless (defined $y) {
			if ($options{PREFER_PAST}) {
				my ($day, $mon011);
				($day, $mon011, $y) = (&righttime($now))[3,4,5];

				print "calc year -past $day-$d $mon011-$m $y\n" if $debug;
				$y -= 1 if ($mon011+1 < $m) || 
					(($mon011+1 == $m) && ($day < $d));
			} elsif ($options{PREFER_FUTURE}) {
				print "calc year -future\n" if $debug;
				my ($day, $mon011);
				($day, $mon011, $y) = (&righttime($now))[3,4,5];
				$y += 1 if ($mon011 >= $m) || 
					(($mon011+1 == $m) && ($day > $d));
			} else {
				print "calc year -this\n" if $debug;
				$y = (localtime($now))[5];
			}
		}

		$y += 100  if $y < 70;
		$y += 1900 if $y < 171;

		$jd = julian_day($y, $m, $d);
		print "jd($y, $m, $d) = $jd\n" if $debug;
	}


	# put time into HMS

	if (! defined($H)) {
		if (defined($rd) || defined($rs)) {
			($S, $M, $H) = &righttime($now, %options);
			print "HMS set to $H $M $S\n" if $debug;
		} 
	}

	my $carry;

	print "before $rs $jd $H $M $S\n" if $debug;
	#
	# add in relative seconds.  Do it this way because we want to
	# preserve the localtime across DST changes.
	#

	$S = 0 unless $S; # -w
	$M = 0 unless $M; # -w
	$H = 0 unless $H; # -w

	$S += $rs if defined $rs;
	$carry = int($S / 60);
	$S %= 60;
	$M += $carry;
	$carry = int($M / 60);
	$M %= 60;
	$H += $carry;
	$carry = int($H / 24);
	$H %= 24;
	$jd += $carry;

	print "after rs  $jd $H $M $S\n" if $debug;

	$secs = jd_secondsgm($jd, $H, $M, $S);
	print "jd_secondsgm($jd, $H, $M, $S) = $secs\n" if $debug;

	# 
	# If we see something link 3pm CST then and we want to end
	# up with a GMT seconds, then we convert the 3pm to GMT and
	# subtract in the offset for CST.  We subtract because we
	# are converting from CST to GMT.
	#
	my $tzadj;
	if ($tz) {
		$tzadj = tz_offset($tz, $secs);
		print "adjusting secs for $tz: $tzadj\n" if $debug;
		$secs -= $tzadj;
	} elsif (defined $tzo) {
		print "adjusting time for offset: $tzo\n" if $debug;
		$secs -= $tzo;
	} else {
		unless ($options{GMT}) {
			if ($options{ZONE}) {
				$tzadj = tz_offset($options{ZONE}, $secs);
				print "adjusting secs for $options{ZONE}: $tzadj\n" if $debug;
				$secs -= $tzadj;
			} else {
				$tzadj = tz_local_offset($secs);
				print "adjusting secs for local offset: $tzadj\n" if $debug;
				$secs -= $tzadj;
			}
		}
	}

	print "returning $secs.\n" if $debug;

	return $secs;
}


sub mkoff
{
	my($offset) = @_;

	if (defined $offset and $offset =~ s#^([-+])(\d\d)(\d\d)$##) {
		return ($1 eq '+' ? 
			  3600 * $2  + 60 * $3
			: -3600 * $2 + -60 * $3 );
	}
	return undef;
}

sub parse_tz_only
{
	my($tr, $tz, $tzo) = @_;

	$$tr =~ s#^\s+##;
	my $o;

	if ($$tr =~ s#^
			([-+]\d\d\d\d)
			\s+
			\(
				"?
				(?:
					(?:
						[A-Z]{1,4}[TCW56]
					)
					|
					IDLE
				)
			\)
			(?:
				\s+
				|
				$ 
			)
			##x) { #"emacs
		$$tzo = &mkoff($1);
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^GMT\s*([-+]\d{1,2})(\s+|$)##x) {
		$o = $1;
		if ($o <= 24 and $o !~ /^0/) {
			# probably hours.
			printf "adjusted at %d. ($o 00)\n", __LINE__ if $debug;
			$o = "${o}00";
		}
		$o =~ s/\b(\d\d\d)/0$1/;
		$$tzo = &mkoff($o);
		printf "matched at %d. ($$tzo, $o)\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^(?:GMT\s*)?([-+]\d\d\d\d)(\s+|$)##x) {
		$o = $1;
		$$tzo = &mkoff($o);
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^"?((?:[A-Z]{1,4}[TCW56])|IDLE)(?:\s+|$ )##x) { #"
		$$tz = $1;
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	}
	return 0;
}

sub parse_date_only
{
	my ($tr, $yr, $mr, $dr, $uk) = @_;

	$$tr =~ s#^\s+##;

	if ($$tr =~ s#^(\d\d\d\d)([-./])(\d\d?)\2(\d\d?)(\s+|$)##) {
		# yyyy/mm/dd

		($$yr, $$mr, $$dr) = ($1, $3, $4);
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^(\d\d)([-./])(\d\d?)\2(\d\d\d\d?)(\s+|$)##) {
		# mm/dd/yyyy - is this safe?  No.
		# -- or dd/mm/yyyy! If $1>12, then it's umabiguous.
		# Otherwise check option UK for UK style date.
		if ($uk || $1>12) {
		  ($$yr, $$mr, $$dr) = ($4, $3, $1);
		} else {
		  ($$yr, $$mr, $$dr) = ($4, $1, $3);
		}
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^(\d\d\d\d)/(\d\d?)(?:\s|$ )##x) {
		# yyyy/mm

		($$yr, $$mr, $$dr) = ($1, $2, 1);
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^(?xi)
			(?:
				(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun),?
				\s+
			)?
			(\d\d?)
			(\s+ | - | \. | /)
			(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)
			(?:
				\2
				(\d\d (?:\d\d)? )
			)?
			(?:
				\s+
			|
				$
			)
			##) {
		# [Dow,] dd Mon [yy[yy]]
		($$yr, $$mr, $$dr) = ($4, $mtable{"\u\L$3"}, $1);

		printf "%d: %s - %s - %s\n", __LINE__, $1, $2, $3 if $debug;
		print "y undef\n" if ($debug && ! defined($$yr));
		return 1;
	} elsif ($$tr =~ s#^(?xi)
			(?:
				(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun),?
				\s+
			)?
			(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)
			(\s+ | - | \. | /)
				
			(\d\d?)
			(?:
				\2
				(\d\d (?: \d\d)?)
			)?
			(?:
				\s+
			|
				$
			)
			##) {
		# [Dow,] Mon dd [yyyy]
		($$yr, $$mr, $$dr) = ($4, $mtable{"\u\L$1"}, $3);
		printf "%d: %s - %s - %s\n", __LINE__, $1, $2, $3 if $debug;
		print "y undef\n" if ($debug && ! defined($$yr));
		return 1;
	} elsif ($$tr =~ s#^(?xi)
			(January|Jan|February|Feb|March|Mar|April|Apr|May|
			    June|Jun|July|Jul|August|Aug|September|Sep|
			    October|Oct|November|Nov|December|Dec)
			\s+
			(\d+)
			(?:st|nd|rd|th)?
			\,?
			(?: 
				\s+
				(?:
					(\d\d\d\d)
					|(?:\' (\d\d))
				)
			)?
			(?:
				\s+
			|
				$
			)
			##) {
		# Month day{st,nd,rd,th}, 'yy
		# Month day{st,nd,rd,th}, year
		($$yr, $$mr, $$dr) = ($3 || $4, $mtable{"\u\L$1"}, $2);
		printf "%d: %s - %s - %s - %s\n", __LINE__, $1, $2, $3, $4 if $debug;
		print "y undef\n" if ($debug && ! defined($$yr));
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^(\d\d?)([-/.])(\d\d?)\2(\d\d?)(\s+|$)##x) {
		if ($1 > 31 || (!$uk && $1 > 12 && $4 < 32)) {
			# yy/mm/dd
			($$yr, $$mr, $$dr) = ($1, $3, $4);
		} elsif ($1 > 12 || $uk) {
			# dd/mm/yy
			($$yr, $$mr, $$dr) = ($4, $3, $1);
		} else {
			# mm/dd/yy
			($$yr, $$mr, $$dr) = ($4, $1, $3);
		}
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^(\d\d?)/(\d\d?)(\s+|$)##x) {
		if ($1 > 31 || (!$uk && $1 > 12)) {
			# yy/mm
			($$yr, $$mr, $$dr) = ($1, $2, 1);
		} elsif ($2 > 31 || ($uk && $2 > 12)) {
			# mm/yy
			($$yr, $$mr, $$dr) = ($2, $1, 1);
		} elsif ($1 > 12 || $uk) {
			# dd/mm
			($$mr, $$dr) = ($2, $1);
		} else {
			# mm/dd
			($$mr, $$dr) = ($1, $2);
		}
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^(\d\d)(\d\d)(\d\d)(\s+|$)##x) {
		if ($1 > 31 || (!$uk && $1 > 12)) {
			# YYMMDD
			($$yr, $$mr, $$dr) = ($1, $2, $3);
		} elsif ($1 > 12 || $uk) {
			# DDMMYY
			($$yr, $$mr, $$dr) = ($3, $2, $1);
		} else {
			# MMDDYY
			($$yr, $$mr, $$dr) = ($3, $1, $2);
		}
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^(?xi)
			(\d{1,2})
			(\s+ | - | \. | /)
			(January|Jan|February|Feb|March|Mar|April|Apr|May|
			    June|Jun|July|Jul|August|Aug|September|Sep|
			    October|Oct|November|Nov|December|Dec)
			(?:
				\2
				(
					\d\d
					(?:\d\d)?
				)
			)
			(:?
				\s+
			|
				$
			)
			##) {
		# dd Month [yr]
		($$yr, $$mr, $$dr) = ($4, $mtable{"\u\L$3"}, $1);
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^(?xi)
			(\d+)
			(?:st|nd|rd|th)
			\s+
			(January|Jan|February|Feb|March|Mar|April|Apr|May|
			    June|Jun|July|Jul|August|Aug|September|Sep|
			    October|Oct|November|Nov|December|Dec)
			(?: 
				\,?
				\s+
				(\d\d\d\d)
			)?
			(:?
				\s+
			|
				$
			)
			##) {
		# day{st,nd,rd,th}, Month year
		($$yr, $$mr, $$dr) = ($3, $mtable{"\u\L$2"}, $1);
		printf "%d: %s - %s - %s - %s\n", __LINE__, $1, $2, $3, $4 if $debug;
		print "y undef\n" if ($debug && ! defined($$yr));
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	}
	return 0;
}

sub parse_time_only
{
	my ($tr, $hr, $mr, $sr, $tzr, %options) = @_;

	$$tr =~ s#^\s+##;

	if ($$tr =~ s!^(?x)
			(?:
				(?:
					([012]\d)		(?# $1)
					(?:
						([0-5]\d) 	(?# $2)
						(?:
						    ([0-5]\d)	(?# $3)
						)?
					)
					\s*
					([ap]m)?  		(?# $4)
				) | (?:
					(\d{1,2}) 		(?# $5)
					(?:
						\:
						(\d\d)		(?# $6)
						(?:
							\:
							(\d\d)	(?# $7)
						)?
					)
					\s*
					([apAP][mM])?		(?# $8)
				) | (?:
					(\d{1,2})		(?# $9)
					([apAP][mM])		(?# ${10})
				)
			)
			(?:
				\s+
				"?
				(				(?# ${11})
					(?: [A-Z]{1,4}[TCW56] )
					|
					IDLE
				)	
			)?
			(?:
				\s+
			|
				$
			)
			!!) { #"emacs
		# HH[[:]MM[:SS]]meridan [zone] 
		my $ampm;
		$$hr = $1 || $5 || $9 || 0; # 9 is undef, but 5 is defined..
		$$mr = $2 || $6 || 0;
		$$sr = $3 || $7 || 0;
		$ampm = $4 || $8 || $10;
		$$tzr = $11;
		$$hr += 12 if $ampm and "\U$ampm" eq "PM" && $$hr != 12;
		$$hr = 0 if $$hr == 12 && "\U$ampm" eq "AM";
		$$hr = 0 if $$hr == 24;
		printf "matched at %d, rem = %s.\n", __LINE__, $$tr if $debug;
		return 1;
	} elsif ($$tr =~ s#noon(?:\s+|$ )##ix) {
		# noon
		($$hr, $$mr, $$sr) = (12, 0, 0);
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#midnight(?:\s+|$ )##ix) {
		# midnight
		($$hr, $$mr, $$sr) = (0, 0, 0);
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	}
	return 0;
}

sub parse_time_offset
{
	my ($tr, $rsr, %options) = @_;

	$$tr =~ s/^\s+//;

	return 0 if $options{NO_RELATIVE};

	if ($$tr =~ s#^(?xi)
			(?:
				(\+ | \-)
				\s*
			)?
			(\d+)
			\s*
			(sec|second|min|minute|hour)s?
			(?:
				\s+
				|
				$
			)
			##) {
		# count units
		$$rsr = 0 unless defined $$rsr;
		$$rsr += $umult{"\L$3"} * "$1$2";
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} 
	return 0;
}

sub calc 
{
	my ($rsr, $yr, $mr, $dr, $rdr, $now, $units, $count, %options) = @_;

	$units = "\L$units";

	if ($units eq 'day') {
		$$rdr = $count;
	} elsif ($units eq 'week') {
		$$rdr = $count * 7;
	} elsif ($umult{$units}) {
		$$rsr = $count * $umult{$units};
	} elsif ($units eq 'mon' || $units eq 'month') {
		($$yr, $$mr, $$dr) = &monthoff($now, $count, %options);
		$$rsr = 0 unless $$rsr;
	} elsif ($units eq 'year') {
		($$yr, $$mr, $$dr) = &monthoff($now, $count * 12, %options);
		$$rsr = 0 unless $$rsr;
	} else {
		carp "interal error";
	}
	print "calced rsr $$rsr rdr $$rdr, yr $$yr mr $$mr dr $$dr.\n" if $debug;
}

sub monthoff
{
	my ($now, $months, %options) = @_;

	# months are 0..11
	my ($j, $j, $j, $d, $m11, $y) = &righttime($now, %options);

	$y += 100  if $y < 70;
	$y += 1900 if $y < 171;

	print "m11 = $m11 + $months, y = $y\n" if $debug;

	$m11 += $months;
	if ($m11 > 11 || $m11 < 0) {
		$y -= 1 if $m11 < 0;
		$y += int($m11/12);

		# this is required to work around a bug in perl 5.003
		no integer;
		$m11 %= 12;
	}
	print "m11 = $m11, y = $y\n" if $debug;

	# 
	# What is "1 month from January 31st?"  
	# I think the answer is February 28th most years.
	#
	# Similarly, what is one year from February 29th, 1980?
	# I think it's February 28th, 1981.
	#
	# If you disagree, change the following code.
	#
	if ($d > 30 or ($d > 28 && $m11 == 1)) {
$INC{'Time::DaysInMonth'} = 'cpan-libs/Time/DaysInMonth.pm';
eval {
package Time::DaysInMonth;

use Carp;

require 5.000;

@ISA = qw(Exporter);
@EXPORT = qw(days_in is_leapyear);
@EXPORT_OK = qw(%mltable);


use vars qw($VERSION %mltable);

$VERSION = 96.032702;

CONFIG:	{
	%mltable = qw(
		 1	31
		 3	31
		 4	30
		 5	31
		 6	30
		 7	31
		 8	31
		 9	30
		10	31
		11	30
		12	31);
}

sub days_in
{
	# Month is 1..12
	my ($year, $month) = @_;
	return $mltable{$month+0} unless $month == 2;
	return 28 unless &is_leap($year);
	return 29;
}

sub is_leap
{
	my ($year) = @_;
	return 0 unless $year % 4 == 0;
	return 1 unless $year % 100 == 0;
	return 0 unless $year % 400 == 0;
	return 1;
}

1;


};
		my $dim = Time::DaysInMonth::days_in($y, $m11+1);
		print "dim($y,$m11+1)= $dim\n" if $debug;
		$d = $dim if $d > $dim;
	}
	return ($y, $m11+1, $d);
}

sub righttime
{
	my ($time, %options) = @_;
	if ($options{GMT}) {
		return gmtime($time);
	} else {
		return localtime($time);
	}
}

sub parse_year_only
{
	my ($tr, $yr) = @_;

	$$tr =~ s#^\s+##;

	if ($$tr =~ s#^(\d\d\d\d)(?:\s+|$)##) {
		$$yr = $1;
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#\'(\d\d)(?:\s+|$ )##) {
		$$yr = $1;
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	}
	return 0;
}

sub parse_date_offset
{
	my ($tr, $now, $yr, $mr, $dr, $rdr, $rsr, %options) = @_;

	return 0 if $options{NO_RELATIVE};

	# now - current seconds_since_epoch
	# yr - year return
	# mr - month return
	# dr - day return
	# rdr - relatvie day return
	# rsr - relative second return

	my $j;
	my $wday = (&righttime($now, %options))[6];

	$$tr =~ s#^\s+##;

	if ($$tr =~ s#^(?xi)
			(?:
				(?:
					now
					\s+
				)?
				(\+ | \-)
				\s*
			)?
			(\d+)
			\s*
			(day|week|month|year)s?
			##) {
		my ($one, $two) = ($1, $2);
		$one = '' unless defined $one;
		$two = '' unless defined $two;
		&calc($rsr, $yr, $mr, $dr, $rdr, $now, $3, 
			"$one$two", %options);
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^(?xi)
			(Mon|Tue|Wed|Thu|Fri|Sat|Sun|Monday|Tuesday
				|Wednesday|Thursday|Friday|Saturday|Sunday)
			\s+
			after
			\s+
			next
			(?: \s+ | $ )
			##) {
		# Dow "after next"
		$$rdr = $wdays{"\L$1"} - $wday + ( $wdays{"\L$1"} > $wday ? 7 : 14);
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^(?xi)
			next\s+
			(Mon|Tue|Wed|Thu|Fri|Sat|Sun|Monday|Tuesday
				|Wednesday|Thursday|Friday|Saturday|Sunday)
			(?:\s+|$ )
			##) {
		# "next" Dow
		$$rdr = $wdays{"\L$1"} - $wday 
				+ ( $wdays{"\L$1"} > $wday ? 0 : 7);
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^(?xi)
			last\s+
			(Mon|Tue|Wed|Thu|Fri|Sat|Sun|Monday|Tuesday
				|Wednesday|Thursday|Friday|Saturday|Sunday)
			(?:\s+|$ )##) {
		# "last" Dow
		printf "c %d - %d + ( %d < %d ? 0 : -7 \n", $wdays{"\L$1"},  $wday,  $wdays{"\L$1"}, $wday if $debug;
		$$rdr = $wdays{"\L$1"} - $wday + ( $wdays{"\L$1"} < $wday ? 0 : -7);
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($options{PREFER_PAST} and $$tr =~ s#^(?xi)
			(Mon|Tue|Wed|Thu|Fri|Sat|Sun|Monday|Tuesday
				|Wednesday|Thursday|Friday|Saturday|Sunday)
			(?:\s+|$ )##) {
		# Dow
		printf "c %d - %d + ( %d < %d ? 0 : -7 \n", $wdays{"\L$1"},  $wday,  $wdays{"\L$1"}, $wday if $debug;
		$$rdr = $wdays{"\L$1"} - $wday + ( $wdays{"\L$1"} < $wday ? 0 : -7);
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($options{PREFER_FUTURE} and $$tr =~ s#^(?xi)
			(Mon|Tue|Wed|Thu|Fri|Sat|Sun|Monday|Tuesday
				|Wednesday|Thursday|Friday|Saturday|Sunday)
			(?:\s+|$ )
			##) {
		# Dow
		$$rdr = $wdays{"\L$1"} - $wday 
				+ ( $wdays{"\L$1"} > $wday ? 0 : 7);
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^today(?:\s+|$ )##xi) {
		# today
		$$rdr = 0;
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^tomorrow(?:\s+|$ )##xi) {
		$$rdr = 1;
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^yesterday(?:\s+|$ )##xi) {
		$$rdr = -1;
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^last\s+(week|month|year)(?:\s+|$ )##xi) {
		&calc($rsr, $yr, $mr, $dr, $rdr, $now, $1, -1, %options);
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^next\s+(week|month|year)(?:\s+|$ )##xi) {
		&calc($rsr, $yr, $mr, $dr, $rdr, $now, $1, 1, %options);
		printf "matched at %d.\n", __LINE__ if $debug;
		return 1;
	} elsif ($$tr =~ s#^now (?: \s+ | $ )##x) {
		$$rdr = 0;
		return 1;
	}
	return 0;
}

1;


};
Time::ParseDate->import();
}
use Time::Local;

BEGIN { 
Text::PropertyList->import();
}

require Exporter;
@ISA = ('Exporter');
@EXPORT = qw[ asdate astime ];

BEGIN { 
Text::Format->import();
}
Text::Format::add( 'asdate',   \&asdate );
Text::Format::add( 'astime',   \&astime );

BEGIN { 
$INC{'DateTime::Date'} = 'lib/DateTime/Date.pm';
eval {
### DATE - a day in history

### Creators
  # $date = DateTime::Date->new();
  # $equivalent_date = $date->clone;
  # $date = current_date();
  # $date->set_current();
  # $date = new_date_from_ymd( $year, $month, $day );
  # $date = new_date_from_value( $value );
  # $date->set_from_scalar( $value )

### Value Access
  # $year = $date->year; or pass ($year) to set it
  # $month = $date->month; or pass ($month) to set it
  # $day = $date->day; or pass ($day) to set it
  # ($year, $month, $day) = $date->ymd; or pass ($year, $month, $day) to set
  # $udt = $date->udt; or pass ($udt) to set it; UDT means Unix DateTime

### Calendar Features
  # $daysinmonth = $date->num_days_in_month;
  # $date->make_day_valid;
  # $flag = $date->check_day_bounds;
  # $dow_from_one_to_seven = $date->dayofweek; #!# or pass ($flag), opt -1/0/+1
  # $weekofyear = $date->weekofyear; #!# or pass ($weekofyear) to set
  # $holidayname_or_zero = $date->isholiday;  #!# Need to build a holiday table
  # $flag = $date->isweekend;  #!# or pass ($flag), add -1/0/+1 for direction
  # $flag = $date->isbusinessday; #!# or pass ($flag), add -1/0/+1 for directn
  # ($nth, $dayofweek) = $date->nthweekday; or pass ($nth, $dayofweek) to set
  # $flag = $date->firstdayofmonth; or pass ($flag) to set it
  # $flag = $date->lastdayofmonth; or pass ($flag) to set it

### Display Output
  # $month = $date->month_name;
  # @names_of_months = months();
  # $short_name_for_month = $date->mon;
  # @short_names_of_months = mons();
  # $dayofweek = $date->dayofweek;
  # @daysofweek = daysofweek();
  # $zero_padded_string = $date->zero_padded( $value, $field_size || 2 );
  # $four_digit_year = $date->yyyy;
  # $two_digit_month = $date->mm;
  # $two_digit_day = $date->dd;
  # $yyyymmdd = $date->yyyymmdd;
  # $m/d/year = $date->full;
  # $m/d/yy = $date->short;
  # $monthdaycommayear = $date->long;
  # $dowcommamonthdaycommayear = $date->complete;

### Spinoffs
  # $duration = $date->duration_to_date($other_date);
  # $julianday = $date->julianday; or pass ($julianday) to set
  #   A julian day is represented as a number of actual historical days since
  #   some very long ago day. Therefore, you can add a number of days and get
  #   back the correct day, compensating for leap years, Gregorianism, etc.

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon	   M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 1998-05-14 Added expressions to set_from_scalar to accept formats
  #            "dd Month yy", "Mon yyyy dd", and "yyyy Mon dd". -Dan
  # 1998-05-14 Modified set_from_scalar to accept date format yyyy mm dd. -Dan
  # 1998-01-22 Added complete format for dates.
  # 1997-12-10 Moved to new source tree. -Jeremy
  # 19970930 Fixed parsing of m/yy dates (we pick the first day of that month).
  # 19970924 IntraNetics97 Version 1.00.000
  # 19970611 Cleanup.
  # 19970610 Created module. -Simon

package DateTime::Date;

use integer;

BEGIN { 
Time::ParseDate->import();
}
use Time::Local;
BEGIN { 
Time::JulianDay->import();
}

use Exporter;
push @ISA, qw( Exporter );
@EXPORT = qw( current_date new_date_from_value );

### Creators

# $date = DateTime::Date->new();
sub new {
  my ($package) = @_;
  my $date = { 'year' => 1970, 'month' => 1, 'day' => 1 };
  bless $date, $package;
}

# $equivalent_date = $date->clone;
sub clone {
  my $date = shift;
  my $package = ref $date;
  my $clone = $package->new;
  $clone->ymd( $date->ymd );
  return $clone;
}

# $date = current_date();
sub current_date {
  my $date = DateTime::Date->new;
  $date->set_current;
  return $date;
}

# $date->set_current();
sub set_current {
  my $date = shift;
  $date->udt( time() );
}

# $date = new_date_from_ymd( $year, $month, $day );
sub new_date_from_ymd {
  my $date = DateTime::Date->new;
  $date->ymd( @_ );
  return $date;
}

# $date = new_date_from_value( $value );
sub new_date_from_value {
  my $date = DateTime::Date->new;
  $date->set_from_scalar( @_ );
  return $date;
}

# $date->set_from_scalar( $value )
  # $value can be just about any date format
sub set_from_scalar {
  my ($date, $value) = @_;
  my %months = qw(
    january	1
    february	2
    march	3
    april	4
    june	6
    july	7
    august	8
    september	9
    october	10
    november	11
    december	12
  );
  my %short_months = qw(
    jan	1
    feb	2
    mar	3
    apr	4
    may	5
    jun	6
    jul	7
    aug	8
    sep	9
    oct	10
    nov	11
    dec	12
  );

  # warn "scalar is '$value'"; 
  if ( ref $value eq 'HASH' ) {
    $date->ymd($value->{'year'},$value->{'month'},$value->{'day'});
  } elsif ($value =~ /^\s*(\d{1,2})\D(\d{1,2})\s*$/) {
    my ($month, $day) = ($1, $2);
    $date->set_current;
    my $year = $date->year;
    # Fix for mm/yy format
    if ( $day > 50 ) { $year = $day + 1900; $day = 1; }
    $date->ymd( $year, $month, $day );
  } elsif ($value =~ /^\s*(\d{1,2})\D(\d{1,2})\D(\d{2})\s*$/) {
    my ($year, $month, $day) = ( $3, $1, $2 );
    $year += 1900;
    $year += 100 if ( $year < 1950 );
    $date->ymd($year, $month, $day);
  } elsif ($value =~ /^\s*(\d{1,2})\D(\d{1,2})\D(\d{4})\s*$/) {
    my ($year, $month, $day) = ( $3, $1, $2 );
    $date->ymd($year, $month, $day);
  } elsif ($value =~ /^\s*(?=1|2)(\d{4})\D?(\d{2})\D?(\d{2})\s*$/) {
    my ($year, $month, $day) = ($1, $2, $3);
    $date->ymd($year, $month, $day);
  } elsif ($value =~ /^\s*(\d{4})[\D\W]?(\w{3})[\D\W]?(\d{1,2})\s*$/){
    my ($year, $day) = ($1, $3);
    my $month = $short_months{lc($2)} if $short_months{lc($2)};
    $date->ymd($year, $month, $day);
  } elsif ($value =~ /^\s*(\w{3})[\D\W]?(\d{4})[\D\W]?(\d{1,2})\s*$/) {
    my ($year, $day) = ($2, $3);
    my $month = $short_months{lc($1)} if $short_months{lc($1)};
    $date->ymd($year, $month, $day);
  } elsif ($value =~ /^\s*(\d{1,2})[\D\W]?(\w{4}\w*)[\D\W]?(\d{2})\s*$/) {
    my ($year, $day) = ($3, $1);
    my $month = $months{lc($2)} if $months{lc($2)};
    $year += 1900;
    $year += 100 if ( $year < 1950 );
    $date->ymd($year, $month, $day);
  } elsif ($value =~ /^\s*(\d{9,10})\s*$/i) {
    $date->udt($value);
  } elsif ($value =~ /today/i) {
    $date->set_current;
  } else {
    my $udt = Time::ParseDate::parsedate($value, 'DATE_REQUIRED' => 1);
    if ($udt) {   
      $date->udt($udt);
    } else {
      $date->isbogus(1);
    }
  }
  $date->bogus_date( $value ) if $date->isbogus();
  return;
}

sub bogus_date {
  my $date = shift;
  $date->{'bogus_date'} = shift if (scalar @_ ) ;
  return $date->{'bogus_date'};
}

sub isbogus {
  my $date = shift;
  $date->{'isbogus'} = shift if (scalar @_);
  return $date->{'isbogus'};
}

### Value Access

# $year = $date->year; or pass ($year) to set it
sub year {
  my $date = shift;
  if (scalar @_) {
    my $value = shift;
    if ( $value < 1000 or $value > 3000) {
      warn "invalid year $value";
      $value = 1900;
    }
    $date->{'year'} = $value;
    $date->make_day_valid;
  }
  return $date->{'year'} - 0;
}

# $month = $date->month; or pass ($month) to set it
sub month {
  my $date = shift;
  if (scalar @_) {
    my $value = shift;
    if ( $value < 1 ) {
      $date->year( $date->year - 1 );
      $date->month( 12 + $value );
      $date->{'wrapped'} = 1;
    } elsif( $value > 12) {
      $date->year( $date->year + 1 );
      $date->month( $value - 12 );
      $date->{'wrapped'} = 1;
    } else{
      $date->{'month'} = $value;
      $date->make_day_valid;
    }
  }
  return $date->{'month'} - 0;
}

# $day = $date->day; or pass ($day) to set it
sub day {
  my $date = shift;
  if (scalar @_) {
    my $value = shift;
    if ( $value < 1 ) {
      $date->month( $date->month - 1 );
      $date->day( $date->num_days_in_month + $value );
      $date->{'wrapped'} = 1;
    } elsif ($value > $date->num_days_in_month) {
      $value = $value - $date->num_days_in_month ;
      $date->month( $date->month + 1 );
      $date->day( $value );
      $date->{'wrapped'} = 1;
    } else{
      $date->{'day'} = $value;
    }
  }
  return $date->{'day'} - 0;
}

# ($year, $month, $day) = $date->ymd; or pass ($year, $month, $day) to set 'em
sub ymd {
  my $date = shift;
  if (scalar @_) {
    $date->year ( shift );
    $date->month ( shift );
    $date->day ( shift );
  } 
  return ( $date->year, $date->month, $date->day );
}

# $udt = $date->udt; or pass ($udt) to set it, oh, and udt means Unix DateTime
sub udt {
  my $date = shift;
  if (scalar @_) {
    my $udt = shift;
    my ($x, $y, $z, $day, $month, $year) = localtime($udt);
    $month ++;
    $year += 1900;
    $date->ymd($year, $month, $day);
  }
  my ($year, $month, $day) = $date->ymd;
  $month --;
  $year -= 1900;
  return timelocal(0, 0, 0, $day, $month, $year);
}

### Calendar Features

# $daysinmonth = $date->num_days_in_month;
sub num_days_in_month {
  my $date = shift;
  
  my ($year, $month, $day) = $date->ymd;
  return days_in_month($year, $month);
}

sub days_in_month {
  my ($year, $month) = @_;
  if ($month == 2) {
    # Maybe this matches the english better?
    # unless (($year % 4 != 0) || ($year % 100 == 0 && $year % 400 != 0)) {
    # if (($year % 4 == 0) && ! ($year % 100 == 0 && $year % 400 != 0)) {
    if (($year % 4 == 0) && ($year % 400 == 0 || $year % 100 != 0)) {
      return 29;
    } else {
      return 28;
    }
  } else {
    my @maxdays = (0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    return $maxdays[$month];
  }
}

# $date->make_day_valid;
sub make_day_valid {
  my $date = shift;
  $date->day( $date->num_days_in_month ) if $date->day_out_of_bounds;
}

# $flag = $date->check_day_bounds;
sub day_out_of_bounds {
  my $date = shift;
  return ($date->day > $date->num_days_in_month) ? 1 : 0;
}

# $dow_from_one_to_seven = $date->dayofweek; #!# or pass ($flag), opt -1/0/+1
sub dayofweek {
  my $date = shift;
  return (localtime($date->udt))[6] || 7;
}

# $weekofyear = $date->weekofyear; #!# or pass ($weekofyear) to set
sub weekofyear {
  my $date = shift;
  # !
}

# $holidayname_or_zero = $date->isholiday;  #!# Need to build a holiday table
sub isholiday {
  my $date = shift;
  return 0;
}

# $flag = $date->isweekend;  #!# or pass ($flag), add -1/0/+1 for direction
sub isweekend {
  my $date = shift;
  return ( $date->dow == 6 or $date->dow == 7 ) ? 1 : 0;
}

# $flag = $date->isbusinessday; #!# or pass ($flag), add -1/0/+1 for direction
sub isbusinessday {
  my $date = shift;
  return ! ( $date->isweekend or $date->isholiday );
}

# ($nth, $dayofweek) = $date->nthweekday; or pass ($nth, $dayofweek) to set
sub nthweekday {
  my $date = shift;
  
  if (scalar @_) {
    my ($nth, $dayofweek) = @_;
    $date->day( 1 + (7 * $nth) );
    $date->dayofweek( $dayofweek, 1 );
  }
  
  my $nth = ( $date->day / 7 ) + 1;
  my $dayofweek = $date->dayofweek;
  return ($nth, $dayofweek);
}

# $flag = $date->firstdayofmonth; or pass ($flag) to set it
sub firstdayofmonth {
  my $date = shift;
  if (scalar @_) {
    if (shift) {
      $date->day(1);
    } else {
      $date->day(2) if ( $date->day == 1 );
    }
  }
  return ( $date->day == 1 ) ? 1 : 0;
}

# $flag = $date->lastdayofmonth; or pass ($flag) to set it
sub lastdayofmonth {
  my $date = shift;
  my $daysinmonth = $date->num_days_in_month;
  if (scalar @_) {
    if (shift) {
      $date->day( $daysinmonth );
    } else {
      $date->day($daysinmonth - 1) if ( $date->day == $daysinmonth );
    }
  }
  return ( $date->day == $daysinmonth ) ? 1 : 0;
}

### Offsets

# $prev_date = $date->prev_day;
sub prev_day {
  my $date = shift;
  my $clone = $date->clone;
  $clone->day( $date->day - 1 );
  return $clone;
}

# $next_date = $date->next_day;
sub next_day {
  my $date = shift;
  my $clone = $date->clone;
  $clone->day( $date->day + 1 );
  return $clone;
}

# $newday = $date->first_day_in_month;
sub first_day_in_month {
  my $date = shift;
  my $clone = $date->clone;
  $clone->day( 1 );
  return $clone;
}

# $newday = $date->last_day_in_month;
sub last_day_in_month {
  my $date = shift;
  my $clone = $date->clone;
  $clone->day( $date->num_days_in_month );
  return $clone;
}

### Display Output

# $month = $date->month_name;
sub month_name {
  my $date = shift;
  return ( $date->months )[ $date->month ];
}

# @names_of_months = months();
sub months {
  return ( undef, qw[ January February March April May June 
		      July August September October November December ] );
}

# $short_name_for_month = $date->mon;
sub mon {
  my $date = shift;
  return ( $date->mons )[ $date->month ];
}

# @short_names_of_months = mons();
sub mons {
  return ( undef, qw[ Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ] );
}

# $dayofweek = $date->nameofweekday;
sub nameofweekday {
  my $date = shift;
  return ( $date->daysofweek )[ $date->dayofweek ];
}

# @daysofweek = daysofweek();
sub daysofweek {
  return (undef, qw[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]);
}

# $zero_padded_string = $date->zero_padded( $value, $field_size || 2 );
sub zero_padded {
  my ($date, $value, $field_size) = @_;
  $value += 0;
  $field_size ||= 2;
  return '0' x ($field_size - length( $value ) ) . $value;
}

# $four_digit_year = $date->yyyy;
sub yyyy {
  my $date = shift;
  return $date->zero_padded( $date->year, 4 );
}

# $two_digit_month = $date->mm;
sub mm {
  my $date = shift;
  return $date->zero_padded( $date->month );
}

# $two_digit_day = $date->dd;
sub dd {
  my $date = shift;
  return $date->zero_padded( $date->day );
}

# $yyyymmdd = $date->yyyymmdd;
sub yyyymmdd {
  my $date = shift;
  return $date->yyyy . $date->mm . $date->dd ;
}

# $m/d/year = $date->full;
sub full {
  my $date = shift;
  return $date->month . '/' . $date->day . '/' . $date->year;
}

# $m/$d/yy = $date->short;
sub short {
  my $date = shift;
  my ($year, $month, $day) = $date->ymd;
  $year = substr($year,2,4) if ($year > 1950 and $year < 2050);
  return "$month/$day/$year";
}

# $monthdaycommayear = $date->long;
sub long {
  my $date = shift;
  return $date->month_name . ' ' . $date->day . ', ' . $date->year;
}

# $dowcommamonthdaycommayear = $date->complete;
sub complete {
  my $date = shift;
  
  return $date->nameofweekday . ', ' . 
		    $date->month_name . ' ' . $date->day . ', ' . $date->year;
}


### Spinoffs

# $duration = $date->duration_to_date($other_date);
sub duration_to_date {
  my ($date, $other_date) = @_;
  
  my $days = $other_date->julian_day -  $date->julian_day;
  
  return DateTime::Duration->new_from_days($days);
}

# $julianday = $date->julianday; or pass ($julianday) to set 
  # A julian day is represented as a number of actual historical days since
  # some very long ago day. Therefore, you can add a number of days and get
  # back the correct day, compensating for leap years, Gregorianism, etc.
sub julianday {
  my $date = shift;
  $date->ymd( inverse_julian_day( shift ) ) if (scalar @_);
  return julian_day( $date->ymd );
}

1;

};
DateTime::Date->import();
}
BEGIN { 
$INC{'DateTime::Time'} = 'lib/DateTime/Time.pm';
eval {
### TIME - a time of day

### Create / Init
  # $time = DateTime::time->new();
  # $equivalent_time = $time->clone;
  # $time = current_time();
  # $time->set_current();
  # $time = new_time_from_value( $value );
  # $time->set_from_scalar( $value ); where value is just about anything timish

### Value Access
  # $hour = $time->hour; or pass ($hour) to set it
  # $minute = $time->minute; or pass ($minute) to set it
  # $second = $time->second; or pass ($second) to set it
  # ($hour, $minute, $second) = $time->hms; or pass ($hour, $minute, $second)
  # ($twelvehour, $ampm) = $time->twelvehour; or pass ($twelvehour, $ampm)
  # ($hour, $minute, $second, $ampm) = $time->hms_ampm; or pass the same to set
  # $udt = $time->udt; or pass ($udt) to set it

### Display
  # $zero_padded_string = $time->zero_padded( $value, $field_size || 2 );
  # $two_digit_hours = $time->hh;
  # $two_digit_minutes = $time->mm;
  # $two_digit_seconds = $time->ss;
  # $hh:mm:ss = $time->full;
  # $hh:mm(:ss) = $time->military;
  # $h:mm(:ss)a/p = $time->ampm;
  # $h(:mm:ss)a/p = $time->short;

### Spinoffs
  # $duration = $time->duration_to_time($other_time);

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon	   M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 1998-05-20 set_from_scalar now rejects minutes higher than 59. -Dan
  # 1998-05-05 set_from_scalar modified to accept single or double digit
  #            entries. -Dan
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-11 Cleanup.
  # 1997-06-10 Created module. -Simon

package DateTime::Time;

use integer;
BEGIN { 
Time::ParseDate->import();
}
use Time::Local;

use Exporter;
push @ISA, qw( Exporter );
@EXPORT = qw[ current_time new_time_from_value ];

### Create / Init

# $time = DateTime::Time->new();
sub new {
  my ($package) = @_;
  my $time = { 'hour' => 0, 'minute' => 0, 'second' => 0 };
  bless $time, $package;
}

# $equivalent_time = $time->clone;
sub clone {
  my $time = shift;
  my $package = ref $time;
  my $clone = $package->new;
  $clone->hms( $time->hms );
}

# $time = current_time();
sub current_time {
  my $time = DateTime::Time->new;
  $time->set_current;
  return $time;
}

# $time->set_current();
sub set_current {
  my $time = shift;
  $time->udt( time() );
}

# $time = new_time_from_value( $value );
  # $value can be just about any time format
sub new_time_from_value {
  my ($value) = @_;
  my $time = DateTime::Time->new;
  $time->set_from_scalar($value);
  return $time;
}

# $time->set_from_scalar( $value ); where $value is just about anything timish
sub set_from_scalar {
  my ($time, $value) = @_;
  
  if ( ! $value) {
    $time->isbogus(1);
  } elsif ( ref $value eq 'HASH' ) {
    $time->hms( $value->{'hour'}, $value->{'minute'}, $value->{'second'} );
  } elsif ($value =~ /\A\s*(\d{2})\D(\d{2})\D(\d{2})\s*\Z/i) {
    $time->hms($1, $2, $3);
  } elsif ($value =~ /\A\s*(\d{1,2})\D(\d{1,2})(?:\D(\d{1,2}))?(?:\s*(am?|pm?))\s*\Z/i) {
    $time->hms_ampm($1, $2, $3, $4);
  } elsif ($value =~ /^\s*(\d{2})(\d{2})(\d{2})?(?:\s*(am?|pm?))?\s*$/i) {
    $time->hms_ampm($1, $2, $3, $4);
  } elsif ($value =~ /^\s*(\d{9,10})\s*$/i) {
    $time->udt($value);
  } elsif ($value =~ /^\s*(\d{1,2})\s*(am?|pm?)?\s*$/i) {
    my ($h, $ampm) = ($1, $2);
    $time->hms_ampm($h,0,0,$ampm);
  } else {
    my $udt = Time::ParseDate::parsedate($value, 'TIME_REQUIRED' => 1);
    # warn "UDT is $udt \n";
    if ($udt) {   
      $time->udt($udt);
    } else {
      $time->isbogus(1);
    }
  }
  if ( $time->{'wrapped'} ) {
    $time->isbogus(1);
    warn 'WRAPPED.  TIME IS BOGUS';
  }
  $time->bogus_time( $value ) if $time->isbogus();
  return;
}

sub bogus_time {
  my $time = shift;
  $time->{'bogus_time'} = shift if (scalar @_ );
  return $time->{'bogus_time'};
}

sub isbogus {
  my $time = shift;
  $time->{'isbogus'} = shift if (scalar @_);
  return $time->{'isbogus'};
}

### Value Access

# $hour = $time->hour; or pass ($hour) to set it
sub hour {
  my $time = shift;
  if (scalar @_) {
    my $value = shift;
    if ( $value < 0 or $value > 23) {
      warn "invalid hour $value";
      $value = 0;
    }
    $time->{'hour'} = $value;
  }
  return $time->{'hour'};
}

# $minute = $time->minute; or pass ($minute) to set it
sub minute {
  my $time = shift;
  if (scalar @_) {
    my $value = shift;
    if ( $value < 0 ) {
      $time->hour( $time->hour - 1 );
      $time->minute( 60 + $value );
      $time->{'wrapped'} = 1;
    } elsif( $value > 59) {
      $time->hour( $time->hour + 1 );
      $time->minute( $value - 60 );
      $time->{'wrapped'} = 1;
      warn 'time was wrapped';
    } else{
      $time->{'minute'} = $value;
    }
  }
  return $time->{'minute'} - 0;
}

# $second = $time->second; or pass ($second) to set it
sub second {
  my $time = shift;
  if (scalar @_) {
    my $value = shift;
    if ( $value < 0 ) {
      $time->minute( $time->minute - 1 );
      $time->second( 60 + $value );
      $time->{'wrapped'} = 1;
    } elsif( $value > 59) {
      $time->minute( $time->minute + 1 );
      $time->second( $value - 60 );
      $time->{'wrapped'} = 1;
    } else{
      $time->{'second'} = $value;
    }
  }
  return $time->{'second'} - 0;
}

# ($hour, $minute, $second) = $time->hms; or pass ($hour, $minute, $second)
sub hms {
  my $time = shift;
  if (scalar @_) {    
    $time->hour ( shift );
    $time->minute ( shift );
    $time->second ( shift );
  }
  return ( $time->hour, $time->minute, $time->second );
}

# ($twelvehour, $ampm) = $time->twelvehour; or pass ($twelvehour, $ampm) to set
sub twelvehour {
  my $time = shift;
  
  if (scalar @_) {
    my ($hour, $ampm) = @_;
    $hour += 12 if ($ampm =~ /p/i && $hour <= 11);
    $hour -= 12 if ($ampm =~ /a/i && $hour > 11);
    $time->hour($hour) 
  }
  
  my $hour = $time->hour;
  my $ampm;
  if ($hour < 12) {
    $hour = (($hour - 0) or '12');
    $ampm = 'am';
  } else {
    $hour = (($hour - 12) or '12') ;
    $ampm = 'pm';
  }
  return ($hour, $ampm)
}

# ($hour, $minute, $second, $ampm) = $time->hms_ampm; or pass ($h, $m, $s, $ap)
sub hms_ampm {
  my $time = shift;
  if (scalar @_) {
    my ($hour, $minute, $second, $ampm) = @_;
    # warn "setting time to $hour, $minute, $second, $ampm \n";
    if ( ! $ampm ) {
      if (( $hour != 0 and $hour < 8 ) or ( $hour == 12 )) {
        $ampm = 'pm';
        warn 'Ambiguous time entry assumed to be PM';
      } elsif ( $hour >= 8 and $hour < 12 ) {
        $ampm = 'am';
        warn 'Ambiguous time entry assumed to be AM';
      } elsif ( $hour == 0 ) {
        $hour = 12;
        $ampm = 'am';
        warn 'Military time entry assigned meridian AM';
      } elsif ( $hour > 12 and $hour <= 24 ) {
        $hour = ( $hour - 12 );
        $ampm = 'pm';
        warn 'Military time entry assigned meridian PM';
      } else {
        $time->isbogus(1);
      }
    }
    $time->twelvehour($hour, $ampm);
    $time->minute($minute);
    $time->second($second);
  }
  my ($hour, $ampm) = $time->twelvehour;
  return ($hour, $time->minute, $time->second, $ampm)
  
}

# $udt = $time->udt; or pass ($udt) to set it
sub udt {
  my $time = shift;
  
  if (scalar @_) {
    my ($second, $minute, $hour, $undef, $undef, $undef) = localtime( shift );
    $time->hms($hour, $minute, $second);
  }
  
  my ($hour, $minute, $second) = $time->hms;
  return timelocal($second, $minute, $hour, 1, 0, 0);
}

### Display

# $zero_padded_string = $time->zero_padded( $value, $field_size || 2 );
sub zero_padded {
  my ($time, $value, $field_size) = @_;
  $value += 0;
  return '0' x ( $field_size || 2 - length( $value ) ) . $value;
}

# $two_digit_hours = $time->hh;
sub hh {
  my $time = shift;
  return $time->zero_padded( $time->hour );
}

# $two_digit_minutes = $time->mm;
sub mm {
  my $time = shift;
  return $time->zero_padded( $time->minute );
}

# $two_digit_seconds = $time->ss;
sub ss {
  my $time = shift;
  return $time->zero_padded( $time->second );
}

# $hh:mm:ss = $time->full;
sub full {
  my $time = shift;
  return $time->hh . ':' . $time->mm . ':' . $time->ss;
}

# $hh:mm(:ss) = $time->military;
sub military {
  my $time = shift;
  my($result) =  $time->hour .':'. $time->minute;
  $result .= ':'. $time->second if ($time->second > 0);
  return $result;
}

# $h:mm(:ss)a/p = $time->ampm;
sub ampm {
  my $time = shift;
  my ($hour, $minute, $second , $ampm) = $time->hms_ampm;
  my($result) =  $hour .':'. $time->mm;
  $result .= ':'. $time->ss if ($time->ss > 0);
  $result .= $ampm;
  return $result;
}

# $h(:mm:ss)a/p = $time->short;
sub short {
  my $time = shift;
  my ($hour, $minute, $second , $ampm) = $time->hms_ampm;
  my($result) =  $hour ;
  $result .= ':'. $minute if ($minute > 0 or $second > 0);
  $result .= ':'. $second if ($second > 0);
  $result .= $ampm;
  return $result;
}

### Spinoffs

# $duration = $time->duration_to_time($other_time);
sub duration_to_time {
  my ($time, $other_time) = @_;
  
  my ($seconds);
  $seconds = 3600 * ( $timea->hour - $timeb->hour);
  $seconds += 60 * ( $timea->minute - $timeb->minute);
  $seconds += ( $timea->second - $timeb->second);
  
  return DateTime::Duration->new_from_seconds($seconds);
}

1;

};
DateTime::Time->import();
}

# use datetime::duration;
# use datetime::moment;
# use datetime::period;

### Dates

sub asdate {
  my ($value, $style) = @_;
  
  my $date = DateTime::Date::new_date_from_value( $value );
  
  if ($date->isbogus) {
    warn "invalid date " . printablestring($value);
    return; 
  }
  
  # return $date if (not $style or $style =~ /hash/i);
  $style ||= 'short';
  
  return $date->short if ($style =~ /short/i);
  return $date->full if ($style =~ /full/i);
  return $date->yyyymmdd if ($style =~ /ymd/i);
  return $date->long if ($style =~ /long/i);
  return $date->complete if ($style =~ /complete/i);
  return $date->udt if ($style =~ /timestamp/i);
  
  warn "Date error: unknown date style " . &printablestring($style) . 
  return $date->full;
}

### Times

sub astime {
  my ($value, $style) = @_;
  
  my $time = DateTime::Time::new_time_from_value( $value );
  if ($time->isbogus) {
    warn "invalid time " . printablestring($value) . "\n";
    return; 
  }
  
  return $time if (not $style or $style =~ /hash/i);
  
  return $time->full if ($style =~ /full/i);
  return $time->military if ($style =~ /24hr/i);
  return $time->ampm if ($style =~ /ampm/i);
  return $time->short if ($style =~ /short/i);
  return $time->udt if ($style =~ /timestamp/i);
  
  warn "astime called with unknown time style " . printablestring($style);
  return $time->full;
}

1;
};
DateTime::Formats->import();
}
BEGIN { 
$INC{'Number::Formats'} = 'lib/Number/Formats.pm';
eval {
### Number::Formats provide a Text::Format interface for the Number::* routines

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-24 Added Currency support and initial visible formats -Del
  # 1997-11-24 Added comma separated format. 
  # 1997-11-17 Created to work with new Text::Format package -Simon

package Number::Formats;

use vars qw( $VERSION );
$VERSION = 1.00_1998_03_11;

BEGIN { 
$INC{'Number::Bytes'} = 'lib/Number/Bytes.pm';
eval {
### Number::Bytes provides formatting for byte and bit counts.

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-23 Fixed typo.
  # 1997-11-17 Split this into several packages, added bit_format. -Simon
  # 1997-06-23 Created original numbers package -JGB

package Number::Bytes;

use vars qw( $VERSION );
$VERSION = 1.00_1998_03_23;

# Export on demand: byte_format bit_format
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( byte_format bit_format );

# @byte_scales, @bit_scales - text labels for powers of two-to-the-tenth
use vars qw( @byte_scales @bit_scales );
@byte_scales = qw( Bytes KB MB GB TB );
@bit_scales = qw( bits Kb Mb Gb Tb );

# $value = byte_format($number)
  # Show no more than one decimal place, followed by scale label
sub byte_format {
  my $value = shift;
  my $options = shift;
  
  my $scale;
  foreach $scale (@byte_scales) {
    return ( (int($value * 10 + 0.5)/10) . $scale ) if ($value < 1024); 
    $value = $value / 1024;
  }
  warn "huge value";
}

# $value = bit_format($number)
  # Show no more than one decimal place, followed by scale label
sub bit_format {
  my $value = shift;
  my $options = shift;
  
  return byte_format($value / 8) if ( $options =~ /bytes/i );
  
  my $scale;
  foreach $scale (@bit_scales) {
    return ( (int($value * 10 + 0.5)/10) . $scale ) if ($value < 1024); 
    $value = $value / 1024;
  }
  warn "huge value";
}

1;


};
Number::Bytes->import();
}
Text::Format::add( 'bytes',   \&Number::Bytes::byte_format );
Text::Format::add( 'bits',    \&Number::Bytes::bit_format );

BEGIN { 
$INC{'Number::Roman'} = 'lib/Number/Roman.pm';
eval {
### Number::Roman provides functions to convert to and from roman numerals.

### Interface
  # Export on demand: roman unroman isroman
  # %ones, %fives - Roman characters for 1 and 5 of each scale, 1 .. 1000
  # $formatted = roman( $number );
  # $n = unroman( $roman );
  # $flag = isroman( $value );

### Usage Examples
  # roman( 42 ) eq 'XLII'
  # roman( 42, 'lc' ) eq 'xlii'
  # unroman( 'xlii' ) == 42 

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License
  # Derived from code developed by OZAWA Sakuro and released to CPAN.

### Change History
  # 1997-11-17 Split this into several packages. -Simon
  # 1997-06-23 Created original numbers package -JGB

package Number::Roman;

use vars qw( $VERSION );
$VERSION = 1.00_1998_03_11;

# Export on demand: roman unroman isroman
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( roman unroman isroman );

# %ones, %fives - Roman characters for 1 and 5 of each scale, 1 .. 1000
use vars qw( @scales %ones %fives %unroman );

@scales = ( 1, 10, 100, 1000 );
@ones{ @scales } = ( 'I', 'X', 'C', 'M' );
@fives{ @scales } = ( 'V', 'L', 'D', 'MMMMM' );
%unroman = map { $ones{$_} => $_, $fives{$_} => $_*5 } @scales;

# $formatted = roman( $number );
# $lowercase = roman( $number, 'lc' );
sub roman {
  my $value = shift;
  my $opt = shift;
  warn "in roman $value $opt \n";
  return undef unless ( 0 < $value and $value < 4000 );
  my $roman; 	# value to return
  my $x;	# digit cary
  my $scale;
  foreach $scale (reverse @scales) {
    my $digit = int($value / $scale);
    if (1 <= $digit and $digit <= 3) {
      $roman .= $ones{ $scale } x $digit;
    } elsif ($digit == 4) {
      $roman .= $ones{ $scale } . $fives{ $scale };
    } elsif ($digit == 5) {
      $roman .= $fives{ $scale };
    } elsif (6 <= $digit and $digit <= 8) {
      $roman .= $fives{ $scale } . $ones{ $scale } x ($digit - 5);
    } elsif ($digit == 9) {
      $roman .= $ones{ $scale } . $x;
    }
    $value -= $digit * $scale;
    $x = $ones{ $scale };
  }
  return (defined $opt and $opt =~ /lc/i) ? lc( $roman ) : $roman ;
}

# $n = unroman( $roman );
sub unroman {
  my $value = lc( shift );
  return undef unless ( isroman($value) );
  my $last_digit = $scales[-1];
  my($number, $letter);
  foreach $letter (split(//, uc $value)) {
    my($digit) = $unroman{$letter};
    $number -= 2 * $last_digit if $last_digit < $digit;
    $number += ($last_digit = $digit);
  }
  return $number;
}

# $flag = isroman( $value );
sub isroman {
  my $value = shift;
  $value ne '' and $value =~ /\A(?: M{0,3})
				(?: D?C{0,3} | C[DM])
				(?: L?X{0,3} | X[LC])
				(?: V?I{0,3} | I[VX])\Z/ix;
}

1;


};
Number::Roman->import();
}
Text::Format::add( 'roman',   \&Number::Roman::roman );
Text::Format::add( 'unroman', \&Number::Roman::unroman );

BEGIN { 
$INC{'Number::Words'} = 'lib/Number/Words.pm';
eval {
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


};
Number::Words->import();
}
Text::Format::add( 'words',   \&Number::Words::aswords );
Text::Format::add( 'nth',     \&Number::Words::nth );

BEGIN { 
$INC{'Number::Separated'} = 'lib/Number/Separated.pm';
eval {
### Number::Separated - Comma separated integers.

### Interface
  # Export on demand: separated
  # $commasep - comma separator
  # $value = separated($value)

### Usage Examples
  # separated('45326') eq '45,326'

### Copyright 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1997-11-24 Extracted from base Number package and exported back.

package Number::Separated;

use vars qw( $VERSION );
$VERSION = 1.00_1998_03_11;

# Export on demand: separated
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( separated );

# $commasep - comma separator
use vars qw( $commasep );
$commasep = ',';

# $value = separated($value)
  # Comma-separated integers - doesn't handle floats yet.
sub separated {
  my $nval = shift;
  return reverse join($commasep, reverse($nval) =~ m/(\d{1,3})/g);
}

1;


};
Number::Separated->import();
}
Text::Format::add( 'separated',   \&Number::Separated::separated );

BEGIN { 
$INC{'Number::WorkTime'} = 'lib/Number/WorkTime.pm';
eval {
### Number::WorkTime - Minutes as hours and workdays.

### Interface
  # Export on demand: ashours
  # $minutesperday - minutes per work day
  # $value = ashours($value)

### Usage Examples
  # ashours('120') eq '2hrs'
  # ashours('420') eq '1wkday'

### Copyright 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1997-12-03 Duplicated from Number::Separated package.

package Number::WorkTime;

use vars qw( $VERSION );
$VERSION = 1.00_1998_03_11;

# Export on demand: ashours
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( ashours );

# $minutesperday - minutes in a standard work day
use vars qw( $minutesperday );
$minutesperday = 420;

# $value = ashours($value)
  # Minutes -> workdays or hours.
sub ashours {
  my $m = shift;
  return '' unless $m;
  my @clauses;
  
  my $wd = int($m / $minutesperday);
  $m -= $minutesperday * $wd;
  push @clauses, $wd . ' wkday' . ( $wd == 1 ? '' : 's') if $wd;
  
  my $h = int($m / 60);
  $m -= 60 * $h;
  push @clauses, $h . ' hr' . ( $h == 1 ? '' : 's') if $h;
  
  push @clauses, $m . ' min' if $m;
  return join(', ', @clauses);
}

1;


};
Number::WorkTime->import();
}
Text::Format::add( 'ashours',   \&Number::WorkTime::ashours );

BEGIN { 
$INC{'Number::Currency'} = 'lib/Number/Currency.pm';
eval {
### Number::Currency provides currency-appropriate formatting for numbers

### Interface
  # @ones, @tens, @thousands - Words to be localized
  # use_dollars();
  # $formatted_currency = pretty_dollars( $value_with_decimal_point );
  # $formatted_currency = cents_to_dollars( $pennies );
  # $formatted_currency = display($dollars, $cents);
  # $pennies = dollars_to_cents( $value_with_decimal_point );
  # ($dollars, $cents) = split_dollar($value_with_decimal_point)
  # ($dollars, $cents) = split_pennies( $pennies );
  # $value_with_decimal_point = pennies( $pennies );

### Change History
  # 1998-04-18 Added POD. -Jeremy
  # 1998-03-24 Corrected typos; most functions are not methods. -Del
  # 1998-03-17 Corrected typo in method call. -Del
  # 1997-11-17 Preliminary revised version. -Simon

package Number::Currency;

# Export on demand: roman unroman isroman
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( pretty_dollars pennies dollars_to_cents );

BEGIN { 
Err::Debug->import();
}

# @ones, @tens, @thousands - Words to be localized
use vars qw( $places $symbol $separator );

use_dollars(); # US Dollars are the default (currently only) supported currency

# use_dollars();
sub use_dollars {
  $places = 2;
  $symbol = '$';
  $separator = '.';
}

# $formatted_currency = pretty_dollars( $value_with_decimal_point );
sub pretty_dollars {
  my $value = shift;
  $value =~ s/[^\d\.]//g;

  debug 'currency', 'pretty_dollars: $value =', $value;

  return display(split_dollar( $value ));
}

# $formatted_currency = cents_to_dollars( $pennies );
sub cents_to_dollars {
  my($value) = @_;
  $value = int($value);

  debug 'currency', 'cents_to_dollars: $value =', $value;
  
  return display(split_pennies( $value ));
}

# $formatted_currency = display($dollars, $cents);
sub display {
  my ($dollars, $cents) = @_;
  debug 'currency', 'display: $dollars =', $dollars, '$cents =', $cents;
  return ($symbol . Number::Separated::separated($dollars) . $separator . $cents);
}

# ($dollars, $cents) = split_dollar($value_with_decimal_point)
sub split_dollar {
  my $value = shift;
  my ($dollars, $cents) = split(/\./, $value, 2);
  $cents = substr($cents, 0, $places) . ('0' x ($places - length($cents)));
  $dollars ||= '0';

  debug 'currency', 'split_dollar: $value =', $value, '$dollars =', $dollars, '$cents =', $cents;

  return ($dollars, $cents);
}

# ($dollars, $cents) = split_pennies( $pennies );
sub split_pennies {
  my $value = shift;
  my($dollars, $cents) =
      (length("$value") > $places) ?
	  ( $value =~ /\A(?:(\d*)(\d{$places}))\Z/ ) : ( 0, $value );
  $cents = sprintf("%0${places}d", $cents) if (length($cents) < $places);
  ($dollars > 0) || ($dollars = '0');

  return ($dollars, $cents);
}

# $pennies = dollars_to_cents( $value_with_decimal_point );
sub dollars_to_cents {
  my $value = shift;
  $value =~ s/[^\d\.]//g;
  return join('', split_dollar($value) );
}

# $value_with_decimal_point = pennies( $pennies );
sub pennies {
  my($value) = @_;
  $value = int($value);
  return '0.00' unless ($value > 0);
  $value = ( ('0' x (3 - length($value))) . $value )
				      if(3 > length($value));
  $value =~ s/(..)$/.$1/;
  return $value;
}

1;


};
Number::Currency->import();
}
Text::Format::add( 'cents_to_dollars', \&Number::Currency::cents_to_dollars );
Text::Format::add( 'dollars_to_cents', \&Number::Currency::dollars_to_cents );

1;

};
Number::Formats->import();
}

BEGIN { 
Text::Escape->import(qw( escape ));
}
$Escapes{'uppercase'} = \&uppercase;
$Escapes{'lowercase'} = \&lowercase;
$Escapes{'initialcase'} = \&initialcase;
sub uppercase ($) { "\U$_[0]\E" }
sub lowercase ($) { "\L$_[0]\E" }
sub initialcase ($) { "\L\u$_[0]\E" }

# [print value=#x (plus=#n ifempty=alt format="fmt-name arg" escape=esc-name)]
Script::Tags::Print->register_subclass_name();
sub subclass_name { 'print' }

# $argdef_hash_ref = $tag->arg_defn();
sub arg_defn () { {
  'value' =>   {'dref' => 'optional', 'required'=>'anything'},
  'plus' =>    {'dref'=>'optional', 'required'=>'number'},
  'ifempty' => {'dref'=>'no', 'required'=>'string_or_nothing'},
  'case' =>    {'dref'=>'no', 'required'=>'oneof_or_nothing upper lower'},
  'format' =>  {'dref'=>'no', 'required'=>'string_or_nothing'},
  'escape' =>  {'dref'=>'no', 'required'=>'string_or_nothing'},
} }

# $text = $tag->interpret();
sub interpret {
  my $tag = shift;
  my $args = $tag->get_args;
  
  my $value = $args->{'value'};
  $value = '' unless ( defined $value );
  
  $value += $args->{'plus'} if ($args->{'plus'});
  $value = formatted($args->{'format'}, $value) if ( $args->{'format'} );
  $value = $args->{'ifempty'} if ($value !~/\S/ && defined $args->{'ifempty'});
  $value = escape($args->{'escape'}, $value) if ( $args->{'escape'} );
  
  return $value;
}

1;


};
Script::Tags::Print->import();
}
BEGIN { 
$INC{'Script::Tags::Set'} = 'lib/Script/Tags/Set.pm';
eval {
### Script::Set provides a basic assignment operation for EvoScript

### Interface
  # [set target=dref asdref escape=fromtext|html|url...] ... [/set]
  # $emptystring = $settag->interpret();

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-11 Inline POD added.
  # 1997-10-29 Updated to four-oh stylee.
  # 1997-03-11 Split from script.tags.pm -Simon
  # 1996-08-01 Initial creation of the set tag.

package Script::Tags::Set;

$VERSION = 4.00_1998_03_11;

BEGIN { 
Script::Container->import();
}
@ISA = qw( Script::Container );

BEGIN { 
Text::Words->import(qw( string2list));
}
BEGIN { 
Data::DRef->import();
}

# [set target=dref asdref escape=fromtext|html|url...] ... [/set]
Script::Tags::Set->register_subclass_name();
sub subclass_name { 'set' }

%ArgumentDefinitions = (
  'target' => {'dref' => 'target', 'required'=>'non_empty_string'},
  'asdref' => {'dref'=>'no', 'required'=>'flag'},
  'wordsof' => {'dref'=>'no', 'required'=>'flag'},
  'escape' => {'dref'=>'no', 'required'=> 'oneof_or_nothing ' .
					    join(' ', Text::Escape::names()) },
);

# $emptystring = $settag->interpret();
sub interpret {
  my $tag = shift;
  my $args = $tag->get_args;
  
  my $value = $tag->interpret_contents();
  $value = getData($value) if ($args->{'asdref'});
  $value = [ string2list($value) ] if ($args->{'wordsof'});
  $value = escape($args->{'escape'}, $value) if ( $args->{'escape'} );
  
  setData($args->{'target'}, $value);
  return '';
}

1;


};
Script::Tags::Set->import();
}
BEGIN { 
$INC{'Script::Tags::If'} = 'lib/Script/Tags/If.pm';
eval {
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

BEGIN { 
Script::Container->import();
}
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


};
Script::Tags::If->import();
}
BEGIN { 
$INC{'Script::Tags::ForEach'} = 'lib/Script/Tags/ForEach.pm';
eval {
### Script::Tags::ForEach defines EvoScript's basic iterator tag.

### Interface
  # [foreach target=#src (count|wordsof|leafnodes) sort|skip|join|periodicjoin]
  # $string = $foreachtag->interpret();
  # $foreach->pick_keys( $args );
  # $foreach->skip_keys($skipper);
  # $foreach->sort_keys($sorter);
  # $results = $loop->do_loop
  # $string = $loop->prefix();
  # $stringvalue = $sequence->interpret_contents();

### To Do
  # - Add support for next and last.
  # - Improve subclassability.

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-11 Inline POD added.
  # 1997-10-29 Refactored.
  # 1997-03-11 Split from script.tags.pm -Simon
  # 1996-08-01 Initial creation of the foreach tag.

package Script::Tags::ForEach;

$VERSION = 4.00_1998_03_11;

BEGIN { 
Script::Container->import();
}
@ISA = qw( Script::Container );

BEGIN { 
Data::DRef->import();
}
BEGIN { 
$INC{'Data::Collection'} = 'lib/Data/Collection.pm';
eval {
### Data::Collection provides nested datastructure functions based on DRef. 

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # This is free software; you can use it under the same terms as Perl itself.

### Change History
  # 1998-05-21 Added undef behavior in matching_keys and matching_values.
  # 1998-05-07 Replaced map with foreach in a few places.
  # 1998-04-17 Updated to use new Data::Sorting interface.
  # 1998-04-10 Added hash_by_array_key.
  # 1998-04-09 Fixed single-item problem with scalarkeysof algorithm. -Simon
  # 1998-03-12 Changed keysof to protect the dref separator.
  # 1998-02-24 Changed valuesof to return value of non-ref arguments.  -Piglet
  # 1998-01-30 Added array_by_hash_key($) and intersperse($@) -Simon
  # 1997-12-08 Removed package Data::Types, replaced with UNIVERSAL isa.
  # 1997-12-07 Exported uniqueindexby.  -Piglet
  # 1997-11-24 Finished orderedindexby.
  # 1997-11-13 Added orderedindexby, but it still needs a bit of work. -S.
  # 1997-09-05 Package split from the original dataops.pm into Data::*. -Simon
  # 1997-04-08 Added getbysubkeys, now called matching_values
  # 1997-01-21 Added scalarsof.
  # 1997-01-21 Failure for keysof, valuesof now returns () rather than undef.
  # 1997-01-11 Cloned and cleaned for IWAE.
  # 1996-11-18 Moved v2 code into production, additional cleanup. -Simon
  # 1996-11-13 Major overhaul. (Version 2.00)
  # 1997-04-18 Cleaned up documentation a smidge.
  # 1997-01-28 Possible fix to recurring "keysof operates on containers" error.
  # 1997-01-26 Catch bad argument types for sortby, indexby.
  # 1996-06-24 First version of dataops.pm created. -Simon

package Data::Collection;

$VERSION = 4.00_01;

# Dependencies
BEGIN { 
Data::DRef->import(qw( getData setData getDRef setDRef joindref shiftdref $Root $Separator ));
}
BEGIN { 
$INC{'Data::Sorting'} = 'lib/Data/Sorting.pm';
eval {
### Data::Sorting provides a function for sorting data structures.

### Caveats and Things Undone
  # - Reverse-order (or "descending") sorting -- fairly urgent, eh?
  # - Jeremy's sorting model:
  #   Split each the string into runs of alpha, numeric, and other characters, 
  #   then compare each item in order; bob2 comes before bob11


### Change History
  # 1998-04-21 Revision of sorting rules for non-alphanumeric items
  # 1998-04-18 Refactored to single-function interface.
  # 1997-11-23 Made sortbycalculation always use text_sort_value.
  # 1997-11-13 Refactored sortbycalculation, added new sort_inplace function.
  # 1997-11-04 Yanked these out of the old dataops.pm library into Data::*.
  # 1997-05-09 Added sortbycalculation.
  # 1997-01-11 Version 3 forked for use with IWAE.
  # 1996-11-13 Version 2.00 of dataops adds sorting wrapper. -Simon
  # 1996-06-24 First version of dataops.pm created. -Simon

package Data::Sorting;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( sort_in_place );

use Carp;
BEGIN { 
Data::DRef->import(qw( getDRef ));
}

use vars qw( $ComparisonStyle );
$ComparisonStyle = 'simpletext';
# $ComparisonStyle = 'locale';

# sort_in_place($array_ref, $dref, &$sorter_func, ...);
sub sort_in_place ($;@) {
  my $list = shift;
  unless ( UNIVERSAL::isa($list,'ARRAY') ) {
    carp "Sorting error: sort_inplace operates on lists only, not '$list'"; 
    return;
  }
  
  local @value_arrays;
  unless ( scalar @_ ) {
    push @value_arrays, [ map { defined $_ ? $_ : '' } @$list ];
  }
  foreach $sort_rule ( @_ ) {
    my @values;
    if ( defined $sort_rule and ! ref $sort_rule ) {
      my $item;
      foreach $item (@$list) {
	my $value = getDRef($item, $sort_rule);
	$value = '' unless (defined $value);
	# Should do something about references.
	push @values, $value;
      }
    } elsif ( ref $sort_rule eq 'CODE' ) {
      my $item;
      foreach $item (@$list) {
	my $value = &$sort_rule($item);
	$value = '' unless (defined $value);
	# Should do something about references.
	push @values, $value;
      }
    } else {
      croak "Unknown type of sorting rule: $sort_rule";
    }
    # warn "Sorting values for $sort_rule: " . join(', ', @values);
    push @value_arrays, \@values;
  }
  
  @$list = @{$list}[ sort _sip_comparison ( 0 .. $#$list ) ];
}

# $comparison = _sip_comparison (implicit $a, $b);
  # Compare two array indexes by looking at the results stored in each of the 
  # local value arrays computed above.
sub _sip_comparison {
  # warn "sorting $a and $b\n";
  my ($rc, $calculation);
  foreach $calculation ( @value_arrays ) {
    # warn "comparing $calculation->[$a] and $calculation->[$b]\n";
    
    # Compare non-alphanumeric elements strictly
    if ( $ComparisonStyle eq 'simpletext' ) {
      my $a_alpha = ( $calculation->[$a] =~ /\w/ );
      my $b_alpha = ( $calculation->[$b] =~ /\w/ );
      # If both items are non-alphanumeric
      return $rc if ( ! $a_alpha and ! $b_alpha and 
	$rc = $calculation->[$a] cmp $calculation->[$b]
      );
      return $rc if ( $rc = $a_alpha <=> $b_alpha );
    }
    
    # If both items are numeric, use numeric comparison
    my $a_numer = ( $calculation->[$a] =~ /\A\-?\d+(?:\.\d+)?\Z/ );
    my $b_numer = ( $calculation->[$b] =~ /\A\-?\d+(?:\.\d+)?\Z/ );
    return $rc if (
      $a_numer and $b_numer and 
      $rc = $calculation->[$a] <=> $calculation->[$b]
    );
    return $rc if ( 
      $rc = $b_numer <=> $a_numer
    );
    
    # Compare textual items
    if ( $ComparisonStyle eq 'simpletext' ) {
      $rc = mangle($calculation->[$a]) cmp mangle($calculation->[$b])
    # } elsif ( $ComparisonStyle eq 'locale' ) {
    #   use locale;
    #   use POSIX qw(strcoll);
    #   $rc = strcoll(lc($calculation->[$a]), lc($calculation->[$b]));
    } else {
      $rc = $calculation->[$a] cmp $calculation->[$b];
    };
    return $rc if ( $rc );
  }
  
  # If we haven't been able to distinguish between them, leave them in order.
  return $a <=> $b;
}

# $mangled_text = mangle( $original_text );
  # Lower-case, alphanumeric-only version of a string for textual comparisons
sub mangle { my $t = lc(shift); $t=~tr/0-9a-z/ /cs; $t=~s/\A\s+//; return $t; }

1;


};
Data::Sorting->import(qw( sort_in_place ));
}
BEGIN { 
Text::PropertyList->import();
}

# Exports and Overrides
use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( valuesof keysof scalarkeysof scalarkeysandvalues  
	           matching_values matching_keys array_by_hash_key
		   indexby uniqueindexby orderedindexby intersperse );


### Collection Basics: keysof and valuesof.
  # Move to DRef.pm !!

# @keys = keysof($collection)
  # Returns a list of keys (numeric or string) in a referenced hash or list
  
sub keysof {
  my $collection = shift;
  if ( UNIVERSAL::isa($collection,'HASH') ) {
    my @keys = keys %$collection;
    foreach ( @keys ) { s/(\Q$Separator\E)/\\$1/g; } 
    return @keys;
  } elsif ( UNIVERSAL::isa($collection,'ARRAY') ) {
    return (0 .. $#{$collection}) 
  } else {
    return ();
  }
}

# move keysof and valuesof into DRef.pm

# @values = valuesof($collection)
  # Returns a list of scalar values in a referenced hash or list
  
sub valuesof {
  my $collection = shift;
  return ($collection) if (! ref($collection));
  return (@$collection) if ( UNIVERSAL::isa($collection,'ARRAY') );
  return (values %$collection) if ( UNIVERSAL::isa($collection,'HASH') );
  return (); 
}

### DRefs to leaf nodes

# @drefs = scalarkeysof($collection);
  # Returns a list of drefs for non-ref leaves in a referenced structure
  
sub scalarkeysof ($) {
  my $collection = shift;
  my @keys = keysof( $collection );
  my $i;
  # warn "scalar keys are " . join(', ', @keys) . "\n";
  for ( $i = 0; $i <= $#keys; $i++) {
    my $key = $keys[$i];
    my $val = getDRef($collection, $key);
    next unless (ref $val);
    my @drefs = keysof( $val );
    if (scalar @drefs) {
      foreach ( @drefs ) { $_ = joindref($key, $_) };
      splice (@keys, $i, 1, @drefs);
      $i--;
    }
    # warn "                " . join(', ', @keys) . "\n";
  }
  # warn "                " . join(', ', @keys) . "\n";
  return @keys;
}

# %$flat_hash = scalarkeysandvalues( $collection )
  
sub scalarkeysandvalues ($) {
  my $collection = shift;
  my %hash;
  foreach ( scalarkeysof( $collection ) ) {
    $hash{ $_ } = getDRef($collection, $_);
  }
  # warn "scalar keys and values are " . join(', ', %hash) . "\n";
  return \%hash;
}

### Index by DRefs 

# $index = indexby($collection, @drefs)
  # needs to handle count keys > 3
sub indexby {
  my($collection, @drefs) = @_;
  
  my $item;
  my $index = {};
  if (scalar @drefs == 1) {
    foreach $item (valuesof ($collection)) {
      push (@{$index->{ getDRef($item,$drefs[0]) }}, $item );
    }
  } 
  elsif (scalar @drefs == 2) {
    foreach $item (valuesof ($collection)) {
      push (@{$index->{ getDRef($item,$drefs[0]) }->{ 
      	getDRef($item,$drefs[1]) }}, $item );
    }
  } 
  elsif (scalar @drefs == 3) {
    foreach $item (valuesof ($collection)) {
      push (@{$index->{ getDRef($item,$drefs[0]) }->{ 
      	getDRef($item,$drefs[1]) }->{ getDRef($item,$drefs[2]) }}, $item );
    }
  }
    
  return $index;
}

# $index = uniqueindexby($collection, @drefs)
  # needs to handle multiple keys
sub uniqueindexby {
  my($collection, @drefs) = @_;
  my $index = {};
  
  my $item;
  foreach $item (valuesof($collection)) {
    $index->{ getDRef($item, $drefs[0]) } = $item;
  }
  
  return $index;
}

# %@$groups = orderedindexby( @$items, $grouper, @sorters );
sub orderedindexby {
  my($collection, $grouper, @sorters) = @_;
  
  my $index = {};
  my $order = [];
  
  my $item;
  foreach $item (sort_in_place([ valuesof $collection ], @sorters )) {
    
    # Err::Debug::debug( 'Field::Compound::SectionSorter', 
    #   ['orderedindexby'],
    #   $item
    # );
    
    my $value = getDRef($item, $grouper);
    $value = '' unless (defined $value);
    push @$order, ( $index->{$value} = { 'value' => $value, 'items' => [] } )
					unless ( exists($index->{ $value }) );
    push @{ $index->{ $value }{'items'} }, $item;
  }
  return $order;
}

### Select by DRefs

# $item or @items = matching_values($collection, %kvp_criteria);
sub matching_values {
  my($collection, %kvp_criteria) = @_;
  my($item, $dref, @items);
  ITEM: foreach $item (valuesof $collection) {
    foreach $dref (keys %kvp_criteria) {
      next ITEM unless $kvp_criteria{$dref} eq 
      			( defined $dref ? getDRef($item, $dref) : $item )  
    }
    return $item unless (wantarray);
    push @items, $item;
  }
  return @items;
}

# $dref or @keys = matching_keys($collection, %kvp_criteria);
sub matching_keys {
  my($collection, %kvp_criteria) = @_;
  return unless ($collection and scalar %kvp_criteria);
  my ($majorkey, $dref, @keys);
  ITEM: foreach $majorkey (keysof $collection) {
    my $item = getDRef($collection,$majorkey);
    foreach $dref (keys %kvp_criteria) {
      next ITEM unless $kvp_criteria{$dref} eq 
	      ( defined $dref && length $dref ? getDRef($item, $dref) : $item )  
    }
    return $majorkey unless (wantarray);
    push @keys, $majorkey;
  }
  return @keys;
}

### Conversions

# @$items = array_by_hash_key( %$items );
sub array_by_hash_key ($) {
  my $hashref = shift;
  return $hashref if (UNIVERSAL::isa($hashref, 'ARRAY'));
  my $arrayref = [];
  my $key;
  foreach $key ( keys %$hashref ) {
    $arrayref->[ $key + 0 ] = $hashref->{ $key };
  }
  return $arrayref;
}

# %$items = hash_by_array_key( @$items );
sub hash_by_array_key ($) {
  my $arrayref = shift;
  return $arrayref if (UNIVERSAL::isa($arrayref, 'HASH'));
  my $hashref = {};
  my $key;
  foreach $key ( 0 .. $#$arrayref ) {
    $hashref->{ $key } = $arrayref->[ $key ];
  }
  return $hashref;
}

# %$items = hash_of_array_key( @$items );
sub hash_of_array_key ($) {
  my $arrayref = shift;
  return { map { $arrayref->[$_], $_ } (0 .. $#$arrayref) };
}

### Utilities

# @items_with_seps = intersperse( $spacer, @items );
sub intersperse ($@) {
  my $item = shift;
  my $count;
  map { $count++ ? ( $item, $_ ) : ( $_ ) } @_;
}

1;


};
Data::Collection->import();
}
BEGIN { 
Text::Words->import(qw( string2list ));
}

Script::Tags::ForEach->register_subclass_name();
sub subclass_name { 'foreach' }

# [foreach target=#src (count|wordsof|leafnodes) sort|skip|join|periodicjoin]
%ArgumentDefinitions = (
  'target' =>	{'dref' => 'optional', 'required'=>'anything'},
  
  'count' => 	{'dref' => 'no', 'required'=>'flag'},
  'wordsof' => 	{'dref'=>'no', 'required'=>'flag'},
  'leafnodes' => {'dref'=>'no', 'required'=>'flag'},
  
  'sort' => 	{'dref'=>'no', 'required'=>'string_or_nothing'},
  'skip' => 	{'dref'=>'no', 'required'=>'string_or_nothing'},
  
  'join' => 	{'dref'=>'no', 'required'=>'string_or_nothing'},
  'periodicjoin' => {'dref'=>'no', 'required'=>'string_or_nothing'},
);

# $string = $foreachtag->interpret();
sub interpret {
  my $tag = shift;
  my $args = $tag->get_args;
  
  $tag->pick_keys( $args );
  
  $tag->skip_keys( $args->{'skip'} ) if ( $args->{'skip'} );
  $tag->sort_keys( $args->{'sort'} ) if ( $args->{'sort'} );
  
  $tag->{'join'} = $args->{'join'};
  ($tag->{'pjoin_count'}, $args->{'pjoin_text'}) = 
	split(/\s+/, $args->{'periodicjoin'}, 2) if ($args->{'periodicjoin'});
  
  $tag->{'outer'} = $Root->{'loop'};
  local $Root->{'loop'} = $tag;
  
  my $results = $tag->do_loop;
  
  $tag->{'target'} = $tag->{'keys'} = '';
  
  return $results;
}

# $foreach->pick_keys( $args );
sub pick_keys {
  my $tag = shift;
  my $args = shift;
  
  my $target = $args->{'target'};
  
  if ( $args->{'count'} ) {
    $tag->{'target'} = [ 1 .. $args->{'target'} ];
  } elsif ( $args->{'wordsof'} ) {
    $tag->{'target'} = [ string2list($target) ];
  } else {
    $tag->{'target'} = $args->{'target'};
  }
  
  $tag->{'keys'} = [ $args->{'leafnodes'} ? scalarkeysof($tag->{'target'}) 
					  : keysof($tag->{'target'})     ];
}

# $foreach->skip_keys($skipper);
sub skip_keys {
  my $tag = shift;
  my $skipper = shift;
  
  @{$tag->{'keys'}} = map { $_ !~ /\A$skipper\Z/ } @{$tag->{'keys'}};  
}

# $foreach->sort_keys($sorter);
sub sort_keys {
  my $tag = shift;
  my $sorter = shift;
  
  return unless $sorter;
  
  if ($sorter eq 'key') {
    @{$tag->{'keys'}} = sort @{$tag->{'keys'}};
  } 
  elsif ($sorter) {
    @{$tag->{'keys'}} = sort {
	    getDRef($target, joindref($a, $sorter) ) 
	cmp getDRef($target, joindref($b, $sorter) ) 
    } @{$tag->{'keys'}};
  }
}

# $results = $loop->do_loop
sub do_loop {
  my $loop = shift;
  
  my $results = '';
  $loop->{'count'} = 0;
  
  my $key;
  foreach $key ( @{$loop->{'keys'}} ) {
    $loop->{'key'} = $key;
    $loop->{'value'} = getDRef($loop->{'target'}, $loop->{'key'});
    $results .= $loop->prefix();
    $results .= $loop->interpret_contents();
    $loop->{'count'} ++;
  }
  
  return $results;
}

# $string = $loop->prefix();
sub prefix {
  my $loop = shift;
  
  # no prefix before 0th element
  return '' unless ( $loop->{'count'} );
  
  return $loop->{'pjoin_text'} if ($loop->{'pjoin_count'} and 
				 ! $loop->{'count'} % $loop->{'pjoin_count'});
  
  return $loop->{'join'} if ($loop->{'join'});
  
  return '';
}

1;


};
Script::Tags::ForEach->import();
}
BEGIN { 
$INC{'Script::Tags::Perl'} = 'lib/Script/Tags/Perl.pm';
eval {
### Script::Tags::Perl allows execution of Perl embedded on a page

### Interface
  # [perl target=#target (silently)]
  # $string = $perltag->interpret();

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-28 Imported astext and fromtext from Text::PropertyList. -Simon
  # 1998-03-17 Patched perl tag for silently without target.   -Piglet
  # 1998-03-17 Added explicit import of setData.
  # 1998-03-11 Inline POD added.
  # 1997-10-30 Rebuilt TextContainer class, rewrote [perl] tag 
  # 1997-01-13 Initial creation of the perl tag. -Simon

package Script::Tags::Perl;

$VERSION = 4.00_1998_03_11;

BEGIN { 
Err::Debug->import();
}
BEGIN { 
Data::DRef->import(qw( getData setData ));
}
BEGIN { 
Text::Excerpt->import(qw( printablestring ));
}
BEGIN { 
Text::PropertyList->import(qw( astext fromtext ));
}

@ISA = qw( Script::TextContainer );

Script::Tags::Perl->register_subclass_name();
sub subclass_name { 'perl' }

%ArgumentDefinitions = (
  'target' => {'dref' => 'target', 'required'=>'string_or_nothing'},
  'silently' => {'dref'=>'no', 'required'=>'flag'},
  'aslist' => {'dref'=>'no', 'required'=>'flag'},
  'ashash' => {'dref'=>'no', 'required'=>'flag'},
);

# $string = $perltag->interpret();
sub interpret {
  my $tag = shift;
  my $args = $tag->get_args;
  
  my $contents = $tag->{'contents'};
  
  # Perhaps do this in a separate package, or even safe it.
  
  my $results = $args->{'aslist'} ? [ eval $contents ] : 
  		$args->{'ashash'} ? { eval $contents } :
				      eval $contents;
  
  warn "Error in Perl tag: " . printablestring($contents) . "\n  $@\n" if ($@);
  
  return (defined $results) ? $results : ''
		    if ( not $args->{'target'} and not $args->{'silently'} );
  
  setData($args->{'target'}, $results) if $args->{'target'};
  
  return '';
}

sub get_picky_about_your_arguments {
  my $tag = shift;
  my $args = $tag->get_args;
  warn 'ack!' if ( $args->{'ashash'} && $args->{'aslist'} or
	      ! $args->{'target'} && $args->{'ashash'} || $args->{'aslist'} ); 
}

1;


};
Script::Tags::Perl->import();
}

BEGIN { 
$INC{'Script::Tags::Redirect'} = 'lib/Script/Tags/Redirect.pm';
eval {
### Script::Tags::Redirect provides cgi-redirect and end-request functionality.

### Interface
  # [redirect] url... [/redirect]
  # $tag->interpret();		// dies !

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-11 Inline POD added.
  # 1998-03-11 Switched to redirect_and_end.
  # 1997-11-17 Brought up to four-oh.
  # 1997-01-17 Initial creation of the cgi-redirect tag.

package Script::Tags::Redirect;

$VERSION = 4.00_1998_03_11;

BEGIN { 
Script::Container->import();
}
@ISA = qw( Script::Container );

Script::Tags::Redirect->register_subclass_name();
sub subclass_name { 'redirect' }

# [redirect] url... [/redirect]
%ArgumentDefinitions = (
);

BEGIN { 
Data::DRef->import();
}

# $tag->interpret();		// dies !
sub interpret {
  my $tag = shift;
  my $args = $tag->get_args;
  
  my $url = $tag->interpret_contents();
  my $request = getData('request');
  
  if ($url =~ m[\A\w+\:]) { 
    # appears to be fully qualified already.
  } elsif ( $url =~ m[\A\/] ) {
    $url = getDRef($request, 'site.url') . $url;
  } else {
    $url = getDRef($request, 'site.url') . 
	   getDRef($request, 'links.script') . 
	   getDRef($request, 'links.dir') . $url;
  }
  
  $request->redirect_and_end($url);
}

1;


};
Script::Tags::Redirect->import();
}
BEGIN { 
$INC{'Script::Tags::Sort'} = 'lib/Script/Tags/Sort.pm';
eval {
### Script::Tags::Sort provides a tag interface to the sort_by_drefs function

### Interface
  # [sort list=#items keys="dref dref" ( target=#target ) ]
  # $emptystring = $tag->interpret();

### Comments
  # If you pass a target, it gets the sorted values; otherwise the original 
  # list is sorted in place

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-17 Updated to use new Data::Sorting interface.
  # 1998-03-11 Inline POD added.
  # 1998-03-11 Fixed use of old argument name -- thanks Tim! 
  # 1997-11-17 Brought up to four-oh. -Simon

package Script::Tags::Sort;

$VERSION = 4.00_1998_03_11;

BEGIN { 
Script::Tag->import();
}
@ISA = qw( Script::Tag );

Script::Tags::Sort->register_subclass_name();
sub subclass_name { 'sort' }

BEGIN { 
Data::Sorting->import(qw( sort_in_place ));
}

BEGIN { 
Data::DRef->import();
}

# [sort list=#items keys="dref dref" ( target=#target ) ]
%ArgumentDefinitions = (
  'list' => {'dref'=>'optional', 'required'=>'list'},
  'keys' => {'dref'=>'optional', 'required'=>'list'},
  'target' => {'dref'=>'target', 'required'=>'string_or_nothing'},
);

# $emptystring = $tag->interpret();
sub interpret {
  my $tag = shift;
  my $args = $tag->get_args;
  
  my $sortedlist = $args->{'list'};
  
  setData( $args->{'target'}, ($sortedlist = [@$sortedlist]) )
		if (defined $args->{'target'} and length $args->{'target'});
  
  sort_in_place( $sortedlist, @{ $args->{'key'} } );
  
  return '';
}

1;


};
Script::Tags::Sort->import();
}
BEGIN { 
$INC{'Script::Tags::Silently'} = 'lib/Script/Tags/Silently.pm';
eval {
### Script::Tags::Silently allows you to run script tags without seeing results

### Interface
  # [silently] ... [/silently]
  # $emptystring = $tag->interpret();

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-11 Inline POD added.
  # 1997-11-17 Brought up to four-oh.

package Script::Tags::Silently;

$VERSION = 4.00_1998_03_11;

BEGIN { 
Script::Container->import();
}
@ISA = qw( Script::Container );

Script::Tags::Silently->register_subclass_name();
sub subclass_name { 'silently' }

# [silently] ... [/silently]
%ArgumentDefinitions = (
);

# $emptystring = $tag->interpret();
sub interpret {
  my $tag = shift;
  my $args = $tag->get_args;
  
  $tag->interpret_contents();
  
  return '';
}

1;


};
Script::Tags::Silently->import();
}
BEGIN { 
$INC{'Script::Tags::Warn'} = 'lib/Script/Tags/Warn.pm';
eval {
### Script::Tags::Warn allows you to write messages to the server error log

### Interface
  # [warn] ... [/warn]
  # $emptystring = $tag->interpret();

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License.

### Change History
  # 1998-03-11 Inline POD added.
  # 1997-11-17 Brought up to four-oh.

package Script::Tags::Warn;

$VERSION = 4.00_1998_03_11;

BEGIN { 
Script::Container->import();
}
@ISA = qw( Script::Container );

Script::Tags::Warn->register_subclass_name();
sub subclass_name { 'warn' }

# [warn] ... [/warn]
%ArgumentDefinitions = ();

# $emptystring = $tag->interpret();
sub interpret {
  my $tag = shift;
  warn $tag->interpret_contents . "\n";
  return '';
}

1;


};
Script::Tags::Warn->import();
}

BEGIN { 
$INC{'Script::Tags::Grid'} = 'lib/Script/Tags/Grid.pm';
eval {
### Script::Tags::Grid iterates over a collection, building table cells

### Interface
  # [grid values=dref (direction=across|down border,width=n)] ... [/grid]
  # $html_table = $gridtag->interpret();

### Caveats and Things Left Undone
  # - Use Script::HTML::Tables
  # - Subclass Script::Tags::ForEach?

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-05-19 Support record-based sorting of grids. -Del
  # 1998-04-17 Updated to use new Data::Sorting interface.
  # 1998-03-11 Inline POD added.
  # 1997-11-24 Updated to four-oh. -Simon
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-07 Split grid and table -Jeremy
  # 1997-03-23 Added switch for grid order (across or down).
  # 1997-03-22 Turned grid into a container.
  # 1997-03-22 Improved exception handling.
  # 1997-03-19 Created grid  -Piglet

package Script::Tags::Grid;

$VERSION = 4.00_1998_03_11;

BEGIN { 
Script::Container->import();
}
@ISA = qw( Script::Container );

BEGIN { 
Data::DRef->import();
}
BEGIN { 
Data::Sorting->import(qw( sort_in_place ));
}
BEGIN { 
$INC{'Script::HTML::Styles'} = 'lib/Script/HTML/Styles.pm';
eval {
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

BEGIN { 
$INC{'Script::HTML::Tag'} = 'lib/Script/HTML/Tag.pm';
eval {
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

BEGIN { 
$INC{'Script::HTML::Escape'} = 'lib/Script/HTML/Escape.pm';
eval {
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

};
Script::HTML::Escape->import();
}
BEGIN { 
Script::Parser->import();
}
BEGIN { 
Text::Words->import(qw( string2list ));
}

BEGIN { 
Script::Element->import();
}
push @ISA, qw( Script::Element );

use Carp;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( html_tag );

### Subclass Information

# Uses Class::NamedFactory for subclass names

BEGIN { 
Class::NamedFactory->import();
}
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

BEGIN { 
Script::Sequence->import();
}
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


};
Script::HTML::Tag->import();
}
push @ISA, qw( Script::HTML::Container );

sub subclass_name { 'style' };
Script::HTML::Styles->register_subclass_name;

BEGIN { 
Text::Words->import(qw( string2hash ));
}
BEGIN { 
Text::PropertyList->import(qw( astext ));
}
BEGIN { 
Script::Literal->import();
}

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
};
Script::HTML::Styles->import();
}

# [grid values=dref (direction=across|down border,width=n)] ... [/grid]
Script::Tags::Grid->register_subclass_name();
sub subclass_name { 'grid' }

%ArgumentDefinitions = (
  'values' => {'dref'=>'optional', 'required'=>'list'},
  
  'sortorder' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
  
  'numcols' => {'dref'=>'optional', 'required'=>'number'},
  'direction' => {'dref'=>'optional', 'default'=>'down', 
					    'required'=>'oneof across down'},
  'border' => {'dref'=>'optional', 'default' => 0, 
					    'required'=>'number'},
  'width' => {'dref'=>'optional', 'default' => 0, 
					    'required'=>'string_or_nothing'},
  'style' => {'dref'=>'optional', 'default'=>'normal', 
					    'required'=>'string_or_nothing'},
);

# $html_table = $gridtag->interpret();
sub interpret {
  my $gridtag = shift;
  my $args = $gridtag->get_args;
  
  my $values = $args->{'values'};
  
  map { $_ = "readable." . $_ } @{$args->{'sortorder'}}
      if UNIVERSAL::isa($values->[0], 'Record');
  
  # Make a copy of the list so we don't alter the sort order of the original
  sort_in_place( $values=[@$values], @{$args->{'sortorder'}})
						    if ($args->{'sortorder'});
  
  my $numberofcols = $args->{'numcols'};
  my $numrows = int(.99 + scalar(@$values) / $numberofcols);  # -filled- rows
  my $width = $args->{'width'};
  my $cellwidth = $width ? int ($width / $numberofcols) : 0;
  
  my $html = "<table width=$width cellspacing=0 cellpadding=0 " . 
	"border=$args->{'border'}>\n";
  
  $gridtag->{'outer'} = $Root->{'loop'};
  local $Data::DRef::Root->{'loop'} = $gridtag;
  
  my($row, $col);
  foreach $row (0 .. ($numrows - 1)) {
    $gridtag->{'row'} = $row;
    $html .= '<tr>';
    for $col (0 .. ($numberofcols - 1)) {
      $gridtag->{'col'} = $col;
      $gridtag->{'n'} = ($args->{'direction'} eq 'across') 
		    ? $gridtag->{'col'} + ($gridtag->{'row'} * $numberofcols) 
		    : $gridtag->{'row'} + ($gridtag->{'col'} * $numrows);
      next if ($gridtag->{'n'} > $#{$values});
      $html .= "<td valign=top align=left" . 
      				($cellwidth ? "width=$cellwidth" : '' ) . ">";
      $gridtag->{'value'} = $values->[$gridtag->{'n'}];
      my $value = $gridtag->interpret_contents();
      $value = stylize($args->{'style'}, $value) if ($args->{'style'});  
      $html .= $value;
      $html .= '</td>' . "\n";
    }
    $html .= '</tr>' . "\n";
  }
    
  $html .= "</table>\n";
  
  return $html;
}

1;


};
Script::Tags::Grid->import();
}
BEGIN { 
$INC{'Script::Tags::Report'} = 'lib/Script/Tags/Report.pm';
eval {
### Script::Tags::Report generates columnar tables for records and the like

### Caveats and Things To Do
  # - Combine the display and subtotal column structures.

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Piglet   E. J. Evans         (piglet@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-05-29 Switched to use of Script::Evaluate package instead of Script.-S
  # 1998-05-04 Added "if scalar @subtotals" to expand.  -Piglet
  # 1998-04-23 Changed link logic in columns_for_record.
  # 1998-04-20 Changed columns_for_record's map to foreach to avoid $_ problems
  # 1998-04-17 Updated to use new Data::Sorting interface.
  # 1998-03-11 Inline POD added. -Simon
  # 1998-03-11 Improved columns_for_record to set dref to readable or link.
  # 1998-03-10 Changed 'die' in columns_for_record to 'return []'.  -Piglet
  # 1998-03-03 Removed uses of field.group.name drefs; field.readable instead
  # 1998-01-25 Refactored to support non-record items, new cell options. -Simon
  # 1997-12-04 Finished implementing sub-totals behavior.  -Piglet
  # 1997-11-25 Improved column-level information structure.
  # 1997-11-20 Found cell-option scoping problem; bgcolors alternate again. -S.
  # 1997-11-11 Extracted from fieldtags.pm. -Piglet

package Script::Tags::Report;

$VERSION = 4.00_1998_03_11;

BEGIN { 
$INC{'Script::Evaluate'} = 'lib/Script/Evaluate.pm';
eval {
### Script::Evaluate -- provide the runscript macro without changing syntaxes.

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Caveats and Things Undone
  # - Should support local DRef assignments via something like the below:
  #   runscript( $script, '-record' => $foo );

### Change History
  # 1998-06-04 Added runscript_with_local_data.
  # 1998-05-29 Separated from top-level Script.pm -Simon

package Script::Evaluate;

require 5.000;

BEGIN { 
Script::Parser->import();
}

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( runscript );

# $result = runscript( $script_text );
sub runscript { Script::Parser->new->parse( shift )->interpret(); }

# $result = runscript_with_local_data( $script_text, $dref => $value, ... );
sub runscript_with_local_data {
  my $script_text = shift;
  
  my %ex_locals;
  while ( scalar @_ ) {
    my ($key, $val) = (shift, shift);
    $ex_locals{ $key } = getData($key);
    setData($key, $val);
  }
  
  my $result = runscript( $script_text );
  
  foreach ( keys %ex_locals ) {
    setData($_, $ex_locals{ $_ });
  }
  
  return $result;
}

1;

};
Script::Evaluate->import(qw( runscript ));
}
BEGIN { 
Script::Tag->import();
}
@ISA = qw( Script::Tag );

BEGIN { 
Err::Debug->import();
}

BEGIN { 
Data::DRef->import();
}
BEGIN { 
Data::Collection->import();
}
BEGIN { 
Data::Sorting->import(qw( sort_in_place ));
}

BEGIN { 
Text::Format->import(qw( formatted ));
}
BEGIN { 
Script::HTML::Styles->import();
}
BEGIN { 
$INC{'Script::HTML::Tables'} = 'lib/Script/HTML/Tables.pm';
eval {
### Script::HTML::Tables provides three tag classes for building HTML tables
  #
  # For your html generation pleasure we have....
  # - tables, a list of rows (and some options)
  # - table rows, a list of cells (and ...?)
  # - table cells, a string (and some options)
  #
  # We often build sub-tables and then merge 'em, but that code's a bit rusty

### Interface
  # $table = table( $args, @rows );
  # $row = row( $args, @cells );
  # $cell = cell( $args, @elements );

### Table: <table> <tr>...</tr> ... </table>
  # $tag = Script::HTML::Table->new( $args, @rows );
  # $table->default_options;
  # $table->new_row( @cells );
  # $sequence->add( $element );
  # $stringvalue = $sequence->interpret_contents();
  # $count = $table->rowspan;
  # $count = $table->colspan;
  # $table->add_table_to_right( $other_table );
  # $table->add_table_to_bottom( $other_table );

### Table Row: <tr> <td>...</td> ... </tr>
  # $sequence->add( $element );
  # $tag = Script::HTML::Row->new( $args, @cells );
  # $row = Script::HTML::Table::Row->new_with_new_cell( @_ );
  # $colspan = $row->colspan;

### Table Cell: <td> ... </td>
  # $tag = Script::HTML::Table::Cell->new( $args, @elements );
  # $colspan = $cell->colspan;
  # $cell->default_options;
  # %$args = $tag->get_args();
  # $html_or_nbsp = $cell->interpret_contents();

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-30 removed version number from Number::Stats import lines - bnair
  # 1998-03-29 Added add_table_to_top method. -Simon
  # 1998-03-19 Replaced cell() with Cell->new in add_table_to_right.  -P
  # 1998-01-25 Table cells now use Script::HTML::Colors for bgcolor mapping -S.
  # 1997-12-09 Changed new cell default alignment to left.  -Piglet
  # 1997-11-07 Fixed some lines that were causing "use of undefined" errors
  # 1997-10-31 Refactored for four-oh. -Simon
  # 1997-09-30 Changes to cell->html(); don't show colspan if it's == 1.
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-21 Minor cleanup.
  # 1997-06-19 Created these classes based on existing HTML manipulation code.

package Script::HTML::Tables;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( table row cell );

BEGIN { 
Script::HTML::Tag->import();
}

# $table = table( $args, @rows );
sub table ($;@) { return Script::HTML::Table->new( shift, @_ );     }

# $row = row( $args, @cells );
sub row ($;@)   { return Script::HTML::Table::Row->new( shift, @_ );  }

# $cell = cell( $args, @elements );
sub cell ($;@)  { return Script::HTML::Table::Cell->new( shift, @_ );}

### Table: <table> <tr>...</tr> ... </table>

package Script::HTML::Table;
@ISA = qw( Script::HTML::Container );

sub subclass_name { 'table' };
Script::HTML::Table->register_subclass_name;

BEGIN { 
$INC{'Number::Stats'} = 'lib/Number/Stats.pm';
eval {
### Number::Stats provides basic math manipulations for groups of numbers

### Change History
  # 1997-11-24 Moved into the new Number:: hierachy.
  # 1997-11-0? Created. -Simon

package Number::Stats;

use vars qw( $VERSION );
$VERSION = 1.00_1998_03_11;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( maximum minimum total average );

# $n = maximum( @numbers );
sub maximum {
  my $max = 0;
  foreach ( @_ ) { $max = $_ if ( ! $max or $max < $_ ); } 
  return $max;
}

# $n = minimum( @numbers );
sub minimum {
  my $min = 0;
  foreach ( @_ ) { $min = $_ if ( ! $min or $min > $_ ); } 
  return $min;
}

# $n = total( @numbers );
sub total {
  my $total = 0;
  foreach ( @_ ) { $total += $_  } 
  return $total;
}

# $n = average( @numbers );
sub average {
  return total( @_ ) / scalar(@_);
}

1;


};
Number::Stats->import(qw( maximum ));
}
use Carp;

# $table->default_options;
sub default_options {
  my $table = shift;
  $table->{'args'} = { 'border' => 0, 'cellspacing' => 0, 'cellpadding' => 0 };
}

# $table->new_row( @cells );
sub new_row {
  my $table = shift;
  $table->add( Script::HTML::Table::Row->new( {}, @_ ) );
}

# $ok_flag = $sequence->about_to_add( $element );
sub about_to_add {
  my $sequence = shift;
  my $target = shift;
  
  return if ( UNIVERSAL::isa($target, 'Script::Literal')
  						 and $target->iswhitespace());
  
  # Hmm. Do we want to check that it doesn't return anything that's not a
  # a table row? Or...
  confess "can't add '$target' as contents of a table" 
			unless ( UNIVERSAL::isa($target, 'Script::HTML::Table::Row')
				  or UNIVERSAL::isa($target, 'Script::Element') );
  	
  return 1;
}

# $stringvalue = $sequence->interpret_contents();
sub interpret_contents {
  my $sequence = shift;
  
  my $value = '';
  $value .= "\n";
  foreach $item ( $sequence->elements ) {
   $value .= $item->interpret();
    $value .= "\n";
  }
  return $value;
}

# $count = $table->rowspan;
sub rowspan {
  my $table = shift;
  return $table->elementcount;
}

# $count = $table->colspan;
sub colspan {
  my $table = shift;
  return maximum ( $table->call_on_each('colspan') );
}

# $table->add_table_to_right( $other_table );
sub add_table_to_right {
  my ($table, $other_table) = @_;
  
  my $total_cols = $table->colspan + $other_table->colspan;
  
  my $most_rows = maximum( $table->rowspan, $other_table->rowspan );
  
  my $original_table_colspan = $table->colspan;
  foreach $row_n (0 .. $most_rows -1) {
    # warn "adding table, at row $row_n \n";
    unless ( $row_n < $table->rowspan ) {
      # warn "compensating for shortness of table len " . $table->rowspan . "\n";
      my @spacers;
      push @spacers, Script::HTML::Table::Cell->new({ 'colspan' => $original_table_colspan }, '') if ( $original_table_colspan );
      $table->new_row( @spacers );
      # warn "new row is at " . $table->rowspan . "\n";
    }
    
    if ( $row_n < $other_table->rowspan ){
      # warn "adding row \n";
      $table->elements->[ $row_n ]->append_elements( 
      			$other_table->elements->[ $row_n ]->elements );
    } else   {
      # warn "padding row \n";
      my $spacer = Script::HTML::Table::Cell->new();
      $spacer->{'args'}{'colspan'} = $other_table->colspan; 
      $table->elements->[ $row_n ]->append_elements( $spacer );
    }
  }
  $table->{'cols'} = $total_cols;
}

# $table->add_table_to_top( $other_table );
sub add_table_to_top {
  my ($table, $other_table) = @_;
  
  my ($colspan, $other_colspan) = ( $table->colspan, $other_table->colspan );
  my $most_cols = maximum( $colspan, $other_colspan );
  $table->pad_to_column( $most_cols ) if ( $colspan < $most_cols );
  $other_table->pad_to_column($most_cols) if ( $other_colspan < $most_cols );
  
  $table->prepend_elements( @{$other_table->elements()} );
}

# $table->add_table_to_bottom( $other_table );
sub add_table_to_bottom {
  my ($table, $other_table) = @_;
  
  # warn ((caller(0))[1] . ' line ' . (caller(0))[2]);
  # warn "table $table, other_table $other_table\n";
  
  my ( $colspan, $other_colspan ) = ( $table->colspan, $other_table->colspan );
  
  my $most_cols = maximum( $colspan, $other_colspan );
  
  $table->pad_to_column( $most_cols ) if ( $colspan < $most_cols );
  $other_table->pad_to_column( $most_cols ) if ( $other_colspan < $most_cols );
  $table->append_elements( @{$other_table->elements()} );
}

sub pad_to_column {
  my $table = shift;
  my $width = shift;
  foreach $row ( $table->elements ) {
    my $diff = ($width - $row->colspan) || next;
    $row->append_elements( Script::HTML::Table::Cell->new(
			      { 'colspan' => $diff }, '') );
  }
}

### Table Row: <tr> <td>...</td> ... </tr>

package Script::HTML::Table::Row;
@ISA = qw( Script::HTML::Container );

sub subclass_name { 'tr' };
Script::HTML::Table::Row->register_subclass_name;

use Carp;
BEGIN { 
Number::Stats->import(qw( total ));
}

# $ok_flag = $sequence->about_to_add( $element );
sub about_to_add {
  my $sequence = shift;
  my $target = shift;
    
  return if ($target->isa('Script::Literal') and $target->iswhitespace());
  
  croak "can't add '$target' as contents of a table row" 
			unless ( $target->isa('Script::HTML::Table::Cell') 
				  or $target->isa('Script::Element') );
  	
  return 1;
}

# $stringvalue = $sequence->interpret_contents();
sub interpret_contents {
  my $sequence = shift;
  
  my $value = '';
  $value .= "\n";
  foreach $item ( $sequence->elements ) {
    $value .= '  ';
    $value .= $item->interpret();
    $value .= "\n";
  }
  return $value;
}

# $row = Script::HTML::Table::Row->new_with_new_cell( @_ );
sub new_with_new_cell {
  my $package = shift;
  return $package->newrow( {}, Script::HTML::Table::Cell->new( @_ ) );
}

# $colspan = $row->colspan;
sub colspan {
  my $row = shift;
  return total( $row->call_on_each('colspan') );
}

### Table Cell: <td> ... </td>

package Script::HTML::Table::Cell;
@ISA = qw( Script::HTML::Container );

sub subclass_name { 'td' };
Script::HTML::Table::Cell->register_subclass_name;

use Carp;
BEGIN { 
$INC{'Script::HTML::Colors'} = 'lib/Script/HTML/Colors.pm';
eval {
### Script::HTML::Colors provides a named color registry for HTML macros

### Change History
  # 1998-01-25 Created. -Simon

package Script::HTML::Colors;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( color_by_name %Colors );

use vars qw( %Colors );

%Colors = (
  'bgcolor' => '#ffffff',
  'link' => '#bb0000',
  'alink' => '#ff0000',
  'vlink' => '#880088',
);

sub color_by_name {
  my $color_val = shift;
  return $Colors{ $color_val } || $color_val;
}

1;
};
Script::HTML::Colors->import(qw( color_by_name ));
}

# $colspan = $cell->colspan;
sub colspan {
  my $cell = shift;
  return $cell->{'args'}{'colspan'} || 1;
}

# $cell->default_options;
sub default_options {
  my $cell = shift;
  $cell->{'args'} = { 'align' => 'left', 'valign' => 'top' };
}

# %$args = $tag->get_args();
sub get_args {
  my $tag = shift;
  
  confess "bad tag $tag" unless ( UNIVERSAL::isa($tag->{'args'}, 'HASH' ) );
  my $args = ref $tag->{'args'} ? { %{$tag->{'args'}} } : {};
  
  delete $args->{'colspan'}
	    if ( exists $args->{'colspan'} and $args->{'colspan'} == 1 );
  delete $args->{'rowspan'}
	    if ( exists $args->{'rowspan'} and $args->{'rowspan'} == 1 );
  
  delete $args->{'bgcolor'} 
	    if ( exists $args->{'bgcolor'} and $args->{'bgcolor'} eq '-none' );
  $args->{'bgcolor'} = color_by_name($args->{'bgcolor'})
						  if ( $args->{'bgcolor'} );
  
  return $args;
}

1;
};
Script::HTML::Tables->import();
}

Script::Tags::Report->register_subclass_name();
sub subclass_name { 'report' }

%ArgumentDefinitions = (
  'records' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
  
  'display' => {'dref'=>'optional', 'required'=>'hash_or_nothing'},
  
  'columns' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
					    # really, list of hashes
  'fieldorder' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
  'sortorder' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
  'groupby' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
  'grouporder' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
  'subtotals' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
  
  'block' => {'dref'=>'optional', 'required'=>'string_or_nothing' },
  'colheader' => {'dref'=>'no', 'default'=> '1', 'required'=>'flag'},
  'border' => {'dref'=>'no', 'default'=> '0' },
  'width' => {'dref'=>'no', 'default'=> '100%' },
  'nocolor' => {'required' => 'flag'},
);

# $args = $tag->get_args();
  # Allow people to pass in a display argument refering to an options hash.
sub get_args {
  my $tag = shift;
  my $args = $tag->SUPER::get_args();
  
  debug('report', ['$args->{\'grouporder\'} :'], $args->{'grouporder'});

  if ($args->{'display'}) {
    $args->{'sortorder'} ||= $args->{'display'}{'sortorder'};
    $args->{'fieldorder'} ||= $args->{'display'}{'fieldorder'};
    $args->{'block'} ||= $args->{'display'}{'block'};
    $args->{'groupby'} ||= $args->{'display'}{'groupby'};
    $args->{'grouporder'} ||= $args->{'display'}{'grouporder'};
    $args->{'subtotals'} ||= $args->{'display'}{'subtotals'};
  }

  # debug('report', ['$args are:'], $args);
  
  return $args;
}

# $htmltext = $report->interpret;
sub interpret {
  my $report = shift;
  $report->expand->interpret;
}

# $table = $report->expand;
sub expand {
  my $report = shift;
  my $args = $report->get_args;
  
  # Content Items
  local $report->{'items'} = $args->{'records'} || [];
  my $itemzero = $report->{'items'}[0];
  
  # Sorting and Grouping
  local $report->{'sortorder'} = $args->{'sortorder'} || [];
  map { $_ = "field.readable." . $_ } @{$report->{'sortorder'}}
				  if UNIVERSAL::isa($itemzero, 'Record');
  local $report->{'groupby'} = $args->{'groupby'} || [];
  map { $_ = "field.readable." . $_ } @{$report->{'groupby'}}
				  if UNIVERSAL::isa($itemzero, 'Record');
  local $report->{'grouporder'} = $args->{'grouporder'} || [];
  map { $_ = "field.readable." . $_ } @{$report->{'grouporder'}}
				  if UNIVERSAL::isa($itemzero, 'Record');
  
  # Columns
  local $report->{'columns'} = $args->{'columns'} ||
	    $report->columns_for_record($itemzero, @{$args->{'fieldorder'}} );
  debug('report', 'Columns are ', $report->{'columns'});
  
  local $report->{'subtotals'} = 
	    $report->columns_for_record($itemzero, @{$args->{'subtotals'}}  )
	    if scalar @{$args->{'subtotals'}};
  
  local $field2cols = {};
  foreach $i (0..$#{$report->{'columns'}}) { 
    $field2cols->{ $report->{'columns'}[$i]{'fieldname'} } = $i; 
  }
  foreach $field (@{$report->{'subtotals'}}) { 
    $field2cols->{ $field->{'fieldname'} } = scalar(keys %$field2cols)
    				unless $field2cols->{ $field->{'fieldname'} }; 
  }
  debug 'report', "My field2cols hash is", $field2cols;
  
  # Spanning Line
  local $spanning_line = sub { Script::runscript($args->{'block'}) } 
							  if $args->{'block'};
  
  # Styling
  local $nocolor = $args->{'nocolor'};
  
  # Build the Table
  local $target = table( { 'cellspacing' => 0, 'cellpadding' => 2,
		'width' => $args->{'width'}, 'border' => $args->{'border'} });
  
  $target->add($report->columntitles) if ( $args->{'colheader'} );
  
  $report->do_tabulation( $target, {}, $report->{'items'}, 0 );
  
  return $target;
}

### Columns

# %@$columns = $report->columns_for_record($record, @fieldnames);
sub columns_for_record {
  my $report = shift;
  my $record = shift; 	  # UNIVERSAL::isa($record, 'Record')
  return [] unless (ref $record);
  my $count = 0;
  my $links = UNIVERSAL::isa($record, 'Record') && 
		$record->datastore && $record->datastore->user_can('view');
  my $title = $record->default_fieldname;
  
  my $fieldname;
  my @columns;
  foreach $fieldname ( @_ ) {
    my $method = $links && ($fieldname eq $title) ? 'link' : 'display';
    push @columns, {
      'fieldname' => $fieldname,
      'position' => $count++,
      
      'dref' => "field.$method.$fieldname",
      'valref' => "field.value.$fieldname",
      
      'title' => getDRef($record, "field.title.$fieldname") || '',
      'align' => getDRef($record, "field.align.$fieldname") || 'left',
      'format' => getDRef($record, "field.format.$fieldname") || '',
      'width' => getDRef($record, "field.colwidth.$fieldname") || 0,
    }
  }
  return \@columns;
}

# $html_row = $report->columntitles()
sub columntitles {
  my $report = shift;
  my $style = $nocolor ? 'bold' : 'heading';
  my $opts = { 'valign' => 'bottom' };
  $opts->{'bgcolor'} = 'colhead' unless $nocolor;
  my $row = row('');
  my $column;
  foreach $column (@{$report->{'columns'}}) {
    local $opts->{'width'} = $column->{'width'} if ( $column->{'width'} );
    $row->add(cell( {%$opts, 'align' => $column->{'align'}}, 
    		stylize($style, $column->{'title'} || '&nbsp;') ));
  }
  foreach $column (@{$report->{'subtotals'}}) {
    next if ( $field2cols->{ $column->{'fieldname'} } < 
					      scalar(@{$report->{'columns'}}));
    local $opts->{'width'} = $column->{'width'} if ( $column->{'width'} );
    $row->add(cell( {%$opts, 'align' => $column->{'align'}}, 
	      stylize($style, $column->{'title'} || '&nbsp;') )) 
  }
  return $row;
}

### Tabulation

# $report->do_tabulation( $table, $totals, $items, $round )
sub do_tabulation {
  my ($report, $table, $totals, $items, $round) = @_;
  
  my ($subtable, $subtotals) = $report->build_table($items, $round);
  $table->add_table_to_bottom($subtable);
  
  if (scalar @{$report->{'subtotals'}}) {
    $table->add( $report->totals_row($subtotals, 
		  ( $round ? 'Subtotals:  &nbsp;' : 'Totals: &nbsp;' ) ) );
    $report->add_totals( $totals, $subtotals );
  }
}

# ($table, $totals) = $report->build_table( $items, $round );
sub build_table {
  my ($report, $items, $round) = @_;
  
  # No Items In List
  return $report->no_items_in_list if (scalar @$items < 1);
  
  # Break into groups and recurse
  return $report->grouped_table( $items, $round )
				unless (($#{$report->{'groupby'}}) < $round);
  
  # Tabulate
  return $report->table_for_items($items, $round % 2)
}

# ($table, $totals) = $report->no_items_in_list;
sub no_items_in_list {
  my $report = shift;
   
  return table('', row('', cell( { 'colspan' => $target->colspan() }, 
	  stylize('normal', "No items in list.")))), {};
}

# ($table, $totals) = $report->grouped_table( $items, $round );
sub grouped_table {
  my ($report, $items, $round) = @_;
  
  my $group_label = $report->{'groupby'}->[$round];
  my $group_sort = $report->{'grouporder'}->[$round] || $group_label;
  debug('report', ["\$group_label = '$group_label'", "\$group_sort = '$group_sort'"]);
  debug('report', ["\$report->{'grouporder'}", $report->{'grouporder'}]);

  my $groups = orderedindexby($items, $group_label, $group_sort);
  
  my $table = table('', '');
  my $totals = {};
  
  foreach $group (@$groups) {
    $table->new_row( cell( { 'colspan' => $target->colspan }, 
    	stylize('group' . $round, 
	  (length $group->{'value'} ? $group->{'value'} : 'None' ))));
    
    $report->do_tabulation( $table, $totals, $group->{'items'}, $round + 1 );
    
    $table->new_row( cell( { 'colspan' => $target->colspan }, 
			   	 stylize('normal', '&nbsp;'))) unless $round; 
  }
  
  return ($table, $totals);
}

# ($table, $totals) = $report->table_for_items( $items, $even_flag );
sub table_for_items {
  my ($report, $items, $even) = @_;
  my $table = table('', '');
  my $totals = {};

  sort_in_place($items, @{$report->{'sortorder'}} )  
  					if scalar(@{$report->{'sortorder'}});
  
  foreach $item (@$items) {
    $table->add( $report->rows_for_item($item, $even) );
    $report->add_item_to_totals($totals, $item);
    $even = ! $even;
  }
  
  debug 'report', "My totals in table_for_items are", $totals;
  return ($table, $totals);
}

# @rows = $report->rows_for_item($item, $even);
sub rows_for_item {
  my $report = shift;
  my ($item, $even) = @_;
  
  my $args = { 'valign' => 'top' };  
  $args->{'bgcolor'} = ($even ? 'alternate' : 'background') unless $nocolor;
  
  my $row = row('','');
  
  my $column;
  foreach $column (@{$report->{'columns'}}) {
    my $value = getDRef( $item, $column->{'dref'} );
    $value = '&nbsp;' unless (defined $value and length $value);
    $row->add( cell({%$args, 'align' => $column->{'align'}}, 
		    stylize('normal', $value)));
  }
  
  my @rows = ( $row );
  
  # Spanning line
  if ($spanning_line) {
    setData('-record', $item);
    debug 'report', "My item body is", $item->{'body'};
    my $line = &$spanning_line;
    debug 'report', "My line is $line";
    push @rows, row({}, cell( { %$args, 'align' => 'left', 
	    'colspan' => $target->colspan }, stylize('normal', $line)))
							  if ($line =~ /\S/);
  }
  return @rows;
}

### Totals

# $report->add_item_to_totals($totals, $item);
sub add_item_to_totals {
  my $report = shift;
  my ($totals, $item) = @_;
  my $col;
  foreach $col (@{$report->{'subtotals'}}) { 
    $totals->{ $col->{'fieldname'} } ||= 0;
    $totals->{ $col->{'fieldname'} } += getDRef( $item,  $col->{'valref'} ); 
  }
}

# $report->add_totals($base_totals, $totals_to_be_added);
sub add_totals {
  my $report = shift;
  my ($totals, $others) = @_;
  
  foreach $field (@{$report->{'subtotals'}}) { 
    $totals->{ $field->{'fieldname'} } ||= 0; 
    $totals->{ $field->{'fieldname'} } += $others->{$field->{'fieldname'}}; 
  }
}

# $row = $report->totals_row( $totals, $label );
sub totals_row {
  my ($report, $totals, $label) = @_;
  
  debug 'report', "Building subtotal row for totals", $totals;
  
  my @cells = map { cell('') } (1..scalar(keys %$field2cols));
  foreach $field (@{$report->{'subtotals'}}) { 
    my $value = $totals->{$field->{'fieldname'}};
    $value = formatted($field->{'format'}, $value) if $field->{'format'};
    my $cell = $cells[$field2cols->{ $field->{'fieldname'} }];
    $cell->{'args'}{'align'} = $field->{'align'} || 'left';
    $cell->add( stylize('normal', $value) );
  }
  
  $cells[0]->prepend(Script::Literal->new(stylize('label', $label))) 
				  	if (defined $label and length $label);
  
  return row(@cells) ;
};

1;


};
Script::Tags::Report->import();
}
BEGIN { 
$INC{'Script::Tags::Detail'} = 'lib/Script/Tags/Detail.pm';
eval {
### Script::Tags::Detail provides a two-column record table layout for records

### Interface
  # [detail record=#x]
  # $text = $detailtag->interpret();

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-06-01 Changed record_edit 'required' to $field->{'require'} eq 'yes'.  -Piglet
  # 1998-05-27 Changed asterisk.jpeg to asterisk.jpg to be consistant with
  #            our other image files.  -EJM
  # 1998-05-27 Restored searchhints. -Simon
  # 1998-05-22 Left comlumn width no longer defaults to 160. -Dan
  # 1998-05-22 Changed usage of required field indicator. -Dan
  # 1998-05-18 Fields can now override their layout for edit forms by defining  
  #            a row_edit method; used by Field::Compound::Postal.  -EJM
  # 1998-05-05 Added $RequiredIndicator.
  # 1998-05-03 Changed left column width default to 160.
  # 1998-04-23 Added support for Field::Compound's $field->edit_title method 
  # 1998-03-19 Use new editable method to avoid editing calculated fields. -Del
  # 1998-03-11 Inline POD added.
  # 1998-02-01 Added compact_edit.
  # 1998-01-25 Use of field definition for field detail. 
  # 1997-12-04 Expanded field detail support into its own subclass.
  # 1997-12-02 Initial support for field detail.
  # 1997-11-26 Some reorganization, half-hearted support for field-details.
  # 1997-11-25 Added support for search mode -- maybe should subclass?
  # 1997-11-19 Added support for edit mode, error messages
  # 1997-11-10 Created. -Simon

package Script::Tags::Detail;

$VERSION = 4.00_1998_03_11;

BEGIN { 
Script::HTML::Tables->import();
}

BEGIN { 
Script::Tag->import();
}
@ISA = qw( Script::Tag );
BEGIN { 
Err::Debug->import();
}

BEGIN { 
Script::HTML::Styles->import();
}

# [detail record=#x]
Script::Tags::Detail->register_subclass_name();
sub subclass_name { 'detail' }

%ArgumentDefinitions = (
  'record' =>  {'dref' => 'optional', 'required'=>'anything'},
  'mode' =>  {'dref' => 'optional', 'default'=>'display',
  					 'required'=>'string_or_nothing'},
  'compacttitle' =>  {'dref' => 'optional', 'required'=>'anything'},
  'compactappend' =>  {'dref' => 'optional', 'required'=>'anything'},
);

# $text = $htmlmacro->interpret();
sub interpret {
  my $detail = shift;
  return $detail->expand->interpret;
}

# $html_table = $detailtag->expand();
sub expand {
  my $detail = shift;
    
  local $detail->{'rows'} = $detail->make_rows;
  
  return $detail->build_table();
}

### HTML Generation

# $html_table = $detailtag->build_table( );
sub build_table {
  my $detail = shift;
  my $table = Script::HTML::Table->new({'cellpadding'=>0, 'cellspacing'=>2});

  my $row;
  my $contains_required;
  foreach $row ( @{$detail->{'rows'}} ) {
    my $display = stylize('normal', $row->{'display'} );
    
    my $rower = $row->{'wide'} ? \&add_wide_row : \&add_normal_row;
    
    &$rower($table, $row->{'title'}, $display, $row->{'required'} );
    &$rower($table, '', stylize('hint', $row->{'hint'}) ) if $row->{'hint'};
    if ( $row->{'errors'} and scalar @{$row->{'errors'}} ) {
      &$rower($table, '', stylize('alert', join('<br>', @{$row->{'errors'}})));
    }
    $contains_required = 1 if ( $row->{'required'} );
  }

if ( $contains_required ) {
  $table->prepend(row({}, cell({'colspan'=>3}, stylize ('normal', '<img src=' . $WebApp::Handler::SiteHandler::Site->asset_url('images', 'asterisk.jpg'). '> indicates required field.'))));
}

  return $table;
}

# add_normal_row( $table, $label, $value );
sub add_normal_row {
  my ($table, $label, $value, $require) = @_;

  $table->new_row( 
    cell(
      { 'nowrap'=>1, 'valign'=>'top', 'align'=>'right'}, 
	( $label ? stylize('label', $label) : '' ) ),

    cell( 
      { 'valign'=>'top', 'align'=>'left', 'width'=>2 },
        ( $require ? $RequiredIndicator : '&nbsp;' ) ),

    cell({ 'valign'=>'top' }, $value )
  );
}

# add_wide_row( $table, $label, $value );
sub add_wide_row {
  my ($table, $label, $value, $require) = @_;
  
  $table->new_row( 
    cell({ 'colspan'=>3, 'valign'=>'top', 'align'=>'left'}, 
	( $label ? stylize('label', $label) . 
	( $require ? $RequiredIndicator : '&nbsp;' ) . '<br>' : '' ) . $value),
  );
}

### Record Interface

use vars qw( %display_functions );
%display_functions = (
  'sparse' => \&record_sparse_display,
  'display' => \&record_display,
  'edit' => \&record_edit,
  'search' => \&record_search,
  'compactedit' => \&record_compact_edit,
);

use vars qw( $RequiredIndicator );
$RequiredIndicator ||= '<font color=red>*</font>';

# %@$rows = $detailtag->make_rows();
sub make_rows {
  local $detail = shift;
  
  my $args = $detail->get_args;
  
  my $displayer = $display_functions{ $args->{'mode'} };
  die "unknown detail mode '$args->{'mode'}'\n" unless $displayer;
  
  my @rows;
  push @rows, &$displayer( $args->{'record'} );
  
  return \@rows;
}

# %@rows = record_sparse_display( $record );
sub record_sparse_display {
  my @rows;
  my $record = shift;
  my $fieldname;
  foreach $fieldname ( $record->fieldnames ) {
    next if $record->prefer_silent( $fieldname );
    
    my $display = $record->display( $fieldname );
    debug 'detail', 'Detail display:', $fieldname, '-', $display;
    next unless ( length $display );
    
    push @rows, { 
      'title' => $record->title( $fieldname ) .':',
      'display' => $display,
      'wide' => $record->prefer_wide_row( $fieldname ),
    };
  }
  return @rows;
}

# %@rows = record_display( $record );
sub record_display {
  my @rows;
  my $record = shift;
  my $fieldname;
  foreach $fieldname ( $record->fieldnames ) {
    next if $record->prefer_silent( $fieldname );
   push @rows, { 
      'title' => $record->title( $fieldname ) .':',
      'display' => $record->display( $fieldname ),
      'wide' => $record->prefer_wide_row( $fieldname ),
    };
  }
  return @rows;
}

# %@rows = record_edit( $record );
sub record_edit {
  my @rows;
  my $record = shift;
  my $fieldname;
  foreach $fieldname ( $record->fieldnames ) {
    # next if $record->prefer_silent( $fieldname );
    next unless $record->editable( $fieldname );
    my $field = $record->field( $fieldname );

    # See if there is an row_edit method for this field.  If so, we will 
    # do our processing there as we need to break out the subfields onto
    # individual lines.

    if ( $field->can('row_edit') ) {
       $field->row_edit ( $record, \@rows, 'prefix'=>'record' );
       }
    else {
       my $title = $field->can('edit_title') ? $field->edit_title( $record ) 
   					   : $record->title( $fieldname ) .':';
         
       push @rows, { 
         'title' => $title,
         'display' => $record->edit( $fieldname, 'prefix'=>'record' ),
         'wide' => $record->prefer_wide_row( $fieldname ),
         'errors' => $record->errors->{ $fieldname },
         'hint' => $field->{'hint'},
         'required' => (exists $field->{'require'} and $field->{'require'} eq 'yes'),
       };
    }
  }
  return @rows;
}

# %@rows = record_compact_edit( $record );
sub record_compact_edit {
  my @rows;
  my $record = shift;
  my $fieldname;
  $rows[0] = { 'wide' => 1, 'title'=> $detail->{'args'}{'compacttitle'}.':' };
  foreach $fieldname ( $record->fieldnames ) {
    my $field = $record->field( $fieldname );
    next unless $field->{'compact'};
    next unless $record->editable( $fieldname );
    #!# This isn't really general-purpose at the moment. -Simon
    
    if ( ! $record->prefer_wide_row( $fieldname ) ) {
      $rows[0]->{'display'} .= ' on ' if ( $rows[0]->{'display'} );
      $rows[0]->{'display'} .= $record->edit( $fieldname, 'prefix'=>'record' );
      push @{$rows[0]->{'errors'}}, @{$record->errors->{ $fieldname }};
      $rows[0]->{'hint'} .= $field->{'hint'};
    } else {
      my $title = $record->title( $fieldname ) .':';
      $title .= $RequiredIndicator if ( $field->{'require'} eq 'yes' );
      push @rows, { 
	'title' => $title,
	'display' => $record->edit( $fieldname, 'prefix'=>'record' ),
	'wide' => 1,
	'errors' => $record->errors->{ $fieldname },
	'hint' => $record->field( $fieldname )->{'hint'},
      };
    }
  }
  $rows[0]->{'display'} .= $detail->{'args'}{'compactappend'};
  
  return @rows;
}

# %@rows = record_search( $record );
sub record_search {
  my @rows;
  my $record = shift;
  my $fieldname;
  foreach $fieldname ( $record->searchfields ) {
    next if $record->prefer_silent( $fieldname );
    my $field = $record->field( $fieldname );
    
    push @rows, {
      'title' => $record->title( $fieldname ) .':',
      'display' => $record->edit_criteria({},$fieldname, 'prefix'=>'criteria'),
      'hint' => $field->{'searchhint'},
    };
  }
  return @rows;
}

### Field Interface

package Script::Tags::FieldDetail;

BEGIN { 
Script::Tags::Detail->import();
}
@ISA = qw( Script::Tags::Detail );

# [fielddetail field=#fielddef step=n]
Script::Tags::FieldDetail->register_subclass_name();
sub subclass_name { 'fielddetail' }

%ArgumentDefinitions = (
  'field' =>  {'dref' => 'optional', 'required'=>'anything'},
  'step' =>  {'dref' => 'optional', 'required'=>'string_or_nothing'},
);

# %@$rows = $detailtag->make_rows();
sub make_rows {
  my $detail = shift;
  
  my $args = $detail->get_args;
  my $f_def = $args->{'field'};
  
  my $prefix = 'instance';
  my @rows;
  if ( $args->{'step'} eq 'type' ) {
    push @rows, { 'title' => 'Name:', 
		  'display' => $f_def->edit( 'title', 'prefix'=>$prefix ) };
    push @rows, { 'title' => 'Type:',
		  'display' => Script::HTML::Forms::Select->new(
		      { 'name'=>"$prefix.type", 'current'=>$f_def->{'type'} },
		      map { 
			Script::HTML::Forms::Option->new({'value' => $_,
							  'label' => "\u$_" }) 
		      } sort keys %Field::known_subclasses
		    )->interpret };
    
  } elsif ( $args->{'step'} eq 'options' ) {
    my $fieldname;
    foreach $fieldname ( $f_def->fieldnames ) {
      next if ( $fieldname eq 'title' or $f_def->prefer_silent($fieldname) );
      push @rows, { 
	'title' => $f_def->title( $fieldname ) .':',
	'display' => $f_def->edit( $fieldname, 'prefix' => $prefix ),
	'wide' => $f_def->prefer_wide_row( $fieldname ),
	'errors' => $f_def->errors->{ $fieldname },
	'hint' => $f_def->field( $fieldname )->{'hint'},
      };
    }
  } else {
    die "unsupported step '$args->{'step'}'";
  }
  
  return \@rows;
}

1;


};
Script::Tags::Detail->import();
}
BEGIN { 
$INC{'Script::Tags::Calendar'} = 'lib/Script/Tags/Calendar.pm';
eval {
### Script::Tags::Calendar generates HTML month, week, and day calendars

### Caveats and Things To Do
  # - There's some overlap between the various expand functions that could
  #   effectively be moved into the superclass.

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Piglet   E.J. Evans (piglet@evolution.com)
  # Eric     Eric Moss

### Change History
  # 1998-05-07 Fixed background color for prev/next cells of Day views.
  # 1998-05-07 Fixed label display style for Day views.
  # 1998-05-04 Added picker.view=Day to prev/next in Day view. -Simon
  # 1998-04-28 Moved date increment to bottom of loop in right grid, week view.
  # 1998-04-24 Added picker.view=Week to week URLs; picker.view=Day to day. -P
  # 1998-04-17 Updated to use new Data::Sorting interface.
  # 1998-03-18 Fixed daily display.
  # 1998-03-11 Inline POD added.
  # 1998-02-23 Revised Week tag.
  # 1998-02-22 Revised Day and Month tags. -Simon
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-07-01 Cleanup and conversion to better date handling code.
  # 1997-06-29 Built out weeks and days.
  # 1997-06-24 Changes to monthly layout
  # 1997-06-?? Cleanup. -Simon
  # 1997-05-?? Developed calendar_month tag. -Eric
  # 1997-01-?? Wrote timechart tag. -Simon

package Script::Tags::Calendar;

$VERSION = 4.00_1998_03_11;

BEGIN { 
Script::Container->import();
}
@ISA = qw( Script::Container );

BEGIN { 
Data::DRef->import();
}

%ArgumentDefinitions = (
  # Target Day Date
  'date' => {'dref'=>'optional', 'default'=>'today',
  				'required'=>'string_or_nothing'},
  # Records
  'records' =>  {'dref' => 'optional', 'required'=>'list'},
  # Back Links
  'list_url' =>  {'dref' => 'optional', 'required'=>'string_or_nothing'},
  # Fields
  'startdatefield' => {'dref'=>'optional', 'default'=>'date_start'},
  'enddatefield' => {'dref'=>'optional', 'default'=>'date_end'},
  'sortorder' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
  # html style
  'datestyle' => {'dref'=>'optional', 'default'=>'name=normal bold',
					'required'=>'string_or_nothing'},
  'style' => {'dref'=>'optional', 'default'=>'name=normal',
					'required'=>'string_or_nothing'},
  'border' =>   {'dref'=>'optional', 'default'=> 1,'required'=>'number'},
  'bgcolor' =>   {'dref'=>'optional', 'default'=> '#000000'},
  'cellspacing' =>{'dref'=>'optional','default'=>1,'required'=>'number'},
  'cellpadding' =>{'dref'=>'optional','default'=>2,'required'=>'number'},
  'cellwidth' =>{'dref'=>'optional','default'=> 75,'required'=>'number'},
  'headcolor' => {'dref'=>'optional','default'=> 'colhead',
  					'required'=>'string_or_nothing'},
  'rowcolor' => {'dref'=>'optional','default'=> 'background',
  					'required'=>'string_or_nothing'},
  'altcolor' => {'dref'=>'optional','default'=> 'alternate',
  					'required'=>'string_or_nothing'},
);

%Types = (
  'month' => 'Script::Tags::Calendar::Month',
  'week' => 'Script::Tags::Calendar::Week',
  'day' => 'Script::Tags::Calendar::Day',
);

# $tag = Script::*TagClass*->new( %args );
sub new {
  my $package = shift;
  my %args = @_;
  
  if ( $package eq 'Script::Tags::Calendar' ) {
    $package = $Types{ $args{'type'} } ||
			    die "unknown calendar style $args{'type'}\n";
  }
  
  return $package->SUPER::new( %args );
}

# $html_text = $calendar_tag->interpret();
sub interpret {
  my $calendar_tag = shift;
  return $calendar_tag->expand->interpret;
}

# $html_text = $calendar_tag->daily_display($date, $records);
sub daily_display {
  my $tag = shift;
  my $date = shift;
  my $records = shift;
  
  local $Data::DRef::Root->{'calendar'} = $tag;
  
  $date = $date->yyyymmdd if ( ref $date );
  
  my $contents;
  foreach (@$records) {
    $tag->{'record'} = $_;
    unless ( ref $_ ) {
      warn "Bogus calendar record $tag->{'record'} \n";
      next;
    }
    # warn "Calendar record $tag->{'record'} \n";
    my $start = getDRef($tag->{'record'}, $tag->{'startdatefield'});
    my $end = getDRef($tag->{'record'}, $tag->{'enddatefield'});
    # warn "   $start $end\n";
    # warn "cal:".$date.' ' . $start->yyyymmdd . ' ' . $end->yyyymmdd . "\n";
    if ($start->yyyymmdd <= $date and $end->yyyymmdd >= $date) {
      warn "Day match:".$date.' '.$start->yyyymmdd.' '.$end->yyyymmdd."\n";
      my $value = $tag->interpret_contents;
      $value = stylize($args->{'style'}, $value) if ($args->{'style'});
      $contents .= '<p>' . $value;
    }
  }
  delete $tag->{'record'};
  
  $contents = '&nbsp;' unless ( defined $contents and length $contents );
  return $contents;
}

### CALENDAR DAY

package Script::Tags::Calendar::Day;

@ISA = qw( Script::Tags::Calendar );

BEGIN { 
Script::HTML::Tag->import();
}
BEGIN { 
Script::HTML::Tables->import();
}
BEGIN { 
Script::HTML::Styles->import();
}

BEGIN { 
Data::DRef->import(qw( getData setData ));
}
BEGIN { 
Data::Sorting->import(qw( sort_in_place ));
}
BEGIN { 
DateTime::Date->import();
}

# [cal_day record=#x]
Script::Tags::Calendar::Day->register_subclass_name();
sub subclass_name { 'cal_day' }

%ArgumentDefinitions = %Script::Tags::Calendar::ArgumentDefinitions;

# $html_table = $day_tag->expand();
sub expand {
  my $day_tag = shift;
  my $args = $day_tag->get_args;
  my $date = DateTime::Date::new_date_from_value( $args->{'date'} );
  my $pickdate_args = getData('request.args.pickdate');
  my @months = (DateTime::Date::months)[1..12];
  my $records = $args->{'records'};

  $day_tag->{'startdatefield'} = $args->{'startdatefield'};
  $day_tag->{'enddatefield'} = $args->{'enddatefield'};

  warn 'pickdate args sub month is ', $pickdate_args->{'month'};

  if ( $pickdate_args->{'year'} ) {
    $pickdate_args->{'year'} += 2000 if ($pickdate_args->{'year'} < 50);
    $pickdate_args->{'year'} += 1900 if ($pickdate_args->{'year'} < 100);
    $date->year( $pickdate_args->{'year'} );
  }
  $date->month( $pickdate_args->{'month'} +1 ) if ( defined
						  $pickdate_args->{'month'} );
  $date->day( $pickdate_args->{'day'} ) if ( defined
						  $pickdate_args->{'day'} );
  setData('my.pickdate', $date);
  my $monthpicker = (html_tag('select', {'name'=>'pickdate.month',
					'current'=>($date->month)-1}));
  my $month_index = 0;
  warn 'Months are ', @months;
  foreach $month (@months) {
    $monthpicker->add(html_tag('option', {'value'=>$month_index,
							 'label'=>$month}));
    $month_index++;
  }

  # Make a copy of the list so we don't alter the sort order of the original
  # Maybe do this within each day for that day's records?
  sort_in_place( $records=[@$records] , @{$args->{'sortorder'}} )  
						    if ($args->{'sortorder'});
    
  # Create the table
  my $table = table( { map { $_, $args->{$_} }
		      qw( border width cellspacing cellpadding bgcolor ) } );
  
  my $site = $WebApp::Handler::SiteHandler::Site || {};
  
  # Add title row with prev/next links and date picker
  $table->new_row(
    cell( {'bgcolor' => $args->{'headcolor'}, 'align'=>'center' }, 
      html_tag('form', {'action'=>'-current'},
        html_tag('a', { 'href' => $args->{'list_url'} . 
	    '&date=' . $date->prev_day->yyyymmdd . '&picker.view=Day'}, 
        html_tag('img', { 'src'=>$site->asset_url('navicons', 'prev.gif'), 
							'border'=>0 }) ),
        ' &nbsp; ',
        $monthpicker,
        ' &nbsp; ',
        html_tag('input', {'type',=>'text', 'size'=>3, 'name'=>'pickdate.day', 
							'value'=>$date->dd}),
        ' &nbsp; ',
        html_tag('input', {'type',=>'text', 'size'=>5, 'name'=>'pickdate.year', 
							'value'=>$date->year}),
        ' &nbsp; ',
        html_tag('input', {'type',=>'submit', 'value'=>'Redisplay'}),
        ' &nbsp; ',
        html_tag('a', { 'href' => $args->{'list_url'} . 
    		'&date=' . $date->next_day->yyyymmdd  . '&picker.view=Day' }, 
        html_tag('img', { 'src'=>$site->asset_url('navicons', 'next.gif'), 
							'border'=>0 }) ),
      ),
    ),
  );
  
  $table->new_row(
    cell({ 'bgcolor'=>$args->{'rowcolor'}, 'colspan'=>1, 'align'=>'left' },
	  stylize('name=normal', $day_tag->daily_display($date, $records) ))
  );
  return $table;
}

### CALENDAR MONTH

package Script::Tags::Calendar::Month;

@ISA = qw( Script::Tags::Calendar );

BEGIN { 
Script::HTML::Tag->import();
}
BEGIN { 
Script::HTML::Tables->import();
}
BEGIN { 
Script::HTML::Styles->import();
}

BEGIN { 
Data::Sorting->import(qw( sort_in_place ));
}
BEGIN { 
Data::DRef->import();
}
BEGIN { 
DateTime::Date->import();
}

# [cal_month record=#x]
Script::Tags::Calendar::Month->register_subclass_name();
sub subclass_name { 'cal_month' }

%ArgumentDefinitions = %Script::Tags::Calendar::ArgumentDefinitions;

# $html_table = $month_tag->expand();
sub expand {
  my $month_tag = shift;
  my $args = $month_tag->get_args;
  
  my $date = DateTime::Date::new_date_from_value( $args->{'date'} );
  
  my $records = $args->{'records'};
  $month_tag->{'startdatefield'} = $args->{'startdatefield'};
  $month_tag->{'enddatefield'} = $args->{'enddatefield'};
 
  # Make a copy of the list so we don't alter the sort order of the original
  # Maybe do this within each day for that day's records?
  sort_in_place( $records=[@$records] , @{$args->{'sortorder'}} )  
						    if ($args->{'sortorder'});
    
  # Create the table
  my $table = table( { map { $_, $args->{$_} }
		      qw( border width cellspacing cellpadding bgcolor ) } );
  
  my $site = $WebApp::Handler::SiteHandler::Site;
  
  # Add title row with prev/next links and date picker
  my $prev = DateTime::Date::new_date_from_value( 
      { 'day'=> 1, 'year'=>$date->year,  'month'=>$date->month - 1 } 
  );
  my $next = DateTime::Date::new_date_from_value ( 
      { 'day'=> 1, 'year'=>$date->year,  'month'=>$date->month + 1 } 
  );
  $table->new_row(
    cell( {'colspan'=>8, 'bgcolor'=>'background', 'align'=>'center' }, 
        html_tag('a', { 'href' => $args->{'list_url'} . '&date=' . 
							$prev->yyyymmdd }, 
        html_tag('img', { 'src'=>$site->asset_url('navicons', 'prev.gif'), 
							'border'=>0 }) ),
        stylize('label', '&nbsp; [' . $date->month_name 
					. '] [' . $date->year . '] &nbsp;'),
        html_tag('a', { 'href' => $args->{'list_url'} . '&date=' . 
							$next->yyyymmdd }, 
        html_tag('img', { 'src'=>$site->asset_url('navicons', 'next.gif'), 
							'border'=>0 }) ),
    ),
  );
  
  # Days-of-week header
  my @days_of_week = (DateTime::Date::daysofweek)[1..7];
  $table->new_row(
    cell({ 'bgcolor'=>$args->{'headcolor'}, 'width'=>15 }, '&nbsp;' ),
    map { cell(
      {'bgcolor'=>$args->{'headcolor'}, 'align'=>'center', 'valign'=>'bottom'},
      stylize('heading', $_ ) ) 
    } @days_of_week
  );
  
  # Monthly Calendar Geometry
  my $daysinmonth = $date->num_days_in_month;
  my $first_day_of_month = $date->first_day_in_month;
  my $firstday_dow = $first_day_of_month->dayofweek;
  
  my $last_day_of_month = $date->last_day_in_month;
  my $lastday_dow = $last_day_of_month->dayofweek;
   
  my $numrows = int(.99 + ($daysinmonth + $firstday_dow - 1) / 7);
  
  # Generate week rows
  
  my $week_n;
  foreach $week_n ( 0 .. ($numrows - 1) ) {
    
    my $first_day_of_week = $first_day_of_month->clone;
    $first_date_of_week = ($week_n * 7) - $firstday_dow + 2;
    $first_day_of_week->day($first_date_of_week) if ($week_n);
    
    my $row = row( {}, cell(
	{'bgcolor' => 'colhead', 'width'=>15, 'valign'=>'top'}, 
      html_tag('a', { 'href' => 
      		$args->{'list_url'}.'&date='.$first_day_of_week->yyyymmdd.'&picker.view=Week' }, 
      html_tag('img', { 'border'=>0, 'src' =>
      		$site->asset_url('navicons', 'week.gif') }),
      '<br><br>' ), 
    ) );
    
    for $dow (1 .. 7) {
      $day = $dow + $first_date_of_week - 1;
      if ($day > 0 && $day <= $daysinmonth) {
	$date->day( $day );
	# Generate day contents
	$row->add( cell({ 'bgcolor'=>'white', 
	    'width'=>$args->{'cellwidth'}, 'valign'=>'top', 'align'=>'left' },
	  html_tag('a', { 'href' => 
	      $args->{'list_url'}.'&date='.$date->yyyymmdd.'&picker.view=Day' }, 
	    stylize('label', $date->day) ),
	  stylize('normal', $month_tag->daily_display($date, $records)),
	));
      } elsif ( $day == 0 ) {
	$row->add( cell({'bgcolor'=>'#cccccc', 
			'colspan' => $firstday_dow - 1 }, '&nbsp;' ));
      } elsif ( $day == ($daysinmonth + 1) ) {
	$row->add( cell({'bgcolor'=>'#cccccc', 
			'colspan' => 7 - $lastday_dow }, '&nbsp;' ));
      }
    }
    $table->add( $row );
  }
  
  return $table;
}

### CALENDAR WEEK

package Script::Tags::Calendar::Week;

@ISA = qw( Script::Tags::Calendar );

BEGIN { 
Script::HTML::Tag->import();
}
BEGIN { 
Script::HTML::Tables->import();
}
BEGIN { 
Script::HTML::Styles->import();
}

BEGIN { 
Data::Sorting->import(qw( sort_in_place ));
}
BEGIN { 
Data::DRef->import();
}
BEGIN { 
DateTime::Date->import();
}

# [cal_week record=#x]
Script::Tags::Calendar::Week->register_subclass_name();
sub subclass_name { 'cal_week' }

%ArgumentDefinitions = %Script::Tags::Calendar::ArgumentDefinitions;

# $html_table = $week_tag->expand();
sub expand {
  my $week_tag = shift;
  my $args = $week_tag->get_args;
  
  my $date = DateTime::Date::new_date_from_value( $args->{'date'} );
  # push date back to the Monday of the same week
  $date->day( $date->day - $date->dayofweek + 1 );
  
  my $records = $args->{'records'};
  $week_tag->{'startdatefield'} = $args->{'startdatefield'};
  $week_tag->{'enddatefield'} = $args->{'enddatefield'};
 
  # Make a copy of the list so we don't alter the sort order of the original
  # Maybe do this within each day for that day's records?
  sort_in_place( $records=[@$records] , @{$args->{'sortorder'}} )  
						    if ($args->{'sortorder'});
  
  # Create the table
  my $table = table( { map { $_, $args->{$_} }
		      qw( border width cellspacing cellpadding bgcolor ) } );
  
  my $site = $WebApp::Handler::SiteHandler::Site;
  
  # Add title row with prev/next links and date picker
  my $prev = $date->clone;
  $prev->day( $date->day - 7 );  
  my $next = $date->clone;
  $next->day( $date->day + 7 );  
  
  my $startdate = $date->clone;
  my $enddate = $date->clone;
  $enddate->day( $date->day + 6 );
  
  $table->new_row(
    cell( {'colspan'=>6, 'bgcolor'=>'background', 'align'=>'center' }, 
      html_tag('a', { 'href' => 
	  $args->{'list_url'}.'&date='.$prev->yyyymmdd.'&picker.view=Week' }, 
	html_tag('img', { 'src'=>$site->asset_url('navicons', 'prev.gif'), 
						      'border'=>0 })
      ),
      html_tag('form', {'action'=>'-current'},
	html_tag('select', {'name'=>'blah'}, 
	  html_tag('option', {'label'=>'Is this'}),
	  html_tag('option', {'label'=>'Working?'}),
        )
      ),
      stylize('label', '&nbsp; Week of: &nbsp;'),
      html_tag('a', { 'href' => 
	  $args->{'list_url'}.'&date='.$next->yyyymmdd.'&picker.view=Week' }, 
	html_tag('img', { 'src'=>$site->asset_url('navicons', 'next.gif'), 
						      'border'=>0 }) 
      ),
    ),
  );
  
  my $left_grid = table( {} ) ;
  foreach $day ( 1 .. 3 ) {
    
    my $label = '&nbsp;<br>' . 
    		stylize('sans white size=+3', $date->day ) . 
		'<br>' .
		stylize('small white sans', $date->nameofweekday) . 
		'<br>&nbsp;';
    
    my $daylink = html_tag('a', { 'href' => 
      		$args->{'list_url'}.'&date='.$date->yyyymmdd.'&picker.view=Day' }, 
      html_tag('img', { 'border' => 0, 'src' =>
      		$site->asset_url('navicons', 'day.jpg') }) );
    
    my $rowspan = (($day == 3) ? 2 : 1);
    $left_grid->new_row(
      cell( {'rowspan'=>$rowspan, 'bgcolor'=>'#336699',  
	  'valign'=>'middle' }, $daylink), 
      cell( {'width'=>90, 'align'=>'center', 'bgcolor'=>'background', 
      	  'rowspan'=>$rowspan }, $label), 
      cell( {'rowspan'=>$rowspan, 'width'=>$args->{'cellwidth'}, , 
	'bgcolor'=>'background' }, $week_tag->daily_display($date, $records)), 
    );
    
    $date->day( $date->day + 1 );
  }
  $left_grid->new_row();
  
  my $right_grid = table( {} ) ;
  foreach $day ( 4 .. 7 ) {
    
    my $label = '&nbsp;<br>' . 
    		stylize('sans white size=+3', $date->day ) . 
		'<br>' .
		stylize('small white sans', $date->nameofweekday) . 
		'<br>&nbsp;';
    
    my $daylink = html_tag('a', { 'href' => 
      		$args->{'list_url'}.'&date='.$date->yyyymmdd.'&picker.view=Day' }, 
      html_tag('img', { 'border' => 0, 'src' =>
      		$site->asset_url('navicons', 'day.jpg') }) );
    
    $right_grid->new_row(
      cell( {'width'=>$args->{'cellwidth'}, 'bgcolor'=>'background' }, 
      	  $week_tag->daily_display($date, $records)), 
      cell( {'width'=>90, 'align'=>'center', 'bgcolor'=>'background' },
         $label), 
      cell( { 'bgcolor'=>'#336699', 'valign'=>'middle' }, $daylink), 
    );
    $date->day( $date->day + 1 );
        
  }
  
  $left_grid->add_table_to_right( $right_grid );
  $table->add_table_to_bottom( $left_grid );
  
  return $table;
}

1;


};
Script::Tags::Calendar->import();
}

BEGIN { 
$INC{'Script::Tags::Hidden'} = 'lib/Script/Tags/Hidden.pm';
eval {
### Script::Tags::Hidden provides bulk-creation of new HTML input type=hidden's

### Interface
  # [hidden args=#/"argument names" (source=#request.args prefix=namepadding) ]
  # $html_tag_text = $hidden->interpret();
  # %$arg = $hidden->get_args();
  # $sequence_of_html_tag = $hidden->expand();

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-11 Inline POD added.
  # 1997-12-04 Added skip option
  # 1997-11-26 Brought up to four-oh.
  # 1997-03-11 Split from script.tags.pm -Simon

package Script::Tags::Hidden;

$VERSION = 4.00_1998_03_11;

BEGIN { 
Script::Tag->import();
}
@ISA = qw( Script::Tag );

Script::Tags::Hidden->register_subclass_name();
sub subclass_name { 'hidden' }

BEGIN { 
$INC{'Script::HTML::Forms'} = 'lib/Script/HTML/Forms.pm';
eval {
### Script::HTML::Forms provides forms-related HTML tags

### <form> ... </form>

### <input>
  # %$args = $tag->get_args();

### <select> <option> text ... </select>

### <option>
  # %$args = $tag->get_args();

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-06-11 Added support for <option label=#...> -Simon
  # 1998-05-27 Added default_command. -Dan
  # 1998-04-27 Added escaping for option labels.
  # 1998-03-20 Replaced request.links.script_file with links.script . path.info
  # 1998-03-05 Added Submit package, which creates <input type=submit> tags.
  # 1998-03-03 Shifted to exlicit imports from Data::DRef.
  # 1997-11-23 Moved 'current' argument from option->args to select->interpret
  # 1997-11-21 Added option label argument handling
  # 1997-10-31 Created. -Simon

package Script::HTML::Forms;

$VERSION = 4.00_1998_03_03;

BEGIN { 
Script::HTML::Tag->import();
}

### <form> ... </form>

package Script::HTML::Forms::Form;
@ISA = qw( Script::HTML::Container );

sub subclass_name { 'form' };
Script::HTML::Forms::Form->register_subclass_name;

BEGIN { 
Data::DRef->import(qw( getData ));
}

# <form action=#url|-current method=get|post|multipart enctype=x target=x>..</>

# %$args = $tag->get_args();
sub get_args {
  my $tag = shift;
  
  my $args = { %{$tag->{'args'}} };
  
  $args->{'action'} = 
	      getData('request.links.script') . getData('request.path.info')
		  if ( $args->{'action'} and $args->{'action'} eq '-current' );
  
  if ( $args->{'method'} and $args->{'method'} eq 'multipart' ) {
    $args->{'method'} = 'post';
    $args->{'enctype'} = 'multipart/form-data';
  }

  if ($args->{'default_command'} and (getData('request.client.browser') =~ /MSIE/)) {

    warn 'WEB BROWSER IS IE';
    $args->{'onsubmit'} = 'if ( ! this.command.value ) { 
                             this.command.click();
			     return false
			   } else { return true }'
  } else {
    warn 'WEB BROWSER IS: ', getData('request.client.browser');
  }

  delete $args->{'default_command'};

  return $args;
}

### <input>

package Script::HTML::Forms::Input;
@ISA = qw( Script::HTML::Tag );

sub subclass_name { 'input' };
Script::HTML::Forms::Input->register_subclass_name;

BEGIN { 
Data::DRef->import(qw( getData ));
}

# %$args = $tag->get_args();
sub get_args {
  my $tag = shift;
  
  my $args = { %{$tag->{'args'}} };
  
  $args->{'value'} = getData($args->{'value'})
		      if ( $args->{'value'} and $args->{'value'} =~ s/\A\#// );
  
  return $args;
}

### <input type=submit>

package Script::HTML::Forms::Submit;
@ISA = qw( Script::HTML::Forms::Input );

sub init {
  my $tag = shift;
  $tag->{'args'}{'type'} ||= 'submit';
  $tag->{'args'}{'name'} ||= 'command';
}

### <textarea> text ... </textarea>

package Script::HTML::Forms::TextArea;
@ISA = qw( Script::HTML::Container );

sub subclass_name { 'textarea' };
Script::HTML::Forms::TextArea->register_subclass_name;

### <select> <option> text ... </select>

package Script::HTML::Forms::Select;
@ISA = qw( Script::HTML::Container );

BEGIN { 
Data::DRef->import(qw( getData ));
}

sub subclass_name { 'select' };
Script::HTML::Forms::Select->register_subclass_name;

# $sequence->add( $element );
# sub add {
#   my $sequence = shift;  
#   my $element = shift;
#   $element = Evo::Script::Literal->new( $element ) unless (ref $element);
#   
#   $sequence->append($element) if ($element->isa('Script::HTML::Forms::Option'));
# }

# $html = $tag->interpret()
sub interpret {
  my $tag = shift;
  local $Current = $tag->{'args'}->{'current'}
				    if ( exists $tag->{'args'}->{'current'} );
  $Current = getData($Current) if (defined $Current and $Current =~ s/\A\#// );
  return $tag->SUPER::interpret();
}

### <option>

package Script::HTML::Forms::Option;
push @ISA, qw( Script::HTML::Tag );

sub subclass_name { 'option' };
Script::HTML::Forms::Option->register_subclass_name;

BEGIN { 
Data::DRef->import(qw( getData ));
}

# use Evo::Script::Sequence;
# push @ISA, qw( Evo::Script::Sequence );

# $html = $tag->interpret()
sub interpret {
  my $tag = shift;
  my $label_arg = $tag->{'args'}{'label'};
  $label_arg = getData($label_arg) if ( $label_arg =~ s/\A\#// );
  my $label = $label_arg || $tag->{'args'}{'value'} || '';
  return $tag->open_tag() . Script::HTML::Escape::html_escape($label);
}

# %$args = $tag->get_args();
sub get_args {
  my $tag = shift;
  
  my $args = $tag->SUPER::get_args();
  
  $args->{'value'} = getData($args->{'value'})
  					if ( $args->{'value'} =~ s/\A\#// );
  
  if (defined $Script::HTML::Forms::Select::Current) {
    if ( $Script::HTML::Forms::Select::Current eq $args->{'value'} ) {
      $args->{'selected'} = undef;
    } else {
      delete $args->{'selected'};
    }
  }
  
  delete $args->{'current'};
  delete $args->{'label'};
  
  return $args;
}

1;
};
Script::HTML::Forms->import();
}
BEGIN { 
Data::Collection->import();
}
BEGIN { 
Data::DRef->import(qw( $Separator getDRef getData ));
}

# [hidden args=argnames (source=#request.args prefix=namepadding skip=regex) ]
%ArgumentDefinitions = (
  # Name of the set of variables to be preserved as hidden input fields
  'args' => {'dref'=>'optional', 'required'=>'list'},
  
  # This is where to look for the existing values; defaults to #request.args
  'source' => {'dref'=>'optional', 'required'=>'hash_or_nothing'},
  # Written before each argument name, with a dot; default to empty
  'prefix' => {'dref'=>'optional', 'required'=>'string_or_nothing'},
  # Regex for subkeys you want to skip over.
  'skip' => {'dref'=>'optional', 'required'=>'string_or_nothing'},
  # Flag to avoid the scalarkeysandvaluesof call.
  'flat' => {'dref'=>'optional', 'required'=>'flag'},
);

# $html_tag_text = $hidden->interpret();
sub interpret {
  my $hidden = shift;
  $hidden->expand->interpret;
}

# %$arg = $hidden->get_args();
sub get_args {
  my $hidden = shift;
  
  my $args = $hidden->SUPER::get_args();
  
  $args->{'source'} ||= getData('request.args');
  $args->{'prefix'} .= $Separator if ($args->{'prefix'}); 
  
  return $args;
}

# $sequence_of_html_tag = $hidden->expand();
sub expand {
  my $hidden = shift;
  my $args = $hidden->get_args;
  
  my $sequence = Script::Sequence->new();
  
  my $argname;
  foreach $argname ( @{$args->{'args'}} ) {
    my $currentvalue = getDRef($args->{'source'}, $argname);
    if (! ref $currentvalue) {
      $sequence->add( $hidden->new_hidden_input( $args->{'prefix'} . $argname, 
      							$currentvalue ) );
    } else {
      $currentvalue = scalarkeysandvalues( $currentvalue ) 
      						unless ($args->{'flat'});
      my ($key, $value);
      while ( ($key, $value) = each %$currentvalue ) {
	next if ( $args->{'skip'} and $key =~ /\A$args->{'skip'}\Z/ );
	next unless (defined $value and length $value);
	$sequence->add( $hidden->new_hidden_input( 
		  $args->{'prefix'} . $argname . $Separator . $key, $value ) );
      }
    }
  }
  
  return $sequence;
}

sub new_hidden_input {
  my $hidden = shift;
  
  return Script::HTML::Forms::Input->new( 
		    { 'type'=>'hidden', 'name' => shift, 'value' => shift } );
}

1;


};
Script::Tags::Hidden->import();
}

BEGIN { 
$INC{'Script::Tags::Random'} = 'lib/Script/Tags/Random.pm';
eval {
### Script::Tags::Random returns a random selection from a given list

### Copywrite 1998 Evolution Online Systems, Inc.
  # Dan     Dan Hallum (dan@evolution.com)

### Change History
  # 1998-06-01 Created -Dan

package Script::Tags::Random;

BEGIN { 
Script::Tag->import();
}
@ISA = qw( Script::Tag );

Script::Tags::Random->register_subclass_name();
sub subclass_name { 'random' }

%ArgumentDefinitions = (
  'values' => {'dref'=>'optional', 'required'=>'list'},
);

sub interpret {
  my $gridtag = shift;
  my $args = $gridtag->get_args;
  
  my $values = $args->{'values'};

  return unless (scalar @$values);
  srand() unless ($we've_done_this_before ++);
  my $random = int( rand( scalar @$values ) );
  return $values->[$random];
};

1;
};
Script::Tags::Random->import();
}

1;
};
Script::Tags::Available->import();
}

# Enable script parsing for HTML tags: <tag arg=value>
BEGIN { 
Script::HTML::Tag->import();
}
Script::Parser->add_syntax( Script::HTML::Tag );

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( runscript );
push @EXPORT_OK, qw( runscript );

# $result = runscript( $script_text );
sub runscript { Script::Parser->new->parse( shift )->interpret(); }

1;

};
Script->import();
}

BEGIN { 
$INC{'WebApp::Server'} = 'lib/WebApp/Server.pm';
eval {
### WebApp::Server - Provides a framework for Perl web applications

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-10 Replaced do_request_safely with UNIVERSAL::TRY mechanism.
  # 1998-04-09 Added message() infrastructure.
  # 1998-04-06 Minor changes to support new subclasses.
  # 1998-03-02 Changed error message.
  # 1998-02-22 Added current $server->{'request'} throughout scope of run().
  # 1998-02-17 Moved WebApp.pm functionality into distinct Server package.
  # 1998-02-17 Changed do_request_safely to avoid failure message on redirect.
  # 1998-02-03 Commented out alarm due to NT failure.
  # 1998-01-28 Added tryto_do_request.
  # 1997-10-20 Minor changes.
  # 1997-10-05 Version 4 forked; Evo::request.pm is now WebApp/*

package WebApp::Server;

$VERSION = 1.01_00;

require 5.000;

use Carp;
BEGIN { 
Err::Debug->import();
}
BEGIN { 
$INC{'Err::Exception'} = 'lib/Err/Exception.pm';
eval {
### Err::Exception provides simple exception handling based on eval.

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # Developed by M. Simon Cavalletto (simonm@evolution.com)
  # Basic try and catch code from <cite>Programming Perl</cite>.
  # Additional inspiration from Organic Online's Exceptions.pm.

### Change History
  # 1998-04-23 Added DIE => BACKTRACE pragma.
  # 1998-04-17 Tweaked.
  # 1998-04-10 Replaced with new UNIVERSAL::TRY.
  # 1998-01-28 Moved try-related functions, but not throw/assert, to Err::Try.
  # 1997-03-23 Added assert function 
  # 1997-03-23 Started change log (couple of untracked weeks in there) -Simon

package Err::Exception;

BEGIN { 
Err::Debug->import();
}

sub UNIVERSAL::TRY {
  my ($self, $catch, @catchers) = @_;
  
  debug 'exceptions', "Attempting", "$catch", "on $self";
  
  my $wantarray = wantarray();
  
  local $pragmas = { 'TIMEOUT' => 0, 'DIE' => '' };
  while ( scalar @catchers and exists $pragmas->{ $catchers[0] } ) {
    my ($pragma, $value) = ( shift(@catchers), shift(@catchers) );
    debug 'exceptions', "Pragma", $pragma, 'is being set to', $value;
    if ( $pragma eq 'DIE' and $value eq 'STACKTRACE' ) {
      $value = sub {
	warn Carp::longmess "Exception backtrace:\n"; # Carp::cluck
	CORE::die @_;
      };	
    }
    $pragmas->{ $pragma } = $value;
  }
  
  my @results;
  eval {
    local $SIG{'__DIE__'} = $pragmas->{'DIE'} if ( $pragmas->{'DIE'} );
    warn "PRAGMA DIE $pragmas->{'DIE'}\n" if ( $pragmas->{'DIE'} );
    local $SIG{'ALRM'} = sub { die "timeout"; }, alarm $pragmas->{'TIMEOUT'} 
						  if ($pragmas->{'TIMEOUT'});
    
    my ($method, @args) = ( ref $catch eq 'ARRAY' ? @$catch : ($catch) );
    @results = ( $wantarray ? $self->$method(@args) 
			    : scalar($self->$method(@args)) );
  };
  alarm 0 if ( $pragmas->{'TIMEOUT'} );
  
  return ( $wantarray ? @results : $results[0] ) unless ( $@ );
  
  my $error = $@;
  debug 'exceptions', "Exception:", $error;
  
  while ( scalar @catchers ) {
    my ($pattern, $handler) = ( shift(@catchers), shift(@catchers) );
    # debug 'exceptions', "Checking catcher", $pattern, "against", $error;
    if ( $pattern eq 'ANY' or $error =~ /\A\s*$pattern\s*\Z/is ) {
      debug 'exceptions', "Catching", $pattern, 'with', "$handler";
      if ( $handler eq 'IGNORE' ) {
	return;
      } elsif ( ref $handler eq 'ARRAY' and $handler->[0] eq 'warn' ) {
        $_ = $error;
        my $msg = eval "\"$handler->[1]\"";
	warn $msg . ( substr($msg, -1) eq "\n" ? '' : "\n" );
      } elsif ( ref $handler eq 'ARRAY' and $handler->[0] eq 'method' ) {
	$self->TRY( [ @{$handler}[1..$#$handler] ], @catchers);
	return;
      } elsif ( ref $handler eq 'ARRAY' and $handler->[0] eq 'eval' ) {
	TRY( [ @{$handler}[1..$#$handler] ], @catchers);
	return;
      } else {
	die 'Unknown exception recovery option $pattern - $handler; unable to catch $error';
      }
    }
  }
  die $error;
}

1;


};
Err::Exception->import();
}
BEGIN { 
Data::DRef->import(qw( $Root ));
}

### Instantiation and Configuration

# $RequestTimeout - Number of seconds per-request; zero value sets no limit.
use vars qw( $RequestTimeout $DeathTrap );
$RequestTimeout = 30 unless ($^O =~ /Win32/); # alarm not safe in win32

# $server = WebApp::Server->new();
# $server = WebApp::Server->new($request_class, @handler_classes);
sub new {
  my $package = shift;
  my $server = { };
  bless $server, $package;
  $server->request_class(shift) if (scalar @_);
  while (scalar @_) { $server->add_handler(shift->new) ;}
  return $server;
}

# $request_class = $server->request_class();
# $server->request_class($request_class);
sub request_class {
  my $server = shift;
  $server->{'request_class'} = shift if (scalar @_);
  return $server->{'request_class'};
}

# $server->add_handler( $handler );
sub add_handler {
  my $server = shift;
  push @{$server->{'handlers'}}, shift; 
}

# $server->notify_handlers( $method, @args );
sub notify_handlers {
  my ( $server, $method, @args) = @_;
  my $handler;
  foreach $handler ( @{$server->{'handlers'}} ) { $handler->$method(@args); }
}

# $handler = $server->find_one_handler( $method, @args );
sub find_one_handler {
  my ($server, $method, @args) = @_;
  
  my $handler;
  foreach $handler ( @{$server->{'handlers'}} ) {
    return $handler if $handler->$method(@args);
  }
}

### Server Lifecycle

# $server->run();
sub run {
  my $server = shift;
  
  $server->startup;
  while ( $server->{'request'} = $server->request_class->new ) { 
    $server->do_request( $server->{'request'} );
    delete $server->{'request'};
  }
  $server->shutdown;
}

# $server->startup;
sub startup {
  my $server = shift;
  
  debug 'server', 'Starting up.';
  $server->notify_handlers('startup');
  $server->request_class->startup();
  debug 'server', 'Startup complete.';
  debug 'server-v', 'Server is:', $server;
}

# $server->do_request( $request );
sub do_request {
  my ($server, $request) = @_;
  
  debug 'server-v', 'Received request:', $request;
  debug 'server', 'Starting to respond to the request.';
  
  $server->TRY(['respond_to_request', $request], 
    'TIMEOUT' => $RequestTimeout,
    # 'DIE' => 'STACKTRACE',
    'ANY' => ['warn', 'Request Terminated: $_'],
    'Unable to connect to MySQL.*' => 
	      ['method', 'redirect_to_page', $request, 'dberror.page'],
    'No Tables' => ['method', 'redirect_to_page', $request, 'welcome.page'],
    'ODBC connection' => 
	['method', 'redirect_to_page', $request, 'dberror.page', 'msg'=>'$_'],
    'banned' => ['method', 'send_message', $request, 'banned'],
    'redirected' => 'IGNORE',
    'ANY' => ['method', 'send_message', $request, 'failure'],
  );
  
  $server->send_message($request, 'request_not_handled') 
			    unless ( $request->{'has_replied'} );
  
  $server->notify_handlers('done_with_request', $request);
  
  $request->done_with_request();
  debug 'server', 'Done with request.';
}

# $server->respond_to_request( $request );
sub respond_to_request {
  my ($server, $request) = @_;
  
  $server->TRY(['notify_handlers', 'starting_request', $request], 
    'redirected' => 'IGNORE',
  );
  
  local $Root->{'my'} = {};
  
  $server->TRY(['find_one_handler', 'handle_request', $request], 
    'redirected' => 'IGNORE',
  ) unless ( $request->{'has_replied'} );
}

# $server->shutdown;
sub shutdown {
  my $server = shift;
  debug 'server', 'Shutting down.';
  $server->request_class->at_end();
  $server->notify_handlers('shutdown');
  debug 'server', 'Shutdown complete.';
}

### Messages and Other Replies

# $server->redirect_to_page($request, $page_name, %info);
sub redirect_to_page {
  my ($server, $request, $page_name, %info) = @_;
  
  $request->redirect_and_end(
    $request->{'site'}{'url'} . $request->{'links'}{'script'} . 
    "/" . $page_name . '?' . WebApp::Request::query_string_from_args(\%info)
  );
}

# $html_page_string = $server->message($message, %info);
sub message {
  my ($server, $message, %info) = @_;
  
  my ($severity, $title, $error, $description);
  if ( $message eq 'banned' ) {
    $severity = 'Permission Exception';
    $title = 'Request Refused';
    $error = "Sorry, you don't have permission to see this page."
  } elsif ( $message eq 'request_not_handled' ) {
    $severity = 'Application Server Error';
    $title = 'Request Not Handled';
    $error = 'Sorry, the server was unable to handle your request.'
  } elsif ( $message eq 'failure' ) {
    $severity = 'Application Server Error';
    $title = 'Error';
    $error = 'Sorry, there was a fatal error while trying to handle your request.';
  } else {
    $severity = 'Application Server Error';
    $title = 'Unknown Exception';
    $error = 'Sorry, there was a fatal error while trying to handle your request.';
  }
  $server->message_page($severity, $title, $error, $description || '');
}

# $html_page_string = $server->message_page($severity, $title, $error, $desc);
sub message_page {
  my ($server, $severity, $title, $error, $description) = @_;
  
  return $server->custom_message_page($severity, $title, $error, $description)
  					if $server->can('custom_message_page');
  
  return "<html><head><title>$severity: $title</title></head>\n" . 
	"<body bgcolor=white><h1>$title</h1>\n" . 
	  "<p>$error\n<p>$description</body></html>\n";
}

# $server->send_message($request, $message, %info);
sub send_message {
  my ($server, $request, $message, %info) = @_;
  debug 'server', 'Sending message:', $message, (scalar %info ? (\%info):());
  $request->reply( $server->message( $message, %info ) );
}

### DRef interface

BEGIN { 
Data::DRef->import();
}

# $value = get($server, $dref);
sub get {
  my ($server, $dref) = @_;
  
  return time() if ( $dref eq 'timestamp' );
  
  Data::DRef::get( $server, $dref );
}

1;


};
WebApp::Server->import();
}

BEGIN { 
$INC{'WebApp::Request::CGI'} = 'lib/WebApp/Request/CGI.pm';
eval {
### WebApp::Request::CGI implements the basic CGI request/response protocol

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License
  # Distantly descended from code by s.e.brenner@bioc.cam.ac.uk
  # 
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Piglet   E.J. Evans (piglet@evolution.com)
  # Eric     Eric Schneider (roark@evolution.com)

### Change History
  # 1998-06-10 Added client:browser:is:IE3 in read_headers.  -Piglet
  # 1998-04-15 Made reply method a wrapper around subclass' send_reply
  # 1998-03-20 Portions moved to superclass, general cleanup, added inline POD. 
  # 1998-02-22 Added check for argument with empty name in parse_url_encoded.
  # 1998-02-18 Changed scoping of request data buffer from lexical to object.
  # 1998-02-18 Patch for IE3's bogus GET-multipart requests after redirect.
  # 1998-02-17 Fixed typo in error message.
  # 1998-02-01 Further mucking with parse_multipart_args.
  # 1998-01-25 Updated HTTPS detection logic based on INetics 1.01.
  # 1997-11-17 New nested arg handling to replace set(append) functionality
  # 1997-10-21 Folded remaining comments in from stripped 3.0 libraries. 
  # 1997-10-05 Version 4 forked; Evo::CGI moved to WebApp::Request::CGI.
  # 1997-10-15 Version 3.1 lib/Evo libraries archived for distribution
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-09-19 More careful stripping of directory_name out of directory_url
  # 1997-09-16 Changed parse_multipart_args to use it $_[0] in place, not split
  # 1997-08-12 Changed redirect to use CRLF pairs more carefully.
  # 1997-08-09 Changed return to use CRLF pairs more carefully.
  # 1997-08-08 Arg! More binmode suffering! Use of CRLFs in return.
  # 1997-07-11 Strip trailing slash from script_url, reordered parsing steps
  # 1997-06-01 Changed parse_multipart_args to include crlfs
  # 1997-05-27 Changed read to sysread, CRLF to CRLF|CR|LF, for Win32 usage
  # 1997-04-16 Moved debug and message arguments up and out of args hash
  # 1997-04-15 Now query_string for a post is *not* handled.
  # 1997-02-04 Removed script_name, added intranetics_path and intranetics_url
  # 1997-01-21 Cleanup of arg parsing functions.
  # 1997-01-20 Parse now handles multiple arg types (eg query string for posts)
  # 1997-01-11 Version 3 cloned and cleaned for use with IntraNetics.
  # 1996-11-14 Cleanup and styling.
  # 1996-11-12 Version 2 overhaul; method & encoding done in a single pass
  # 1996-08-16 Added cgi:file, cgi:timestamp. -Simon
  # 1996-07-31 Added filename and contenttype to multipart encoded data.
  # 1996-07-18 Added support for multipart/form-data encoding.
  # 1996-07-13 Build a nested argument hash using Evo::dataops::set. -Piglet
  # 1996-06-24 Modified to return hash with args and other data of note.
  # 1996-04-06 Version 1, first Evo build of a cgi library.  -Simon

package WebApp::Request::CGI;

$VERSION = 1.03;

BEGIN { 
$INC{'WebApp::Request'} = 'lib/WebApp/Request.pm';
eval {
### WebApp::Request - Superclass for HTTP-request interfaces

### Change History
  # 1998-06-12 Use of new WebApp::Browser package.
  # 1998-06-12 Revised parse_multipart_args for a 10-15% speed gain. -Simon
  # 1998-06-04 Use File::Name::Temp for uploaded file data, and
  #            save the original filename for use by Field::File. -Del
  # 1998-05-29 Multipart optimization with index and substr, not regexes. -Bala
  # 1998-05-07 New, non-binmode get_contents call
  # 1998-05-07 File uploads written to disk. -Simon
  # 1998-04-30 Corrected improper default content-type in send_file method
  # 1998-04-21 Re-added get_contents binmode flag until it settles down -Del
  # 1998-04-15 Made reply method a wrapper around subclass' send_reply
  # 1998-04-14 Added query_string_from_args function
  # 1998-03-20 Portions of CGI subclass abstracted up to here. 
  # 1998-01-27 Added send_file method.
  # 1997-10-?? Refactored. -Simon

package WebApp::Request;

$VERSION = 1.03;

use Carp;

BEGIN { 
Err::Debug->import();
}
BEGIN { 
Data::DRef->import(qw( getDRef setDRef ));
}
BEGIN { 
Data::Collection->import(qw( scalarkeysof ));
}

BEGIN { 
$INC{'WebApp::Browser'} = 'lib/WebApp/Browser.pm';
eval {
### WebApp::Browser provides information about some HTTP user agents.

### Copyright 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License
  # Portions cribbed from CGI::MozSniff, Jason Costomiris <jcostom@sjis.com>
  # 
  # Simon    M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 1998-06-15 Made MethodMaker import single line to help Devel::Preprocessor.
  # 1998-06-12 Created. -Simon

package WebApp::Browser;

BEGIN { 
$INC{'Class::MethodMakerExtentions'} = 'lib/Class/MethodMakerExtentions.pm';
eval {
#

### Change History
  # 1998-06-12 Added lookup.
  # 1998-05-09 Created. -Simon

package Class::MethodMakerExtentions;

BEGIN { 
$INC{'Class::MethodMaker'} = 'cpan-libs/Class/MethodMaker.pm';
eval {
package Class::MethodMaker;

#
# $Id: MethodMaker.pm,v 1.1.1.2 1997/01/23 23:05:36 seibel Exp $
#

# Copyright (c) 1996 Organic Online. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.



require 5.00307; # for the ->isa method.
use Carp;


use vars '$VERSION';
$VERSION = "0.92";
			
# Just to point out the existence of these variables

use vars
 '$TargetClass',    # The class we are making methods for.

 '%BooleanPos',     # A hash of the current index into the bit vector
                    # used in boolean for each class.

 '%BooleanFields',  # A hash of refs to arrays which store the names of
                    # the bit fileds for a given class

 '%StructPos',      # A hash of the current index into the arry used in
                    # struct for each class.

 '%StructFields';   # A hash of refs to arrays which store the names of
                    # the struct fields for a given class

sub ima_method_maker { 1 };

sub set_target_class {
  my ($class, $target) = @_;
  $TargetClass = $target;
}

sub get_target_class {
  my ($class) = @_;
  $TargetClass || $class->find_target_class;
}

sub find_target_class {
  # Find the class to add the methods to. I'm assuming that it would be
  # the first class in the caller() stack that's not a subsclass of
  # MethodMaker. If for some reason a sub-class of MethodMaker also
  # wanted to use MethodMaker it could redefine ima_method_maker to
  # return a false value and then $class would be set to it.
  my $class;
  my $i = 0;
  while (1) {
    $class = (caller($i))[0];
    $class->isa('Class::MethodMaker') or last;
    $i++;
  }
  $TargetClass = $class;
}

sub import {
  my ($class, @args) = @_;

  # Set a bit of syntactic sugar if desired which allows us to say things
  # like:
  #
  #   make methods
  #     get_set => [ qw / foo bar baz / ],
  #     list    => [ qw / a b c / ];

  if (defined $args[0] and $args[0] eq '-sugar') {
    shift @args;
    *methods:: = *Class::MethodMaker::;
  }
  
  @args and $class->make(@args);
}

sub make {
  my ($method_maker_class, @args) = @_;

  $method_maker_class->find_target_class; # sets $TargetClass

  # We have to initialize these before we run any of the
  # meta-methods. (At least the anon lists, so they get captured properly
  # in the closures.
  $BooleanPos{$TargetClass} ||= 0;
  $BooleanFields{$TargetClass} ||= [];
  $StructPos{$TargetClass} ||= 0;
  $StructFields{$TargetClass} ||= [];
  
  # make generic methods. The list passed to import should alternate
  # between the names of the meta-method to call to generate the methods
  # and either a scalar arg or a ARRAY ref to a list of args.

  # Each meta-method is responsible for calling install_methods() to get
  # it's methods installed.
  my ($meta_method, $arg);
  while (1) {
    $meta_method = shift @args or last;
    $arg = shift @args or
      croak "No arg for $meta_method in import of $method_maker_class.\n";

    my @args = ref($arg) ? @$arg : ($arg);
    $method_maker_class->$meta_method(@args);
  }
}

sub install_methods {
  my ($class, %methods) = @_;

  no strict 'refs';
#  print STDERR "CLASS: $class\n";
  $TargetClass || $class->find_target_class;
  my $package = $TargetClass . "::";
  
  my ($name, $code);
  while (($name, $code) = each %methods) {
    # add the method unless it's already defined (which should only
    # happen in the case of static methods, I think.)
    
    *{"$package$name"} = $code unless defined *{"$package$name"}{CODE};
  }
}


## GENERIC METHODS ##


sub new {
  my ($class, @args) = @_;
  my %methods;
  foreach (@args) {
    $methods{$_} = sub {
      my ($class) = @_;
      my $self = {};
      bless $self, $class;
    };
  }
  $class->install_methods(%methods);
}


sub new_with_init {
  my ($class, @args) = @_;
  my %methods;
  foreach (@args) {
    my $field = $_;
    $methods{$field} = sub {
      my ($class, @args) = @_;
      my $self = {};
      bless $self, $class;
      $self->init(@args);
      $self;
    };
  }
  $class->install_methods(%methods);
}


sub new_hash_init {
  my ($class, @args) = @_;
  my %methods;
  foreach (@args) {
    $methods{$_} = sub {
      my ($class, %args) = @_;
      my $self = ref($class) ? $class : bless {}, $class;

      foreach (keys %args) {
	$self->$_($args{$_});
      }
      $self;
    };
  }
  $class->install_methods(%methods);
}


sub get_set {
  my ($class, @args) = @_;
  my %methods;
  foreach (@args) {
    my $name = $_;
    $methods{$name} = sub {
      my ($self, $new) = @_;
      defined $new and $self->{$name} = $new;
      $self->{$name};
    };
     
    $methods{"clear_$name"} = sub {
      my ($self) = @_;
      $self->{$name} = undef;
    };
  }
  $class->install_methods(%methods);
}


sub get_concat {
  my ($class, @args) = @_;
  my %methods;
  foreach (@args) {
    my $name = $_;
    $methods{$name} = sub {
      my ($self, $new) = @_;
      $self->{$name} ||= "";
      defined $new and $self->{$name} .= $new;
      $self->{$name};
    };

    $methods{"clear_$name"} = sub {
      my ($self) = @_;
      $self->{$name} = undef;
    };
  }
  $class->install_methods(%methods);
}


sub grouped_fields {
  my ($class, %args) = @_;
  my %methods;
  foreach (keys %args) {
    my @slots = @{$args{$_}};
    $class->get_set(@slots);
    $methods{$_} = sub { @slots };
  }
  $class->install_methods(%methods);
}


sub object {
  my ($class, @args) = @_;
  my %methods;

  while (@args) {
    my $class = shift @args;
    my $list = shift @args or die "No slot names for $class";
    my @list;

    my $ref = ref $list;
    if ($ref eq 'HASH') {
      my $name = $list->{'slot'};
      my $composites =  $list->{'forward'} || $list->{'comp_mthds'};
      @list = ($name);
      my @composites = ref($composites) eq 'ARRAY'
	? @$composites : ($composites);
      my $meth;
      foreach $meth (@composites) {
	$methods{$meth} =
	  sub {
	    my ($self, @args) = @_;
	    $self->$name()->$meth(@args);
	  };
      }
    } else {
      @list = ref($list) eq 'ARRAY' ? @$list : ($list);
    }

    foreach (@list) {
      my $name = $_;
      my $type = $class; # Hmmm. We have to do this for the closure to
                         # work. I.e. using $class in the closure dosen't
                         # work. Someday I'll actually understand scoping
                         # in Perl. [ Uh, is this true? 11/11/96 -PBS ]
      $methods{$name} = sub {
	my ($self, @args) = @_;
	if (ref $args[0] eq $class) { # This is sub-optimal. We should
                                      # really use isa from UNIVERSAL.pm
                                      # to catch sub-classes too.
	  $self->{$name} = $args[0];
	} else {
	  defined $self->{$name} or $self->{$name} = $type->new(@args);
	}
	$self->{$name};
      };

      $methods{"delete_$name"} = sub {
	my ($self) = @_;
	$self->{$name} = undef;
      };
    }
  }
  $class = $class; # Huh? Without this line the next line doesn't work!
  $class->install_methods(%methods);
}

sub forward {
  my ($class, %args) = @_;
  my %methods;

  foreach (keys %args) {
    my $slot = $_;
    my @methods = @{$args{$_}};
    foreach (@methods) {
      my $field = $_;
      $methods{$field} = sub {
	my ($self, @args) = @_;
	$self->$slot()->$field(@args);
      };
    }
  }
  $class->install_methods(%methods);
}



sub boolean {
  my ($class, @args) = @_;
  my %methods;

  my $TargetClass = $class->get_target_class;

  my $boolean_fields =
    $BooleanFields{$TargetClass};

  $methods{'bits'} =
    sub {
      my ($self, $new) = @_;
      defined $new and $self->{'boolean'} = $new;
      $self->{'boolean'};
    };
  
  $methods{'bit_fields'} = sub { @$boolean_fields; };

  $methods{'bit_dump'} =
    sub {
      my ($self) = @_;
      map { ($_, $self->$_()) } @$boolean_fields;
    };
  
  foreach (@args) {
    my $field = $_;
    my $bfp = $BooleanPos{$TargetClass}++;
        # $boolean_pos a global declared at top of file. We need to make
        # a local copy because it will be captured in the closure and if
        # we capture the global version the changes to it will effect all
        # the closures. (Note also that it's value is reset with each
        # call to import_into_class.)
    push @$boolean_fields, $field;
        # $boolean_fields is also declared up above. It is used to store a
        # list of the names of all the bit fields.

    $methods{$field} =
      sub {
	my ($self, $on_off) = @_;
	defined $self->{'boolean'} or $self->{'boolean'} = "";
	if (defined $on_off) {
	  vec($self->{'boolean'}, $bfp, 1) = $on_off ? 1 : 0;
	}
	vec($self->{'boolean'}, $bfp, 1);
      };

    $methods{"set_$field"} =
      sub {
	my ($self) = @_;
	$self->$field(1);
      };

    $methods{"clear_$field"} =
      sub {
	my ($self) = @_;
	$self->$field(0);
      };
  }
  $class->install_methods(%methods);
}


sub struct {
  my ($class, @args) = @_;
  my %methods;

  $class->get_target_class;

  my $struct_fields =
    $StructFields{$TargetClass};

  $methods{'struct_fields'} = sub { @$struct_fields; };

  $methods{'struct'} =
    sub {
      # For filling up the whole structure at once. The values must be
      # provided in the order they were declared.
      my ($self, @values) = @_;
      defined $self->{'struct'} or $self->{'struct'} = [];
      @values and @{$self->{'struct'}} = @values;
      @{$self->{'struct'}};
    };
  
  $methods{'struct_dump'} =
    sub {
      my ($self) = @_;
      map { ($_, $self->$_()) } @$struct_fields;
    };
  
  foreach (@args) {
    my $field = $_;
    my $sfp = $StructPos{$TargetClass}++;
        # $struct_pos a global declared at top of file. We need to make
        # a local copy because it will be captured in the closure and if
        # we capture the global version the changes to it will effect all
        # the closures. (Note also that its value is reset with each
        # call to import_into_class.)
    push @$struct_fields, $field;
        # $struct_fields is also declared up above. It is used to store a
        # list of the names of all the struct fields.

    $methods{$field} =
      sub {
	my ($self, $new) = @_;
	defined $self->{'struct'} or $self->{'struct'} = [];
	defined $new and $self->{'struct'}->[$sfp] = $new;
	$self->{'struct'}->[$sfp];
      };

    $methods{"clear_$field"} =
      sub {
	my ($self) = @_;
	defined $self->{'struct'} or $self->{'struct'} = [];
	$self->{'struct'}->[$sfp] = undef;
      };
  }
  $class->install_methods(%methods);
}



sub listed_attrib {
  my ($class, @args) = @_;
  my %methods;

  foreach (@args) {
    my $field = $_;

    my %list = ();

    $methods{$field} =
      sub {
	my ($self, $on_off) = @_;
	if (defined $on_off) {
	  if ($on_off) {
	    $list{$self} = $self;
	  } else {
	    delete $list{$self};
	  }
	}
	$list{$self} ? 1 : 0;
      };

    $methods{"set_$field"} =
      sub {
	my ($self) = @_;
	$self->$field(1);
      };

    $methods{"clear_$field"} =
      sub {
	my ($self) = @_;
	$self->$field(0);
      };
    
    $methods{$field . "_objects"} =
      sub {
	values %list;
      };
  }
  $class->install_methods(%methods);
}


sub key_attrib {
  my ($class, @args) = @_;
  my %methods;

  foreach (@args) {
    my $field = $_;
    my %list = ();

    $methods{$field} =
      sub {
	my ($self, $new) = @_;
	if (defined $new) {
	  # We need to set the value
	  if (defined $self->{$field}) {
	    # the object must be in the hash under its old value so
	    # that entry needs to be deleted
	    delete $list{$self->{$field}};
	  }
	  my $old;
	  if ($old = $list{$new}) {
	    # There's already an object stored under that value so we
	    # need to unset it's value
	    $old->{$field} = undef;
	  }

	  # Set our value to new
	  $self->{$field} = $new;

	  # Put ourself in the list under that value
	  $list{$new} = $self;
	}
	$self->{$field};
      };

    $methods{"clear_$field"} =
      sub {
	my ($self) = @_;
	delete $list{$self->{$field}};
	$self->{$field} = undef;
      };
    
    $methods{"find_$field"} =
      sub {
	my ($self, @args) = @_;
	if (scalar @args) {
	  return @list{@args};
	} else {
	  return \%list;
	}
      };
  }
  $class->install_methods(%methods);
}


sub key_with_create {
  my ($class, @args) = @_;
  my %methods;

  foreach (@args) {
    my $field = $_;
    my %list = ();

    $methods{$field} =
      sub {
	my ($self, $new) = @_;
	if (defined $new) {
	  # We need to set the value
	  if (defined $self->{$field}) {
	    # the object must be in the hash under its old value so
	    # that entry needs to be deleted
	    delete $list{$self->{$field}};
	  }
	  my $old;
	  if ($old = $list{$new}) {
	    # There's already an object stored under that value so we
	    # need to unset it's value
	    $old->{$field} = undef;
	  }

	  # Set our value to new
	  $self->{$field} = $new;

	  # Put ourself in the list under that value
	  $list{$new} = $self;
	}
	$self->{$field};
      };
    
    $methods{"clear_$field"} =
      sub {
	my ($self) = @_;
	delete $list{$self->{$field}};
	$self->{$field} = undef;
      };
    
    $methods{"find_$field"} =
      sub {
	my ($class, @args) = @_;
	if (scalar @args) {
	  foreach (@args) {
	    $class->new->$field($_) unless defined $list{$_};
	  }
	  return @list{@args};
	} else {
	  return \%list;
	}
      };
  }
  $class->install_methods(%methods);
}


sub list {
  my ($class, @args) = @_;
  my %methods;
  
  foreach (@args) {
    my $field = $_;

    $methods{$field} =
      sub {
	my ($self, @list) = @_;
	defined $self->{$field} or $self->{$field} = [];
	push @{$self->{$field}}, map { ref $_ eq 'ARRAY' ? @$_ : ($_) } @list;
	@{$self->{$field}}; # no it's not. That was exposing the
                            # implementation, plus you couldn't say
                            # scalar $obj->field to get the number of
                            # items in it.
      };

    $methods{"pop_$field"} =
      sub {
	my ($self) = @_;
	pop @{$self->{$field}}
      };

    $methods{"push_$field"} =
      sub {
	my ($self, @values) = @_;
	push @{$self->{$field}}, @values;
      };

    $methods{"shift_$field"} =
      sub {
	my ($self) = @_;
	shift @{$self->{$field}}
      };

    $methods{"unshift_$field"} =
      sub {
	my ($self, @values) = @_;
	unshift @{$self->{$field}}, @values;
      };

    $methods{"splice_$field"} =
      sub {
	my ($self, $offset, $len, @list) = @_;
	splice(@{$self->{$field}}, $offset, $len, @list);
      };

    $methods{"clear_$field"} =
      sub {
	my ($self) = @_;
	$self->{$field} = [];
      };

    $methods{"$ {field}_ref"} =
      sub {
	my ($self) = @_;
	$self->{$field};
      };
  }
  $class->install_methods(%methods);
}


sub hash {
  my ($class, @args) = @_;
  my %methods;

  foreach (@args) {
    my $field = $_;

    $methods{$field} =
      sub {
	my ($self, @list) = @_;
	defined $self->{$field} or $self->{$field} = {};
	if (scalar @list == 1) {
	  my $key = shift @list;
	  if (ref $key) { # had better by an array ref
	    return @{$self->{$field}}{@$key};
	  } else {
	    return $self->{$field}->{$key};
	  }
	} else {
	  while (1) {
	    my $key = shift @list;
	    defined $key or last;
	    my $value = shift @list;
	    defined $value or carp "No value for key $key.";
	    $self->{$field}->{$key} = $value;
	  }
	  wantarray ? %{$self->{$field}} : $self->{$field};
	}
      };

    $methods{"$ {field}s"} = $methods{$field};

    $methods{$field . "_keys"} =
      sub {
	my ($self) = @_;
	keys %{$self->{$field}};
      };
    
    $methods{$field . "_values"} =
      sub {
	my ($self) = @_;
	values %{$self->{$field}};
      };

    $methods{$field . "_tally"} =
      sub {
	my ($self, @list) = @_;
	defined $self->{$field} or $self->{$field} = {};
	map { ++$self->{$field}->{$_} } @list;
      };

    $methods{"add_$field"} =
      sub {
	my ($self, $attrib, $value) = @_;
	$self->{$field}->{$attrib} = $value;
      };

    $methods{"clear_$field"} =
      sub {
	my ($self, $attrib) = @_;
	delete $ {$self->{$field}}{$attrib};
      };

    $methods{"add_$ {field}s"} =
      sub {
	my ($self, %attribs) = @_;
	my ($k, $v);
	while (($k, $v) = each %attribs) {
	  $self->{$field}->{$k} = $v;
	}
      };

    $methods{"clear_$ {field}s"} =
      sub {
	my ($self, @attribs) = @_;
	my $attrib;
	foreach $attrib (@attribs) {
	  delete $ {$self->{$field}}{$attrib};
	}
      };
  }
  $class->install_methods(%methods);
}

sub static_hash {
  my ($class, @args) = @_;
  my %methods;

  foreach (@args) {
    my $field = $_;
    my %hash;

    $methods{$field} =
      sub {
	my ($self, @list) = @_;
	if (scalar @list == 1) {
	  my $key = shift @list;
	  if (ref $key) { # had better by an array ref
	    return @hash{@$key};
	  } else {
	    return $hash{$key};
	  }
	} else {
	  while (1) {
	    my $key = shift @list;
	    defined $key or last;
	    my $value = shift @list;
	    defined $value or carp "No value for key $key.";
	    $hash{$key} = $value;
	  }
	  %hash;
	}
      };

    $methods{"$ {field}s"} = $methods{$field};

    $methods{$field . "_keys"} =
      sub {
	my ($self) = @_;
	keys %hash;
      };
    
    $methods{$field . "_values"} =
      sub {
	my ($self) = @_;
	values %hash;
      };

    $methods{$field . "_tally"} =
      sub {
	my ($self, @list) = @_;
	defined $self->{$field} or $self->{$field} = {};
	map { ++$hash{$_} } @list;
      };

    $methods{"add_$field"} =
      sub {
	my ($self, $attrib, $value) = @_;
	$hash{$attrib} = $value;
      };

    $methods{"clear_$field"} =
      sub {
	my ($self, $attrib) = @_;
	delete $hash{$attrib};
      };

    $methods{"add_$ {field}s"} =
      sub {
	my ($self, %attribs) = @_;
	my ($k, $v);
	while (($k, $v) = each %attribs) {
	  $hash{$k} = $v;
	}
      };

    $methods{"clear_$ {field}s"} =
      sub {
	my ($self, @attribs) = @_;
	my $attrib;
	foreach $attrib (@attribs) {
	  delete $hash{$attrib};
	}
      };
  }
  $class->install_methods(%methods);
}


sub code {
  my ($class, @args) = @_;
  my %methods;
  
  foreach (@args) {
    my $field = $_;
    
    $methods{$field} = sub {
      my ($self, @args) = @_;
      if (ref($args[0]) eq 'CODE') {
	# Set the function
	$self->{$field} = $args[0];
      } else {
	# Run the function on the given arguments
	&{$self->{$field}}(@args)
      }
    };
  }
  $class->install_methods(%methods);
}


sub method {
  my ($class, @args) = @_;
  my %methods;

  foreach (@args) {
    my $field = $_;

    $methods{$field} = sub {
      my ($self, @args) = @_;
      if (ref($args[0]) eq 'CODE') {
	# Set the function
	$self->{$field} = $args[0];
      } else {
	# Run the function on the given arguments
	&{$self->{$field}}($self, @args)
      }
    };
  }
  $class->install_methods(%methods);
}


sub abstract {
  my ($class, @args) = @_;
  my %methods;
  
  $class->get_target_class;

  foreach (@args) {
    my $field = $_;
    $methods{$field} = sub {
      my ($self) = @_;
      my $calling_class = ref $self;
      die
	qq#Can't locate abstract method "$field" declared in #.
	qq#"$TargetClass", called from "$calling_class".\n#;
    };
  }
  $class->install_methods(%methods);
}



## EXPERIMENTAL META-METHODS

sub builtin_class {
  my ($class, $func, $arg) = @_;
  my @list = @$arg;
  my %results = ();
  my $field;
  
  $class->get_target_class;

  my $struct_fields =
    $StructFields{$TargetClass};

  # Cuz neither \&{"CORE::$func"} or $CORE::{$func} work ...  N.B. this
  # only works for core functions that take only one arg. But I can't
  # quite figure out how to pass in the list without it getting evaluated
  # in a scalar context. Hmmm.
  my $corefunc = eval "sub { scalar \@_ ? CORE::$func(shift) : CORE::$func }";

  $results{'new'} = sub {
    my ($class, @args) = @_;
    my $self = [];
    @$self = &$corefunc(@args);
    bless $self, $class;
  };

  $results{'fields'} = sub { @$struct_fields; };

  $results{'dump'} =
    sub {
      my ($self) = @_;
      map { ($_, $self->$_()) } @$struct_fields;
    };
  
  foreach $field (@list) {
    my $sfp = $StructPos{$TargetClass}++;
        # $struct_pos a global declared at top of file. We need to make
        # a local copy because it will be captured in the closure and if
        # we capture the global version the changes to it will effect all
        # the closures. (Note also that its value is reset with each
        # call to import_into_class.)
    push @$struct_fields, $field;
        # $struct_fields is also declared up above. It is used to store a
        # list of the names of all the struct fields.

    $results{$field} =
      sub {
	my ($self, $new) = @_;
	defined $new and $self->[$sfp] = $new;
	$self->[$sfp];
      };
  }
  $class->install_methods(%results);
}

sub method_maker {
  # This is crazy!!!
  my ($class, %args) = @_;
  my %methods;
  $class->set_target_class(caller);

  foreach (keys %args) {
    my $field = $_;
    my $sub = $args{$_};
    $methods{$field} = sub {
      my ($c, @a) = @_;
      my %m;

      foreach (@a) {
	my $f = $_;
	$m{$f} = $sub;
      }
      $c->install_methods(%m);
    }
  }
  $class->install_methods(%methods);
  $class->set_target_class(undef);
}

1;


};
Class::MethodMaker->import();
}

@Class::MethodMakerExtentions::ISA = qw ( Class::MethodMaker );

# $package->import( no_op => [ qw / foo bar baz / ] )
sub no_op {
  my ($class, @args) = @_;
  my %methods;
  foreach (@args) {
    $methods{ $_ } = sub { };
  }
  $class->install_methods(%methods);
}

# $package->import( determine_once => [ qw / foo bar baz / ] );
sub determine_once {
  my ($class, @args) = @_;
  my %methods;
  foreach (@args) {
    my $name = $_;
    my $determiner = 'determine_' . $name ;
    my $TargetClass = $class->get_target_class;
    $methods{$name} = sub {
      my ($self) = @_;
      $self->{$name} = $self->$determiner() unless ( exists $self->{$name} );
      $self->{$name};
    };
    $methods{$determiner} = sub {
      die "Can't locate abstract method 'determine_$name', " . 
	  "required for $TargetClass, called from " . ref(shift) .".\n";
    };
    $methods{"clear_$name"} = sub {
      my ($self) = @_;
      delete $self->{$name};
    };
  }
  $class->install_methods(%methods);
}

# $package->import( lookup => [ 'price' => 'item_type' ] );
sub lookup {
  my ($class, @args) = @_;
  my %methods;
  while (@args) {
    my $name = shift @args;
    my $index = shift @args or die "No index for $name";
    my $TargetClass = $class->get_target_class;
    my $LookupTable = eval '\%' . $TargetClass . '::Lookup_' . $index;
    $methods{$name} = sub {
      my $self = shift;
      $LookupTable->{ $self->$index() }{ $name };
    };
    $methods{"set_$name"} = sub {
      my $self = shift;
      $LookupTable->{ $self->$index() }{ $name } = shift;
    };
  }
  $class->install_methods(%methods);
}

1;


};
Class::MethodMakerExtentions->import(( new_with_init => 'new_from_ua', new_hash_init => 'new', get_set => [ qw( ua id version flavor os spoof ) ], list => 'proxies', lookup => [ 'title'=>'id', 'frames'=>'id_v', 'java'=>'id_v', 'javascript'=>'id_v' ] ));
}

# $browser->init( $user_agent_string );
sub init {
  my $browser = shift;
  my $ua = shift;
  
  while ( $ua =~ s/\Wvia\W(.*?)(?=$|\Wvia\W)// ) {
    $browser->push_proxies( $1 );
  }
  
  if ( $ua =~ s/^Mozilla\/(\d)\.\d+\s\((?:compatible\;\s|not really)// ) {
    $browser->spoof('NS' . $1);
  }
    
  if ( $ua =~ /^Mozilla\/(\d+\.\d+)/ ) {
    # Netscape
    $browser->id('NS');
    $browser->version( $1 );
    if ( int($browser->version) == 4 ) {
      $browser->flavor('communicator') unless $ua =~ /\;\s*Nav\)/;
    } elsif ( int($browser->version) == 3 ) {
      $browser->flavor( $1 ) if $ua =~ /\W(Gold|WorldNet)\W(\d)/;
    }
    $ua =~ /\((\w+)\;/;
    if ( $1 eq 'Win95' or $1 eq 'WinNT' ) {
      $browser->os('Win32') 
    } elsif ( $1 eq 'Win16' ) {
      $browser->os('MSDOS') 
    } elsif ( $1 eq 'Macintosh' ) {
      $browser->os('MacOS') 
    } elsif ( $1 eq 'OS/2' ) {
      $browser->os('OS/2') 
    } elsif ( $1 eq 'X11' ) {
      $browser->os('Unix') 
    }
  } elsif ( $ua =~ /^MSIE\s(\d+\.\d+)/ ) {
    # Microsoft Internet Explorer
    $browser->id('IE');
    $browser->version( $1 );
    $browser->flavor( $1 . $2 ) if $ua =~ /\W(MSN|AOL)\W(\d)/;
    $browser->flavor( $1 ) if $ua =~ /\W(ZDNet|Gateway2000)\W/;
    if ( $ua =~ /\WWindows\W(?:\d\d|NT)/ ) {
      $browser->os('Win32') 
    } elsif ( $ua =~ /\WWindows\W3/ ) {
      $browser->os('MSDOS') 
    } elsif ( $ua =~ /\WMac_(?:68K|PPC|P\w+?PC)/ ) {
      $browser->os('MacOS') 
    }
  } elsif ( $ua =~ /^AOL\D+?(\d+\.\d+)/ ) {
    # Opera
    $browser->id('AOL');
    $browser->version( $1 );
    $browser->os( $ua =~ /\WWindows\W3/ ? 'MSDOS' : 'Win32' ) 
  } elsif ( $ua =~ /^Opera\/(\d+\.\d+)/ ) {
    # Opera
    $browser->id('O');
    $browser->version( $1 );
    $browser->os( $ua =~ /\WWindows\W3/ ? 'MSDOS' : 'Win32' ) 
  } elsif ( $ua =~ /^Lynx\/(\d+\.\d+)/ ) {
    # Lynx
    $browser->id('L');
    $browser->version( $1 );
    $browser->os('Unix') 
  } elsif ( $ua =~ /^OmniWeb\/(\d+\.\d+)/ ) {
    # Omniweb
    $browser->id('OW');
    $browser->version( $1 );
    $browser->os('Unix') 
  } else {
    $browser->ua( $ua );
  }
}

# $id_v = $browser->id_v;
sub id_v {
  my $self = shift;
  ($self->id ? $self->id : '') . ($self->version ? int( $self->version ) : '');
}

%Lookup_id = (
  'M' => {
    'title' => 'NCSA Mosaic',
  },
  'NS' => {
    'title' => 'Netscape Navigator',
  },
  'IE' => {
    'title' => 'Microsoft Internet Explorer',
  },
  'O' => {
    'title' => 'Opera',
  },
  'L' => {
    'title' => 'Lynx',
  },
  'OW' => {
    'title' => 'OmniWeb',
  },
);

%Lookup_id_v = (
  'M1' => {
  },
  'M2' => {
  },
  'M3' => {
  },
  'NS1' => {
  },
  'NS2' => {
    'javascript' => 1.0,
  },
  'NS3' => {
    'frames' => 1,
    'javascript' => 1.1,
    'java' => 1,
    'multipart-forms' => 1,
  },
  'NS4' => {
    'frames' => 1,
    'javascript' => 1.2,
    'java' => 1,
    'multipart-forms' => 1,
  },
  'IE1' => {
  },
  'IE2' => {
  },
  'IE3' => {
    'frames' => 1,
    'javascript' => 1.05,
    'java' => 1,
    #!# Requires update -- currently undetected
    'multipart-forms' => 1,
  },
  'IE4' => {
    'frames' => 1,
    'javascript' => 1.1,
    'java' => 1,
    'multipart-forms' => 1,
  },
  'O1' => {
  },
  'OW1' => {
  },
  'OW2' => {
    'javascript' => 0,
  },
  'OW3' => {
    'javascript' => 0,
  },
);

1;


};
WebApp::Browser->import();
}

BEGIN { 
Script::HTML::Escape->import(qw( url_escape ));
}
BEGIN { 
$INC{'File::Name'} = 'lib/File/Name.pm';
eval {
### The File::Name class provides file path objects and related operations.
  # Primarily an OOP wrapper for functionality from FileHandle, Basename, Cwd.

### Caveats and Things To Do
  # - Simple_wildcard_to_regex is pretty general purpose; maybe split it out,
  # or use one of the pre-existing modules (KGlobRE?) to do the same thing.
  # - Perhaps re-export the Fcntl O_ constants.

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # This is free software; you can use it under the same terms as Perl itself.
  # Portions based on File::PathConvert, (c) 1996, 1997, 1998 Shigio Yamaguchi.
  # Temp directory logic based on CGI.pm. Copyright 1995-1997 Lincoln D. Stein.

### Change History
  # 1998-06-12 Added new_typed_filled_temp method. -Simon
  # 1998-06-04 Added Temp subclass; it's only concrete method is a DESTROY that
  #            ensures the underlying file, if it still exists, is deleted when
  #            the filename goes out of scope.  Typical usage would be to bless
  #            an existing File::Name object into File::Name::Temp. -Del
  # 1998-05-29 Added append and text_lines methods.
  # 1998-05-07 Added temp_dir and new_temp methods.
  # 1998-04-22 Added non-binmode *_text_* and low-level sys_* methods.
  # 1998-04-13 Made use of binmode universal; commented out sysread/write code
  # 1998-04-06 Added explicit import from Data::DRef. -Simon
  # 1998-04-02 Use sysread/syswrite in place of read/print (performance). 
  # 1998-03-31 Added binmode logic. 
  # 1998-03-31 Corrected test in ensure_is_dir(); corrected move_to_dir. -Del
  # 1998-03-26 Added O_TRUNC to the open_writer FileHandle/Fcntl mode.
  # 1998-03-20 Added descendents method.
  # 1998-02-26 Mucked with permits method.
  # 1998-02-25 Added absolute and make_absolute methods.
  # 1998-02-22 Worked on relatives; split out File::SystemType package. -Simon
  # 1998-02-?? Added create_path, can_create_path, other functions. -Jeremy
  # 1998-02-01 Added ext_for_mediatype.
  # 1998-01-26 Added move_to_dir and ensure_is_dir method for directories.
  # 1998-01-21 Switched to Fcntl constants for FileHandle open modes.
  # 1998-01-21 Instruct File::Basename to use MSDOS rules when we're on Win32.
  # 1997-12-15 Added preliminary unique_variation method.
  # 1997-12-02 Added base_name.
  # 1997-10-06 Created File::Name package based on version 3 of Evo::file.
  # 1997-09-25 Minor change to regularize warning
  # 1997-08-08 Working on regularize to handling differing dirseps.
  # 1997-08-07 Forced immediate close on filehandles in getFile.
  # 1997-08-03 Argh! More binmode madness.
  # 1997-03-23 Improved exception handling.
  # 1997-03-** Minor updates.
  # 1997-01-13 Created Evo::file module. -Simon

package File::Name;

use vars qw( $VERSION );
$VERSION = 1.00_03;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( filename current_directory );

use Carp;

use Fcntl;
use FileHandle;
use Cwd;
use File::Basename;
fileparse_set_fstype('MSDOS') if ( $^O =~ /Win32/ );

BEGIN { 
$INC{'File::SystemType'} = 'lib/File/SystemType.pm';
eval {
### File::SystemType provides information about the local file system

### Interface
  # $fsys_type = file_system_type;
  # $character = directory_separator;
  # $character = discover_directory_separator;
  # %directory_separators = ( 'fsys_type' => 'sep_character' );

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # This is free software; you can use it under the same terms as Perl itself.

### Change History
  # 1998-02-22 Split from File::Name. -Simon

package File::SystemType;

# $fsys_type = File::Name->file_system_type;
  # Returns MacOS, MSDOS, Win32, VMS, or Unix 
sub file_system_type {
  my $fsys_type = 'Unix';
  
  if ( $^O =~ /Win32/ ) {
    $fsys_type = 'Win32';
    # It seems that Netscape switches the separator before invoking CGI scripts
    $fsys_type = 'Unix' if ( $ENV{'SERVER_SOFTWARE'} =~ /[Nn]etscape/ );
  } elsif ( $^O =~ /MSDOS/ ) {
    $fsys_type = 'MSDOS';
  } elsif ( $^O =~ /VMS/ ) {
    $fsys_type = 'VMS';
  } elsif ( $^O =~ /MacOS/ ) {
    $fsys_type = 'MacOS';
  }
  
  return $fsys_type;
}

use vars qw( $directory_separator %directory_separators );

# $character = File::SystemType->directory_separator;
sub directory_separator {
  return $directory_separator ||= discover_directory_separator();
}

# $character = discover_directory_separator();
sub discover_directory_separator {
  my $fsys_type = file_system_type;
  
  # Maybe this should produce an error?
  return '/' unless ( exists $directory_separators{ $fsys_type } );
  return $directory_separators{ $fsys_type };
}

# %directory_separators = ( 'fsys_type' => 'sep_character' );
%directory_separators = (
  'MSDOS' => '\\',
  'Win32' => '\\',
  'MacOS' => ':',
  'VMS' => '/',		# Colon? Angle brace? Anyone? Beuler?
  'Unix' => '/',
);

1;


};
File::SystemType->import();
}
use vars qw( $SL );
$SL = File::SystemType->directory_separator;

BEGIN { 
Data::DRef->import(qw( shiftdref ));
}
BEGIN { 
Err::Debug->import();
}

# $regex = simple_wildcard_to_regex( $simple_wildcard_with_stars );
  # Protect all meta characters, then convert * and ? to their Perl equivalents
sub simple_wildcard_to_regex {
  my $filemask = shift;
  $filemask = quotemeta ($filemask);
  $filemask =~ s/\\\*/\.\*/;
  $filemask =~ s/\\\?/\./;
  return $filemask;
}

### Instantiation

# $fn = filename($path);
sub filename ($) { File::Name->new(@_); }

# $fn = current_directory();
sub current_directory () { File::Name->current(); }

# $fn = File::Name->new( @path_name_elements ); 
  # pass series of relative path elements
sub new ($$) {
  my $referent = shift;
  my $class = ref $referent || $referent;
  
  my $path = '';
  my $fn = \$path;
  bless $fn, $class;
  
  my $base = shift;
  $fn->path( ref $base ? ($base)->path : $base );
  $fn->regularize();
  
  while ( scalar @_ ) {
    $fn = $fn->relative( shift );
  }
  
  return $fn;
}

# $fn = File::Name->current();
sub current ($) {
  my $class = shift;
  my $path = cwd;
  my $fn = \$path;
  bless $fn, $class;
}

# $fn_str = regularize( $fn_str );
sub regularize ($) {
  my $fn = shift;
  
  my $fn_str = $fn->path;
  
  my $original = $fn_str;
  
  # forward and back slashes forced to local dialect
  $fn_str =~ s/[\/\\]/$SL/g;
  
  # initial /../  -> /
  $fn_str =~ s/\A\Q$SL\E\.\.\Q$SL\E/$SL/g;
  
  # initial /./   -> /
  $fn_str =~ s/\A\Q$SL\E\.\Q$SL\E/$SL/g;
  
  # multiple ///  -> /
  $fn_str =~ s/(?:\Q$SL\E)+/$SL/g;
  
  # dirname/../    -> removed
  $fn_str =~ s/(\Q$SL\E|\A)[^\Q$SL\E]+\Q$SL\E\.\.(\Q$SL\E|\Z)/$1/g;
  
  # 1998-03-05 This is a bit of a beast. Must avoid discarding '../..' paths.
  #!!!# Not sure why /g isn't enough, but multiple uses are needed.
  # do { $_ = ($fn_str =~ s/(\Q$SL\E|\A)(?:[^\.\Q$S\E]|[^\.\Q$S\E][^\Q$S\E]|[^\Q$S\E][^\.\Q$S\E])[^\Q$SL\E]*\Q$SL\E\.\.(\Q$SL\E|\Z)/$1/g) } while ( $_ );
  
  # trailing /.    -> /
  $fn_str =~ s/\Q$SL\E\.\Z/$SL/;
  
  # trailing /    -> removed
  $fn_str =~ s/(.)\Q$SL\E\Z/$1/;
  
  unless ($original eq $fn_str) {
    debug 'filename', "Regularized filename", $original;
    debug 'filename', "         name is now", $fn_str;
  }
  
  $fn->path( $fn_str );
}

### Relatives

# $fn = $root_fn->relative( $partial_path );
sub relative($;$) {
  my $fn = shift;
  my $offset = File::Name->new( shift );
  return $offset if $offset->is_absolute;
  return $fn->new( $fn->path . $SL . $offset->path );
}

# $flag = $fn->is_absolute();
sub is_absolute {
  my $fn = shift;
  my $fs_type = File::SystemType::file_system_type;  
  if ( $fs_type eq 'Win32' or $fs_type eq 'MSDOS' ) {
    return 1 if ( $fn->path =~ /\A(\w\:)?[\/\\]/ );
  } else {
    return 1 if ( $fn->path =~ /\A\// );
  }
  return 0;
}

# $absolute_fn = $fn->absolute;
sub absolute {
  my $fn = shift;
  return $fn if $fn->is_absolute;
  File::Name->current->relative( $fn );
}

# $fn->make_absolute;
  # Against current directory.
sub make_absolute {
  my $fn = shift;
  return if $fn->is_absolute;
  $fn->path( cwd() . $SL . $fn->path );
  $fn->regularize();
}

### Path and Name

# $fn->path($path);
# $path = $fn->path; 
sub path {
  my $fn = shift;
  $$fn = shift if ( scalar @_ );
  carp "path is empty" unless (defined $$fn and length $$fn);
  return $$fn;
}

# $name = $fn->name;
sub name {
  my $fn = shift;
  my ($name, $parent) = fileparse($fn->path);
  return $name;
}

# $name = $fn->base_name;
sub base_name {
  my $fn = shift;
  my ($name, $parent) = (fileparse($fn->path, '\\.\\w+'))[0];
  return $name;
}

# $flag = $fn->hasextension( $extn );
sub hasextension {
  my $fn = shift;
  my $ext = shift;
  my ($name, $parent, $match) = fileparse($fn->path, "(?i)\\.\Q$ext\E");
  return length($match) ? 1 : 0;
}

# $extension = $fn->extension;
sub extension {
  my $fn = shift;
  my ($name, $parent, $ext) = fileparse($fn->path, '\\.\\w+');
  $ext =~ s/\A\.//; # or die "what happened to the period?";
  return $ext;
}

# $similar_but_nonexistant_fn = $fn->unique_variation;
sub unique_variation {
  my $fn = shift;
  
  my $candidate = $fn->new( $fn->path );
  my ($name, $parent, $extention) = (fileparse($fn->path, '\\.\\w+'));
  my $base = $parent . $name;
  my $n = 0;
  while ( ++ $n < 1000 ) {
    return $candidate unless $candidate->exists;
    #!# We should really fileparse(), then reassemble "$name\.$n\.$ext"
    $$candidate = $base . '.' . $n . $extention;
  }
  die "couldn't produce a unique variation on " . $fn->path . 
  	", there must be a thousand of them!\n";
}

### Permissions; Updates

# $fn->permits( $permission_bits );	Dies if chmod doesn't succeed
sub permits {
  my $fn = shift;
  my $perms = shift;
  
  croak "file permits called without argument" unless (defined $perms);
  $fn->must_exist;
  
  chmod( $perms, $fn->path )
    or croak "can't set permissions for " . $fn->path;
}

# $fn->delete();
sub delete {
  my $fn = shift;
  return unless $fn->exists();
  if ( $fn->isdir() ) {
    my $child;
    foreach $child ( $fn->children() ) { $child->delete() }
    rmdir $fn->path or die "Can't remove dir '" . $fn->path . "': $_";
  } else {
    unlink $fn->path or die "Can't unlink file '" . $fn->path . "': $_";
  }
  return;
}

### Directories

# $parent_fn = $fn->parent;
sub parent {
  my $fn = shift;
  my $dirname = dirname( $fn->path );
  return $fn->new($dirname);
}

# $child_fn = $fn->child( $name );
sub child {
  my $fn = shift;
  $fn->must_be_dir;
  File::Name->new( $fn->path, shift );
}

# @children = $fn->children;
# @children = $fn->children( $simple_name_regex )
sub children {
  my $fn = shift;
  my $wildcard = shift || '';
  my $regex = (length $wildcard) ? simple_wildcard_to_regex($wildcard) : '';
  
  $fn->must_be_dir;
  wantarray or die "can't call children in a scalar context";
  
  my $path = $fn->path;
  unless ( opendir(DIR, $path) ) {
    warn "Couldn't read files from $path\n";
    return;
  }
  my(@filenames) = readdir(DIR);  closedir(DIR);  
  # Skip . and .. entries
  @filenames = grep { $_ !~ /\A\.\.?\Z/ } @filenames;  
  # Only get matching files
  @filenames = grep( /\A${regex}\Z/i, @filenames) if (length $regex);  
  return map { $fn->child($_) } @filenames;
}

# @directories = $fn->sub_directories;
sub sub_directories {
  my $fn = shift;
  grep { $_->isdir } $fn->children;
}

# @offspring = $fn->descendents;
# @offspring = $fn->descendents( $simple_name_regex )
sub descendents {
  my $fn = shift;
  my $wildcard = shift || '';
  
  return ( 
    $fn->children( $wildcard ), 
    map { $_->descendents($wildcard) } $fn->sub_directories 
  );
}

# $fn->ensure_is_dir			Dies if directory can't be created
sub ensure_is_dir {
  my $fn = shift;
  return if $fn->exists;
  
  mkdir($fn->path, 0777) or die "can't make dir '" . $fn->path . "'\n";
  $fn->permits( 0777 );
}

# $fn->create_path()			Dies if path can't be created
# $fn->create_path( $permission_bits )
sub create_path {
  my ($fn, $perms) = @_;
  
  unless ( $fn->exists() ) {
    until ( $fn->parent->exists() ) { $fn->parent->create_path( $perms ); }
    mkdir( $fn->path, $perms ) or die "can't make dir " . $fn->path . "\n";
    $fn->permits( $perms || 0777 );
  }
  
  return;
}

# $flag = $fn->can_create_path()
sub can_create_path {
  my $fn = shift;
  return $fn->exists ? $fn->writable : $fn->parent->can_create_path;
}

# $fn->move_to_dir( @fn );
sub move_to_dir {
  my $fn = shift;
  $fn->ensure_is_dir;
  my $file;
  foreach $file ( @_ ) {
    rename( $file->path, $fn->relative($file->name)->path ) 
      or die "Couldn't move " . $file->path . " into " .  $fn->path . "\n"; 
  }
  return;
}

### Types and Info

# $flag = $fn->exists();
sub exists {
  my $fn = shift;
  return ( -e $fn->path ) ? 1 : 0;
}

# $fn->must_exist();   				exception unless exists
sub must_exist {
  my $fn = shift;
  $fn->exists() or die "required file '" . $fn->path . "' doesn't exist\n";
  return;
}

# $flag = $fn->isdir();
sub isdir {
  my $fn = shift;
  return ( -d $fn->path ) ? 1 : 0;
}

# $fn->must_be_dir(); 				exception unless isdir
sub must_be_dir {
  my $fn = shift;
  $fn->exists() or die "required directory '".$fn->path."' doesn't exist\n";
  $fn->isdir() or die "required file '".$fn->path."' exists but is not a directory as it should be\n";
  return;
}

# $bytecount = $fn->size();
sub size {
  my $fn = shift;
  return -s $fn->path;
}

# $flag = $fn->readable();
sub readable {
  my $fn = shift;
  return -r $fn->path;
}

# $flag = $fn->writable();
sub writable {
  my $fn = shift;
  return -w $fn->path;
}

# $days = $fn->age_since_change();
sub age_since_change {
  my $fn = shift;
  return -M $fn->path;
}

### Contents and FileHandles 

# $fh = $fn->open_reader();
sub open_reader ($) {
  my $fn = shift;
  my $fh = FileHandle->new( $fn->path, O_RDONLY );
  binmode($fh) if ($fh); 
  return $fh;
}

# $fh = $fn->open_writer();
sub open_writer ($) {
  my $fn = shift;
  my $fh = FileHandle->new( $fn->path, O_CREAT|O_WRONLY|O_TRUNC );
  binmode($fh) if ($fh); 
  return $fh;
}

# $fh = $fn->open_appender();
sub open_appender ($) {
  my $fn = shift;
  my $fh = FileHandle->new( $fn->path, O_CREAT|O_WRONLY|O_APPEND );
  binmode($fh) if ($fh); 
  return $fh;
}

# $fh = $fn->reader(); 
sub reader ($) {
  my $fn = shift;
  my $fh = $fn->open_reader();
  die "couldn't open reader for " . $fn->path . "\n" unless ($fh);
  return $fh;
}

# $fh = $fn->writer(); 
sub writer ($) {
  my $fn = shift;
  my $fh = $fn->open_writer();
  die "couldn't open writer for " . $fn->path . "\n" unless ($fh);
  return $fh;
}

# $fh = $fn->appender(); 
sub appender ($) {
  my $fn = shift;
  my $fh = $fn->open_appender();
  die "couldn't open writer for " . $fn->path . "\n" unless ($fh);
  return $fh;
}

# $contents = $fn->get_contents();
sub get_contents {
  my $fn = shift;
  my $data = '';
  my $length = read($fn->reader(), $data, $fn->size );
  return $data;
}

# $fn->set_contents($contents);
  # Leaves the contents at $_[0] to avoid copying them.
sub set_contents {
  my $fn = shift;
  $fn->writer()->print($_[0]);
  return;
}

# $contents = $fn->sys_get_contents();
sub sys_get_contents {
  my $fn = shift;
  
  my $fh = $fn->reader();
  
  my $data = '';
  my $offset = 0;
  my $blocksize = $fn->size;
  
  my $count;
  do {
    $count = sysread($fh, $data, $blocksize, $offset);
    die "Reading $$fn interupted: $!\n" unless (defined $count);
    $offset += $count;
  } until ( ! $count );
  
  return $data;
}

# $fn->sys_set_contents($contents);
sub sys_set_contents {
  my $fn = shift;
  
  my $fh = $fn->writer();
  
  my $len = length($_[0]);
  my $offset = 0;
  while ( $len ) {
    my $count = syswrite( $fh, $_[0], $len, $offset );
    die "Writing $$fn interupted: $!\n" unless (defined $count);
    $len -= $count;
    $offset += $count;
  }
  
  return;
}

### Text Contents and FileHandles

# $fh = $fn->open_text_reader();
sub open_text_reader ($) {
  my $fn = shift;
  my $fh = FileHandle->new( $fn->path, O_RDONLY );
  return $fh;
}

# $fh = $fn->open_text_writer();
sub open_text_writer ($) {
  my $fn = shift;
  my $fh = FileHandle->new( $fn->path, O_CREAT|O_WRONLY|O_TRUNC );
  return $fh;
}

# $fh = $fn->open_text_appender();
sub open_text_appender ($) {
  my $fn = shift;
  my $fh = FileHandle->new( $fn->path, O_CREAT|O_WRONLY|O_APPEND );
  return $fh;
}

# $fh = $fn->text_reader(); 
sub text_reader ($) {
  my $fn = shift;
  my $fh = $fn->open_text_reader();
  die "couldn't open text reader for " . $fn->path . "\n" unless ($fh);
  return $fh;
}

# $fh = $fn->text_writer(); 
sub text_writer ($) {
  my $fn = shift;
  my $fh = $fn->open_text_writer();
  die "couldn't open text writer for " . $fn->path . "\n" unless ($fh);
  return $fh;
}

# $fh = $fn->text_appender(); 
sub text_appender ($) {
  my $fn = shift;
  my $fh = $fn->open_text_appender();
  die "couldn't open text writer for " . $fn->path . "\n" unless ($fh);
  return $fh;
}

# $contents = $fn->get_text_contents();
sub get_text_contents {
  my $fn = shift;
  my $data = '';
  my $length = read( $fn->text_reader(), $data, $fn->size );
  return $data;
}

# $fn->set_text_contents($contents);
sub set_text_contents {
  my $fn = shift;
  $fn->text_writer()->print( $_[0] );
  return;
}

# $fn->append_text($contents);
sub append_text {
  my $fn = shift;
  $fn->text_appender()->print( $_[0] );
  return;
}

# @lines = $fn->get_text_lines();
sub get_text_lines {
  my $fn = shift;
  my $fh = $fn->text_reader();
  return (<$fh>);
}

# $fn->set_text_lines( @lines );
sub set_text_lines {
  my $fn = shift;
  $fn->set_text_contents(join('', map { $_, "\n" }  @_));
}

# $fn->append_text_lines( @lines );
sub append_text_lines {
  my $fn = shift;
  $fn->append_text(join('', map { $_, "\n" }  @_));
}

### Media Type

use vars qw( %media_type_map );
%media_type_map = (
  'doc' => 'application/msword',
  'ppt' => 'application/vnd.ms-powerpoint',
  'xls' => 'application/vnd.ms-excel',
  'jpg' => 'image/jpeg',
  'gif' => 'image/gif',
  'bmp' => 'image/bmp',
  'zip' => 'application/zip',
  '123' => 'application/vnd.lotus-1-2-3',
  'pre' => 'application/vnd.lotus-freelance',
  'htm' => 'text/html',
  'html' => 'text/html',
  'txt' => 'text/plain',
  'pdf' => 'application/pdf',
  'rtf' => 'application/rtf',
);

# $mediatype = $fn->media_type() 
  # Currently, we just guess this based on the file extension.
sub media_type {
  my $fn = shift;
  type_for_filename( $fn->name );
}

# $mediatype = type_for_filename( $filename );
sub type_for_filename {
  my $filename = shift;
  my $ext = ( $filename =~ /\.(\w{2,7})$/ )[0];
  return $media_type_map{ lc($ext) }
}

# $extension = ext_for_type( $mediatype );
sub ext_for_type {  
  my $expr = lc( shift );
  foreach ( keys %media_type_map ) {
    return $_ if ( $media_type_map{ $_ } eq $expr );
  }
}

# $filename = typed_filename($filename, $mediatype);
sub typed_filename {
  my ($filename, $mediatype) = @_;
  
  unless ( type_for_filename($filename) eq lc($mediatype) ) {
    my $extn = ext_for_type( $mediatype );
    $filename .= '.' . $extn if $extn;
  }
  
  return $filename;
}

### Temp Files

use vars qw( $TempDirectory @TempDirCandidates );
@TempDirCandidates = ('/usr/tmp', '/var/tmp', '/tmp', '/temp', '/Temporary Items', '.');

# $tmp_dir_fn = File::Name->temp_dir;
sub temp_dir {
  my $package = shift;
  unless ( $TempDirectory ) {
    foreach ( @TempDirCandidates ) {
      my $fn = $package->new( $_ );
      next unless ( $fn->isdir and $fn->writable );
      $TempDirectory = $fn;
      return $TempDirectory;
    }
    die "Couldn't find a writable temp directory\n" unless ( $TempDirectory );
  }
  return $TempDirectory;
}

# $tmp_fn = File::Name->new_temp( $filename );
sub new_temp {
  my ($package, $filename) = @_;
  my ($base, $parent) = fileparse($filename);
  return $package->temp_dir->child( $base )->unique_variation;
}

### DRef Interface

# $value = $fn->get($dref);
sub get ($$) {
  my $fn = shift;
  my $dref = shift;
  
  my $key = shiftdref($dref);
  
  my %methods = (
    'contents' => 'get_contents',
    'lastmod' => 'age_since_change',
    'size' => 'size',
    'path' => 'path',
    'name' => 'name',
    'extension' => 'extension',
    'media_type' => 'media_type',
  );
  my $method = $methods{$key};
  
  return $fn->$method() if ( length $method );
  
  # should add navigation to parent, children.
  
  die "unsupported key '$key' in get from filename\n";
}

# $fn->set($dref, $value);
sub set {
  my ($fn, $dref, $value) = @_;
  
  if ( $dref eq 'contents' ) {
    $fn->set_contents($value);
  } else {
    die "unsupported dref '$dref' in set on filename\n";
  }
}

### Debugging

# $fn->check_state($context_name);
sub check_state {
  my $fn = shift;
  my $description = shift || 'File' ;
  
  my $info = $description . " path: '" . $fn->path . "'";
  $info .= " (non-existant)" unless ( $fn->exists() );
  $info .= "\n";
  $info .= "  Directory '" . $fn->parent->path() . "'\n";
  
  warn $info;
}

package File::Name::Temp;	# This type of file deletes itself.  Cool.

@File::Name::Temp::ISA = qw( File::Name );

# $fn = File::Name::Temp->new_typed_filled_temp($name, $type, $contents);
sub new_typed_filled_temp {
  my $package = shift;
  my $fn = File::Name->new_temp( File::Name::typed_filename(shift, shift) );
  $fn->set_contents( @_ );
  bless $fn, $package;
}

sub DESTROY {
  my $fn = shift;
  Err::Debug::debug ('File::Name::Temp', 'Destroying/Deleting', $fn) if $fn->exists;
  $fn->delete;
}

1;


};
File::Name->import();
}

use vars qw( $DefaultMediaType $GenericMediaType );
$DefaultMediaType = 'text/html';
$GenericMediaType = 'application/octet-stream';

# WebApp::Request->startup() 				// NO-OP
sub startup { return }

# WebApp::Request->at_end() 				// NO-OP
sub at_end { return }

### Receving Requests

# $request = WebApp::Request->new;
sub new {
  my $class = shift;
  
  return unless $class->request_available;
  
  my $request = { };
  bless $request, $class;	
  
  $request->init();
  $request->get_request_info();
  
  return $request;
}

# $flag = WebApp::Request->request_available()		// ABSTRACT
sub request_available { croak "abstract request_available called on $_[0]"; }

# $request->init;
sub init {
  my $request = shift;
  $request->{'response_headers'} = {
    'content-type'=>$DefaultMediaType, 
    'pragma'=>'no-cache',
    # 'expires' => 0,		# equivalent to no-cache?
  };
  return;
}

# $request->set_browser_from_ua( $user_agent_string );
sub set_browser_from_ua {
  my $request = shift;
  my $ua = shift;
  $request->{'client'}{'browser'} = $ua;
  $request->{'browser'} = WebApp::Browser->new_from_ua( $ua );
  $request->{'client'}{'browser_id_v'} = $request->{'browser'}->id_v;
  debug 'request', "Browser is:", $request->{'browser'}->id_v;
}

# $browser = $request->browser;
sub browser {
  my $request = shift;
  $request->{'browser'};
}

# $request->get_request_info;
sub get_request_info {
  my $request = shift;
  
  $request->{'timestamp'} = time;
  $request->read_headers;
  $request->read_arg_data;
  $request->parse_arg_data;
  
  debug 'request-verbose', "CGI Request is:", $request;
  
  return $request; 
}

# $request->read_headers;				// ABSTRACT
sub read_headers { croak "abstract read_headers called on $_[0]"; }

# $request->read_arg_data;				// ABSTRACT
sub read_arg_data { croak "abstract read_arg_data called on $_[0]"; }

# $request->set_method_and_type( $method, $content_type );
sub set_method_and_type {
  my $request = shift;
  
  $request->{'method'} = shift || 'GET';
  $request->{'content_type'} = shift || 'application/x-www-form-urlencoded';
  
  # Patch for IE3, which doesn't clear content_type when it gets a redirect.
  if ( $request->{'method'} eq 'GET' and 
  	$request->{'content_type'} =~ /multipart\/form-data/ ) {
    $request->{'content_type'} = 'application/x-www-form-urlencoded';
    debug 'request', 'Overriding bogus multipart encoding for GET request.';
  }
}

# $request->parse_arg_data;
sub parse_arg_data {
  my $request = shift;
  
  # Hash to store the parsed version of the arguments.
  $request->{'args'} = {};
  
  warn "content type $request->{'content_type'}\n";
  if ($request->{'content_type'} =~ /multipart\/form-data/) {
    debug 'request', "Parsing multipart request arguments";
    my $boundary = '--'.( $request->{'content_type'} =~ /boundary=(.*)$/ )[0];
    $request->parse_multipart_args($boundary);
  } else {
    # application/x-www-form-urlencoded
    debug 'request', "Parsing request arguments";
    $request->parse_urlencoded_args;
  }
  delete $request->{'data'};
  
  debug 'request', "Done parsing request arguments";
  return;
}

# $request->parse_urlencoded_args;
sub parse_urlencoded_args {
  my $request = shift;
  debug 'request-args-verbose', "URL-encoded data is:", $request->{'data'};
  foreach ( split(/[&;]/, $request->{'data'}) ) {
    $_ =~ s/\+/ /g;
    my($key, $val) = split(/=/, $_, 2); 
    next unless ( defined $key and length $key );
    $key =~ s/%([\dA-Fa-f]{2})/chr(hex($1))/ge;
    $val =~ s/%([\dA-Fa-f]{2})/chr(hex($1))/ge if ( defined $val );
    $request->add_argument($key, $val);
  }
}

# $request->parse_multipart_args( $boundary );
  # BOUNDARY
  # HEADERS
  # 
  # OPAQUE-DATA
  # BOUNDARY
  # HEADERS
  # 
  # OPAQUE-DATA
  # BOUNDARY--
  
sub parse_multipart_args {
  my ($request, $boundary) = @_;
  
  debug 'request-args', 'Multipart argument data is', 
	  length($request->{'data'}), 'bytes', 'separated by', $boundary;
  debug 'request-args-verbose', "Multipart content:", $request->{'data'};
  
  my $boundary_length = length($boundary);
  my ($pos, $index) = (0, 0);
  
  while ( 1 ) {
    # Advance position to after the end of the boundary and CRLF
    $pos += $boundary_length + 2;
    
    # Check if we're on the last boundary, with its '--' ending.
    last if substr($request->{'data'}, $pos -2, 4) eq "--\015\012";
    
    # Extract header information
    my %header;
    while ( 1 ) {
      # Look for the next line; if none, we're done.
      $index = index($request->{'data'}, "\015\012", $pos);
      croak "can't find end of header line\n" if ($index == -1);
      
      # Extract the header line and move postion indicator to the end of it.
      my $header = substr($request->{'data'}, $pos, $index - $pos);
      $pos = $index + 2;
      
      # If the line is blank, we're at the end of the header section.
      last if ( $header eq '' );
      
      # Parse the header; force names lowercase for consistency
      my ($name, $value) = split(': ', $header, 2);
      $header{ lc($name) } = $value;
    }
    
    # Determine the argument name
    my $arg_name = ($header{'content-disposition'} =~ / name="([^"]*)"/)[0];
    warn "multipart arg received without name.\n" unless ( length $arg_name );
    
    # Look for the next CRLF-boundary line.
    $index = index($request->{'data'}, "\015\012" . $boundary, $pos);
    croak "can't find end of multipart argument data\n" if ($index == -1);
    
    # Extract the data and move position indicator to start of next boundary.
    my $data = substr($request->{'data'}, $pos, $index - $pos );
    $pos = $index + 2;
    
    # Check if the value is being sent as a file upload. If it is, save it
    # into a temp file and use that File::Name object as the argument value.
    if ($header{'content-disposition'} =~ / filename="(.+)"/) {
      my $filename = $1;
      $data = File::Name::Temp->new_typed_filled_temp($filename, 
      					$header{'content-type'}, $data);
      # I'm not 100% sold on this original_name mechanism... -Simon
      $request->add_argument($arg_name.'_original_name', $filename);
    }
    
    $request->add_argument($arg_name, $data);
  }
}

# $request->add_argument($key, $val);
  # if we get the same argument more than once, we make an array of 'em.
sub add_argument {
  my($request, $key, $val) = @_;
  
  debug 'request-args-verbose', "Argument", $key, "Value", $val;
  
  my $current = getDRef($request->{'args'}, $key);
  if ( ! defined $current ) {
    setDRef($request->{'args'}, $key, $val);
  } elsif ( ref $current eq 'ARRAY' ) {
    push @$current, $val;
  } else {
    debug 'request-args-verbose', 'Building array of arguments named', $key;
    setDRef($request->{'args'}, $key, [ $current, $val ] );
  }
}

# $url = $request->repeat_url;
sub repeat_url {
  my $request = shift;
  $request->{'site'}{'url'} . $request->{'links'}{'script'} . 
    $request->{'path'}{'info'} . '?' . $request->query_string;
}

# $query_string = $request->query_string;
sub query_string {
  my $request = shift;
  query_string_from_args( $request->{'args'} );
}

# $query_string = query_string_from_args( $args );
sub query_string_from_args {
  my $args = shift;
  
  my @args;
  
  debug 'qs_from_args', 'source:', $args;
  
  #!# Algorithm needs to be modified to properly encode arrays of scalars
  # as a sequence of arguments with the same name, rather than name.0, name.1.
  
  my $key;
  foreach $key ( scalarkeysof( $args ) ) {
    my $val = getDRef($args, $key);
    if ( ref($val) ) {
      debug 'qs_from_args', 'empty item', $key, '=', $val;
      next;
    }
    my $arg = url_escape($key);
    $arg .= '=' . url_escape($val) if (defined $val);
    push (@args, $arg);
  }
  debug 'qs_from_args', 'args:', @args;
  
  my $qstr = join('&', @args);
  debug 'qs_from_args', 'string:', $qstr;
  
  return $qstr;
}

### Responding to Requests

# $request->reply( $page_or_file );
sub reply {
  my $request = shift;
  # Maybe support nph operation -- send "HTTP/1.0 200 OK" status line first?
  $request->{'response_headers'}{'content-length'} = length( $_[0] );
  $request->send_reply( $_[0] );
  ++ $request->{'has_replied'};
}

# $request->send_reply( $content );  			// ABSTRACT
sub send_reply { croak "abstract send_reply called on $_[0]"; }

# $request->done_with_request;  			// NO-OP
sub done_with_request { return }

# $request->send_file( $fn );
sub send_file {
  my $request = shift;
  my $fn = File::Name->new( shift(@_) );
  
  my $headers = $request->{'response_headers'};
  delete $headers->{'pragma'};	# Pragma: no-cache isn't desirable here
  $headers->{'content-type'} = $fn->media_type || $GenericMediaType;
  $headers->{'content-disposition'} = "attachment; filename=" . $fn->name 
  		    if ($headers->{'content-type'} eq $GenericMediaType);
  
  $request->reply( $fn->get_contents );
}

# $request->redirect( $location );
sub redirect {
  my $request = shift;
  my $location = shift;
  
  $request->{'response_headers'}{'content-type'} = 'text/html';
  $request->{'response_headers'}{'location'} = $location;
  
  $request->reply( "<a href=$location>Click here for your document.</a>" );
}

# $request->redirect_and_end( $url );
sub redirect_and_end {
  my $request = shift;
  my $url = shift;
  $request->redirect( $url );
  die "redirected\n";
}

# $request->redirect_via_refresh( $location );
  # Send an HTML page with a refresh 
sub redirect_via_refresh {
  my $request = shift;
  my $location = shift;
  
  $request->{'response_headers'}{'content-type'} = 'text/html';
  
  $location = html_escape( $location );
  
  $request->reply( "<meta http-equiv=refresh content=\"0;url=$location\">" . 
		   "<a href=$location>Click here for your document.</a>"   );
}

1;


};
WebApp::Request->import();
}
@WebApp::Request::CGI::ISA = qw( WebApp::Request );

require 5.000;

BEGIN { 
Err::Debug->import();
}
BEGIN { 
Script::HTML::Escape->import();
}

### Receving Requests

use vars qw( $Counter );

# $flag = WebApp::Request::CGI->request_available()
sub request_available { ! ( $Counter++ ) }

# $req->read_headers;
sub read_headers {
  my $req = shift;
  
  # Request Data						# CGI 1.1
  $req->set_method_and_type( $ENV{'REQUEST_METHOD'}, $ENV{'CONTENT_TYPE'} );
  
  # Referenced File						# CGI 1.1
  $req->{'path'}{'info'} = $ENV{'PATH_INFO'} || '';
  $req->{'path'}{'names'} = [ split(/\//, $req->{'path'}{'info'}) ];
  shift @{$req->{'path'}{'names'}};
  $req->{'path'}{'filename'} = $ENV{'PATH_TRANSLATED'} || '';
  
  # Current Script					 	# CGI 1.1
  $req->{'links'}{'script'} = $ENV{'SCRIPT_NAME'} || '';
  
  # IIS/NT sets path_info to links.script if it was otherwise empty 
  if ($req->{'path'}{'info'} eq $req->{'links'}{'script'}) {
    $req->{'path'}{'info'} = $req->{'file'}{'filename'} = '';
  }
  
  # IIS + SP3 adds SCRIPT_NAME to PATH_INFO and PATH_TRANSLATED
  # This may be fixed with the .dll's that ship with IE4.0
  if ($req->{'path'}{'info'} ne $req->{'links'}{'script'}) {
    $req->{'path'}{'info'} =~ s/\A\Q$req->{'links'}{'script'}\E//;
    $req->{'path'}{'filename'} =~ s/\A\Q$req->{'links'}{'script'}\E//;
  }
  
  # Netscape/NT puts a trailing slash on script_url if file_url ends with one
  $req->{'links'}{'script'} =~ s/[\/\\]\Z//;
  
  # Web Server Software						# CGI 1.1
  $req->{'web_server'}{'httpds'} = 
			[ split(/\s+/, ($ENV{'SERVER_SOFTWARE'} || '')) ];
  $req->{'web_server'}{'gateways'} = 
			[ split(/\//, ($ENV{'GATEWAY_INTERFACE'} || '')) ];
  $req->{'web_server'}{'protocols'} = 
			[ split(/\//, ($ENV{'SERVER_PROTOCOL'} || '')) ];
  $req->{'web_server'}{'secure'} = ( $ENV{'SERVER_PORT_SECURE'} or 
			  $ENV{'HTTPS'} && $ENV{'HTTPS'} =~ /on/i or
			  $req->{'web_server'}{'protocols'}[0] =~ /https/i);
  
  # Web Site							# CGI 1.1
  $req->{'site'}{'addr'} = $ENV{'SERVER_NAME'} || 'localhost';
  $req->{'site'}{'port'} = $ENV{'SERVER_PORT'} || 80;
  if ( $req->{'web_server'}{'secure'} ) {
    $req->{'site'}{'url'} = 'https://' . $req->{'site'}{'addr'} . 
      ($req->{'site'}{'port'} == 443  ? '' : ':'.$req->{'site'}{'port'});
  } else {
    $req->{'site'}{'url'} = 'http://' . $req->{'site'}{'addr'} . 
      ($req->{'site'}{'port'} == 80  ? '' : ':'.$req->{'site'}{'port'});
  }
  
  $req->{'site'}{'path'} = $ENV{'DOCUMENT_ROOT'} || '';		# Apache
  
  # User Authentication						# CGI 1.1
  $req->{'user'}{'authtype'} = $ENV{'AUTH_TYPE'} || 'none';
  $req->{'user'}{'login'} = $ENV{'REMOTE_USER'} || '';
  if ( $ENV{'REMOTE_IDENT'} and ! $req->{'user'}{'login'} ) {
    $req->{'user'}{'authtype'} = 'ident';
    $req->{'user'}{'login'} = $ENV{'REMOTE_IDENT'} || '';	# Not used much
  }
  
  # Client Information						# CGI 1.1
  $req->{'client'}{'hostname'} = $ENV{'REMOTE_HOST'} || '';
  $req->{'client'}{'ipaddr'} = $ENV{'REMOTE_ADDR'} || '';
  $req->{'client'}{'addr'} = $ENV{'REMOTE_HOST'}||$ENV{'REMOTE_ADDR'}||'';
  
  # Browser Information						# HTTP 1.1
  $req->set_browser_from_ua( $ENV{'HTTP_USER_AGENT'} || '' );

  $req->{'client'}{'accepts'} = [ split(/,\s*/, ($ENV{'HTTP_ACCEPT'} || '')) ];
  
  # State Information						# HTTP 1.1
  $req->{'client'}{'cookies'} = [ split /\;\s*/, ($ENV{'HTTP_COOKIE'} || '') ];
  
  $req->{'links'}{'back'} = $ENV{'HTTP_REFERER'} || '';
  
  return;
} 

# $req->read_arg_data;
sub read_arg_data {
  my $req = shift;
  
  # Buffer to read argument data stream into
  $req->{'data'} = '';
  debug 'cgi', "Reading request arguments";
  if ($req->{'method'} eq 'GET') {
    $req->{'data'} = $ENV{'QUERY_STRING'} || '';
  } elsif ($req->{'method'} eq 'POST') {
    binmode STDIN;
    my $len = read(STDIN, $req->{'data'}, $ENV{'CONTENT_LENGTH'});
    debug 'cgi', "Read $len from stdin";
  } else {
    die "unknown CGI Request method '$req->{'method'}'";
  }
} 


### Responding to Requests

# $req->send_reply( $page_or_file );
sub send_reply {
  my $req = shift;
    
  binmode STDOUT;
  
  my $key;
  foreach $key (keys %{$req->{'response_headers'}} ) {
    print $key . ': ' . $req->{'response_headers'}{$key} . "\n";
  }
  
  print "\n", $_[0];
}



1;


};
WebApp::Request::CGI->import();
}

BEGIN { 
$INC{'WebApp::Handler::FileHandler'} = 'lib/WebApp/Handler/FileHandler.pm';
eval {
### A WebApp::FileHandler returns files requested in path info

### Interface
  # $rc = $handler->handle_request($request);
  # $flag = $handler->can_handle_file( $fn );
  # $handler->send_file( $request, $fn );

### Caveats and Things To Do
  # - Support configurable document root directory and virtual directories.

### Change History
  # 1998-03-02 Better subclass integration.
  # 1997-12-06 Made DirectoryHandler and ScriptHandler subclasses of this one.
  # 1997-11-04 Refactored with an eye towards adding a superclass
  # 1997-10-21 Started using File::Name and moved media-type detection to there 

package WebApp::Handler::FileHandler;

BEGIN { 
File::Name->import();
}

BEGIN { 
$INC{'WebApp::Handler'} = 'lib/WebApp/Handler.pm';
eval {
### WebApp::Handler provides a superclass for bundles of server functionality

### Change History
  # 1998-04-?? Doc added; init call moved to new; reference to server dropped.
  # 1998-02-04 Added shutdown method.
  # 1998-01-28 Added init method.
  # 1997-11-03 Added inline comments
  # 1997-10-** Created this package.

package WebApp::Handler;

$VERSION = 1.02_00;


### Instantiation

# $handler = WebApp::Handler::SUBCLASS->new();
sub new {
  my $class = shift;
  my $handler = { };
  bless $handler, $class;
  $handler->init;
  return $handler;
}

# WebApp::Handler::SUBCLASS->add_new( $server );
sub add_new {
  my $class = shift;
  my $server = shift;
  my $handler = $class->new;
  $server->add_handler( $handler );
}

### Subclass Hooks

# $handler->init();
sub init 		{    }

# $handler->startup();
# $handler->shutdown();
sub startup 		{    }
sub shutdown 		{    }

# $handler->starting_request( $request );
# $handler->done_with_request( $request );
sub starting_request	{    }
sub done_with_request	{    }

# $zero = $handler->handle_request( $request );
sub handle_request { return 0; }

1;


};
WebApp::Handler->import();
}
unshift @ISA, qw( WebApp::Handler );


# $rc = $handler->handle_request($request);
sub handle_request {
  my $handler = shift;
  my $request = shift;
  
  my $filepath = $handler->path_for_request($request) or return 0;
  
  my $fn = File::Name->new( $filepath );
  
  return 0 unless ( $fn->exists and $handler->can_handle_file( $fn ) );
  
  $handler->send_file( $request, $fn );
  
  return 1;
}

# $filepath = $handler->path_for_request($request);
sub path_for_request {
  my $handler = shift;
  my $request = shift;
  
  return $request->{'path'}{'filename'} || '';
}

# $flag = $handler->can_handle_file( $fn );
sub can_handle_file {
  my $handler = shift;
  my $fn = shift;
  return ( ! $fn->isdir );
}

# $handler->send_file( $request, $fn );
sub send_file {
  my $handler = shift;
  my $request = shift;
  my $fn = shift;
  
  $request->send_file( $fn );
}

1;
};
WebApp::Handler::FileHandler->import();
}
BEGIN { 
$INC{'WebApp::Handler::DirectoryHandler'} = 'lib/WebApp/Handler/DirectoryHandler.pm';
eval {
# Directory handler

### Interface
  # $flag = $handler->can_handle_file( $fn );
  # $reply = $handler->send_file( $fn );

### Change History
  # 1997-12-06 Made into a subclass of FileHandler.
  # 1997-11-04 Revised interface to match changes in FileHandler.
  # 1997-10-21 Created this handler. 

package WebApp::Handler::DirectoryHandler;

BEGIN { 
WebApp::Handler::FileHandler->import();
}
unshift @ISA, qw( WebApp::Handler::FileHandler );


# $flag = $handler->can_handle_file( $fn );
sub can_handle_file {
  my $handler = shift;
  my $fn = shift;
  return ( $fn->isdir );
}

# $reply = $handler->send_file( $request, $fn );
sub send_file {
  my $handler = shift;
  my $request = shift;
  my $fn = shift;
  
  my $message = "<html><head><title>Directory Listing</title></head>\n" . 
  		"<body bgcolor=white>\n" . 
  		"Directory information for " . $fn->path . "\n";
  
  my $child;
  foreach $child ( $fn->children ) {
    my $link = $child->name;
    $message .= "<br><a href=$link>" . $child->name . "</a>";
  }
  $message .= "</body></html>\n";
  
  $request->reply( $message );
}

1;
};
WebApp::Handler::DirectoryHandler->import();
}
BEGIN { 
$INC{'WebApp::Handler::ResourceHandler'} = 'lib/WebApp/Handler/ResourceHandler.pm';
eval {
### WebApp::ResourceHandler provides access to IntraNetics applications

### Interface
  # $rc = $handler->handle_request($request);

### Change History
  # 1998-04-28 Added empty-cache method on done_with_request.
  # 1998-01-02 Moved debug tracing code to logging handler.
  # 1997-11-04 Moved Resource functionality into new package.
  # 1997-11-01 Created.

package WebApp::Handler::ResourceHandler;

BEGIN { 
WebApp::Handler->import();
}
unshift @ISA, qw( WebApp::Handler );

BEGIN { 
Err::Debug->import();
}

BEGIN { 
File::Name->import();
}
BEGIN { 
$INC{'WebApp::Resource'} = 'lib/WebApp/Resource.pm';
eval {
### WebApp::Resource is the superclass for file-based application objects.

### Instantiation
  # $resource = WebApp::Resource::SUBCLASS->new;

### Request Handling
  # $rc = $site->handle_request( $request );		Abstract

### SearchPath By-Name Access
  # $resource = WebApp::Resource->new_from_full_name( $name_with_extension );
  # $resource = WebApp::Resource::SUBCLASS->new_from_name( $short_name );
  # @resources = WebApp::Resource->resources_by_type( $file_extension );
  # @resources = WebApp::Resource::SUBCLASS->resources();

### File I/O
  # $resource = WebApp::Resource->new_from_file( $filename );
  # $resource->load_from_file;
  # $resource->reload_if_needed;
  # $flag = $resource->disk_has_changed;
  # $resource->write_to_file;

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-05-07 Switched from (g|s)et_contents to (g|s)et_text_contents.
  # 1998-04-28 Added object_for_file with filename-based cache.
  # 1998-03-05 Set file info before read_source to allow init-time behaviour.
  # 1998-02-27 Added resources() method.
  # 1998-02-24 Fixed typo in error message.
  # 1998-01-16 Moved path-list management into new File::SearchPath package.
  # 1997-12-02 Overhaul of file-access methods; improved site path mapping.
  # 1997-11-05 Added site-specific path list.
  # 1997-11-04 Added new_from_name, new_from_file, add_path, path_list().
  # 1997-11-04 Refactored factory methods into SubclassFactory.pm.
  # 1997-11-03 Created.

package WebApp::Resource;

$VERSION = 1.02_00;

use Carp;
BEGIN { 
Err::Debug->import();
}

BEGIN { 
Class::NamedFactory->import();
}
push @ISA, qw( Class::NamedFactory );
use vars qw( %ResourceClasses );
sub subclasses_by_name { \%ResourceClasses; }

BEGIN { 
$INC{'File::SearchPath'} = 'lib/File/SearchPath.pm';
eval {
### File::SearchPath provides by-name file access across a group of directories
  # Two bonus packages, SearchPathSet and SearchPathProxy, are also included.

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-30 Changed add_paths() to avoid "Modification of a read-only value"
  # 1998-03-26 Inline POD added.
  # 1998-01-16 Created this package. -Simon

package File::SearchPath;

BEGIN { 
File::Name->import(qw( filename current_directory ));
}

BEGIN { 
Err::Debug->import();
}

### Instantiation

# $spath = File::SearchPath->new( @dir_filenames );
sub new {
  my $package = shift;
  
  my $spath = [];
  bless $spath, $package;
  debug('searchpath', "Creating SearchPath $spath");
  
  $spath->add_paths( @_ );
  
  return $spath;
}

sub DESTROY {
  debug('searchpath', "Destroying SearchPath $_[0]");
}

### Fetch/Store Dir path list

# $spath->add_paths( @dir_filenames );
sub add_paths {
  my $spath = shift;
  my @filenames = @_;
  my $fn;
  foreach $fn ( @filenames ) {
    debug 'searchpath', "Adding SearchPath files for $spath:", $fn;
    $fn = File::Name->current if ( $fn eq '.' );
    $fn = File::Name->new($fn) unless ( ref $fn );
    $fn->must_be_dir;
    unshift @$spath, $fn;
  }
}

# @paths = $spath->list_paths;
sub list_paths {
  my $spath = shift;
  return @$spath;
}

### Matching Files

# $file = $spath->file_by_name( $name );
sub file_by_name {
  my $spath = shift;
  my $name = shift;
  
  debug 'searchpath', "Looking for file named", $name;
  my $path;
  foreach $path ( $spath->list_paths ) {
    my $file = $path->child( $name );
    if ( $file->exists ) {
      debug 'searchpath', "Found file", $name, "in", $path->path;
      return $file;
    }
    debug 'searchpath', "Couldn't find file", $name, "in", $path->path;
  }
  debug 'searchpath', "Couldn't find file named", $name, "in search path";
  return 0;
}

# @files = $spath->all_files( $simple_wildcard_or_nothing );
sub all_files {
  my $spath = shift;
  my $pattern = shift;
  debug('searchpath', "Looking for file pattern", $pattern) if ( $pattern );
  
  my ( $file, %names, @results );
  my $path;
  foreach $path ( $spath->list_paths ) {
    debug 'searchpath', "Looking for files in", $path->path;
    foreach $file ( $path->children( $pattern ) ) {
      next if ( $names{ $file->name } ++ );
      push @results, $file;
    }
  }
  return @results;
}

### File::SearchPathSet provides a SearchPath interface for a set of SerchPaths

package File::SearchPathSet;

# $spathset = File::SearchPathSet->new( @dir_filenames );
sub new {
  my $package = shift;
  my $spathset = [];
  bless $spathset, $package;
  
  $spath->add_pathssets( @_ );
}

### Fetch/Store Dir path list

# $spathset->add_pathssets( @SearchPaths );
sub add_pathssets {
  my $spathset = shift;
  my $sp;
  foreach $sp ( @_ ) {
    unshift @$spathset, $sp;
  }
}

# $spathset->add_paths( @dir_filenames );
sub add_paths {
  my $spathset = shift;
  my $sp = ( $spathset->[0] ||= File::SearchPath->new );
  $sp->add_paths(@_);
}

# @paths = $spathset->list_paths;
sub list_paths {
  my $spathset = shift;
  my @paths;
  my $sp;
  foreach $sp ( @$spathset ) {
    push @paths, $sp->list_paths;
  }
  return @paths;
}

### Matching Files

# $file = $spathset->file_by_name( $name );
sub file_by_name {
  my $spathset = shift;
  my $name = shift;
  
  my $sp;
  foreach $sp ( @$spathset ) {
    my $fn = $sp->file_by_name( $name );
    return $fn if $fn;
  }
  return 0;
}

# @files = $spathset->all_files( $simple_wildcard );
sub all_files {
  my $spathset = shift;
  my $pattern = shift;
  
  my ( $file, %names, @results );
  my $sp;
  foreach $sp ( @$spathset ) {
    foreach $file ( $sp->all_files( $pattern ) ) {
      next if ( $names{ $file->name } ++ );
      push @results, $file;
    }
  }
  return @results;
}

### File::SearchPathProxy is a hash-based delegating proxy mixin class.

### Interface
  # $spath = $self->search_path;
  # Provides proxy methods that delegate to our private SearchPath

package File::SearchPathProxy;

# $spath = $self->search_path;
sub search_path  { (shift)->{'-search_path'} ||= File::SearchPath->new; }

# Provide proxy methods that delegate to our private SearchPath
sub add_paths    { (shift)->search_path->add_paths   ( @_ ); }
sub list_paths   { (shift)->search_path->list_paths  ( @_ ); }
sub file_by_name { (shift)->search_path->file_by_name( @_ ); }
sub all_files    { (shift)->search_path->all_files   ( @_ ); }

1;


};
File::SearchPath->import();
}
use vars qw( $SearchPath );
sub search_path { $SearchPath ||= File::SearchPath->new('.') }


### Instantiation

# $resource = WebApp::Resource::SUBCLASS->new;
sub new {
  my $package = shift;
  my $resource = {};
  bless $resource, $package;
  debug('resources', "Creating resource $resource");
  return $resource;
}

sub DESTROY {
  my $resource = shift;
  debug('resources', "Destroying resource $resource");
}

### Request Handling

# $rc = $site->handle_request( $request );		Abstract
sub handle_request { die "abstract method" }

### SearchPath By-Name Access

# $resource = WebApp::Resource->new_from_full_name( $name_with_extension );
sub new_from_full_name {
  my $package = shift;
  my $name = shift;
  debug('resources', 'Looking for resource named', $name);
  my $file = $package->search_path->file_by_name( $name );  
  return unless ( $file and $file->exists );
  $package->object_for_file( $file );
}

# $resource = WebApp::Resource::SUBCLASS->new_from_name( $short_name );
sub new_from_name {
  my $package = shift;
  WebApp::Resource->new_from_full_name($_[0] . '.' . $package->subclass_name); 
}

# @resources = WebApp::Resource->resources_by_type( $file_extension );
sub resources_by_type {
  my $package = shift;
  my $extension = shift;
  return map { $package->object_for_file($_) } 
		( $package->search_path->all_files("*.$extension") );
}

# @resources = WebApp::Resource::SUBCLASS->resources();
sub resources {
  my $package = shift;
  WebApp::Resource->resources_by_type($package->subclass_name); 
}

### File I/O

use vars qw( %Cache );

# WebApp::Resource->empty_cache
sub empty_cache { %Cache = (); }

# $resource = WebApp::Resource->object_for_file( $filename );
sub object_for_file {
  my $package = shift;
  my $fn = shift;
  
  if ( $Cache{ $$fn } ) {
    $Cache{ $$fn }->reload_if_needed;
  } else { 
    $Cache{ $$fn } = $package->new_from_file( $fn );
  }
  return $Cache{ $$fn };
}

# $resource = WebApp::Resource->new_from_file( $filename );
sub new_from_file {
  my $package = shift;
  my $fn = shift;
  
  debug 'resources', "Loading resource from" , $fn->path ;
  
  my $subclass = $package->subclass_by_name( $fn->extension ) 
	      or croak "Couldn't find Resource class to handle " . $fn->path;
  
  my $resource = $subclass->new;
  $resource->{'-filename'} = $fn;
  $resource->load_from_file;
  
  return $resource;
}

# $resource->load_from_file;
sub load_from_file {
  my $resource = shift;
  
  my $fn = $resource->{'-filename'};
  debug 'resources', 'loading resource', "$resource", 'from', $fn;
  
  $resource->{'-filename'} = $fn;
  $resource->{'-name'} = $fn->base_name;
  $resource->{'-loadage'} = $fn->age_since_change;
  
  $resource->read_source( $fn->get_text_contents );
}

# $resource->reload_if_needed;
sub reload_if_needed {
  my $resource = shift;
  if ( $resource->disk_has_changed ) {
    debug 'resources', 'reloading resource', "$resource";
    $resource->load_from_file;
  } else {
    debug 'resources', 'resource', "$resource", 'hasn\'t changed.';
  }
}

# $flag = $resource->disk_has_changed;
sub disk_has_changed {
  my $resource = shift;
  my $d = $resource->{'-loadage'} - $resource->{'-filename'}->age_since_change;
  debug 'resources', 'file changed', $d, 'days ago' if ( $d );
  return $d;
}

# $resource->write_to_file;
sub write_to_file {
  my $resource = shift;

  my $fn = $resource->{'-filename'};
  
  # 1998-01-19 When saving, sometimes the filename is just a string;
  #            not clear why, but for now, we'll rebless it if needed. -Simon
  $fn = File::Name->new( $fn ) if ( defined $fn and length $fn and ! ref $fn );
  
  # local $resource->{'-name'};
  # local $resource->{'-filename'};
  # local $resource->{'-loadage'};
  
  $fn->set_text_contents( $resource->write_source );
}

1;


};
WebApp::Resource->import();
}

# $rc = $handler->handle_request($request);
sub handle_request {
  my $handler = shift;
  my $request = shift;
  
  my $name = $request->{'path'}{'names'}[0];
  
  debug 'resource-handler', 'Checking for a resource named', $name;
  
  return 0 unless ( $name );
  my $resource = WebApp::Resource->new_from_full_name( $name );
  return 0 unless ( $resource );
  
  debug 'resource-handler', 'Delegating handle_request to', "$resource";
  
  $resource->handle_request( $request );
}

# $handler->done_with_request($request);
sub done_with_request {
  my $handler = shift;
  my $request = shift;
  
  debug 'resource-handler', 'Emptying resource cache';
  WebApp::Resource->empty_cache;
  
  return;
}

1;
};
WebApp::Handler::ResourceHandler->import();
}
BEGIN { 
$INC{'WebApp::Handler::LoggingHandler'} = 'lib/WebApp/Handler/LoggingHandler.pm';
eval {
### A WebApp::LoggingHandler manages server event and diagnostic logging.

### Interface
  # warn( $message );
  # $handler->startup();
  # $handler->starting_request($request);
  # $handler->got_request($request);
  # $zero = $handler->handle_request($request);
  # $handler->done_with_request($request);

### Caveats and Things To Do
  # - Provide a mechanism for temporarily setting Err::Debug::Level by passing
  # request argument, then replace the {'args'}{'debug'} code below with debug.

### Change History
  # 1998-04-02 Args are logged under "requestargs" instead of "request". -Del
  # 1998-03-02 Added request resolved-by logging.
  # 1998-01-29 Changed warns to debugs.
  # 1998-01-02 Moved uses of Err::WebLogFormat and Err::LogFile to WebApp.cgi
  # 1998-01-02 New logging output for request args debug=env, request, or data.
  # 1997-12-04 Added use of Err::LogFile::log_errors_to.
  # 1997-11-20 Added use of Err::WebLogFormat.
  # 1997-11-03 Cleaned up header
  # 1997-10-?? Four-oh fork. -Simon

package WebApp::Handler::LoggingHandler;

BEGIN { 
WebApp::Handler->import();
}
unshift @ISA, qw( WebApp::Handler );

use vars qw( $count $time_request );

BEGIN { 
Err::Debug->import();
}
BEGIN { 
Text::PropertyList->import(qw( astext ));
}

# $handler->startup();
sub startup {
  my $handler = shift;
  debug 'times', "- WebApp ready after ", (time - $main::Start), "second(s) starting up" if ($main::Start) ;
}

# $handler->starting_request($request);
sub starting_request {
  my $handler = shift;
  my $request = shift;
  
  $time_request = time();
  
  my $client = $ENV{REMOTE_HOST} || '';
  my $page = $ENV{PATH_INFO} || 'the home page';
  
  ++$count;
  warn "--- Request number $count, from $client for $page\n";
  
  my $val;
  
  debug 'request', "- Request is for", $request->{'file_url'};
  
  debug 'request', "- Request arguments are", $request->{'args'};
  
  debug 'request', "- Referred from", $val
				    if ($val = $request->{'referer'});
  
  warn "- Environment variables are " . astext( \%ENV ) 
    if ($request->{'args'}{'debug'} && $request->{'args'}{'debug'} =~ /env/i);
  			    
  warn "- Request structure is " . astext( $request ) 
    if ($request->{'args'}{'debug'} && $request->{'args'}{'debug'} =~ /req/i);
  
  return;
}

# $handler->done_with_request($request);
sub done_with_request {
  my $handler = shift;
  my $request = shift;
   
  my $elapsed = time - $time_request;
  if ($elapsed) {
    $elapsed .= ' second' . ($elapsed > 1 ? 's' :'');
  } else {
    $elapsed = 'under 1 second';
  }
  my $page = $ENV{PATH_INFO} || 'the home page';
  debug 'times', "- Completed $page in $elapsed";
  
  warn "- Post-request data structures are " . astext( $Data::DRef::Root ) 
    if ($request->{'args'}{'debug'} && $request->{'args'}{'debug'} =~ /data/i);
  
}

1;

};
WebApp::Handler::LoggingHandler->import();
}
BEGIN { 
$INC{'WebApp::Handler::Scripted'} = 'lib/WebApp/Handler/Scripted.pm';
eval {
### The Scripted Handler looks for scripts to run on notifications

### Interface
  # $handler->init();

### Change History
  # 1998-05-07 Switched from get_contents to get_text_contents.
  # 1998-03-21 Created. -Simon

package WebApp::Handler::Scripted;

BEGIN { 
WebApp::Handler->import();
}
unshift @ISA, qw( WebApp::Handler );

BEGIN { 
Err::Debug->import();
}

BEGIN { 
File::Name->import();
}
BEGIN { 
Script::Evaluate->import(qw( runscript ));
}

# $handler->init;
sub init {
  my $handler = shift;
  $handler->{'dir'} ||= File::Name->current;
}

# $handler->run_script_by_name( $script_name );
sub run_script_by_name {
  my $handler = shift;
  my $name = shift;
  
  my $config_file = $handler->{'dir'}->child("$name.script");
  runscript($config_file->get_text_contents) if $config_file->exists;
}

# $handler->startup;
sub startup {
  my $handler = shift;
  $handler->run_script_by_name( 'startup' );
}

# $handler->starting_request;
sub starting_request {
  my $handler = shift;
  $handler->run_script_by_name( 'before' );
}

# $handler->done_with_request;
sub done_with_request {
  my $handler = shift;
  $handler->run_script_by_name( 'after' );
}

# $handler->shutdown;
sub shutdown {
  my $handler = shift;
  $handler->run_script_by_name( 'shutdown' );
}

1;

};
WebApp::Handler::Scripted->import();
}
BEGIN { 
$INC{'WebApp::Handler::Plugins'} = 'lib/WebApp/Handler/Plugins.pm';
eval {
### The Plugins Handler looks for Perl Modules to load at startup. 

### Interface
  # $handler->init();

### Change History
  # 1998-05-07 Switched from get_contents to get_text_contents.
  # 1998-02-27 Fixed.
  # 1998-01-06 Created. -Simon

package WebApp::Handler::Plugins;

BEGIN { 
WebApp::Handler->import();
}
unshift @ISA, qw( WebApp::Handler );

BEGIN { 
Err::Debug->import();
}
BEGIN { 
File::Name->import();
}

# $handler->init;
sub init {
  my $handler = shift;
  my $dir = $handler->{'dir'} || File::Name->current->relative( '../plugins' );
  
  return unless ( $dir->exists );
  
  # Load Perl Modules
  unshift(@INC, $dir->absolute->path);
  my $module;
  foreach $module ( $dir->descendents( '*.pm' ) ) {
    debug 'plugins', 'Loading plugin from', $module->path;
    eval "package main;\n" . 
	 # "$INC{'" . $module->base_name . "'} = '" . $module->path . "';\n" . 
	 $module->get_text_contents;
  }
  shift(@INC);
}

1;

};
WebApp::Handler::Plugins->import();
}

BEGIN { 
WebApp::Resource->import();
}
$WebApp::Resource::SearchPath = File::SearchPath->new($Resource_Path);

BEGIN { 
$INC{'WebApp::Resource::Site'} = 'lib/WebApp/Resource/Site.pm';
eval {
### WebApp::Resource::Site allows you to make things site-specific.

### Class Name
  # $classname = WebApp::Resource::Site->subclass_name();

### Request Handling
  # $rc = $site->handle_request( $request );
  # $self_url = $site->self_url;
  # $site->has_focus;
  # $site->lost_focus;

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-01-11 Added has_focus, lost_focus; moved get_descriptions to INApp.pm
  # 1997-12-02 Updated to use improved Resource functionality.
  # 1997-11-20 Created. -Simon

package WebApp::Resource::Site;

BEGIN { 
$INC{'WebApp::Resource::PropertyList'} = 'lib/WebApp/Resource/PropertyList.pm';
eval {
### WebApp::Resource::PropertyList - resources defined in property list files.

### Change History
  # 1998-04-26 Modified write_source to skip '-.*' keys.
  # 1998-02-01 Fixed destructive shift on $resource->page_methods->{$name}.
  # 1998-01-16 Factored out of Resource superclass and existing subclasses. -S.

package WebApp::Resource::PropertyList;

BEGIN { 
WebApp::Resource->import();
}
push @ISA, qw( WebApp::Resource );

BEGIN { 
Text::PropertyList->import(qw( astext fromtext ));
}

### File Format

# $resource->read_source( $propertylist_text );
sub read_source {
  my $resource = shift;
  my $definition = fromtext( shift );
  foreach $key ( keys %$definition ) {
    next if ( $key =~ /\A\-/ );
    $resource->{ $key } = $definition->{ $key };
  }
  return;
}

# $propertylist_text = $resource->write_source;
sub write_source { 
  my $resource = shift;
  my %clean = map {$_, $resource->{$_}} grep {$_ !~ /\A\-/} keys %$resource;
  return astext( \%clean );
}

### Page Generation

# $rc = $resource->send_page_for_request( $request );
sub send_page_for_request {
  my $resource = shift;
  my $request = shift;
  
  my $pagename = $request->{'path'}{'names'}[1];
  $pagename = '-default' unless ( defined $pagename and length $pagename );
  
  my $page = $resource->page_for_request( $pagename );
  return 0 unless ( $page );
  
  $request->reply( $page->interpret );
  return 1;
}

# $page = $resource->page_for_request( $pagename );
sub page_for_request {
  my $resource = shift;
  my $pagename = shift;
  
  my $page;
  $page ||= $resource->scripted_page_by_name( $pagename );
  $page ||= $resource->page_by_name( $pagename );
  
  return $page;
}

# $method_hash = $resource->page_methods();
sub page_methods { return {}; }

# $page = $resource->page_by_name( $pagename );
sub page_by_name {
  my $resource = shift;
  my $pagename = shift;
  
  my $pagemethod = $resource->page_methods->{ $pagename };
  
  return unless $pagemethod;
  
  my $page;
  if ( ! ref $pagemethod ) {
    $page = $resource->$pagemethod();
  } else {
    my @args = @$pagemethod;
    my $methodname = shift @args;
    $page = $resource->$methodname( @args );
  }
  
  return $page;
}

# $page = $resource->scripted_page_by_name( $pagename );
sub scripted_page_by_name {
  my $resource = shift;
  my $pagename = shift;
  
  return unless ( $resource->{'pages'}{ $pagename } );

  $page = Script::Parser->new->parse( $resource->{'pages'}{ $pagename } );
  return $page;
}

1;


};
WebApp::Resource::PropertyList->import();
}
push @ISA, qw( WebApp::Resource::PropertyList );

BEGIN { 
Data::DRef->import();
}
BEGIN { 
Data::Collection->import();
}
use Carp;

BEGIN { 
Script::HTML::Tag->import();
}

WebApp::Resource::Site->register_subclass_name;

# $classname = WebApp::Resource::Site->subclass_name();
sub subclass_name { 'site' }

### Request Handling

# $rc = $site->handle_request( $request );
sub handle_request {
  my $site = shift;
  local $Request = shift;
  local $Root->{'request'} = $Request;
  
  $site->send_page_for_request( $Request );
}

# $self_url = $site->self_url;
sub self_url {
  my $site = shift;
  return $Request->{'links'}{'script'} . '/' . 
  	 $site->{'-name'} . '.' . $site->subclass_name;
}

# $site->has_focus;
sub has_focus {
  my $site = shift;
  
  setData('site', $site);
}

# $site->lost_focus;
sub lost_focus {
  setData('site', undef);
}

1;
};
WebApp::Resource::Site->import();
}
BEGIN { 
$INC{'WebApp::Resource::ScriptedPage'} = 'lib/WebApp/Resource/ScriptedPage.pm';
eval {
### WebApp::Resource::ScriptedPage

### File Format
  # $page->read_source( $propertylist_text );
  # $propertylist_text = $page->write_source;

### Page Generation
  # $page = $page->scripted_page_by_name( $pagename );
  # $page = $page->page_by_name( $pagename );
  # $page = $page->page_for_request( $pagename );
  # $rc = $page->send_page_for_request( $pagename );

### Change History
  # 1998-05-29 Switched to use of Script::Evaluate package instead of Script.
  # 1998-02-24 Created. -Simon

package WebApp::Resource::ScriptedPage;

$VERSION = 4.00_01;

BEGIN { 
WebApp::Resource->import();
}
push @ISA, qw( WebApp::Resource );

WebApp::Resource::ScriptedPage->register_subclass_name;
sub subclass_name { 'page' }

BEGIN { 
Script::Parser->import();
}
BEGIN { 
Data::DRef->import(qw( $Root ));
}

### File Format

# $page->read_source( $script_text );
sub read_source {
  my $page = shift;
  $page->{'elements'} = Script::Parser->new->parse( shift );
}

# $script_text = $page->write_source;
sub write_source { 
  my $page = shift;
  return $page->{'elements'}->source;
}

### Request Handling

# $rc = $page->handle_request( $request );
sub handle_request {
  my $page = shift;
  my $request = shift;
  
  local $Root->{'request'} = $request;
  $request->reply( $page->{'elements'}->interpret );
}

1;
};
WebApp::Resource::ScriptedPage->import();
}

# Create a WebApp Server
my $WebApp = WebApp::Server->new( qw( 
  WebApp::Request::CGI
  WebApp::Handler::FileHandler
  WebApp::Handler::DirectoryHandler
  WebApp::Handler::LoggingHandler
  WebApp::Handler::ResourceHandler
  WebApp::Handler::Scripted
  WebApp::Handler::Plugins
) );

setData('server', $WebApp);

# Execution
$WebApp->run();
