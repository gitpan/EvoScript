### Field::Association.pm 
  # Foreign-key Association Mix-in

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-05-29 Switched to use of Script::Evaluate package instead of Script.
  # 1998-02-27 Using new Record->class_from_name interface. -Simon
  # 19971110 Moved to v4 as a mixin class out of relation.pm

package Field::Association;

use Record;
use Script::Evaluate qw( runscript );

# $field->init_related_record_class()
sub init_related_record_class {
  my($field) = @_;
  
  $field->{'related_class'} = Record->class_from_name($field->{'relation_to'});
  
  die( "Could not find record class '$field->{'relation_to'}'")
    unless( $field->{'related_class'} );

  return;
}

# $package = $field->related_record_class()
sub related_record_class {
  my($field) = @_;
  return $field->{'related_class'};
}

# $related_record = $field->related_record( $record );
sub related_record {
  my($field, $record) = @_;
  my $id = $field->value( $record );
  return unless( $id );
  return $field->related_record_class->record_by_id( $id );
}

# @$records = $field->related_records( @$criteria );
sub related_records {
  my($field, $criteria) = @_;
  if ($field->{'related_criteria_field'} and 
  				! (ref($criteria) && scalar(@$criteria)) ) {
    $criteria = Data::Criteria->new_from_def( {
      'key'   => $field->{'related_criteria_field'},
      'match' => 'isequal',
      'value' => runscript( $field->{'related_criteria_value'} ),
    } );
  }
  return $field->related_record_class->records( $criteria );
}

# ($related_field, %related_options) = $field->related_field( $fieldname );
sub related_field {
  my($field, $fieldname) = @_;

  $fieldname = $field->related_fieldname( $fieldname );

  return $field->related_record_class->field( $fieldname );
}

# $fieldname = $field->related_fieldname( $fieldname );
sub related_fieldname {
  my($field, $fieldname) = @_;

  return $fieldname if ( $fieldname and length($fieldname) );

  return $field->{'related_fieldname'}
      || $field->related_record_class->default_fieldname();  
}

1;

=pod

=head1 Field::Association

Foreign-key Association Mix-in.

=head1 Synopsis

=head1 Reference

=over 4

=item $field->init_related_record_class()

To be called the init method of a mixed class Field. Tries to get the package name of a related record class. Dies upon failure.

=item $field->related_record_class() : $package

Returns the package name of the related record class.

=item $field->related_record( $record ) : $related_record

Returns the foreign record related to $record.

=item $field->related_records( @$criteria ) : @$records

Returns a list of records from the related record class.

=item $field->related_fieldname( $fieldname ) : $fieldname

Returns the name or a related field. If no $fieldname is supplied, and there is no $field->{'related_field'}, the related record class's default field name will be used. 

=item $field->related_field( $fieldname ): ($related_field, %related_options)

Returns a field and options for a related field. See the Field option method.

=back

=head1 Caveats and Upcoming Changes

=head1 This is Free Software

Copyright 1997, 1998 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut