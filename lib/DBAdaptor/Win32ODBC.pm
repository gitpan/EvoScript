### DBAdaptor::Win32ODBC provides an interface to Win32::ODBC datasources.

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Developed by
  # Eric     Eric Schneider (roark@evolution.com)
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # MAP      Marc A. Powell (map@evolution.com)

### Change History
  # 1998-05-08 Switched to use of $dbms->unpack.
  # 1998-03-18 Changed try to eval in count records.
  # 1998-03-10 Added die when we are unable to connect to the ODBC source.
  # 1998-01-28 Added import method to simplify setting driver license keys.
  # 1998-01-28 Fixed logical inversion in field detection's trivial query code.
  # 1998-01-27 Added debug statements, fixed return from perform_query.
  # 1998-01-21 Fixed typo mentioned by Del & Randy
  # 1997-11-16 Revised to follow new DBA interface.
  # 1997-09-25 Added code to allow caching of driver type. -Simon
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-09-20 Changed Sybase recognition string to 'sql server'.
  # 1997-08-** Various changes
  # 1997-05-26 Added text_field_type, get_server_type  -Eric
  # 1997-02-01 Moved this code here. -Simon
  # 1997-01-30 Implemented ODBC Insert, Delete, Update, Overwrite, and
  #            additional criteria madness - including postquery criteria 
  # 1997-01-29 Build criteria into ODBC load() (again, it is the prophecy) 
  # 1997-01-28 Added ODBC support for load(). - MAP 

package DBAdaptor::Win32ODBC;

use Data::DRef;
use DBAdaptor::SQL;
use Carp;
use Err::Exception;
use Err::Debug;
use Text::Excerpt;

@ISA = qw[ DBAdaptor::SQL ];

# Win32::ODBC available at http://www.roth.net v970104
  # requires $PERL_ROOT\lib\win32\odbc.pm 
  #      and $PERL_ROOT\lib\auto\win32\odbc\odbc.pll
use Win32::ODBC;

DBAdaptor::Win32ODBC->register_subclass_name( );
sub subclass_name { 'odbc' }

# DBAdaptor::Win32ODBC->import( 'keys' => [ ... ] );
sub import {
  my $package = shift;
  while ( $_ = shift ) {
    if ( /keys/ ) {
      my $keys = shift;
      @ConnectKeys = @$keys;
    } else {
      die "unknown import";
    }
  }
}

### Connection

use vars qw( @ConnectKeys );

# $dbh = $dba->connect_to_source( $dsn )
sub connect_to_source {
  my ($dba, $DSN) = @_;
  
  my $dbh = Win32::ODBC->new($DSN, @ConnectKeys);
  
  # Check to see if we made a connection.  If not, then let's throw an
  # exceptions so that we can redirect to the ODBC setup screen.
  
  if ( ! $dbh ) {
     die "ODBC connection failure for '$DSN'.  Error = " . Win32::ODBC::Error();
  }
  
  return $dbh;
}

### Query Execution 

# $dbh = $dba->perform_query($sql);
sub perform_query {
  my ($dba, $sql) = @_;
  
  my $dbh = $dba->connection;
  debug 'odbc', "ODBC query:", $sql;
  
  return $dbh unless ( $sqlFailure = $dbh->Sql($sql) );
  
  die "ODBC Database error during query from $dbadptor->{'database'}: " . 
      $dbh->Error . "\n" . " Unable to run SQL '$sql'";
}

# $dba->executesql($sql);
sub executesql {
  my($dba, $sql) = @_;
  
  my $start_time = time;
    
  $dba->perform_query($sql);
  
  debug 'odbc', "ODBC Query completed in", (time - $start_time), "second(s)";
}

# $dba->fetchsql($sql);
sub fetchsql {
  my($dba, $sql) = @_;
  
  my $start_time = time;
  
  my $dbh = $dba->perform_query($sql);
  
  # Get the field names as they were actually returned
  my $fields = $dba->{'fieldnames'} = $dbh->FieldNames();
  my $dbms = $dba->dbms;
  $dbms = '' unless ( $dbms->can( 'unpack' ) );
  
  my(@rows);
  while ( $dbh->FetchRow() ) {
    my %results = $dbh->DataHash(@$fields);
    $dbms->unpack($dba, \%results) if ( $dbms );
    push(@rows, \%results);
  }
  
  debug 'odbc', "ODBC query required", (time - $start_time), "second(s)",
  		"and returned", scalar(@rows), "record(s)";
  
  return @rows;
}

### Remote Server Types

# $server_type = $dba->server_type
sub server_type {
  my $dba = shift;
  
  return $dba->{'server_type'} ||= $dba->determine_server_type();
}

# $server_type = $dba->determine_server_type
sub determine_server_type {
  my $dba = shift;
  
  # ODBC constant SQL_DBMS_NAME == 17
  $driverinfo = $dba->connection->GetInfo(17);
  
  debug 'odbc', "ODBC DriverInfo", $driverinfo;
  
  my $regex;
  foreach $regex ( sort { length($a) <=> length($b) } keys %ServerTypes ) {
    next unless ( $driverinfo =~ /$regex/i );
    debug 'odbc', "ODBC server type", $ServerTypes{ $regex };
    return $ServerTypes{ $regex };
  }
  
  return '';
}

