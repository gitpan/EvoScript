### Script::Tags::Calendar generates HTML month, week, and day calendars

### Caveats and Things To Do
  # - There's some overlap between the various expand functions that could
  #   effectively be moved into the superclass.

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # Simon    M. Simon Cavalletto (simonm@evolution.com)
  # Piglet   E.J. Evans (piglet@evolution.com)
  # Eric     Eric Moss

### Change History
  # 1998-05-07 Fixed background color for prev/next cells of Day views.
  # 1998-05-07 Fixed label display style for Day views.
  # 1998-05-04 Added picker.view=Day to prev/next in Day view. -Simon
  # 1998-04-28 Moved date increment to bottom of loop in right grid, week view.
  # 1998-04-24 Added picker.view=Week to week URLs; picker.view=Day to day. -P
  # 1998-04-17 Updated to use new Data::Sorting interface.
  # 1998-03-18 Fixed daily display.
  # 1998-03-11 Inline POD added.
  # 1998-02-23 Revised Week tag.
  # 1998-02-22 Revised Day and Month tags. -Simon
  # 1997-09-24 IntraNetics97 Version 1.00.000
  # 1997-07-01 Cleanup and conversion to better date handling code.
  # 1997-06-29 Built out weeks and days.
  # 1997-06-24 Changes to monthly layout
  # 1997-06-?? Cleanup. -Simon
  # 1997-05-?? Developed calendar_month tag. -Eric
  # 1997-01-?? Wrote timechart tag. -Simon

package Script::Tags::Calendar;

$VERSION = 4.00_1998_03_11;

use Script::Container;
@ISA = qw( Script::Container );

use Data::DRef;

%ArgumentDefinitions = (
  # Target Day Date
  'date' => {'dref'=>'optional', 'default'=>'today',
  				'required'=>'string_or_nothing'},
  # Records
  'records' =>  {'dref' => 'optional', 'required'=>'list'},
  # Back Links
  'list_url' =>  {'dref' => 'optional', 'required'=>'string_or_nothing'},
  # Fields
  'startdatefield' => {'dref'=>'optional', 'default'=>'date_start'},
  'enddatefield' => {'dref'=>'optional', 'default'=>'date_end'},
  'sortorder' => {'dref'=>'optional', 'required'=>'list_or_nothing'},
  # html style
  'datestyle' => {'dref'=>'optional', 'default'=>'name=normal bold',
					'required'=>'string_or_nothing'},
  'style' => {'dref'=>'optional', 'default'=>'name=normal',
					'required'=>'string_or_nothing'},
  'border' =>   {'dref'=>'optional', 'default'=> 1,'required'=>'number'},
  'bgcolor' =>   {'dref'=>'optional', 'default'=> '#000000'},
  'cellspacing' =>{'dref'=>'optional','default'=>1,'required'=>'number'},
  'cellpadding' =>{'dref'=>'optional','default'=>2,'required'=>'number'},
  'cellwidth' =>{'dref'=>'optional','default'=> 75,'required'=>'number'},
  'headcolor' => {'dref'=>'optional','default'=> 'colhead',
  					'required'=>'string_or_nothing'},
  'rowcolor' => {'dref'=>'optional','default'=> 'background',
  					'required'=>'string_or_nothing'},
  'altcolor' => {'dref'=>'optional','default'=> 'alternate',
  					'required'=>'string_or_nothing'},
);

%Types = (
  'month' => 'Script::Tags::Calendar::Month',
  'week' => 'Script::Tags::Calendar::Week',
  'day' => 'Script::Tags::Calendar::Day',
);

# $tag = Script::*TagClass*->new( %args );
sub new {
  my $package = shift;
  my %args = @_;
  
  if ( $package eq 'Script::Tags::Calendar' ) {
    $package = $Types{ $args{'type'} } ||
			    die "unknown calendar style $args{'type'}\n";
  }
  
  return $package->SUPER::new( %args );
}

# $html_text = $calendar_tag->interpret();
sub interpret {
  my $calendar_tag = shift;
  return $calendar_tag->expand->interpret;
}

