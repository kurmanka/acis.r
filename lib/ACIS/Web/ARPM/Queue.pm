package ACIS::Web::ARPM::Queue;
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Automatic Research Profile Update Queue management
#
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
#  $Id: Queue.pm,v 2.2 2007/03/05 23:39:53 ivan Exp $
#  ---


use strict;
use ACIS::Web::ARPM qw( logit );

use sql_helper;

my $table_name = "arpm_queue";
use vars qw( $arpu_threshold_hours );

$arpu_threshold_hours = 24;

use ACIS::APU qw( logit push_item_to_queue );


sub task_prepare {
  my $acis = shift;

  my $sql = $acis -> sql_object;
  
  my $r = $sql -> do( "create table $table_name " .
                      " ... )" );

  print +($r) ? "OK" : "FAIL";
  print "\n";
}
  
my $error_count = 0;
sub error {
  my $message = shift;
  logit "ERR: $message";
  if ( $error_count > 15 ) {
    die "too many errors";
  }
  $error_count ++;
}

sub task_queue {
  my $acis = shift;
  my $sql  = $acis -> sql_object;
  ACIS::Web::ARPM::interactive();
  while ( my $item = shift @ARGV ) {
    push_item_to_queue( $sql, $item );
  }
}

use Carp::Assert;




use Carp::Assert;
use ACIS::Web::SysProfile;



sub task_init_lastautosearch {
  my $acis = shift;
  my $sql  = $acis -> sql_object;

  $sql -> prepare( q!
SELECT 
       r.shortid as sid,
       r.id as id,
       r.owner as owner
FROM 
       records as r 
LEFT JOIN 
       sysprof as s 
   ON 
       s.id = r.shortid 
     AND 
       s.param = 'last-autosearch-time'    
WHERE  
       s.data is NULL
!);

  my $r    = $sql -> execute;
  my $data = $r   -> {row};
  while ( $data ) {

    my $id  = $data -> {id};
    my $sid = $data -> {sid};
    my $usr = $data -> {owner};

    assert( $id );

    if ( not $sid ) {
      print "record $id has no shortid; ignoring\n";
      next;
    }
    assert( $sid );
    assert( $usr );

    print "id: $id, sid: $sid, user: $usr\n";

    my $file = $acis -> userdata_file_for_login( $usr );
    my $ud;

    assert( $file );

    if ( -e "$file.lock" ) {
      print "account locked, skipping\n";
      next;
    }

    if ( open UD, "<:utf8", $file ) {
#      my @l = <UD>;
#      my $data = join '', @l;
      close UD;
      require ACIS::Web::UserData;
      $ud = ACIS::Web::UserData -> load( $file );
      
    } else { 
      warn "Can't open $file for reading";
      next;
    }
    assert( $ud );
    
    my $records = $ud -> {records};
    my $found;
    my $last_autosearch_time;
    foreach ( @$records ) {
      if ( lc( $_->{id} ) eq lc $id ) {
        $found = $_;
        my $c;
        if ( ( $c = $_ -> {contributions} )
             and $c -> {autosearch} ) {
          $last_autosearch_time = $c -> {autosearch} {'last-time-epoch'};
        }
      }
    }

    if ( not $found ) {
      print "didn't find a matching record.\n";
      print "found: ";
      foreach ( @$records ) {
        print $_->{id}, ' ';
      }
      print "\n";
      print "looked for: $id\n";
      next;
    }      

    if ( $last_autosearch_time ) {
      ### put it into sysprof
      put_sysprof_value( $sid, 'last-autosearch-time', 
                         $last_autosearch_time );
      print "OK: $last_autosearch_time\n";

    } else {
      print "didn't find last autosearch time\n";
      push_item_to_queue( $sql, $usr );
      
    }
      

  } continue {
    $data = $r -> next;
  }

}




my $acis;
my $sql;
my @to_process;

sub prepare_to_process_queue {
  my $size = shift;

#  $sql -> {verbose_log} = 1;

  logit "prepare the process queue: size=$size";

  my $get = ($size < 3) ? 6 : $size * 2;

  my @skipped; 
  my @to_process_logins;
  my @items;

  my $run = 0;
  my $out = 0;
  my $by_lastsearch;

  my $r;

  $sql -> prepare( qq!
SELECT what 
FROM $table_name 
WHERE status = '' 
ORDER BY class DESC,filed ASC
LIMIT $get ! );
  $r = $sql -> execute;



  while ( 1 ) {
    
    my $item = $r -> {row} {what};
    if ( $item ) {

      if ( $by_lastsearch ) {
        my $last = $r -> {row} {data};
        assert( $last );

        my $now  = time;
        if ( $now - $last <= $arpu_threshold_hours * 60 * 60 ) {
#          logit "skipping $item";
          push @skipped, $item;
          next;
        }
      }

      my $login = get_login_from_queue_item( $acis, $item );
      if ( $login ) {
        push @items, $item;
        push @to_process, [ $login, $item ];
        push @to_process_logins, $login;
 #       logit "to_process: $login";
        $get--;

      } else {
        if ( not $by_lastsearch ) {
          $sql -> prepare_cached( "delete from $table_name where what=?" );
        } else {
          $sql -> prepare_cached( "delete from sysprof where id=?" );
        }
        $sql -> execute( $item );
        logit "cleared bogus queue item: $item";
      }
    }

    if ( not $get ) { last; }

  } continue {
    
    if ( not $r -> next ) {

      if ( $by_lastsearch ) { last; }
      
      undef $r; 
      $by_lastsearch = 1;
      $sql -> prepare( qq!
SELECT id as what,data 
FROM sysprof 
WHERE param = 'last-autosearch-time' 
ORDER BY data+1 ASC
LIMIT $get
! );
      $r = $sql -> execute;
    }  

  }

  logit "to process: ", join( ' ', @items  );
  if ( scalar @skipped ) {
    logit "skipped   : ", join( ' ', @skipped );
  }
}



