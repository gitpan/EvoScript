### Evo::libs specifies the path to a directory containing the Evo libraries.

package Evo::libs;

use lib '/opt/evoscript/lib';

1;

__END__

=head1 Evo::libs

Provides a central registry for configuring the path to a directory containing the Evo libraries, including EvoScript, WebApp, and DBO.

Really just a kludge to put the Evo libraries into your search path at compile-time.

=cut