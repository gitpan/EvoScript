### Data::Criteria provides a collection of classes modeling selection rules

### Basic Calling Interface
  # @matches = match_criteria( @$criteria, @$records );
  # $crit = new_group_from_values( @criteria );
  # @matches = $crit->matchers( @$records );

### Instantiation
  # SubclassFactory: subclasses_by_name %CriteriaClasses 
  # $crit = Data::Criteria->new_from_hash( $hashref );
  # $crit = Data::Criteria->new_from_def( $hashref );
  # $crit = Data::Criteria->new_from_value( $crit_hashref_or_string );

### Base Criteria Methods
  # $flag = $crit->matches( $record );		// Abstract
  # $sql_where_clause = $crit->sql( $dba );	// Abstract

### Data::Criteria::Simple - Abstract class for key-match-value criteria
  # $crit = Data::Criteria::Simple->new_from_string($field_match_value);
  # $crit = Data::Criteria::Simple::SUBCLASS->new_kv($key, $value);
  # $value = $crit->value( $record );

### Data::Criteria::SimpleSQL - Abstract superclass for atomic SQL equivalents
  # $sql_where_clause = $crit->sql( $dba );
  # $operator = $crit->sql_comparator();	// Abstract
  # $qvalue = $crit->db_quoted_value( $dba );
  # $qvalue = $crit->db_quote( $dba, $value );

### Data::Criteria::StringEquality - A string against which to match exactly
  # Concrete subclass of Data::Criteria::SimpleSQL, named 'isstring'
  # $flag = $crit->matches( $record );
  # $eq = $crit->sql_comparator( $dba );

### Data::Criteria::Like - SQL regular expression matching
  # Concrete subclass of Data::Criteria::SimpleSQL, named 'like'
  # $flag = $crit->matches( $record );
  # $regex = $crit->regex(); 
  # $eq = $crit->sql_comparator( $dba );

### Data::Criteria::SubString 
  # Concrete subclass of Data::Criteria::SimpleSQL, named 'substring'
  # $flag = $crit->matches( $record );
  # $eq = $crit->sql_comparator( $dba );
  # $qvalue = $crit->db_quoted_value( $dba );

### Data::Criteria::CaseInsensitiveSubString 
  # Concrete subclass of Data::Criteria::SimpleSQL, named 'insenstivesubstring'
  # $flag = $crit->matches( $record );
  # $sql_where_clause = $crit->sql( $dba );
  # $qval = $crit->db_quote( $dba, $value )

### Data::Criteria::NumericEquality - A basic numeric value comparison
  # Concrete subclass of Data::Criteria::SimpleSQL, named 'isequal'
  # sub inverse { 'Data::Criteria::NumericInequality' }
  # $flag = $crit->matches( $record );
  # $eq = $crit->sql_comparator( $dba );

### Data::Criteria::NumericGreater
  # Concrete subclass of Data::Criteria::SimpleSQL, named 'greaterthan'
  # $flag = $crit->matches( $record );
  # $gt = $crit->sql_comparator()

### Data::Criteria::NumericLesser
  # Concrete subclass of Data::Criteria::SimpleSQL, named 'lessthan'
  # $flag = $crit->matches( $record );
  # $lt = $crit->sql_comparator()

### Data::Criteria::NumericGreaterOrEqual
  # Concrete subclass of Data::Criteria::SimpleSQL, named 'greaterthanorequal'
  # $flag = $crit->matches( $record );
  # $gt = $crit->sql_comparator()

### Data::Criteria::NumericLesserOrEqual
  # Concrete subclass of Data::Criteria::SimpleSQL, named 'lessthanorequal'
  # $flag = $crit->matches( $record );
  # $lt = $crit->sql_comparator()

### Data::Criteria::StringInequality
  # Concrete subclass of Data::Criteria::Simple, named 'isnotstring'
  # $flag = $crit->matches( $record );

### Data::Criteria::StringInList - Allows you to match any of several strings
  # Concrete subclass of Data::Criteria::Simple, named 'isstringinlist'
  # $flag = $crit->matches( $record );
  # $sql_where_clause = $crit->sql( $dba );
  # $crit = $crit->expand();

