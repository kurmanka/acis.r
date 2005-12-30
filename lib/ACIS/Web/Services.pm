package ACIS::Web;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    The continuation of the ACIS::Web class, which is the heart of
#    the web application framework.  This file contains some of the
#    "other"-level methods, probably less abstract, more
#    ACIS-specific-logic-dependent, but not much, really.
#
#
#  Copyright (C) 2003 Ivan Baktcheev, Ivan Kurmanov for ACIS project,
#  http://acis.openlib.org/
#
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License, version 2, as
#  published by the Free Software Foundation.
# 
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#  ---
#  $Id: Services.pm,v 2.0 2005/12/27 19:47:40 ivan Exp $
#  ---

use strict;

use Data::Dumper;
use Carp::Assert;

use Web::App::Common    qw( date_now debug convert_date_to_ISO );
use ACIS::Data::DumpXML qw( dump_xml );

use Encode qw/encode decode/;

use ACIS::Web::SysProfile;



####   SESSION STUFF   ####


sub start_session {
  my $self  = shift;
  my $type  = shift;

  assert( ref $self );
  assert( not $self -> session ); ### XXX ?

  my $sid;

  my $class = $SESSION_CLASS{$type};
  if ( not $class ) { 
    $self -> errlog( "Session class for session type '$type' is undefined" );
    return undef; 
  }

  my $session  = $class -> new( $self, @_ );

  if ( not $session ) {
    $self -> errlog( "can't create session" );
    die "can't create session";
  }

  $sid = $session ->id;
  debug "session '$sid' created";

  $self -> set_session_cookie( $sid );
  $self -> session( $session );

  return $session;
}



sub load_session {
  my $app = shift;
  my $just_try = shift;
  
  if ( $app -> session ) {  ###  to not reload same session twice
    return $app -> session;
  }

  my $request  = $app -> request;
  my $home     = $app -> {home};
  
  my $seid     = $request -> {'session-id'};

  if ( not $seid ) {
    if ( not $just_try ) {
      $app -> clear_process_queue;
    }
    return undef;
  }

  my $IP           = $ENV{'REMOTE_ADDR'};
  my $override;
  
  my $sessions_dir = "$home/sessions";
  my $sfilename    = "$sessions_dir/$seid";

#  assert( -f $sfilename );
 
  my $session = $SESSION_CLASS_MAIN -> load( $app, $sfilename );

  if ( not $session ) {
    ###  XXX should I delete this bad session then?
    if ( $just_try ) {
      return "bad-session-file";

    } else {
      $app -> error( "session-failure" );
      $app -> set_form_action( $app ->config ('base-url') );
      $app -> clear_session_cookie;
      $app -> set_presenter( 'login' );
      $app -> clear_process_queue;
      debug "can't load the session, session expired or load somehow failed";
      return undef;
    }
  }


  if ( $session -> owner -> {IP} eq $IP ) {
    debug "previous session found, IP matches, continuing";
    
  } else {
    # IPs don't match -- should not continue
    debug "can't load the session, the user IP addresses don't match";

    ###  may be it is better to check the session validity by checking
    ###  the user-agent string?  Probably it will be more comfortable
    ###  for the users, although -- less secure.  In some big
    ###  organizations both IP addresses and the user agent strings
    ###  may in fact be the same with high probability.

    my $pass = $app -> request_input( "pass" );

    if ( $pass ) {

      if ( $session -> owner -> {password} eq $pass ) {
        ###  Override
        $session -> owner ->{IP} = $IP;
        $override = 1;
      
      } else {
        my $login = $session ->owner ->{login};

        if ( $just_try ) {
          return "no-good-password";
          
        } else { 
          ###  serious
          $app -> log ( "session override attempt failed [$login] from $IP" );

          $app -> error( "login-bad-password" );
          $app -> set_presenter ( 'relogin-password' );
          $app -> clear_process_queue;
          
          return undef;
        }
      }
      
    } else {
      
      if ( $just_try ) {
        return "no-good-password";

      } else { # serious
  
        $app -> message( "must-relogin" );
        $app -> set_presenter ( 'relogin-password' );
        $app -> clear_process_queue;
        return undef;
      }
    }

  }

  $app -> session( $session );

  if ( $override and not $just_try ) {
    $app -> userlog ( "session $seid IP override (new: $IP)" );
    my $screen = $app ->request ->{screen};
    $app -> redirect_to_screen( $screen );
  }

  return $session;
}


