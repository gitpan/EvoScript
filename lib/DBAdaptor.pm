### The DBAdaptor abstract class models a connection to a record storage system
  # Create a DBAdaptor by providing a datasource name and a unique table name,
  # then use the create, read, update, delete interface for flat-hash records.
  # 
  # DBAdaptor subclasses exist for:
  # - SQL DBMS tables (Win32::ODBC, MySQL, DBI)
  # - Flat files (delimited text, PropertyList)
  # - Possible future addition: Database files (dbm, etc.)

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License
  #
  # Development by...
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Piglet   E.J. Evans (piglet@evolution.com)

### Change History
  # 1998-05-06 Optimized criteria constructed in fetchbyid.
  # 1998-04-18 Use of sort_in_place rather than sort_by_dref. -Simon
  # 1998-03-31 Corrected typo in base update method. -Del
  # 1998-03-02 Added ensure_source_exists method.
  # 1997-11-16 Added datasource registry
  # 1997-11-06 Addidional mucking with interface.
  # 1997-11-04 Updated to use SubclassFactory; reviewed code and added comments
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-09-03 Fixed the same typo in isstringinlist_criteria.
  # 1997-09-02 Fixed typo in twiddle_criteria.
  # 1997-08-10 Added isequal as synonym for equals to keep up with sql criteria
  # 1997-02-20 General cleanup; record data moved to datastore.pm.
  # 1997-02-01 Rehashed existing code into adaptor subclasses.
  # 1997-01-03 Added ()s around or'd sets of criteria
  # 1997-10-15 Switched from msql to mysql, enhanced criteria.
  # 1997-10-08 Added database selection for insert (if not loaded first).
  # 1997-10-07 Query optimization for 'or' clauses and regex matching.
  # 1997-10-03 Enhanced client-side/server-side criteria handling.
  # 1996-09-08 Moved to Evo::msql.
  # 1996-09-06 First build. -Simon

package DBAdaptor;

use Carp;
use Text::PropertyList;

### Instantiation

# Class::NamedFactory %DBAdaptorClasses
use Class::NamedFactory;
push @ISA, qw( Class::NamedFactory );
use vars qw( %DBAdaptorClasses );
sub subclasses_by_name { \%DBAdaptorClasses; }

# $dba = DBAdaptor->newfromdef( $hashref );
sub newfromdef {
  my $package = shift;
  my $def = shift;
  return $package->new_from_info( $def->{'datasource'}, $def->{'name'} );
}

# $dba = DBAdaptor->new_from_info( $source, $name );
sub new_from_info {
  my ($package, $source, $name) = @_;
  
  # warn "ds $source \n";
  my $ds_info = DBAdaptor->datasource_info( $source );
  
  # warn "DBA classes are " . astext( \%DBAdaptorClasses );
  
  my $subclass = $package->subclass_by_name($ds_info->{'type'});
  croak( "unknown type of DBAdaptor '$ds_info->{'type'}'" ) unless $subclass;
  
  my $dba = $subclass->new( $ds_info->{'source'}, $name );
  return $dba;
}

# $dba = DBAdaptor->new();
  # Create an empty DBAdaptor. Here so we can add any global whatnot later on.
sub new {
  my $package = shift;
  my $dba = {};
  bless $dba, $package;
}

### Datasource Information
  # Is this an independant class, or a class interface of DBAdaptors?

use vars qw( %Datasources );

# DBAdaptor->add_datasource( $name, $info );
sub add_datasource {
  my ($package, $sourcename, $sourceinfo) = @_;
  $Datasources{ $sourcename } = $sourceinfo;
}

# %$ds_info = DBAdaptor->datasource_info( $sourcename );
sub datasource_info {
  my ($package, $source) = @_;
  
  $source = $Datasources{ $source } if ( exists $Datasources{ $source } );
  
  ($adaptor_type, $source) = split(/\:/, $source, 2);
  # warn "a $adaptor_type ds $source \n";
  
  return { 'type' => $adaptor_type, 'source' => $source };
}

### Creation and Deletion of Remote Source

# $flag = $dba->source_exists
sub source_exists { croak "abstract operation"; }

# $dba->create_source( $RecordClass )
  # Create the remote data source for a datastore
sub create_source { croak "abstract operation"; }

# $dba->delete_source
  # Delete the remote data source
sub delete_source { croak "abstract operation"; }

# $dba->recreate_source
  # Delete the source, than create it again
sub recreate_source { 
  my $dba = shift;
  $dba->delete_source if ( $dba->source_exists );
  $dba->create_source( @_ );
}

# $dba->ensure_source_exists( $RecordClass )
  # Create the remote data source for a datastore if it does not already exist
sub ensure_source_exists {
  my $dba = shift;
  $dba->create_source( @_ ) unless $dba->source_exists;
}

### Field Information
  # We keep track of remote field types: text(len), integer, ...

# $fielddef = $dba->fields();
  # Get the current field defs (retrieve them from the datasource if needed)
sub fields {
  my $dba = shift;
  $dba->{'fields'} = $dba->getfields unless defined $dba->{'fields'};
  return $dba->{'fields'};
}

