package ACIS::Web::Admin;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Experimental administrative access and control stuff for ACIS.
#
#
#  Copyright (C) 2003 Ivan Baktcheev, Ivan Kurmanov for ACIS project,
#  http://acis.openlib.org/
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

use strict;

use Carp::Assert;
use Data::Dumper;

use Storable qw( &retrieve );

use Web::App::Common;

use ACIS::Data::DumpXML qw(dump_xml);


sub check_access {
  my $acis = shift;
  my $allow_deceased_list_manager = shift || 0;

  # check for user's access
  if ( $acis -> load_session_if_possible ) {
    my $session = $acis -> session;
    
    if ( $session 
         and $session -> owner -> {type}
         and exists $session -> owner -> {type} {admin} ) {
      return 1;
    }

    if ($allow_deceased_list_manager) {
        if ( $session 
             and $session -> owner -> {type}
             and exists $session -> owner -> {type} {'deceased-list-manager'} ) {
            $acis->variables->{'deceased-list-manager-mode'} = 1;
            return 1;
        }
    }
  }

  $acis -> clear_process_queue;
  $acis -> respond_403;
  return 0;
}

sub check_access_allow_deceased_volunteer {
  my $acis = shift;
  my $check = check_access( $acis, 'allow deceased manager' );
}



sub show_sessions {
  my $acis = shift;
  my $current_time = time;
  my $home = $acis ->{paths} ->{home};
  my $sessions_dir = "$home/sessions";
  opendir SES, $sessions_dir;
  my @sessions = readdir SES;
  closedir SES;
  my @sl;
  foreach ( @sessions ) {
    my $id = $_;
    my $filename = "$sessions_dir/$_";
    next if not -f $filename or not -r _;
    my @filestat = stat $filename;
    my $mtime = $filestat[9];
    my $difference = $current_time - $mtime;  # in seconds
    my $about = {
                 id => $id,
                 filename => $filename,
                 diff => $difference,
                 };
    my $loaded;
    eval {
      $loaded = retrieve ($filename);
    };
    if ( not $@ and defined $loaded ) {
      my $name;
      my $login;
      if ( $loaded -> owner ->{name} ) {
        $name  = $loaded -> owner -> {name};
        $login = $loaded -> owner -> {login};
      } else {
        $name  = $loaded -> {'user-data'} {name};
        $login = $loaded -> {'user-data'} {login};
      }
      $about->{owner} = $name;
      $about->{login} = $login;
      $about->{type}  = $loaded -> type;
      push @sl, $about;
    }
  }
  $acis->variables->{'session-list'} = \@sl;
}




sub session_act {
  my $acis = shift;

  my $current_time = time;
  my $home = $acis ->{paths} ->{home};
  my $sessions_dir = "$home/sessions";

  my $input = $acis -> form_input;

  my $id = $input -> {id};
  my $action = "view";
  if ( $input ->{action} ) {
    $action = $input->{action};
  }

  if ( not $id 
       or ( $id =~ m!(/|\.)!g )
     ) {
    $acis ->error ( "id-bad-or-missing" );
    return undef;
  }

  my $filename = "$sessions_dir/$id";
  die "No session file: $filename" if not -f $filename or not -r _;

  if ( $action eq "view" ) {
    my @filestat = stat $filename;
    my $mtime = $filestat[9];
    my $difference = $current_time - $mtime;  # in seconds
    my $about = {
                 id => $id,
                 filename => $filename,
                 diff => $difference,
                };
    
    my $loaded;
    eval {
      $loaded = retrieve ($filename);
    };
    
    if ( not $@ and defined $loaded ) {
      $acis->variables->{se} = $about;
      
      if ( $loaded->{'.owner'}->{name} ) {
        $acis->variables->{se} -> {owner} = $loaded->{'.owner'};
        
      } else {
        $acis->variables->{se} -> {owner} = $loaded->{'user-data'}{owner};
      }      
      #    $acis->variables->{se} -> {contents} = $loaded;
      
      use Data::Dumper;
      #    my $session_text = dump_xml( $loaded );
      my $session_text = Dumper( $loaded );
      
      $acis->variables->{se} -> {text} = $session_text;
      
    }  
    return;

  } elsif ( $action eq "delete" ) {
    my $res = unlink $filename;
    
    if ( $res ) { 
      $acis -> success(1);
    }
    $acis -> set_presenter( "adm/session/deleted" );
  }
    
}





