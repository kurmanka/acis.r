package ACIS::Web::PasswordReset;

use strict;

use Carp::Assert;
use Web::App::Common qw( debug );
use ACIS::Web::UserPassword;

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

  debug "going to load userdata to check the account";

  my $udata = load ACIS::Web::UserData( $udata_file );
  
  my $owner = $udata -> {owner};

  if ( not $owner 
       or not $owner ->{login} ) {
    $app -> error ( 'login-account-damaged' );
    $app -> clear_process_queue;
    return undef;
  }
  
  $app -> {'presenter-data'} {request} {user} = {
    name  => $owner -> {name},
    login => $owner -> {login},
    type  => $owner -> {type},
  };

  my $token_string = ACIS::Web::UserPassword::create_password_reset( $app, $owner->{login} );
  $vars->{token_string} = $token_string;
  
  $app -> send_mail ( 'email/forgotten-password.xsl' );
  $app -> success( 1 );  ### XXX email/forgotten-password.xsl should check this

  $app -> set_username($login);
  $app -> userlog( "requested a password reset link" );

  $app -> message( 'forgotten-password-email-sent' );
  $app -> set_form_value ( 'login', $login );
  $app -> set_form_action( $app -> config( 'base-url' ) );
  $app -> clear_process_queue;
  $app -> set_presenter ( 'login' );
}

sub password_reset {
  my $app = shift;
  my $request  = $app -> request;
  my $home     = $app -> {home};
  my $vars     = $app -> variables;

  debug "reset request";
  #use Data::Dumper;
  #debug Data::Dumper::Dumper($request);
 
  my $token = $request-> {subscreen};
  debug "token: $token";

  my $login = ACIS::Web::UserPassword::check_password_reset_token( $app, $token );
  if ($login == -1) {
    debug "expired token";
    $app->error('reset-token-expired');
    return;

  } elsif ($login == -2) {
    debug "already used token";
    $app->error('reset-token-reused');
    return;
  
  } elsif (not defined $login) {
    debug "bad token";
    $app->error('reset-token-bad');
    return;   
  }

  # valid token:  
  debug "login: $login";
  $vars->{login} = $login;
  $app->success(1);
  
  # see the next function below 
  # to see what happens next.
}


sub password_reset_process {
  my $app = shift;
  my $input = $app -> form_input;
  my $home  = $app -> {home};
  my $vars  = $app -> variables;

  debug "reset password";

  my $login = $vars->{login} || die;

  my $pass1 = $input->{'pass'};
  my $pass2 = $input->{'pass-confirm'};

  if ($pass1 and $pass2 and $pass1 ne $pass2) {
    $app->error( 'password-confirmation-mismatch' );
    return;
  }
  if (not $pass1) { return; }

  # different page template
  $app->set_presenter('reset-done');
  
  # grab the userdata
  my $status = $app->attempt_userdata_access( $login );
  if (not ref $status) {
    debug "status: $status";
  }
  
  my $ok;
  # login
  if ( $status eq 'no-account' ) {
    #$app -> error ( 'no-account' );
  } elsif ( $status eq 'account-damaged' )  {
    # XXX
  } elsif ( $status eq 'existing-session-loaded' ) {
    # very strange, but could work
    $ok = 1;
  } elsif ( $status =~ /^account-locked:([^:]+):(.+)/ ) {
    # may happen; need to try again later
  } elsif ( ref $status ) {

    my $udata = $status;
    $app->update_paths_for_login( $login );
    my $udata_file = $app -> paths -> {'user-data'};
    my $session = $app -> start_session( "user", 
                                          {login => $login}, # session owner
                                          object => $udata, 
                                          file   => $udata_file );
    debug "created a new session";
    $ok = 1;
  }

  if ($ok) {
    $app->success(1);
    $app->set_new_password( $pass1 );
    $app->logoff_session();
    undef $app->{'presenter-data'}{request}{session}{id};

    $app->set_username($login);
    $app->userlog( "has set new password via reset link" );
    
    # mark the token as used
    my $token = $app->request->{subscreen};
    ACIS::Web::UserPassword::password_reset_token_used( $app, $token );
  }
}




1;
