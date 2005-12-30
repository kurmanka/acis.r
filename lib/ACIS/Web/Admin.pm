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
#  ---
#  $Id: Admin.pm,v 2.0 2005/12/27 19:47:39 ivan Exp $
#  ---



use strict;

use Carp::Assert;
use Data::Dumper;

use Storable qw( &retrieve );

use Web::App::Common;

use ACIS::Data::DumpXML qw(dump_xml);


my $current_time = time;


sub show_current_time {
  my $acis = shift;
  $acis -> variables -> {'current-time'} = $current_time;
}



sub check_access {
  my $acis = shift;

  my $cgi  = $acis -> request -> {CGI};
  
  my $pass    = $acis -> config( 'admin-access-pass' );

  if ( $pass and length( $pass ) > 5 ) { 

    my $form_input = $acis -> form_input();
    my $param   = $form_input -> {pass};
    my $cookie  = $cgi -> cookie( 'admin-pass' );
    
    if ( $param and $form_input -> {'remember-me'} ) {
      $acis -> set_cookie( -name  => 'admin-pass', 
                           -value => $param,
                           -expires => '+1M' );
    }

    if ( $cookie and $cookie eq $pass ) {  return 1;  }
    
    if ( $param and $param eq $pass ) {    return 1;  }

  }


  {
    if ( $acis -> load_session_if_possible ) {
       
      my $session = $acis -> session;
      if ( $session 
           and $session -> owner -> {type}
           and exists $session -> owner -> {type} {admin} ) {
        return 1;
      }

    }
  }


  $acis -> clear_process_queue;
  $acis -> set_presenter( 'adm/pass' );
  return;
}




sub show_sessions {
  my $acis = shift;

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



use CGI qw( :standard );

sub session_act {
  my $acis = shift;

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
  my $resu;

  debug "offline work for $login";

  my $paths = $acis ->{paths};

  my $session;
  my $userdata;
  my $userdata_file;

  $acis -> update_paths_for_login( $login );

  eval {
    $userdata = get_hands_on_userdata( $acis );
  };

  if ( not $userdata ) {
    return undef;
  }

  ###  create a session for that user-data
  
  my $owner = { login => $0 };
  $owner -> {'IP'} = '0.0.0.0';
  
  $session = $acis -> start_session ( "magic", $owner );
  $session -> object_set( $userdata );

  my $user = $userdata->{owner};
  my $ulogin= $user   ->{login};
  my $udata_file = $acis -> paths -> {'user-data'};

  $acis ->sevent ( -class => 'auth',
                  -action => 'granted',
                   -descr => 'offline service for account',
                   -file  => $udata_file,
                   -login => $ulogin,
                 -process => $owner -> {login},
               -humanname => $user->{name},
       ($rec) ? ( -record => $rec ) : (),                   
                 );

  $acis -> {'presenter-data'} {request} {user} {name}  = $user->{name};
  $acis -> {'presenter-data'} {request} {user} {pass}  = $user->{password};
  $acis -> {'presenter-data'} {request} {user} {login} = $ulogin;
  
  if ( $rec ) {
    if ( not $session -> choose_record( $rec ) ) {
      $acis -> errlog( "Can't choose record $rec" );
    }
  }

  ### now do some compatibility checks/upgrades for the record
  {
    use ACIS::Web::Person;
    my $record = $session -> current_record;
    if ( $record ->{type} eq 'person' ) {
      ACIS::Web::Person::bring_up_to_date( $acis, $record );
    }
  }
  
  eval {
    no strict;
    $resu = &{ $func } ( $acis );
  };
  if ( $@ ) {
    debug "offline service failed: $@";
  }

  ###  close session

  $session -> close( $acis );
  return $resu;
}



sub userdata_offline_reload_contributions {
  my $acis = shift;
  my $login = shift;


  debug "offline work for $login";

  my $paths = $acis ->{paths};

  my $session;
  my $userdata;
  my $userdata_file;

  $acis -> update_paths_for_login( $login );

  $userdata = get_hands_on_userdata( $acis );

  if ( not $userdata ) {
    return undef;
  }

  ###  create a session for that user-data
  
  my $owner = { login => $0 };
  $owner -> {'IP'} = '0.0.0.0';
  
  $session = $acis -> start_session ( "magic", $owner );
  $session -> object_set( $userdata );

  
  ###  do maintenance

  {
    ###  loop around records for records' maintenance
    my $num = 0;
    foreach ( @{ $userdata->{records} } ) {
      $session -> set_current_record_no( $num );

      ### do the record maintenance here

      # for instance, reload the contributions:
      require ACIS::Web::Contributions;
      ACIS::Web::Contributions::reload_accepted_contributions( $acis );

      $num ++;
    }
  }


  ###  close session

  $session -> close( $acis );
  
}




sub get_hands_on_userdata {
  my $acis    = shift;

  my $userdata;

  my $paths            = $acis -> paths;

  my $userdata_file    = $paths -> {'user-data'};
  my $userdata_lock    = $paths -> {'user-data-lock'};
  my $userdata_deleted = $paths -> {'user-data-deleted'};

  if ( not -f $userdata_file ) {
    # no such user 
#    print "no such file (or user): $userdata_file\n";
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
      ###  we can't go on -- the user is working on the userdata
    
    } else {
      ###  it is another session of ours or similar
      debug "and in fact, there is a session";
      
    }
#    print "userdata is locked\n";
    return 0;
  }
 AFTER_LOCK:


  ###  load the userdata

  $userdata = load ACIS::Web::UserData ( $userdata_file );

  if ( not defined $userdata
       or not defined $userdata->{owner}
       or not defined $userdata->{owner}{login}
       or not defined $userdata->{owner}{password} 
     ) {
    # a problem

    print "userdata is corrupted";
    return 0;
  }

  return $userdata;
}