# $html_text = $calendar_tag->daily_display($date, $records);
sub daily_display {
  my $tag = shift;
  my $date = shift;
  my $records = shift;
  
  local $Data::DRef::Root->{'calendar'} = $tag;
  
  $date = $date->yyyymmdd if ( ref $date );
  
  my $contents;
  foreach (@$records) {
    $tag->{'record'} = $_;
    unless ( ref $_ ) {
      warn "Bogus calendar record $tag->{'record'} \n";
      next;
    }
    # warn "Calendar record $tag->{'record'} \n";
    my $start = getDRef($tag->{'record'}, $tag->{'startdatefield'});
    my $end = getDRef($tag->{'record'}, $tag->{'enddatefield'});
    # warn "   $start $end\n";
    # warn "cal:".$date.' ' . $start->yyyymmdd . ' ' . $end->yyyymmdd . "\n";
    if ($start->yyyymmdd <= $date and $end->yyyymmdd >= $date) {
      warn "Day match:".$date.' '.$start->yyyymmdd.' '.$end->yyyymmdd."\n";
      my $value = $tag->interpret_contents;
      $value = stylize($args->{'style'}, $value) if ($args->{'style'});
      $contents .= '<p>' . $value;
    }
  }
  delete $tag->{'record'};
  
  $contents = '&nbsp;' unless ( defined $contents and length $contents );
  return $contents;
}

### CALENDAR DAY

package Script::Tags::Calendar::Day;

@ISA = qw( Script::Tags::Calendar );

use Script::HTML::Tag;
use Script::HTML::Tables;
use Script::HTML::Styles;

use Data::DRef qw( getData setData );
use Data::Sorting qw( sort_in_place );
use DateTime::Date;

# [cal_day record=#x]
Script::Tags::Calendar::Day->register_subclass_name();
sub subclass_name { 'cal_day' }

%ArgumentDefinitions = %Script::Tags::Calendar::ArgumentDefinitions;

# $html_table = $day_tag->expand();
sub expand {
  my $day_tag = shift;
  my $args = $day_tag->get_args;
  my $date = DateTime::Date::new_date_from_value( $args->{'date'} );
  my $pickdate_args = getData('request.args.pickdate');
  my @months = (DateTime::Date::months)[1..12];
  my $records = $args->{'records'};

  $day_tag->{'startdatefield'} = $args->{'startdatefield'};
  $day_tag->{'enddatefield'} = $args->{'enddatefield'};

  warn 'pickdate args sub month is ', $pickdate_args->{'month'};

  if ( $pickdate_args->{'year'} ) {
    $pickdate_args->{'year'} += 2000 if ($pickdate_args->{'year'} < 50);
    $pickdate_args->{'year'} += 1900 if ($pickdate_args->{'year'} < 100);
    $date->year( $pickdate_args->{'year'} );
  }
  $date->month( $pickdate_args->{'month'} +1 ) if ( defined
						  $pickdate_args->{'month'} );
  $date->day( $pickdate_args->{'day'} ) if ( defined
						  $pickdate_args->{'day'} );
  setData('my.pickdate', $date);
  my $monthpicker = (html_tag('select', {'name'=>'pickdate.month',
					'current'=>($date->month)-1}));
  my $month_index = 0;
  warn 'Months are ', @months;
  foreach $month (@months) {
    $monthpicker->add(html_tag('option', {'value'=>$month_index,
							 'label'=>$month}));
    $month_index++;
  }

  # Make a copy of the list so we don't alter the sort order of the original
  # Maybe do this within each day for that day's records?
  sort_in_place( $records=[@$records] , @{$args->{'sortorder'}} )  
						    if ($args->{'sortorder'});
    
  # Create the table
  my $table = table( { map { $_, $args->{$_} }
		      qw( border width cellspacing cellpadding bgcolor ) } );
  
  my $site = $WebApp::Handler::SiteHandler::Site || {};
  
  # Add title row with prev/next links and date picker
  $table->new_row(
    cell( {'bgcolor' => $args->{'headcolor'}, 'align'=>'center' }, 
      html_tag('form', {'action'=>'-current'},
        html_tag('a', { 'href' => $args->{'list_url'} . 
	    '&date=' . $date->prev_day->yyyymmdd . '&picker.view=Day'}, 
        html_tag('img', { 'src'=>$site->asset_url('navicons', 'prev.gif'), 
							'border'=>0 }) ),
        ' &nbsp; ',
        $monthpicker,
        ' &nbsp; ',
        html_tag('input', {'type',=>'text', 'size'=>3, 'name'=>'pickdate.day', 
							'value'=>$date->dd}),
        ' &nbsp; ',
        html_tag('input', {'type',=>'text', 'size'=>5, 'name'=>'pickdate.year', 
							'value'=>$date->year}),
        ' &nbsp; ',
        html_tag('input', {'type',=>'submit', 'value'=>'Redisplay'}),
        ' &nbsp; ',
        html_tag('a', { 'href' => $args->{'list_url'} . 
    		'&date=' . $date->next_day->yyyymmdd  . '&picker.view=Day' }, 
        html_tag('img', { 'src'=>$site->asset_url('navicons', 'next.gif'), 
							'border'=>0 }) ),
      ),
    ),
  );
  
  $table->new_row(
    cell({ 'bgcolor'=>$args->{'rowcolor'}, 'colspan'=>1, 'align'=>'left' },
	  stylize('name=normal', $day_tag->daily_display($date, $records) ))
  );
  return $table;
}

