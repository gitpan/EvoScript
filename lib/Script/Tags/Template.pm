

package Script::Template;

@ISA = qw( Script::Statement );

# Decide how to handle this. Maybe make it another tag.
# 'interpret' => {'dref'=>'no', 'required'=>'flag'},

%ArgumentDefinitions = {
  'name' =>  {'dref' => 'optional', 'required'=>'string_or_nothing'},
  
  'escape' => {'dref'=>'no', 
  		'required'=>'oneof_or_nothing url html quotedhtml htmltext'},
}


# code type handler for text-with-embedded-tags
sub codetype_script_tags {
  my($script_mgr, $tag_def, $tag) = @_;
  
  my($code) = $tag_def->{'code'};
  unless (defined $code) {
    warn "script error: no code definition for tag " . $tag->{'name'};
    return;
  }
  
  my($recordseparator) = $/;
  undef $/;
  my($codechecksum) = unpack ("%32C*", $code) % 32767;
  $/ = $recordseparator;
  
  my $current_checksum = $tag_def->{'parse_checksum'} || 0;
  unless ($codechecksum == $current_checksum) {
    $tag_def->{'parse_checksum'} = $codechecksum;
    ($tag_def->{'parsetree'}) = &parse_text_with_tags($script_mgr, $code);
  }
  
  my ($oldargs) = $script_mgr->{'context'}{'-args'};
  &set($script_mgr->{'context'}, '-args', $tag->{'args'});
  
  my $oldcontents = $script_mgr->{'context'}{'-contents'};
  my $contents = $tag->{'contents'};
  my $content_type = $tag_def->{'content'} || '';
  if ($content_type eq 'tags') {
    $contents = $script_mgr->run_tags($contents);
  }
  set($script_mgr->{'context'}, '-contents', $contents);
  
  my $result = $script_mgr->run_tags($tag_def->{'parsetree'});
  
  &set($script_mgr->{'context'}, '-args', $oldargs);
  &set($script_mgr->{'context'}, '-contents', $oldcontents);
  
  # warn "$tag->{'name'} returns $result";
  
  return $result;
};
