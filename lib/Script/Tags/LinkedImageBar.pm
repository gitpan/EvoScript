### Script::Tags::LinkedImageBar expands to a animated set of linked images

### Interface
  # [linkedimagebar items=#my.links imgsrc=/images]
  # $text = $imgbartag->interpret();

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-03-11 Inline POD added.
  # 1998-03-11 Added suffix and hisuffix arguments, inlined JavaScript.
  # 1998-01-26 Created. -Simon

package Script::Tags::LinkedImageBar;

$VERSION = 4.00_1998_03_11;

use Script::HTML::Tables;

use Script::Tag;
@ISA = qw( Script::Tag );

use Script::HTML::Tag;
use Script::HTML::Pages;
use Script::HTML::Links;

# [LinkedImageBar record=#x]
Script::Tags::LinkedImageBar->register_subclass_name();
sub subclass_name { 'LinkedImageBar' }

%ArgumentDefinitions = (
  'items' =>  {'dref' => 'optional', 'required'=>'anything'},
  'imgsrc' =>  {'dref' => 'optional', 'required'=>'non_empty_string'},
  'suffix' =>  {'dref' => 'optional', 'default'=>'_lo.jpg', 'required'=>'non_empty_string'},
  'hisuffix' =>  {'dref' => 'optional', 'default'=>'_hi.jpg', 'required'=>'non_empty_string'},
);

# $text = $htmlmacro->interpret();
sub interpret {
  my $btnbar = shift;
  return $btnbar->expand->interpret;
}

# $html_table = $detailtag->expand();
sub expand {
  my $btnbar = shift;
  my $args = $btnbar->get_args;
   
  my $sequence = Script::Sequence->new;
  
  $sequence->add(html_tag('script', { 'language' => 'JavaScript' }, 
    "<!-- // setimgsrc('img_name', 'new_src'); \n" . 
    "function setimgsrc(imageName, imageLocation) { \n". 
    "  if (document.images) document.images[imageName].src = imageLocation;\n".
    "  return true; \n" . 
    "} \n // -->\n"
  ));
  
  my $item;
  foreach $item ( @{$args->{'items'}} ) {
    my $lo_img = $args->{'imgsrc'} . $item->{'name'} . $args->{'suffix'};
    my $hi_img = $args->{'imgsrc'} . $item->{'name'} . $args->{'hisuffix'};
    $sequence->add(html_tag('a', { 
        'target'=>'content', 
	'href' => $item->{'link'},
	'onMouseOver'=>"setimgsrc('$item->{'name'}', '$hi_img'); return true;", 
	'onMouseOut' =>"setimgsrc('$item->{'name'}', '$lo_img'); return true;",
      },
      html_tag('img', { 'name'=>$item->{'name'}, 'src'=>$lo_img, 'border'=>0,  
      			'alt' => "[\u$item->{'name'}]" }),
    ));
  }
  
  return $sequence;
}

1;

__END__

=head1 LinkedImageBar

Generates a series of images, each one wrapped in a link. JavaScript is appended to provide mouse-over highlight functionality.

    [LinkedImageBar items=#items imgsrc=/images]

=over 4

=item items

A reference to an array of hashes, each with entries for name and link. Use '#' for DRefs. Required argument. 

=item imgsrc

A numeric value to add the the value argument. Use '#' for DRefs. Required argument. 

=item suffix

A string to add to the end of each item name for the image sources. Defaults to '_lo.jpg'. Use '#' for DRefs. 

=item hisuffix

A string to add to the end of each item name for the mouse-over highlight source. Optional. Defaults to '_hi.jpg'. Use '#' for DRefs. 

=back

For each item name, there should be two file in B<imgsrc>, one with that name followed by the B<suffix>, and one followed by the B<hisuffix>. 

=cut