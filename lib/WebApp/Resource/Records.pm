### WebApp::Resource::Records 

### Class Name
  # $classname = WebApp::Resource::Site->subclass_name();

### Request Handling
  # $rc = $recordset->handle_request( $request );
  # $self_url = $recordset->self_url;
  # $recordset->has_focus;
  # $recordset->lost_focus;

### Copyright 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-04-30 added file download handling -JeReMYYYY
  # 1998-04-15 Replaced banned.page redirects with Server messages. -Simon
  # 1998-03-04 Added name and detail_field helper methods.
  # 1998-03-03 Added page handling & list and detail pages.  -Piglet
  # 1998-03-03 Added Record::class_from_name override.
  # 1998-02-27 Created. -Simon


# Package and Inheritance

package WebApp::Resource::Records;

use Script::HTML::Colors qw( color_by_name );

use WebApp::Resource::PropertyList;
push @ISA, qw( WebApp::Resource::PropertyList );

WebApp::Resource::Records->register_subclass_name;
sub subclass_name { 'records' }

# Imports and Dependencies

use Err::Debug;  

use Record;
use Data::DRef;
use Data::Collection;
use Carp;
use Script::HTML::Escape;
use Script::HTML::Tag;
use Script::HTML::Pages;
use Script::HTML::Links;
use Script::Tags::Report;

# Exports and Overrides

sub Record::class_from_name {
  my $package = shift;
  my $name = shift;
  my $ds = WebApp::Resource::Records->new_from_name($name);
  confess "Could not find Records '$name'" unless ( $ds );
  return $ds->record_class();
}

# override $resource->read_source( $propertylist_text );
sub read_source {
  my $recordset = shift;
  my $definition = shift;
  $recordset->SUPER::read_source( $definition );
  # add detaillink to fields list
  push( @{$recordset->{'fields'}}, 
	{ 
	  'escape' => 'no',
	  'expr' => "\\<a href=[print escape=\"url html\" value=#request.links.script]/$recordset->{'-name'}.records/[print value=#-record.id escape=\"url html\"]>[print value=#-record.field.display." . ($recordset->{'detail'} || 'name') . "]\\</a>",
	  'name' => 'detaillink',
	  'title' => 'Detail',   # should be title of $recordset->detail_field
	  'type' => 'calculated',
	} );
  return;
}

# override $resource->write_source;
sub write_source { 
  my $recordset = shift;
  # remove detaillink from fields list
  pop( @{$recordset->{'fields'}} );
  $recordset->SUPER::write_source;
}

# $boolean = $recordset->user_can( $action );
sub user_can {
  my $recordset = shift;
  my $action = shift;
  debug('roles', 'explicit roles are', valuesof( $recordset->{'permit'}{ $action })) if $recordset->{'permit'}{ $action };
#  return grep { user_is( $_ ) } valuesof( $recordset->{'permit'}{ $action }) if $recordset->{'permit'}{ $action };
  return 1;
}



### Request Handling

# $rc = $recordset->handle_request( $request );
sub handle_request {
  my $recordset = shift;
  local $Request = shift;
  local $Root->{'request'} = $Request;
  
  return $recordset->download_file_attachment($Request, 
		    $Request->{'path'}{'names'}[2], 
		    $Request->{'path'}{'names'}[3], 
		    $Request->{'path'}{'names'}[4]  )
			  if ( $Request->{'path'}{'names'}[1] eq 'download' );

  $recordset->send_page_for_request( $Request );
}

# $recordset->download_file_attachment($request, $id, $fieldname, $filename);
sub download_file_attachment {
  my ($recordset, $request, $id, $fieldname, $filename) = @_;
  
  #!# Need exeption handling here! - Jeremy 1998-01-27
  my $field = $recordset->record_class->field( $fieldname );
  my $fn = $field->file_from_id_and_name( $id, $filename );
  
  $request->send_file( $fn );
}

use vars qw( %page_methods );
%WebApp::Resource::Records::page_methods = (
  '-default' => 'list_page',
  'new' => ['detail_page', 'new'],
);

