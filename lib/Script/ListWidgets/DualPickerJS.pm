package Script::ListWidgets::DualPickerJS;

# $text = $htmlmacro->interpret()
sub interpret {
  my $dualpicker = shift;
  return Script::HTML::INJLists::DDList::javascript() .  
  stylize('label', $dualpicker->{'args'}{'title'}) . '<br>' .
  '<table BORDER=0 cellspacing=0 cellpadding=0><TR><TD valign=top>' .
  '<select size=8 name=ddlc>' . join('', map { "<option> $_" }
  			@{$dualpicker->{'args'}{'values'}} ) . '</select>' .
  '</TD><TD align=center valign=middle>
    <input type=button VALUE=" Add ->" onClick=moveSelection(this.form.ddlc,this.form.sldd)><br>
    <input type=button VALUE="<- Drop" onClick==moveSelection(this.form.sldd,this.form.ddlc)><br>
  </TD><TD align=center valign=middle>
  <select size=8 name=sldd>' . join('', map { "<option> $_" }
  			@{$dualpicker->{'args'}{'current'}} ) . '</select>' .
  '</TD><TD align=center valign=middle>
  <input type=button VALUE=" First " onClick=moveToTop(this.form.sldd)><br>
  <input type=button VALUE="  Up  " onClick=moveUp(this.form.sldd)><br>
  <input type=button VALUE="Down" onClick=moveDown(this.form.sldd)><br>
  <input type=button VALUE=" Last " onClick=moveToBottom(this.form.sldd)>' .
  '</TD><TD align=left valign=top>' .
 '</TD></TR></table>';
}

sub javascript {
  return <<ENDOFSCRIPT;
  
  <SCRIPT language=JavaScript1.1><!--
  // (C) 1997 Howard Wanderman SiteSpecific
  // please note: this script can accomodate any number of items in a select
  // box as long as both the "work" and "bank" fields both have the MAXIMUM
  // number of spaces created (the combined number of all the items in both
  // fields). the blanks can be created with "<option>".

  // // MOVE ITEMS BETWEEN LISTS
  
  // runs the functions to move an item from one list to another
  // adds selected item to the top of the other list and selects it
  function moveSelection(mySelect,myTarget) {
    testForNull(mySelect)
    if (begin) {
      insertRowAtTop(myTarget)
      myTarget.options[0].text = mySelect.options[mySelect.selectedIndex].text
      myTarget.options[0].selected = 1
      deleteSelection(mySelect)
    }
  }
  
  // // WIDTH FORCING
  
  // gets rid of the text that forces the select boxes open wide
  function cleanUp() {
    for (var k = 2; k >= 0; --k)  {
      n = document.forms[k].work.length-1
      if (document.forms[k].work.options[n].text == "--open me this wide--") {
	document.forms[k].work.options[n].text = ""
      }
      if (document.forms[k].bank.options[n].text == "--open me this wide--") {
	document.forms[k].bank.options[n].text = ""
      }
    }
  }
  
  // puts the text that forces the select boxes open wide back so they don't collapse on reload
  
  function MakeDirty() {
    if (navigator.appVersion.substring(6,9) != "Mac"){
      for (var k = 2; k >= 0; --k)  {
	n = document.forms[k].work.length-1
	if (document.forms[k].work.options[n].text == "") {
	  document.forms[k].work.options[n].text = "--open me this wide--"
	}
	if (document.forms[k].bank.options[n].text == "") {
	  document.forms[k].bank.options[n].text = "--open me this wide--"
	}
      }
    }
  }
  // -->
  </SCRIPT>
ENDOFSCRIPT
}