##########################################################################
###  do some work on a userdata   ########################################
##########################################################################

sub offline_userdata_service {
  my $acis  = shift || die;
  my $login = shift || die;
  my $func  = shift || die;
  my $rec   = shift; 
  # any other parameters, if given, will be passed to the $func function
  my $resu;

  debug "offline work for $login";
  my $paths = $acis ->{paths};
  my $session;
  my $userdata;
  $acis -> update_paths_for_login( $login );
  my $userdata_file = $paths -> {'user-data'} || die;
  eval {
    $userdata = get_hands_on_userdata( $acis );
  };

  if ( not $userdata ) {
    return undef;
  }

  ###  create a session for that user-data
  my $owner = {login=>$0, IP=>'0.0.0.0'};
  $session = $acis -> start_session( "magic", $owner,
                                     object => $userdata, 
                                     file   => $userdata_file );
                                     
  #$session -> set_userdata( $userdata, $userdata_file );
  #die Dumper( $session );

  # upgrade userdata, if necessary (esp. the owner part)
  require ACIS::Web::User;
  $acis -> userdata_bring_up_to_date();

  my $user = $session->userdata_owner;
  my $ulogin= $user   ->{login};

  $acis ->sevent ( -class => 'auth',
                  -action => 'granted',
                   -descr => 'offline service for account',
                   -file  => $userdata_file,
                   -login => $ulogin,
                 -process => $owner -> {login},
               -humanname => $user->{name},
       ($rec) ? ( -record => $rec ) : (),        
                 );

  $acis -> {'presenter-data'} {request} {user} {name}  = $user->{name};
  $acis -> {'presenter-data'} {request} {user} {pass}  = '######'; # XXX-Password
  $acis -> {'presenter-data'} {request} {user} {login} = $ulogin;
  
  if ( $rec ) {
    if ( not $session -> choose_record_by_id( $rec ) ) {
      debug "No such record $rec";
      $acis -> errlog( "No such record $rec" );
      die "can't run offline service for record $rec because the record is not found in account";
      return(undef);
    }
  }

  ### now do some compatibility checks/upgrades for the record
  require ACIS::Web::Person;
  my $record = $session -> current_record;
  if ( $record ->{type} eq 'person' ) {
    ACIS::Web::Person::bring_up_to_date( $acis, $record );
  }
  
  eval {
    no strict;
    $resu = &{ $func } ( $acis, @_ );
  };
  my $error = $@;

  ###  close session
  eval {
    $session -> close( $acis );
    $acis->clear_after_request();
  };
  $error ||= $@;

  if ( $error ) {
    debug "offline service failed: $error";
    $acis-> errlog( "offline service $func failed: $error" );
    die $error;
  }

  return $resu;
}



sub userdata_offline_reload_contributions {
  my $acis = shift;
  my $login = shift;

  debug "userdata_offline_reload_contributions() for $login";
  my $paths = $acis ->{paths};
  my $session;
  my $userdata;
  my $userdata_file;

  $acis -> update_paths_for_login( $login );
  $userdata = get_hands_on_userdata( $acis ) or return undef;

  ###  create a session for that userdata
  $session = $acis -> start_session( "magic", { login => $0, IP => '0.0.0.0' } );
  $session -> object_set( $userdata );
  
  ###  go through the records 
  my $num = 0;
  foreach ( @{ $userdata->{records} } ) {
    $session -> set_current_record_no( $num );
    ### do things here
    # for instance, reload the contributions:
    require ACIS::Web::Contributions;
    ACIS::Web::Contributions::reload_accepted_contributions( $acis );
    $num++;
  }

  ###  close session
  $session -> close( $acis );
  return $num;
}




