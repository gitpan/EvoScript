### DBAdaptor::MySQL provides database access through the Mysql.pm library.

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # This software is derived from materials developed and owned by Evolution
  # which have been made available for public use under the Artistic License.

### Change History
  # 1998-04-10 Replaced old Err::Exception try {} with UNIVERSAL::TRY.
  # 1998-03-03 Commented out the IDENT and IDX field types -- unsupported
  # 1997-11-17 Refactored.
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-09-07 Escaped for _, %.
  # 1997-09-04 Moved twiddle criteria here.
  # 1997-04-10 Minor cleanup.
  # 1997-03-29 Added perform_query wit shared open-cursor code, better logging
  # 1997-03-28 Cleaned up exception handling.
  # 1997-02-01 Moved this code here. -Simon

### Contributors
  # Simon    M. Simon Cavalletto (simonm@evolution.com)

package DBAdaptor::MySQL;

### DBAdaptor::MySQL, Subclass of DBAdaptor::SQL

use DBAdaptor::SQL;
@ISA = qw( DBAdaptor::SQL );

DBAdaptor::MySQL->register_subclass_name( );
sub subclass_name { 'mysql' }

use Err::Exception;
use Text::PropertyList;

# Uses Mysql.pm, available from CPAN
use Mysql;
$Mysql::QUIET = '1';	# We'll do our own error logging, thank you very much.

### Connection Management

# $connection = $dba->connect_to_source($datasource);
sub connect_to_source {
  my ($dba, $datasource) = @_;
  
  # if there's no host name in front, just use the dbname
  my ($dbname, $host) = reverse split(/\s*\:\s*/, $datasource);
  my $dbh = Mysql->Connect($host, $dbname);
  
  die "Unable to connect to MySQL '$datasource': $Mysql::db_errstr\n"
							    unless ( $dbh );
  return $dbh;
}

### Remote Server Types

# $mysql = $dba->server_type
sub server_type { return 'mysql'; }

# $quoted = $dba->quote( $value );
sub quote ($$) {
  my ($dba, $value) = @_;
  Mysql->quote( $value );
}

# $value = $dba->unquote( $quoted );
sub unquote ($$) {
  my ($dba, $value) = @_;
  $value =~ s/\A\'(.*)\'\Z/$1/g;
  $value =~ s/\'\'/\'/g;
  return $value;
}

### Query Execution 

# log_start( $sql );                    // write out a start-query log item
sub log_start {
  return;
  
  #!# We should support optional logging of sql queries
  $start_time = time;
  warn "-> Running SQL: $_[0] \n";
}

# log_start( $number_of_rows );          // write out a query-finished log item
sub log_stop {
  return;
  
  my $time = (time - $start_time) || 'less than one';
  warn "-> SQL query " . (scalar @_ && 'returned ' . $_[0] . ' rows and') .
  		" required $time second(s) \n";
}

# $sth = $dba->perform_query($sql);
sub perform_query {
  my ($dba, $sql) = @_;
  
  my $sth = $dba->connection->query($sql);	
  
  die "Error from MySQL database $dba->{'database'}: $Mysql::db_errstr \n" . 
      "Could not perform query '$sql'\n"      		       unless ($sth); 
  
  return $sth;
}

# $dba->executesql($sql);
sub executesql {
  my ($dba, $sql) = @_;
  
  log_start ($sql);
  
  my $sth = $dba->perform_query($sql);
  
  log_stop;
  
  return;
}

# @rows = $dba->fetchsql($sql);
sub fetchsql {
  my ($dba, $sql) = @_;
  
  log_start ($sql);
  
  my $sth = $dba->perform_query($sql);
  
  $dba->{'fields'} ||= $dba->retrieve_fields($sth);
  
  my @rows = $dba->retrieve_records( $sth );
  # warn "Rows: " . join(' ', @rows) . " \n";
  
  log_stop (scalar @rows);
  
  return @rows;
}

# @rows = $dba->retrieve_records( $sth );
  # Return the records associated with a statement handle as a list of hashes
