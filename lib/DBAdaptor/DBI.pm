## DBAdaptor::DBI - abstract subclass of SQL DBAdaptors for all DBI/DBD classes

### SQL Transactions 
  # $dba->executesql($sql);
  # $dba->fetchsql($sql);

### Connection Management
  # $dba->connect;
  # $connection = $dba->open_connection($databasename);
  # connection syntax is DBD driver specific.

### Creation and Deletion of Remote Source
  # $records = $dba->source_exists
  # $records = $dba->count_records

### Field Information
  # %@$fields = $dba->fields;
  # %@$fields = $dba->fields;
  # SQL field types are DMBS specific

### Copyright 1997 Evolution Online Systems, Inc.
  # This software is derived from materials developed and owned by Evolution
  # which have been made available for public use under the Artistic License.

### Change History
  # 1997-11-18 Updated to four-oh style.
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-08-20 Created - Eric

### Contributors
  # Eric     Eric Schneider (roark@evolution.com)

package DBAdaptor::DBI;

use DBAdaptor::SQL;
push @ISA, qw( DBAdaptor::SQL );

use DBI;
  # Available from CPAN; see also
  # 	http://www.hermetica.com/technologia/perl/DBI/index.html

### Connection Management

# $dba->disconnect;
sub disconnect {
  my($dba) = @_;
  
  $dba->connection->disconnect;
  
  undef $dba->{'connection'};
}

### Query Execution 

# log_start()
sub log_start {
  # return;
  
  #!# We should support optional logging of sql queries
  $start_time = time;
  warn "- Running SQL: $_[0] \n";
}

# log_stop()
sub log_stop {
  # return;
  
  warn "- SQL query " . (scalar @_ && 'returned ' . $_[0] . ' rows and') .
  		" required ".(time - $start_time)." second(s) \n";
}

# $dba->executesql($sql);
sub executesql {
  my($dba,$sql) = @_;
  
  log_start($sql);
  my $sth = $dba->perform_query($sql);
  $sth->finish;
  log_stop;
}

# $dba->fetchsql($sql);
sub fetchsql {
  my ($dba, $sql) = @_;
  
  log_start($sql);
  my $sth = $dba->perform_query($sql);
  $dba->{'fields'} = $dba->retrieve_fields($sth);
  my(@rows);
  while ($rowhash = $sth->fetchrow_hashref) {
    push(@rows, $rowhash);
  }
  $sth->finish;
  log_stop(scalar(@rows));
  
  return @rows;
}

# $sth = $dba->perform_query($sql);
sub perform_query {
  my ($dba, $sql) = @_;
    
  my $sth = $dba->connection->prepare($sql);
  die "Database error during query to $dbadptor->{'database'}: $DBI::errstr\n".
	   "Unable to prepare sql: $sql"        unless ( $sth );
  
  my $success = $sth->execute;
  
  die "Database error during query to $dbadptor->{'database'}: $DBI::errstr\n"
					      unless ( defined( $success ) );
  
  return $sth;
}

### Field Information

# %@$fields = $dba->fields;
sub fields {
  my($dba) = @_;
  
  unless ($dba->{'fields'}) {
   warn "getting field info for " . $dba->{'table'};
    my $sth = $dba->perform_query("select * from $dba->{'table'}")
    $dba->{'fields'} = $dba->retrieve_fields($sth);
  }
  
  return $dba->{'fields'};
}

# %@$fields = $dba->retrieve_fields($sth)
sub retrieve_fields {
  my($dba, $sth) = @_;
  
  my($names) = $sth->{NAME};
  my($types) = $sth->{TYPE};
  
  # DBI apparently uses ODBC numeric constants for field type info. Hm.
  my $odbctypes = {
    1 => 'text',	# char
    2 => 'float',	# numeric (?)
    3 => 'float',	# decimal
    4 => 'int',		# integer
    5 => 'int',		# smallint
    6 => 'float',	# float
    7 => 'float',	# real
    8 => 'float',	# double
    9 => 'time',	# datetime
    12 => 'text',	# varchar
  };
  
  my (@fields);
  for ($i = 0; $i < scalar(@{$names}); $i++) {
    #warn "$names->[$i] => $odbctypes->{$types->[$i]}\n";
    my($field) = {
      'name' => $names->[$i],
      'type' => $odbctypes->{$types->[$i]}
    };
    push( @fields, $field );
  }
  
  return \@fields;
}

### Creation and Deletion of Remote Source

# $records = $dba->source_exists
sub source_exists {
  my($dba) = @_;
  
  my($x) = $dba->count_records;
  
  return ($x) ? 1 : 0;
}

# $records = $dba->count_records
sub count_records {
  my($dba) = @_;
  
  my $count;
  
  my($sql) = "select count(*) from $dba->{'table'}";
  my($dbh) = $dba->connection;
  my($sth) = $dbh->prepare($sql);
  
  if ($sth) {
    $sth->execute;
    $count = scalar(@{$sth->{NAME}});
    $sth->finish;
    undef $sth;
  } else {
    warn "Couldn't prepare sql statement: $sql\n";
  }
  
  return $count;
}

1;

__END__

=head1 DBAdaptor::DBI

Abstract DBAdaptor superclass for connections via DBI and DBD::*, available from CPAN.

=head2 Connection Management
=over 4
=item $dbh = $dba->connect_to_source( $dsn )
Abstract method that must be implemented in a DBD* subclass.

=item $dba->disconnect;
=back

=head2 Query Execution 
=over 4
=item log_start()
=item log_stop()
=item $dba->executesql($sql);
=item $dba->fetchsql($sql);
=item $sth = $dba->perform_query($sql);
=back

=head2 Field Information
=over 4
=item %@$fields = $dba->fields;
=item %@$fields = $dba->retrieve_fields($sth)
=back

=head2 Creation and Deletion of Remote Source
=over 4
=item $records = $dba->source_exists
=item $records = $dba->count_records
=back

=cut