sub get_hands_on_userdata {
  my $acis    = shift;
  my $userdata;
  my $paths            = shift || $acis -> paths;
  my $userdata_file    = $paths -> {'user-data'};
  my $userdata_lock    = $paths -> {'user-data-lock'};
  my $userdata_deleted = $paths -> {'user-data-deleted'};

  if ( not -f $userdata_file ) {
    die "no such file (or user): $userdata_file\n";
    return undef;
  }

  ###  need to check the lock
  my $lock = $userdata_lock;
 
  if ( -f $lock ) {
    debug "found lock file at '$lock'";
    my $sid; 
    my $home = $acis -> home;
    if ( open LOCK, $lock ) {
      $sid = <LOCK>;
      close LOCK;
      debug "locked by session $sid";
    }    

    ### go get the session, if it exists
    ### ignore the lock if it doesn't

    my $file = "$home/sessions/$sid";
    if ( not -f $file ) {
      debug "but session doesn't exist ($file)";
      goto AFTER_LOCK;
    }
    
    my $session = ACIS::Web::Session -> load( $acis, $file );
      
    if ( not defined $session or not $session ) {
      unlink $lock;
      debug "but session is not valid (can't load $file)";
      goto AFTER_LOCK;
    }
    
    debug "and in fact, there is a session";
    ###  does it belong to the user?
    if ( $session -> type eq 'user' 
         or $session -> type eq 'new-user' ) {
      ###  we can't go on -- the user is working on her account
    } else {
      ###  it is another session of ours or similar
      debug "neither user type, nor new-user type; strange";
    }
    return 0;
  }
 AFTER_LOCK:

  ###  load the userdata
  $userdata = load ACIS::Web::UserData( $userdata_file );
  my $owner = $userdata->{owner};

  if ( not defined $userdata
       or not defined $owner
       or not defined $owner->{login}
     ) {
    # a problem

    print "userdata is corrupt";
    return 0;
  }

  return $userdata;
}




sub user_republish {
  my $acis = shift;
  my $user = $acis -> form_input ->{login};
}


use ACIS::Web::Person;

sub move_records {
  my $acis = shift;
  my $src  = shift || die; 

  # $src is a list of items. Each item may be a short-id, or an ARRAY
  # of [ LOGIN, SHORTID ] pairs.

  my $session = $acis ->session;
  my $ud      = $session ->userdata;
  my $login   = $ud ->{owner} {login};
  my $dest    = $ud ->{records};
  my $moved   = [];

  debug "move records to $login account";
  debug "sources: @$src";
  
  foreach ( @$src ) {
    my $src_login;
    my $src_sid;

    if ( ref $_ eq 'ARRAY' ) {
        $src_login = $_->[0];
        $src_sid   = $_->[1];
    } else {
        $src_login = ACIS::Web::Person::get_login_from_person_id( $acis->sql_object, $_ );
    }

    if (not $src_login) {
        debug "no login for $_";
        next;
    }

    if ($src_login eq $login) {
        debug "source record $_ is already in the destination account $login!";
        next;
    }

    my $file = $acis ->userdata_file_for_login( $src_login );
    if ( not -e $file ) { 
      debug "no such file: $file";
      next;
    }
    
    if ( -e "$file.lock" ) {
      debug "account $src_login is locked";
      next;
    }

    require ACIS::Web::UserData;
    my $srcud = ACIS::Web::UserData -> load( $file );

    if ( not $srcud ) { next; }
    debug "opened $src_login userdata";
    
    my $srcrec = $srcud ->{records};
    my $should_remove = scalar @$srcrec;

    foreach ( @$srcrec ) {
      if ( $src_sid 
           and ($src_sid ne $_->{sid}) ) { 
          debug "skipping $_->{sid}";
          $should_remove = 0;
          next; 
      }

      my $name = $_ ->{name}{full};
      debug "record of $name: moving it";
      delete $_ -> {'about-owner'};

      # the add_record_to_userdata() is a more careful way to do the same:
      #push @$dest, $_;
      $session -> add_record_to_userdata( $_ );
      push @$moved, $_;
    }

    ### XXX this could be deferred until the session end.
    ### XXX run it via ->run_at_close()?
    if ( $should_remove ) {
        ACIS::User::remove_account( $acis, -login => $src_login );
    }
    if ( scalar @$dest > 1 ) {
      $ud ->{owner} {type} {advanced} = 1;
    }
    
  }

  return $moved;
}




sub move_record_handler {
    my $acis = shift;
    my $session = $acis->session || die;
    my $input   = $acis->form_input;

    my $is_admin = 1; ### could be 0 if the user is a deceased account volunteer
    #my $deceased = 1;

    #my $to = $input->{to};
    #if ( $to 
    #     and not $is_admin
    #     and $session->owner->{login} eq $to ) {
    #    die "only admin 

    # here we would move a record from another account into this
    # current account.
    my $from = $input->{from} || die;
    my $sid  = $input->{sid}  || die;
    
    debug "move record $sid from account $from";

    my $ret = move_records( $acis, [ [$from, $sid] ] );
    
    debug "got return from move_records(): $ret";
    if ( scalar @$ret
         and $ret->[0] ) {
        $acis->success(1);
        $acis->variables->{'new-record-sid'}  = $sid;
        $acis->variables->{'new-record-name'} = $ret->[0]{name}{full};
    } else {
        $acis->success(0);
    }

}




######################################################################
###   DATABASE ACCESS
######################################################################

my $wa;
my $vars ; 
my $input;
my $sql  ;
my $sql_res;
my $query;
my $result;
my $res_decode_func;

sub prepare_env {
  my $app = shift;

  $wa    = $app;
  $input = $app -> form_input;
  $sql   = $app -> sql_object;
  $vars  = $app -> variables;
  $result  = $vars -> {result} = {};
  $sql_res = 0;
  $query   = {};

  $ACIS::Web::Contributions::DB = $app -> config( 'metadata-db-name' );

}


sub sql_query_analyze {
  my $body  = $input -> {body};

  my @para;
  foreach( qw( par1 par2 par3 par4 ) ) {
    if ( $input ->{$_} ) {
      push @para, $input ->{$_};
    }
  }

  sql_query_execute( $body, @para );  
  build_general_results_table( );
}


sub sql_query_execute {
  my $query  = shift;
  my @para   = @_;

  my $vars   = $wa -> variables;

  my $pre_res = $sql -> prepare( $query );
  if ( not $pre_res ) {
    $result -> {problem} {'bad-statement'} = 1;
  }
  
  debug( "execute with @para" );
  $sql_res = $sql -> execute( @para );
  
  if ( not $sql_res ) {
    $result -> {problem} {response} = $sql->error;
  }
  return $sql_res;
}





sub build_general_results_table {
  my $res = $sql_res;
#  my $row_decode = \&make_list_from_db_row();

  if ( not $res ) {
    return undef;
  }

  my $columns = [];
  my $data    = [];

  $columns = $res -> {sth} {NAME};
  
  my $rrow = $res -> {row};
  if ( $rrow ) {

    while ( $rrow ) {
      my $item = make_list_from_db_row( $rrow, $columns, 1 );
      push @$data, $item;
      $rrow = $res -> next;
    }
      
  } else {
    
    $result -> {problem} {'empty-result'} = 1;
    $res -> finish;
    return undef;
  }
  $res -> finish;
  
  $result -> {columns} = $columns;
  $result -> {data}    = $data; 
}





use Encode;

sub make_list_from_db_row {
  my $row = shift;
  my $col = shift;
  my $decode = shift;
  my @res = ();

  foreach ( @$col ) {
    my $val = $row -> {$_};
    my $dec;
#    if ( $val =~ /\x01/ and $_ ne 'data' ) {
#      $val =~ s/^\x1|\x1$//g;
#      $val =~ s/\x1/ & /g;
#    }
    if ( $_ ne 'data' 
         and $decode ) {
      $dec = decode( 'utf8', $val, Encode::FB_PERLQQ );

      if ( not $dec and $val ) {
        $dec = $val;
      }

    } else {
      $dec = $val;
    }
    push @res, $dec;
  }

  return \@res;
}










#################################################################
###   A D M / S E A R C H 
#################################################################

sub adm_search {
  my $app = shift;
  prepare_env( $app );
  
  my $for = $input -> {for};
  $for =~ s/[^\w]//g;

  if ( $for ) {
    { 
      no strict;
      &{ "adm_search_for_$for" }(  );
    }
    if ( $@ ) { 
      $app -> error ( "adm-search-problem" );
      $app -> variables -> {'dollar-at'} = $@;
    }
  }
}


