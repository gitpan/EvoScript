### DBAdaptor::DelimitedText provides access to tab-delimited text files.

### Should add additional options:
  # - w/ or w/o fieldnames forst
  # - "" around text or all fields, or not
  # - , or \t between items

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)

### Change History
  # 1997-11-04 Updated for four-oh.
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-02-01 A quickie. -Simon

package DBAdaptor::DelimitedText;

use Text::Escape;

### DBAdaptor Subclass (registered as "tabtext")

use DBAdaptor::FlatFile;
@ISA = qw( DBAdaptor::FlatFile );

DBAdaptor::DelimitedText->register_subclass_name( );
sub subclass_name { 'tabtext' }

use Err::Debug;

### Record Access

# @rows = $dba->load;
sub load {
  my $dba = shift;
  
  my $time = time();
  
  my $fh = $dba->reader;
  
  # Get the field names as they were saved
  unless ( $_ = $fh->getline ) {
    die "Delimited Text DBAdaptor: no field names in " . $dba->fn->path;
  }
  chomp;
  $fields = [ $dba->split_sep( $_ ) ];
  $dba->{'fieldnames'} = $fields;
  
  debug 'delimtext', "Reading delimited text records from ", $dba->fn->path;
  
  # Get the rows
  my @rows;
  while ($_ = $fh->getline) {
    chomp;
    my %record;
    @record{@$fields} = escape('unprintable', $dba->split_sep( $_ ) );
    push(@rows, \%record);
  }
  
  debug 'delimtext', "Loading required ", time() - $time, "second(s).";
  
  return @rows;
}

# $dba->write_records( $rows );
sub write_records {
  my $dba = shift;
  my @rows = @_;
  
  my $time = time();
  
  my $fh = $dba->writer;
  debug 'delimtext', "Writing delimited text records to ", $dba->fn->path;
  
  my $fields = $dba->{'fieldnames'};
  $fh->print( $dba->join_sep(@$fields) . "\n" );
  
  foreach $record (@rows) {
    my (%record) = %$record;
    $fh->print( $dba->join_sep(escape('printable', @record{@$fields})) ."\n" );
  }
  
  debug 'delimtext', "Writing required ", time() - $time, "second(s).";
}

### Delimiter Syntax

# $tabchar = $dba->separator();
sub separator { return "\t"; }

# $text = $dba->join_sep( @list );
sub join_sep {
  my $dba = shift;
  return join($dba->separator, @_);
}

# @list = $dba->split_sep( $text );
sub split_sep {
  my $dba = shift;
  my $sep = $dba->separator;
  return split(/\Q$sep\E/, $_[0]);
}

__END__

=head1 DBAdaptor::DelimitedText

DBAdaptor subclass for Tab-Delimited text files. 

Registered as "tabtext"

=head2 Record Access
=over 4
=item @rows = $dba->fetchall;
=item @rows = $dba->load;
=item $dba->overwrite($rows);
=item $dba->write_records( $wfh, $rows );
=back

=head2 Delimiter Syntax
=over 4
=item $tabchar = $dba->separator();
=item $text = $dba->join_sep( @list );
=item @list = $dba->split_sep( $text );
=back

=cut
