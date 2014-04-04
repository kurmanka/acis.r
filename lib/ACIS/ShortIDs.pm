package ACIS::ShortIDs;

#  This perl module is responsible for generation of unique short
#  (alpha-numeric) identifiers for records, as aliases for their 
#  (usually) long identifiers.

#  Copyright (c) 2003-2005 Ivan Kurmanov, ACIS project.
#  Copyright (c) 2002 Ivan Kurmanov and Ivan Baktcheev, RePEc project.
#  All rights reserved.
#
#  This program is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#

use strict;
use Carp qw( cluck croak );
use Carp::Assert;

use ACIS::ShortIDs::Local; ### 

use vars qw( $home_dir $print_out_new_ids $per_output_dir 
           );

###             $db_name $db_user $db_pass 

$print_out_new_ids = 0; # a flag for external usage

my $table_name_prefix = "sid_";

use vars qw( $sql_helper );

use sql_helper;

my $log_name  = $home_dir . '/short-id.log';

if ( not -d $home_dir ) {
  die "$home_dir is not a directory";
}

assert( -d $home_dir );


sub prepare {
 my $res = get_sql_helper();
 return $res;
}


sub problem {
  my $msg = join '', @_;
  open  PLOG, ">>$home_dir/problems.log";
  print PLOG scalar localtime, " ", $msg, "\n";
  close PLOG;
  croak $msg;
}



################    s u b   M A K E   S H O R T   I D    ######################