sub user_republish {
  my $acis = shift;

  my $user = $acis -> form_input ->{login};
  
}



sub move_records {
  my $acis = shift;
  
  my $src  = main::get_sources();

  my $session = $acis ->session;
  my $ud      = $session ->object;
  my $login   = $ud ->{owner} {login};
  my $dest    = $ud ->{records};

  debug "move records to $login account";
  debug "sources: @$src";
  
  foreach ( @$src ) {
    my $l = $_;
    
    my $file = $acis ->userdata_file_for_login( $l );
    if ( not -e $file ) { 
      debug "no such file: $file";
      next;
    }
    
    if ( -e "$file.lock" ) {
      debug "account $l is locked";
      next;
    }

    require ACIS::Web::UserData;
    my $srcud = ACIS::Web::UserData -> load( $file );

    if ( not $srcud ) { next; }
    debug "openned $l";
    
    my $srcrec = $srcud ->{records};

    foreach ( @$srcrec ) {
      my $name = $_ ->{name}{full};
      debug "record of $name";
      
      push @$dest, $_;
      delete $_ -> {'about-owner'};
    }

    remove_account( $acis, -login => $l );
    if ( scalar @$dest > 1 ) {
      $ud ->{owner} {type} {advanced} = 1;
    }
  }

}


sub remove_account {   
  my $app    = shift;
  my $par    = { @_ };

  my $login  = $par -> {-login};
  my $notify = $par -> {-notify};
  my $clean  = $par -> {-clean};

  assert( $login );


  my $paths   = $app -> make_paths_for_login( $login );

  
  my $file    = $paths -> {'user-data'};
  my $bakfile = $paths -> {'user-data-deleted'};
  

  $app -> sevent ( -class  => 'account', 
                   -action => 'delete',
                   -login  => $login,
                   -backup => $bakfile,
                 );
  

  while ( -e $bakfile ) {
    debug "backup file $bakfile already exists";
    $bakfile =~ s/\.xml(\.(\d+))?$/".xml." . ($2+1)/eg;
  }

  debug "move '$file' to '$bakfile'";
  my $check = rename $file, $bakfile;  
  
  if ( not $check ) {
    debug "failed";
    $app -> errlog ( "Can't move $file file to $bakfile" );
    $app -> error ( "cant-remove-account" );
    return;
  }

  $app -> userlog( "removed $login account" );


  ###  send update request to the RI UD (RePEc-Index Update Daemon)
  require RePEc::Index::UpdateClient;
  my $udatadir = $app -> userdata_dir;
  my $relative = substr( $file, length( "$udatadir/" ) );
  $app -> log( "requesting RI update for $relative" );
  RePEc::Index::UpdateClient::send_update_request( 'ACIS', $relative );


  
  if ( $clean ) {
    ### delete the profile pages
    debug "clean-up after deletion";
    
    require ACIS::Web::UserData;
    
    my $udata = ACIS::Web::UserData -> load( $bakfile );
    
    foreach ( @{ $udata-> {records} } ) {
      my $f = $_ -> {profile} {file};
      
      if ( $f and -f $f ) {
        unlink $f;
        $app-> userlog( "removed profile file $file" );
      }
      
      my $exp = $_ -> {profile} {export};
      if ( $exp ) {
        foreach ( values %$exp ) {
          unlink $_;
          $app-> userlog( "removed exported profile data: $_" );
        }
      }
      
    }
    
  }

  ### XXX Further clean-up is probably needed

  if ( $notify ) {
    # $app -> send_mail( 'email/account-deleted.xsl' );
    debug "clean-up after deletion";
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
    require ACIS::Web::Contributions;
    $query = ACIS::Web::Contributions::query_resources( $table, $where );
    $query .= $q->{limit};
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

      use Storable qw( thaw );
      if ( $item -> {data} ) {
        my $packed = thaw( $item -> {data} );
        foreach ( keys %$packed ) {
          my $val = $packed -> {$_};
          $item -> {$_} = $val;
        }
        delete $item -> {data};
      }

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
                    $q -> {what},
                    " from $table ",
                    $q -> {where},
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
                    $q -> {what},
                    " from $table ",
                    $q -> {where},
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
  my $request = $app -> {request} {subscreen};
  my $input = $app->form_input;

  if ( $request =~ m!^(\w+)/([^/]+)(/(\w+))?$! ) {
    my $col = $1;
    my $id  = $2;
    my $op  = $4;
    
    $input ->{id} = $id;
    $input ->{col} = $col;
    $input ->{op} = $op;
    debug "subscreen: col:$col, id:$id, op:$op";
  }


  my $var = $app ->variables;
  my $op  = $input -> {op};
  my $id  = $input -> {id};
  my $col = $input -> {col};

  if ( not $op ) {
    $op = 'hist';
  }

  if ( not $id or not $col ) {
    return;
  }


  my $data;

  ### $op is one of 'rec' | 'hist' | 'ardb' 
  if ( $op eq 'rec'
       or $op eq 'record' ) {

    require RePEc::Index::Reader;
    my $reader = RePEc::Index::Reader -> new( $col );
    $data = $reader -> get_record( $id );
    $var -> {record}  = $data ->[0];
    $var -> {type}    = $data ->[1];
    if ( $reader -> get_conflict( $id ) ) {
      $var -> {conflict} = 1;
    }

  } elsif ( $op eq 'hist' 
            or $op eq 'history' ) {

    require RePEc::Index::Reader;
    my $reader = RePEc::Index::Reader -> new( $col );
    $data = $reader -> get_history( $id );

    resolve_times_in_history( $data );
    $var -> {history}  = $data;
    if ( $reader -> get_conflict( $id ) ) {
      $var -> {conflict} = 1;
    }

  } elsif ( $op eq 'ardb' ) {
    require ARDB;
    require ARDB::Local;
    my $ardb = ARDB-> new();
    $data = $ardb -> get_record( $id );
    $var -> {record} = $data;

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



1;