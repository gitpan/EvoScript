### Script::HTML::Lists displays HTML selects for lists

### <single title=x values=list>
  # $text = $htmlmacro->interpret()
  # $htmltags = $htmlmacro->expand()

### <dual title=x values=list current=list>
  # $text = $htmlmacro->interpret()
  # $htmltags = $htmlmacro->expand()

### Example Usage:
  # html_tag('single', { 'title' => 'Available Views', 'values' => [
  #   map { $_->{'label'} } @{$datastore->{'displays'}}
  # ] } )->interpret;

### Copyright 1997 IntraNetics, Inc.
  # Developed by Evolution Online Systems, Inc.

### Change History
  # 1997-11-26 Added primitive ddlc, rudimentary javascript methods.
  # 1997-11-25 Created sldd. -Simon

### <single title=x values=list>

package Script::HTML::Lists::Single;
@ISA = qw( Script::HTML::Tag );

sub subclass_name { 'single' };
Script::HTML::Lists::Single->register_subclass_name;

use Script::HTML::Tag;
use Script::HTML::Applets;
use Script::HTML::Tables;
use Script::HTML::Escape;
use Script::HTML::Styles;
use Data::DRef;

sub buildscript {
  my $name = shift;
  
  return <<ENDOFSCRIPT
  <SCRIPT LANGUAGE="JavaScript">
  // Check which browser we are in.  We need to know this so we
  // can find the applet differently because of the differences in 
  // the object models.
  var isNav;
  var isIE;
  isNav = (navigator.appName =="Netscape") ? true : false;
  isIE = (navigator.appName.indexOf ("Microsoft" != -1)) ? true : false;
  
  // Function that we will use later on in the submit potion 
  // of the form.
  function get_output_values(){
    var output_list;
    var numitems;
    var i;
    var myelem;
    
    if ( isNav ){
      output_list = document.$name.getOutputList();
    } else if ( isIE ){
      output_list = document.forms[0].$name.getOutputList();
    } else {
      output_list = null;
    }
    
    // If we got an output list, then let's continue on.  Otherwise, we
    // should just close up shop.
    if ( output_list != null ){
      numitems = output_list.size();
      for ( i = 0; i < numitems; i++ ){
	document.forms[0].elements[i].value = output_list.elementAt(i) + "";
      }		
    }
  }
  </SCRIPT>
ENDOFSCRIPT
}

# $text = $htmlmacro->interpret()
sub interpret {
  my $single = shift;
  $single->expand->interpret;
}

sub reorder {
  my $single = shift;
  my @keys = @_;     # list of id's of hashes in the single select
  
  my @order;
  my($last, $down, $up);
  my $index = Data::Collection::uniqueindexby($single->{'args'}{'pool'}, $single->{'args'}{'id'});
  my $pickername = 'picker' . ( $single->{'args'}{'prefix'} ? "\.$single->{'args'}{'prefix'}" : '');
  my $command = getData('request.args.command');
  foreach $item (@keys) {
    unless ($item eq getData("request.args.$pickername")) {
      push @order, $index->{$item};
      if ($down) {
	push @order, $down;
	$down = '';
      }
    } else {      # item is current; handle any command
      if ($command eq 'First') {
	unshift @order, $index->{$item};
      } elsif ($command eq '  Up  ') {
	$up = pop @order;
	push @order,  $index->{$item}, $up;
      } elsif ($command eq 'Down') {
	$down = $index->{$item};
      } elsif ($command eq ' Last ') {
	$last = $index->{$item};
      } else {
	push @order, $index->{$item};
      }
    }
  }
  push @order, $last if $last;
  $single->{'values'} = [ @order ];
}

sub reorderbyvalue {
  my $listtag = shift;
  my @values = @_;     # list of displayed values for hashes in the single select
  my $display = Script::Parser->new->parse( $listtag->{'args'}{'display'} );
  
  my @bydisplay = map { setData('-select', $_);
			{'value' => $_, 'label' => $display->interpret() }
		      } @{$listtag->{'args'}{'pool'}};
  my $index = Data::Collection::uniqueindexby([ @bydisplay ], 'label');
  
  my @order;
  foreach $item (@values) {
    push (@order, $index->{$item}{'value'}) if $index->{$item};
  }
  $listtag->{'values'} = [ @order ];
}

sub retrieveIDs {      # also called to retrieve values from hidden args for javascript output
  my $currentorder = shift;
  
  my @keys = Data::Collection::keysof($currentorder);
  my @ids;
  foreach $order (sort { $a <=> $b } @keys) {
    push @ids, getDRef($currentorder, $order);
  }
  return @ids;
}


sub init {
  my $single = shift;
  $single->{'java'} = 1 unless &getData('request.client.browser') =~ /Omni/; #  test for java capability
  my $ordername = ($single->{'java'} ? 'java' : 'instance') . ( $single->{'args'}{'prefix'} ? "\.$single->{'args'}{'prefix'}" : '');
  
  if ($single->{'args'}{'override'}) {
    $single->reorder(@{$single->{'args'}{'override'}});
  } elsif (&getData("request.args.$ordername")) {
    if (&getData("request.args.java")) {
      $single->reorderbyvalue(&retrieveIDs(&getData("request.args.$ordername")));
      # copy to request.args.instance for use on previous/next pages
      &setData('request.args.instance' . 
		  ( $single->{'args'}{'prefix'} ? "\.$single->{'args'}{'prefix'}" : ''),
		$single->{'values'});
    } else {
      $single->reorder(&retrieveIDs(&getData("request.args.$ordername")));
    }
  } else {
    $single->{'values'} = $single->{'args'}{'pool'};
  }
}

sub buildselect {
  my $single = shift;
  
  my $id = $single->{'args'}{'id'};
  my $display = Script::Parser->new->parse( $single->{'args'}{'display'} );
  my $values = $single->{'values'};
  my $selectname = 'picker' . ( $single->{'args'}{'prefix'} ? "\.$single->{'args'}{'prefix'}" : '');
  
  html_tag('select', 
	    { 'name'=>$selectname,'size'=>8, 'current'=>getData("request.args.$selectname") }, 
	    map { setData('-select', $_);
		  html_tag('option', {'value' => &getData("-select.$id"),
				      'label' => $display->interpret() } ); 
		} @$values );
}			    

sub buildbuttons {
  html_tag('input', { 'type' => 'submit', 'name' => 'command', 'value' => 'First' }), 
  '<br>',
  html_tag('input', { 'type' => 'submit', 'name' => 'command', 'value' => '  Up  ' }), 
  '<br>',
  html_tag('input', { 'type' => 'submit', 'name' => 'command', 'value' => 'Down' }), 
  '<br>',
  html_tag('input', { 'type' => 'submit', 'name' => 'command', 'value' => ' Last ' })
}			    

sub buildhidden {
  my $single = shift;
  
  my $id = $single->{'args'}{'id'};
  my $hiddenname = ($single->{'java'} ? 'java' : 'instance') . ( $single->{'args'}{'prefix'} ? "\.$single->{'args'}{'prefix'}\." : '.');
  my $values = $single->{'values'};
  my @hidden;
  
  foreach $i (0 .. $#{@$values}) {
    push(@hidden, 
	  html_tag('input', { 'type' => 'hidden', 
			      'name' => "$hiddenname$i", 
			      'value' => ($single->{'java'} ? '' : &getDRef($values, "$i.$id"))}));
  }
  return @hidden; 
}			    

# $htmltag = $htmlmacro->expand()
sub expand {
  my $single = shift;
  
  if ($single->{'java'}) {
    my $display = Script::Parser->new->parse( $single->{'args'}{'display'} );
    my $values = $single->{'values'};
    my $outname = 'instance' . ( $single->{'args'}{'prefix'} ? "\.$single->{'args'}{'prefix'}" : '');
    
    my $opts = {};
    $opts->{'code'} = 'INSingleList.class';
    
    my $site = $WebApp::Handler::SiteHandler::Site;
    $opts->{'codebase'} = $site->asset_url('java');
    $opts->{'name'} = 'INSingleList';
    $opts->{'id'} = 'INSingleList';
    $opts->{'height'} = 240;
    $opts->{'width'} = 300;
    
    my $applet = html_tag('applet', $opts);
    
    $applet->add_param('ol.title' => $single->{'args'}{'title'});
    $applet->add_param('ol.numlines' => 8);
    
    my $n;
    foreach $n ( 0 .. $#$values ) {
      setData('-select', $values->[$n]);
      $applet->add_param("ol.in.$n" => $display->interpret());
    }
    
    return Script::Sequence->new( $single->buildhidden(), $applet, &buildscript('INSingleList'));
  } else {
    my $table = table('', row({}, 
      (cell({'valign' => 'top'}, (stylize('label', $single->{'args'}{'title'}) . '<br>'), $single->buildselect()),
	cell({ 'align' => 'center', 'valign' => 'middle'}, $single->buildbuttons()))));
		      
    return Script::Sequence->new( $table, $single->buildhidden() );
  }
}


### <dual title=x values=list current=list>

package Script::HTML::Lists::Dual;
@ISA = qw( Script::HTML::Tag );

sub subclass_name { 'dual' };
Script::HTML::Lists::Dual->register_subclass_name;

use Script::HTML::Tag;
use Script::HTML::Tables;
use Script::HTML::Escape;
use Script::HTML::Styles;
use Data::DRef;

# $text = $htmlmacro->interpret()
sub interpret {
  my $dual = shift;
  $dual->expand->interpret;
}

sub init {
  my $dual = shift;
  $dual->{'java'} = 1 unless &getData('request.client.browser') =~ /Omni/; #  test for java capability
  
  my $id = $dual->{'args'}{'id'};
  my @override;
  my $instancename = ($dual->{'java'} ? 'java' : 'instance') . ( $dual->{'args'}{'prefix'} ? "\.$dual->{'args'}{'prefix'}" : '');
  
  my $command = &getData('request.args.command');
  my $currentinstance = &getData("request.args.$instancename");
  if ($dual->{'java'}) {
    my $single = html_tag('single', { 'title' => $dual->{'args'}{'subtitle'}, 
				      'pool' => $dual->{'args'}{'pool'},
				      'override' => [],
				      'prefix' => $dual->{'args'}{'prefix'},
				      'id' => $id,
				      'display' => $dual->{'args'}{'display'} } );
    if ($currentinstance) {
      $single->reorderbyvalue
	(&Script::HTML::Lists::Single::retrieveIDs(&getData("request.args.$instancename")));
      # copy to request.args.instance for use on previous/next pages
      &setData('request.args.instance' . 
		  ( $single->{'args'}{'prefix'} ? "\.$single->{'args'}{'prefix'}" : ''),
		[ map { $_->{'name'} } @{$single->{'values'}} ]);
      warn "MY request.args.instance has been set to " . Text::PropertyList::astext(&getData('request.args.instance'));
    } else {
      $single->reorder(&Script::HTML::Lists::Single::retrieveIDs(&getData('request.args.instance' . ( $dual->{'args'}{'prefix'} ? "\.$dual->{'args'}{'prefix'}" : ''))));
    }
    $dual->{'single'} = $single;
    @override = map { &getDRef($_, $id); } @{$single->{'values'}};
    warn "My override is " . Text::PropertyList::astext( \@override );
  } else {
    if ($currentinstance) {
      if ($command eq '<- Drop') {
	my $pickername = 'picker' . 
			  ( $dual->{'args'}{'prefix'} ? "\.$dual->{'args'}{'prefix'}" : '');
	foreach $key (&Data::Collection::keysof($currentinstance)) {
	  delete $currentinstance->{$key} if $currentinstance->{$key} eq &getData("request.args.$pickername");
	}
      }
      @override = &Script::HTML::Lists::Single::retrieveIDs($currentinstance);
      if ($command eq ' Add ->') {
	my $poolname = 'pool' . ( $dual->{'args'}{'prefix'} ? "\.$dual->{'args'}{'prefix'}" : '');
	# append to request.args.instance
	push @override, &getData("request.args.$poolname");
	# warn "My ids are @override";
      } 
    } else {
      @override = $dual->{'args'}{'pickerinit'};
    }
  }
  
  my %picked;
  @picked{@override} = (1) x @override;
  my @values;
  foreach $item (@{$dual->{'args'}{'pool'}}) {   # set $values to everything not picked
    push(@values, $item) unless $picked{$item->{$id}};
  }
  $dual->{'values'} = [ @values ];
  $dual->{'single'} = html_tag('single', { 
      'title' => $dual->{'args'}{'subtitle'}, 
      'override' => [ @override ],
      'pool' => $dual->{'args'}{'pool'},
      'prefix' => $dual->{'args'}{'prefix'},
      'id' => $id,
      'display' => $dual->{'args'}{'display'}
    } )					unless $dual->{'single'};
}

