### Record - a first class class

### Copyright Evolution Online Systems 1997

### Contributors
  # Jeremy Bishop <jeremy@evolution.com>
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Piglet   E.J. Evans (piglet@evolution.com)

### Change History
  # 1998-05-28 Added searchable=no handling for fields
  # 1998-05-20 Set target=main, etc. for detail_link unless app_is_current.  -Piglet
  # 1998-04-28 Modified *_from_definition logic to fix scoping issues.
  # 1998-03-18 Patched flat_fields to skip empty column definitions.
  # 1998-03-10 Added unsaved status.
  # 1998-03-03 Replaced $r->class with ref($r); added ensure_source_exists().
  # 1998-03-02 Patch to class_from_name().
  # 1998-02-27 Added new Record->class_from_name interface. -Simon
  # 1998-01-25 Minor reorg and cleanup. -Simon
  # 1998-01-23 moved get and error handling methods to fieldset - Jeremy
  # 1998-01-22 New raise_errorlevel method extracted from update cycle. -Simon
  # 1997-12-05 Split FieldSet into a separate package.
  # 1997-11-26 Added edit_criteria to support searching
  # 1997-11-25 Added ID to silent list.
  # 1997-11-03 Incorporated fieldset functionality, removed fieldset object
  # 1997-10-21 Added subs fieldset and dbadaptor, first good query
  # 1997-10-20 first successfull compile
  # 1997-10-20 Folded in code from datastore & fieldtags
  # 1997-10-10 Build - Jeremy

package Record;

$VERSION = 2.00_1998_03_03;

use FieldSet;
push @ISA, qw( FieldSet );

use DBAdaptor;

use strict;
use Carp;
use Err::Debug;
use Data::DRef;
use Text::PropertyList;
use Text::Escape;

### Dynamic Class Generation

# $subclass = Record->class_from_name($name)
sub class_from_name {
  my $package = shift;
  my $name = shift;
  my $resource = WebApp::Resource::Datastore->new_from_name($name);
  die( "Could not find Datastore '$name'") unless ( $resource );
  return $resource->record_class();
}

# $classname = Record::Subclass->set_from_definition($definition);
sub set_from_definition {
  my ($package, $definition) = @_;
  
  eval '@' . $package . '::ISA = qw[ Record ]';
  
  $package->dbadaptor( DBAdaptor->newfromdef($definition->{'dbadaptor'}) );
  $package->set_fields_from_def( $definition->{'fields'} );
  $package->default_fieldname( $definition->{'detail'} );
}

### Datastore Interface

# $html_text = $record->link( $fieldname, %options );
sub link {
  my($record, $fieldname, %options) = @_;
  # warn "DL: \$r->link for $fieldname\n";
  $record->detail_link( $record->display( $fieldname, %options ) );
}

# $html_str = $record->detail_link;
# $html_str = $record->detail_link( $display_str );
sub detail_link {
  my($record, $display) = @_;
  # warn "DL: \$r->detail_link\n";
  
  my $url;
  if ( $record->datastore->app_is_current ) {
    $url = $record->datastore->self_url . '/' . $record->{'id'};
  } else {
    $url = $record->datastore->app_url . '/frameset/' . $record->datastore->{'-name'} . '.' . $record->datastore->subclass_name . '/' . $record->{'id'};
  }
  $display ||= $record->display( $record->default_fieldname );
  
  return '<a href='. escape('url qhtml', $url) . ( $record->datastore->app_is_current ? '' : ' target=main') . '>' . $display  . '</a>';
}

# $datastore = $package->datastore or $record->datastore;
  # or pass a value to set it
sub datastore {
  my $record = shift;
  my $package = ( ref($record) || $record );
  if ( scalar @_ ) {
    my $datastore = shift;
    eval '$' . $package . '::datastore = $datastore';
  }
  return eval( '$' . $package . '::datastore' );
}

### DBAdaptor Interface

# $dbadaptor = $package->dbadaptor or $record->dbadaptor;
  # or pass a value to set it
sub dbadaptor {
  my $widget = shift;
  my $package = ( ref($widget) || $widget );
  if ( scalar @_ ) {
    my $dbadaptor = shift;
    eval '$' . $package . '::dbadaptor = $dbadaptor';
  }
  return eval( '$' . $package . '::dbadaptor' );
}

# Record::Subclass->create_data_source;
sub create_data_source {
  my($package) = @_;
  $package->dbadaptor->create_source( $package );
}

# Record::Subclass->ensure_source_exists;
sub ensure_source_exists {
  my($package) = @_;
  $package->dbadaptor->ensure_source_exists( $package );
}

# @$dbfields = Record::Subclass->flat_fields;
sub flat_fields {
  my $record = shift;
  return [ grep { $_ } ( $record->call_on_each_field( 'flat_fields') ) ];
}

