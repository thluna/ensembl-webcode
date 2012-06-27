# $Id$

package EnsEMBL::Web::Document::Panel;

use strict;

use HTML::Entities qw(encode_entities);

use EnsEMBL::Web::Document::Renderer::String;

use base qw(EnsEMBL::Web::Root);

sub new {
  my $class = shift;
  
  my $self = {
    _renderer       => undef,
    components      => {},
    component_order => [],
    @_
  };
  
  bless $self, $class;
  return $self;
}

sub renderer :lvalue  { $_[0]->{'_renderer'}; }
sub hub               { return $_[0]->{'hub'}; }
sub clear_components  { $_[0]{'components'} = {}; $_[0]->{'component_order'} = []; }
sub components        { return @{$_[0]{'component_order'}}; }
sub component         { return $_[0]->{'components'}->{$_[1]}; } # Given a component code, returns the component itself
sub params            { return $_[0]->{'params'}; }
sub status            { return $_[0]->{'status'}; }
sub code              { return $_[0]->{'code'};   }
sub print             { shift->renderer->print(@_);  }
sub printf            { shift->renderer->printf(@_); }
sub timer_push        { $_[0]->{'timer'} && $_[0]->{'timer'}->push($_[1], 3 + $_[2]); }
sub _is_ajax_request  { return $_[0]->renderer->can('r') && $_[0]->renderer->r->headers_in->{'X-Requested-With'} eq 'XMLHttpRequest'; }
sub ajax_is_available { return 1; }

sub caption {
  my $self = shift;
  $self->{'caption'} = shift if (@_);
  return $self->{'caption'};
}

sub _error {
  my ($self, $caption, $message) = @_;
  return "<h4>$caption</h4>$message";
}

sub parse {
  my $self   = shift;
  my $string = shift;
  $string =~ s/\[\[object->(\w+)\]\]/$self->{'object'}->$1/eg;
  return $string;
}

=head2 Panel options.

There are five functions which set, clear and read the options for the panel

=over 4

=item C<$panel-E<gt>clear_option( $key )>

resets the option C<$key>

=item C<$panel-E<gt>add_option( $key, $val )>

sets the value of option C<$key> to C<$val>

=item C<$panel-E<gt>option( $key )>

returns the value of option C<$key>

=item C<$panel-E<gt>clear_options>

resest the options list

=item C<$panel-E<gt>options>

returns an array of option keys.

=back

=cut

sub clear_options { $_[0]{'_options'} = {};            }
sub clear_option  { delete $_[0]->{'_options'}{$_[1]}; }
sub add_option    { $_[0]{'_options'}{$_[1]} = $_[2];  }
sub option        { return $_[0]{'_options'}{$_[1]};   }
sub options       { return keys %{$_[0]{'_options'}};  }

=head2 Panel components.

There are a number of functions which set, clear, modify the list of 
components which make up the panel.

=over 4

=item C<$panel-E<gt>add_components(       $new_key, $function_name, [...] )>

Adds one or more components to the end of the component list

=item C<$panel-E<gt>remove_component(    $key )>

Removes the function called by the component named C<$key>

=item C<$panel-E<gt>replace_component(    $key,     $function_name )>

Replaces the function called by the component named C<$key> with a new function
named C<$function_name>

=item C<$panel-E<gt>prepend_to_component( $key,     $function_name )>

Extends a component, by adding another function call to the start of the list
keyed by name C<$key>. When the page is rendered each function for the component
will be called in turn (until one returns 0)

=item C<$panel-E<gt>add_to_component(     $key,     $function_name )>

Extends a component, by adding another function call to the end of the list
keyed by name C<$key>. When the page is rendered each function for the component
will be called in turn (until one returns 0)

=item C<$panel-E<gt>add_component_before( $key,     $new_key, $function_name )>

Adds a new component to the component list before the one
named C<$key>, and gives it the name C<$new_key>

=item C<$panel-E<gt>add_component_after(  $key,     $new_key, $function_name )>

Adds a new component to the component list after the one
named C<$key>, and gives it the name C<$new_key>

=item C<$panel-E<gt>add_component_first(  $new_key, $function_name )>

Adds a new component to the start of the component list and gives it the name C<$new_key>

=item C<$panel-E<gt>add_component_last(   $new_key, $function_name )>

Adds a new component to the end of the component list and gives it the name C<$new_key>

=item C<$panel-E<gt>add_component(        $new_key, $function_name )>

Adds a new component to the end of the component list and gives it the name C<$new_key>

=back 

=cut

sub add_components {
  my $self = shift;
  
  while (my ($code, $function) = splice(@_, 0, 2)) {
    if (exists $self->{'components'}{$code}) {
      push @{$self->{'components'}{$code}}, $function;
    } else {
      push @{$self->{'component_order'}}, $code;
      $self->{'components'}{$code} = [ $function ];
    }
  }
}

