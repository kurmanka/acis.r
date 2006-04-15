package ACIS::Web::Admin::Events;

###  Events log analysis and presentation preparation


use strict;

use Encode;
use Exporter;

require Storable;
use Carp::Assert;

use Web::App::Common;
use ACIS::Web::Events;


use vars qw( @ISA @EXPORT_OK );

@ISA = ('Exporter');
@EXPORT_OK = qw(
                add_to_about
                chain_process_event
                start_new_chain
                find_session
                make_session
);


use vars qw( $ecount $options );

$ecount  = 0;
$options = {};

sub add_to_about($$$) {
  my $about = shift;
  my $prop  = shift;
  my $val   = shift;

  if ( not $val 
       or $about->{$prop} ) {
    return 0;

  } else {
    $about->{$prop} = $val;
    return 1;
  }
}


###  A chain is a chain of related events, namely, a session in ACIS.  Here a
###  chain is an object (a hash), representing a session.  This function
###  collects session metadata, based on separate events.

sub chain_process_event($$;$) {
  my $chain = shift;
  my $e     = shift;      # event 
  my $save  = shift || 1; # flag -- save to session log?
 
  my $about = $chain -> {about};

  my $error;
  my $type  = $e -> {type}   || '';
  my $class = $e -> {class}  || '';
  my $action= $e -> {action} || '';

  my $noadd = 0; ### do not add to log?
  
  if ( $type eq 'error' ) {
    $about -> {errors} ++;
    $error = 1;
  } 
  
  if ( $class eq 'session' ) {
    if ( $action eq 'started' ) {

      $noadd |= add_to_about( $about, 'stype', $e ->{stype} );
      add_to_about( $about, 'sesid', $e ->{chain} );

      if ( $e ->{data} ) {
        my $data = $e->{data};
        foreach ( split "\n", $data ) {
          my ( $f, $v ) = split( ": ", $_, 2 );
          if ( $f ) { 
            $about -> {$f} = $v;
          }
        }
      }

      if ( $e ->{packed} ) {
        my $log = $e ->{packed};
        $chain ->{log} = Storable::thaw( $log );
        
        if ( not $chain->{log} ) {
          debug "bad storable frozen value: $e->{chain}";
        }
        
        if ( $about ->{closed} ) { 
          $chain ->{complete} = 1; 
          delete $chain->{open};
        }
      }
      $save = 0;
      
    } elsif ( $action eq 'closed' ) {
      delete $chain ->{open};
      $about ->{closed} = $e ->{date};
      $chain ->{complete} = 1;
  
    } elsif ( $action eq 'discard' ) {
      $about ->{discarded} = 'y';
      $chain ->{complete} = 1;
    }
  }
  
  if ( $about->{closed} ) {
    if ( $class ne 'session' 
         and $action ne 'started' ) {
      $about -> {closed} = $e ->{date};
      delete $chain ->{open};
    }
  }


  if ( $class eq 'auth' 
       or $class eq 'new-user' ) {
    $noadd |= add_to_about( $about, 'login', $e ->{login} );
    
    add_to_about( $about, 'userdata-file', $e ->{file} );
    add_to_about( $about, 'IP', $e ->{IP} );
    $noadd |= add_to_about( $about, 'humanname', $e ->{humanname} );
  }

  if ( $class eq 'record' 
       or $class eq 'new-user' ) {
    $noadd |= add_to_about( $about, 'record-id', $e ->{id} );
    add_to_about( $about, 'record-short-id', $e ->{sid} );
  }


  if ( $save ) {
    if ( $options->{onlyresearch} ) {
      if ( $class eq 'contrib' ) {
        undef $e ->{class};
      } else { $save = 0; }
    }
  }

  if ( $save ) {
    my $log   = $chain -> {log} || [];
    
    delete $e->{chain};
    delete $e->{startend};

    push @$log, $e;
    $ecount ++;

    #  if ( not $noadd ) {
    #  $chain -> {log} .= present_event( $e );
    #  }
  } else { 
#    debug "not saving $e->{date}\n";
  }

}




sub start_new_chain ($) {
  my $event = shift;
  
  my $chain = {
               log   => [],
               about => {},
               open  => 1,
               date  => $event->{date},
              };

#  warn "new ses: ". $event->{chain}. "\n";
  chain_process_event( $chain, $event, 0 );
  
  return $chain;
}