### Data::Criteria::MultiMatch, nee "twiddle"
  # Concrete subclass of Data::Criteria, named 'twiddle'
  # $flag = $crit->matches( $record );
  # $sql_where_clause = $crit->sql( $dba );
  # $crit = $crit->expand();

### Data::Criteria::Group
  # $crit = Data::Criteria::Group->new_empty()
  # @subs or @$subs = $crit->subs
  # $crit->add_sub( $sub );
  # @clauses = $crit->sql_sub_clauses( $dba );
  # $clause = $crit->join_clauses( $joiner, @subclauses );

### Data::Criteria::And
  # Concrete subclass of Data::Criteria::Group, named 'and'
  # $flag = $crit->matches( $record );
  # $sql_where_clause = $crit->sql( $dba );

### Data::Criteria::Or
  # Concrete subclass of Data::Criteria::Group, named 'or'
  # $flag = $crit->matches( $record );
  # $sql_where_clause = $crit->sql( $dba );

### To Do
  # - Contemplate the name of this package. Data::Criterion? Data::Selector??
  # - Move the matching_values/matching_keys multi-key criteria functionality 
  # out of Data::Colllection and export it back.
  # - Complete integration of SQL criteria, including updated version of the
  # fail-through mechanism for non-SQL (or partial) criteria.
  # - During alpha, look for methods to optimize for speed.

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-06-02 Added startswith criteria to handle alpha control. -EJM
  # 1998-04-09 Modified match_criteria to handle pre-built criteria objects.
  # 1997-11-26 Some debugging.
  # 1997-11-16 Completed remaining SQL methods, including twiddle expansion
  # 1997-11-09 Separated Simple and SimpleSQL; worked on simple call interface
  # 1997-11-07 Abstracted Group and Simple superclasses.
  # 1997-11-06 Created the new, OOP version of this package.
  # 1997-11-04 Removed these functions from DBAdaptor and exported 'em back.

package Data::Criteria;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT, qw( match_criteria new_group_from_values );

use Carp;

### Basic Calling Interface

# @matches = match_criteria( @$criteria, @$records );
sub match_criteria {
  my $crit = shift;
  $crit = new_group_from_values( @$crit) if ( ref $crit eq 'ARRAY' );
  return $crit->matchers( shift );
}

# $crit = new_group_from_values( @criteria );
sub new_group_from_values {
 my $crit = Data::Criteria::And->new_empty();
  foreach $string ( @_ ) { 
    $crit->add_sub( Data::Criteria::Simple->new_from_value( $string ) );
  }
  return $crit;
}

# @matches = $crit->matchers( @$records );
sub matchers {
  my $crit = shift;
  # warn "looking for matchers for '$crit'\n";
  my $records = shift;
  return grep { $crit->matches( $_ ) } ( @$records );
}

### Instantiation

# SubclassFactory: subclasses_by_name %CriteriaClasses 
use Class::NamedFactory;
push @ISA, qw( Class::NamedFactory );
use vars qw( %CriteriaClasses );
sub subclasses_by_name { \%CriteriaClasses; }

# $crit = Data::Criteria->new_from_hash( $hashref );
sub new_from_hash {
  my $package = shift;
  my $hashref = shift;
  bless $hashref, $package;
}

# $crit = Data::Criteria->new_from_def( $hashref );
sub new_from_def {
  my $package = shift;
  my $hashref = shift;
  my $subclass = $package->subclass_by_name($hashref->{'match'} || 'isstring');
  $subclass or die "unknown match style '$hashref->{'match'}'\n";
  $subclass->new_from_hash( $hashref );
}

# $crit = Data::Criteria->new_from_value( $crit_hashref_or_string );
  # Given some scalar value, do the best we can to return a criterion.
sub new_from_value {
  my $package = shift;
  my $value = shift;
  return $value if ( UNIVERSAL::isa($value, $package) );
  return $package->new_from_string( $value ) if ( ! ref $value );
  return $package->new_from_def( $value ) if ( ref $value eq 'HASH');
  croak "unknown criteria format '$value'";
}

### Base Criteria Methods

use Carp;

# $flag = $crit->matches( $record );		// Abstract
sub matches { croak "abstract method called on $_[0]"; }