sub logoff_session {
  my $self = shift;
  my $session = $self -> session;
  $session -> close( $self );

  $self -> clear_session_cookie;

  undef $self -> request -> {'session-id'};
  undef $self -> {session};
}


sub set_session_cookie {
  my $self = shift;
  my $sid  = shift;
  $self -> set_cookie( -name  => 'session',
                       -value => $sid     );
}

sub clear_session_cookie {
  my $self = shift;
  $self -> set_cookie( -name  => 'session',
                       -value => '',
                       -expires => '-3Y',
                     );
}

####  END OF SESSION STUFF  ####


####  create userdata  ####

sub create_userdata {
  my $app = shift;
  my $class = shift || "ACIS::Web::UserData";

  assert( $app -> paths -> {'user-data'} );

  my $file = $app -> paths -> {'user-data'};
  
  my $userdata = $class -> new( $file );
}


###############################################################
###############     A U T H E N T I C A T E      ##############
###############################################################

sub equal_passwords($$) {
  my $p1 = shift;
  my $p2 = shift;

  return 1 if $p1 eq $p2;

  $p1 =~ tr/lIO/110/;
  $p2 =~ tr/lIO/110/;
  
  if ( $p1 eq $p2 ) { return 1; }
  if ( lc $p1 eq lc $p2 ) { return 1; }

  return 0;
}



sub check_login_and_pass {

# Returns one of:
#   $udata - login and pass are fine
#   'no-account' - no such account
#   'account-damaged' 
#   'wrong-password' 
#   'account-locked:$sid' - account locked by a session
#   'existing-session-loaded' - 

  my $app   = shift;
  
  my $login = shift;
  my $pass  = shift;
  my $override = shift; # ?


  ### lower-case login
  $login = lc $login; 


  ###  now it's time to check, if such a user exists and if her
  ###  password matches to the one entered.
  ###  if both true, check the lock;

  my $udata_file    = $app -> userdata_file_for_login( $login );

  if ( not -f $udata_file ) {
    return 'no-account';
  }


  my $lock = "$udata_file.lock";
  
  if ( -f $lock ) {{

    debug "found lock file at '$lock'";

    my $sid; 
    if ( open LOCK, $lock ) {
      $sid = <LOCK>;
      close LOCK;
      debug "locked by session $sid";
    }    

    ### go get the session, if it exists
    ### ignore the lock if it doesn't
    ### if it exists, see if user wants to steal it...
    
    my $file = $app -> paths -> {sessions} . "/$sid";

    if ( not -f $file ) {
      debug "but session doesn't exist anymore ($file)";
      unlink $lock;
      last;
    }
    
    my $session = $SESSION_CLASS_MAIN -> load( $app, $file );
      
    if ( not defined $session or not $session ) {
      unlink $lock;
      debug "but session can't be loaded ($session)";
      last;
    }
    
    debug "and in fact, there is a session, and it belongs to the user";
    
    my $owner = $session -> owner;

    if ( $owner and $owner ->{login} ) {
      if ( $login eq lc $owner ->{login} ) {


        if ( not equal_passwords( $pass, $owner ->{password} ) ) {
          return "wrong-password:$owner->{password}";
        }

        if ( $override ) {
          ####  steal the session.  override.
          $app -> update_paths_for_login( $login );
          $app -> session( $session );
          return 'existing-session-loaded';
        }
      }
    }

    return "account-locked:$sid:$owner->{login}";

  }} else {
    debug 'lock file does not exist';
  } 


  my $udata = load ACIS::Web::UserData ( $udata_file );

  if ( not defined $udata
       or not defined $udata->{owner}
       or not defined $udata->{owner}{login}
       or not defined $udata->{owner}{password} 
    ) {
    return 'account-damaged';
  }


  if ( not equal_passwords $pass, $udata -> {owner} {password} ) {
    return "wrong-password:$udata->{owner}{password}";
  }

   
  return $udata;
}




sub authenticate {
  my $app = shift;

  ### if a session is already loaded, why authenticate?

  return undef if $app -> session;

  ### some preparations
#  my $request  = $app -> request;
#  my $home     = $app -> {home};
#  my $paths    = $app -> {paths};
#  my $vars     = $app -> variables;

  my $login;  
  my $passwd;

  debug "check CGI parameters and cookies";
  
  # now we find out

  my $form_input = $app -> form_input;
  my $query      = $app -> request -> {CGI} ;
 
  $login  = $form_input -> {login}; 
  $passwd = $form_input -> {pass}; 
 
  if ( not $login ) {
    $login = $query -> cookie ( 'login' );
  }

  if ( not $passwd ) {
    $passwd = $query -> cookie( 'pass' );
  }


  if ( $login and $form_input -> {'remind-password'} ) {
    $app -> forgotten_password ();
    return 0;
  }


  ### final check
  if ( not $login or not $passwd ) {

    $app -> clear_process_queue;
    if ( defined $login ) {
      $app -> set_form_value( 'login', $login );
      $app -> variables -> {'remind-password-button'} = 1;
    }
    $app -> set_presenter ( 'login' );

    return undef;
  }
  
  $login = lc $login;
  debug "we do have both login ($login) and password ($passwd)";

  
  ###  now it's time to check, if such a user exists and if her
  ###  password matches to the one entered.

  my $status = $app -> check_login_and_pass( $login, $passwd, 1 );

  if ( $status eq 'no-account' ) {

    # no such user 
    $app -> errlog( "login attempt failed, user not found: $login" );
    $app -> set_form_value( 'login', $login );
    $app -> error ( 'login-unknown-user' );
    $app -> clear_process_queue;

    $app -> set_presenter( 'login' );
    $app -> variables -> {'show-register-invitation'} = 1;

  } elsif ( $status eq 'account-damaged' )  {

    my $udata_file = $app -> userdata_file_for_login( $login );

    $app -> errlog( "[$login] userdata file $udata_file is damaged" );
    $app -> error( 'login-account-damaged' );
    $app -> clear_process_queue;
    $app -> set_presenter( 'sorry' );

    $app -> event ( -class => 'authenticate',
                    -descr => "userdata damaged"
                    -file  => $udata_file,
                    -login => $login,
                  );

  } elsif ( $status =~ m/wrong\-password:(.+)/ ) {
    
    my $expected = $1;

    $app -> errlog( "[$login] login attempt failed, wrong password ($passwd)" );
    $app -> set_form_value( 'login', $login );
    $app -> error( 'login-bad-password' );
    $app -> variables -> {'remind-password-button'} = 1;
    $app -> clear_process_queue;
    
    $app -> set_presenter( 'login' );
    
    $app -> event ( -class => 'authenticate',
                    -descr => "login failed, password given/expected: $passwd/$expected",
                    -login => $login,
                  );
    
  } elsif ( $status eq 'existing-session-loaded' ) {

    my $IP    = $ENV {REMOTE_ADDR};
    my $owner = $app -> session -> owner;

    if ( $owner -> {IP} eq $IP ) {
      $app -> userlog ( "session relogin (override) from the same IP ($IP)" );
      
    } else {
      $app -> userlog ( "session relogin (override) from another IP ($IP)" );
      $owner -> {IP} = $IP;
    }
    
    $app -> sevent ( -class  => 'auth',
                     -descr  => 'user re-entered',
                     -IP     => $IP );
    
    $app -> set_session_cookie( $app -> session -> id );

    return 1;

  } elsif ( $status =~ /^account-locked:([^:]+):(.+)/ ) {

    $app -> event ( -class => 'authenticate',
                    -descr => "login failed, userdata locked: se:$1 by $2",
                    -login => $login,
                  );
    
  } elsif ( ref $status ) {

    my $udata = $status;
    $app -> update_paths_for_login( $login );

    return login_start_session ( $app, $udata, $login );

  } else {
    ### XX ??
  }

  return undef;
}



