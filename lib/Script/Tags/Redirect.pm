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

use Script::Container;
@ISA = qw( Script::Container );

Script::Tags::Redirect->register_subclass_name();
sub subclass_name { 'redirect' }

# [redirect] url... [/redirect]
%ArgumentDefinitions = (
);

use Data::DRef;

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

=head1 Redirect

Using its evaluated contents as a URL, redirects and dies. Once this happens, execution of the current request generally stops.

    [redirect][print value=#homepage escape=url][/redirect]

There are no arguments for this tag.

It the URL starts with a slash, the current web server address is prepended to it. If not, and the URL is not fully qualified, the web server address, script URL, and non-terminal path-info is prepended. 

For example, if you had made a request for http://localhost/script.cgi/foo/bar.page, and the page invoked [redirect]/baz.page[/redirect], you would be redirected to http://localhost/baz.page; if it used [redirect]baz.page[/redirect], you would be sent to http://localhost/script.cgi/foo/baz.page.

=cut