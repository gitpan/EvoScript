#!/usr/bin/perl

### EvoScript.cgi - Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # Perl source code for the EvoScript Web Application Framework with DBObjects 
  # is freely available under the artistic license at http://www.evoscript.com/

### Configuration Variables ###

# Resource Directory Path
my $Resource_Path = '/sites/evoscript/examples';

# Declare library paths
use lib '/sites/evoscript/src-lib-current';
use lib '/sites/evoscript/src-lib-CPAN';

# To add support for relational databases, uncomment one of these two:
# use DBAdaptor::MySQL;
# use DBAdaptor::Win32ODBC;

###############################

# Init process globals
BEGIN { $VERSION = 4.00_03; };
BEGIN { $Start = time();    };

# Log process startup and exit
use Err::WebLogFormat;
BEGIN { warn "--- Starting WebApp (Version $main::VERSION)\n"; }
END   { warn "--- Stopping WebApp\n"; }

use strict;

# Supporting Libraries

use Data::DRef;

use Script;

use Record;
use Field::Available;

use DBAdaptor::DelimitedText;

use WebApp::Server;

use WebApp::Request::CGI;

use WebApp::Handler::FileHandler;
use WebApp::Handler::DirectoryHandler;
use WebApp::Handler::ResourceHandler;
use WebApp::Handler::LoggingHandler;
use WebApp::Handler::Scripted;
use WebApp::Handler::Plugins;

use WebApp::Resource;
$WebApp::Resource::SearchPath = File::SearchPath->new($Resource_Path);

use WebApp::Resource::Site;
use WebApp::Resource::ScriptedPage;
use WebApp::Resource::Records;

# Create a WebApp Server
my $WebApp = WebApp::Server->new( qw( 
  WebApp::Request::CGI
  WebApp::Handler::FileHandler
  WebApp::Handler::DirectoryHandler
  WebApp::Handler::LoggingHandler
  WebApp::Handler::ResourceHandler
  WebApp::Handler::Scripted
  WebApp::Handler::Plugins
) );

setData('server', $WebApp);

# Execution
$WebApp->run();
