### DBAdaptor::PropertyList provides access to propertylist text files.

### Interface
  # @rows = $dbadaptor->fetchall;
  # $dbadaptor->overwrite($rows);

### Copyright 1997 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 1997-11-04 Renamed and refreshed.
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-03-10 -Simon

package DBAdaptor::PropertyList;

use DBAdaptor::FlatFile;
@ISA = qw( DBAdaptor::FlatFile );

use Err::Debug;

use Data::Collection;
use Text::PropertyList;

### Record Access

# @rows = $dbadaptor->load;
sub load {
  my $dba = shift;
  
  debug 'dba-plist', "Reading propertylist text records from ", $dba->fn->path;
  
  my $data = fromtext( join('', ( $dba->reader->getlines )) );
  
  return values (%$data);
}

# $dba->write_records( $rows );
sub write_records {
  my $dba = shift;
  my @rows = @_;
  
  my $fh = $dba->writer;
  debug 'dba-plist', "Writing propertylist text records to ", $dba->fn->path;
  
  $fh->print( astext( uniqueindexby($rows, 'id') ) );
  
}

1;

__END__

=head1 DBAdaptor::PropertyList

FlatFile DBAdaptor subclass using the Next PropertyList format.

=head2 Record Access
=over 4
=item @rows = $dbadaptor->fetchall;
=item $dbadaptor->overwrite($rows);
=back
=cut