sub page_methods { \%WebApp::Resource::Records::page_methods }

# $page = $recordset->page_for_request( $pagename );
sub page_for_request {
  my $recordset = shift;
  my $pagename = shift;
  
  return $recordset->detail_page( $1 ) if ( $pagename =~ /\A(\d+)\Z/ );
  
  $recordset->SUPER::page_for_request( $pagename );
}

# $self_url = $recordset->self_url;
sub self_url {
  my $recordset = shift;
  return getData('request.links.script') . '/' . 
  	 $recordset->{'-name'} . '.' . $recordset->subclass_name;
}

# $fieldname = $recordset->detail_field;
sub detail_field {
  my $recordset = shift;
  return $recordset->{'detail'} || 'name';
}

# $itemname = $recordset->name( $key );
sub name {
  my $recordset = shift;
  my $key = shift;
  return $recordset->{'names'}{ $key } || $key;
}

# $classname = $datastore->record_class();
sub record_class {
  my $datastore = shift;
  
  unless ( $datastore->{'-record_class'} ) {
    $datastore->{'-record_class'} = 'Record::' . $datastore->{'-name'};
    Record::set_from_definition($datastore->{'-record_class'}, $datastore);
    $datastore->{'-record_class'}->datastore( $datastore );
  } 
  return $datastore->{'-record_class'};
}

### List Page

# $htmlpage = $recordset->list_page();
sub list_page {
  my $recordset = shift;
  
  # Load the matching records
  local $Root->{'records'} = $recordset->record_class->records;
  
  my $page = html_tag('html', '', 
    html_tag('head', '', html_tag('title', '', $recordset->name('Items') ) ),
    html_tag('body', {'bgcolor' => color_by_name('bgcolor'), 
	    'link' => color_by_name('link'), 'alink' => color_by_name('alink'), 
	    'vlink' => color_by_name('vlink')},
      Script::Tags::Report->new( 'records' => $Root->{'records'},
				  'fieldorder' => $recordset->detail_field )
    )
  );
  
  return $page;
}

### Detail Page

# $htmlpage = $recordset->detail_page( $id );
sub detail_page {
  my $recordset = shift;
  my $id = shift;
  
  my $command = $Request->{'args'}{'command'} ||
#	(( $id eq 'new' or ($recordset->{'always_edit'} && $recordset->user_can('edit'))) ? 'Edit' : 'display');
	(( $id eq 'new' or $recordset->{'always_edit'}) ? 'Edit' : 'display');

  if ($id eq 'new') {
    die "banned\n" unless $recordset->user_can( 'new' );
  }

  local $Record = $id eq 'new' ? $recordset->record_class->new_record 
			      : $recordset->record_class->record_by_id($id);
  local $Root->{'record'} = $Record;
  # do author check for each field in the record, set User:is roles
#  my $field;
#  foreach $field (@{$Record->fieldorder()}) {
#    user_is($field->get_role($Record), 1) if $field->can('get_role') && $field->get_role($Record);
#  }
  
  my $self_url = $recordset->self_url;
  
  if ($command eq 'Save') {
    die "banned\n" unless $recordset->user_can( 'edit' );
    my $update = getData('request.args.record');
    # warn "got args " . join(' ', %$update) . "\n";
    # warn "original record " . join(' ', %$Record) . "\n";
    $Record->update( $update );
    if ($Record->errorlevel eq 'none') {
      $Record->save_record;
      $self_url .= "?msg=" . url_escape('Record Saved') . "&refresh=" . time();
      warn "Saved; redirecting\n";
      $Request->redirect_and_end( $self_url );
   } else {
      warn "Couldn't save!!!\n";
      $command = 'Edit';
      debug 'updatecycle', 'errorlevel is', $Record->errorlevel(), 
      		'with the following errors:', $Record->errors;
    }
  }
  
  if ($command eq 'Cancel') {
    $Request->redirect_and_end( $self_url );
  }
  
  if ($command eq 'Delete') {
    die "banned\n" unless $recordset->user_can( 'delete' );
    $Record->delete_record();
    $self_url .= "?msg=" . url_escape('Record Deleted') . "&refresh=" . time();
    $Request->redirect_and_end( $self_url );
  }

  if ($command eq 'More Files') {
    my $update = getData('request.args.record');
    # warn "in More Files Function:\n" . astext( $Record );
    $Record->update( $update );
    return $recordset->detail_edit_page( $id );
  }
  
  if ($command eq 'display') {
    return $recordset->detail_display_page;
  } elsif ($command eq 'Edit') {
    return $recordset->detail_edit_page( $id );
  } else {
    warn "unknown command $command";
    return 0;
  }
}

