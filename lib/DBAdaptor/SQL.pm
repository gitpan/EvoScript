### DBAdaptor::SQL is an abstract superclass for connections to SQL databases.

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # This is free software; you can use it under the same terms as Perl itself.

### Change History
  # 1998-05-08 Extended to work with new DBMS package for server-specific code.
  # 1998-03-20 Changed the warn to a debug on SQL in text_field_type.
  # 1998-02-25 Moved fieldset->flat_fields call out of sql_create_statement.
  # 1998-02-24 Fixed scoping of temp list in quoted_record_values. 
  # 1998-02-01 Some debugging on update and quoting methods.
  # 1997-11-16 Cleanup.
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-08-11 Fixed the bug introduced by last night's minor change.
  # 1998-08-10 Minor change.
  # 1997-04-10 Changed handling of criteria.
  # 1997-03-** Various changes
  # 1997-02-01 Moved this code here. -Simon

package DBAdaptor::SQL;

$VERSION = 4.00_03;

use DBAdaptor;
push @ISA, qw( DBAdaptor );

use Err::Debug;
use Data::Collection;
use Data::Criteria;
use Carp;

### Instantiation

# $dba = DBAdaptor::SQL->new($source_info, $unique_name);
sub new {
  my($package, $source_info, $unique_name) = @_;
  
  my $dba = $package->SUPER::new;
  
  die "SQL DBAdaptor didn't specify datasource name" unless ( $source_info );
  die "SQL DBAdaptor didn't specify table name" unless ( $unique_name );
  
  $dba->{'database'} = $source_info;
  $dba->{'table'} = $unique_name;
  
  return $dba;
}

### Query Execution - Implemented by Subclasses

# $dba->executesql($sql);
sub executesql { die "abstract operation on $_[0]"; }

# $dba->fetchsql($sql);
sub fetchsql { die "abstract operation on $_[0]"; }

### Connection Management

# $dba->connect;
  # Attempt to connect to the datasource

use vars qw( %OpenSources );

# $dba->connect;
  # Keep connections open, and only use one per DSN.
sub connect {
  my $dba = shift;
  
  my $dsn = $dba->{'database'};
  $dba->{'connection'} = 
  		($OpenSources{$dsn} ||= $dba->connect_to_source($dsn));
}

# $connection = $dba->open_connection($databasename);
# connection syntax is DBD driver specific.
sub connect_to_source { die "abstract operation"; }

# $connector = $dba->connection;
  # Get the connection value (and actually connect if we weren't already)
sub connection {
  my $dba = shift;
  $dba->connect unless $dba->isconnected;
  return $dba->{'connection'};
}

# $flag = $dba->isconnected;
  # Check to see if we're currently connected
sub isconnected {
  my $dba = shift;
  return ( defined $dba->{'connection'} ) ? 1 : 0;
}

# $flag = $dba->can_connect;
  # Check to see if we can connect, and catch any exceptions. (nee db_exists)
sub can_connect {
  my $dba = shift;
  
  my $dbh;
  eval { $dbh = $dba->connect; };
  return $dbh ? 1 : 0;
}

# $dba->disconnect;
  # Disconnect from the datasource
sub disconnect {
  my $dba = shift;
  delete $dba->{'connection'};	# by default, just free the connection
}

# $dba->DESTROY;
  # On destruction, close the connection
sub DESTROY {
  my $dba = shift;
  $dba->disconnect;
}

### Record Access

# $dba->fetchall;
sub fetchall {
  my ($dba) = @_;
  
  $dba->fetchsql($dba->sql_select());
}

# @rows = $dba->fetch($criteria, $ordering);
sub fetch {
  my ($dba, $criteria, $sortorder) = @_;
  
  my $rows = [ $dba->fetchsql($dba->sql_select($criteria, $sortorder)) ];
  
  # Post-SQL criteria
  # my $non_sql_criteria = $dba->non_sql_criteria($criteria);
  # @$rows = $dba->apply_criteria($rows, $non_sql_criteria);
  
  return @$rows;
}

# $dba->insert($row);
sub insert {
  my ($dba, $row) = @_;
  return $dba->dbms->insert($dba, $row) if $dba->dbms->can('insert');
  $dba->executesql( $dba->sql_insert($row) );
}

# Consider supporting auto-increment here, along these lines:
  # my $sql;
  # $sql = $dba->sql_insert( $row);    
  # try {
  #  $dba->executesql($sql);
  # } catch {
  #   if (defined ($dba->{'autoincrement'}) && (! $cursor) &&
  # 		($_ =~ /Dup+licate entry '.*' for key (.*)/)) {
  #	warn "-> Record already exists, autoincrementing.\n";
  #	my ($key) = $row->{'id'};
  #	$key ++;
  #	die "couldn't increment id value '$key'" if ($key eq $row->{'id'});
  #	$row->{'id'} = $key;
  #	RETRY;
  #   } else {
  #	die "Can't run query: " . $err . "\n(in sql: " . $sql . ")\n" ;
  #   }
  # };