### CALENDAR MONTH

package Script::Tags::Calendar::Month;

@ISA = qw( Script::Tags::Calendar );

use Script::HTML::Tag;
use Script::HTML::Tables;
use Script::HTML::Styles;

use Data::Sorting qw( sort_in_place );
use Data::DRef;
use DateTime::Date;

# [cal_month record=#x]
Script::Tags::Calendar::Month->register_subclass_name();
sub subclass_name { 'cal_month' }

%ArgumentDefinitions = %Script::Tags::Calendar::ArgumentDefinitions;

# $html_table = $month_tag->expand();
sub expand {
  my $month_tag = shift;
  my $args = $month_tag->get_args;
  
  my $date = DateTime::Date::new_date_from_value( $args->{'date'} );
  
  my $records = $args->{'records'};
  $month_tag->{'startdatefield'} = $args->{'startdatefield'};
  $month_tag->{'enddatefield'} = $args->{'enddatefield'};
 
  # Make a copy of the list so we don't alter the sort order of the original
  # Maybe do this within each day for that day's records?
  sort_in_place( $records=[@$records] , @{$args->{'sortorder'}} )  
						    if ($args->{'sortorder'});
    
  # Create the table
  my $table = table( { map { $_, $args->{$_} }
		      qw( border width cellspacing cellpadding bgcolor ) } );
  
  my $site = $WebApp::Handler::SiteHandler::Site;
  
  # Add title row with prev/next links and date picker
  my $prev = DateTime::Date::new_date_from_value( 
      { 'day'=> 1, 'year'=>$date->year,  'month'=>$date->month - 1 } 
  );
  my $next = DateTime::Date::new_date_from_value ( 
      { 'day'=> 1, 'year'=>$date->year,  'month'=>$date->month + 1 } 
  );
  $table->new_row(
    cell( {'colspan'=>8, 'bgcolor'=>'background', 'align'=>'center' }, 
        html_tag('a', { 'href' => $args->{'list_url'} . '&date=' . 
							$prev->yyyymmdd }, 
        html_tag('img', { 'src'=>$site->asset_url('navicons', 'prev.gif'), 
							'border'=>0 }) ),
        stylize('label', '&nbsp; [' . $date->month_name 
					. '] [' . $date->year . '] &nbsp;'),
        html_tag('a', { 'href' => $args->{'list_url'} . '&date=' . 
							$next->yyyymmdd }, 
        html_tag('img', { 'src'=>$site->asset_url('navicons', 'next.gif'), 
							'border'=>0 }) ),
    ),
  );
  
  # Days-of-week header
  my @days_of_week = (DateTime::Date::daysofweek)[1..7];
  $table->new_row(
    cell({ 'bgcolor'=>$args->{'headcolor'}, 'width'=>15 }, '&nbsp;' ),
    map { cell(
      {'bgcolor'=>$args->{'headcolor'}, 'align'=>'center', 'valign'=>'bottom'},
      stylize('heading', $_ ) ) 
    } @days_of_week
  );
  
  # Monthly Calendar Geometry
  my $daysinmonth = $date->num_days_in_month;
  my $first_day_of_month = $date->first_day_in_month;
  my $firstday_dow = $first_day_of_month->dayofweek;
  
  my $last_day_of_month = $date->last_day_in_month;
  my $lastday_dow = $last_day_of_month->dayofweek;
   
  my $numrows = int(.99 + ($daysinmonth + $firstday_dow - 1) / 7);
  
  # Generate week rows
  
  my $week_n;
  foreach $week_n ( 0 .. ($numrows - 1) ) {
    
    my $first_day_of_week = $first_day_of_month->clone;
    $first_date_of_week = ($week_n * 7) - $firstday_dow + 2;
    $first_day_of_week->day($first_date_of_week) if ($week_n);
    
    my $row = row( {}, cell(
	{'bgcolor' => 'colhead', 'width'=>15, 'valign'=>'top'}, 
      html_tag('a', { 'href' => 
      		$args->{'list_url'}.'&date='.$first_day_of_week->yyyymmdd.'&picker.view=Week' }, 
      html_tag('img', { 'border'=>0, 'src' =>
      		$site->asset_url('navicons', 'week.gif') }),
      '<br><br>' ), 
    ) );
    
    for $dow (1 .. 7) {
      $day = $dow + $first_date_of_week - 1;
      if ($day > 0 && $day <= $daysinmonth) {
	$date->day( $day );
	# Generate day contents
	$row->add( cell({ 'bgcolor'=>'white', 
	    'width'=>$args->{'cellwidth'}, 'valign'=>'top', 'align'=>'left' },
	  html_tag('a', { 'href' => 
	      $args->{'list_url'}.'&date='.$date->yyyymmdd.'&picker.view=Day' }, 
	    stylize('label', $date->day) ),
	  stylize('normal', $month_tag->daily_display($date, $records)),
	));
      } elsif ( $day == 0 ) {
	$row->add( cell({'bgcolor'=>'#cccccc', 
			'colspan' => $firstday_dow - 1 }, '&nbsp;' ));
      } elsif ( $day == ($daysinmonth + 1) ) {
	$row->add( cell({'bgcolor'=>'#cccccc', 
			'colspan' => 7 - $lastday_dow }, '&nbsp;' ));
      }
    }
    $table->add( $row );
  }
  
  return $table;
}