sub make_session($) {
  my $row   = shift;
  my $about = {};
  
  my $data = $row ->{data};
  if ( $data ) {
    foreach ( split "\n", $data ) {
      my ( $f, $v ) = split( ": ", $_, 2 );
      if ( $f ) { 
        $about -> {$f} = $v;
      }
    }
  }

  my $se = { about => $about };
  $se ->{date}   = $row ->{date};
  $se ->{log}    = [];
  $se ->{open}   = 1;
  $se ->{id}     = $row ->{chain};

  my $log = $row ->{packed};
  if ( $log ) {
    require Storable;
    $se ->{log} = Storable::thaw( $log );
    delete $se ->{open};
  }

  return $se;
}


sub find_session ($$$) {
  my $sql  = shift || die;
  my $id   = shift || die;
  my $date = shift || die;

  $sql -> prepare( "select * from events where chain=? and date<=? and startend=1 "
                 . "order by date desc limit 1" );

  my $r = $sql ->execute( $id, $date );

  if ( $r and $r->{row} ) {
    for ( $r->{row} ) {
      return make_session $r->{row};
    }
  }
  return undef;
}




###############################################################################
###                 S H O W   E V E N T S   F O R 
###############################################################################

###  This takes a list of parameters as arguments.  It gets events from the
###  database for a period of time and prepares them for display.  Limits tell
###  it where to stop if it goes too far (gets too much data).

###  Parameters: 
###    -start   => [ day, time ]
###    -end     => [ day, time ]
###    -slimit  => number,
###    -elimit  => number,
###    -options => [ opt1, ... ]


