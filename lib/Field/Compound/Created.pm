### Field::Compound::Created.pm
  # Tracks creation of a record

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-02-27 Debugging -Simon
  # 1998-02-25 Rebuilt in v4 libs
  # 19970924 IntraNetics97 Version 1.00.000
  # 19970710 Builded it anews -Jeremy

package Field::Compound::Created;

use vars qw( $VERSION );
$VERSION = 1.00;

use Field::Compound::Action 1.0;
push @ISA, qw( Field::Compound::Action );

Field::Compound::Created->add_subclass_by_name( 'created' );

sub init {
  my($field) = @_;
  $field->{'action_name'} ||= 'Created';
  $field->{'actor_name'} ||= 'Creator';
  $field->{'title'} ||= 'Created';
  $field->SUPER::init;
  return;
}

sub default {
  my($field, $record) = @_;
  $field->action($record);
  return;
}

1;