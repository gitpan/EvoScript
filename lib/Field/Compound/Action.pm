### Field::Compound::Action tracks created and edited actions on a record

### Copyright 1998 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-06-03 Set default related_fieldname so user is displayed by staff name
  # 1998-06-02 Added display_link to user subfield. -Simon
  # 1998-04-27 Renamed display to compound_display to fix subfields. EJM
  # 1998-04-24 Fixed typo in compound_readable.
  # 1998-03-09 Fixed get_role method. Added $package->add_subclass.. call.
  # 1998-02-27 Debugging -Simon
  # 1998-02-25 Implemented $field->get_role( $record )
  # 1998-02-04 Started V4 Rebuild
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-07-10 Builded it agains -Jeremy

### Reference
  # $role = $field->get_role( $record )
  # $field->action()
  # $formatted = $field->format_action($date, $action);

package Field::Compound::Action;

use vars qw( $VERSION );
$VERSION = 1.00_1997_03_09;

use Field::Compound;
push @ISA, qw[ Field::Compound ];

Field::Compound::Action->add_subclass_by_name( 'action' );

use Data::DRef qw( getData );

use DateTime::Date;

use strict;

# $field->init()
sub init {
  my($field) = @_;

  $field->{'show'} ||= 0;
  $field->{'action_name'} ||= 'Edited';
  $field->{'actor_name'} ||= $field->{'action_name'} . ' by';
  $field->{'actor_datastore'} = 'users';

  # $field->{'actor_displayfield'} = 'detaillink';

  $field->SUPER::init();
  return;
}

# %@$subfield_defs = $field->subfield_definitions() 
sub subfield_definitions {
  my ($field) = @_;
  return [
    {
      'title' => $field->{'action_name'},
      'name' => 'date',
      'type' => 'date',
    },
    {
      'title' => $field->{'actor_name'},
      'name' => 'actor',
      'type' => 'relation',
      'display_link' => 1,
      'relation_to' => $field->{'actor_datastore'},
      'related_fieldname' => 'staff',
    },
  ];
}

# $html = $field->edit($record, %options)  => display
sub edit { (shift)->display( @_ ); }

# $field->action($record)
sub action {
  my($field, $record, $date, $actor) = @_;
  $record->{ $field->subfield('date')->{'name'} } = current_date();
  $record->{ $field->subfield('actor')->{'name'} } = getData('user.id');
  return;
}

# $text = $field->compound_readable($record, %options);
sub compound_readable {
  my ($field, $record, %options) = @_;
  
  my $date = $field->subfield('date')->readable($record) 
	      if( $field->subfield('date')->value($record) );
  
  my $actor = $field->subfield('actor')->readable($record)
	      if( $field->subfield('actor')->value($record) );
  
  return  $field->format_action($date, $actor);
}

# $html = $field->compund_display($record, %options)
sub compound_display {
  my ($field, $record, %options) = @_;

  my $date = $field->subfield('date')->display($record) 
	     if( $field->subfield('date')->value($record) );

  my $actor = $field->subfield('actor')->display($record)
	     if( $field->subfield('actor')->value($record) );

  return  $field->format_action($date, $actor);
}

# $prettiness = $field->format_action($date, $actor);
sub format_action {
  my($field, $date, $actor) = @_;
  if ($date or $actor) {
    $actor ||= '-unknown-';
    $date ||= '-unknown-';
    if ( $field->{'shortdisplay'}  ) {
      return ( $date ? "$date" : "") . 
	    ( $actor ? " by $actor" : "");
    } else {
      return $field->{'action_name'}  . 
	    ( $date ? " on $date" : "") . 
	    ( $actor ? " by $actor" : "");
    }
  }
  return '- no history -';
}

# $field->update($record, $source)
sub update {
  return;
}

# $role = $field->get_role( $record );
sub get_role {
  my ( $field, $record ) = @_;
  
  my $actor = $field->subfield('actor')->value($record);
  return unless( $actor and $actor == getData('user.id') );
  
  return $field->{'role'} if ( $field->{'role'} );
}

1;