# $dba->deleterecordbyid( $id );
sub deleterecordbyid {
  my($dba, $id) = @_;
  
  $dba->executesql($dba->sql_delete({ 'id' => $id }));
}

# $dba->update( $row );
sub update {
  my($dba, $row) = @_;
  return $dba->dbms->update($dba, $row) if $dba->dbms->can('update');
  $dba->executesql($dba->sql_update({ 'id' => $row->{'id'} } , $row));
}

# $dba->create_source($fieldset)
  # Actually create the remote data source
sub create_source {
  my($dba, $fieldset) = @_;
  my $columns = $fieldset->flat_fields;
  return $dba->dbms->create($dba, $columns) if $dba->dbms->can('create');
  $dba->executesql($dba->sql_create_statement($columns));
}

### Quoted SQL Escaping

# $quoted = $dba->quote( $value );
sub quote ($$) {
  my ($dba, $value) = @_;
  $value =~ s/\'/\\\'/g;
  $value = '\'' . $value . '\'';
  return $value;
}

# $value = $dba->unquote( $quoted );
sub unquote ($$) {
  my ($dba, $value) = @_;
  $value =~ s/\A\'(.*)\'\Z/$1/g;
  $value =~ s/\'\'/\'/g;
  return $value;
}

### Quoted Statement Values

# $qvalue = $dba->quote_by_type( $type, $value );
sub quote_by_type {
  my ($dba, $type, $value) = @_;
  $value = '' unless (defined $value);
  # warn $type . ' ' . $value;
  if ($type eq 'text') {
    $value = $dba->quote($value);
  } else {
    $value += 0;
  }
  # warn $type . ' ' . $value;
  return $value;
}

# @values = $dba->quoted_values ( $row, @fieldnames )
sub quoted_values {
  my($dba, $row, @fieldnames) = @_;
  
  my $fields = $dba->fields;
  my @values;
  foreach $fieldname (@fieldnames) {
    my $field = matching_values($fields, 'name' => $fieldname);
    push @values, 
	  $dba->quote_by_type($field->{'type'}, $row->{$fieldname});
  }
  
  return @values;
}

# $keypairstring = $dba->quoted_record_values($row, $joiner, @fnames)
sub quoted_record_values {
  my($dba, $row, $joiner, @fnames) = @_;
  
  my $fields = $dba->fields;
  
  debug 'sql', 'quoting', @fnames, 'for record', "$row";
  my @values;
  my $fieldname;
  foreach $fieldname ( keys %$row ) {
    next if ( scalar @fnames and ! grep { $_ eq $fieldname } @fnames );
    my $field = matching_values($fields, 'name' => $fieldname);
    next unless $field;
    push @values, $fieldname . ' = ' .
	  $dba->quote_by_type($field->{'type'}, $row->{$fieldname});
  }
  
  return join($joiner, @values);
}

### Server-Specific SQL

# $server_type = $dba->server_type
sub server_type { croak 'abstract'; }

use DBAdaptor::DBMS;

# $dbms_class = $dba->dbms
sub dbms {
  my $dba = shift;
  $dba->{'dbms'} ||= DBAdaptor::DBMS->subclass_by_name( $dba->server_type ) 
		      || DBAdaptor::DBMS->subclass_by_name( 'generic' );
  return $dba->{'dbms'};
}

# $escaped, $escape = $dba->sql_escape_for_like($value);
sub sql_escape_for_like {
  my ($dba, $value) = @_;
  $dba->dbms->escape_for_like($value);
}

# $field_sql = $dba->text_field_type($length);
sub text_field_type {
  my($dba, $length) = @_;
  return "varchar($length)" if ($length < 256);
  $dba->dbms->long_text_field_type($length);
}

### SQL Statements

# $sql_stmt = $dba->sql_select($criteria, $order);
sub sql_select {
  my ($dba, $criteria, $orderby) = @_;
  
  my $sql = "select * from $dba->{'table'}";
  
  my $whereclause = $criteria ? $dba->sql_where($criteria) : '';
  $sql .= ' where ' . $whereclause if ( $whereclause and length $whereclause );
  
  $sql .= ' order by '. join(', ', @$order) if ($orderby and scalar @$order);
  
  debug 'sql', $sql;
  return $sql;
}

# $sql_stmt = $dba->sql_insert($fields, $row);
sub sql_insert {
  my ($dba, $row) = @_;
  my $fields = $dba->fields;
  my $table = $dba->{'table'};
  
  $dba->dbms->pack($dba, $row) if ( $dba->dbms->can('pack') );
  
  # print "building insert statement for " . join(' ', %$row) . "\n\n";
  
  my (@fieldnames) = map($_->{'name'}, @$fields);
  my $sql = "insert into $table (";
  $sql .= join(', ', @fieldnames);
  $sql .= ')  values (';
  $sql .= join(', ', $dba->quoted_values($row, @fieldnames));
  $sql .= ')';
  
  debug 'sql', $sql;
  return $sql;
}

