### DBAdaptor::DBMS provides SQL database-server-specific behavior.

### We need to support the following DBMS-specific behaviour.
  # - All: type for long text field 
  # - Oracle: single, trailing long. 
  # - MySQL, Oracle: downcase column names. 
  # - DB2: Long insertion via multiple updates. 
  # - Informix: escape newlines on insert/update/where and select

### Change History
  # 1998-05-08 Extracted from DBAdaptor::SQL and IWAE::dbadaptor::odbc. -Simon

package DBAdaptor::DBMS;

# Class::NamedFactory %DBAdaptorClasses
use Class::NamedFactory;
push @ISA, qw( Class::NamedFactory );
use vars qw( %DBMS_Classes );
sub subclasses_by_name { \%DBMS_Classes; }

# $field_sql = $dbms->long_text_field_type($length);
sub long_text_field_type { 'varchar(' . $_[1] . ')' }

# $escaped = $dbms->escape_for_like($value);
sub escape_for_like {
  my ($dbms, $value) = @_;
  $value =~ s/(\%|\_)/\\$1/g;
  return $value;
}

### DBMS::MySQL

package DBAdaptor::DBMS::MySQL;
@DBAdaptor::DBMS::MySQL::ISA = ('DBAdaptor::DBMS');

DBAdaptor::DBMS::MySQL->register_subclass_name( );
sub subclass_name { 'mysql' }

# $field_sql = $dbms->long_text_field_type($length);
sub long_text_field_type { 'blob' }


### DBMS::DB2

package DBAdaptor::DBMS::DB2;
@DBAdaptor::DBMS::DB2::ISA = ('DBAdaptor::DBMS');

DBAdaptor::DBMS::DB2->register_subclass_name( );
sub subclass_name { 'db2' }

# $field_sql = $dbms->long_text_field_type($length);
sub long_text_field_type { 'long varchar' }

use Data::Collection;
use Err::Debug;

use vars qw( $ChunkSize );
$ChunkSize = 512;

# $dbms->update($dba, $row);
sub update {
  my ($dbms, $dba, $row) = @_;
  $row = { %$row };
  my @overflows  = $dbms->extract_overflow_chunks( $dba, $row );
  $dba->executesql($dba->sql_update( {'id' => $row->{'id'}} , $row ));
  $dbms->update_overflow_concats( $dba, $row->{'id'}, @overflows );
}

# $dbms->insert($dba, $row);
sub insert {
  my ($dbms, $dba, $row) = @_;
  $row = { %$row };
  my @overflows  = $dbms->extract_overflow_chunks( $dba, $row );
  $dba->executesql( $dba->sql_insert($row) );
  $dbms->update_overflow_concats( $dba, $row->{'id'}, @overflows );
}

# ($fieldname => $value, ...) = $dbms->extract_overflow_chunks( $dba, $row );
sub extract_overflow_chunks {
  my ($dbms, $dba, $row) = @_;
  my @overflows;
  
  my $field;
  foreach $field (@{ $dba->fields }) {
    my $fieldname = $field->{'name'};
    while ( length $row->{$fieldname} > $ChunkSize ) {
      my $chunk = substr($row->{$fieldname}, $ChunkSize, $ChunkSize);
      substr($row->{$fieldname}, $ChunkSize, $ChunkSize) = '';
      push @overflows, $fieldname,$dba->quote_by_type($field->{'type'},$chunk);
    }
  }
  return @overflows;
}

# $dbms->update_overflow_concats( $dba, $row->{'id'}, @overflows );
sub update_overflow_concats {
  my ($dbms, $dba, $id, @overflows) = @_;
  my $where_clause = $dba->sql_where(
	      Data::Criteria::StringEquality->new_kv('id' => $id) );
  while ( scalar @overflows ) {
    $fieldname = shift @overflows;
    my $chunk = shift @overflows;
    my $sql = "update $dba->{'table'} set $fieldname = " . 
	      "CONCAT($fieldname, $chunk) where $where_clause";
    debug 'sql', $sql;
    $dba->executesql( $sql );
  }
}


### DBMS::Oracle

package DBAdaptor::DBMS::Oracle;
@DBAdaptor::DBMS::Oracle::ISA = ('DBAdaptor::DBMS');

DBAdaptor::DBMS::Oracle->register_subclass_name( );
sub subclass_name { 'oracle' }

# $field_sql = $dbms->long_text_field_type($length);
sub long_text_field_type { $_[1] > $LongLimit ? 'long' : 'varchar('.$_[1].')' }

use vars qw( $LongLimit $Packer_A $Packer_B );
$LongLimit = 255;

$Packer_A = '-=-' x 5;
$Packer_B = '||@field@||';

# $escaped = $dbms->escape_for_like($value);
sub escape_for_like {
  my ($dbms, $value) = @_;
  $value =~ s/(\%|\_)/\\$1/g;       # escape % and _
  return $value, " escape '\\'";
}

