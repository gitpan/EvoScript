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

use Err::Debug;
use Data::DRef qw( getData setData );
use Text::Excerpt qw( printablestring );
use Text::PropertyList qw( astext fromtext );

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

__END__

=head1 Perl

Executes a bit of in-line Perl. 

    [perl]
      return $ENV{'SERVER_PROTOCOL'};
    [/perl]

=over 4

=item target

Optional. The DRef at which to store the value returned by the Perl code. 

=item silently

Optional flag. If a target is not provided, the perl tag will return the result of the expression unless this argument I<is> provided.

=item aslist

Optional flag. Interprets the Perl in a list context and returns an array reference containing the results.

=item ashash

Optional flag. Interprets the Perl in a list context and returns a hash reference containing the results.

=back

=cut