# $sql_where_clause = $crit->sql( $dba );	// Abstract
sub sql { croak "abstract method called on $_[0]"; }

### Data::Criteria::Simple - Abstract class for key-match-value criteria

package Data::Criteria::Simple;
push @ISA, qw( Data::Criteria );

# $crit = Data::Criteria::Simple->new_from_string($field_match_value);
sub new_from_string {
  my $package = shift;
  my $string = shift;
  my ($name, $match, $value) = split(' ', $string, 3);
  $package->new_from_def( { 'key'=>$name, 'match'=>$match, 'value'=>$value } );
}

# $crit = Data::Criteria::Simple::SUBCLASS->new_kv($key, $value);
sub new_kv {
  my $package = shift;
  $package->new_from_hash( { 'match' => $package->subclass_name, 
			      'key' => shift, 'value' => shift } );
}

# $value = $crit->value( $record );
sub value {
  my ($crit, $record) = @_;
  return $record->{ $crit->{'key'} };
}

### Data::Criteria::SimpleSQL - Abstract superclass for atomic SQL equivalents

package Data::Criteria::SimpleSQL;
push @ISA, qw( Data::Criteria::Simple );

use Err::Debug;
use Data::Collection;

# $sql_where_clause = $crit->sql( $dba );
sub sql {
  my ($crit, $dba) = @_;
  return unless (defined $crit->{'value'});
  # warn "sqlign crit ref " . (ref $crit) . " key $crit->{'key'} value $crit->{'value'} \n";
  return $crit->{'key'} . ' ' . $crit->sql_comparator( $dba ) . ' ' . 
  				$crit->db_quoted_value( $dba );
};

# $operator = $crit->sql_comparator();	// Abstract
sub sql_comparator { die "abstract"; }

# $qvalue = $crit->db_quoted_value( $dba );
sub db_quoted_value {
  my ($crit, $dba) = @_;
  $crit->db_quote( $dba, $crit->{'value'});
}

# $qvalue = $crit->db_quote( $dba, $value );
sub db_quote {
  my ($crit, $dba, $value) = @_;
  my $db_field = matching_values($dba->fields, 'name' => $crit->{'key'});
  debug('criteria', "field named $crit->{'key'} is ", $db_field );
  $dba->quote_by_type($db_field->{'type'}, $value);
}

### Data::Criteria::StringEquality - A string against which to match exactly

package Data::Criteria::StringEquality;

# Concrete subclass of Data::Criteria::SimpleSQL, named 'isstring'
push @ISA, qw( Data::Criteria::SimpleSQL );
Data::Criteria::StringEquality->register_subclass_name();
sub subclass_name { 'isstring' }
sub inverse { 'Data::Criteria::StringInequality' }

# $flag = $crit->matches( $record );
sub matches {
  my ($crit, $record) = @_;
  return ($crit->value( $record ) eq $crit->{'value'}) ? 1 : 0;
}

# $eq = $crit->sql_comparator( $dba );
sub sql_comparator { return '='; }

### Data::Criteria::Like - SQL regular expression matching

package Data::Criteria::Like;

# Concrete subclass of Data::Criteria::SimpleSQL, named 'like'
push @ISA, qw( Data::Criteria::SimpleSQL );
Data::Criteria::Like->register_subclass_name();
sub subclass_name { 'like' }

# $flag = $crit->matches( $record );
sub matches {
  my ($crit, $record) = @_;
  my $regex = $crit->regex(); 
  return ($crit->value( $record ) =~ /$regex/) ? 1 : 0;
}

# $regex = $crit->regex(); 
  # Map a SQL 'like' regex into its perl equivalent - '_' => /./, '%' => /.*/ 
sub regex {
  my $crit = shift;
  my $value = $crit->{'value'};
  $value = quotemeta( $value );
  $value =~ s/\%/\.\*/g;
  $value =~ s/\_/\./g;
  return $value;
}

# $eq = $crit->sql_comparator( $dba );
sub sql_comparator { return 'like'; }

### Data::Criteria::SubString 

package Data::Criteria::SubString;