sub analyse_search_parameters {
  my $select_what = $input -> {show} || '*'; 
  my $limit       = $input -> {limit};
  my $field       = $input -> {by};
  my $value       = $input -> {key};

  my $operator;
  
  if ( $input -> {op} ) {
    $operator = $input -> {op};

  } else {
    if ( $value =~ m!%! ) {
      $operator = "LIKE";
    } else {
      $operator = "=";
    }
  }
  
  $query = my $q = {
                    what  => "select $select_what ",           
                   };

  if ( $limit ) {
    $q -> {limit} = " LIMIT $limit";
  }

  if ( $field and $operator and $value ) {
    $q -> {where} = " where $field $operator ? ";
  }

  return $q;
}


sub adm_search_for_documents {
  
  my $q = analyse_search_parameters( );  

  my $table;

  my $by    = $input -> {by};
  my $value = $input -> {key};

  my $ope;
  if ( $value =~ m!%! ) {
    $ope = " LIKE ";
  } else {
    $ope = "=";
  }
  
  my $query;
  my $where;

  if ( $by eq 'id' )         { 
    $table = "resources";    
    $where = "catch.id$ope?";

  } elsif ( $by eq 'title' ) { 
    $table = "resources";    
    $where = "match( catch.title ) against ( ? )";

  } elsif ( $by eq 'creator' ) { 
    $table = "res_creators_separate"; 
    $where = "catch.name$ope?";

  } elsif ( $by eq 'creators' ) {
    $table = "res_creators_bulk"; 
    $where = "catch.names$ope?";
  }
  
  my $db = $wa -> config( 'metadata-db-name' );
 
  if ( $where ) {
    $where .= $q->{limit};
    require ACIS::Resources::Search;
    $query = ACIS::Resources::Search::query_resources( $table, $where );
  }

  debug "QUERY: $query";
  $result -> {query} = $query;

  if ( sql_query_execute( $query, $value ) ) {
    build_result_document_list( );
  }

  $wa -> clear_process_queue;
  $wa -> set_presenter( "adm/search/doc" );
}


sub build_result_document_list {

  my $res = $sql_res;

  if ( not $res ) {
    return undef;
  }

  my $columns = [];
  my $data    = [];

  $columns = $res -> {sth} {NAME};
  
  my $rrow = $res -> {row};
  if ( $rrow ) {

    while ( $rrow ) {
      my $item = $rrow;
# make_list_from_db_row( $rrow, $columns, 1 );

      ## schmorp
      #use Storable qw( thaw );
      use ACIS::Data::Serialization;     
      if ( $item -> {data} ) {
        #my $packed = eval {thaw( $item -> {data}); };
        my $packed=inflate($item-> {'data'});
        foreach ( keys %$packed ) {
          my $val = $packed -> {$_};
          $item -> {$_} = $val;
        }
        delete $item -> {data};
      }
      ## /schmorp

      push @$data, $item;
      $rrow = $res -> next;
    }
      
  } else {
    
    $result -> {problem} {searched} = 'found nothing';
    $res -> finish;
    return undef;
  }
  $res -> finish;
  
  $result -> {columns} = $columns;
  $result -> {data}    = $data; 
}



sub adm_search_for_records {
  
  my $q = analyse_search_parameters( );  

  my $table;

  my $by  = $input -> {by};
  my $key = $input -> {key};
  
  $table = 'records';

  my $query_text = join( '', 
                    $q -> {what} || '',
                    " from $table ",
                    $q -> {where} || '',
                    $q -> {limit} );


  debug "QUERY: $query_text";

  $result -> {query} = $query_text;
  $result -> {key}   = $key;

  if ( sql_query_execute( $query_text, $key ) ) {
    build_general_results_list( 1 );

  } else {
    debug "no result";
  }

  $wa -> clear_process_queue;
  $wa -> set_presenter( "adm/search/rec" );
}


