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

use strict;
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

__END__

=head1 Data::DRef

Data::DRef provides functions that allow you to uses delimited key-strings to get and set values in nested structures, and publishes a shared root for an application's object graph. The DRef functions are slower than direct variable access, but provide additional flexibility for scripting and other late-binding behaviour. 

=head1 Synopsis

    use Data::DRef;
    
    my $hash = { 'items' => [] };
    
    setDRef( $hash, 'items.0', 'value!' );
    print getDRef($hash, 'items.0');
    
    setData( 'myhash', $hash );    
    print getData('myhash.items.0');

=head1 Description

B<Nested Data Structures>

Data::DRef provides a streamlined interface for setting and retrieving values within Perl data structures. These data structures are generally networks of hashes and arrays, some "raw" and some blessed into a class/package, containing a mix of simple scalar values and references to other items in the structure. 

Programmatic access to these values within Perl usually looks something like this:

    print $report->{'employees'}[3]{'name'};

B<Value access with DRefs>

The Data::DRef functions allow you to access these values using drefs, string values composed of a series of keys separated by the $Separator delimiter character, '.'. For example, you could replace the above statement with:

    print getDRef($report, 'employees.3.name');

B<The Root Access Point>

Data::DRef also provides a common point-of-entry datastructure, refered to as $Root. Objects or structures accessible through $Root can be refered to identically from any package using the getData and setData functions. Here's another report example:

    setData('report', $report);
    ...
    print getData('report.employees.3.name');

B<Parenthesized substrings>

The getData and setData functions support a parenthesized substring syntax, where each substring is looked with getData and replaced with the results. For example:

    setData('report', $report);
    ...
    setData('empl_number', 3);
    ...
    print getData('report.employees.(empl_number).name');

Nested parentheses are supported, with the innermost parentheses resolved first.

B<Object Overrides>

Classes that wish to provide alternate DRef-like behavior or generate values on demand should implement get and set methods, and these functions will hand-off to them when appropriate.

For example, here's a get method for an object which provides a calculated timestamp value:

    package Clock;
    
    sub new { bless {}; }
    
    sub get {
      my ($self, $dref) = @_;
      return time() if ( $dref eq 'timestamp' );
      # fall through for other drefs
      Data::DRef::get( $self, $dref ); 
    }
    
    package main;
    
    setData( 'clock', new Clock );
    ...
    print getData( 'clock.timestamp' );

=head1 Reference

=head2 DRef Syntax

=over 4

=item $Separator 

This package variable provides the multiple-key delimiter character. It defaults to '.', but can be locally overridden.

=item joindref( @keys ) : $dref

Joins the provided keys with the $Separator character.

=item splitdref( $dref ) : @keys

Splits $dref on $Separator, returning a series of keys.

=item shiftdref( $dref ) : $key

Removes the first key from the dref and returns it. Note that the original $dref variable is altered, and set to '' when the last key is removed.

=back

=head2 Multiple-Key Get and Set

These functions implement the underlying access-by-DRef mechanism. Direct access to values in hashes and arrays are supported. 

=over 4

=item get($item, $dref) : $value

Starting at $item, attempts to look up each key in $dref and sequentially follow references then return the last value.

=item set($item, $dref, $value)

Starting at $item, look up each key in $dref, creating new empty hash references as needed, then set the value at the tip.

=back

=head2 Core DRef Functions

=over 4

=item getDRef($item, $dref) : $value

Calls get($item, $dref), using $item's implementation or the above function.

=item setDRef($item, $dref, $value)

Calls set($item, $dref, $value), using $item's implementation or the above function.

=back

=head2 Shared Data Graph

=over 4

=item $Root

Data graph entry point used by getData and setData. 

=item getData($dref) : $value

Gets the value at $dref from $Root. Supports embedded parenthesis via resolveparens.

=item setData($dref, $value)

Sets's $dref in $Root to $value. Supports embedded parenthesis via resolveparens.

=item resolveparens( $dref_with_embedded_parens ) : $dref

Replaces parenthenthesized substrings in the argument with the value returned by getData.

=back

=head1 Caveats and Upcoming Changes

We don't yet properly escape and unescape drefs for printability, or protect $Separators embedded within a subkey. This is expected to change, perhaps to use backslash escapes.

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut