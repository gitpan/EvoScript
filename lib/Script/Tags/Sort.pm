### Script::Tags::Sort provides a tag interface to the sort_by_drefs function

### Interface
  # [sort list=#items keys="dref dref" ( target=#target ) ]
  # $emptystring = $tag->interpret();

### Comments
  # If you pass a target, it gets the sorted values; otherwise the original 
  # list is sorted in place

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-17 Updated to use new Data::Sorting interface.
  # 1998-03-11 Inline POD added.
  # 1998-03-11 Fixed use of old argument name -- thanks Tim! 
  # 1997-11-17 Brought up to four-oh. -Simon

package Script::Tags::Sort;

$VERSION = 4.00_1998_03_11;

use Script::Tag;
@ISA = qw( Script::Tag );

Script::Tags::Sort->register_subclass_name();
sub subclass_name { 'sort' }

use Data::Sorting qw( sort_in_place );

use Data::DRef;

# [sort list=#items keys="dref dref" ( target=#target ) ]
%ArgumentDefinitions = (
  'list' => {'dref'=>'optional', 'required'=>'list'},
  'keys' => {'dref'=>'optional', 'required'=>'list'},
  'target' => {'dref'=>'target', 'required'=>'string_or_nothing'},
);

# $emptystring = $tag->interpret();
sub interpret {
  my $tag = shift;
  my $args = $tag->get_args;
  
  my $sortedlist = $args->{'list'};
  
  setData( $args->{'target'}, ($sortedlist = [@$sortedlist]) )
		if (defined $args->{'target'} and length $args->{'target'});
  
  sort_in_place( $sortedlist, @{ $args->{'key'} } );
  
  return '';
}

1;

__END__

=head1 Sort

Sorts an array of items by looking up as DRefs each of the provided keys.  

    [sort list=#records target=#sorted keys="lastname firstname"]

=over 4

=item list

The items which are to be sorted. Use '#' for DRefs. Required argument.

=item target

Optional. If provided, the list will be copied and the sorted version stored at this DRef; otherwise the list will be sorted in place.

=item keys

The keys to examine within each item. Earlier items in the list take precedence. Use '#' for DRefs. Required argument. 

=back

=cut