### <in_sldd title=x values=list>

package Script::ListWidgets::ReorderableJS;

use Script::ListWidgets::Reorderable;
@ISA = qw( Script::ListWidgets::Reorderable );

use Script::HTML::Tag;
use Script::HTML::Escape;
use Script::HTML::Styles;

# $html_tags = $widget->build_select
sub build_hidden { 
  my $widget = shift;
  return $widget->js_select_reordering;
}

# $html_tags = $widget->build_select
sub build_select {
  my $widget = shift;
  
  '<select size=8 name=sldd>' . join('', map { "<option> " . $_->{'label'} }
  			@{$widget->{'args'}{'pool'}} ) . '</select>';
}

# $html_tags = $widget->build_reorder_buttons
sub build_reorder_buttons {
  my $widget = shift;
  my $name = 'sldd';
  
  html_tag('input', { 'type'=>'button','value'=>'First', 
		      'onClick' => "moveToTop(this.form.$name)" }), 
  '<br>',
  html_tag('input', { 'type'=>'button', 'value'=>'  Up  ', 
		      'onClick' => "moveUp(this.form.$name)" }), 
  '<br>',
  html_tag('input', { 'type'=>'button', 'value'=>'Down', 
		      'onClick' => "moveDown(this.form.$name)" }), 
  '<br>',
  html_tag('input', { 'type'=>'button', 'value'=>' Last ', 
		      'onClick' => "moveToBottom(this.form.$name)" })
}

# $js_src_select_reordering = $widget->js_select_reordering;
sub js_select_reordering {
  return <<ENDOFSCRIPT;
  
  <SCRIPT language=JavaScript1.1><!--
  // (C) 1997 Howard Wanderman SiteSpecific
  
  // // MOVE ITEM UP & DOWN
  
  // switches the selected item with the one above it and re-selects it
  function moveUp(mySelect) {
    testForNull(mySelect)
    testForFirst(mySelect)
    if (begin) {
      var n = mySelect.selectedIndex
      
      var swap = mySelect.options[n].text
      mySelect.options[n].text = mySelect.options[n - 1].text
      mySelect.options[n - 1].text = swap
      
      mySelect.options[n - 1].selected = 1
    }
  }
  
  // switches the selected item with the one below it and re-selects it
  function moveDown(mySelect) {
    testForNull(mySelect)
    testForLast(mySelect)
    if (begin) {
      var n = mySelect.selectedIndex
      
      var swap = mySelect.options[n].text
      mySelect.options[n].text = mySelect.options[n + 1].text
      mySelect.options[n + 1].text = swap
      
      mySelect.options[n + 1].selected = 1
    }
  }
  
  // moves an item to the top of its list and selects it
  function moveToTop(mySelect) {
    testForNull(mySelect)
    testForFirst(mySelect)
    if (begin) {
      var swap = mySelect.options[mySelect.selectedIndex].text
      
      deleteSelection(mySelect)
      insertRowAtTop(mySelect)
      
      mySelect.options[0].text = swap
      mySelect.options[0].selected = 1
    }
  }
  
  // moves an item to the bottom of its list and selects it
  function moveToBottom(mySelect) {
    testForNull(mySelect)
    testForLast(mySelect)
    if (begin) {
      var swap = mySelect.options[mySelect.selectedIndex].text
      
      deleteSelection(mySelect)
      firstBlank(mySelect)
      
      mySelect.options[f].text = swap
      mySelect.options[f].selected = 1
    }
  }
  
  // // TESTS
  
  // tests to make sure there is something selected to work with  
  function testForNull(mySelect) {
    begin = false
    if (mySelect.options[mySelect.selectedIndex]){
      if (mySelect.options[mySelect.selectedIndex].text != "") {
	begin = true
      }
    }
  }
  
  // tests to make sure the selected item isn't already first
  function testForFirst(mySelect){
    if (mySelect.selectedIndex == 0) {
      begin = false
    }
  }
  
  // tests to make sure the selected item isn't already last
  function testForLast(mySelect){
    if (mySelect.selectedIndex == mySelect.length-1){
      begin = false
    } else {
      c = mySelect.selectedIndex
      if (mySelect.options[c + 1].text == "") {
	begin = false
      }
    }
  }
  
  // // LIST MANIPULATION
  
  // drops everything in the list down 1 
  function insertRowAtTop(mySelect) {
    i = mySelect.length -1
    for (i ; i > 0; --i)  {
      mySelect.options[i].text = mySelect.options[i-1].text
    }
  }
  
  // deletes selected item from the list by moving all below it up one.
  function deleteSelection(mySelect) {
    var x = mySelect.selectedIndex
    var m	= mySelect.length-1
    for (x; x < m; ++x)  {
      mySelect.options[x].text = mySelect.options[x+1].text
    }
    
    mySelect.options[x].text = ""
  }
  
  // looks for the first empty slot
  function firstBlank(mySelect) {
    j = mySelect.length-1
    for (j; j > 0; --j)  {
      if (mySelect.options[j].text == "") {
	f = j
      }
    }
  }
  // -->  </SCRIPT>
ENDOFSCRIPT
} 
