### Number::Formats provide a Text::Format interface for the Number::* routines

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-24 Added Currency support and initial visible formats -Del
  # 1997-11-24 Added comma separated format. 
  # 1997-11-17 Created to work with new Text::Format package -Simon

package Number::Formats;

use vars qw( $VERSION );
$VERSION = 1.00_1998_03_11;

use Number::Bytes;
Text::Format::add( 'bytes',   \&Number::Bytes::byte_format );
Text::Format::add( 'bits',    \&Number::Bytes::bit_format );

use Number::Roman;
Text::Format::add( 'roman',   \&Number::Roman::roman );
Text::Format::add( 'unroman', \&Number::Roman::unroman );

use Number::Words;
Text::Format::add( 'words',   \&Number::Words::aswords );
Text::Format::add( 'nth',     \&Number::Words::nth );

use Number::Separated;
Text::Format::add( 'separated',   \&Number::Separated::separated );

use Number::WorkTime;
Text::Format::add( 'ashours',   \&Number::WorkTime::ashours );

use Number::Currency;
Text::Format::add( 'cents_to_dollars', \&Number::Currency::cents_to_dollars );
Text::Format::add( 'dollars_to_cents', \&Number::Currency::dollars_to_cents );

1;
