package ACIS::APU;

=head1 NAME

ACIS::APU -- Automatic Profile Update

=cut

use strict;
use warnings;
use Exporter;
use Carp;
use Carp::Assert;
use Web::App::Common qw( debug );
use sql_helper;
## fixme: strange sequence of declarations
use vars qw( $ACIS @EXPORT_OK @EXPORT);
*ACIS = *ACIS::Web::ACIS;
@EXPORT = qw( logit set_queue_item_status push_item_to_queue );
use base qw( Exporter );

use ACIS::APU::Queue;


## evcino
my $interactive;
my $logfile;
## counts errors for premature termination
my $error_count = 0;


sub logit (@) {
  if ( not $logfile and $ACIS ) {
    $logfile = $ACIS -> home . "/opt/log/autoprofileupdate.log";
  }
  if ( $logfile ) {
    open LOG, ">>:utf8", $logfile;
    print LOG scalar localtime(), " [$$] ", @_, "\n";
    close LOG;
  }
  else {
    warn "can't logit: @_";
  } 
  if ( $interactive ) {
    print @_, "\n";
  }
}


sub error {
  my $message = shift;
  logit "ERR: $message";
  if ( $error_count > 15 ) {
    die "more than 15 errors, I die.";
  }
  $error_count ++;
}

## resolve long id & short id into email address of the owner
sub get_login_from_queue_item {
  my $sql = shift;
  my $item = shift;
  my $login;
 
  if ( length( $item ) > 8 
       and $item =~ /^.+\@.+\.\w+$/ ) {
    $sql -> prepare( "select owner from records where owner=?" );
    my $r = $sql -> execute( lc $item );
    if ( $r and $r -> {row} ) {
      $login = $r ->{row} {owner};      
    } 
    else {
      logit "get_login_from_queue_item: email $item not found";
    }    
  } 
  else {
    if ( length( $item ) > 15
         or index( $item, ":" ) > -1 ) {
      $sql -> prepare( "select owner from records where id=?" );
      my $r = $sql -> execute( lc $item );
      if ( $r and $r -> {row} ) {
        $login = $r ->{row} {owner};
      } 
      else {
        logit "get_login_from_queue_item: id $item not found";
      }
    } 
    elsif ( $item =~ m/^p[a-z]+\d+$/ 
            and length( $item ) < 15 ) {
      $sql -> prepare( "select owner,id from records where shortid=?" );
      my $r = $sql -> execute( $item );
      if ( $r and $r -> {row} ) {
        $login = $r ->{row} {owner};        
      } 
      else {
        logit "get_login_from_queue_item: sid $item not found";
      }
    }
  }
  return $login;
}


sub run_apu_by_queue {
  my $chunk = shift || 3;
  my %para  = @_;
  my $auto_restart_queue = $para{-auto}   || 0;
  ## defaults to 1 in the apu binary
  my $failed_ones        = $para{-failed} || 0;
  $interactive           = $para{-interactive};
  ## allows to implement only one type of search (research/citations)
  my $only_do           = $para{-only_do} || ''; 
  ## | add mail_user parameter, mail the user?
  my $mail_user          = $para{-mail_user} || 0;
  ## |
  
  $ACIS || die;
  my $sql = $ACIS->sql_object || die;

  ## how many still to do
  my $number = $chunk;
  ## fixme: this explanation of failed_ones is inconsistent 
  ## with what's written in the binary
  if ( $failed_ones ) {
    logit "would only take previously failed queue items";
  }
  while ( $number ) {
    my ($qitem, $class) = get_next_queued_item( $sql );
    if ( $failed_ones ) {
      ($qitem, $class) = get_next_failed_queued_item( $sql );
    }
    if ( not $qitem ) {
      logit "no more items in the queue";
      if ( $auto_restart_queue ) {
        logit "reinitialize the queue";
        clear_the_queue_table( $sql );
        fill_the_queue_table( $sql );
        $auto_restart_queue = 0;
        next;
      } 
      else {
        logit "quitting";
        last; 
      }
    }
    my $login = get_login_from_queue_item( $sql, $qitem );
    if ( not $login ) {
      set_item_processing_result( $sql, $qitem, 'FAIL', 'not found' );
      next;
    }
    my $rid   = $qitem; # this we assume
    if ( $rid ne $login ) { 
      logit "about to process: $rid ($login)";
    } 
    else {
      logit "about to process: $login";
    }
    
    require ACIS::Web::Admin;
    my $res;
    my $error;
    eval {
      ##  get hands on the userdata (if possible),
      ##  create a session and then do the work      
      ##  XXX $qitem is not always a record identifier, but
      ##  offline_userdata_service expects an indentifier if anything on
      ##  4th parameter position
      ## evcino: the remaining parameters are passed to the function in the 3rd place, add mail_user
      $res = ACIS::Web::Admin::offline_userdata_service( $ACIS, $login, 'ACIS::APU::record_apu', $rid, $class, $mail_user, $only_do) || 'FAIL';
      ## 
    };
    if ($@) { 
      $error = $@; 
      $res   = "FAIL"; 
    }    
    logit "apu for $login/$rid result: $res";
    if ( $error ) {
      logit "error from offline_userdata_service: '$error'";
    }    
    set_item_processing_result( $sql, $rid, $res, $error );
    if ( $res ne 'SKIP' ) { 
      $number--; 
    }    
  }
}

