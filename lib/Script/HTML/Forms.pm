### Script::HTML::Forms provides forms-related HTML tags

### <form> ... </form>

### <input>
  # %$args = $tag->get_args();

### <select> <option> text ... </select>

### <option>
  # %$args = $tag->get_args();

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-06-11 Added support for <option label=#...> -Simon
  # 1998-05-27 Added default_command. -Dan
  # 1998-04-27 Added escaping for option labels.
  # 1998-03-20 Replaced request.links.script_file with links.script . path.info
  # 1998-03-05 Added Submit package, which creates <input type=submit> tags.
  # 1998-03-03 Shifted to exlicit imports from Data::DRef.
  # 1997-11-23 Moved 'current' argument from option->args to select->interpret
  # 1997-11-21 Added option label argument handling
  # 1997-10-31 Created. -Simon

package Script::HTML::Forms;

$VERSION = 4.00_1998_03_03;

use Script::HTML::Tag;

### <form> ... </form>

package Script::HTML::Forms::Form;
@ISA = qw( Script::HTML::Container );

sub subclass_name { 'form' };
Script::HTML::Forms::Form->register_subclass_name;

use Data::DRef qw( getData );

# <form action=#url|-current method=get|post|multipart enctype=x target=x>..</>

# %$args = $tag->get_args();
sub get_args {
  my $tag = shift;
  
  my $args = { %{$tag->{'args'}} };
  
  $args->{'action'} = 
	      getData('request.links.script') . getData('request.path.info')
		  if ( $args->{'action'} and $args->{'action'} eq '-current' );
  
  if ( $args->{'method'} and $args->{'method'} eq 'multipart' ) {
    $args->{'method'} = 'post';
    $args->{'enctype'} = 'multipart/form-data';
  }

  if ($args->{'default_command'} and (getData('request.client.browser') =~ /MSIE/)) {

    warn 'WEB BROWSER IS IE';
    $args->{'onsubmit'} = 'if ( ! this.command.value ) { 
                             this.command.click();
			     return false
			   } else { return true }'
  } else {
    warn 'WEB BROWSER IS: ', getData('request.client.browser');
  }

  delete $args->{'default_command'};

  return $args;
}

### <input>

package Script::HTML::Forms::Input;
@ISA = qw( Script::HTML::Tag );

sub subclass_name { 'input' };
Script::HTML::Forms::Input->register_subclass_name;

use Data::DRef qw( getData );

# %$args = $tag->get_args();
sub get_args {
  my $tag = shift;
  
  my $args = { %{$tag->{'args'}} };
  
  $args->{'value'} = getData($args->{'value'})
		      if ( $args->{'value'} and $args->{'value'} =~ s/\A\#// );
  
  return $args;
}

### <input type=submit>

package Script::HTML::Forms::Submit;
@ISA = qw( Script::HTML::Forms::Input );

sub init {
  my $tag = shift;
  $tag->{'args'}{'type'} ||= 'submit';
  $tag->{'args'}{'name'} ||= 'command';
}

### <textarea> text ... </textarea>

package Script::HTML::Forms::TextArea;
@ISA = qw( Script::HTML::Container );

sub subclass_name { 'textarea' };
Script::HTML::Forms::TextArea->register_subclass_name;

### <select> <option> text ... </select>

package Script::HTML::Forms::Select;
@ISA = qw( Script::HTML::Container );

use Data::DRef qw( getData );

sub subclass_name { 'select' };
Script::HTML::Forms::Select->register_subclass_name;

# $sequence->add( $element );
# sub add {
#   my $sequence = shift;  
#   my $element = shift;
#   $element = Evo::Script::Literal->new( $element ) unless (ref $element);
#   
#   $sequence->append($element) if ($element->isa('Script::HTML::Forms::Option'));
# }

# $html = $tag->interpret()
sub interpret {
  my $tag = shift;
  local $Current = $tag->{'args'}->{'current'}
				    if ( exists $tag->{'args'}->{'current'} );
  $Current = getData($Current) if (defined $Current and $Current =~ s/\A\#// );
  return $tag->SUPER::interpret();
}

### <option>

package Script::HTML::Forms::Option;
push @ISA, qw( Script::HTML::Tag );

sub subclass_name { 'option' };
Script::HTML::Forms::Option->register_subclass_name;

use Data::DRef qw( getData );

# use Evo::Script::Sequence;
# push @ISA, qw( Evo::Script::Sequence );

# $html = $tag->interpret()
sub interpret {
  my $tag = shift;
  my $label_arg = $tag->{'args'}{'label'};
  $label_arg = getData($label_arg) if ( $label_arg =~ s/\A\#// );
  my $label = $label_arg || $tag->{'args'}{'value'} || '';
  return $tag->open_tag() . Script::HTML::Escape::html_escape($label);
}

# %$args = $tag->get_args();
sub get_args {
  my $tag = shift;
  
  my $args = $tag->SUPER::get_args();
  
  $args->{'value'} = getData($args->{'value'})
  					if ( $args->{'value'} =~ s/\A\#// );
  
  if (defined $Script::HTML::Forms::Select::Current) {
    if ( $Script::HTML::Forms::Select::Current eq $args->{'value'} ) {
      $args->{'selected'} = undef;
    } else {
      delete $args->{'selected'};
    }
  }
  
  delete $args->{'current'};
  delete $args->{'label'};
  
  return $args;
}

1;