### DBAdaptor::DBDInformix - dbadaptor for Informix.

### Overview
  # This dbadaptor provides database access to Informix servers via DBD.
  # See dbd.pm or http://www.hermetica.com/technologia/perl/DBI/index.html

### Connection Management
  # $sqltype = $dbadaptor->text_field_type($length);
  # $connection = $dbadaptor->open_connection($dbstring);

### Copyright 1997 Evolution Online Systems, Inc.
  # This software is derived from materials developed and owned by Evolution
  # which have been made available for public use under the Artistic License.

### Change History
  # 1997-08-20 Created - Eric

### Contributors
  # Eric     Eric Schneider (roark@evolution.com)

package DBAdaptor::DBDInformix;

use DBAdaptor::DBI;
@ISA = qw[ DBAdaptor::DBI ];

### Remote Server Types

# $informix = $dba->server_type
sub server_type { return 'informix'; }

### Connection Management

# $dbh = $dba->connect_to_source( $dsn )
  # syntax is: "dbname[@server][:username:password]"
sub connect_to_source {
  my ($dbadaptor, $dbstring) = @_;
  
  my($dbname,$username,$password) = split(':', $dbstring);
  
  # These env vars are required. There should be a better way to do this.
  $ENV{'INFORMIXDIR'} ||= '/opt/informix';
  $ENV{'INFORMIXSERVER'} ||= 'evolution';
  
  warn "opening connection to $dbname\n";
  my($dbh) = DBI->connect('dbi:Informix:' . $dbname, $username, $password,
                          { AutoCommit => 1, PrintError => 1 });
  
  die "could not connect to Informix database '$dbstring': $DBI::errstr" 
			  			unless ( defined($dbh) );
  
  # warn_dbh_info($dbh);
  
  return $dbh;
}

# warn_dbh_info($dbh);
sub warn_dbh_info {
  my $dbh = shift;
  
  warn "Database Information for $dbh\n";
  # Type is always 'db'
  warn "    Type:                    $dbh->{Type}\n";
  
  # Name is the name of the database specified at connect
  warn "    Database Name:           $dbh->{Name}\n";
  
  # AutoCommit is 1 (true) if the database commits each statement.
  warn "    AutoCommit:              $dbh->{AutoCommit}\n";
  
  # ix_InformixOnLine is 1 (true) if the handle is connected to an
  # Informix-OnLine server.
  warn "    Informix-OnLine:         $dbh->{ix_InformixOnLine}\n";
  
  # ix_LoggedDatabase is 1 (true) if the database has
  # transactions.
  warn "    Logged Database:         $dbh->{ix_LoggedDatabase}\n";
  
  # ix_ModeAnsiDatabase is 1 (true) if the database is MODE ANSI.
  warn "    Mode ANSI Database:      $dbh->{ix_ModeAnsiDatabase}\n";
  
  # ix_AutoErrorReport is 1 (true) if errors are reported as they
  # are detected.
  warn "    AutoErrorReport:         $dbh->{ix_AutoErrorReport}\n";
  
  # ix_InTransaction is 1 (true) if the database is in a transaction
  warn "    Transaction Active:      $dbh->{ix_InTransaction}\n";
  
  # ix_ConnectionName is the name of the ESQL/C connection.
  # Mainly applicable with Informix-ESQL/C 6.00 and later.
  warn "    Connection Name:         $dbh->{ix_ConnectionName}\n";
}

1;

__END__

=head1 DBAdaptor::DBDInformix

Provides a subclass of DBAdaptor::DBI tailored for DBD::Informix.

=head2 Remote Server Types
=over 4
=item $informix = $dba->server_type
This DBAdaptor only connects to Informix servers, so it returns a constant.
=back

=head2 Connection Management
=over 4
=item $dbh = $dba->connect_to_source( $dsn )
Uses DBDInformix's connection syntax.
=item warn_dbh_info($dbh)
Provides diagnostic information about this DB Handle.
=back
=cut