sub replace_component {
  my ($self, $code, $function, $flag) = @_;
  
  if ($self->{'components'}{$code}) {
    $self->{'components'}{$code} = [ $function ];
  } elsif ($flag ne 'no') {
    $self->add_component_last($code, $function);
  }
}

sub prepend_to_component {
  my ($self, $code, $function) = @_;
  return $self->add_component_first($code, $function) unless exists $self->{'components'}{$code};
  unshift @{$self->{'components'}{$code}}, $function;
}

sub add_to_component {
  my ($self, $code, $function) = @_;
  return $self->add_component_last($code, $function) unless exists $self->{'components'}{$code};
  push @{$self->{'components'}{$code}}, $function;
}

sub add_component_before {
  my ($self, $oldcode, $code, $function) = @_;
  
  return $self->prepend_to_component($code, $function) if exists $self->{'components'}{$code};
  return $self->add_component_first($code, $function) unless exists $self->{'components'}{$oldcode};
  
  my $i = 0;
  
  foreach (@{$self->{'component_order'}}) {
    if ($_ eq $oldcode) {
      splice @{$self->{'component_order'}}, $i, 0, $code;
      $self->{'components'}{$code} = [ $function ];
      return;
    }
    
    $i++;
  }
}

sub add_component_first {
  my ($self, $code, $function) = @_;
  return $self->prepend_to_component($code, $function) if exists $self->{'components'}{$code};
  unshift @{$self->{'component_order'}}, $code;
  $self->{'components'}{$code} = [ $function ];
}

sub add_component { my $self = shift; $self->add_component_last( @_ ); }

sub add_component_last {
  my ($self, $code, $function) = @_;
  return $self->add_to_component($code, $function) if exists $self->{'components'}{$code};
  push @{$self->{'component_order'}}, $code;
  $self->{'components'}{$code} = [ $function ];
}

sub add_component_after {
  my ($self, $oldcode, $code, $function) = @_;
  
  return $self->add_to_component($code, $function) if exists $self->{'components'}{$code};
  return $self->add_component_first($code, $function) unless exists $self->{'components'}{$oldcode};

  my $i = 0;
  
  foreach (@{$self->{'component_order'}}) {
    if ($_ eq $oldcode) {
      splice @{$self->{'component_order'}}, $i+1, 0, $code;
      $self->{'components'}{$code} = [ $function ];
      return;
    }
    
    $i++;
  }
  
  $self->{'components'}{$code} = [ $function ];
}

sub remove_component {
  my ($self, $code) = @_;
  
  my $i = 0;
  
  foreach (@{$self->{'component_order'}}) {
    if ($_ eq $code) {
      splice @{$self->{'component_order'}}, $i, 1;
      delete $self->{'components'}{$code};
      return;
    }
    
    $i++;
  }
}

sub content_Text { 
  my $self = shift;
  
  my $temp_renderer = $self->renderer;
  
  $self->renderer = new EnsEMBL::Web::Document::Renderer::String;
  $self->content;
  
  my $value = $self->renderer->content;
  
  $self->renderer = $temp_renderer;
  $self->renderer->print($value)
}

sub _caption_h1 {
  my $self    = shift;
  my ($head, $subhead);
  my $html = '<h1 class="summary-heading">';

  if (ref($self->{'caption'}) eq 'ARRAY') {
    my ($head, $subhead) = @{$self->{'caption'} || []};
    $html .= $head;
    if ($subhead) { 
      $html .= ' <span class="summary-subhead">'.$subhead.'</span>'; 
    }
  }
  else {
    $html .= $self->{'caption'};
  }

  $html .= '</h1>';
  return $html;
}

sub _caption_h2_with_helplink {
  my $self  = shift;
  my $id    = $self->{'help'};
  my $html  = '<h1 class="caption">';
     $html .= sprintf ' <a href="/Help/View?id=%s" class="popup help-header constant" title="Click for help (opens in new window)">', encode_entities($id) if $id;
     $html .= $self->{'caption'};
     $html .= '</a>' if $id;
     $html .= '</h1>';

  return $html;
}


sub content {
  my $self = shift;
  
  return $self->{'raw'} if exists $self->{'raw'};
  
  my $hub        = $self->hub;
  my $status     = $hub ? $hub->param($self->{'status'}) : undef;
  my $content    = sprintf '%s<p class="invisible">.</p>', $status ne 'off' ? sprintf('<div class="content">%s</div>', $self->component_content) : '';
  my $panel_type = $self->renderer->{'_modal_dialog_'} ? 'ModalContent' : 'Content';
  
  if (!$self->{'omit_header'}) {

    my $caption = '';
    if (exists $self->{'caption'}) {
      my $summary = $self->{'code'} eq 'summary_panel' ? 1 : 0;
      if ($summary) {
        $caption = $self->_caption_h1;
      }
      else {
        $caption = $self->_caption_h2_with_helplink;
      }
    }
    
    $content = qq{
      <div class="nav-heading">
        $caption
        <p class="invisible">.</p>
      </div>
      $content
    };
  }
  
  return qq{
    <div class="panel js_panel">
      <input type="hidden" class="panel_type" value="$panel_type" />
      $content
    </div>
  };
}

