### Script::Tags::Random returns a random selection from a given list

### Copywrite 1998 Evolution Online Systems, Inc.
  # Dan     Dan Hallum (dan@evolution.com)

### Change History
  # 1998-06-01 Created -Dan

package Script::Tags::Random;

use Script::Tag;
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