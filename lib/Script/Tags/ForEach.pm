### Script::Tags::ForEach defines EvoScript's basic iterator tag.

### Interface
  # [foreach target=#src (count|wordsof|leafnodes) sort|skip|join|periodicjoin]
  # $string = $foreachtag->interpret();
  # $foreach->pick_keys( $args );
  # $foreach->skip_keys($skipper);
  # $foreach->sort_keys($sorter);
  # $results = $loop->do_loop
  # $string = $loop->prefix();
  # $stringvalue = $sequence->interpret_contents();

### To Do
  # - Add support for next and last.
  # - Improve subclassability.

### Copyright 1996, 1997 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-11 Inline POD added.
  # 1997-10-29 Refactored.
  # 1997-03-11 Split from script.tags.pm -Simon
  # 1996-08-01 Initial creation of the foreach tag.

package Script::Tags::ForEach;

$VERSION = 4.00_1998_03_11;

use Script::Container;
@ISA = qw( Script::Container );

use Data::DRef;
use Data::Collection;
use Text::Words qw( string2list );

Script::Tags::ForEach->register_subclass_name();
sub subclass_name { 'foreach' }

# [foreach target=#src (count|wordsof|leafnodes) sort|skip|join|periodicjoin]
%ArgumentDefinitions = (
  'target' =>	{'dref' => 'optional', 'required'=>'anything'},
  
  'count' => 	{'dref' => 'no', 'required'=>'flag'},
  'wordsof' => 	{'dref'=>'no', 'required'=>'flag'},
  'leafnodes' => {'dref'=>'no', 'required'=>'flag'},
  
  'sort' => 	{'dref'=>'no', 'required'=>'string_or_nothing'},
  'skip' => 	{'dref'=>'no', 'required'=>'string_or_nothing'},
  
  'join' => 	{'dref'=>'no', 'required'=>'string_or_nothing'},
  'periodicjoin' => {'dref'=>'no', 'required'=>'string_or_nothing'},
);

# $string = $foreachtag->interpret();
sub interpret {
  my $tag = shift;
  my $args = $tag->get_args;
  
  $tag->pick_keys( $args );
  
  $tag->skip_keys( $args->{'skip'} ) if ( $args->{'skip'} );
  $tag->sort_keys( $args->{'sort'} ) if ( $args->{'sort'} );
  
  $tag->{'join'} = $args->{'join'};
  ($tag->{'pjoin_count'}, $args->{'pjoin_text'}) = 
	split(/\s+/, $args->{'periodicjoin'}, 2) if ($args->{'periodicjoin'});
  
  $tag->{'outer'} = $Root->{'loop'};
  local $Root->{'loop'} = $tag;
  
  my $results = $tag->do_loop;
  
  $tag->{'target'} = $tag->{'keys'} = '';
  
  return $results;
}

# $foreach->pick_keys( $args );
sub pick_keys {
  my $tag = shift;
  my $args = shift;
  
  my $target = $args->{'target'};
  
  if ( $args->{'count'} ) {
    $tag->{'target'} = [ 1 .. $args->{'target'} ];
  } elsif ( $args->{'wordsof'} ) {
    $tag->{'target'} = [ string2list($target) ];
  } else {
    $tag->{'target'} = $args->{'target'};
  }
  
  $tag->{'keys'} = [ $args->{'leafnodes'} ? scalarkeysof($tag->{'target'}) 
					  : keysof($tag->{'target'})     ];
}

# $foreach->skip_keys($skipper);
sub skip_keys {
  my $tag = shift;
  my $skipper = shift;
  
  @{$tag->{'keys'}} = map { $_ !~ /\A$skipper\Z/ } @{$tag->{'keys'}};  
}

# $foreach->sort_keys($sorter);
sub sort_keys {
  my $tag = shift;
  my $sorter = shift;
  
  return unless $sorter;
  
  if ($sorter eq 'key') {
    @{$tag->{'keys'}} = sort @{$tag->{'keys'}};
  } 
  elsif ($sorter) {
    @{$tag->{'keys'}} = sort {
	    getDRef($target, joindref($a, $sorter) ) 
	cmp getDRef($target, joindref($b, $sorter) ) 
    } @{$tag->{'keys'}};
  }
}

# $results = $loop->do_loop
sub do_loop {
  my $loop = shift;
  
  my $results = '';
  $loop->{'count'} = 0;
  
  my $key;
  foreach $key ( @{$loop->{'keys'}} ) {
    $loop->{'key'} = $key;
    $loop->{'value'} = getDRef($loop->{'target'}, $loop->{'key'});
    $results .= $loop->prefix();
    $results .= $loop->interpret_contents();
    $loop->{'count'} ++;
  }
  
  return $results;
}

# $string = $loop->prefix();
sub prefix {
  my $loop = shift;
  
  # no prefix before 0th element
  return '' unless ( $loop->{'count'} );
  
  return $loop->{'pjoin_text'} if ($loop->{'pjoin_count'} and 
				 ! $loop->{'count'} % $loop->{'pjoin_count'});
  
  return $loop->{'join'} if ($loop->{'join'});
  
  return '';
}

1;

__END__

=head1 ForEach

Iterates over a series of items, evaluating its contents for each one.

    [forach target=#request.path.names]
      [print value=#loop.value]
    [/forach]

The target can be a reference to a hash or array, or a string to be used with the count or wordsof arguments. 

During each iteration, the key and value for this pass are exposed in the DRefs #loop.key and #loop.value. Within a nested loop you can use the loop's 'outer' attribute to refer to the enclosing loop; for example, you could write #loop.outer.outer.key to refer to the current key in the outermost of three nested loops. 

=over 4

=item target

The source of the items to iterate over. Use '#' for DRefs. Required argument. 

=item count

Optional flag. Iterate from 1 to the numeric value of target.

    [forach count target=5][print value=#loop.value][/forach]

=item wordsof

Optional flag. Iterate over the space-separated words of the target.

    [forach wordsof target="One Two Three"][print value=#loop.value][/forach]

=item leafnodes

Optional flag. Iterate over the non-referential leaf nodes of a nested structure at target, using Data::Collection's scalarkeysof() function. 

=item sort

Optional. A DRef by which to sort the keys, or the value 'key' to sort by the keys themselves. 

=item skip

Optional. A regular expression for keys which should be skipped. 

=item join

Optional. A string to be interposed between each repetition of the loop. 

=item periodicjoin

Optional. Set this to a number followed by a space and some text; between every number-th repetitions this text will be inserted. When this occurs, the join argument is I<not> used.

=back

=cut