sub show_events_for {
  my $acis = shift;

  my $param     = { @_ };

  debug "show_events_for() enter";
  
  my $startday ;   ###  YYYY-MM-DD
  my $starttime;   ###  HH:MM:SS
  my $finishday ;
  my $finishtime;

  if ( $param -> {-start} ) {
    $startday  = $param->{-start} [0];
    $starttime = $param->{-start} [1] || '00:00:00';
  }
  if ( $param ->{-end} ) {
    $finishday  = $param->{-end} [0];
    $finishtime = $param->{-end} [1] || '00:00:00';
  }

  if ( $param ->{-recent} ) {
    my $rh = $param->{-recent};
    my $sql = $acis ->sql_object;
    $sql -> prepare( "select ( NOW() - INTERVAL ? HOUR ) as start, NOW() as fin" );
    my $qr  = $sql -> execute( $rh );
    assert( $qr );
    my $start = parse_date( $qr ->{row}{start} );
    my $fin   = parse_date( $qr ->{row}{fin} );
    ( $startday, $starttime )   = @$start;
    ( $finishday, $finishtime ) = @$fin;
  }

  debug "start : $startday $starttime";
  debug "finish: $finishday $finishtime";


  my $slimit ;  ###  sessions limit
  my $elimit ;  ###  events limit
  $options = {
               orphan => 1,
#               onlyresearch => 1
             };


  if ( $param ->{-slimit} ) {  $slimit = $param ->{-slimit}; }
  if ( $param ->{-elimit} ) {  $elimit = $param ->{-elimit}; }

  if ( $param ->{-options} ) { 
    my $o = $param ->{-options}; 
    foreach ( @$o ) {
      $options ->{$_} = 1;
    }
    debug "options: @$o";
  }

  if ( $options->{onlyresearch} ) {
    delete $options->{orphan};
  }

  if ( $elimit ) {  debug "elimit: $elimit";  }
  if ( $slimit ) {  debug "slimit: $slimit";  }

  my $sql = $acis -> sql_object;

  $sql -> prepare( "select * from events"
                   ." where date >= ? and date <= ?"
                   ." order by date"
                   . ", startend desc" 
                 ); 

  my $fullstartdate = "$startday $starttime";
  my $fullfindate   = "$finishday $finishtime";

  my $r = $sql -> execute( $fullstartdate, $fullfindate );

  die if $sql->error;



  my $sessions = {};
  my @events   = ();
  my $days     = {};

  my $scount = 0;
  $ecount = 0;
  my $stopped_at = '';
  
  my $tail   = '';  ###  tail is until what time to scan after the main read

  my $mode = 'collect';
  my $e;
  my $row;

  while ( $row = $r ->{row} ) {  ### the main read
    
    my $date = $row ->{date};

    if ( $mode eq 'collect' 
         and $stopped_at ) {
      if ( $date ne $stopped_at ) {
        $mode = 'scan';
      }
    }

    if ( defined $row->{startend} 
         and $row ->{startend} == 1 ) { 
      if ( $mode eq 'scan' ) { next; }
    }

    if ( $mode eq 'collect' ) {
      my $day = substr( $date, 0, 10 );
      $days ->{"d$day"} = 1;
    }


    my $chid = $row ->{chain};
    if ( not $chid ) {
      if ( $mode eq 'collect' ) {
        if ( $options ->{orphan} ) {
          
          $e = make_event_from_db_row( $row );
          push @events, $e;
          $ecount ++;
##          push @events, present_orphan_event( $e );
        }
      }
      next;
    }

    $e = make_event_from_db_row( $row );

    if ( $e -> {startend}
         and $e -> {startend} == 1 ) {
      
      my $se = start_new_chain( $e );

      if ( $options->{hidemagic} 
           and $se->{about}{stype} eq 'magic' ) {
        next;
      }

      $sessions->{$chid} = $se;
      $scount ++;
      push @events, $se;

      if ( $se ->{about} {closed} ) {
        my $closed = $se ->{about} {closed};
        
        my $log = $se->{log};
        
        debug "$chid, a closed session";
        
        if ( $e ->{packed} and $log ) {
        } else {
          debug "with no packed log";
        }

        if ( $e ->{packed} 
             and $log
             and $se ->{complete} ) { ### double check 
          
          debug "and complete";

          ## Probably, this is a packed (archived) session event.  We need to
          ## run session's log through filters and increase events counter.

          if ( $options->{onlyresearch} ) {
            foreach ( @$log ) {
              if ( $_->{class} ne 'contrib' ) { undef $_; }
              else { undef $_ ->{class}; }
            }
            clear_undefined $log;
            if ( not scalar @$log ) {
              $scount --;
              pop @events;
              delete $sessions->{$chid};
              next;
            }
          }

          $ecount += scalar @$log;


          ## do not scan for further events of this session
          delete $sessions->{$chid};

        } elsif ( not $tail ) {     
          $tail = $closed;

        } else {
          if ( $tail lt $closed ) {
            $tail = $closed;
          } 
        }                           

      } else {
        $tail = 'X'; ### indefinite 
        debug "$chid, a session with undefined finish";
      }
      
      next;
    }
    
    my $se = $sessions ->{$chid};
    if ( $se ) {

      chain_process_event( $se, $e );

      if ( $se -> {complete} ) { 
        delete $sessions ->{$chid};
      }
    } else {
      ### can't find a session to attach event to
    }
    
  } continue {
    
    if ( $mode eq 'collect'
         and not $stopped_at ) {
      if ( $slimit and $scount >= $slimit ) { 
        $stopped_at = $row -> {date}; 
      }
      if ( $elimit and $ecount >= $elimit ) { 
        $stopped_at = $row -> {date}; 
      }
    }
    $r ->next;
    
  }
  $r -> finish;
  

  ### Make data complete -- find sessions' endings

  if ( scalar keys %$sessions ) {
    ### scan until these sessions are complete

    debug "looking for tail: $tail";

    if ( $tail eq 'X' ) {
      # we do not know, until what date to scan
      $sql -> prepare( 
                      "select * from events where date >= ?" 
                      . " and chain is not null order by date"
                     );
      $r = $sql -> execute( $fullfindate );

    } elsif ( $tail ) {
      # we know, until what date to scan

      $sql -> prepare( 
                      "select * from events where date >= ?"
                      . " and date <= ? and chain is not null" 
                      . " order by date" 
                     );
      $r = $sql -> execute( $fullfindate, $tail );
    } 

    ### scan, completing the already started sessions

    my $found = 0;
    my $completed   = 0;
    my $to_complete = scalar keys %$sessions;

    while ( $r ->{row} ) {
      $e = make_event_from_db_row( $r->{row} );

      my $chid = $e ->{chain};
      if ( not $chid ) { next;  }

      if ( $e -> {startend} == 1 ) { next; }
      
      my $se = $sessions ->{$chid};

      if ( $se ) {
        chain_process_event( $se, $e );
        
        $found ++;
        if ( $se -> {complete} ) { 
          delete $sessions ->{$chid};
          $completed ++;
          if ( $completed == $to_complete ) {
            last;
          }
        }
      }

    } continue {
      $r ->next;
    }
    $r -> finish;

    debug "found $found events for previously started sessions";
    debug "completed $completed sessions";

    if ( scalar keys %$sessions ) {
      debug "but there are still incomplete sessions: " . 
        scalar keys %$sessions;
      debug join ' ', keys %$sessions;
    }

  }
  

  ####  If onlyresearch option is "on", go through the @events list, look for
  ####  sessions with no events in its log, and filter them out.
  
  if ( $options->{onlyresearch} 
       # other options may be added later
     ) {
    foreach ( @events ) {
      if ( $_->{about} ) {
        my $log = $_->{log};
        if ( $log and scalar @$log ) { } # good
        else {
          undef $_;
          $scount --;
        }
      }
    }
    clear_undefined \@events;
  }


  ####  Pass the events and other data to the presenter (template).

  $acis -> variables -> {events} = \@events;


  ###  Presenter must know, what events we finally giving it, what user
  ###  requested, and what shall user ask to see further events.
 
  my $showing   = {};
  my $asked_for = {};
  my $from = { day => $startday,  time => $starttime  };
  my $to   = { day => $finishday, time => $finishtime };


  ###  What user asked for:
  $asked_for -> {timespan} = { from => $from,
                               to   => $to };

  if ( $stopped_at ) {
    my ( $stopday, $stoptime ) = 
      ( $stopped_at =~ /^(\d{4}-\d\d?-\d\d?)\s(\d\d:[\d:]+)$/ );
    $to = { day => $stopday, time => $stoptime };
    $acis -> variables -> {to_be_continued} = '1';
  }

  ###  What do we show
  $showing -> {timespan} = { from => $from,
                             to   => $to };
  $showing -> {options} = $options;

  ###  The limits used
  $showing -> {sessionscount} = $scount;
  $showing -> {eventscount}   = $ecount;
  $showing -> {days}          = $days;

  debug "events: $ecount, sessions: $scount";

  $acis -> variables -> {showing}   = $showing;
  $acis -> variables -> {asked_for} = $asked_for;


  
  {###  What to look next:
    my $d = $to->{day};
    my $t = $to->{time};
    my $nextsecond = date_add_one_second( $sql, "$d $t" );
    my ( $day, $time ) = 
       ( $nextsecond =~ /^(\d{4}-\d\d?-\d\d?)\s(\d\d:[\d:]+)$/ ); ### use
                                                                  ### split?
    my $next = { day => $day, time => $time };
    $acis -> variables -> {'next-second'} = $next;
  }

  return scalar @events;
}








