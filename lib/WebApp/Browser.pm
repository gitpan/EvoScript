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

use Class::MethodMakerExtentions ( new_with_init => 'new_from_ua', new_hash_init => 'new', get_set => [ qw( ua id version flavor os spoof ) ], list => 'proxies', lookup => [ 'title'=>'id', 'frames'=>'id_v', 'java'=>'id_v', 'javascript'=>'id_v' ] );

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

__END__;

=head1 WebApp::Browser

B<Instantiation>

=over 4

=item WebApp::Browser->new_from_ua( $user_agent_string ) : $browser

Create a new Browser object based on the provided user agent string.

=item WebApp::Browser->new( @key_value_pairs ) : $browser

Create a new Browser object containing the provided key-value pair attributes.

=item $browser->init( $user_agent_string )

Analyze the provided user agent string in an attempt to determine what piece of software it represents.

=back

B<Attributes>

=over 4

=item $browser->id : $abbrev

=item $browser->id( $abbrev )

Get or set the short browser-ID string, such as 'NS' for Netscape or 'IE' for Microsoft clients.

=item $browser->version : $version_number

=item $browser->version( $version_number )

Get or set the numeric browser version.

=item $browser->id_v : $id_v

Returns the browser id and the integer portion of the version number, like 'IE3' or 'NS4'.

=item $browser->os : $operating_system_type

=item $browser->os( $operating_system_type )

Get or set a string describing the operating system the browser is running on. The following values are used: MacOS, MSDOS, Win32, VMS, or Unix

=item $browser->flavor : $variation_name

=item $browser->flavor( $variation_name )

Get or set a string describing a non-standard aspect of the browser, like 'Gold' for the enhanced version of Netscape 3.

=item $browser->spoof : $facade_browser_id_v

=item $browser->spoof( $facade_browser_id_v )

Get or set a string in the id_v format that the browser claims equivalence with.

=item $browser->proxies : @proxy_title_strings

=item $browser->push_proxies( @proxy_title_strings )

=item $browser->pop_proxies : $proxy_title_strings

Access or update a list of proxy-server identification strings that interceeded in the request.

=item $browser->title : $browser_name

Return the title of identified browsers, like 'Microsoft Internet Explorer'.

=back

B<Feature Availability>

=over 4

=item $browser->frames : $flag

Returns a flag indicating whether the browser supports frames.

=item $browser->java : $empty_or_version

Returns the version number of this browser's support for Java applets. 

=item $browser->javascript : $empty_or_version

Returns the version number of this browser's support for JavaScript. 

=back

=cut
