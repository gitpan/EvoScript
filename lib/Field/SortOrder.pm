### Field::SortOrder.pm 

### Copyright 1998 Evolution Online Systems
  # You may use this software for free under the terms of the Artistic License

### Developed by Evolution Online Systems, Inc.
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-06-08 Code review and fixups. -Simon
  # 1998-05-22 Readable based on fieldname from datastore file. -TPC
  # 1998-04-29 Added default_fieldname to list for $display_fieldname.
  # 1998-04-29 Fixed ordering in select_options.
  # 1998-03-19 Rebuilt in v4 libraries
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-07-31 Changed SQL datatype to float.
  # 1997-06-18 Built. -Jeremy

package Field::SortOrder;

use vars qw( $VERSION );
$VERSION = 1.00_1998_03_19;

use Field;
use Field::Association;
@ISA = qw[ Field Field::Association ];

$Field::known_subclasses{'sortorder'} = 'Field::SortOrder';

use Script::HTML::Tag qw( html_tag );
use Data::DRef qw( joindref );
use Err::Debug qw( debug );

# $field->init;
sub init  {
  my ($field) = @_;
  $field->{'hint'} ||= 'Pick \'first\' or the item to precede this record';
  $field->SUPER::init();
}

# $float = $field->sql_datatype;
sub sql_datatype { 'float' }

# $field->next_option( @$path, %$options )
sub next_option {
  my($field, $path, $options) = @_;
  
  my $item = shift( @$path );
  if ( $item eq 'rawvalue' or $item eq 'rank' or $item eq 'title' ) {
    $options->{'value'} = $item;
  } else {
    unshift( @$path, $item );
    $field->SUPER::next_option( $path, $options ); 
  }
  
  return;
}

# $rank_name_or_value = $field->readable( $record, %options );
sub readable {
  my ($field, $record, %options) = @_;
  if ( ! $options{'value'} ) {
    return $record->readable( $field->{'display_fieldname'} );
  } elsif ( $options{'value'} eq 'rank' ) {
    return $field->rank( $record );
  } elsif ( $options{'value'} eq 'rawvalue' ) {
    return $field->value( $record );
  }
}

# $ordinal = $field->rank($record)
sub rank {
  my ($field, $record) = @_;
  
  my $records = $record->records();
  my $name = $field->{'name'};
  $records = [sort {$field->value($a) <=> $field->value($b)} @$records ];
  
  my $rank = 0;
  my $class_record;
  foreach $class_record (@$records) {
    $rank ++;
    return $rank if ( $class_record->value('id') eq $record->value('id') );
  }
}

# $field->edit( $record, $options );
sub edit {
  my ($field, $record, %options) = @_;
  
  # Name of field to be displayed in <select> list <option>s
  my $display_fieldname = $options{'display'} || 
  		$field->{'display_fieldname'} || $record->default_fieldname;
  
  # Create new <select> list with <option>s
  my $form_element_name = $options{'prefix'} ? 
    joindref($options{'prefix'}, $field->{'name'} ) : $field->{'name'};
  
  # Get <option>s for <select> list
  my $options = $field->select_options( $record, $display_fieldname );
  my $select = html_tag('select', { 'name' => $form_element_name }, @$options);
  
  # Inerpret and return <select>
  return $select->interpret();
}

# @$options = $field->select_options($record, $display_field_name)
sub select_options {
  my($field, $record, $display_field_name) = @_;
  
  # add info for 'First' option
  my $rank_info = [
    { 'id' => '', 'label' => 'First', 'rank' => 0 }
  ];
  
  # Get all records from $record's class
  my $records = $record->records();
  debug( 'Field::SortOrder', '$records = ', $records );
  
  # Extract relavent information from records
  local $checker = $field->{'name'};
  Data::Sorting::sort_in_place($records, sub { $_[0]->value( $checker ) } );
  
  my $class_record;
  foreach $class_record ( @$records ) {
    if ( $class_record->value('id') == $record->value('id') ) {
      $rank_info->[ $#rank_info ]{'selected'} = 1;
      $rank_info->[ $#rank_info ]{'rank'} = $field->value($record);
    } else {
      my $info = {
	'label' => $class_record->readable( $display_field_name ),
	'id' => $class_record->value( 'id' ),
	'rank' => $class_record->value( $field->{'name'} )
      };
      push @$rank_info, $info;
    }
  }
  
  # sort info by rank
  debug( 'Field::SortOrder', '$rank_info = ', $rank_info );
  
  # convert in to <option>s
  my $options = [];
  while ( scalar( @$rank_info ) ) {
    my $info = shift (@$rank_info);
    my $args = {};
    
    # Calculate the value of the <option>
      
    if ( $info->{'selected'} ) {
      $args->{'value'} = $info->{'rank'};
      $args->{'selected'} = undef;
    } elsif ( ! scalar( @$rank_info ) ) {
      $args->{'value'} = $info->{'rank'} + 10;
    } else {
      $args->{'value'} = ( $info->{'rank'} + $rank_info->[0]{'rank'} ) / 2; 
    }
    
    # Name the option
    $args->{'label'} = $info->{'label'};
    
    push @$options, html_tag( 'option', $args );
  }
  
  return $options;
}

1;