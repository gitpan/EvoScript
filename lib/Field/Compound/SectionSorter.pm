### Field::Compound::SectionSorter.pm 
  # Ick...

### Copyright 1997, 1998 Evolution Online Systems

### Developed by Evolution Online Systems, Inc.
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)
  # Piglet   E.J. Evans    (piglet@evolution.com)
  # Del      G. Del Merritt    (dmerritt@intranetics.com)

### Change History
  # 1998-05-06 Don't use character entities (&nbsp;) for select lists. -Del
  # 1998-04-23 Include setDRef in Data::Dref's use. -Del
  # 1998-04-16 *Total* rebuild in v4 libs -Jeremy
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-08-10 Removed status=current requirement. -Simon
  # 1997-07-** Much work -Jeremy
  # 1997-07-03 Debugged & cleaned up.  -Piglet
  # 1997-06-26 Built. -Jeremy

package Field::Compound::SectionSorter;

use Field::Compound;
@ISA = qw[ Field::Compound ];

Field::Compound::SectionSorter->add_subclass_by_name( 'sectionsorter' );

use Data::DRef qw( joindref getDRef setDRef );
use Err::Debug qw( debug );
use Script::HTML::Tag qw( html_tag );

### Display interface

sub compound_readable {
  return 'foo';  
}

sub compound_display {
  return 'bar';  
}

sub init {
  my($field) = @_;

  # debug( 'Field::Compound::SectionSorter',
  #   [ 'SectionSorter field BEFORE init:' ],
  #   $field
  # );

  $field->SUPER::init();

  # debug( 'Field::Compound::SectionSorter',
  #   [ 'SectionSorter field AFTER init:' ],
  #   $field
  # );

  return;
}

### Subfield Instantiation

# %@$subfield_definitions = $field->subfield_definitions();
sub subfield_definitions {
  my $field = shift;
  return [
    {
      'name' => 'item',
      'type' => 'sortorder',
      'title' => 'Order',
    },
    {
      'name' => 'section',
      'type' => 'relation',
      'relation_to' => $field->{'relation_to'},
    },
  ];
}

### Edit Cycle