sub component_content {
  my $self    = shift;
  my $html    = $self->{'content'};
  my $builder = $self->{'builder'};
  my $hub     = $self->hub;
  
  return $html unless $builder;
  return $self->das_content if $self->{'components'}->{'das_features'};
  return $html unless scalar keys %{$self->{'components'}};
  
  my $modal        = $self->renderer->{'_modal_dialog_'};
  my $ajax_request = $self->_is_ajax_request;
  my $base_url     = $hub->species_defs->ENSEMBL_BASE_URL;
  my $function     = $hub->function;
  my $is_html      = ($hub->param('_format') || 'HTML') eq 'HTML';
  
  foreach my $entry (map @{$self->{'components'}->{$_} || []}, $self->components) {
    my ($module_name, $content_function) = split /\//, $entry;
    my $component;
    
    ### Attempt to require the Component module
    if ($self->dynamic_use($module_name)) {
      eval {
        $component = $module_name->new($hub, $builder, $self->renderer);
      };
      
      if ($@) {
        $html .= $self->component_failure($@, $entry, $module_name);
        next;
      }
    } else {
      $html .= $self->component_failure($self->dynamic_use_failure($module_name), $entry, $module_name);
      next;
    }
    
    ### If this component is configured to be loaded by an AJAX request, print just the div which the content will be loaded into
    if ($component->ajaxable && !$ajax_request && $is_html) {
      my $url   = $component->ajax_url($content_function);
      my $class = 'initial_panel' . ($component->has_image ? ' image_panel' : ''); # classes required by the javascript
      
      # Safari requires a unique name on inputs when using browser-cached content (eq when the user presses the back button)
      # $panel_name is the memory location of the current object, so unique for each panel.
      # Without this, ajax panels don't load, or load the wrong content.
      my ($panel_name) = $self =~ /\((.+)\)$/;
      
      $html .= sprintf qq{<div class="ajax $class"><input type="hidden" class="ajax_load" name="$panel_name" value="%s" /></div>}, encode_entities($url);
    } else {
      my $content;
      
      ### Try to call the required content function on the Component module
      eval {
        my $func = $ajax_request ? lc $function : $content_function;
        $func    = "content_$func" if $func;
        $content = $component->get_content($func);
      };
      
      if ($@) {
        $html .= $self->component_failure($@, $entry, $module_name);
      } elsif ($content) {
        if ($ajax_request) {
          my $id         = $function eq 'sub_slice' ? '' : $component->id;
          my $panel_type = $modal || $content =~ /panel_type/ ? '' : '<input type="hidden" class="panel_type" value="Content" />';
          
          # Only add the wrapper if $content is html, and the update_panel parameter isn't present
          $content = qq{<div class="js_panel __h __h_comp_$id" id="$id">$panel_type$content</div>} if !$hub->param('update_panel') && $content =~ /^\s*<.+>\s*$/s;
        } else {
          my $caption = $component->caption;
          $html .= sprintf '<h2>%s</h2>', encode_entities($caption) if $caption;
        }
        
        $html .= $content;
      }
    }
  }
  
  $html .= sprintf '<div class="more"><a href="%s">more about %s ...</a></div>', $self->{'link'}, encode_entities($self->parse($self->{'caption'})) if $self->{'link'};
  
  return $html;
}

sub das_content {
  my $self    = shift;
  my $builder = $self->{'builder'};
  my $xml;
  
  foreach my $function_name (@{$self->{'components'}->{'das_features'}}) {
     my ($module_name, $func) = split /::(\w+)$/, $function_name;
    
    if ($self->dynamic_use($module_name)) {
      eval {
        $xml = $module_name->new($self->hub, $builder)->$func;
      };
      
      $self->component_failure($@, 'das_features', $function_name) if $@;
    } else {
      warn "Component $function_name (compile failure)";
      
      $xml .= $self->_error(
        qq{Compile error in component "<strong>das_features</strong>"},
        qq{<p>Function <strong>$function_name</strong> not executed as unable to use module <strong>$module_name</strong> due to syntax error.</p>} . $self->_format_error($self->dynamic_use_failure($module_name))
      );
    }
    
    last if $xml;
  }
  
  delete $self->{'components'}->{'das_features'};
  
  return $xml;
}

sub component_failure {
  my ($self, $error, $component, $module_name) = @_;
  
  warn $error;
  
  return $self->_error(
    qq{Runtime Error in component "<strong>$component</strong> [content]"},
    qq{<p>Function <strong>$module_name</strong> fails to execute due to the following error:</p>} . $self->_format_error($error)
  );
}

1;