sub login_start_session {
  my $app     = shift;
  my $udata   = shift;
  my $login   = shift;

  my $request = $app -> request;
  my $query   = $request -> {CGI};

  my $udata_file = $app -> paths -> {'user-data'};

  ### create a session
  
  my $owner = $udata -> {owner};


  $login = lc $login;

  if ( lc $owner->{login} ne $login ) {
    $app -> errlog( 
       "[$login] login entered and userdata's owner don't match, userdata: $owner->{login}" );
    assert( 0, "a problem with your account" );
  }

  $owner -> {IP} = $ENV {'REMOTE_ADDR'};

  
  my $session = $app -> start_session( "user", $owner );

  my $sid = $session -> id;

  $app -> sevent ( -class => 'auth',
                  -action => 'success',
                   -descr => 'user entered',
                   -file  => $udata_file,
                   -login => $login,
                   -IP    => $owner->{IP},
               -humanname => $owner->{name},
                 );

  
  ### make a copy of userdata in session
  $session -> object_set( $udata, $udata_file );


  ### now do some compatibility checks for the userdata
  use ACIS::Web::Person;

  my $records = $udata -> {records};

  if ( not $records ) {
    $records = $udata ->{records} = [];
  }

  foreach ( @$records ) {
    if ( $_ ->{type} eq 'person' ) {
      ACIS::Web::Person::bring_up_to_date( $app, $_, $udata );
    }
  }


  put_sysprof_value( $login, 'last-login-date', date_now() );


  ###  compatibility userdata update 
  ###  XXX to be removed
  foreach ( qw( initial-registered-date last-change-date ) ) {

    if ( $owner -> {$_} 
         and $owner -> {$_} =~ /[a-zA-Z]+/
       ) {
      my $date = convert_date_to_ISO( $owner -> {$_} );
      $owner -> {$_} = $date;
    }
  }
  ###### udata lock was here

  my $auto_login = $app -> form_input ->{'auto-login'};
 
  if ( $auto_login eq "true" )  {
    my $pass = $app -> form_input ->{pass};

    $app -> set_auth_cookies( $login, $pass );
  } 

  ### redirect to the same screen, but with session id

  my $base_url = $app -> config( 'base-url' );
  my $screen   = $app -> {request} -> {screen};

  my $URI = "$base_url/$screen!$sid";  ### XXX URL structure, dependency

  $app -> userlog( "logged in", 
                   ($screen and $screen ne 'index') ? " to screen $screen" : '', 
                   ", session $sid",
                   ", IP ", $ENV{REMOTE_ADDR} );

  debug "requesting a redirect to $URI";
  
  $app -> clear_process_queue;
  $app -> redirect( $URI );
  
  return $udata;
}






sub load_session_if_possible {
  my $app = shift;  
  if ( $app -> request ->{'session-id'} ) {
    return $app -> load_session;
  }
  return undef;
}


sub load_session_or_authenticate {
  my $app = shift;
  
  if ( $app -> request ->{'session-id'} ) {
    $app -> load_session;
    
  } else {
    my $udata = $app -> authenticate;

    ###  XXX  failed login attempt
    if ( not $udata ) {
      ###  show something meaningful, explaining why it failed! 
    }
    return $udata;
  }

}




##########################################################
############### FORM PROCESSING STUFF ####################
##########################################################

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



sub path_to_val {
  my $data  = shift;
  my $path  = shift;
  
  my @path  = split '/', $path;
  foreach ( @path ) {
    
    if ( not $data 
         or not ref $data 
         or not ref $data eq 'HASH' ) {
      return undef;
    }

    $data = $data -> {$_};
  }

  return $data;
}