#########################################################################
###                 s c r e e n    h a n d l e r s 
#########################################################################



sub recent_events_raw {
  my $acis = shift;

  my $period = $acis -> form_input -> {hours} || 25;

  my $d = $acis -> get_recent_events( $period );

  my $sql = $acis -> sql_object;
  die if $sql->error;
  
  if ( not $d or not $d -> rows ) { 
    $acis -> error( "no-events" ); 
    return undef;
  }

  my @chains;
  my %chain_ids;
  my @evs = ();
  
  eval {

    while ( $d ->{row} ) {
      my $e     = make_event_from_db_row( $d->{row} );
      my $chain = $e ->{chain};
      push @evs, $e;
      
    } continue {
      $d ->next;
    }
    $d -> finish;
  };

  $acis -> variables -> {events} = \@evs;

}





###  a screen handler
sub recent_events_decode {
  my $acis = shift;

  my $period = $acis -> form_input -> {hours} || 25;

  my $d   = $acis -> get_recent_events( $period );
  my $sql = $acis -> sql_object;
  die if $sql->error;

  if ( not $d or not $d ->{row} ) { 
    $acis -> error( "no-events" ); 
    return undef;
  }

  my @chains;
  my %chain_ids;
  my @evs = ();

  eval {

    while ( $d ->{row} ) {
      my $e    = make_event_from_db_row( $d->{row} );
      my $chid = $e ->{chain};


      ###  event dispatcher

      if ( $chid and $chain_ids{$chid} ) {
        my $chain = $chain_ids{$chid};

        if ( $chain ->{open} ) {
          chain_process_event( $chain, $e );

        } else {
          
          my $date1;
          my $date2 = $e ->{date};
          if (
              defined $chain 
              and $chain ->{log}
              and $chain ->{log}[-1]
              and ( $date1 = $chain -> {log} [-1] {date} )
              and defined $date2 
              and ( $date1 eq $date2 
                    or dates_near( $sql, $date1, $date2 )
                  )
             ) {
            chain_process_event( $chain, $e );

          } else {
            delete $chain_ids{$chid};
            goto NEWCHAIN;
          }
        }
        
      } else {

      NEWCHAIN:
        if ( $chid ) {
          if ( defined $e -> {startend} 
               and $e -> {startend} == 1 ) {
            my $chain = start_new_chain( $e );
            $chain_ids{$chid} = $chain;
            push @evs, $chain;
            next;
          }
        }

        push @evs, $e;
      }

    } continue {
      $d ->next;
    }
    $d -> finish;
  };

  $acis -> variables -> {events} = \@evs;
  $acis -> variables -> {'events-hours-shown'} = $period;

  $acis -> {response} {serializer} = \&ACIS::Data::DumpXML::dump_no_bullshit;

}





