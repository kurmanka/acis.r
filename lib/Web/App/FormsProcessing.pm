package Web::App;


use strict;



sub form_invalid_value {
  my $self = shift;
  $self -> form_error( 'invalid-value', shift );
}


sub form_required_absent {
  my $self = shift;
  $self -> form_error( 'required-absent', shift );
}


sub form_error {
  my $self    = shift;
  my $place   = shift;
  my $element = shift;

  my $response = $self -> {'presenter-data'} {response};
  
  if ( ref $response -> {form} {errors} {$place}  ne 'ARRAY' ) {
    $response -> {form} {errors} {$place} =  [ $element ];
    return;
  }

  push @{ $response -> {form} {errors} {$place} }, $element;
}




sub set_form_action {
  my $self   = shift;
  my $action = shift;

  $self -> {'presenter-data'} {response} {form} {action} = $action;
}


sub set_form_value {
  my $self    = shift;
  my $element = shift;
  my $value   = shift;
  
  $self -> {'presenter-data'} {response} 
           {form} {values} {$element} = $value;

  debug "set form value $element: $value";
}


sub get_form_value {
  my $self    = shift;
  my $element = shift;

  my $value = $self -> form_input -> {$element};

  return $value;
}




sub prepare_form_data {

  my $self   = shift;
  
  my $screen        = $self -> request -> {screen};
  my $screen_config = $self -> get_screen( $screen );
  my $params        = $screen_config   -> {variables};
  my $session       = $self -> session;

  foreach ( @$params ) {
    my $where = $_->{place};
    my $name  = $_->{name};
    
    next unless defined $where;
      
    my $value = $session -> get_value_from_path( $where );
    $self -> set_form_value( $name, $value );
  }
}



sub check_input_parameters {
  my $self   = shift;
  
  require CGI::Untaint;

  my $required_absent;
  my $invalid_value;

  my $screen        = $self -> request -> {screen};
  my $screen_config = $self -> get_screen( $screen );
  my $params        = $screen_config -> {variables};
  my $vars       = $self -> variables;
  my $form_input = $self -> form_input;
  
  debug "checking input parameters";
  debug "loading CGI::Untaint";

  my $form_input_copy = { %$form_input };
  
  my $handler;

  {
    my @cuparams = ();
    my $include_path = $self -> {CGI_UNTAINT_INCLUDE_PATH};
    if ( $include_path ) {
      if ( $CGI::Untaint::VERSION < "1.23" ) {
        $include_path =~ s!::!/!g;
      } else {
        $include_path =~ s!/!::!g;
      }
      push @cuparams, "INCLUDE_PATH", $include_path;
    }
    
    $handler = new CGI::Untaint( { @cuparams }, 
                                 $form_input_copy );
  }

  my $errors;
  
  foreach ( @$params ) {
    my $type     = $_ -> {type};
    my $name     = $_ -> {name};
    my $required = $_ -> {required};
    
    my $error;
    my $value;

    if ( defined $form_input -> {$name} ) {
      
      my $orig_val =  $form_input -> {$name};

      debug "parameter '$name' with value '$orig_val'";

      $orig_val =~ s/(^\s+|\s+$)//g
        unless $self ->{NO_INPUT_TRIMMING};

      if ( $orig_val ) {
        
        if ( $type ) {
          $value = $handler -> extract( "-as_$type" => $name );
          $error = $handler -> error;

          if ( $error ) {
            debug "invalid value at $name with type='$type' ($error)";
            
            $self -> form_error ('invalid-value', $name );
            $errors = 'yes';
            $value = $orig_val;
          }
      
        } else {
          $value = $orig_val; 
        }

      } else {
        
        if ( $required eq 'yes' ) {
          debug "required value at $name is empty";
          $self -> form_error( 'required-absent', $name );
          $errors = 'yes';
        }
        $value = '';
      }

      $self -> set_form_value( $name, $value );

    } else {

      if ( $required eq 'yes' ) {
        debug "required value at $name is absent";
        $self -> form_error( 'required-absent', $name );
        $errors = 'yes';
      }
    }


  }  ### for each in @params

  if ( $errors ) {
    $self -> clear_process_queue;
  }
}








sub process_form_data {
  my $self = shift;
  
  my $variables = $self ->variables;
  my $screen    = $self -> request -> {screen};
  my $screen_config = $self -> get_screen( $screen );
  my $params    = $screen_config -> {variables};
  my $input     = $self -> form_input;
  my $session   = $self -> session;
  
  foreach my $par ( @$params ) {

    my $name   = $par ->{name};
    my $where  = $par ->{place};
     
    next if not defined $where;
    next if not exists $input ->{$name} 
      and exists $par ->{'if-not-empty'};

    my $val    = $input ->{$name};
    my @places = split ',', $where;
    my $data;

    debug "process parameter name = '$name', value = '$val'";
    debug "store to $where";
     
    foreach my $path ( @places ) {
      $session -> save_value_to_path( $path, $val );
    }

  }
}









1;
