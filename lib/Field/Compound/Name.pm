### Field::Compound::Name.pm - First, Middle, Last name compound field

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-05-03 Changed edit_title.
  # 1998-04-23 Added edit_title method for compound edits. -Simon
  # 1997-11-07 Rebuilt in v4 libraries -Jeremy
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-07 Overhaul. -Simon
  # 1997-04-20 Moved compound fields into field::compound::*
  # 1997-03-17 Refactored & standardized; added standard header. -Simon
  # 1997-03-16 not a lame .pm. -Jeremy

package Field::Compound::Name;

use Field::Compound;
@ISA = qw[ Field::Compound ];

Field::Compound::Name->add_subclass_by_name( 'name' );

use Data::DRef;

### OPTION HANDLING

# $field->next_option( @$path, %$options )
sub next_option {
  my($field, $path, $options) = @_;

  my $item = shift( @$path );

  if ( $item eq 'order' ) {
    $options->{'order'} = shift( @$path );    
  } else {
    unshift( @$path, $item );
    $field->SUPER::next_option( $path, $options ); 
  }

  return;
}

### VIEW

# $text = $field->compound_readable($record, %options);
sub compound_readable {
  my($field, $record, %options) = @_;

  # warn ( "name is: '" . join(' ', $field->value( $record ) ) . "'" );
  my($first, $middle, $last) = $field->value( $record );

  my $name;
  if ($options{'order'} and ($options{'order'} eq 'lastfirst')) {
    if ( $last and $first )  {
      $name = "$last, $first";
    } elsif ( $last ) {
      $name = $last;
    } elsif ( $first ) {
      $name = $first;
    }
  } elsif ($options{'order'} and ($options{'order'} eq 'lastfirstmiddle')) {
    if ( $last and $first and $middle ) {
      $name = "$last, $first $middle";
    } elsif ( $first and $last ) {
      $name = "$last, $first";
    } elsif ( $last ) {
      $name = $last;
    } elsif ( $first ) {
      $name = $first;
    }
  } elsif ($options{'order'} and ($options{'order'} eq 'firstlast')) {
    if ( $last and $first )  {
      $name = "$first $last";
    } elsif ( $last ) {
      $name = $last;
    } elsif ( $first ) {
      $name = $first;
    }
  } else {
    if ( $last and $first and $middle ) {
      $name = "$first $middle $last";
    } elsif ( $first and $last ) {
      $name = "$first $last";
    } elsif ( $last ) {
      $name = $last;
    } elsif ( $first ) {
      $name = $first;
    }
  }

  return $name;
}

# @fieldnames = $field->option_list();
sub option_list {
  my $field = shift();
  my $name = $field->name(); 
  return (
    $name,
    joindref( $name, 'order', 'lastfirst' ),
    joindref( $name, 'order', 'lastfirstmiddle' ),
    joindref( $name, 'order', 'firstlast' ),
    joindref( $name, 'subfield', 'first' ),
    joindref( $name, 'subfield', 'middle' ),
    joindref( $name, 'subfield', 'last' )
  );
}

# $text = $field->option_title( %options );
sub option_title {
  my ( $field, %options ) = @_;
  my $subtitle;
  if ( defined $options{'order'} ) {
    my $order = $options{'order'};
    if ( $order eq 'firstlast' ) {
      $subtitle = 'first, last';
    } elsif ( $order eq 'lastfirst' ) {
      $subtitle = 'last, first';
    } elsif ( $order eq 'lastfirstmiddle' ) {
      $subtitle = 'last, first, middle';
    }
  } elsif ( defined $options{'subfield'} ) {
    my $name = $options{'subfield'}->{'-name'};
    if ( $name eq 'last' ){
      $subtitle = 'last';
    } elsif ( $name eq 'middle' ) { 
      $subtitle = 'middle';
    } elsif ( $name eq 'first' ) {
      $subtitle = 'first';
    }
  }
  $subtitle ||= 'first, middle, last';
  return $field->title() . ' (' . $subtitle . ')';
}

# $text = $field->compound_display($record, %options);
sub compound_display {
  my($field, $record, %options) = @_;
  my $name = $field->compound_readable($record, %options);
  return $field->escape( $options{'escape'}, $name );
}

# $text = $field->compound_edit($record, %options);
sub compound_edit {
  my($field, $record, %options) = @_;

  return( $field->subfield('first')->edit( $record, 'formsize' => '16', 'prefix' => $options{'prefix'})
	.  Script::HTML::Escape::nonbreakingspace()
	.  $field->subfield('middle')->edit( $record, 'formsize' => '4', 'prefix' => $options{'prefix'})
	.  Script::HTML::Escape::nonbreakingspace()
	.  $field->subfield('last')->edit( $record, 'formsize' => '16', 'prefix' => $options{'prefix'})
  );
}

# $html = $field->edit_title($record, %options);
sub edit_title {
  my ($field, $record, %options) = @_;
  $field->title( $record, %options )  .
  $field->escape( $options{'escape'}, 
    '(' . join(', ', map { $_->{'title'} } @{ $field->subfieldorder } ) . ')'  
  ) . ':';
}

# $text = $field->compound_search($record, %options);
sub compound_search {
  my($field, $record, %options) = @_;
  return $field->compound_edit( $record, %options )
}

### SUBFIELD INSTANTIATION

# %@$subfield_definitions = $field->subfield_definitions();
sub subfield_definitions {
  return( [
    {
      'name' => 'first',
      'type' => 'text',
      'title' => 'First',
      'length' => '64',
      'formsize' => '40',
    },
    {
      'name' => 'middle',
      'type' => 'text',
      'title' => 'MI',
      'length' => '64',
      'formsize' => '40',
    },
    {
      'name' => 'last',
      'type' => 'text',
      'title' => 'Last',
      'length' => '64',
      'formsize' => '40',
    }
  ] );
}

### VALIDATION

# ($level, $msgs) = $field->require($record)
sub require {
  my ($field, $record) = @_;
  my($first, $middle, $last) = $field->value($record);

  return('error', [$field->title . ' requires a value'])
    if(($middle && !($first && $last)) || !($first || $middle || $last));

  return('none',[]);
}

1;