###  screen handler
sub browse_events_by_month {
  my $acis  = shift;
  my $for   = shift;

  debug "browse_events_by_month() enter";
  if ( $for ) { debug "for: $for"; }

  my $years = {};
 
  my $sql  = $acis -> sql_object;
  
  $sql -> prepare( "select substring(date,1,7) as ym from events group by 1" );
  my $r = $sql -> execute();
  
  while ( $r and $r->{row} ) {
    my $da = $r->{row};
    
    my $ym   = $da->{ym};
    my ( $year, $month ) = ( $ym =~ /^(\d{4})-(\d{2})$/ );
    
    $years -> {$year} -> {$month} = '';
    $r -> next;
  }

  $acis -> variables ->{years} = $years;
  $acis -> variables ->{for}   = $for;

}


sub browse_events_by_days {
  my $acis  = shift;
  my $for   = shift || die;

  debug "browse_events_by_days() enter";
  debug "for: $for";

  browse_events_by_month( $acis );

  my $years = $acis -> variables -> {years};
 
  my $sql  = $acis -> sql_object;
  
  $sql -> prepare( 
     "select substring(date,1,10) as ymd from events"
   . " where substring(date,1,7) = ? group by 1" );

  my $r = $sql -> execute( $for );

  my ( $y, $m ) = split '-', $for;
  if ( $r -> {row} ) {
    $years -> {$y} {$m} = {};
  }

  while ( $r and $r->{row} ) {
    my $da = $r->{row};
    
    my $ymd   = $da->{ymd};
    my ( $year, $month, $day ) = ( $ymd =~ /^(\d{4})-(\d{2})-(\d{2})$/ );
    
    $years -> {$year} {$month} -> {$day} = '';
    $r -> next;
  }

  $acis -> variables ->{years} = $years;
  $acis -> variables ->{for}   = $for;

}


use constant default_recentis => 12;

sub get_current_recent_is {
  my $acis = shift;
  return $acis -> get_cookie( "recentis" ) || default_recentis;
}