# %ServerTypes - regexes mapping DBMS identifier strings to server types
use vars qw( %ServerTypes );
%ServerTypes = (
  'access' => 'access',
  'informix' => 'informix',
  'microsoft sql server' => 'mssql',
  'oracle' => 'oracle',
  'sql server' => 'sybase',
  'db2' => 'db2',
);

### Field Information

# %@$fields = $dba->fields;
sub fields {
  my $dba = shift;  unless ($dba->{'fields'}) {
    debug 'odbc', 'Detecting ODBC field types for', $dba->{'table'}, 'table';
    $dba->{'fields'} = $dba->fields_from_dbh( $dba->perform_trivial_query );
    debug 'odbc', 'ODBC field structure', $dba->{'fields'};
  }
  
  return $dba->{'fields'};
}

# $dbh = $dba->perform_trivial_query;
sub perform_trivial_query {
   my $dba = shift;  
   my $dbh = $dba->connection;
  
   # Yuck. id can be an int or text... one or the other of these should work
   my $sql = "select * from " . $dba->{'table'} . " where id = ";

   # check to see what our return was from queury.  If we were attempting to get
   # the user's table, assume we don't have any tables and we should redirect to 
   # the welcome screen.
  
   if ( $dbh->Sql($sql. "0") and $dbh->Sql($sql ."'0'") ){

      # was it the users table we were looking for?  If so, let's redirect to 
      # the welcome screen.  Otherwise, just put up the error.

      if ( $dba->{'table'} =~ /users/ ) {
         die "No Tables\n";
      }
      else {
         die "Can't execute trivial query to detect ODBC field types\n" . Win32::ODBC::Error();
      }
  
   }


  return $dbh;
}

# %@$fields = $dba->fields_from_dbh( $dbh )
sub fields_from_dbh {
  my ($dba, $dbh) = @_;
  
  my $types = $dba->driver_field_types();
  debug 'odbc', 'ODBC driver field types are', $types;
  
  my %fieldinfo = $dbh->ColAttributes(Win32::ODBC::SQL_COLUMN_TYPE, ());
  debug 'odbc', 'ODBC field info', \%fieldinfo;
  
  # MS-SQL 3.50 driver work-around: the above call to ColAttributes returns 
  # a bunch of null bytes, so we'll use typenames instead of typecodes.
  %fieldinfo = $dbh->ColAttributes( Win32::ODBC::SQL_COLUMN_TYPE_NAME, ())
			  if (grep { $_ =~ /^\0*$/ } ( values %fieldinfo ) );
  
  my @fields = map {
    {
      # Oracle quirk: field names are all UPPER CASE
      'name' => lc( $_ ),
      'type' => $types->{ $fieldinfo{ $_ } },
    }
  } ( keys %fieldinfo );
  
  return \@fields;
}

# %$types_by_name = $dba->driver_field_types();
  # Return a hash mapping ODBC field types to their dba field type equivalent.
  # Cache the field types in the dba, so we don't do the lookups unnecessarily
sub driver_field_types {
  my $dba = shift;
  
  $dba->{'field_types'} ||= {
    &ODBC::SQL_INTEGER => 'int',
    &ODBC::SQL_BIGINT => 'int',
    &ODBC::SQL_SMALLINT => 'int',
    &ODBC::SQL_TINYINT => 'int',
    &ODBC::SQL_REAL => 'float',
    &ODBC::SQL_BIT => 'int',
    &ODBC::SQL_FLOAT => 'float',
    &ODBC::SQL_DOUBLE => 'float',
    &ODBC::SQL_NUMERIC => 'float',
    &ODBC::SQL_DECIMAL => 'float',
    &ODBC::SQL_CHAR => 'text',
    &ODBC::SQL_VARCHAR => 'text',
    &ODBC::SQL_DATE => 'time',
    &ODBC::SQL_TIME => 'time',
    &ODBC::SQL_TIMESTAMP => 'time',
    'int' => 'int',
    'varchar' => 'text',
    'text' => 'text',
    'float' => 'float',
    '-1' => 'text'      # Driver returned unsupported type.
  };
  
  return $dba->{'field_types'};
}

### Creation and Deletion of Remote Source

# $records = $dba->source_exists
sub source_exists {
  my $dba = shift;  
  my($x) = $dba->count_records;
  
  return ($x) ? 1 : 0;
}

# $records = $dba->count_records
sub count_records {
  my $dba = shift;  
  my $cursor;
  eval {
    my $sql = "select count(*) from $dba->{'table'}";
    my($dbh) = $dba->connection;
    
    if ( $sqlFailure = $dbh->Sql($sql)) {
      $err = $dbh->Error();
      die "Can't run query: $err in request $sql \n";
    }
    
    $cursor = $dbh;
  };
  return $cursor->FetchRow if $cursor;
}

1;

__END__

=head1 DBAdaptor::Win32ODBC

SQL DBAdaptor subclass for connections via Win32::ODBC (available through CPAN or at http://www.roth.net).