sub adm_search_for_users {
  
  my $q = analyse_search_parameters( );  

  my $table;

  my $by  = $input -> {by};
  my $key = $input -> {key};
  
  $table = 'users';

  my $query_text = join( '', 
                    $q -> {what} || '',
                    " from $table ",
                    $q -> {where} || '',
                    $q -> {limit} );


  debug "QUERY: $query_text";

  $result -> {query} = $query_text;
  $result -> {key}   = $key;

  if ( sql_query_execute( $query_text, $key ) ) {
    build_general_results_list( 1 );

  } else {
    debug "no result";
  }

  $wa -> clear_process_queue;
  $wa -> set_presenter( "adm/search/usr" );
}


sub adm_search_person {
  my $app = shift;
  my $table;
  my $key = $input -> {key};  
  if ($key =~ /.+@.+/ ) {
      # email
      $input ->{by} = 'owner';
  } elsif ($key =~ /^p\w+\d+/) {
      # shortid
      $input ->{by} = 'shortid';

  } elsif ( length $key > 3) {
      $key = $input->{key} = "\%$key\%";
      $input ->{by} = 'owner';

  } else {
      die "We need a short-id or an email; '$key' does not look like either";
  }

  $table = 'records';
  $input->{show} = 'shortid,id,owner,userdata_file,namefull,profile_url';

  my $q = analyse_search_parameters( );
  my $query_text = join( '', 
                    $q -> {what},
                    " from $table ",
                    $q -> {where} || '',
                    $q -> {limit} || '');
  debug "QUERY: $query_text";
  $result -> {query} = $query_text;
  $result -> {key}   = $key;

  if ( sql_query_execute( $query_text, $key ) ) {
    build_general_results_list('DECODE_UTF8');
  } else {
    debug "no result";
  }

  #$app -> set_presenter( "adm/search/rec" );
  #$app -> set_presenter( "adm/sql" );
}



sub build_general_results_list {
  my $decode_utf8 = shift;

  my $res = $sql_res;

  if ( not $res ) {
    return undef;
  }

  require Encode;
  
  my $columns = [];
  my $data    = [];

  $columns = $res -> {sth} {NAME};
  
  my $rrow = $res -> {row};
  if ( $rrow ) {

    if ( $decode_utf8 ) {

      while ( $rrow ) {
        my $item = $rrow;
        push @$data, $item;
        
        foreach ( keys %$item ) {
          # exclude emailmd5 column, it is in latin1
          next if $_ eq 'emailmd5';
          $item -> {$_} = Encode::decode_utf8( $item ->{$_} );
        }
        $rrow = $res -> next;
      }

    } else {

      while ( $rrow ) {
        my $item = $rrow;
        push @$data, $item;
        $rrow = $res -> next;
      }
    }
   
  } else {
    
    $result -> {problem} {searched} = 'found nothing';
    $res -> finish;
    return undef;
  }
  $res -> finish;
  
  $result -> {columns} = $columns;
  $result -> {data}    = $data; 
}




sub dump_presenter_data {
  my $app = shift;
  $app -> print_http_response_headers;
  $app -> set_presenter( 0 );
  
  print q!
<html>
 <head>
  <title>data dump</title>
 </head>
 <body>
  <h1>data dump</h1>

!;

  use ACIS::Data::DumpXML qw(dump_xml);

  my $data        = $app ->{'presenter-data'};
  my $data_string = dump_xml( $data );
  
  $data_string =~ s/&/&amp;/g;
  $data_string =~ s/</&lt;/g;
  $data_string =~ s/>/&gt;/g;
  
  print "<pre>$data_string</pre>";
  
}


sub test_message {
  my $acis = shift;
  $acis -> message( 'test' );
}

sub refresh_test {
  my $acis = shift;
  $acis -> refresh( 4, "" );
}


