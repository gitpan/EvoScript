### Class::NamedFactory 
  # Provides class registration and by-name lookup methods

### Base Class Environment
  # $hashref = BASECLASS->subclasses_by_name();
  # @names = BASECLASS->subclass_names();
  # $SUBCLASS = BASECLASS->subclass_by_name( $name );

### SUBCLASS Registration
  # SUBCLASS->register_subclass_name();
  # $classname = SUBCLASS->subclass_name();

### Change History
  # 1998-02-25 Minor doc updates
  # 1997-11-24 Moved into the Class::* hierarchy, renamed to NamedFactory.
  # 1997-11-04 Created as Evo::SubclassFactory.

package Class::NamedFactory;

use Carp;

### Base Class Environment

# $hashref = BASECLASS->subclasses_by_name();
sub subclasses_by_name { croak "abstract" }	

# @names = BASECLASS->subclass_names();
sub subclass_names {
  my $package = shift;
  return keys %{ $package->subclasses_by_name };
}

# $SUBCLASS = BASECLASS->subclass_by_name( $name );
sub subclass_by_name {
  my $package = shift;
  my $name = shift;
  return $package->subclasses_by_name->{ $name };
}

### Subclass Registration

# SUBCLASS->register_subclass_name();
sub register_subclass_name {
  my $package = shift;
  $package->subclasses_by_name->{ $package->subclass_name } = $package;
}

# $classname = SUBCLASS->subclass_name();
sub subclass_name { croak "abstract" }

1;

__END__

=head1 Class::NamedFactory

NamedFactory provides a subclass naming mechanism for to allow instantiation by name.

=head1 Synopsis

    package Widget;
    use Class::NamedFactory;
    push @ISA, qw( Class::NamedFactory );
    
    use vars qw( %KindsOfWidgets );
    sub subclasses_by_name { \%KindsOfWidgets; }
    
    sub subclass_name { 'vanilla' }
    Widget->register_subclass_name;
    
    package Gadget;
    push @ISA, qw( Widget );
    
    sub subclass_name { 'gadget' }
    Gadget->register_subclass_name;
    
    ...
    
    $thingie = Widget->subclass_by_name( 'gadget' )->new;

=head1 Description

This package provides some flexibility when creating class hierachies by allowing subclasses to register their availability along with text identifiers, so the the caller can select which class to instantiate.

=head1 Reference

=over 4

=item BaseClass->subclass_by_name( $name ) : $package

Returns the package specified by the provided name.

=item BaseClass->subclass_names : @names

Returns a list of known subclass names.

=back

=head2 Base Class Environment

=over 4

=item BaseClass->subclasses_by_name : $hashref

Abstract. Returns a reference to the hash mapping subclass names to packages. Define this function in your top-level class.

=back

=head2 Subclass Registration Methods

Use these methods to register your subclass.

=over 4

=item Subclass->subclass_name : $text

Abstract. Returns the string identifying this package. Define this function in each named subclass.

=item Subclass->register_subclass_name

Called by each named subclass to notify the superclass of this package's availability.

=back

=head1 Caveats and Upcoming Changes

Perhaps the package should be renamed to Class::SubclassRegistry?

This module is new and open to change suggestions, but we expect to continue to support the current interface.

=head1 This is Free Software

Copyright 1997, 1998 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut
