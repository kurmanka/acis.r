package ACIS::APU;

=head1 NAME

ACIS::APU -- Automatic Profile Update

=cut

use strict;
use warnings;
use Carp;
use Carp::Assert;
use Web::App::Common qw( debug );
use sql_helper;


use vars qw( $ACIS );
*ACIS = *ACIS::Web::ACIS;

my $interactive;
my $logfile;

sub logit (@) {
  if ( not $logfile and $ACIS ) {
    $logfile = $ACIS -> home . "/autoprofileupdate.log";
  }

  if ( $logfile ) {
    open LOG, ">>:utf8", $logfile;
    print LOG scalar localtime(), " [$$] ", @_, "\n";
    close LOG;

  } else {
    warn "can't logit: @_";
  }

  if ( $interactive ) {
    print @_, "\n";
  }
}


# resolve long id & short id into email address of the owner

sub get_login_from_queue_item {
  my $ACIS = shift;
  my $item = shift;
  my $login;

  if ( length( $item ) > 8 
       and $item =~ /^.+\@.+\.\w+$/ ) {
    return lc $item;

  } else {

    my $sql = $ACIS -> sql_object;
    if ( length( $item ) > 15
         or index( $item, ":" ) > -1 ) {
      $sql -> prepare( "select owner from records where id=?" );
      my $r = $sql -> execute( lc $item );
      if ( $r and $r -> {row} ) {
        $login = $r ->{row} {owner};

      } else {
        logit "get_login_from_queue_item: id $item not found";
      }

    } elsif ( $item =~ m/^p[a-z]+\d+$/ 
              and length( $item ) < 15 ) {
      $sql -> prepare( "select owner,id from records where shortid=?" );
      my $r = $sql -> execute( $item );
      if ( $r and $r -> {row} ) {
        $login = $r ->{row} {owner};

      } else {
        logit "get_login_from_queue_item: sid $item not found";
      }

    }
  }

  return $login;
}




my $QUEUE_TABLE_NAME = "arpm_queue";
my @QUERIES = ( 
    # select explicitly queue-ed records
    qq! SELECT what FROM $QUEUE_TABLE_NAME WHERE status='' 
        ORDER BY class DESC,filed ASC
        LIMIT ? !,

    # select records, which don't yet have a non-null value of
    # last-auto-citations-time for them
    qq! SELECT r.shortid as what, s.data as data, s.param as param
    FROM records as r LEFT JOIN sysprof as s 
       ON s.id = r.shortid  AND 
          s.param = 'last-auto-citations-time'    
    WHERE s.data is NULL
    LIMIT ? !,

    # select records, for which we ran APU most long ago
    qq! SELECT id as what,data,param FROM sysprof  
        WHERE param='last-autosearch-time' or param='last-auto-citations-time'
        ORDER BY data+1 ASC LIMIT ? !
);


# get_the_queue: prepare the queue for APU
#
# assumes $QUEUE_TABLE_NAME, $ACIS, @QUERIES

sub get_the_queue {
  my $size = shift || die;
  my @to_process; # return value
  logit "prepare the process queue: size=$size";

  my $sql = $ACIS -> sql_object || die;
  my $get = ($size < 3) ? 9 : $size * 3;
  my @skipped; 
  my @to_process_logins;
  my @items;
  my %items_hash;
  my $r;
  my @q = @QUERIES;

  my $apu_too_recent_days  = $ACIS->config( 'minimum-apu-period-days' ) || 21;
  my $apu_too_recent_hours = $apu_too_recent_days * 24;

  # first source of the queue items
  my $query = shift( @q );
  $sql -> prepare( $query );
  debug "QUERY: $query";
  $r = $sql -> execute( $get );

  # the main loop
  while ( 1 ) {
    my $item =    $r -> {row} {what};
    my $lastrun = $r -> {row} {data};
    my $param   = $r -> {row} {param};
    my $type;

    if ( $param ) {
      if ( $param eq 'last-autosearch-time' ) {
        $type = 'research';
      } elsif ( $param eq 'last-auto-citations-time' ) {
        $type = 'citations';
      }
    }

    if ( ! $item ) { next; }
    if ( $items_hash{$item} ) { next; }

    if ( $lastrun ) {
      my $last = $lastrun || die;
      my $now  = time;
      if ( $now - $last <= $apu_too_recent_hours * 60 * 60 ) {
        # are we running too fast?
        # XXX slow down APU throughput
#       logit "skipping $item";
        push @skipped, $item;
        next;
      }
    }
    
    
    my $login = get_login_from_queue_item( $ACIS, $item );
    if ( $login ) {
      debug "ITEM: $item";
      push @items, $item;
      push @to_process, [ $login, $item, $lastrun, $type ];
      push @to_process_logins, $login;
      $items_hash{$item} = 1;

      $get--;
      if ( not $get ) { last; }
      
    } else {
      if ( not $lastrun ) {
        $sql -> prepare_cached( "delete from $QUEUE_TABLE_NAME where what=?" );
      } else {
        $sql -> prepare_cached( "delete from sysprof where id=?" );
      }
      $sql -> execute( $item );
      logit "cleared bogus queue item: $item";
    }
        

  } continue {
    
    if ( not $r -> next ) {
    QUERY:
      if ( scalar @q ) {
        $query = shift( @q );
        $sql -> prepare( $query );
        debug "QUERY: $query";
        $r = $sql -> execute( $get );
      } else { last; }

      if ( not $r or !$r->{row} ) { goto QUERY; }
    }  
  }

  logit "to process: ", join( ' ', @items  );
  if ( scalar @skipped ) {
    logit "skipped   : ", join( ' ', @skipped );
  }
  return \@to_process;
}