# $sql_stmt = $dba->sql_delete(%$key_value_criteria);
sub sql_delete {
  my ($dba, $row) = @_;
  my $fields = $dba->fields;
  my $table = $dba->{'table'};
  
  my $sql = 'delete from ' . $table . ' where ' .
	$dba->quoted_record_values($row, ' and ', 'id');
  debug 'sql', $sql;
  return $sql;
}

# $sql_stmt = $dba->sql_update( $oldrecord , $newrecord );
sub sql_update {
  my ($dba, $oldrecord, $newrecord) = @_;
  
  my $fields = $dba->fields;
  my $table = $dba->{'table'};
  
  my $sql = 'update ' . $table . 
	' set ' . $dba->quoted_record_values($newrecord, ', ') .
	' where ' . $dba->quoted_record_values($oldrecord, ' and ', 'id');
  
  debug 'sql', $sql;
  return $sql;
}

# $sql_statement = $dba->sql_create_statement($columns)
  # Construct the sql create statement.
sub sql_create_statement {
  my($dba, $columns) = @_;
  my($sql);
  
  $sql = "create table $dba->{'table'} ( \n";
  
  my @sql_fields;
  my $column;
  foreach $column ( @$columns ) {
    $column->{'type'} = $dba->text_field_type($1)
				    if ( $column->{'type'} =~ /text.*?(\d+)/ );
    
    push @sql_fields, $column->{'name'} . 
	    ' ' x (30 - length( $column->{'name'}) ) . $column->{'type'};
  }
  
  $sql .= join ",\n", @sql_fields;
  
  $sql .= "\n)\n";
  
  debug 'sql', $sql;
  return $sql;
}

### SQL Selection criteria
  # Use &sql_where to get a where clause; &non_sql_criteria need to be caught
  # Each handler builds an sql where clause for this type of match
  # Criteria are hashes of { 'name'=> text, 'field'=> word, 'value'=> ref_val }

# $whereclause = sql_where( $criteria );
sub sql_where {
  my ($dba, $criteria) = @_;
  
  $criteria = new_group_from_values(@$criteria) if (ref $criteria eq 'ARRAY');
  return $criteria->sql( $dba );
}

# @$non_sql_criteria = non_sql_criteria(\@criteria);
sub non_sql_criteria {
  my ($dba, $criteria) = @_;
  $criteria = new_group_from_values(@$criteria) if (ref $criteria eq 'ARRAY');
  return ;
  my (@non_sql_criteria);
  foreach $criterion (@$criteria ) {
    my ($where_handler) = 
		  $dba->get_sql_criterion_handler($criterion->{'match'});
    push (@non_sql_criteria, $criterion) 
    		unless ($where_handler and $dba->can($where_handler));
  }
  return \@non_sql_criteria;
}

__END__

=head1 DBAdaptor::SQL

=head2 Instantiation
=over 4
=item $dba = DBAdaptor::SQL->new($source_info, $unique_name);
=back

=head2 Query Execution - Implemented by Subclasses
=over 4
=item $dba->executesql($sql);
=item $dba->fetchsql($sql);
=back

=head2 Connection Management
=over 4
=item $dba->connect;
=item $dba->connect;
=item $connection = $dba->open_connection($databasename);
=item connection syntax is DBD driver specific.
=item $connector = $dba->connection;
=item $flag = $dba->isconnected;
=item $flag = $dba->can_connect;
=item $dba->disconnect;
=item $dba->DESTROY;
=back

=head2 Record Access
=over 4
=item $dba->fetchall;
=item @rows = $dba->fetch($criteria, $ordering);
=item $dba->insert($row);
=item $dba->deleterecordbyid($id);
=item $dba->update( $row );
=item $dba->create_source($columns)
=back

=head2 Quoted SQL Escaping
=over 4
=item Why bother?
=item Text::Escape::add( 'qsql', \&quote );
=item Text::Escape::add( 'unqsql', \&unquote );
=item $quoted = quote( $value );
=item $value = unquote( $quoted );
=back

=head2 Quoted Statement Values
=over 4
=item $qvalue = $dba->quote_by_type( $type, $value );
=item @values = $dba->quoted_values ( $row, @fieldnames )
=item $keypairstring = $dba->quoted_record_values ($row, $joiner)
=back

=head2 Server-Specific SQL
=over 4
=item $server_type = $dba->server_type
=item $escaped, $escape = $dba->sql_escape_for_like($value);
=item $field_sql = $dba->text_field_type($length);
=back

=head2 SQL Statements
=over 4
=item $sql_stmt = $dba->sql_select($criteria, $order);
=item $sql_stmt = $dba->sql_insert($fields, $row);
=item $sql_stmt = $dba->sql_delete(%$key_value_criteria);
=item $sql_stmt = $dba->sql_update( $oldrecord , $newrecord );
=item $sql_statement = $dba->sql_create_statement($fieldset)
=back

=head2 SQL Selection criteria
=over 4
=item $whereclause = sql_where( $criteria );
=item @$non_sql_criteria = non_sql_criteria(\@criteria);
=back

=cut
