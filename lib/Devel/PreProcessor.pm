#!/usr/local/bin/perl -s

### Devel::PreProcessor - Module inlining and other Perl source manipulations

### Change History
  # 1998-05-23 Added support for custom @LibPath.
  # 1998-03-24 Minor doc fixup.
  # 1998-02-24 Removed leading whitespace from POD regexes (thanks Del)
  # 1998-02-23 Changed regex for use statements to break at parenthesis.
  # 1998-02-19 Moved general-purpose code to new Devel::PreProcessor package.
  # 1998-02-19 Added $Conditionals mechanism.
  # 1998-02-19 Added $INC{$module} to output to prevent run-time reloads.
  # 1998-01-26 Modified to imports and eval in the same begin block. 
  # 1998-01-20 Hacked ActiveWare source; changed pragma import calls -Simon

### Copyright 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License
  # 
  # Contributors:
  # M. Simon Cavalletto <simonm@evolution.com>
  # Feature suggestions by Del Merritt <dmerritt@intranetics.com>
  # Win32 debugging assistance from Randy Roy <rroy@intranetics.com>
  # Based on filter.pl, provided by ActiveWare <www.activestate.com>

package Devel::PreProcessor;

$VERSION = 1.03;

use IO::File;

# Option flags, defaulting to off
use vars qw( @LibPath $Includes $Conditionals $StripComments $StripPods $ShowFileBoundaries $StripBlankLines );
@LibPath = @INC unless (scalar @LibPath);

# Devel::PreProcessor->import( 'StripPods', 'Conditionals', ... );
sub import {
  my $package = shift;
  foreach ( @_ ) {
    if ( m/Conditionals/i ) {
      $Conditionals = 1;
    } elsif ( m/Includes/i ) {
      $Includes = 1;
    } elsif ( m/StripComments/i ) {
      $StripComments = 1;
    } elsif ( m/ShowFileBoundaries/i ) {
      $ShowFileBoundaries = 1;
    } elsif ( m/StripBlankLines/i ) {
      $StripBlankLines = 1;
    } elsif ( m/StripPods/i ) {
      $StripPods = 1;
    } elsif ( m/LibPath:(.*)/i ) {
      @LibPath = split(/\:/, $1);
    } else {
      die "unkown import";
    }
  }
}

