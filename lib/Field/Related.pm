### Field::Related
  # Reverse foreign-key relational fields

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Del      G. Del Merritt      (del@intranetics.com)

### Change History
  # 1998-06-08 Made 'wide' optional. -Simon
  # 1998-06-05 Added sortorder for Reports.
  # 1998-04-16 Propagate the nocolor and border flags.
  # 1998-03-18 Included in IntraNetics 1.1/Mystic. -Del
  # 1998-02-28 Created. -Simon

package Field::Related;

use Field;
use Field::Association;
@ISA = qw[ Field::Association Field ];
Field::Related->add_subclass_by_name( 'related' );

use Err::Debug;
use Text::Words qw( string2list );
use Data::DRef;
use Data::Collection;
use Script::Tags::Report;

use strict;

### INSTANTIATION

sub init {
  my($field) = @_;
  $field->init_related_record_class();
  $field->{'wide'} = 1 unless ( exists $field->{'wide'} );
  $field->SUPER::init();
  return;
}

# @$records = $field->related_records($record);
sub related_records {
  my ($field, $record) = @_;
  my $criteria = Data::Criteria::NumericEquality->new_kv(
		      $field->{'reference_field'}, $record->{'id'} );
  return $field->related_record_class->records( [$criteria] );
}

### VIEW

# $text = $field->readable( $record, %options )
sub readable {
  my($field, $record, %options) = @_;
  
  my @values;
  
  my $item;
  foreach $item ($field->related_records($record)) {
    push @values, $item->readable( $field->{'display_field'} );
  }
  return join(', ', @values);
}

# $display = $field->display( $record, %options )
sub display {
  my($field, $record, %options) = @_;
  my $records = $field->related_records($record);
  return unless ( scalar @$records );

  if (! $field->{'style'} || $field->{'style'} eq 'table') {
    Script::Tags::Report->new( 
      'records' => $records,
      'fieldorder' => [string2list( $field->{'report_fields'} )],
      'sortorder' => $field->{'sortorder'},
      'block' => $field->{'report_block'} || '',
      'border' => $field->{'border'},
      'nocolor' => $field->{'nocolor'},
    )->interpret;
  }
  elsif ( $field->{'style'} eq 'grid') {
    my $listing = Script::Tags::Grid->new( 
      'values' => $records,
      'sortorder' => $field->{'sortorder'},
      'direction' => $field->{'direction'},
      'width' => $field->{'width'}, 
      'numcols' => $field->{'cols'} || 2, 
      'border' => $field->{'border'},
      'nocolor' => $field->{'nocolor'},
    );
    $listing->add(Script::Parser->new->parse($field->{'contents'}));
    return $listing->interpret;
  }
}

# $form = $field->edit( $record, %options )
sub edit {
  return;
}

1;

__END__

For example:
  
  {
    name = items;
    title = "Items";
    type = related;
    
    /* datastore to draw the line items from */
    relation_to = items;
    
    /* name of the field in the remote datastore which refers back to us */
    reference_field = report_id;
    
    /* field to show when constructing a text-only readable version */
    display_field = amount;
    
    /* fields to show when constructing an HTML report display */
    report_fields = "status amount created";
    
    /* optional, script to show under each line in an HTML report display */
    report_block = "[print value=#-record.description]";
  },