# Concrete subclass of Data::Criteria::SimpleSQL, named 'substring'
push @ISA, qw( Data::Criteria::SimpleSQL );
Data::Criteria::SubString->register_subclass_name();
sub subclass_name { 'substring' }

# $flag = $crit->matches( $record );
sub matches {
  my ($crit, $record) = @_;
  
  return ($record->{$crit->{'key'}} =~ /\Q$crit->{'value'}\E/) ? 1 : 0;
}

# $eq = $crit->sql_comparator( $dba );
sub sql_comparator { return 'like'; }

# $qvalue = $crit->db_quoted_value( $dba );
sub db_quoted_value {
  my ($crit, $dba) = @_;
  my ($value, $escape) = $dba->sql_escape_for_like($crit->{'value'});
  $escape ||= '';
  $crit->db_quote( $dba, '%' . $value . '%') . $escape;
}

### Data::Criteria::CaseInsensitiveSubString 

package Data::Criteria::CaseInsensitiveSubString;

# Concrete subclass of Data::Criteria::SimpleSQL, named 'insenstivesubstring'
push @ISA, qw( Data::Criteria::SubString );
Data::Criteria::CaseInsensitiveSubString->register_subclass_name();
sub subclass_name { 'insenstivesubstring' }

# $flag = $crit->matches( $record );
sub matches {
  my ($crit, $record) = @_;
  
  return ($record->{$crit->{'key'}} =~ /\Q$crit->{'value'}\E/i) ? 1 : 0;
}

# $sql_where_clause = $crit->sql( $dba );
sub sql {
  my ($crit, $dba) = @_;
  return unless (defined $crit->{'value'});
  
  # escape any SQL-regex characters in the string
  my ($value, $escape) = $dba->sql_escape_for_like($crit->{'value'});
  
  my $fname = $crit->{'key'};
  
  my $dbtype = $dba->server_type;
  
  # setup for case insensitivity
  if ($dbtype eq 'mssql' or $dbtype eq 'mysql') {
    # under MS-SQL, like is always case insensitive, so no change here.
  } elsif ($dbtype eq 'sybase' or $dbtype eq 'informix') {
    $value =~ s/(\w)/\[\u$1\l$1\]/g;
  } elsif ($dbtype eq 'oracle') {
    $value = uc($value);
    $fname = "UPPER($fname)";
  } elsif ($dbtype eq 'db2') {
    $value = uc($value);
    $fname = "TRANSLATE($fname)";
  } else {
    # we don't know how to do case insensitve operations elsewhere.
  }
  
  my $comparator = ( $dba->server_type eq 'informix' ) ? 'matches' : 'like';
  $value = ( $dba->server_type eq 'informix' ) ? '*' . $value . '*'  :
  						 '%' . $value . '%';
  
  return $fname . ' ' . $comparator . ' ' . 
  			$crit->db_quote( $dba, $value ) . $escape; 
}

# $qval = $crit->db_quote( $dba, $value )
sub db_quote {
  my ( $crit, $dba, $value ) = @_;
}

### Data::Criteria::StartsWith

package Data::Criteria::StartsWith;

# Concrete subclass of Data::Criteria::SimpleSQL, named 'startswith'
push @ISA, qw( Data::Criteria::SubString );
Data::Criteria::StartsWith->register_subclass_name();
sub subclass_name { 'startswith' }

# $flag = $crit->matches( $record );
sub matches {
  my ($crit, $record) = @_;
  
  return ($record->{$crit->{'key'}} =~ /\Q$crit->{'value'}\E/i) ? 1 : 0;
}

# $sql_where_clause = $crit->sql( $dba );
sub sql {
  my ($crit, $dba) = @_;
  return unless (defined $crit->{'value'});
  
  # escape any SQL-regex characters in the string
  my ($value, $escape) = $dba->sql_escape_for_like($crit->{'value'});
  
  my $fname = $crit->{'key'};
  
  my $dbtype = $dba->server_type;
  
  # setup for case insensitivity
  if ($dbtype eq 'mssql' or $dbtype eq 'mysql') {
    # under MS-SQL, like is always case insensitive, so no change here.
  } elsif ($dbtype eq 'sybase' or $dbtype eq 'informix') {
    $value =~ s/(\w)/\[\u$1\l$1\]/g;
  } elsif ($dbtype eq 'oracle') {
    $value = uc($value);
    $fname = "UPPER($fname)";
  } elsif ($dbtype eq 'db2') {
    $value = uc($value);
    $fname = "TRANSLATE($fname)";
  } else {
    # we don't know how to do case insensitve operations elsewhere.
  }
  
  my $comparator = ( $dba->server_type eq 'informix' ) ? 'matches' : 'like';
  $value = $value . ( $dba->server_type eq 'informix' ? '*' : '%' );
  
  return $fname . ' ' . $comparator . ' ' . 
  			$crit->db_quote( $dba, $value ) . $escape; 
}