# $dbms->create($dba, $columns);
sub create {
  my ($dbms, $dba, $columns) = @_;
  
  my ($column, @columns, @longs);
  foreach $column ( @$columns ) {
    if ( $column->{'type'} =~ /text.*?(\d+)/ and $1 > $LongLimit ) {
      push @longs, $column;
    } else {
      push @columns, $column;
    }
  }
  if ( scalar @longs < 2 ) {
    push @columns, @longs;
  } else {
    push @columns, { 'name' => 'magic', 'type' => 'long' };
  }
  
  $dba->executesql($dba->sql_create_statement(\@columns));
}

# $dbms->pack($dba, $row);
sub pack {
  my ($dbms, $dba, $row) = @_;
  my $fields = $dba->fields;
  my @longs = grep {$_->{'type'}=~/text.*?(\d+)/ and $1 > $LongLimit} @$fields;
  if ( scalar @longs > 1 ) {
    my ($col, @long_data);
    foreach $col ( @longs ) {
      push @long_data, $col->{'name'}, $row->{ $col->{'name'} };
      delete $row->{ $col->{'name'} };
    }
    $row->{'magic'} = $dbms->pack_long_data( @long_data );
  }
}

# $dbms->unpack($dba, $row);
sub unpack {
  my ($dbms, $dba, $row) = @_;
  # Oracle upcases the column names
  %$row = map { lc($_), $row->{$_} } keys %$row;
  # Check for packed longs in the magic column
  if ( exists $row->{'magic'} ) {
    my @long_data = $dbms->unpack_long_data( $row->{'magic'} );
    while ( scalar @long_data ) {
      $row->{ shift(@long_data) } = shift(@long_data);
    }
    delete $row->{'magic'};
  }
}

# $string = $dbms->pack_long_data( $field, $value, ... );
sub pack_long_data {
  my $dbms = shift;
  my $string = '';
  while ( scalar @_ ) {
    $string .= $Packer_A . $Packer_B . (shift) . $Packer_B . (shift);
  }
  return $string;
}

# $field, $value, ... = $dbms->unpack_long_data( $string );
sub unpack_long_data {
  my ($dbms, $string) = @_;
  my @results;
  my $packed;
  foreach $packed ( split(quotemeta($Packer_A), $string) ) {
    next if (! length $packed);
    my($ignore,$field,$value) = split(quotemeta($Packer_B), $packed, 3);
    push @results, $fieldname, $value;
  }
}


### DBMS::Informix

package DBAdaptor::DBMS::Informix;
@DBAdaptor::DBMS::Informix::ISA = ('DBAdaptor::DBMS');

DBAdaptor::DBMS::Informix->register_subclass_name( );
sub subclass_name { 'informix' }

# $field_sql = $dbms->long_text_field_type($length);
sub long_text_field_type { 'char(' . $_[1] . ')' }

# $escaped = $dbms->escape_for_like($value);
sub escape_for_like {
  my ($dbms, $value) = @_;
  $value =~ s/(\%|\_)/\\$1/g;       # escape % and _
  $value =~ s/(\?|\*)/\\$1/g;       # escape ? and *
  return $value, " escape '\\'";
}

# $dbms->unpack($dba, $row);
  # Unpack the *NL newline expression
sub unpack {
  my ($dbms, $dba, $row) = @_;
  map { $row->{$_} =~ s/\*NL/\n/g } keys %$row 
}


### DBMS::Sybase

package DBAdaptor::DBMS::Sybase;
@DBAdaptor::DBMS::Sybase::ISA = ('DBAdaptor::DBMS');

DBAdaptor::DBMS::Sybase->register_subclass_name( );
sub subclass_name { 'sybase' }

# $field_sql = $dbms->long_text_field_type($length);
sub long_text_field_type { 'text' }

# $escaped = $dbms->escape_for_like($value);
sub escape_for_like {
  my ($dbms, $value) = @_;
  $value =~ s/(\%|\_|\[)/\[$1\]/g; # escape % _ and [
  return $value;
}


### DBMS::MicrosoftSQLServer

package DBAdaptor::DBMS::MicrosoftSQLServer;
@DBAdaptor::DBMS::MicrosoftSQLServer::ISA = ('DBAdaptor::DBMS::Sybase');

DBAdaptor::DBMS::MicrosoftSQLServer->register_subclass_name( );
sub subclass_name { 'mssql' }


### DBMS::MicrosoftAccess

package DBAdaptor::DBMS::MicrosoftAccess;
@DBAdaptor::DBMS::MicrosoftAccess::ISA = ('DBAdaptor::DBMS');

DBAdaptor::DBMS::MicrosoftAccess->register_subclass_name( );
sub subclass_name { 'access' }

# $field_sql = $dbms->long_text_field_type($length);
sub long_text_field_type { 'memo' }
