### Field::Compound::Range.pm
  # abstract superclass for date and time ranges

### Copyright 1997 Evolution Online Systems, Inc.
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-05-20 Added specialty update method. -Dan
  # 1998-04-23 Added edit_title method, spruced up compound_edit.
  # 1998-03-19 Fixed missing method name in update -- thanks Del.
  # 1998-03-18 Debugging. -Simon
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-09-18 Built -JGB

package Field::Compound::Range;

use Field::Compound;
@ISA = qw[ Field::Compound ];

use Script::HTML::Styles;

sub require {
  my ($field, $record) = @_;
  return ('none', []) if ( $field->subfield('start')->has_value($record) );
  return ('error', [$field->subfield('start')->title() ." requires a value"]);
}

sub validate {
  my ($field, $record) = @_;
  my ($level, $messages) = $field->totalvalidate(
			      $field->subfield('start')->validate($record),    
			      $field->subfield('end')->validate($record), 
			   );

  return ($level, $messages) unless ($level eq 'none');

  return ('error', ["Start value must precede end value"])
                           unless ( $field->in_order($record) );

  return ('none', []);
}

sub update {
  my($field, $record, $updates) = @_;
  my ($start_field, $end_field) = @{$field->subfieldorder()};
  $start_field->update($record, $updates);
  if ( $updates->{ $end_field->{'name'} } ) {
    $end_field->update($record, $updates);
  } else {
    $record->{ $end_field->{'name'} } = $start_field->value( $record );
  }
}

sub compound_readable {
  my($field, $record, %options) = @_;
  return unless ( $field->has_value( $record ) );
  $start = $field->subfield('start')->readable( $record, %options );
  $end = $field->subfield('end')->readable( $record, %options );
  return ( ($start eq $end) ? $start : "$start - $end" );
}

sub compound_display {
  my ($field, $record, %options) = @_;
  return $field->readable($record, %options);
}

# $html = $field->edit_title($record, %options);
sub edit_title {
  my ($field, $record, %options) = @_;
  $field->subfield('start')->title . ' ' . 
    $field->SUPER::edit_title($record, %options);
}

sub compound_edit {
  my ($field, $record, %options) = @_;
  
  '<nobr>' . 
  $field->subfield('start')->edit($record, %options) . ' ' . 
  stylize('label', $field->subfield('end')->title . ' ' . 
		      $field->SUPER::edit_title($record, %options) ) .
  $field->subfield('end')->edit($record, %options) . 
  '</nobr>';
}

sub subfield_definitions {
  my ($field) = @_;
  return [
    {
      'title' => 'Start',
      'name' => 'start',
      'type' => $field->{'range_type'},
      'formsize' => 14,
    },
    {
      'title' => 'End',
      'name' => 'end',
      'type' => $field->{'range_type'},
      'formsize' => 14,
    }
  ];
}

### Field::Compound::Range::Date

package Field::Compound::Range::Date;

use Field::Compound::Range;
@ISA = qw[ Field::Compound::Range ];

Field::Compound::Range::Date->add_subclass_by_name( 'daterange' );

sub init {
  my $field = shift;
  $field->{'range_type'} = 'date';
  return $field->SUPER::init();
}

sub in_order {
  my($field, $record) = @_;
  my($start_date, $end_date) = $field->value( $record );
  return 1 unless ( $start_date and $end_date  );
  return ($start_date->yyyymmdd() <= $end_date->yyyymmdd());
}

### Field::Compound::Range::Time
package Field::Compound::Range::Time;

use Field::Compound::Range;
@ISA = qw[ Field::Compound::Range ];

Field::Compound::Range::Time->add_subclass_by_name( 'timerange' );

sub init {
  my $field = shift;
  $field->{'range_type'} = 'time';
  return $field->SUPER::init();
}

sub update {
  my ($field, $record, $updates) = @_;
  my $end_field_name = $field->subfield('end')->{'name'};
  my $start_field_name = $field->subfield('start')->{'name'};

  if ( $updates->{ $start_field_name } =~ /^\s*(\d{1,2})(?:\D(\d{2}))?(?:\s*(am?|pm?))?\s*$/i) {
    my ( $start_hour, $start_ampm ) = ( $1, $3 );
    if (( $updates->{ $end_field_name } =~ /^\s*(\d{1,2})(?:\D(\d{2}))?\s*$/i)
      and ((( $1 >= 8 and $1 < 12 ) 
      and ( $start_hour != 0 and $start_hour < 8 )
      or ( $start_hour == 12 ))
      or ( $start_hour > $1 ))
      and ( $1 != 0 ) 
      and ( $1 != 12 )) {
        $updates->{ $end_field_name } = $updates->{ $end_field_name } . "pm";
        warn 'Ambiguous end time assumed to be PM due to conflicts otherwise';
        if (( $start_hour != 0 )
          and ( $start_hour < 12 )
          and ( ! $start_ampm )) {
	  $updates->{ $start_field_name } = $updates->{ $start_field_name } . "am";
          warn 'Ambiguous start time assumed to be AM due to conflicts otherwise';
        }
    } else { warn 'End time did not match regexp'; }
  } else { warn 'Start time did not match regexp'; }

  $field->SUPER::update($record, $updates);
}

sub in_order {
  my($field, $record) = @_;
  my($start_time, $end_time) = $field->value( $record );
  return 1 unless ( $start_time and $end_time  );
  return ($start_time->udt() <= $end_time->udt());
}

1;