# $qval = $crit->db_quote( $dba, $value )
sub db_quote {
  my ( $crit, $dba, $value ) = @_;
  return join '', "'", $value, "'";
}

### Data::Criteria::NumericEquality - A basic numeric value comparison

package Data::Criteria::NumericEquality;

# Concrete subclass of Data::Criteria::SimpleSQL, named 'isequal'
push @ISA, qw( Data::Criteria::SimpleSQL );
Data::Criteria::NumericEquality->register_subclass_name();
sub subclass_name { 'isequal' }
# sub inverse { 'Data::Criteria::NumericInequality' }

# $flag = $crit->matches( $record );
sub matches {
  my ($crit, $record) = @_;
  return ($crit->value( $record ) == $crit->{'value'}) ? 1 : 0;
}

# $eq = $crit->sql_comparator( $dba );
sub sql_comparator { return '='; }

### Data::Criteria::NumericGreater

package Data::Criteria::NumericGreater;

# Concrete subclass of Data::Criteria::SimpleSQL, named 'greaterthan'
push @ISA, qw( Data::Criteria::SimpleSQL );
Data::Criteria::NumericGreater->register_subclass_name( );
sub subclass_name { 'greaterthan' }
sub inverse { 'Data::Criteria::NumericLesserOrEqual' }

# $flag = $crit->matches( $record );
sub matches {
  my ($crit, $record) = @_;
  return ($crit->value( $record ) > $crit->{'value'}) ? 1 : 0;
}

# $gt = $crit->sql_comparator()
sub sql_comparator { return '>'; }

### Data::Criteria::NumericLesser

package Data::Criteria::NumericLesser;

# Concrete subclass of Data::Criteria::SimpleSQL, named 'lessthan'
push @ISA, qw( Data::Criteria::SimpleSQL );
Data::Criteria::NumericLesser->register_subclass_name( );
sub subclass_name { 'lessthan' }
sub inverse { 'Data::Criteria::NumericGreaterOrEqual' }

# $flag = $crit->matches( $record );
sub matches {
  my ($crit, $record) = @_;
  return ($crit->value( $record ) < $crit->{'value'}) ? 1 : 0;
}

# $lt = $crit->sql_comparator()
sub sql_comparator { return '<'; }

### Data::Criteria::NumericGreaterOrEqual

package Data::Criteria::NumericGreaterOrEqual;

# Concrete subclass of Data::Criteria::SimpleSQL, named 'greaterthanorequal'
push @ISA, qw( Data::Criteria::SimpleSQL );
Data::Criteria::NumericGreaterOrEqual->register_subclass_name( );
sub subclass_name { 'greaterthanorequal' }
sub inverse { 'Data::Criteria::NumericLesser' }

# $flag = $crit->matches( $record );
sub matches {
  my ($crit, $record) = @_;
  return ($crit->value( $record ) >= $crit->{'value'}) ? 1 : 0;
}

# $gt = $crit->sql_comparator()
sub sql_comparator { return '>='; }

### Data::Criteria::NumericLesserOrEqual

package Data::Criteria::NumericLesserOrEqual;

# Concrete subclass of Data::Criteria::SimpleSQL, named 'lessthanorequal'
push @ISA, qw( Data::Criteria::SimpleSQL );
Data::Criteria::NumericLesserOrEqual->register_subclass_name( );
sub subclass_name { 'lessthanorequal' }
sub inverse { 'Data::Criteria::NumericGreater' }

