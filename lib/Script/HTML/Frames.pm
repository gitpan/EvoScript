### Script::HTML::Frames provides frames-related HTML tags

### <frameset> ... </frameset>

### <frame>

### <noframes> ... </noframes>

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1997-11-01 Created. -Simon

package Script::HTML::Frames;

use Script::HTML::Tag;

### <frameset> ... </frameset>

package Script::HTML::Frames::FrameSet;
@ISA = qw( Script::HTML::Container );

sub subclass_name { 'frameset' };
Script::HTML::Frames::FrameSet->register_subclass_name;

### <frame>

package Script::HTML::Frames::Frame;
@ISA = qw( Script::HTML::Tag );

sub subclass_name { 'frame' };
Script::HTML::Frames::Frame->register_subclass_name;

### <noframes> ... </noframes>

package Script::HTML::Frames::NoFrames;
@ISA = qw( Script::HTML::Container );

sub subclass_name { 'noframes' };
Script::HTML::Frames::NoFrames->register_subclass_name;

1;