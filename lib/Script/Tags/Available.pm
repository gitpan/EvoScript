### Script::Tags::Available provides access to locally known tag classes

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-06-01 Added Random. -Dan
  # 1997-11-26 Created. -Simon

package Script::Tags::Available;

# Include EvoScript Tags
use Script::Tags::Print;
use Script::Tags::Set;
use Script::Tags::If;
use Script::Tags::ForEach;
use Script::Tags::Perl;

use Script::Tags::Redirect;
use Script::Tags::Sort;
use Script::Tags::Silently;
use Script::Tags::Warn;

use Script::Tags::Grid;
use Script::Tags::Report;
use Script::Tags::Detail;
use Script::Tags::Calendar;

use Script::Tags::Hidden;

use Script::Tags::Random;

1;