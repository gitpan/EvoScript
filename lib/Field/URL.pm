### Field::URL stores and displays links.

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 1998-06-11 Added use of URI::Heuristic for expansions.
  # 1998-06-11 Now using $field->value($record, $new_value) interface. -Simon
  # 1997-11-17 move to v4. -Jeremy
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-07 Overhaul.
  # 1997-03-17 Refactored & standardized; added standard header. -Simon

package Field::URL;

use Field;
@ISA = qw[ Field::Text ];

Field::URL->add_subclass_by_name( 'url' );

use Script::HTML::Tag;

use URI::Heuristic qw(uf_urlstr);

### INSTANTIATION

# $field->init
sub init {
  my ($field) = @_;
  $field->{'length'} = 255 unless defined( $field->{'length'} );
  $field->SUPER::init();
  return;
}

### DISPLAY RECORD

# $html = $field->display($record, %options)
sub display {
  my($field, $record, %options) = @_;
  
  my $value = $field->value( $record );
  return $value unless $field->has_href( $record );
  
  html_tag( 'a', {'href' => $value}, $value)->interpret;
}

sub option_title {
  my ( $field, %options ) = @_;
  my $title = $field->title() || $field->name();
  return $title . ' (link)';
}

### VALIDATION

# $field->update( $record, %$updates );
sub update {
  my( $field, $record, $updates ) = @_;
  $field->SUPER::update( $record, $updates );
  $field->normalize($record);
}

# $field->normalize($record);
  # Update the record to contain the canonical expression for this field type
sub normalize {
  my ($field, $record) = @_;
  $field->value( $record, uf_urlstr( $field->value( $record ) ) );
}

# $field->validate($record);
sub validate {
  my ($field, $record) = @_;
  
  my($level, $messages) = ('none', []);
  if( defined $field->value($record) and ! $field->has_href($record) ){
    $level = 'error';
    $messages = [
      $field->title() . ' does not appear to contain a valid URL.'
    ];
  }
  $field->totalvalidate(
    $level, $messages,
    $field->SUPER::validate($record)
  );
}

# $flag = $field->has_href($record);
  # Does the record contains a reasonable URL? Don't try to be very picky.
sub has_href {
  my ($field, $record) = @_;
  my $value = $field->value( $record );
  $value =~ /\A\w+\:\S+\Z/ ? 1 : 0;
}

1;