## fixme: this should not be down here
use ACIS::Web::SysProfile;
require ACIS::APU::RP;
require ACIS::Citations::AutoUpdate;
sub record_apu {
  my $acis = shift;

  my $session = $acis -> session;
  my $vars    = $acis -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};
  my $sql     = $acis -> sql_object;

  my $class    = shift;
  ## evcino here comes the mail_user
  my $mail_user = shift;
  
  ## only_do takes a value 'citations' or 'research'.
  my $only_do = shift;

  ## don't do it because user has disabled APU
  if ( $record -> {'pref'} ->{'disable-apu'} ) { 
    logit "user has disabled APU";
    return "SKIP"; 
  }

  my $now = time;
  my $last_research  = get_sysprof_value( $sid, 'last-autosearch-time' )     || '';
  my $last_citations = get_sysprof_value( $sid, 'last-auto-citations-time' ) || '';
  my $last_apu       = get_sysprof_value( $sid, 'last-apu-time' )            || '';

  my $apu_too_recent_days  = $ACIS->config( 'minimum-apu-period-days' ) || 21;
  my $apu_too_recent_seconds = $apu_too_recent_days * 24 * 60 * 60;

  logit "record_apu() -- start ", scalar localtime;
  logit "minimum-apu-period-days: $apu_too_recent_days";
  logit "last apu: $last_apu";
  logit "last research: $last_research";
  logit "last citations: $last_citations";

  ### test with jo
  #if(not ($sid eq 'pda1' or $sid eq 'pkr1')) {
  #  logit "this is not jo or tok";
  #  exit;
  #  return "SKIP";
  #}
  ###
  
  ## check it was done recently
  if ( $last_apu 
       ## evcino adds mail_user
       and $mail_user
       ## |
       and $now - $last_apu < $apu_too_recent_seconds 
       ## for testing
       #and $sid ne 'pda1'
       ##
       #and $sid ne 'pkr1'
       ##
       and not $class ) {
    logit "apu for $id was done recently!";
    return "SKIP";
  }
  
  ## booleans to say that something has been done. 
  my $research;
  my $citations;  
  ## research
  if ( (not $only_do or $only_do eq 'research') and 
       (
        not $last_research
        ## do it if we don't mail
        or not $mail_user
        or ($now - $last_research >= $apu_too_recent_seconds/2)  
        or $class
       )
     ) {
    $research = 1;
    ## | puts mail_user as the second parameter, removed $pretend    
    logit("calling the RP search, mail_user is '$mail_user'");
    ACIS::APU::RP::search( $acis, $mail_user);    
  }
  ### jo case
  elsif($sid eq 'pda1') {
    $research=1;
    logit("calling the RP search, mail_user is '$mail_user'");
    ACIS::APU::RP::search( $acis, $mail_user);
  }
  else {
    logit "skipping research for $id";
  }

  ## citations 
  if ( (not $only_do or $only_do eq 'citations') and 
       (
        not $last_citations
        ## do it if we don't mail
        or not $mail_user
        or ($now - $last_citations >= $apu_too_recent_seconds/2)  
        or $class
       )
     ) {
    $citations = 1;
    ## fixme: next function not prepared for $mail_user, there was $pretend here
    ACIS::Citations::AutoUpdate::auto_processing( $acis, $mail_user );
  }
  if ( $citations or $research ) {
    put_sysprof_value( $sid, 'last-apu-time', $now );
  } 
  else {
    return "SKIP";
  }
  return "OK";
}



sub testme {
  $interactive = 1;

  use ACIS::Web;
  my $acis = ACIS::Web->new();

  die if not $ACIS;
  my @queue = get_the_queue( 5 );
}



1;