sub make_short_id {

  my $lid     = shift || die;  ### the long id
  my $type    = shift || die;
  my $key     = shift || die;
  my $letters = shift || 3;

  prepare();

  my $id = resolve_handle( $lid );
  if ( $id ) {  return $id;  }


  ### lock log file
  open ( LOG, '>> ' . $log_name )
    or problem "Can't open log file: $log_name";


  ### make up the id prefix

  my $prefix = lc substr( $type, 0, 1 );
  my $how_many_letters = $letters;

  if ( ( $key =~ tr/a-zA-Z// ) < $how_many_letters ) {
    eval q!
      require 5.006_008;
      require MIME::Base64;
      $key =~ s/[^\p{Letter}]//g;
      $key = MIME::Base64::encode_base64( $key );
    !;
    warn $@ if $@;
  }

  $key =~ s/[^A-Z]//ig;
  
  my $prefix_item = lc substr ( $key, 0, $how_many_letters );
  
  if ( not $prefix_item ) { 
    warn "Can't generate item-specific part of the short-id prefix! (id:$lid)";
    $prefix .= "z" x $how_many_letters;

  } else {
    $prefix .= $prefix_item;
  }
  
  finish_and_store_id( $lid, $prefix );
}



#
#  sub finish_and_store_id ( 
#

sub finish_and_store_id {
  my $longid = shift;
  $longid = lc $longid;

  my $prefix = shift;
  $prefix = lc $prefix;  ### convert all entries to lowercase

  my $number = get_lastnumber( $prefix );
  if ( not defined $number ) {
    $number = 1;
  } else { 
    $number ++;
  }

  my $id;
 GENERATE: 
  ### generate a valid (unique) short id
  my $failures = 0;  
  while ( 1 ) {
    $id = $prefix . $number;
    my $ok = store_id_handle( $id, $longid );
    
    if ( not $ok ) {
      $number++;  # increment counter
      $failures ++;
      if ( $failures > 80 ) {
        die "Too many failures at the short-id recording:".
        " ha:$longid, pref:$prefix, num:$number";
      } elsif ( $failures > 8 ) {
        $number += 73;
      } elsif ( $failures > 4 ) {
        $number += 7;
      }

      if ( $failures == 3 or $failures == 10 ) {
        my $sid = resolve_handle( $longid );
        if ( $sid ) {  return $sid;  }
      }
      next;  ### repeat
    }

    store_lastnumber( $prefix, $number );
    last;
  }


  ### log it all

  print LOG scalar localtime, " $longid => $id\n";

  if ( $print_out_new_ids ) {
    print scalar localtime, " $longid => $id\n";
  }


  ### unlock log file

  close LOG;

  return $id;
}



sub check_logfile {
  my $logfile  = shift;

  assert( -e $logfile and -r _ );

  open INLOG, "<$logfile"
    or return undef;
 
  prepare();

  my $items = 0;
  my $bad   = 0;
  while ( <INLOG> ) {
    if ( / ([^\s]+) => (.+)$/ ) {
      my $long = lc $1;
      my $sid  = lc $2;

      if ( $sid =~ m/[^\w\d]/ ) {
        print "l$. bad sid: $long => $sid\n" ;
        next;
      }
      $items++;

      my $_long = get_handle( $sid ) || 'undef';
      if ( $_long eq $long ) { next; }

      my $_sid  = get_id( $long ) || 'undef';
      
      print "l$. $long => $sid [$_sid, $_long]\n";

      $bad ++;

    }
  }


  close INLOG;
  return "$bad/$items";
}




sub read_logfile {
  my $logfile  = shift;
  my $clear_db = shift;
  my $dup_save = shift;

  assert( -e $logfile and -r _ );

  open INLOG, "<$logfile";
 
  prepare();

  if ( $clear_db ) {
    clear_database();
  }

  my $items = 0;
  while ( <INLOG> ) {
    if ( / ([^\s]+) => (.+)$/ ) {
      my $longid = lc $1;
      my $id     = lc $2;

      if ( $id =~ m/[^\w\d]/ ) {
        warn "at line $. there is a bad id: $id. skipping\n" ;
        next;
      }

      if ( not store_id_handle( $id, $longid ) ) {

        if ( get_handle( $id ) eq $longid ) {
          next;
        }
        
        if ( $dup_save ) {
          my $r = force_store_id_handle( $id, $longid );
          if ( not $r ) {
            die "Tried force_... but it failed.";
          }
        }
        warn "duplicate: id:$id, ha:$longid\n";
#        problem ( "can't save id & handle pair: $id, $longid" );
      }

      ### update the last_numbers table
      if ( $id =~ m/^([a-z]+)(\d+)$/ ) {
        my $prefix = $1;
        my $ln     = $2;
        store_lastnumber( $prefix, $ln );
      }

      $items++;
    }
  }


  close INLOG;
  return $items;
}






sub resolve_handle {
  my $longid = shift;
  $longid = lc $longid;

  prepare();

  return get_id( $longid );
}



sub resolve_id {
  my $id = shift;
  my $longid;

  $id = lc $id; 

  prepare();

  return get_handle( $id );
}
























#############################################################################
#####                        S T O R A G E  
#############################################################################

#####   Low-level database storage functions for short-ids follow.  Mysql
#####   implementation.


sub clear_database {
  prepare();
  create_tables( 1 );
}


sub get_sql_helper {
  if ( $sql_helper ) {
    return $sql_helper;
  }

  $sql_helper = sql_helper -> new( { 
                                    logfile => $home_dir . '/log/sql.log',
#                                    verbose_log => 1,
                                   },
                                   $db_name, 
                                   $db_user, 
                                   $db_pass );

  $sql_helper -> do( "SET CHARACTER SET utf8" );  ### XXX UTF8 in Mysql

  return $sql_helper;
}


sub create_tables {
  my $recreate = shift;
  my $success;

  prepare();

  my $sql    = $sql_helper || die;
  my $prefix = $table_name_prefix;

  if ( $recreate ) {
    foreach ( qw( id_to_handle last_numbers ) ) {
      $sql -> do( "drop table ${prefix}$_" );
    }
  }

  my $id_st = 
qq! create table ${prefix}id_to_handle ( id char(10) NOT NULL,
                                         handle char(160) NOT NULL,
 primary key ( id ),
 unique ( handle ) 
) !;

  my $ln_st = 
qq! create table ${prefix}last_numbers ( prefix char(6) primary key,
                                         number int unsigned NOT NULL ) !;

  my @statements = ( $id_st, $ln_st );

  my $errors = 0;
  foreach ( @statements ) {
    $sql -> prepare( $_ );
    my $res = $sql -> execute;
    if ( $sql -> error 
         or not $res ) {
#      warn $sql -> error; 
      $errors++;
    } else {
      $success++;
    }
  }
  

  if ( $errors ) {
    $success = 0;
  }

  return $success;
}


sub get_id {
  my $longid = shift;
  my $id;

  my $sql    = $sql_helper;
  my $prefix = $table_name_prefix;

  assert( $sql );

  my $st = "select id from ${prefix}id_to_handle where handle=?";
  if ( $sql -> prepare( $st ) ) {
    my $res = $sql -> execute( $longid );

    if ( $res ) {
      $id = $res -> {row} -> {id};
    } else {
#      warn $sql -> error;
    }
  }
  

  return $id;
}


sub get_handle {
  my $id = shift;
  my $longid;

  my $sql    = $sql_helper;
  my $prefix = $table_name_prefix;

  assert( $sql );
  my $st = qq! select handle from ${prefix}id_to_handle where id= ? !;
  if ( $sql -> prepare( $st ) ) {
    my $res = $sql -> execute( $id ) ;

    if ( $res ) {
      $longid = $res -> {row} -> {handle};
    } else {
#      warn $sql -> error;
    }
  }

  return $longid;
}


sub store_id_handle {
  my $id     = shift;
  my $longid = shift;
  my $success;

  my $sql    = $sql_helper;
  my $prefix = $table_name_prefix;

  assert( $sql );

  my $st = qq! insert into ${prefix}id_to_handle values (?,?) !;
  if ( $sql -> prepare( $st ) ) {
    my $res = $sql -> execute( $id, $longid ) ;

    if ( $res ) {
      $success = 1;
    } else {
#      warn $sql -> error;
    }
  }
  

  return $success;
}


sub force_store_id_handle {
  my $id     = shift;
  my $longid = shift;
  my $success;

  my $sql    = $sql_helper;
  my $prefix = $table_name_prefix;

  assert( $sql );

  my $st = qq! replace into ${prefix}id_to_handle values (?,?) !;
  if ( $sql -> prepare( $st ) ) {
    my $res = $sql -> execute( $id, $longid ) ;

    if ( $res ) {
      $success = 1;
    }
  }

  return $success;
}



sub get_lastnumber {
  my $idprefix = shift;
  my $number;

  my $sql    = $sql_helper;
  my $prefix = $table_name_prefix;

  assert( $sql );

  my $st = qq! select number from ${prefix}last_numbers where prefix= ? !;
  if ( $sql -> prepare( $st ) ) {
    my $res = $sql -> execute( $idprefix ) ;

    if ( $res ) {
      $number = $res -> {row} -> {number};
    } else {
#      warn $sql -> error;
    }
  }

  
  return $number;
}



sub store_lastnumber {
  my $idprefix = shift;
  my $number   = shift;
  my $success;

  my $sql    = $sql_helper;
  my $prefix = $table_name_prefix;

  assert( $sql );

  my $st = qq! replace into ${prefix}last_numbers values (?,?) !;
  if ( $sql -> prepare( $st ) ) {
    my $res = $sql -> execute( $idprefix, $number ) ;

    if ( $res ) {
      $success = 1;
    } else {
#      warn $sql -> error;
    }
  }


  return $success;
}


sub database_backup {
  my $home = $home_dir;

  prepare();
  
  use POSIX qw( strftime );

  my $datedir = strftime( "backup/%Y/%m-%d", localtime( time ) );

  my $backdir = "$home/$datedir";
  if ( not -e $backdir ) {
    assert( -e $home );
    my @parts = split( '/', $datedir );
    my @done;
    
    foreach ( @parts ) {
      if ( not $_ ) {
        next;
      }
      my $pre = $home . "/" . join( '/', @done ) . "/";
      $pre =~ s!/+$!/!g;
      mkdir "$pre$_", 0777;
      push @done, $_;
    }
  }

  my $success;

  my $sql    = $sql_helper;
  my $prefix = $table_name_prefix;

  assert( $sql );

  my $st = qq! backup table ${prefix}last_numbers,${prefix}id_to_handle to ? !;

  if ( $sql -> prepare( $st ) ) {
    my $res = $sql -> execute( $backdir ) ;

    if ( $res ) {
      $success = 1;

      if ( $res -> {row} ) {
        while ( $res -> {row} ) {
          my $row = $res->{row};
#          print "$row->{Table}\t$row->{Msg_type}\t$row->{Msg_text}\n";
          if ( $row->{Msg_type} eq 'status' 
               and $row->{Msg_text} ne 'OK' ) {
            $success = 0;
          }
          $res->next;
        }
      }
    }
  }


  return $success;
}


1;



__END__