sub retrieve_records {
  my ($dba, $sth) = @_;
  
  my (@fields) = map { "\l$_" } @{ $sth->name };
  # Compensate for MySql object upcasing the fieldnames. That's _so_ lame. -S.
  
  my (%record, @rows);
  while ( @record{@fields} = $sth->FetchRow ) {
    %{$rows[$#rows +1]} = %record;
  }
  
  return @rows;
}

### Field Information

# %@$fields = $dba->fields;
sub fields {
  my $dba = shift;
  
  # warn "flds ". astext($dba->{'fields'});
  
  return $dba->{'fields'} ||= $dba->retrieve_fields(
  	$dba->connection->listfields($dba->{'table'}) or die
	"can't retrieve fields for $dba->{'table'}: $Mysql::db_errstr"
      );
}

# %@$fields = $dba->retrieve_fields($sth)
  # Compensate for MySql object upcasing the fieldnames. That's _so_ lame. -S.
  #
  #!# is_pri_key causes the driver to fail with the following fatal error,
    # or at least that happens in the version we last tested it with. -S.
    #    relocation error: symbol not found: mysql_FieldSeek
    # 'pri_key' => $sth->is_pri_key->[$i], 
  
sub retrieve_fields {
  my ($dba, $sth) = @_;
  
  my $types = $dba->driver_field_types();
  # warn "ftyps ". astext($types);
  my $fields = [
    map {
      {
	'name' => lc( $sth->name->[$_] ),
	'type' => $types->{ $sth->type->[$_] },
	'not_null' => $sth->is_not_null->[$_],
	'length' => $sth->length->[$_],
      };
    } (0 .. $sth->numfields -1)
  ];
  # warn "fields: " . astext( $fields );
  return $fields;
}

# %$types_by_name = $dba->driver_field_types();
  # Return a hash mapping MySQL field types to their dba field type equivalent.
  # Cache the field types in the dba, so we don't do the lookups unnecessarily
sub driver_field_types {
  my $dba = shift;
  
  # Which of these do we actually need? -- not all of them, certainly...
  
  return $dba->{'field_types'} ||= {
    &Mysql::INT_TYPE => 'int',
    &Mysql::FIELD_TYPE_LONG => 'int',
    &Mysql::FIELD_TYPE_SHORT => 'int',
    &Mysql::FIELD_TYPE_LONGLONG => 'int',
    &Mysql::FIELD_TYPE_INT24 => 'int',
    
    &Mysql::REAL_TYPE => 'float',
    # &Mysql::FIELD_TYPE_FLOAT => 'float',
    # &Mysql::FIELD_TYPE_DOUBLE => 'float',
    # &Mysql::FIELD_TYPE_DECIMAL => 'float',
    
    # &Mysql::CHAR_TYPE => 'text',
    # &Mysql::TEXT_TYPE => 'text',
    &Mysql::FIELD_TYPE_CHAR => 'text',
    &Mysql::FIELD_TYPE_STRING => 'text',
    &Mysql::FIELD_TYPE_VAR_STRING => 'text',
    &Mysql::FIELD_TYPE_BLOB => 'text',
    # &Mysql::FIELD_TYPE_TINY_BLOB => 'text',
    # &Mysql::FIELD_TYPE_MEDIUM_BLOB => 'text',
    # &Mysql::FIELD_TYPE_LONG_BLOB => 'text',
    
    # &Mysql::IDENT_TYPE => 'id',
    # &Mysql::IDX_TYPE => 'index',
    # &Mysql::FIELD_TYPE_NULL => '',
    
    &Mysql::DATE_TYPE => 'date',
    # &Mysql::FIELD_TYPE_DATE => 'date',
    
    &Mysql::TIME_TYPE => 'time',
    # &Mysql::FIELD_TYPE_TIME => 'time',
    
    # &Mysql::FIELD_TYPE_DATETIME => 'moment',
    # &Mysql::FIELD_TYPE_TIMESTAMP => 'moment',
  };
}

### Status, Creation, and Deletion of Remote Storage

# $flag = $dba->source_exists;       // should be named table_exists
sub source_exists {
  my $dba = shift;
  
  return defined( $dba->count_records );
}

# $rowcount = $dba->count_records
sub count_records {
  my $dba = shift;
  
  my $sql = "select count(*) from $dba->{'table'}";
  my $sth = $dba->TRY(['perform_query', $sql], 'ANY' => 'IGNORE') 
	or return undef;
  return $sth->FetchRow;
}

1;

__END__

=head1 DBAdaptor::MySQL

Subclass of DBAdaptor::SQL that uses MySQL connections (available from CPAN).

=head2 Connection Management
=over 4
=item $connection = $dba->connect_to_source($datasource);
=back

=head2 Remote Server Types
=over 4
=item $mysql = $dba->server_type
=back

=head2 Query Execution 
=over 4
=item log_start( $sql );
write out a start-query log item
=item log_start( $number_of_rows );
write out a query-finished log item
=item $sth = $dba->perform_query($sql);
=item $dba->executesql($sql);
=item @rows = $dba->fetchsql($sql);
=item @rows = $dba->retrieve_records( $sth );
=back

=head2 Field Information
=over 4
=item %@$fields = $dba->fields;
=item %@$fields = $dba->retrieve_fields($sth)
=item %$types_by_name = $dba->driver_field_types();
=back

=head2 Status, Creation, and Deletion of Remote Storage
=over 4
=item $flag = $dba->source_exists;
should be named table_exists
=item $rowcount = $dba->count_records
=back
=cut
