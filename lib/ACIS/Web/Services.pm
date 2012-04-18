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

# cardiff

use strict;

use Carp;
use Carp::Assert;
use Data::Dumper;
use CGI::Untaint;

# inserted to avoid problems when running the module on its own.
use ACIS::Web;           
use Web::App::Common    qw( date_now debug convert_date_to_ISO );
use ACIS::Data::DumpXML qw( dump_xml );

use Encode qw/encode decode/;

use ACIS::Web::SysProfile;


####   SESSION STUFF   ####

sub start_session {
  my $self  = shift;
  my $type  = shift;
  
  assert( ref $self );
  assert( not $self -> session );
  
  my $sid;
  my $class = $SESSION_CLASS{$type};
  if ( not $class ) { 
    $self -> errlog( "Session class for session type '$type' is undefined" );
    die "Session class for session type '$type' is undefined";
  }
  
  my $session  = $class -> new( $self, @_ );
  if ( not $session ) {
    complain "can't create session of $class";
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
  my $session = $SESSION_CLASS_MAIN -> load( $app, $sfilename );

  use Scalar::Util qw( blessed );
  use Data::Dumper;

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
      debug "can't load the session, session loading failed: ". Dumper($session);
      return undef;
    }
  }

  assert( ref $session );
  assert( blessed($session) );
  assert( $session -> isa( 'Web::App::Session' ) );
  assert( $session -> owner );

  my $sIP = $session -> owner ->{IP};
  if ( not $session -> owner ) {
    debug "session owner is undefined, so it is invalid";
    return undef;
  }

  if ( $sIP eq $IP ) {
    debug "previous session found, IP matches, continuing";
    
  } else {
    # IPs don't match -- should not continue
    debug "the user IP addresses don't match";

    ###  may be it is better to check the session validity by checking
    ###  the user-agent string?  Probably it will be more comfortable
    ###  for the users, although -- less secure.  In some big
    ###  organizations both IP addresses and the user agent strings
    ###  may in fact be the same with high probability.

    my $pass = $app -> request_input( "pass" );
    if ( $pass ) {
      if ( equal_passwords( $pass, $session -> owner ->{password} ) ) {
        ###  Override ip address
        debug "but a valid password were given";
        $session -> owner ->{IP} = $IP;
      
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

  ### respect request parameter "short-id"
  if ( my $sid = $request -> {'short-id'} ) {
      debug "request -> sid:$sid";
      if ( $session -> choose_record_by_id( $sid ) ) {

      } else {
          $app  -> error( "bad-short-id-in-request" );
      } 
  } else {
      # SOS for some poor users, for whom contributions fail because
      # they have no current record
      my $reclist = $session -> userdata_record_list;
      if ( not $session->current_record 
	   and scalar @$reclist == 1 ) {
	  $session -> set_current_record_no( 0 );
      }
  }

  return $session;
}


sub logoff_session {
  my $self = shift;
  my $session = $self -> session;
  # cardiff: prepare for sorting call 
  my $presenter=$self->{'presenter-data'};
  my $psid=$self->{'presenter-data'}->{'request'}->{'session'}->{'current-record'}->{'shortid'};
  my $bindir=$self->{'config'}->{'homebin'};
  # cardiff

  $session -> close( $self );

  $self -> clear_session_cookie;  
  if ( $self->request ) { 
    undef $self -> request -> {'session-id'}; 
  }

  # cardiff: call the command to sort refused
  if( $self -> config( "learn-via-daemon" ) 
      and $presenter->{'response'}->{'success'} ) {
    my $executable="$bindir/learn_known_items";
    debug "I have to learn the refused documents: $executable";
    if(-e $executable) {
      my $s="$executable $psid &";
      debug "running $s";
      system($s);      
    }
  }
  else {
      debug "not presorting the refused because there was no change";
  }
  # end of call of the command to sort refused
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
                       -expires => '+0m',
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
  $login = lc $login; # lower-case it
  my $pass  = shift;
  my $override = shift; # ?


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
      debug "but session can't be loaded ($file)";
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


  my $udata = load ACIS::Web::UserData( $udata_file );

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

  $login  = $form_input -> {login};
  $passwd = $form_input -> {pass};

#  my $cookies = $app -> request -> {cookies};

  if ( not $login ) {
    $login = $app -> get_cookie ( 'login' );
  }

  if ( not $passwd ) {
    $passwd = $app -> get_cookie( 'pass' );
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
                    -descr => "userdata damaged",
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
    my $ret = login_start_session( $app, $udata, $login );

    # this is for single-profile accounts, that are opening
    # direct links, e.g. http://authors.repec.org/research/autosuggest
    # we need to choose some record at that moment
    $app -> session -> set_default_current_record;
    return $ret;
  }
  # else ?
  return undef;
}



sub login_start_session {
  my $app     = shift;
  my $udata   = shift;
  my $login   = shift;
  $login = lc $login;

  my $request = $app -> request;
  my $udata_file = $app -> paths -> {'user-data'};

  ### create a session
  my $owner = $udata -> {owner};
  if ( lc $owner->{login} ne $login ) {
    $app -> errlog( 
       "[$login] login entered and userdata's owner don't match, userdata: $owner->{login}" );

    $app -> error( 'login-account-damaged', { 
                       -class => 'authenticate',
                       -descr => "login entered and userdata's owner don't match",
                       -login => $login,
                       -expected => $owner->{login},
                     } );
    return undef;
  }
  $owner -> {IP} = $ENV{'REMOTE_ADDR'};

  # XXX
  my $session = $app -> start_session( "user", $owner,
                                       object => $udata, 
                                       file   => $udata_file );

  my $sid = $session -> id;
  assert( $sid );
  $app -> sevent(  -class => 'auth',
                  -action => 'success',
                   -descr => 'user entered',
                   -file  => $udata_file,
                   -login => $login,
                   -IP    => $owner->{IP},
               -humanname => $owner->{name},
                 );
   
  put_sysprof_value( $login, 'last-login-date', date_now() );

  my $auto_login = $app -> form_input ->{'auto-login'} || '';
  if ( $auto_login eq "true" )  {
    my $pass = $app -> form_input ->{pass};
    $app -> set_auth_cookies( $login, $pass );
  } 

  ### redirect to the same screen, but with session id
  my $base_url = $app -> config( 'base-url' );
  my $screen   = $app -> {request} -> {screen} || '';
  my $URI = "$base_url/$screen!$sid";  ### ZZZ application URL structure dependency

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
  my $element = shift || croak;
  my $value   = shift;

  $self -> {'presenter-data'} {response} 
    {form} {values} {$element} = 
      ( defined $value ) ? $value : undef;

  debug "set form value $element: ", (defined $value)? $value : '*undef*';
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
        $data = $self -> session -> userdata_owner; 
        
      } elsif( $prefix eq 'record' )  {
        $data = $self -> session -> current_record; 
        ### XXX Web::App::Session doesn't have this method

      } elsif( $prefix eq 'session' )  {
        $data = $self -> session;
      }

      my $val = path_to_val ($data, $place);
      $self -> set_form_value ( $_ -> {name}, $val );
    }
  }
}