sub events {
  my $acis = shift || die;
  my $sub  = $acis -> request-> {subscreen};

#  $acis -> variables -> {TOPEVENTS} = 1;
  my $sql  = $acis -> sql_object;

  $acis -> {response} {serializer} = \&ACIS::Data::DumpXML::dump_no_bullshit;

  my $start;
  my $sid  ;
  my $end  = [];
  my $period;
  my $options = get_options( $acis ) || undef;
  my $recent;
  my $overview;

  for ( $sub ) {
    
    if ( m!^([\d\/:-]+)\.\.([\d\/:-]+)$! ) {
      $period = 1;
      $start = parse_date( $1 );
      $end   = parse_date( $2 );
#      debug "period: @$start @$end";
      
    } elsif ( /^(\d{4})-(\d{2})$/ ) {
      ###  show menu of events in this month
      $overview = "$1-$2";
      debug "overview for $overview";

    } elsif ( /^(\d{4})$/ ) {
      ###  show menu of events in this year
      $overview = $1;
      debug "overview for $overview";

    } elsif ( /^$/ ) {
      $overview = '';
      debug "overview, general";

    } elsif ( m!^\d\d\d\d-\d?\d-\d?\d(?:/.+)?$! ) {
      $start = parse_date( $_ );
      debug "a day/time: $_";

    } elsif ( m!^([\-\d\/:]+)-([\w\d]+)$! ) {
      $start = parse_date( $1 );
      $sid   = $2;
      debug "a session: $1 $sid";

    } else {
      debug "request not recognized: $_";
    }

  }

  my $elimit = $acis -> get_cookie( "elimit" ) || '';
  my $slimit = $acis -> get_cookie( "slimit" ) || '';

  if ( $start ) {

    debug "start: @$start";
    debug "end  : @$end";
    
    if ( not $end->[0] ) {
      $end = [ $start->[0] ]
    }
    if ( not $end->[1] ) {
      $end ->[1] = "23:59:59";
    }
    show_events_for( $acis, 
                     -start  => $start, 
                     -end    => $end, 
                     -slimit => $slimit, 
                     -elimit => $elimit, 
     ($options) ? ( -options => $options ) : (),
                   );    

  } elsif ( defined $overview ) {

    if ( length( $overview ) >4 ) {
      browse_events_by_days( $acis, $overview );
    } else {
      browse_events_by_month( $acis, $overview );
    }

    ### set presenter
    $acis -> set_presenter( 'adm/events/overview' );

  } else {
    debug "nothing to do";

  }

}

sub get_options {
  my $acis    = shift;
  my $options = [];

  my $opt_showmagic    = $acis -> get_cookie( "showmagic" );
  my $opt_onlyresearch = $acis -> get_cookie( "onlyresearch" );
  
  if ( not defined $opt_showmagic ) { $opt_showmagic = 'true'; }

  if ( $opt_onlyresearch ) { 
    push @$options, "onlyresearch";
  } else {
    if ( not $opt_showmagic ) {
      push @$options, 'hidemagic';
    }
  }

  my $qstring = $ENV{QUERY_STRING};
  if ( $qstring ) { 
    push @$options, split( '\+', $qstring );
    debug "query string options: @$options";
  }
  
  if ( $acis -> request-> {subscreen} ) {
    my $sub  = $acis -> request-> {subscreen};
    
    ### get options, del.icio.us style
    {
      $sub =~ s!/([\w+]+)$!!;
      if ( $1 ) {
        push @$options, split( '\+', $1 );
      }
    }
  }

  debug "fin options: " , join( ' ', @$options );

  if ( not scalar @$options ) {
    return undef;
  } else { 
    return $options;
  }

}


sub events_recent {
  my $acis = shift || die;
  my $sub  = $acis -> request-> {subscreen};

  my $sql  = $acis -> sql_object;

  $acis -> {response} {serializer} = \&ACIS::Data::DumpXML::dump_no_bullshit;

  my $recent  = get_current_recent_is( $acis );
  my $options = get_options( $acis ) || undef;

  my $elimit = $acis -> get_cookie( "elimit" ) || '';
  my $slimit = $acis -> get_cookie( "slimit" ) || '';

  show_events_for( $acis,
                   -recent => $recent,
                   -slimit => $slimit,
                   -elimit => $elimit,
   ($options) ? ( -options => $options ) : (),
                 );

}


sub preferences {
  my $acis = shift;

  my $elimit = $acis -> get_cookie( "elimit" ) || '';
  $acis -> set_form_value( 'eventslimit', $elimit );

  my $slimit = $acis -> get_cookie( "slimit" ) || '';
  $acis -> set_form_value( 'sessionslimit', $slimit );

  my $recentis = get_current_recent_is( $acis ) || ''; 
  $acis -> set_form_value( 'recentis', $recentis );


  foreach( qw( opensbox showmagic onlyresearch ) ) { 

    my $option = $acis -> get_cookie( $_ );
    if ( $_ eq 'showmagic' ) {
      if ( not defined $option ) { $option = 'true'; }
    }
    if ( $option ) {
      $acis -> set_form_value( $_ . "-true", '' );
    }
  }


}




