#

### Change History
  # 1998-06-12 Added lookup.
  # 1998-05-09 Created. -Simon

package Class::MethodMakerExtentions;

use strict;
use Class::MethodMaker;

@Class::MethodMakerExtentions::ISA = qw ( Class::MethodMaker );

# $package->import( no_op => [ qw / foo bar baz / ] )
sub no_op {
  my ($class, @args) = @_;
  my %methods;
  foreach (@args) {
    $methods{ $_ } = sub { };
  }
  $class->install_methods(%methods);
}

# $package->import( determine_once => [ qw / foo bar baz / ] );
sub determine_once {
  my ($class, @args) = @_;
  my %methods;
  foreach (@args) {
    my $name = $_;
    my $determiner = 'determine_' . $name ;
    my $TargetClass = $class->get_target_class;
    $methods{$name} = sub {
      my ($self) = @_;
      $self->{$name} = $self->$determiner() unless ( exists $self->{$name} );
      $self->{$name};
    };
    $methods{$determiner} = sub {
      die "Can't locate abstract method 'determine_$name', " . 
	  "required for $TargetClass, called from " . ref(shift) .".\n";
    };
    $methods{"clear_$name"} = sub {
      my ($self) = @_;
      delete $self->{$name};
    };
  }
  $class->install_methods(%methods);
}

# $package->import( lookup => [ 'price' => 'item_type' ] );
sub lookup {
  my ($class, @args) = @_;
  my %methods;
  while (@args) {
    my $name = shift @args;
    my $index = shift @args or die "No index for $name";
    my $TargetClass = $class->get_target_class;
    my $LookupTable = eval '\%' . $TargetClass . '::Lookup_' . $index;
    $methods{$name} = sub {
      my $self = shift;
      $LookupTable->{ $self->$index() }{ $name };
    };
    $methods{"set_$name"} = sub {
      my $self = shift;
      $LookupTable->{ $self->$index() }{ $name } = shift;
    };
  }
  $class->install_methods(%methods);
}

1;

=head2 no_op

Takes a single string or a reference to an array of strings as its
argument. For each string, creates a method with an empty body.

  no_op => [ qw / foo bar baz / ]

You might want to create and use such methods when building subclass hooks.

=head2 determine_once

Creates methods which cache their results in a hash key.

  determine_once => [ qw / foo bar baz / ]

Takes a single string or a reference to an array of strings as its
argument. For each string we provide three methods:

  sub x {
    my ($self) = @_;
    $self->{x} = $self->determine_x() unless ( exists $self->{x} );
    $self->{x};
  }

  sub determine_x {
    die "Can't locate abstract method 'determine_x'\n";
  }

  sub clear_x
    my ($self) = @_;
    delete $self->{x};
  }

It is supposed that the developer will supply another implementation of determine_x.

=head2 lookup

Look values up in a package index.

  lookup => [ 'price' => 'item_type' ]

Takes a reference to an array containing key value pairs. For each pair creates a method of the form listed below.

    sub <key> {
      my $self = shift;
      $Lookup_<value>{ $self-><value> }{ <key> };
    }

=cut