sub run_apu_by_queue {
  my $chunk = shift || 3;
  
  $ACIS || die;
  my $sql = $ACIS->sql_object || die;

  my $queue = get_the_queue( $chunk );

  my $number = $chunk;

  while ( $number ) {
    my $qitem = shift @$queue;

    last if not $qitem;
    my $login = $qitem -> [0];
    my $rid   = $qitem -> [1];
    my $type  = $qitem -> [2];
    my $res;
    my $notes;

    if ( $login ) {

      if ( $rid ne $login ) { 
        logit "about to process: $rid ($login)";
      } else {
        logit "about to process: $login";
      }
      
      require ACIS::Web::Admin;

      eval {
        ###  get hands on the userdata (if possible),
        ###  create a session and then do the work

        ###  XXX $qitem is not always a record identifier, but
        ###  offline_userdata_service expects an indentifier if anything on
        ###  4th parameter position

        $res = ACIS::Web::Admin::offline_userdata_service
                        ( $ACIS, $login, 'ACIS::APU::record_apu', $rid, $type ) 
                        || '';
      };
      if ( $@ ) {
        $res   = "FAIL"; 
        $notes = $@;
      }

      logit "apu for $login/$rid result: $res";
      if ( $notes ) {
        logit "notes: $notes";
      }

      if ( $res ) {
        if ( not $type ) {
          set_queue_item_status( $sql, $rid, $res, $notes );
        }
        $number--;
      }
      
    } else {
      last; 
    }


  } continue {
    $ACIS -> clear_after_request();
  }


}


# copied from ACIS::Web::ARPM::Queue
sub set_queue_item_status {
  my $sql  = shift;
  my $item = shift;
  my $stat = shift;
  my $notes = shift;

  $sql -> prepare_cached( 
qq!
REPLACE INTO $QUEUE_TABLE_NAME
    ( what, status, notes, worked ) 
VALUES 
    ( ?, ?, ?, NOW() )
! );

  my $res = $sql -> execute( $item, $stat, $notes );
}




use ACIS::Web::SysProfile;
use ACIS::Web::ARPM;
use ACIS::Citations::AutoUpdate;

sub record_apu {
  my $acis = shift;

  my $session = $acis -> session;
  my $vars    = $acis -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};
  my $sql     = $acis -> sql_object;

  my $pri_type = shift;
  my $pretend  = shift || $ENV{ACIS_PRETEND};

  my $now = time;
  my $last_research  = get_sysprof_value( $sid, 'last-autosearch-time' );
  my $last_citations = get_sysprof_value( $sid, 'last-auto-citations-time' );

  my $apu_too_recent_days  = $ACIS->config( 'minimum-apu-period-days' ) || 21;
  my $apu_too_recent_seconds = $apu_too_recent_days * 24 * 60 * 60;

  # research
  if ( not $pri_type 
       or $pri_type eq 'research' 
       or not $last_research
       or ($now - $last_research >= $apu_too_recent_seconds/2)  
     ) {
    ACIS::Web::ARPM::search( $acis, $pretend );
  }

  # citations 
  if ( not $pri_type 
       or $pri_type eq 'citatitons' 
       or not $last_citations
       or ($now - $last_citations >= $apu_too_recent_seconds/2)  
     ) {
    ACIS::Citations::AutoUpdate::auto_processing( $acis, $pretend );
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