sub check_input_parameters {
  my $self   = shift;

  my $required_absent;
  my $invalid_value;
  my $screen        = $self -> request -> {screen} || die 'no screen in request';
  my $screen_config = $self -> get_screen( $screen ) || die "no such screen: $screen";
  my $params        = $screen_config -> {variables} || warn "Screen $screen: no {variables} defined";

  my $vars       = $self -> variables;
  my $form_input = $self -> form_input;
  my $cgi        = $self -> {request} {CGI};
  
  debug "checking input parameters";
  debug "loading CGI::Untaint";

  my $form_input_copy = { %$form_input };
  
  my $handler;

  eval {
    my $include_path = ( $CGI::Untaint::VERSION < "1.23" )
        ? "ACIS/Web" 
        : "ACIS::Web::CGI::Untaint";
    debug "INCLUDE_PATH is $include_path";
    $handler = new CGI::Untaint ( {INCLUDE_PATH => $include_path},
                                  $form_input_copy );
  };
  if ( $@ ) {
    debug "can't create CGI::Untaint handler";
    die   "can't create CGI::Untaint handler: $@";
  }

  my $errors;

  debug "screen has " . (scalar @$params) . " param(s) defined"; 

  foreach ( @$params ) {
    my $type     = $_ -> {type};
    my $name     = $_ -> {name};
    my $maxlen   = $_ -> {maxlen};
    my $required = $_ -> {required} || 0;

    my $error;
    my $value;

    if ( defined $form_input -> {$name} ) {

      my $orig_val = $form_input -> {$name};

      ### $orig_val may be an ARRAY REF
      if ( $orig_val and ref( $orig_val ) ) {
        debug "multiple values for parameter '$name'... using the first one.";
        $orig_val = $orig_val ->[0] || '';
      }

      ### make sure it is 
      assert( not ref( $orig_val ) );
      
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

    my $name  = $par -> {name};
    my $place = $par -> {place};

    next if not defined $place;

    next if not exists $input->{$name} 
      and exists $par ->{'if-not-empty'};

    my $val = $input -> {$name};
    if ( not defined $val ) { $val = ''; }

    debug "process parameter '$name', value '$val'";
    debug "store to $place";
      
    my $data;
    my @places = split ',', $place;
      
    foreach my $to ( @places ) {
      my ( $prefix, $place ) = split ':', $to;

      if ( $prefix eq 'owner' ) {
        $data = $self -> session -> userdata_owner; 
      
      } elsif ( $prefix eq 'record' ) { 
        $data = $self -> session -> current_record; ### XX ACIS-specific

      } elsif ( $prefix eq 'session' ) { 
        $data = $self -> session ; 

      } else { 
        die "error in screens configuration"; 
      } 

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

  if ( not $owner 
       or not $owner ->{login}
       or not $owner ->{password} ) {
    $app -> error ( 'login-account-damaged' );
    $app -> clear_process_queue;
    return undef;
  }
  assert( $owner );
  
  $app -> {'presenter-data'} {request} {user} = {
    name  => $owner -> {name},
    login => $owner -> {login},
    type  => $owner -> {type},
    pass  => $owner -> {password},
  };
  
  $app -> send_mail ( 'email/forgotten-password.xsl' );
  $app -> success( 1 );  ### XXX email/forgotten-password.xsl should check this

  $app -> message( 'forgotten-password-email-sent' );

  $app -> set_form_value ( 'login', $login );
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