# $flag = $crit->matches( $record );
sub matches {
  my ($crit, $record) = @_;
  return ($crit->value( $record ) <= $crit->{'value'}) ? 1 : 0;
}

# $lt = $crit->sql_comparator()
sub sql_comparator { return '<='; }

### Data::Criteria::StringInequality

package Data::Criteria::StringInequality;

# Concrete subclass of Data::Criteria::Simple, named 'isnotstring'
push @ISA, qw( Data::Criteria::Simple );
Data::Criteria::StringInequality->register_subclass_name();
sub subclass_name { 'isnotstring' }
sub inverse { 'Data::Criteria::StringEquality' }

# $flag = $crit->matches( $record );
sub matches {
  my ($crit, $record) = @_;
  return ($crit->value( $record ) ne $crit->{'value'}) ? 1 : 0;
}

### Data::Criteria::StringInList - Allows you to match any of several strings

package Data::Criteria::StringInList;

# Concrete subclass of Data::Criteria::Simple, named 'isstringinlist'
push @ISA, qw( Data::Criteria::Simple );
Data::Criteria::StringInList->register_subclass_name();
sub subclass_name { 'isstringinlist' }

use Text::Words;
use Data::Collection;

# $flag = $crit->matches( $record );
sub matches {
  my ($crit, $record) = @_;
  
  my $value = $crit->value( $record );  
  my @strings = ref $crit->{'value'} ? @{$crit->{'value'}} : $crit->{'value'};
  foreach $string ( @strings ) {
    return 1 if ($value eq $string) 
  }
}

# $sql_where_clause = $crit->sql( $dba );
sub sql {
  my ($crit, $dba) = @_;
  
  $crit->expand->sql( $dba );
};

# $crit = $crit->expand();
sub expand {
  my $crit = shift;
  
  my $values = $crit->{'value'};
  $values = [ string2list( $values ) ] if (! ref $values);
  $values = array_by_hash_key( $values ) if (UNIVERSAL::isa($values,'HASH'));
    
  my $expansion = Data::Criteria::Or->new_empty();
  foreach $value (@$values) {
    next unless (defined $value and length $value);
    my $kvcrit = Data::Criteria::StringEquality->new_kv(
						    $crit->{'key'}, $value);
    $expansion->add_sub( $kvcrit );
  }
  return $expansion;
}

### Data::Criteria::MultiMatch, nee "twiddle"

package Data::Criteria::MultiMatch;

# Concrete subclass of Data::Criteria, named 'twiddle'
push @ISA, qw( Data::Criteria );
Data::Criteria::MultiMatch->register_subclass_name();
sub subclass_name { 'multimatch' }

use Text::Words;

# $flag = $crit->matches( $record );
sub matches {
  my ($crit, $record) = @_;
  
  my $fields = [ string2list( $crit->{'key'} ) ];
  
  foreach $value ( string2list( $crit->{'value'} ) ) {
    next unless (length $value);
    foreach $field (@$fields) {
      return 1 if ( $record->{$field} =~ /\Q$value\E/i );
    }
  }
  return 0;
}

# $sql_where_clause = $crit->sql( $dba );
sub sql {
  my ($crit, $dba) = @_;
  
  $crit->expand->sql( $dba );
};

# $crit = $crit->expand();
sub expand {
  my $crit = shift;
  
  my $values = $crit->{'value'};
  $values = [ string2list( $values ) ] unless (ref $values);
  
  my $fields = $crit->{'key'};
  $fields = [ string2list( $fields ) ] unless (ref $fields);
  
  my $expansion = Data::Criteria::Or->new_empty();
  my $fieldname;
  foreach $fieldname (@$fields) {
    next unless (defined $fieldname and length $fieldname);
    my $subclause = Data::Criteria::Or->new_empty();
    foreach $value (@$values) {
      next unless (defined $value and length $value);
      my $kvcrit = Data::Criteria::SubString->new_kv($fieldname, $value);
      $subclause->add_sub( $kvcrit );
    }
    $expansion->add_sub( $subclause );
  }
  return $expansion;
}

### Data::Criteria::Group

package Data::Criteria::Group;
push @ISA, qw( Data::Criteria );

use Data::Collection;

