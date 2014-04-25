package ACIS::Web::Admin::EventsArchiving;  ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Module implements session data archiving from and to the events table.
#    It can do its job incrementally.  For that it creates and keeps a table
#    events_last_archived for tracking its status between runs.
#     
#  Copyright (C) 2004 Ivan Kurmanov for ACIS project, http://acis.openlib.org/
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
#  $Id$
#  ---




use strict;

use Encode qw( &decode );
use Web::App::Common qw( debug );

use ACIS::Web::Events;
use ACIS::Web::Admin::Events qw(        
                                add_to_about
                                chain_process_event
                                start_new_chain
                                find_session
                                make_session
                               );

## schmorp
use ACIS::Data::Serialization;
## schmorp

###  Database table events_last_archived (date DATETIME, togo INT) is a
###  storage for status data.  Date field points to a time at which previous
###  archiving run stopped and at which archiving shall continue.  Togo field
###  contains a number of records in the events table, which are waiting to be
###  processed (through archiving).
 
###  Return a hash of values in the events_last_archived table.  We assume the
###  table has just one single row, so we just take first one and return it.

sub get_status {
  my $acis = shift;
  my $par  = {};
  
  my $sql  = $acis -> sql_object;

  $sql -> prepare( "select * from events_last_archived" );    
  my $r = $sql -> execute( );
  
  if ( $r and $r->{row} ) {
    return $r->{row};
  }
  return undef;
}

###  Save_status() function works as a little blackbox.  It shall do its job
###  even if the storage table does not yet exists or if its structure is not
###  yet up-to-date.

###  Parameters are in the function parameter list, after the ACIS object,
###  with each param in -param => $value form.  E.g. save_status( $acis, -date
###  => '2003-12-31 23:59:59' );

sub save_status {
  my $acis = shift;
  my $par  = { @_ };
  
  my $date = $par->{-date};
  my $togo = $par->{-togo};
  my $sql  = $acis -> sql_object;

  # For historical reasons, we just first treat the date thing, then togo.

  my $previous = get_date_of_last_archived_event( $acis );
  if ( not $previous ) {
    ###  probably table doesn't exist

    $sql -> do( 
               "create table events_last_archived "
               . "( date DATETIME not null,"
               . " togo int"
               . " )"
              );
    $sql -> prepare( "insert into events_last_archived (date) values (?)" );    
    
  } else {
    $sql -> prepare( "update events_last_archived set date=?" );
  }
  $sql -> execute( $date );
  
  if ( $togo ) {
    my $try = 0;
    my $r;

    { 
      $sql -> prepare( "update events_last_archived set togo=?" );
      $r = $sql -> execute( $togo );
      
      if ( $sql -> error ) {
        $try ++;

        ### previous version of this module used events_last_archived table
        ### with just date field, so, for togo field we need to add it.

        $sql -> prepare( "alter table events_last_archived add column togo int" );
        $sql -> execute();
      
        if ( not $sql -> error and $try ) { redo; }
      }
      last;
    }

    if ( not $r ) {
      warn "can't save togo";
    }
  }

}



###  This function retrieves that date and returns it.

sub get_date_of_last_archived_event {
  my $acis = shift;
  my $sql  = $acis -> sql_object;
  
  $sql -> prepare( "select date from events_last_archived" );
  my $r = $sql -> execute();
  if ( $r and $r -> {row} ) {
    return $r ->{row}->{date};
  }
  return undef;
}


###  When we just starting archiving and do not yet have events_last_archived
###  table or no data in it, this functions gives us a date to start from.

sub get_date_of_first_event_ever {
  my $acis = shift;
  my $sql  = $acis -> sql_object;
  $sql -> prepare( "select date from events order by date limit 1" );
  my $r = $sql -> execute;
  if ( $r and $r ->{row} ) {
    return $r ->{row} {date};
  } 
  return undef;
}


###  This is an experimental web interface to the archiving.  archive_screen()
###  is a /adm/events/archive screen handler.

sub archive_screen {
  my $acis = shift;

  my ( $worked, $start_date, $last_date ) = archiving_run( $acis );
  
  $acis -> print_content_type_header( "text/plain" );
  $acis -> response -> {headers_printed} = 1;
  print "\n";

  print "Archived: $worked\n";
  print "Start date: $start_date\n";
  print "Last date: $last_date\n";

  print "Log: \n";
  print $Web::App::Common::LOGCONTENTS;
}


###  This is the general house-keeping function, which loads and saves status,
###  checks togo numbers, runs the archiving function itself (for a given
###  number of event records ($limit parameter).

sub archiving_run {
  my $acis   = shift;
  my $limit  = shift || 1000;


  ###  get status

  my $status = get_status( $acis );
  

  ###  get a date to start work from

  my $start;
  if ( $status ) { $start = $status -> {date}; }

  if ( not $start ) {
    $start = get_date_of_first_event_ever( $acis );
  }
  

  ###  First we prepare and execute a database query for events records, which
  ###  then another function will process.

  my $sql = $acis -> sql_object;

  $sql -> prepare( "select * from events where date>=? and date < NOW() ".
                   "order by date asc, startend desc limit $limit" ); 

  my $res = $sql -> execute( $start );


  ###  Second, we pass the result to the main archiving function, which will
  ###  go through the query result $res.
  
  my ($work, $last_date) = decode_and_save_metadata( $acis, $res );


  ###  Togo is the number of events waiting to be archived.  If number of
  ###  events waiting to be archived has increased since last run of
  ###  archiving, then probably there's more events happening then we have
  ###  chance to archive.  That probably means admin shall execute this more
  ###  often.

  my $togo;
  if ( $last_date ) {
    $sql -> prepare( "select count(*) as togo from events where date > ?" );
    my $r = $sql ->execute( $last_date );
    if ( $r and $r->{row} ) {
      $togo = $r->{row}->{togo};
      debug "Events to work on further: $togo";
    }
  }


  ###  save status

  if ( $last_date ) {
    save_status( $acis, 
                 $last_date ? ( -date => $last_date) : (),
                 $togo ? ( -togo => $togo ) : ()
               );
  }

  ###  Compare number of yet unprocessed events after this run with a similar
  ###  number after previous run:

  if ( $status 
       and $status -> {togo} 
       and $status -> {togo} < $togo
       and $togo
       and $togo*2 > $limit ) {
    print "probably you should run archiving more often (", 
      $status->{togo}, "/$togo)\n";
  }

  return ( $work, $start, $last_date );
}



###  The main events processing function.  Goes through the events given in a
###  query result object ($bunch), looks for things to archive and saves them
###  in $sessionlist.  

###  The only things to save are finished (complete) sessions.  They normally
###  occupy a number of rows in the events table, but after archiving a
###  session takes exactly one row.  That row will contain a packed log of the
###  session and some general data about it.  But all that happens later, in
###  the dump_sessions() func.