# $fielddef = $dba->getfields();
  # Retrieve the current field definition from the datasource
sub getfields { croak "abstract operation"; }

### Record Access

# $count = $dba->count_records
sub count_records {
  my $dba = shift;
  return scalar ( $dba->fetchall );
}

# @$records = $dba->fetchall;
  # Retrieve all of the records from the data source
sub fetchall { croak "abstract operation"; }

# @$records = $dba->fetch($criteria, $ordering);
  # Retrieve records matching criteria in given order
sub fetch {
  my($dba, $criteria, $ordering) = @_;
  
  my $rows;
  @$rows = $dba->fetchall;
  
  $dba->apply_criteria($rows, $criteria) if ($criteria);
  $dba->apply_order($rows, $ordering) if ($ordering);
  
  return @$rows;
}

# $records = $dba->fetchbyid($id);
  # Retrieve a specific record by id
sub fetchbyid {
  my ($dba, $id) = @_;
  my $criteria = Data::Criteria->new_from_def(
		  { 'key' => 'id', 'match' => 'isequal', 'value' => $id } );
  my @records = $dba->fetch($criteria);
  
  # warn astext( $records[0] );
  
  return $records[0];
}

### Record Updates

# $dba->update( $record );
sub update {
  my $dba = shift;
  my $record = shift;
  
  $dba->deleterecordbyid( $record->{'id'} )
	  unless ($record->{'id'} eq 'new' or $record->{'--status'} eq 'new');
  
  $dba->insert( $record );
}

# $dba->insert($record);
  # Append or insert a new record
sub insert { croak "abstract operation"; }

# $dbadaptor->deleterecordbyid($id);
sub deleterecordbyid { croak "abstract"; }

# $dba->overwrite( @$records );
sub overwrite {
  my $dba = shift;
  my $records = shift;
  
  $dba->delete_all_records();
  $dba->insert_records( @$records );
}

# $dbadaptor->delete_all_records;
sub delete_all_records { croak "abstract"; }

# $dba->insert_records( @$records );
sub insert_records {
  my $dba = shift;
  my $records = shift;
  
  foreach $rec ( @$records ) {
    $dba->insert( $rec );
  }
}

### Sorting and Searching

use Data::Criteria;

# $dba->apply_criteria($records, $criteria);
sub apply_criteria {
  my($dba, $records, $criteria) = @_;
  
  @$records = match_criteria( $criteria, $records );
}

use Data::Sorting;

# $dba->apply_order($records, $ordering);
sub apply_order {
  my($dba, $records, $ordering) = @_;
  sort_in_place($records, $ordering);
}

### Support Functions

# %$maxlength = maxfieldlength($@records);
sub maxfieldlength {
  my($records) = shift;
  
  my(%maxlength);
  foreach $record ( @$records ) {
    foreach $field ( keys %$record ) {
      my ($len) = length( $record->{$field} );
      $maxlength{$field} = $len if ($len > $maxlength{$field});
    }
  }
  return \%maxlength;
}

1;

__END__

=head1 DBAdaptor

The DBAdaptor abstract class models a connection to a record storage system

Create a DBAdaptor by providing a datasource name and a unique table name,
then use the create, read, update, delete interface for flat-hash records.

DBAdaptor subclasses exist for:
=over 4
=item SQL DBMS tables 
Win32::ODBC, MySQL, DBI
=item Flat files 
Delimited text, PropertyList
=back

Possible future addition: 
=over 4

=item Simple Database Files 
Based on various dbm-equivalent implementations.
=back

=head2 Instantiation
=over 4
=item Class::NamedFactory %DBAdaptorClasses
=item $dba = DBAdaptor->newfromdef( $hashref );
=item $dba = DBAdaptor->new_from_info( $source, $name );
=item $dba = DBAdaptor->new();
=back

=head2 Datasource Information
=over 4
=item DBAdaptor->add_datasource( $name, $info );
=item %$ds_info = DBAdaptor->datasource_info( $sourcename );
=back

=head2 Creation and Deletion of Remote Source
=over 4
=item $flag = $dba->source_exists
=item $dba->create_source( $RecordClass )
=item $dba->delete_source
=item $dba->recreate_source
=back

=head2 Field Information
=over 4
=item $fielddef = $dba->fields();
=item $fielddef = $dba->getfields();
=back

=head2 Record Access
=over 4
=item $count = $dba->count_records
=item @$records = $dba->fetchall;
=item @$records = $dba->fetch($criteria, $ordering);
=item $records = $dba->fetchbyid($id);
=back

=head2 Record Updates
=over 4
=item $dba->update( $record );
=item $dba->insert($record);
=item $dbadaptor->deleterecordbyid($id);
=item $dba->overwrite( @$records );
=item $dbadaptor->delete_all_records;
=item $dba->insert_records( @$records );
=back

=head2 Sorting and Searching
=over 4
=item $dba->apply_criteria($records, $criteria);
=item $dba->apply_order($records, $ordering);
=back

=head2 Support Functions
=over 4
=item %$maxlength = maxfieldlength($@records);
=back
