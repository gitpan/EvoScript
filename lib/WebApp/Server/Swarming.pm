package WebApp::Server::Swarming;

$VERSION = 1.02_00;

require 5.003;
use strict;

use Carp;
use Err::Debug;

# fork several times before receving a request; then parent exits
# children respond