### Class Data Access - supplements numerous methods inherited from FieldSet.

# $default_fieldname = Record::Subclass->default_fieldname;
sub default_fieldname {
  my $self = shift;
  my $package = ( ref($self) || $self );
  if ( scalar @_ ) {
    my $fieldname = shift;
    eval '$' . $package . '::default_fieldname = $fieldname';
  }
  my $fieldname = eval( '$' . $package . '::default_fieldname' );
  return ( ($fieldname && length($fieldname)) ? $fieldname : 'name' );
}

# @fieldnames = Record::Subclass->searchfields; 
sub searchfields {
  my $self = shift;
  my @fieldnames;
  
  my $field;
  foreach $field ( @{ $self->fieldorder } ) {
    push ( @fieldnames, $field->{'name'} ) 
	    if ( $field->{'searchable'} and $field->{'searchable'} !~ /no/i );
  }
  
  return @fieldnames;
}

### Instantiation

# $record = Record::Subclass->new;
sub new {
  my $package_or_record = shift;
  my $package = ref( $package_or_record ) || $package_or_record;
  return bless {}, $package;
}

# $record = Record::Subclass->new_record;
sub new_record {
  my $package = shift; 
  
  my $record = $package->new;
  $record->default;
  $record->status('new');
  
  return $record;
}

# $record = Record::Subclass->record_by_id( $id )
sub record_by_id {
  my $package = shift; 
  my $id = shift; 
  
  my $values = $package->dbadaptor->fetchbyid( $id );
  
  return unless $values;
 
  my $record = $package->new;
  $record->unflatten($values);
  $record->status('from db');
  
  return $record;
}

# @$records = Record::Subclass->records( @$criteria );
sub records {
  my($package, $criteria) = @_;
  
  my @rows = ref $criteria ? $package->dbadaptor->fetch($criteria) 
			   : $package->dbadaptor->fetchall;
  
  # warn "\n\$rows = $rows\n"; # .  asDictionary( $rows );
  
  my @records;
  
  my $row;
  foreach $row (@rows) {
    my $record = $package->new;
    $record->unflatten( $row );
    $record->status('from db');
    push @records, $record;
  }
  
  return \@records;
}

### Record Life Cycle

# $record->save_record;
sub save_record {
  my ($record) = @_;
  
  my $isnew = ( $record->{'id'} eq 'new' or $record->status eq 'new' or $record->status eq 'unsaved'  );
  my $row = $record->flatten;
  
  if ( $isnew ) {
    $record->dbadaptor->insert( $row );
  } else {
    $record->dbadaptor->update( $row );
  }
  
  $record->call_on_each_field_with_self( 'cleanup' );
  $record->status('saved');
  
  return;
}

# $record->delete_record;
sub delete_record {
  my $record = shift;
  
  $record->call_on_each_field_with_self( 'deleteprep' );
  $record->dbadaptor->deleterecordbyid( $record->{'id'} );
  $record->status('deleted');
  
  return;
}

1;

__END__

=head1 Record

Record is the abstract superclass for persistant database objects.

Record inherits from FieldSet and uses DBAdaptor.

=head2 Dynamic Class Generation

=over 4

=item $subclass = Record->package_from_definition($name, $definition)

=back

=head2 Datastore Interface

=over 4

=item $datastore = $package->datastore or $record->datastore;

=back

=head2 DBAdaptor Interface

=over 4

=item $dbadaptor = $package->dbadaptor or $record->dbadaptor;

=item Record::Subclass->create_data_source;

=item @$dbfields = Record::Subclass->flat_fields;

=back

=head2 Class Data Access 

These methods supplements numerous ones inherited from FieldSet.

=over 4

=item $default_fieldname = Record::Subclass->default_fieldname;

=item @fieldnames = Record::Subclass->searchfields; 

=back

=head2 Instantiation

=over 4

=item $record = Record::Subclass->new;

=item $record = Record::Subclass->new_record;

The values of the returned record object are the defaults (if any) of the corresponding record class.

=item $record = Record::Subclass->record_by_id( $id )

A record object is insantiated from values supplied by the record class's DBAdaptor. If an invalid id is supplied, the undef value is returned.

=item @$records = Record::Subclass->records( @$criteria );

A list of record objects is returned containing records that match the supplied criteria. If no criteria are supplied, the default criteria of the record class are used; Absent default criteria, all records will be returned.

=back

=head2 Record Life Cycle

=over 4

=item $record->save_record;

The record will be commited to the storage device and a true value will be returned, unless the record contains errors (invalid data), in which case a false value will be returned.

=item $record->delete_record;

The record will be deleted from the storage device.

=back

=cut