sub buildhidden {    # only used to build javascript output arguments
  my $dual = shift;
  
  my $id = $dual->{'args'}{'id'};
  my $hiddenname = 'java' . ( $dual->{'args'}{'prefix'} ? "\.$dual->{'args'}{'prefix'}" : '') . '.';
  my @hidden;

  foreach $i (0 .. $#{$dual->{'args'}{'pool'}}) {
    push(@hidden, html_tag('input', { 'type' => 'hidden', 
				      'name' => "$hiddenname$i", 
				      'value' => ''}));
  }
  return @hidden; 
}			    

sub buildselect {
  my $dual = shift;

  my $id = $dual->{'args'}{'id'};
  my $display = Script::Parser->new->parse( $dual->{'args'}{'display'} );
  my $values = $dual->{'values'};
  my $selectname = 'pool' . ( $dual->{'args'}{'prefix'} ? "\.$dual->{'args'}{'prefix'}" : '');

  html_tag('select', 
	    { 'name'=>$selectname,'size'=>8, 'current'=>getData("request.args.$selectname") }, 
	    map { setData('-select', $_);
		  html_tag('option', {'value' => &getData("-select.$id"), 
				      'label' => $display->interpret() } ); 
		} @$values );
}

sub buildbuttons {
  html_tag('input', { 'type' => 'submit', 'name' => 'command', 'value' => ' Add ->' }), 
  '<br>',
  html_tag('input', { 'type' => 'submit', 'name' => 'command', 'value' => '<- Drop' })
}			    

# $htmltags = $htmlmacro->expand()
sub expand {
  my $dual = shift;
  
  if ( 1 or $dual->{'java'}) {
    my $display = Script::Parser->new->parse( $dual->{'args'}{'display'} );
    my $values = $dual->{'values'};
    my $single = $dual->{'single'};
    my $subvalues = $single->{'values'};
    my $outname = 'instance' . ( $dual->{'args'}{'prefix'} ? "\.$dual->{'args'}{'prefix'}" : '');
    
    my $opts = {};
    $opts->{'code'} = 'INDualList.class';
    my $site = $WebApp::Handler::SiteHandler::Site;
    $opts->{'codebase'} = $site->asset_url('java');
    $opts->{'name'} = 'INDualList';
    $opts->{'id'} = 'INDualList';
    $opts->{'height'} = 240;
    $opts->{'width'} = 550;
    
    my $applet = html_tag('applet', $opts);
    
    $applet->add_param('dlc.title' => $dual->{'args'}{'title'});
    $applet->add_param('dlc.multiselect' => 'yes');
    $applet->add_param('dlc.ordered' => 'yes');

    $applet->add_param('ol.title' => $dual->{'args'}{'subtitle'});
    $applet->add_param('ol.numlines' => 8);
    
    foreach $n ( 0 .. $#$values ) {
      setData('-select', $values->[$n]);
      $applet->add_param("dlc.in.$n" => $display->interpret());
    }
    foreach $n ( 0 .. $#$subvalues ) {
      setData('-select', $subvalues->[$n]);
      $applet->add_param("ol.in.$n" => $display->interpret());
    }

    return Script::Sequence->new( $dual->buildhidden(), $applet, &Script::HTML::Lists::Single::buildscript('INDualList'));
  } else {
  my $single = $dual->{'single'};
  my $table = table('', row({}, 
    (cell({'valign' => 'top'}, 
	(stylize('label', $dual->{'args'}{'title'}) . '<br>'), $dual->buildselect()),
     cell({ 'align' => 'center', 'valign' => 'middle'}, $dual->buildbuttons()),
     cell({'valign' => 'top'}, 
	(stylize('label', $single->{'args'}{'title'}) . '<br>'), $single->buildselect()),
     cell({ 'align' => 'center', 'valign' => 'middle'}, $single->buildbuttons()))));
  
  return Script::Sequence->new( $table, $single->buildhidden() );
  }
}

1;
