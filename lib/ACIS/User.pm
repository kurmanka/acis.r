package ACIS::User;

use strict;

use Web::App::Common;
use ACIS::Web::UserPassword;

sub cleanup_removed_profile {
  my $acis = shift ;
  my $record = shift;
  
  ## find if there is a user. if there is no user, 
  ## don't write anything to the userlog
  my $user = $acis->username();
  if (not $user) { $acis->set_username("ACIS::User/$0"); }

  for ($record) {
    my $file = $_ -> {profile} {file};
    if ( $file and -f $file ) {
      unlink( $file ) or warn "can't delete $file";
      $acis-> userlog( "removed profile file at $file" );
    }
    
    my $exp = $_ -> {profile} {export};
    if ( $exp and ref $exp ) {
      foreach ( values %$exp ) {
        unlink( $_ ) or warn "can't delete $_";
        $acis-> userlog( "removed exported profile data: $_" );
      }
    }

    my $id  = $_->{id};
    my $sid = $_->{sid} || '';
    eval {
      $sql -> do( "delete from sysprof where id=?", undef, $sid ) if $sid;
      $sql -> do( "delete from sysprof where id=?", undef, $id );
      $sql -> do( "delete from suggestions where psid=?", undef, $sid ) if $sid;
      $sql -> do( "delete from cit_old_sug where psid=?", undef, $sid ) if $sid;
      $sql -> do( "delete from apu_queue where what=?", undef, $sid ) if $sid;
    }    
  }

}


sub delete_current_account {
  my $acis = shift;
  
  my $mode = shift || die; # must be either 'user' or 'admin'
  
  my $session = $acis->session;
  my $crec = $session->current_record;

  my $paths = $acis   ->paths;
  my $udata = $session->object;
  my $owner = $session->userdata_owner;
  my $records = $udata->{records};
  my $sql = $acis->sql_object();


  # log removal in userlog 
  $acis -> userlog( "removing the account, per $mode request" );

  # create event: account delete request
  $acis -> sevent( -class  => 'account', 
                   -action => 'delete request'
                   -mode   => $mode );

  # create userdata backup in deleted-userdata/ folder
  my $userdata = $paths -> {'user-data'};
  my $deleted_userdata = $paths -> {'user-data-deleted'};
  
  while ( -e $deleted_userdata ) {
    debug "backup file $deleted_userdata already exists";
    $deleted_userdata =~ s/\.xml(\.(\d+))?$/".xml." . ($2 ? ($2+1) : '1')/eg;
  }

  ACIS::Web::UserPassword::remove_password( $acis, $owner );
  $session -> set_userdata_saveto_file( $deleted_userdata );

  # delete the userdata
  my $check = unlink $userdata;
  if ( not $check ) {
    $acis -> errlog ( "Can't remove $userdata" );
    $acis -> error ( "cant-remove-account" );
    return;
  }

  # create event: account deleted
  $acis -> sevent ( -class  => 'account', 
                    -action => 'deleted',
                    -file   => $deleted_userdata );


  ### for each record, delete:
  ###  - the profile pages,
  ###  - exported metadata files, and
  ###  - the table records
  foreach ( @$records ) {
    cleanup_removed_profile($acis, $_);
  }

  # anything else to clean-up? XXX
  #  - sysprof by login?


  # close the session
  debug "close the session";
  $acis -> logoff_session;
  $acis -> userlog( "deleted account; backup in $deleted_userdata" );

  if ($mode eq 'user') {
    $acis -> send_mail( 'email/account-deleted.xsl' );    
  }

  # send update request to the Update Daemon
  my $udatadir = $acis -> userdata_dir;
  my $relative = substr( $userdata, length( "$udatadir/" ) );
  $acis -> send_update_request( 'ACIS', $relative );

  return 1;
}




sub remove_account {   
  my $acis   = shift;
  my $par    = { @_ };

  my $login  = $par -> {-login} || die;
  my $notify = $par -> {-notify};

  my $paths   = $acis -> make_paths_for_login( $login );
  my $file    = $paths -> {'user-data'};
  my $bakfile = $paths -> {'user-data-deleted'};

  # get the bakfile name  
  while ( -e $bakfile ) {
    debug "backup file $bakfile already exists";
    $bakfile =~ s/\.xml(\.(\d+))?$/".xml." . ($2+1)/eg;
  }

  debug "move '$file' to '$bakfile'";
  my $check = rename $file, $bakfile;  
  
  if ( not $check ) {
    debug "failed";
    $acis -> errlog ( "Can't move $file file to $bakfile" );
    $acis -> error ( "cant-remove-account" );
    return 0;
  }

  # create event: account deleted
  $acis -> sevent( -class  => 'account', 
                   -action => 'deleted',
                   -login  => $login,
                   -backup => $bakfile,
                 );

  $acis -> userlog( "removed $login account" );

  # delete the profile pages, etc.
  debug "clean-up the remaining files and records";
  
  require ACIS::Web::UserData;
  my $udata = ACIS::Web::UserData -> load( $bakfile );
  
  foreach ( @{ $udata-> {records} } ) {
    cleanup_removed_profile($acis, $_);
  }


  # send update request to the Update Daemon
  my $udatadir = $acis -> userdata_dir;
  my $relative = substr( $file, length( "$udatadir/" ) );
  $acis -> send_update_request( 'ACIS', $relative );


  if ( $notify ) {
    # XXX
    # $acis -> send_mail( 'email/account-deleted.xsl' );
    debug "clean-up after deletion";
  }
  
  return 1; # success
}




1;
