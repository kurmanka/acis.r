package ACIS::Web::Background;

###  a package of tools to run and control background threads, which
###  are capable of useful background work for the user.



###  XXX Add clearing of old lost threads:
###  SQL: delete from threads where started < ( NOW() - INTERVAL 1 HOUR )


use strict;
use Exporter;

use Proc::Daemon;

use Web::App::Common;



use vars qw( $TABLE @EXPORT_OK $APP );

use base qw( Exporter );

@EXPORT_OK = qw( &logit );

$TABLE = "threads";

*APP = *Web::App::APP;

my $logfile;
sub logit {
  if ( not $logfile ) { 
    $logfile = $APP -> home . "/back.log";
  }

  if ( $logfile ) {
    open LOG, ">>:utf8", $logfile;
    print LOG scalar localtime(), " [$$] ", @_, "\n";
    close LOG;
  } 
}
  


sub run_thread;
sub check_thread;

sub check_thread {
  my $app = shift;
  my $sql = $app -> sql_object;

  my $psid   = shift;
  my $typeid = shift;

  my $query  = "select psid,type,started,checkpoint from $TABLE where psid = ?" . 
     ( (defined $typeid) ? " and type=?":'' );

  debug "q: " . $query;
  $sql -> prepare_cached ( $query );

  my $res;
  
  if ( $typeid ) {
    $res = $sql -> execute( $psid, $typeid );
  } else {
    $res = $sql -> execute( $psid );
  }

  if ( $sql->error ) {
    $app -> errlog ( "sql error: " . $sql->error );
  }

  if ( $res and not $sql->error ) {
    if ( $typeid ) {
      
      my $row = $res ->{row};
      $res -> finish;
      return $row;

    } else {

#      debug "will build a list of threads";
      my @res = ();
      while ( $res->{row} ) {
        my $row = $res->{row};
        push @res, $row;
        $res -> next;
#        debug "a thread: $row->{type}";
      }
      $res -> finish;
#      debug "finish";
      return \@res;
    }
  }
  debug "q: no good results";

  if ( $res ) { $res -> finish; }
  return undef;
}




##############################################################################
###        r u n     t h r e a d  
##############################################################################

sub run_thread {
  my $app  = shift;
  my $psid = shift;
  my $type = shift;
  my $func = shift;

  debug "run_thread()";

  ###  this module's own log
  logit "run thread( psid: $psid, type: $type, func: $func )";

  my $check = check_thread ( $app, $psid, $type );

  if ( $check ) {
    debug "such a thread already exists";
    logit "already exists";
    return 0;
  }

  my $sql = $app -> sql_object;
  
  if ( $sql->error ) {
    debug "sql error";
    logit "lasting error: '" . $sql->error . "'";
    logit $sql -> {dbh} -> {Statement};
  }


  my $query = "insert into threads values ( ?, ?, NOW(), NULL )";
  $sql -> prepare( $query ) ;
  $sql -> execute( $psid, $type );
  if ( $sql->error ) {
    debug "Can't insert the thread record ($psid, $type)";
    logit "can't insert thread record '" . $sql->error . "'";
    return 0;
  }


  my $parent = $PPerlServer::child_pid || $PPerlServer::spid || $$;
  my $fork = fork ();

  if ( $fork == 0 ) {
    # the child 

    logit "forked from $parent to run $func";
    undef $sql;
    $app -> {sql_object} = undef;
    $sql = $app -> sql_object;

#    $sql_helper::VERBOSE_LOG = 1;   ### XXX debugging

    my $midpid = $$;

    ### detach
    Proc::Daemon::Init();

    logit "became daemon from $parent via $midpid";


    ### call the function

    eval { 
      no strict;
      &$func ( $app, $sql );
    };

    if ( $@ ) {
      logit "background thread $func failed ($@)";
    }
    
    ### clear up
    clear_thread_record ( $sql, $psid, $type );

    ### exit
    logit "finished";
    exit 1;
    
  } elsif ( defined $fork )  {
    # the parent
    
    # wait till the child goes daemon
    wait;
    return 1;

  } else {

    clear_thread_record ( $sql, $psid, $type );
    return 0;
  }

}


sub clear_thread_record {
  my $sql = shift;
  my $psid = shift;
  my $type = shift;

  $sql -> prepare( "delete from $TABLE where psid=? and type=?");
  $sql -> execute( $psid, $type );
  
  if ( $sql->error ) {
    debug "error while deleting thread record $psid, $type";
    return undef;
  } 

  return 1;
}



################   tests   ##################


sub call_back_test {
  my $app = shift;

  my $session = $app -> session;
  my $record  = $session -> current_record;

  my $sid = $record -> {sid};
  
  if ( not $sid ) {
    $app -> error ( 'no-short-id' );
    return;
  }

  my $r = run_thread( $app, $sid, "test", "ACIS::Web::Background::test" );

  if ( $r ) {
    $app -> success( 1 );
  }

}


sub test {

  my $app = shift;

  my $sql = shift;

  my $record = $app -> session -> current_record; 

  $sql -> do ( "drop table thread_test" );
  $sql -> do ( "create table thread_test ( number int, user char(100) )" );

  my $user = $app -> session -> owner -> {login};

  $sql -> prepare ( "insert into thread_test values ( 1, ? )" );
  $sql -> execute ( $user );

  for ( 1 .. 40 ) {
    $sql -> prepare ( "update thread_test set number = ? where user = ?" );
    $sql -> execute ( $_, $user );
    sleep 6;
  }
  
  $sql -> prepare ( "update thread_test set number = 0 where user = ?" );
  $sql -> execute ( $user );

}

1;