sub adm_get {
  my $app = shift;
  my $request = $app -> {request} {subscreen} || '';
  my $input = $app->form_input;

  if ( $request 
       and $request =~ m!^(\w+)/(.+?)(/(rec|record|hist|history|ardb))?$! ) {
    my $col = $1;
    my $id  = $2;
    my $op  = $4 || '';

    $input ->{id} = $id;
    $input ->{col} = $col;
    $input ->{op} = $op;
    debug "from URL: col:$col, id:$id, op:$op";
  }


  my $var = $app ->variables;
  my $op  = $input -> {op} || 'hist';
  my $id  = $input -> {id};
  my $col = $input -> {col};

  if ( not $id or not $col ) {
    return;
  }

  debug "get id:$id from $col, op:$op";
  
  my $data;

  ### $op is one of 'rec' | 'hist' | 'ardb' 
  if ( $op eq 'rec'
       or $op eq 'record' ) {

    require RePEc::Index::Reader;
    my $reader = RePEc::Index::Reader -> new( $col );
    $data = $reader -> get_record( $id );

    if ( not $data ) { $var -> {nosuchrecord} = 1; }
    else {
      $var -> {record}  = $data ->[0];
      $var -> {type}    = $data ->[1];
      if ( $reader -> get_conflict( $id ) ) {
        $var -> {conflict} = 1;
      }
    }

  } elsif ( $op eq 'hist' 
            or $op eq 'history' ) {

    require RePEc::Index::Reader;
    my $reader = RePEc::Index::Reader -> new( $col );
    $data = $reader -> get_history( $id );

    if ( not $data ) { $var -> {nosuchrecord} = 1; }
    else {
      resolve_times_in_history( $data );
      $var -> {history}  = $data;
      if ( $reader -> get_conflict( $id ) ) {
        $var -> {conflict} = 1;
      }
    }

  } elsif ( $op eq 'ardb' ) {

    require ARDB;
    require ARDB::Local;
    $var -> {ardb}   = 1;
    my $ardb = ARDB-> new();
    $data = $ardb -> get_record( $id );
    if ( not $data ) { $var -> {nosuchrecord} = 1; }
    else {
      $var -> {record} = $data;
    }

  } else {
    $app -> error( "unclear-function-to-get" );
  }

}


# i don't use these anymore
sub get_ri_record {
  my $col  = shift;
  my $id   = shift;

  require RePEc::Index::Reader;
  my $reader = RePEc::Index::Reader -> new( $col );
  
  return $reader -> get_record( $id );
}

# i don't use these anymore
sub get_ri_history {
  my $col  = shift;
  my $id   = shift;

  require RePEc::Index::Reader;
  my $reader = RePEc::Index::Reader -> new( $col );
  return $reader -> get_history( $id );
}


sub resolve_times_in_history {
  my $hist = shift;
  
  my $present = $hist ->{present};
  foreach ( @$present ) {
    $_ ->[3] = localtime( $_->[3] );
  }

  my $history = $hist ->{history}; 
  foreach ( @$history ) {
    $_ ->[0] = localtime( $_->[0] );
  }
 
  for ( 
       $hist ->{last_processed},
       $hist ->{last_changed},
       $hist ->{session_time}
      ) {
    if ( $_ ) {
      $_ = localtime( $_ );
    }
  }
}

# admin-in-disguise feature, /adm/log-into screen

sub adm_log_into {
    my $app = shift;
    my $request = $app -> request;
    my $target_login = $app -> form_input -> {login} || die;
    my $session = $app -> session;
 
    # XXX should show an error message (or an explanation) instead
    die if not $session;
    my $owner = $session->owner;

    # now check if the target account (userdata) is available
    my $paths = $app ->make_paths_for_login( $target_login );
    my $ud_file = $paths->{'user-data'};
    my $ud = get_hands_on_userdata( $app, $paths );

    # now grab it, or complain and quit
    die "the userdata file $ud_file is locked, or something is wrong"
        if not $ud;
    
    # now log off the current session
    # $session is the old session
    $app -> logoff_session;
    
    # now create a new session, with the needed type and owner and object and objectsavefileto
    ###  create a session for that user-data
    $owner->{'logged-in-as'} = $target_login;

    my $session_new = $app -> start_session( "admin-user", $owner );
    $session_new -> object_set( $ud );

    my $user   = $ud->{owner};
    
    $app ->sevent ( -class => 'auth',
                  -action => 'granted',
                   -descr => 'admin entering into a user account',
                   -file  => $ud_file,
                   -login => $target_login,
                -realuser => $owner -> {login},
               -humanname => $user->{name},
                 );

    # make this new session the current session

    # redirect to the record's menu
    $app -> redirect_to_screen( "/welcome" );

} 

1;
