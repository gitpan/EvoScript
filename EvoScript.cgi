#!/usr/bin/perl

### EvoScript.cgi - Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # Perl source code for the EvoScript Web Application Framework 
  # is freely available under the artistic license at http://www.evoscript.com/

### Configuration Variables ###

# Resource Directory Path
my $Resource_Path = '.';

# Declare library paths
use lib '/opt/evoscript/lib';
# use lib '/opt/evoscript/cpan-libs';
  # You'll need the Class::MethodMaker, Ref, Time::JulianDay, Time::ParseDate, 
  # and URI::Heuristic packages, available through CPAN. Uncomment this line to 
  # use copies of these libraries that acompanied this EvoScript distribution.

###############################

# Init process globals
BEGIN { $VERSION = 4.00_04; };
BEGIN { $Start = time();    };

# Log process startup and exit
use Err::WebLogFormat;
BEGIN { warn "--- Starting WebApp (Version $main::VERSION)\n"; }
END   { warn "--- Stopping WebApp\n"; }

use strict;

# Supporting Libraries

use Data::DRef;

use Script;

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
