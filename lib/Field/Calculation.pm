### Field::Calculation provides a field whose value is calculated on demand

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Jeremy   Jeremy G. Bishop    (jeremy@evolution.com)

### To Do
  # Maybe rename value() to readable() to prevent data-cycle problem?

### Change History
  # 1998-05-29 Tweaked Field::Definition interface to use Selects.
  # 1998-05-29 Switched to use of Script::Evaluate package instead of Script.
  # 1998-05-?? Map edit to display method; provide scoping for calc temp vars
  # 1998-01-26 Added definition fields.
  # 1997-11-28 Added a constant has_value method in an attempt to stop cycles
  # 1997-11-19 Updated for four-oh.
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-06-07 Overhaul. -Simon
  # 1997-04-20 Touchups.
  # 1997-03-29 Touchups.
  # 1997-03-17 Built. -Simon

package Field::Calculation;

use Field;
push @ISA, qw( Field );

Field::Calculation->add_subclass_by_name( 'calculated' );

use Err::Debug;
use Data::DRef;
use Data::Sorting;
use Script::Evaluate qw( runscript );

### BASIC FIELD OPERATIONS: VALUE, FLATTEN

# $field->init
sub init {
  my ($field) = @_;
  $field->{'show'} = 0 unless (defined $field->{'show'});
  $field->{'expr'} = '' unless (defined $field->{'expr'});
  $field->SUPER::init();
}

# $data = $field->sql_datatype
sub sql_datatype { }

sub has_value { 1; }

# $html = $field->edit($record, %options)  => display
sub edit { (shift)->display( @_ ); }

sub value {
  my ($field, $record) = @_;
  debug 'field_calculation', "calculating $record $field->{'name'}";
  local $Root->{'-record'} = $record;
  local $Root->{'-calc_temp'};
  my $script = $field->script;
  my $val = $script->interpret;
  debug 'field_calculation', "done calculating $record $field->{'name'}";
  return $val;
}

sub script {
  my $field = shift ;
  unless ( $field->{'script'} ) {
    $field->{'script'} = Script::Parser->new->parse( $field->{'expr'} );
    debug 'field_calculation', $field->{'name'}, 'script is', "$field->{'script'}", $field->{'script'};
  }
  return $field->{'script'};
}

=head1 Field::Calculation

Provides a field whose value is calculated on demand

=head1 Synopsis

=head1 Reference

=over 4

=item $field->init

=item $field->edit($record, %options) : $html

=item $field->sql_datatype()  : $type

=item $field->value( $record ) : $value

=item $field->script() : $text

=back

=head1 Caveats and Upcoming Changes

=head1 This is Free Software

Copyright 1996, 1997 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut

### Field::Calculation::Definition

package Field::Calculation::Definition;

use Field;
@ISA = qw[ Field::Definition ];

use vars qw[ $fields $fieldorder $init];

Field::Calculation::Definition->Field::Definition::add_subclass_by_name('calculated');

sub init {
  return if ( $init ++ );
  Field::Calculation::Definition->set_fields_from_def([
    {
      'name' => 'title',
      'type' => 'text',
      'title' => 'Title',
      'hint' => '',
    },
    {
      'name' => 'align',
      'type' => 'select',
      'list' => [ 'right', 'left' ],
      'title' => 'Display Alignment',
      'default' => 'left',
      'require' => 1,
      'title' => 'Display Alignment',
      'hint' => '',
    },
    {
      'name' => 'show',
      'type' => 'select',
      'list' => [ 'yes', 'no' ],
      'default' => 'no',
      'require' => 1,
      'title' => 'Show in Detail View',
    },
    {
      'name' => 'expr',
      'type' => 'textarea',
      'title' => 'Expression',
    },
  ]);
}

1;

=pod

=head1 Field::Calculation::Definition

=cut