# parse_file( $filename );
sub parse_file {
  my $filename = shift;
  
  my $fh = IO::File->new($filename);
  my $line_number;
  
  LINE: while(<$fh>) {
    $line_number ++;
    
    if ( $line_number < 2 and /^\#\!/ ){
      print $_;  			# don't discard the shbang line
      next LINE;
    } 
      
    elsif ( $StripPods and /^=(pod|head[12])/i ){
      do { ++ $line_number; } 
	  while ( <$fh> !~ /^=cut/i );  # include everything up to '=cut'
      next LINE;
    }    
    elsif ( /^=(pod|head[12])/i ){
      do { print $_; ++ $line_number; $_ = <$fh> } 
	  while ( $_ !~ /^=cut/i );  	# discard everything up to '=cut'
      next LINE;
    }
    
    elsif ( $Includes and /^\s*use\s+([^\s\(]+)(?:\s*(\S.*))?;/ ) {
      my( $module, $import ) = ( $1, $2 );
      do_use($module, $import) or print $_;
    } elsif ( $Includes and /^\s*require\s+([^\$]+);/ ) {
      my $module = $1;
      do_require( $module ) or print $_;
    } elsif ( $Includes and /^\s*__(END|DATA)__/ ){
      last LINE;			    # discard the rest of the file
    }
    
    elsif ( $StripBlankLines and /^\s*$/){
      next LINE;			    # skip whitespace only lines
    }
    
    elsif ( $StripComments and /^\s*\#/){
      next LINE;			    # skip full-line comments
    }
    
    elsif ( $Conditionals and /^\s*#__INCLUDE__ if (.*)/i ) {
      my $rc = eval "package main;\n" . $1;
      unless ( $rc and ! $@ ) {	    # if expr isn't true, skip to end
	do { ++ $line_number; print "\n"; } 
	    while ( <$fh> !~ /^\s*\#__INCLUDE__ endif/i );
      }
    } elsif ( $Conditionals and /^\s*\#__INCLUDE__ endif/i){
      next LINE;			    # skip conditional end
    } elsif ( $Conditionals and /^\s*\#__INCLUDE__ dlftskp (.*)/i){
      print $1;			    # remove conditional defaulting
      next LINE;
    } else {
      print $_;
    }
  }
  undef $fh;
}

# do_use( $module, $import_list );
sub do_use {
  my $module = shift;
  my $imports = shift;
  
  return 1 if ($module eq 'strict');  # problems with scoping of strict
  
  if ($module eq 'lib') {
    my @paths = eval "$imports";
    push @LibPath, @paths;
    return 1;
  }
  
  my $filename = find_file_once( $module );
  return if ( ! $filename ) ;
  
  print "BEGIN { \n";
  
  do_include( $module, $filename ) unless ( $filename == -1 );
  
  # Call import, but don't use the OOP notation for lowercase pragmas.
  print $module, ($module =~ /\A[a-z]+\Z/ ? "::import('$module', " 
					  : "->import("), "$imports);\n";
  
  print "}\n";
  
  return 1;
}

# do_require( $module );
sub do_require {
  my $module = shift;
  
  my $filename = find_file_once( $module );
  return if ( ! $filename or $filename == -1 ) ;
  do_include( $module, $filename );
}

# do_include( $module, $filename );
sub do_include {
  my $module = shift;
  my $filename = shift;
  
  print "### Start of inlined library $module.\n" if $ShowFileBoundaries;
  print "  # Source file $filename.\n" if $ShowFileBoundaries;
  print "\$INC{'$module'} = '$filename';\n";
  print "eval {\n";
  
  parse_file($filename);
  
  print "\n};\n";
  print "### End of inlined library $module.\n" if $ShowFileBoundaries;
  
  return 1;
}

# %files_found - hash of filenames included so far
use vars qw( %files_found );

# $filename_or_nothing = find_file_once($module);
sub find_file_once {
  my $module_file = shift;
  
  return if ($module_file =~ /^[\.\_\d]+/); # ignore Perl version requirements
  
  $module_file =~ s#::#/#g;
  $module_file .= '.pm';
  
  # If we've already included this file, we don't need to do it again.
  return -1 if $files_found{ $module_file };
  my $filename = search_path( $module_file );
  $files_found{ $module_file } ++ if ( $filename );
  return $filename;
}

# $filename = search_path($module);
sub search_path {
  my $module = shift;
  
  my $dir;
  foreach $dir (@LibPath) {
    my $match = $dir . "/" . $module;
    return $match if ( -e $match );
  }
  
  return 0;
}

# If we're being run directly, expand the first file on the command line.
unless ( caller ) {
  $Includes ||= $main::Includes;
  $Conditionals ||= $main::Conditionals;
  $StripComments ||= $main::StripComments;
  $StripBlankLines ||= $main::StripBlankLines;
  $StripPods ||= $main::StripPods;
  $ShowFileBoundaries ||= $main::ShowFileBoundaries;
  my $source = shift @ARGV;
  @LibPath = @ARGV if ( scalar @ARGV );
  parse_file($source);
}

1;

__END__

=head1 Devel::PreProcessor

Given a Perl source file, attempts to include all used and required files.

=head2 Synopsis

From a command line,

    sh> perl PreProcessor.pm -Flags sourcefile > targetfile

Or in a Perl script,

    use Devel::PreProcessor qw( Flags );
    ...
    select(OUTPUTFH);
    Devel::PreProcessor::parse_file( $sourcefn );

=head2 Flags

There are several flags listed below which can be used as 'Flags' is above, on the command line or import statement. Each of these flags are mapped to the scalar package variable of the same name.

=over 4

=item Includes

If true, parse_file will replace all use and require statements with inline declarations using the contents of the file found in the current @INC. The resulting script should operate identically and no be longer dependant on external libraries (but see compatibility note below).

=item ShowFileBoundaries

If true, comment lines will be inserted delimiting the start and end of each inlined file.

=item StripPods

If true, parse_file will not include POD from the source files. All groups of lines resembling the following will be discarded. 

    =head(1|2)
    ...
    =cut

=item StripBlankLines

If true, parse_file will skip lines that are empty, or that contain only whitespace. 

=item StripComments

If true, parse_file will not include full-line comments from the source files. Only lines that start with a pound sign are discarded; this might not match Perl's parsing rules in some obscure cases.

=item Conditionals

If true, parse_file will utilize a simple conditional inclusion scheme, as follows.

    #__INCLUDE__ if expr
    ...		
    #__INCLUDE__ endif

The provided expression is evaluated, and unless it is true, everything up to the next endif declaration is replaced with empty lines. In order to allow the default behavour to be provided when running the raw files, comment out lines in non-default branches with the following:

    #__INCLUDE__ dlftskp ...

Empty lines are used  in place of skipped blocks to make line numbers come out evenly, but conditional use or require statements will throw the count off, as we don't pad by the size of the file that would have been in-lined.

Finally, Perl's -s switch allows you to set additional flags on the command line, like:

    perl -s PreProcessor.pm -Conditionals -Switch filter.test

You can use any name for your switch, and the matching scalar variable will be set true; the following code will only be used if you supply the above switch.

    #__INCLUDE__ if $Switch
    #__INCLUDE__ dlftskp print "you hit the switch!\n";
    #__INCLUDE__ endif

=head2 Functions

=over 4

=item parse_file( $filename );

=item do_use( $module, $import_list );

=item do_require( $module );

=item $filename_or_nothing = find_file_once($module);

=item $filename = search_path($module);

=back

=head1 Examples

To inline all used modules:

    perl -s Devel/PreProcessor.pm -Includes SCRIPT_FILENAME > SCRIPT_INCLUDED

To count the lines of Perl source in a file, run the preprocessor from a shell with the following options

    perl -s Devel/PreProcessor.pm -StripComments -StripPods -StripBlankLines MODULE_FILENAME | wc -l

=head1 Caveats and Upcoming Changes

=over 4

=item Compatibility: Includes

Libraries inlined with Includes may not be appropriate on another system, eg, if Config is inlined, the script may fail if run on a platform other that on which it was built.

=item New Feature: Include Filter

Includes should take an option to control which files are resolved; for example, to inline various custom libraries but leave the use statements in for libraries in the standard distribution.

=item New Feature: Support use lib pragma

Should look for "use lib" pragmas and honor them while preprocessing.

=item Limitation: Use statements can't span lines

Should support newline in import blocks for long use statements.

=item Limitation: __DATA__ lost

We should really preserve the __DATA__ block from the original source file.

=item Limitation: AL, XSUB files not included

Autoload files are not handled. There's not much we can do about XSub/PLL files.

=cut
