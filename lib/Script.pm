
#!# THIS PACKAGE IS ARCHAIC - PLEASE USE Script::Evalutate INSTEAD

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

package Script;

require 5.000;

use Script::Parser;

# Include Syntax Classes
use Script::Literal;
Script::Parser->add_syntax( Script::EscapedLiteral );
Script::Parser->add_syntax( Script::Literal );

use Script::PoundTag;
Script::Parser->add_syntax( Script::PoundTag );

# Enable script parsing for EvoScript tags: [tag arg=value]
use Script::Tag;
use Script::Container;
Script::Parser->add_syntax( Script::Tag );

# Get any defined tags
use Script::Tags::Available;

# Enable script parsing for HTML tags: <tag arg=value>
use Script::HTML::Tag;
Script::Parser->add_syntax( Script::HTML::Tag );

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( runscript );
push @EXPORT_OK, qw( runscript );

# $result = runscript( $script_text );
sub runscript { Script::Parser->new->parse( shift )->interpret(); }

1;
