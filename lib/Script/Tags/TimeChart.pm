sub _timechart_tag {
  my ($script, $tag) = @_;
  
  throw "you must have a records arguement" unless ($tag->{'args'}{'records'});
  
  my ($records) = &get($script->{'context'}, $tag->{'args'}{'records'});
  throw "records argument is not a list" unless (&typeof($records) eq 'ARRAY');
  throw "no records" unless (scalar @$records);
  
  local ($datekey, $startkey, $endkey) = ('date:full', 'start', 'end');
  
  my ($display) = &get($script->{'context'}, $tag->{'args'}{'displaydef'});
  
  my ($itemtemplate) = $tag->{'args'}{'itemtemplate'};
  if (not $itemtemplate and $display->{'template'}) {
    $itemtemplate = $display->{'template'};
  }
  if (not $itemtemplate) {
    $itemtemplate = "[print dref=-record]";
  } elsif ($itemtemplate =~ /^(\w|\\.|\:)+$/) {
    $itemtemplate = &get($script->{'context'}, $itemtemplate);
  } else {
    ### Hmm. what do we do here? For now, just use the value they supplied
  }
  ($itemtemplate) = &IWAE::script::parse_text_with_tags($script, $itemtemplate);
  my (@indexkeys) = $datekey;
  
  my ($groupby) = [];
  $groupby = &get($script->{'context'}, $tag->{'args'}{'groupby'}) if $tag->{'args'}{'groupby'};
  $groupby = $display->{'groupby'} if $display->{'groupby'};
  
  foreach $groupingrule (@$groupby) {
    push(@indexkeys, $groupingrule->{'field'});
    ($groupingrule->{'tags'}) = 
		&IWAE::script::parse_text_with_tags($script, $groupingrule->{'labelstyle'});
  }
  
  my ($range) = $tag->{'args'}{'range'};
  my ($starthour, $endhour);
  if ($range =~ /^(\w|\\.)+(\:(\w|\\.|))+$/) {
    $range = &get($script->{'context'}, $range); 
  } 
  if (not $range and $display->{'range'}) {
    $range = $display->{'range'};
  }
  if (not $range or $range =~ /as ?needed/i) {
    $range = 'asneeded';
    ($starthour, $endhour) = (astime('23:59', 'full'), astime('00:00', 'full'));
    foreach $record (@$records) {
      my($eventstart) = astime($record->{$startkey}, 'full');
      $starthour = $eventstart if ($eventstart < $starthour);
      my($eventend) = astime($record->{$endkey}, 'full');
      $endhour = $eventend if ($eventend > $endhour);
    }
    my($starthour) = astime($starthour, 'hash');
    $starthour = $starthour->{'hour'};
    my($endhour) = astime($endhour, 'hash');
    $endhour = $endhour->{'hour'};
    $endhour--;
  } elsif ($range =~ /^(\d+)\D(\d+)$/) {
    ($starthour, $endhour) = ( $1, $2 );
    $endhour--;
  } elsif ($range =~ /all/i) {
    $range = 'all';
    ($starthour, $endhour) = (0, 23);
  } else {
    ### Hmm. what do we do here? For now, just use do all.
    $range = 'all';
    ($starthour, $endhour) = (0, 23);
  }
  ($range) = &IWAE::script::parse_text_with_tags($script, $range);
  &set('piglet:range', $range);
  
  throw "invalid start and end times ($starthour - $endhour)" unless 
  	(0 <= $starthour and $endhour <= 23 and $starthour < $endhour);
  
  my(@hours) = ($starthour .. $endhour);
  
  my($colsperhour) = 4;
  my($timebarcols) = scalar @hours * $colsperhour;
  
  my ($hourheaders);
  foreach $hour (@hours) {
    my($hourstring) = &astime($hour.':00', 'short');
    $hourheaders .= "<th colspan=$colsperhour align=left bgcolor=#999999><font face=Helvetica size=-1>$hourstring</font></th>";
  }
  
  my ($index) = &indexby($records, @indexkeys);
  
  # return &asDictionary($groupby);
  
  my ($value);
  $value = "<table width=" . ($tag->{'args'}{'width'} ? $tag->{'args'}{'width'} : "100%") . " border=1><tr>\n";
  
  foreach $date ( sort(keys(%$index)) ) {
    &set('piglet:index', $index);
    $theData->{'-reg'}{'date'} = $date;
    $value .= "<th rowspan=2 bgcolor=#999999>&nbsp;</th>" x scalar @$groupby;
    my($datestring) = &asdate($date, 'short');
    $value .= "<th align=center colspan=$timebarcols bgcolor=#999999>" . 
		"<font face=Helvetica size=-1>$datestring</font></th>\n" .
		"</tr><tr>\n $hourheaders </tr><tr>\n";
  
    if (scalar @indexkeys == 1) {
      my (@bars) = eventbars($script, $tag, $index->{$date});
      $value .= join("\n", @bars);
    } elsif (scalar @indexkeys == 2) {
      foreach $group (sort (keys %{$index->{$date}})) {
	$theData->{'-reg'}{'group'} = $group;
	my (@bars) = eventbars($script, $tag, $index->{$date}{$group});
	my ($count) = scalar @bars;
	my ($header) = "<td rowspan=$count bgcolor=#cccccc>" .
		&run_tags($script, $groupby->[0]{'tags'}) . "</td>";
	$value .= $header . join("\n", @bars) if (scalar @bars);
      }
    } elsif (scalar @indexkeys == 3) {
      foreach $group (sort (keys %{$index->{$date}})) {
	my(@bigbars);
	foreach $subgroup (sort (keys %{$index->{$date}{$group}})) {
	  $theData->{'-reg'}{'group'} = $subgroup;
	  my (@bars) = eventbars($script, $tag, $index->{$date}{$group}{$subgroup});
	  my ($count) = scalar @bars;
	  if ($count) {
	    my($header) = "<td rowspan=$count bgcolor=#cccccc>" .
		      &run_tags($script, $groupby->[1]{'tags'}) . "</td>";
	    $bars[0] = $header . $bars[0];
	  }
	  push (@bigbars, @bars);
	}
	$theData->{'-reg'}{'group'} = $group;
	my ($count) = scalar @bigbars;
	my ($header) = "<td rowspan=$count bgcolor=#cccccc>" .
		&run_tags($script, $groupby->[0]{'tags'}) . "</td>";
	$value .= $header . join("\n", @bigbars) if (scalar @bigbars);
      }
    } else {
      throw "Can't do that many groupings (" . scalar @indexkeys . ")";
    }
  }
  $value .= '</tr></table>' ."\n";
  return $value;
      
  sub eventbars {
    my ($script, $tag, $listref) = @_;
    my (@bars);
    my (@groups);
    sortby($listref, $startkey);
    foreach $event (@$listref) {
      next if (
	astime($event->{'end'},'full') <= astime($starthour.':00', 'full') or 
	astime($endhour.':00', 'full') <= astime($event->{'start'},'full'));
      my($found);
      foreach $group (@groups)  {
	if ($group->[0]{$endkey} <= $event->{$startkey}) {
	  $found++;
	  unshift(@$group, $event);
	  last;
	}
      }
      push(@groups, [ $event ]) if (not $found);
    } 
    foreach $group (@groups) {
      my($bar);
      my($current) = astime($starthour . ':00');
      foreach $event (reverse @$group) {
	my($start) = astime($event->{$startkey});
	my($end) = astime($event->{$endkey});
	my($offset) = timerange('hours', $start, $current);
	my($length) = timerange('hours', $end, $start);
	if ($offset < 0) {
	  $length += $offset;
	  $offset = 0;
	}
	my($overflow) = timerange('hours', $end, ($endhour +1) . ':00');
	if ($overflow > 0) {
	  $length -= $overflow;
	}
	$offset *= $colsperhour;
	$length *= $colsperhour;
	$current = $end;
	
	$theData->{'-record'} = $event;
	
	$bar .= "<td colspan=$offset></td>" if ($offset); 
	$bar .= "<td colspan=$length align=left bgcolor=#ff99ff>" . 
		  &run_tags($script, $itemtemplate) . "</td>\n";
	
	delete $theData->{'-record'};
      }
      $bar .= "</tr><tr>\n";
      push(@bars, $bar);
    }
    return @bars;
  }
}
