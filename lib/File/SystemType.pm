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

__END__

=head1 File::SystemType

These functions provide information about the local file system.

=over 4

=item file_system_type : $fsys_type

Returns one of these string constants: MacOS, MSDOS, Win32, VMS, or Unix.

=item discover_directory_separator : $dir_sep_char

Returns the directory separator character for the current environment, forward slash, backslash, or colon.

=item directory_separator : $dir_sep_char

Returns the directory separator character. Caching wrapper around discover_directory_separator.

=item %directory_separators

Package variable mapping known $fsys_type values to their $dir_sep_char.

=back
