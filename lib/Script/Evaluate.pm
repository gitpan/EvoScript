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

use Script::Parser;

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