sub assign_path {
  my $data  = shift;
  my $path  = shift;
  my $value = shift;

  assert( $data );
  assert( $path );
#  assert( $value );

  my @path = split '/', $path;
  my $last = pop @path;
  foreach ( @path ) {
    unless (defined $data -> {$_}) {
      $data -> {$_} = {}; 
    }
    
    $data = $data -> {$_};
     
  }
  $data -> {$last} = $value;
}


sub prepare_form_data {

  my $self   = shift;
  
  my $screen        = $self -> request -> {screen};
  my $screen_config = $self -> get_screen( $screen );
  my $params        = $screen_config   -> {variables};

  foreach (@$params) {

    next unless defined $_ -> {place};
      
    my $data;
      
    my @places = split ',', $_ -> {place};
      
    foreach my $place ( @places ) {   ### XX multiple passes will overwrite previous values
      my ( $prefix, $place ) = split ':', $place;
      
      if ( $prefix eq 'owner' ) { 
        $data = $self -> session -> object -> {owner}; 
        
      } elsif( $prefix eq 'record' )  {
        $data = $self -> session -> current_record; 
        ### XXX Web::App::Session doesn't have this method

      } elsif( $prefix eq 'session' )  {
        $data = $self -> session;
      }
      
      $self -> set_form_value ( $_ -> {name}, path_to_val ($data, $place) );
    }
  }
}