sub events_show_screen {
  my $acis = shift;

  my $par  = $acis -> form_input();
  my $start = $par -> {'startdate'};
  my $end   = $par -> {'enddate'};

  my $himagic  = $par -> {hidemagic};
  my $research = $par -> {onlyresearch};
  
  my $base = $acis -> config( 'base-url' );

  my $ts, my $te;
  if ( not $ts = check_date($start) ) {
    $acis -> error( "bad-start-date" );
    $acis -> set_presenter( "sorry" );
    return;
  }
  if ( not $te = check_date( $end ) ) {
    $acis -> error( "bad-end-date" );
    $acis -> set_presenter( "sorry" );
    return;
  }

  if ( $ts gt $te ) {
    $acis -> error( "period-ends-before-start" );
    $acis -> set_presenter( "sorry" );
    return;
  }
  
  $start = sprintf( '%04i-%02i-%02i/%s', ($ts =~ /^(....)(..)(..)(..:..:..)/));
  $end   = sprintf( '%04i-%02i-%02i/%s', ($te =~ /^(....)(..)(..)(..:..:..)/));

  $start =~ s!/00:00:00$!!;
  $end   =~ s!/00:00:00$!!;

  my $url = $base . "/adm/events/" 
    . "$start..$end";

  if ( $himagic or $research ) { 
    $url .= "?";
    my @o = ();
    if ( $himagic ) { push @o, "hidemagic"; }
    if ( $research) { push @o, "onlyresearch"; }
    $url .= join "+", @o;
  }

  $acis -> redirect( $url );
  
}


sub check_date ($) {
  my $date = shift;
  require Date::Manip;
  my $t = Date::Manip::ParseDateString( $date );
  return $t;
}


sub parse_date ($) {

  my $string = shift;
  for ( $string ) {
    if ( m!^(\d{4})-(\d{1,2})-(\d{1,2})(?:[/\s](\d{2}:\d{2}(?::\d{2})?))?$! ) {
      my $date = sprintf( "%04d-%02d-%02d", $1, $2, $3 );
      my $time = $4;
      if ( $time =~ /^\d\d:\d\d$/ ) {
        $time = "$time:00";
      }
      return( [ $date, $time ] );
    }
  }
  return undef;
}




######  PRESENTATION FUNCS, for speed

sub present_event {
  my $event = shift;

  my $date  = $event->{date};
  my $type  = $event->{type}  || '';
  my $class = $event->{class} || '';
  my $action= $event->{action}|| '';
  my $URL   = $event->{URL}   || '';
  my $desc  = $event->{descr} || '';
  my $data  = $event->{data}  || '';

  if ( $data ) {
    my @items = split( /\n/, $data );
    $data = '<ul>';
    foreach ( @items ) { 
      if ( substr( $_, 0, 4 ) eq 'URL:' ) { next; }
      $data .= "<li>$_</li>";
    }
    $data .= "</ul>";
  }

  if ( $URL ) {
    if ( $desc ) {
      $desc = "<a href='$URL'>$desc</a>";
    } else {
      $desc = "<a href='$URL'>$URL</a>";
    }
  }
  my $trclass = '';
  if ( $type ) { $trclass = " class='$type'"; $type = "[ $type ] ";}
  if ( $action ) { $action = " - $action"; }

  return qq!<tr$trclass title='$date'><td>$type$class$action</td><td>$desc$data</td></tr>!;
}


sub present_orphan_event {
  my $event = shift;

  my $date  = $event->{date};
  my $time  = substr( $date, 11 );

  my $type  = $event->{type}  || '';
  my $class = $event->{class} || '';
  my $action= $event->{action}|| '';
  my $desc  = $event->{descr} || '';
  my $data  = $event->{data}  || '';
  my $chain = $event->{chain}   || '';
  my $se    = $event->{startend}|| '';

  my $trclass = 'orphan';
  if ( $type ) { $trclass .= " $type"; $type = "<small>[ $type ]</small> ";}
  if ( $action ) { $action = " - $action"; }

  return qq!<tr class='$trclass'><td>$time</td><td>$type$class$action</td><td>$desc</td><td>$data</td><td>$chain</td><td>$se</td></tr>!;
}


1;


