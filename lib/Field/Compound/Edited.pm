### Field::Compound::Edited.pm
  # Tracks edits to a record

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-02-27 Debugging -Simon
  # 1998-02-25 Rebuilt in v4 libs
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-07-10 Builded it anews -Jeremy

package Field::Compound::Edited;

use vars qw( $VERSION );
$VERSION = 1.00;

use Field::Compound::Action 1.00;
push @ISA, qw( Field::Compound::Action );

Field::Compound::Edited->add_subclass_by_name( 'edited' );

sub init {
  my($field) = @_;
  $field->{'action_name'} = 'Edited';
  $field->{'actor_name'} = 'Editor';
  $field->{'title'} ||= 'Edited';
  $field->SUPER::init;
  return;
}

sub flatten {
  my($field, $record, $target) = @_;
  $field->action($record);
  $field->SUPER::flatten($record, $target);
  return;
}

1;