sub check_input_parameters {
  my $self   = shift;
  
  my $required_absent;
  my $invalid_value;
  my $screen        = $self -> request -> {'screen'};
  my $screen_config = $self -> get_screen( $screen );
  my $params        = $screen_config -> {variables};

  my $vars       = $self -> variables;
  my $form_input = $self -> form_input;
  my $cgi        = $self -> {request} {CGI};
  
  debug "checking input parameters";
  debug "loading CGI::Untaint";

  my $form_input_copy = { %$form_input };
  
  my $handler;

  {
    my $include_path = ( $CGI::Untaint::VERSION < "1.23" ) 
        ? "ACIS/Web" 
        : "ACIS::Web";
    $handler = new CGI::Untaint ( {INCLUDE_PATH => $include_path}, 
                                  $form_input_copy );
  }
  my $errors;

  foreach ( @$params ) {
    my $type     = $_ -> {type};
    my $name     = $_ -> {name};
    my $maxlen   = $_ -> {maxlen};
    my $required = $_ -> {required};

    my $error;
    my $value;

    if ( defined $form_input -> {$name} ) {

      my $orig_val =  $form_input -> {$name};

      ### XXX $orig_val may be an ARRAY REF
      
      debug "parameter '$name' with value '$orig_val'";

      $orig_val =~ s/(^\s+|\s+$)//g;

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

        if ( $maxlen and 
             length( $value ) > $maxlen ) {
          debug "cutting the value at pos $maxlen";
          substr( $value, $maxlen ) = '...';
        }

      } else {
        
        if ( $required eq 'yes' ) {
          debug "required value at $name is empty";
          $self -> form_error ( 'required-absent', $name );
          $errors = 'yes';
        }
        $value = '';
      }

      $self -> set_form_value ( $name, $value );

    } else {

      if ( $required eq 'yes' ) {
        debug "required value at $name is absent";
        $self -> form_error ( 'required-absent', $name );
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
  
  foreach my $par ( @$params ) {

    my $name = $par -> {name};
     
    next if not defined $par -> {place};

    next if not exists $input->{$name} 
      and exists $par ->{'if-not-empty'};

    debug "process parameter name = '" . $name . "', value = '" . 
      $input -> {$name} . "'";
     
    debug "store to " . $par -> {place};
      
    my $data;
      
    my @places = split ',', $par -> {place};
      
    foreach my $to ( @places ) {
      my ( $prefix, $place ) = split ':', $to;

      if ( $prefix eq 'owner' ) {
        $data = $self -> session -> object -> {owner}; 
      
      } elsif ( $prefix eq 'record' ) { 
        $data = $self -> session -> current_record; ### XX ACIS-specific

      } elsif ( $prefix eq 'session' ) { 
        $data = $self -> session ; 

      } else { 
        die "error in screens configuration"; 
      } 

      my $val = $input -> {$name};

      assign_path ( $data, $place, $val );
    }  
  }
}



#############  end of main form processing subs  ###




sub forgotten_password {

  my $app = shift;

  my $request  = $app -> request;
  my $home     = $app -> {home};
  my $vars     = $app -> variables;

  debug 'get login';
  
  my $login  = lc $app -> get_form_value( 'login' ); 
 
  if ( not defined $login or not $login ) {
    $app -> form_required_absent ( 'login' );
    $app -> clear_process_queue;
    return undef;
  }

  
  my $udata_file  = $app -> userdata_file_for_login( $login );

  if ( not -f $udata_file ) {
    # no such user 
    $app -> error ( 'login-unknown-user' );
    $app -> clear_process_queue;
    return undef;
  }

  debug "going to load userdata to find the password";

  my $udata = load ACIS::Web::UserData ( $udata_file );
  
  my $owner = $udata -> {owner};
  
  $app -> {'presenter-data'} {request} {user} = {
    name  => $owner -> {name},
    login => $owner -> {login},
    type  => $owner -> {type},
    pass  => $owner -> {password},
  };
  
  $app -> send_mail ( 'email/forgotten-password.xsl' );
  $app -> success( 1 );  ### XXX email/forgotten-password.xsl should check this

  $app -> message( 'forgotten-password-email-sent' );

  $app -> set_form_value ( 'login', $owner->{login} );
  $app -> set_form_action( $app -> config( 'base-url' ) );

  $app -> clear_process_queue;
  $app -> set_presenter ( 'login' );
}




sub personal_static_url {
  my $app    = shift;
  my $reset  = shift;

  my $record = $app -> session ->current_record;

  my $profile_dir = $app -> config( "profile-pages-dir" );
  my $paths      = $app ->paths;
  my $static_url = $paths ->{static};

  debug "profile-pages-dir: $profile_dir";
  
  my $url;

  if ( not $reset
       and $url = $record -> {settings} {static_url} ) {
    
    if ( index( $url, $static_url ) == -1 ) {
      $app -> errlog( "user static url is out of global static url: $url" );
    }

    return $url;
  }

  my $sid = $record -> {sid};

  if ( not $sid ) {
    $app -> error( "short-id-required" );
    $app -> set_presenter( "sorry" );
    return undef;
  }

  if ( $app -> config( "compact-redirected-profile-urls" ) ) {
    debug "use compact-redirected-profile-urls";
    $url = $static_url . "/$profile_dir$sid/";

  } else {
    debug "no compact-redirected-profile-urls";

    my @parts = split( '', $sid );
    my $iddir = join '/', @parts;

    $url = $static_url . "/$profile_dir$iddir/";
  }

  $record -> {settings} {static_url} = $url;
}



sub personal_static_file {
  my $app   = shift;
  my $reset = shift;

  my $record     = $app -> session ->current_record;
  my $paths      = $app -> paths;
  my $static_dir = $paths ->{shared};

  my $profile_dir = $app -> config( "profile-pages-dir" );

  if ( not $reset 
       and $record -> {settings} {static_file} ) {
    my $file = $record -> {settings} {static_file};
    
    ### sanity check
    if ( index( $file, $static_dir ) == -1 ) {  
      $app -> errlog( "user static file is out of global static dir: $file" );
    }

    return $file;
  }

  my $sid = $record -> {sid};

  if ( not $sid ) {
    $app -> error( "short-id-required" );
    $app -> set_presenter( "sorry" );
    return undef;
  }

  my $file;

#  my @parts = unpack( 'aaaaaaa*', $sid );
  my @parts = split( '', $sid );
  my $iddir = join '/', @parts;

  $file = $static_dir . "/$profile_dir$iddir";
  
  force_dir ( $static_dir, "$profile_dir$iddir" );  ### create sub tree

  $record -> {settings} {static_dir}  = $file;

  $file = "$file/index";

  $record -> {settings} {static_file} = $file;
}



1;