# $crit = Data::Criteria::Group->new_empty()
sub new_empty {
  my $package = shift;
  $package->new_from_hash( { 'subs' => [] } );
}

# @subs or @$subs = $crit->subs
sub subs {
  my $crit = shift;
  wantarray ? @{ $crit->{'subs'} } : $crit->{'subs'};
}

# $crit->add_sub( $other_crit );
sub add_sub {
  my $crit = shift;
  my $sub = shift;
  push @{ $crit->subs }, $sub;
}

# @clauses = $crit->sql_sub_clauses( $dba );
sub sql_sub_clauses {
  my ($crit, $dba) = @_;
  return map {  $_->sql( $dba ) } ( $crit->subs );
}

# $clause = $crit->join_clauses( $joiner, @subclauses );
sub join_clauses {
  my ($crit, $joiner, @clauses) = @_;
  return $clauses[0] unless ( scalar @clauses > 1 );
  return '(' . join(' ' . $joiner . ' ', @clauses) . ')';
}

### Data::Criteria::And

package Data::Criteria::And;

# Concrete subclass of Data::Criteria::Group, named 'and'
push @ISA, qw( Data::Criteria::Group );
Data::Criteria::And->register_subclass_name( );
sub subclass_name { 'and' }

# $flag = $crit->matches( $record );
sub matches {
  my $crit = shift;
  my $record = shift;
  # warn "matching '$record'\n";
  foreach $sub ( $crit->subs ) {
    return 0 unless ( $sub->matches( $record ) );
    # warn "matched '$sub'\n";
  }
  return 1;
}

# $sql_where_clause = $crit->sql( $dba );
sub sql {
  my ($crit, $dba) = @_;
  $crit->join_clauses( 'and', $crit->sql_sub_clauses( $dba ) );
};

### Data::Criteria::Or

package Data::Criteria::Or;

# Concrete subclass of Data::Criteria::Group, named 'or'
push @ISA, qw( Data::Criteria::Group );
Data::Criteria::Or->register_subclass_name( );
sub subclass_name { 'or' }

# $flag = $crit->matches( $record );
sub matches {
  my $crit = shift;
  my $record = shift;
  foreach $sub ( $crit->subs ) {
    return 1 if ( $sub->matches( $record ) );
  }
  return 0;
}

# $sql_where_clause = $crit->sql( $dba );
sub sql {
  my ($crit, $dba) = @_;
  $crit->join_clauses( 'or', $crit->sql_sub_clauses( $dba ) );
};

1;

__END__

=head1 Data::Criteria

Data::Criteria provides a collection of classes modeling selection rules

=head2 Basic Calling Interface
=over 4
=item @matches = match_criteria( @$criteria, @$records );
=item $crit = new_group_from_values( @criteria );
=item @matches = $crit->matchers( @$records );
=back

=head2 Instantiation
=over 4
=item SubclassFactory: subclasses_by_name %CriteriaClasses 
=item $crit = Data::Criteria->new_from_hash( $hashref );
=item $crit = Data::Criteria->new_from_def( $hashref );
=item $crit = Data::Criteria->new_from_value( $crit_hashref_or_string );
=back

=head2 Base Criteria Methods
=over 4
=item $flag = $crit->matches( $record );                // Abstract
=item $sql_where_clause = $crit->sql( $dba );   // Abstract
=back

=head1 Data::Criteria::Simple;

Abstract class for key-match-value criteria

=over 4
=item $crit = Data::Criteria::Simple->new_from_string($field_match_value);
=item $crit = Data::Criteria::Simple::SUBCLASS->new_kv($key, $value);
=item $value = $crit->value( $record );
=back

=head1 Data::Criteria::SimpleSQL

Abstract superclass for atomic SQL equivalents

=over 4
=item $sql_where_clause = $crit->sql( $dba );
=item $operator = $crit->sql_comparator();      // Abstract
=item $qvalue = $crit->db_quoted_value( $dba );
=item $qvalue = $crit->db_quote( $dba, $value );
=back

=head1 Data::Criteria::StringEquality

A string against which to match exactly
 
=over 4
=item Concrete subclass of Data::Criteria::SimpleSQL, named 'isstring'
=item $flag = $crit->matches( $record );
=item $eq = $crit->sql_comparator( $dba );
=back