sub decode_and_save_metadata {
  my $acis  = shift;
  my $bunch = shift;

  my $sql      = $acis -> sql_object;
  die if $sql->error;
  
  if ( not $bunch ) { return undef; }
  if ( not $bunch->{row} ) { return( "0/0", "" ); }

  my $sessions = {};     ### temporary holder for session data, by session id
  my $sessionlist = [];  ### holder for sessions to be archived

  my $events_count   = 0;
  my $sessions_count = 0;
  
  my $last_date;    #### Date of last processed event, for reporting back


  eval {    ###  Wrapped this in eval.  Probably unnecesarilly.

    while ( $bunch ->{row} ) {
      $events_count ++;

      $_ = $bunch ->{row};

      my $e    = make_event_from_db_row( $_ );
      my $chid = $e ->{chain};
      my $date = $e ->{date}; 
      my $start= $e ->{startend};
      $last_date = $date;
#      debug "$date";
      
      ###  event dispatcher
      
      if ( $chid ) {

        if ( $start == 1 ) {
          
          if ( $e->{packed} ) { next; }

          warn "start again? $date-$chid\n" 
            if $sessions->{$chid} and $sessions->{$chid} {open};

          debug "found session start: $date-$chid";

          my $se = make_session $_;
          if ( $se ) {
            ###  new session block
            $sessions ->{$chid} = $se;
            push @$sessionlist, $se;
            $sessions_count++;

          } else {
            warn "can't create session structure for $chid";
            next;
          }

        } else {

          my $s = $sessions->{$chid};

          if ( not $s ) {
            ### find and load session's first event:
            $s = find_session( $sql, $chid, $date );

            if ( not $s ) { 
              warn "didn't find session start $chid-$date\n";
              next;
            }
            
            ### find and load other session's events, between the start and
            ### this one:
            $sql ->prepare( 'select * from events where chain=? and '
                            . 'date >= ? and date <? and startend<>1 '
                            . 'order by date asc' );
            my $data = $sql ->execute( $chid, $s->{date}, $date );
            
            if ( not $data ) { 
              warn "can't find/load session's body data $chid\n";
              next;
            }

            while ( $data->{row} ) {
              my $event = make_event_from_db_row( $data->{row} );
              chain_process_event( $s, $event );
              $data->next;
            } 
              
            $sessions->{$chid} = $s;
            push @$sessionlist, $s;
          }

          if ( $s ) {
            chain_process_event( $s, $e );
          } else { 

            warn "didn't find session $chid at $date\n";
            next;
          }

        }

      }

    } continue {
      $bunch ->next;
    }
    $bunch ->finish;
  };

  debug "Last date: $last_date";

  if ( $@ ) {
    debug "eval: $@";

  } else {
    dump_sessions( $sql, $sessionlist );
  }

  return( "$sessions_count/$events_count", $last_date );
}



use Carp::Assert;



sub dump_sessions {
  my $sql         = shift;
  my $sessionlist = shift;

  my $remove = [];
  my $saved  = 0;

  my $last_date = '';

  ## schmorp
  require Storable;
  ## /schmorp

  $sql ->prepare( "update events set packed=?,data=?"
                  . " where date=? and chain=? and startend=1" );

  foreach ( @$sessionlist ) {
    my $se   = $_;
    my $sid  = $se->{id};

    my $about = $se -> {about};

    ###  Is there anything to pack?

    if ( not $se->{log} ) {  next;  }

    my $closed_at = $se ->{about} {closed};
    if ( $closed_at ) {

      ###  a little check
      if ( not $about ->{humanname} ) {
        warn "no humanname in session's about\n";
        #; skipping session $sid\n";
        #next;
      }

      if ( not $about ->{login} ) {
        warn "no login in session's about; skipping session $sid\n";
        next;
      }

      ## schmorp
      ###  Pack the log with Storable's nfreeze      
      #my $log = Storable::nfreeze( $se->{log} );
      my $log=deflate($se->{'log'});
      ## /schmorp

      ### Pack $about as string of several attribute: value lines,
      ### "\n"-separated

      my $data = ''; 
      foreach ( keys %$about ) {
        my $a = $_;
        my $v = $about ->{$a};
        if ( $a ) {
          $data .= "$a: $v\n";
        }
      }      

      $sql -> execute( $log, $data, $se->{date}, $sid );
      if ( $sql ->error ) { warn "can't save session metadata and log $sid"; next; }
      $saved ++;

      push @$remove, [ $sid, $se->{date}, $closed_at ];
      
      if ( $closed_at gt $last_date ) {
        $last_date = $closed_at;
      }

    } else {
      debug "$sid is not ready for packing";
    }
    

  }

  debug "packed data into $saved session-events";


  ###  clear all events of each session but the first one from the events
  ###  table:
  
  $sql ->prepare( "delete from events where date>=? and date<=? and chain=? and (startend<>1 or startend is null)" );
  
  my $cleared = 0;
  foreach ( @$remove ) {
    my $id  = $_->[0];
    my $sta = $_->[1];
    my $end = $_->[2];

    assert( $id and $sta and $end );
    $sql ->execute( $sta, $end, $id );
    $cleared++;
  }

  debug "cleared sessions: $cleared";

  
  debug "last date: $last_date";
  return $last_date;
}



1;