### CALENDAR WEEK

package Script::Tags::Calendar::Week;

@ISA = qw( Script::Tags::Calendar );

use Script::HTML::Tag;
use Script::HTML::Tables;
use Script::HTML::Styles;

use Data::Sorting qw( sort_in_place );
use Data::DRef;
use DateTime::Date;

# [cal_week record=#x]
Script::Tags::Calendar::Week->register_subclass_name();
sub subclass_name { 'cal_week' }

%ArgumentDefinitions = %Script::Tags::Calendar::ArgumentDefinitions;

# $html_table = $week_tag->expand();
sub expand {
  my $week_tag = shift;
  my $args = $week_tag->get_args;
  
  my $date = DateTime::Date::new_date_from_value( $args->{'date'} );
  # push date back to the Monday of the same week
  $date->day( $date->day - $date->dayofweek + 1 );
  
  my $records = $args->{'records'};
  $week_tag->{'startdatefield'} = $args->{'startdatefield'};
  $week_tag->{'enddatefield'} = $args->{'enddatefield'};
 
  # Make a copy of the list so we don't alter the sort order of the original
  # Maybe do this within each day for that day's records?
  sort_in_place( $records=[@$records] , @{$args->{'sortorder'}} )  
						    if ($args->{'sortorder'});
  
  # Create the table
  my $table = table( { map { $_, $args->{$_} }
		      qw( border width cellspacing cellpadding bgcolor ) } );
  
  my $site = $WebApp::Handler::SiteHandler::Site;
  
  # Add title row with prev/next links and date picker
  my $prev = $date->clone;
  $prev->day( $date->day - 7 );  
  my $next = $date->clone;
  $next->day( $date->day + 7 );  
  
  my $startdate = $date->clone;
  my $enddate = $date->clone;
  $enddate->day( $date->day + 6 );
  
  $table->new_row(
    cell( {'colspan'=>6, 'bgcolor'=>'background', 'align'=>'center' }, 
      html_tag('a', { 'href' => 
	  $args->{'list_url'}.'&date='.$prev->yyyymmdd.'&picker.view=Week' }, 
	html_tag('img', { 'src'=>$site->asset_url('navicons', 'prev.gif'), 
						      'border'=>0 })
      ),
      html_tag('form', {'action'=>'-current'},
	html_tag('select', {'name'=>'blah'}, 
	  html_tag('option', {'label'=>'Is this'}),
	  html_tag('option', {'label'=>'Working?'}),
        )
      ),
      stylize('label', '&nbsp; Week of: &nbsp;'),
      html_tag('a', { 'href' => 
	  $args->{'list_url'}.'&date='.$next->yyyymmdd.'&picker.view=Week' }, 
	html_tag('img', { 'src'=>$site->asset_url('navicons', 'next.gif'), 
						      'border'=>0 }) 
      ),
    ),
  );
  
  my $left_grid = table( {} ) ;
  foreach $day ( 1 .. 3 ) {
    
    my $label = '&nbsp;<br>' . 
    		stylize('sans white size=+3', $date->day ) . 
		'<br>' .
		stylize('small white sans', $date->nameofweekday) . 
		'<br>&nbsp;';
    
    my $daylink = html_tag('a', { 'href' => 
      		$args->{'list_url'}.'&date='.$date->yyyymmdd.'&picker.view=Day' }, 
      html_tag('img', { 'border' => 0, 'src' =>
      		$site->asset_url('navicons', 'day.jpg') }) );
    
    my $rowspan = (($day == 3) ? 2 : 1);
    $left_grid->new_row(
      cell( {'rowspan'=>$rowspan, 'bgcolor'=>'#336699',  
	  'valign'=>'middle' }, $daylink), 
      cell( {'width'=>90, 'align'=>'center', 'bgcolor'=>'background', 
      	  'rowspan'=>$rowspan }, $label), 
      cell( {'rowspan'=>$rowspan, 'width'=>$args->{'cellwidth'}, , 
	'bgcolor'=>'background' }, $week_tag->daily_display($date, $records)), 
    );
    
    $date->day( $date->day + 1 );
  }
  $left_grid->new_row();
  
  my $right_grid = table( {} ) ;
  foreach $day ( 4 .. 7 ) {
    
    my $label = '&nbsp;<br>' . 
    		stylize('sans white size=+3', $date->day ) . 
		'<br>' .
		stylize('small white sans', $date->nameofweekday) . 
		'<br>&nbsp;';
    
    my $daylink = html_tag('a', { 'href' => 
      		$args->{'list_url'}.'&date='.$date->yyyymmdd.'&picker.view=Day' }, 
      html_tag('img', { 'border' => 0, 'src' =>
      		$site->asset_url('navicons', 'day.jpg') }) );
    
    $right_grid->new_row(
      cell( {'width'=>$args->{'cellwidth'}, 'bgcolor'=>'background' }, 
      	  $week_tag->daily_display($date, $records)), 
      cell( {'width'=>90, 'align'=>'center', 'bgcolor'=>'background' },
         $label), 
      cell( { 'bgcolor'=>'#336699', 'valign'=>'middle' }, $daylink), 
    );
    $date->day( $date->day + 1 );
        
  }
  
  $left_grid->add_table_to_right( $right_grid );
  $table->add_table_to_bottom( $left_grid );
  
  return $table;
}

1;

__END__

=head1 Calendar

Generate a daily, weekly, or monthly calendar view.

=cut