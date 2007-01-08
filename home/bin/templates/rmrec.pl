
use strict;

use sql_helper;
use ACIS::Web;

my $login = shift @ARGV;
my $rec   = shift @ARGV;

if ( not $login or scalar @ARGV ) {
  die "Usage: $0 user\@login [record]\n\nwhere record may be a short-id or a full id\n";
}

my $acis = ACIS::Web -> new( home => $homedir );

use ACIS::Web::Admin;

###  get hands on the userdata (if possible),
###  create a session and then do the work

my $res= ACIS::Web::Admin::offline_userdata_service( $acis, $login, 'ACIS::rmrec::delete_record', $rec, $rec );


package ACIS::rmrec;

use strict;
use Web::App::Common;

sub delete_record {
  my $acis = shift;
  my $onerec = shift;

  my $session = $acis->session;
  my $crec = $session->current_record;

  my $paths = $acis ->paths;
  my $udata = $session ->object;
  my $records = $udata->{records};
  my $sql = $acis->sql_object();

  if ( scalar @$records >1 and not $onerec ) {
    die "there's more than one record here, and you didn't specify which one should I delete";
  }

  my @deleted;

  # delete the profile
  foreach ( @$records ) {
    my $id  = $_->{id};
    my $sid = $_->{sid} || '';
    if ( $onerec and $_ != $crec ) { next; }
    
    push @deleted, $_;
    undef $_;

    # log
    $acis -> userlog( "removing the record $id/$sid, per admin's request ($0)" );
    $acis -> sevent ( -class  => 'account', 
                      -action => 'delete record',
                      -id => $id,
                      -sid => $sid );

  }
  clear_undefined $records;

  ### delete the profile pages and exported metadata files
  foreach ( @deleted ) {
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

  return 1;
}



# not finished:
sub delete_account {
  my $acis = shift;
  my $session = $acis->session;
  my $rec  = $session->current_record;

  my $paths = $acis ->paths;
  my $udata = $session ->object;

#  ......
  my $userdata = $paths -> {'user-data'};
  my $deleted_userdata = $paths -> {'user-data-deleted'};
  
  $session -> object_set( undef );

  $acis -> send_mail( 'email/account-deleted.xsl' );

  $acis -> sevent ( -class  => 'account', 
                   -action => 'deleted',
                   -file   => $deleted_userdata );
    
  $acis -> userlog( "deleted account; backup stored in $deleted_userdata" );
    
  debug "close the session";

  $acis -> logoff_session;
  
  $acis -> message( 'account-deleted' );
  $acis -> success( 1 );
  $acis -> set_presenter( "account-deleted" );


  ###  request RI update
  require RePEc::Index::UpdateClient;
  my $udatadir = $acis -> userdata_dir;
  my $relative = substr( $userdata, length( "$udatadir/" ) );
  $acis -> log( "requesting RI update for $relative" );
  RePEc::Index::UpdateClient::send_update_request( 'ACIS', $relative );
  
}



1;
