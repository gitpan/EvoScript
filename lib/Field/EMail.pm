### Field::EMail.pm 
  # email text field

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### Change History
  # 19971117 move to v4
  # 19970924 IntraNetics97 Version 1.00.000
  # 19970607 Overhaul. -Simon
  # 19970317 Refactored & standardized; added standard header. -Simon

package Field::EMail;

use Field::Text;
@ISA = qw[ Field::Text ];

Field::EMail->add_subclass_by_name( 'email' );

use Script::HTML::Tag;

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

  my $href = $field->value( $record );

  return $field->readable($record)
      unless( $href = $field->valid_href( $href ) );
  
  html_tag( 'a', {'href' => $href}, $field->readable($record))->interpret;
}

# $href = $field->addr( $record )
 # This function returns undef if it can't construct a vaild href
sub addr {
  my($field, $record) = @_;
  my $href = $field->value( $record );
  return unless $field->valid_href( $href );
  return $href; 
}

# $href = $field->valid_href( $href )
 # This function returns undef if it can't construct a vaild href
sub valid_href {
  my($field, $href) = @_;
  return unless length( $href ); 
  return unless ($href =~ /\w+\@\w+/);
  return "mailto:$href"; 
}

### VALIDATION

sub validate {
  my ($field, $record) = @_;
  
  my($level, $messages) = ('none', []);

  unless( $field->valid_href( $field->value( $record ) ) ){
    $level = 'error';
    $messages = [
      $field->title() . ' does not appear to contain a valid e-mail address.'
    ];
    warn "I don't like it!!\n";
  }

  return $field->totalvalidate(
	    $level, $messages,
	    $field->SUPER::validate($record)
	 );
}

sub option_title {
  my ( $field, %options ) = @_;
  my $title = $field->title() || $field->name();
  return $title . ' (link)';
}

1;