### DBAdaptor::FlatFile is the superclass for file dbadaptors.

### Instantiation
  # $dba = DBAdaptor::FlatFile->new($source_info, $unique_name);

### Connection Management
  # $fh = $dba->open_reader;
  # $dba->connect;
  # $dba->connect_for_write;
  # $dba->disconnect;

### Creation and Deletion of Remote Source
  # $count = $dba->source_exists
  # $dba->create_source($RecordClass)

### Record Access
  # $dba->deleterecordbyid($id);
  # $dba->insert($record);

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 1998-05-07 Now uses non-binmode File::Name methods.
  # 1998-02-27 Debugging and interface cleanup
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-02-01 Moved this code here. -Simon

package DBAdaptor::FlatFile;

$VERSION = 4.00_02;

use DBAdaptor;
push @ISA, qw( DBAdaptor );

use File::Name qw( filename current_directory );
use Carp;
use Data::DRef;
use Err::Debug;

use vars qw( $base_directory );
$base_directory ||= File::Name->current;

### Instantiation

# $dba = DBAdaptor::FlatFile->new($source_info, $unique_name);
sub new {
  my $package = shift;
  my $datasource = shift;
  my $filename = shift;
  
  my $dba = $package->SUPER::new();
  
  my $fn = File::Name->new( $datasource, $filename );
  croak "Can't open a filedb without a filename." unless ( $fn );
  $fn = $base_directory->relative( $fn ) unless $fn->is_absolute;
  
  $dba->{'filename'} = $fn;
  
  return $dba;
}

### Connection Management

# $fh = $dba->reader;
sub reader {
  my $dba = shift;
  $dba->fn->text_reader();
}

# $fh = $dba->writer;
sub writer {
  my $dba = shift;
  $dba->fn->text_writer();
}

# $fn = $dba->fn();
sub fn {
  my $dba = shift;
  $dba->{'filename'}
}

# $dba->connect;
sub connect {
  my $dba = shift;
  $dba->{'connection'} = $dba->reader;
}

sub target_filename {
  my $dba = shift;
  $dba->{'filename'};
}

# $dba->connect_for_write;
sub connect_for_write {
  my $dba = shift;
  
  my $filename = $dba->target_filename();
  
  if ($filename->exists and not -T $filename->path) {
    die "Database file '$filename' is not a text file, could not connect";
  }
  
  warn "-> Writing text data to '$dba->{'filename'}' \n";
  $dba->{'connection'} = $filename->writer;
}

# $dba->disconnect;
sub disconnect {
  my $dba = shift;
  
  close $dba->{'connection'};
  delete $dba->{'connection'};
}

### Configuration 

sub define_config_fields {
  return (    {      name => 'source',      type => 'text',      title => 'Database Name',      hint => 'Enter the directory path',    },    {      name => 'name',      type => 'text',      title => 'Filename Name',      hint => 'Enter the file name.',
    },  );
}

### Creation and Deletion of Remote Source

# $count = $dba->source_exists
sub source_exists {
  my($dba) = @_;
  
  $dba->target_filename->exists;
}

# $dba->create_source( $RecordClass )
sub create_source {
  my($dba, $RecordClass) = @_;
  
  debug 'flatfile', "Creating data file", $dba->target_filename;
  
  my @fieldnames;
  my $dbfields = $RecordClass->flat_fields;
  foreach $dbfield ( @$dbfields ) {
    push @fieldnames, $dbfield->{'name'};
  }
  $dba->{'fieldnames'} = [ @fieldnames ];
  
  $dba->overwrite();
  
  return;
}

### Record Access
  # Other methods implemented in subclasses

# $dba->deleterecordbyid($id);
sub deleterecordbyid {
  my($dba, $id) = @_;
    
  my $rows;
  @$rows = $dba->fetchall;
  @$rows = grep { $_->{'id'} ne $id } @$rows;
  # foreach $hash (@$rows) { warn join(", ", %$hash) . "\n"; }
  $dba->overwrite($rows);
}

# $dba->insert($record);
sub insert {
  my($dba, $record) = @_;
    
  my $rows = [];
  @$rows = $dba->fetchall;
  push @$rows, $record;
  # foreach $hash (@$rows) { warn join(", ", %$hash) . "\n"; }
  $dba->overwrite($rows);
}

### Bulk Access with Caching

# @rows = $dba->fetchall;
sub fetchall {
  my $dba = shift;
  
  unless ( $dba->{'cachetime'} and 
			$dba->{'cachetime'} == $dba->fn->age_since_change ) {
    $dba->{'cache'} = [ $dba->load ];
    $dba->{'cachetime'} = $dba->fn->age_since_change;
  }
  
  return @{$dba->{'cache'}};
}

# $dba->overwrite($rows);
sub overwrite {
  my $dba = shift;
  my $rows = shift;
  $dba->{'cache'} = [ @$rows ];
  $dba->write_records( @$rows );
}

# @rows = $dba->load;
sub load { die "abstract operation on $_[0]"; }

# $dba->write_records(@rows);
sub write_records { die "abstract operation on $_[0]"; }

__END__

=head1 DBAdaptor::FlatFile


=head2 Instantiation

=over 4

=item DBAdaptor::FlatFile->new($source_info, $unique_name) : $dba

=back


=head2 Connection Management

=over 4

=item $dba->reader : $fh

=item $dba->writer : $fh

=item $dba->fn : $fn

=item $dba->connect

=item $dba->connect_for_write

=item $dba->disconnect

=back


=head2 Configuration 


=head2 Creation and Deletion of Remote Source

=over 4

=item $dba->source_exists : $count

=item $dba->create_source( $RecordClass )

=back


=head2 Record Access

=over 4

=item $dba->deleterecordbyid($id)

=item $dba->insert($record)

=back


=head2 Bulk Access with Caching

=over 4

=item $dba->fetchall : @rows

=item $dba->overwrite($rows)

=item $dba->load : @rows

=item $dba->write_records(@rows)

=back

=cut