# $html_form_element = $field->edit_form( $record, %options );
sub compound_edit {
  my ( $field, $record, %options ) = @_;
  
  # Create an ordered list of section records, $sections

  my $sections = $field->subfield('section')->related_records();
  my $sort_field = $field->{'section_order_field'};
  $sections = [ 
    sort { $a->{ $sort_field } <=> $b->{ $sort_field } } @$sections
  ];

  # debug( 'Field::Compound::SectionSorter',
  #  [ '$sections in compound_edit:' ],
  #  $sections
  # );

  # Build a couple handy data srtuctures:
  # %section index is a hash of $section_id => rank, used later for sorting
  # $option_list is a list of information to be used for the generation of html
  # option tags. At this poin the 'First' option for each section is added to
  # the option list

  my %section_index;
  my $rank;
  my $option_list = [];
  foreach $section ( @$sections ) {
    $section_index{ $section->{'id'} } = $rank++;
    push @$option_list, {
	'label'      => $section->readable( $field->{'section_title_field'} )
		      . ' - First',
	'section'    => $section->{'id'},
	'sortorder' => 0,
    };
  }

  # debug( 'Field::Compound::SectionSorter',
  #   [ '%section_index in compound_edit:' ],
  #   \%section_index
  # );
  
  # Strip relavent information from records, add to option list

  my $indent = '.' x 4;
  
  foreach $class_record ( @{ $record->records() } ) {
    my $option = {
	'label'      => 
	  $indent . $class_record->readable($field->{'item_title_field'}),
	'section'    => 
	  $class_record->{ $field->subfield('section')->{'name'} },
	'sortorder' => 
	  $class_record->{ $field->subfield('item')->{'name'} },
    };
    $option->{'selected'} = 1
      if ( $record->{'id'} == $class_record->{'id'} );
    if ( $option->{'section'} and $option->{'sortorder'} ) {
      push @$option_list, $option;
    }
  }
  
  # Sort the record info by both section and sortorder
  
  # debug( 'Field::Compound::SectionSorter',
  #   [ '$option_list before sort in compound_edit:' ],
  #   $option_list
  # );
  
  $option_list = [ 
    sort {
      # my $warning = "\$a in sort in SectionSorter:\n";
      # for $key ( keys %$a ) {$warning .= "  $key = $a->{$key},\n"}
      # warn "$warning";
      # warn "\$a->{'section'} = '$a->{'section'}', \$b->{'section'} = '$b->{'section'}'";
      if ( $a->{'section'} != $b->{'section'} ) {
	return $section_index{ $a->{'section'} } 
	    <=> $section_index{ $b->{'section'} };
      } else {
	return $a->{'sortorder'} <=> $b->{'sortorder'};
      }
    } @$option_list
  ];

   # debug( 'Field::Compound::SectionSorter',
   #   [ '$option_list after sort in compound_edit:' ],
   #   $option_list
   # );

  # Convert the record info to html option tags

  my $options = $field->build_option_tags( $option_list );

  debug( 'Field::Compound::SectionSorter',
    [ '$options in compound_edit:' ],
    $options
  );

  # Add the first option to the list

  my $text = $field->{'required'} ? 'Select One' : 'None';
  push @$options, html_tag( 'option', { 'value' => '', 'lable' => $text } );

  my $form_name;

  if ($options{'prefix'}) {
    $form_name = joindref($options{'prefix'}, $field->{'name'} );
  } else {
    $form_name = $field->{'name'};
  }

  my $select = html_tag('select', {'size'=>1, 'name'=>$form_name}, @$options);

  return $select->interpret();
}

# @$option_tags = $field->build_option_tags( @%$record_infos );
sub build_option_tags {
  my ( $field, $infos ) = @_;

  my $options = [];
  while ( scalar( @$infos ) ) {
    my $info = shift( @$infos );    

    # If the current $info is the current record value, set the last option to
    # it's value. We know that there will always be a last option in this case
    # because of the 'first' options we put at the begining of each section.

    if ( $info->{'selected'} ) {
      my $last_option = $options->[ -1 ];
      $last_option->{'value'} =
	$info->{'section'} . '--' . $info->{'sortorder'};
      $last_option->{'selected'} = undef;
    }

    # If this is the last $info in the list or it it's the last $info in it's
    # section, create an option with a sort-order to 100 higher than the $info
    # value and push it on to the list @$options.

    elsif (! scalar(@$infos) or $infos->[0]{'section'} != $info->{'section'}) {
      my $option = {
	'label' => $info->{'label'},
	'value' => $info->{'section'} . '--' . ($info->{'sortorder'} + 100),
      };
      push @$options, $option;
    }

    # Otherwise, we can assume that the next item in @$infos is in the same
    # section as the current $info. In this case, create an option with the
    # sort-order set to an average of the current $info and the next $info and
    # push it on to the list @$options.

    else {
      my $sortorder = ( $infos->[0]{'sortorder'} + $info->{'sortorder'} ) / 2;
      my $option = {
	'label' => $info->{'label'},
	'value' => $info->{'section'} . '--' . $sortorder,
      };
      push @$options, $option;
    }
  }

  return [ map { html_tag('option', $_) } @$options ];
}

# $field->update($record, $updates);
sub update {
  my ( $field, $record, $updates ) = @_;
  my $value = getDRef( $updates, $field->{'name'} );
  if ( $value and ( $value =~ /--/ ) ) {
    my ( $section, $sortorder ) = split( '--', $value );
    setDRef( $record, $field->subfield('item')->{'name'}, $sortorder );
    setDRef( $record, $field->subfield('section')->{'name'}, $section );
  }
  return;
}

1;