sub get_next_queued_item {

  $sql -> prepare_cached( qq!
SELECT what 
FROM $table_name 
WHERE status = '' 
ORDER BY class DESC,filed ASC
LIMIT 1! );
  my $r = $sql -> execute;
    
  if ( $r ) {
    my $item = $r -> {row} {what};
    
    if ( $item ) {
      my $login = get_login_from_queue_item( $acis, $item );
      if ( $login ) {
        return $login;
      }
    }
  }

  $r -> finish;

  logit "give sysprof table a try\n";

  $sql -> prepare_cached( qq!
SELECT id,data 
FROM sysprof 
WHERE param = 'last-autosearch-time' 
ORDER BY data+1 ASC
LIMIT 1
! );
  $r = $sql -> execute;
  if ( $r ) {
    my $item = $r -> {row} {id};
    my $last = $r -> {row} {data};

    assert( $item );
    assert( $last );
    $r -> finish;

    print "$item, $last?\n";
        
    my $now  = time;
    if ( $now - $last > $arpu_threshold_hours * 60 * 60 ) {
      my $login = get_login_from_queue_item( $acis, $item );
      logit "yes: $login\n";
      return $login;
    }
  }
  $r -> finish;
   

  return undef;
}


  
sub task_work_by_queue {
  $acis = shift;

  my $number = 1;
  
  if ( scalar @ARGV ) {
    $number = shift @ARGV;
  }
  
  $sql = $acis -> sql_object;

  prepare_to_process_queue( $number );

  while ( $number ) {
    my $qitem = shift @to_process;
    my $login = $qitem -> [0];
    $qitem    = $qitem -> [1];
    my $res;
    my $notes;

    if ( $login ) {

      if ( $qitem ne $login ) { 
        logit "about to process: $qitem ($login)";
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

        $res   = ACIS::Web::Admin::offline_userdata_service
          ( $acis, $login, 'ACIS::Web::ARPM::search', $qitem );
      };
      if ( $@ ) {
        $res   = "FAIL"; 
        $notes = $@;
      }

      if ( $res ) {
        set_queue_item_status( $sql, $qitem, $res, $notes );
        $number--;
      }
      
    } else {
      last; 
    }


  } continue {
    $acis -> clear_after_request();
  }
  
}




sub task_test_set_queue_item_status {
  my $acis = shift;
  my $sql  = $acis -> sql_object;
  
  my $file = shift @ARGV;
  
  set_queue_item_status( $sql, $file, "TEST" );

}


sub task_reset_queue_item_status {
  my $acis = shift;
  my $sql  = $acis -> sql_object;
  
  my $file = shift @ARGV;

  set_queue_item_status( $sql, $file, "" );

}

sub set_queue_item_status {
  my $sql  = shift;
  my $item = shift;
  my $stat = shift;
  my $notes = shift;

  $sql -> prepare_cached( 
qq!
REPLACE INTO $table_name 
    ( what, status, notes, worked ) 
VALUES 
    ( ?, ?, ?, NOW() )
! );

  my $res = $sql -> execute( $item, $stat, $notes );
}


sub task_work {
  my $acis = shift;

  foreach ( @ARGV ) {
    my $item = $_;
    
    my $login = get_login_from_queue_item( $acis, $item );

    my $res;
    my $notes;

    if ( $login ) {

      require ACIS::Web::Admin;

      eval {
        ###  get hands on the userdata (if possible),
        ###  create a session and then do the work
        
        $res = ACIS::Web::Admin::offline_userdata_service
          ( $acis, $login, 'ACIS::Web::ARPM::search' );
      };
      if ( $@ ) {
        $res = "FAIL"; 
        $notes = $@;
      }

      logit "$item: $res";
      if ( $notes ) { 
        logit "$notes";
      }
      
    }

  }
  
}


################

sub get_login_from_queue_item {

  my $acis = shift;
  my $item = shift;
  my $login;
#  print "get login for $item\n";

  if ( length( $item ) > 8 
       and $item =~ /^.+\@.+\.\w+$/ ) {

    return lc $item;

  } else {

    my $sql = $acis -> sql_object;

    if ( length( $item ) > 15
         or index( $item, ":" ) > -1 ) {

#      print "is it an identifier?\n";
      $sql -> prepare( "select owner from records where id=?" );
      my $r = $sql -> execute( lc $item );
      if ( $r and $r -> {row} ) {
        $login = $r ->{row} {owner};

      } else {
        logit "get_login_from_queue_item: id $item not found";
      }

    } elsif ( $item =~ m/^p[a-z]+\d+$/ 
              and length( $item ) < 15 ) {

#      print "is it an sid?\n";
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


1;