# $htmlpage = $recordset->detail_display_page;
sub detail_display_page {
  my $recordset = shift;
  
  my $page = html_tag('html', '', 
    html_tag('head', '', html_tag('title', '', $recordset->name('Item') . ': ' . getData('record.field.readable.' . $recordset->detail_field ) ) ),
    html_tag('body', {'bgcolor' => color_by_name('bgcolor'), 
	    'link' => color_by_name('link'), 'alink' => color_by_name('alink'), 
	    'vlink' => color_by_name('vlink')},
      html_tag('p', '', 
	html_tag('a', { 'href' => $recordset->self_url }, 'View all ' . $recordset->name('Items') ),
	# new item
	# push into list; display as white text on green bgcolor table cells
	'&nbsp;',
	html_tag('a', { 'href' => $recordset->self_url . "/$Record->{'id'}?command=Edit" }, 'Edit' ),
      ),
      Script::Tags::Detail->new( 'record' => $Root->{'record'},
				  'mode' => 'sparse')
    )
  );
  
  return $page;    # use $page->body->add, etc.
}

# $htmlpage = $recordset->detail_edit_page( $id );
sub detail_edit_page {
  my $recordset = shift;
  my $id = shift;
  
  my $page = Script::HTML::Pages::HTML->new;
  $page->head->title->add( 
    $recordset->name('Item') . ': ' . 
    getData('record.field.readable.' . $recordset->detail_field ) 
  );
  $page->body->{'args'} = { 'bgcolor' => color_by_name('bgcolor'), 
			    'link' => color_by_name('link'), 
			    'alink' => color_by_name('alink'), 
			    'vlink' => color_by_name('vlink') };
  $page->{'links'} = Script::Sequence->new( 
    html_tag('a', { 'href' => $recordset->self_url }, 'View all ' . $recordset->name('Items') ),
  );
  $page->{'links'}->add( 
    html_tag('a', { 'href' => $recordset->self_url . "/$Record->{'id'}?command=Delete" }, 
      'Delete' ) ) unless $id eq 'new'; 
  $page->{'links'}->intersperse( '&nbsp;' ); 
  $page->body->add( $page->{'links'} );
  $page->{'formtable'} = 
    Script::HTML::Table->new({'cellpadding'=>3, 'cellspacing'=>0});
  $page->body->add( Script::HTML::Forms::Form->new( 
    { 'action' => $recordset->self_url . '/' . $Record->{'id'} , 'method' => 'multipart' },
		      $page->{'formtable'} ) );
  $page->{'buttons'} = Script::Sequence->new;
  $page->{'formtable'}->new_row( 
    Script::HTML::Table::Cell->new(
      {},
      Script::Tags::Detail->new( 'record' => $Root->{'record'}, 
				'mode' => 'edit') ),
   Script::HTML::Table::Cell->new( 
      { 'align' => 'center', 'valign' => 'top' }, 
      $page->{'buttons'} 
    ) 
  );
  $page->{'buttons'}->add( 
    Script::HTML::Forms::Submit->new( { 'value' => 'Save' } ),
    Script::HTML::Forms::Submit->new( { 'value' => 'Cancel' } ),
  );
  $page->{'buttons'}->intersperse( '<br>' ); 
  
  return $page;
}


1;