=head1 Data::Criteria::Like

SQL regular expression matching

=over 4
=item Concrete subclass of Data::Criteria::SimpleSQL, named 'like'
=item $flag = $crit->matches( $record );
=item $regex = $crit->regex(); 
=item $eq = $crit->sql_comparator( $dba );
=back

=head1 Data::Criteria::SubString

=over 4
=item Concrete subclass of Data::Criteria::SimpleSQL, named 'substring'
=item $flag = $crit->matches( $record );
=item $eq = $crit->sql_comparator( $dba );
=item $qvalue = $crit->db_quoted_value( $dba );
=back

=head1 Data::Criteria::CaseInsensitiveSubString

=over 4
=item Concrete subclass of Data::Criteria::SimpleSQL, named 'insenstivesubstring'
=item $flag = $crit->matches( $record );
=item $sql_where_clause = $crit->sql( $dba );
=item $qval = $crit->db_quote( $dba, $value )
=back

=head1 Data::Criteria::NumericEquality

A basic numeric value comparison

=over 4
=item Concrete subclass of Data::Criteria::SimpleSQL, named 'isequal'
=item sub inverse { 'Data::Criteria::NumericInequality' }
=item $flag = $crit->matches( $record );
=item $eq = $crit->sql_comparator( $dba );
=back

=head1 Data::Criteria::NumericGreater
=over 4
=item Concrete subclass of Data::Criteria::SimpleSQL, named 'greaterthan'
=item $flag = $crit->matches( $record );
=item $gt = $crit->sql_comparator()
=back

=head1 Data::Criteria::NumericLesser
=over 4
=item Concrete subclass of Data::Criteria::SimpleSQL, named 'lessthan'
=item $flag = $crit->matches( $record );
=item $lt = $crit->sql_comparator()
=back

=head1 Data::Criteria::NumericGreaterOrEqual
=over 4
=item Concrete subclass of Data::Criteria::SimpleSQL, named 'greaterthanorequal'
=item $flag = $crit->matches( $record );
=item $gt = $crit->sql_comparator()
=back

=head1 Data::Criteria::NumericLesserOrEqual
=over 4
=item Concrete subclass of Data::Criteria::SimpleSQL, named 'lessthanorequal'
=item $flag = $crit->matches( $record );
=item $lt = $crit->sql_comparator()
=back

=head1 Data::Criteria::StringInequality
=over 4
=item Concrete subclass of Data::Criteria::Simple, named 'isnotstring'
=item $flag = $crit->matches( $record );
=back

=head1 Data::Criteria::StringInList

Allows you to match any of several strings

=over 4
=item Concrete subclass of Data::Criteria::Simple, named 'isstringinlist'
=item $flag = $crit->matches( $record );
=item $sql_where_clause = $crit->sql( $dba );
=item $crit = $crit->expand();
=back

=head1 Data::Criteria::MultiMatch

Multiword substring matching. Previously known as "twiddle".

=over 4
=item Concrete subclass of Data::Criteria, named 'twiddle'
=item $flag = $crit->matches( $record );
=item $sql_where_clause = $crit->sql( $dba );
=item $crit = $crit->expand();
=back

=head1 Data::Criteria::Group

Abstract superclass for a criteria composed of other criteria.

=over 4
=item $crit = Data::Criteria::Group->new_empty()
=item @subs or @$subs = $crit->subs
=item $crit->add_sub( $other_crit );
=item @clauses = $crit->sql_sub_clauses( $dba );
=item $clause = $crit->join_clauses( $joiner, @subclauses );
=back

=head1 Data::Criteria::And

Group that requires each of its criteria to be met.

=over 4
=item Concrete subclass of Data::Criteria::Group, named 'and'
=item $flag = $crit->matches( $record );
=item $sql_where_clause = $crit->sql( $dba );
=back

=head1 Data::Criteria::Or

Group that is satisfied if any one of its criteria is met.

=over 4
=item Concrete subclass of Data::Criteria::Group, named 'or'
=item $flag = $crit->matches( $record );
=item $sql_where_clause = $crit->sql( $dba );
=back

=cut