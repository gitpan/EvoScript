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

use Script::Tag;
@ISA = qw( Script::Tag );

Script::Tags::Hidden->register_subclass_name();
sub subclass_name { 'hidden' }

use Script::HTML::Forms;
use Data::Collection;
use Data::DRef qw( $Separator getDRef getData );

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

__END__

=head1 Hidden

Generates a series of hidden form fields. 

    [hidden args="criteria view"]

=over 4

=item args

A list of argument names to hide. If multiple argument names are given, each of them will be handled in the same way. Use '#' for DRefs. Required argument. 

=item source

Optional. Defaults to #request.args, where the current WebApp::Request::CGI arguments are expected to be stored. 

=item prefix

Optional. A string to prefix before each argument name. Use '#' for DRefs.

=item skip

Optional. A regular expression for argument names to skip. Use '#' for DRefs. 

=item flat

Optional flag. Unless this flag is set, the hidden tag will use L<Data::Collection>'s scalarkeysandvaluesof function to determine the non-leaf items in the argument values. 

I<This option is likely to go away unless someone needs it; let me know if you do. -Simon>

=back

Unless the flat flag is used, multiple hidden arguments will be generated for reference values. For example, if [hidden args=user] was invoked during a request to http://localhost/script.cgi?user.name=Joe&user.email=joe@spud.com, it would generate <input type=hidden name=user.name value=Joe><input type=hidden name=user.email value=joe@spud.com>.

=cut