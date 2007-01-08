package ACIS::Web::NewUser; ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    ACIS: new users' web interface logic.  Creation of the initial
#    userdata, user account, processing the initial registration
#    screens and so on.
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
#  $Id: NewUser.pm,v 2.5 2007/01/08 19:22:01 ivan Exp $
#  ---


use strict;
use warnings;

use Data::Dumper;
use Carp::Assert;

use Web::App::Common;

use ACIS::Data::DumpXML qw( &dump_xml );


my $initial_sid;

######  new-user screen (initial)  ###


sub initial_prepare {
  my $app = shift;

  my ($year, $month, $day) = (localtime)[5, 4, 3];
    
  $app -> set_form_value ( 'year',  $year + 1900 );
  $app -> set_form_value ( 'month', sprintf( "%02d", $month + 1) );
  $app -> set_form_value ( 'day',   sprintf( "%02d", $day ) );
  
}


sub initial_process {
  my $app = shift;
  
  my $form_input = $app -> form_input;
  
  debug "processing new-user initial screen";

  my $abort;

  my $owner = {};
  my $login = $owner -> {login} = $form_input -> {email};
  assert( $login, 'no email address given' );
  assert( $form_input -> {'first-name'}, 'no first name given' );
  assert( $form_input -> {'last-name'} , 'no last name given'  );

  my $paths = $app -> update_paths_for_login( $login );

  if ( -e $paths ->{'user-data'} ) {
    $app -> error( "account-exists-already" );
    $app -> set_presenter( "sorry" );
    $abort = 1;
  }


  ### check password and password confirmation
  if ( not $app -> get_form_value ('pass') 
       or ( $app -> get_form_value ('pass') 
            ne $app -> get_form_value ('pass-confirm') ) ) {
    $app -> form_invalid_value( 'pass' );
    $app -> form_invalid_value( 'pass-confirm' );
    $abort = 1;
  }


  {
    my ( $year, $month, $day );
    $year  = $form_input -> {year}  || die;
    $month = $form_input -> {month} || die;
    $day   = $form_input -> {day}   || die;
    my $bad;

    if ( $year > 2200  or $year < 1000 ) { 
      $app -> form_invalid_value( 'year' );
      $app -> form_invalid_value( 'id-date-year' );
      $bad = 1;
    }
    
    if ( $month < 1    or $month > 12 ) {
      $app -> form_invalid_value( 'month' );
      $app -> form_invalid_value( 'id-date-month' );
      $bad = 1;
    }
    
    if ( $day < 1      or $day > 31 ) {
      $app -> form_invalid_value( 'day' );
      $app -> form_invalid_value( 'id-date-day' );
      $bad = 1;
    }    
    
    if ( not $bad ) {
      ###  check date for realness
      use Time::Local;
      eval " Time::Local::timelocal( 0,0,0, \$day, (\$month-1), (\$year) ); ";
      if ( $@ ) {
        $app -> form_invalid_value( 'year'  );
        $app -> form_invalid_value( 'month' );
        $app -> form_invalid_value( 'day'   );
        $app -> form_invalid_value( 'iddate-unreal' );
        $abort = 1;
        debug "Date check: $@";
        undef $@;
      } else {
        # good!
      }
    } else { 
      $abort = 1;
    }
  }

  if ( $abort ) {
    $app -> clear_process_queue;
    return;
  }


  $owner -> {IP} = $ENV{'REMOTE_ADDR'};

  debug "creating a session";
  my $session = $app -> start_session ( 'new-user', $login, $owner );

  my $sid     = $session -> id;
  debug "new session created: $sid";

  $app -> sevent ( -class => 'new-user',
                   -login => $login,
                    -file => $paths ->{'user-data'},
                      -IP => $owner ->{IP}, 
                 );

  my $homepage = $form_input -> {homepage};
  
  if ( $homepage =~ m!^http://(?:none)?$! ) {
    undef $form_input -> {homepage};
  }

  $app -> process_form_data;

  $app -> userlog ( "initial registration" ); 

  prepare_user( $app );

  $app -> redirect_to_screen( 'new-user/additional' );


  if ( $form_input -> {'remember-me'} ) {
    $app -> set_authentication_cookie( 'login', $login );
    $app -> set_authentication_cookie( 'pass',  $form_input -> {pass} );
  }

}




sub prepare_user {

  my $app = shift;
  
  my $session = $app -> session;
  my $record  = $session -> current_record;
  
  debug ( Dumper $record );

  assert( $record->{name} );
  assert( $record->{name} -> {last} );


  $record ->{type} = 'person';

  my $name         = $record -> {name}; 

  my $first_name   = $name -> {first};
  my $middle       = $name -> {middle};
  my $last_name    = $name -> {last};
  my $suffix       = $name -> {suffix};

  my $full_name = "$first_name $middle $last_name";

  if ( $suffix ) {
    $full_name .= ", $suffix";
  }

  $full_name =~ s/\s+/ /g;

  debug( "Full name: $full_name" );

  $app -> userlog ( "initial: full name: $full_name" );
    
  $record  ->{name} {full} = $full_name;
  $session -> object -> {owner} {name} = $full_name;

  $app -> sevent ( -class => 'new-user',
               -humanname => $full_name, 
                 );


  if ( $session ->type eq 'new-user' ) {
    $session ->owner ->{name}  = $full_name;
    $session ->owner ->{login} = $record ->{contact} {email};

    my $handle_name = $full_name;

    ###  name characters check
    $session -> make_sticky( 'ask-latin-name' );

    require ACIS::Misc;

    if ( ACIS::Misc::contains_non_ascii( $full_name ) ) {
      $session -> {'ask-latin-name'} = 1;
      debug ( "will ask for latin name" );

      my $trans = ACIS::Misc::transliterate( $full_name );
      if ( $trans ) {
        $record  ->{name} {latin} = $trans;
      }

    } else {
      delete $session -> {'ask-latin-name'};
    }

  }
    

  ### generate initial name variations

  my $variations_list = ACIS::Web::Person::generate_name_variations( $record );

  $record -> {name}{'additional-variations'} = $variations_list;

  ACIS::Web::Person::compile_name_variations( $app, $record );

}





######  new-user/additional screen  ###


sub additional_prepare {
  my $app = shift;
  
  my $session = $app -> session;

  debug "preparing personal data service screen";
  
  if ( $session -> type ne 'new-user' ) {
    $app -> error( 'session-wrong-type' );
    $app -> clear_process_queue;
    $app -> set_presenter( 'sorry' );
    return;
  }
  
  my $variations = join "\n", @{ $session -> current_record -> 
                                   {name} {'additional-variations'} };
  debug "Name variations: $variations";

  $app -> set_form_value ( 'name-variations', $variations );

  
  ### ask latin name

  if ( $session -> {'ask-latin-name'} ) {
    $app -> variables -> {'ask-latin-name'} = 1;
  }

}


sub additional_process {
  my $app = shift;
  
  my $session = $app -> session;

  debug "running personal data service screen";
  
  if ( $session-> type ne 'new-user' )  {
    $app -> error( 'session-wrong-type' );
    $app -> clear_process_queue;
    $app -> set_presenter( 'sorry' );
    return;
  }

  $app -> variables -> {'ask-latin-name'} = $session -> {'ask-latin-name'};

  my $input = $app -> form_input;

  if ( $session -> {'ask-latin-name'} ) {
    if ( not $input -> {'name-latin'} ) {
      $app -> form_required_absent ( 'name-latin' );
      return;
    } 
  }
  
  my $record = $session -> current_record;

  $record -> {name} {'additional-variations'} = 
    [ split ( /\s*[\n\r]+/, $app -> get_form_value ('name-variations') ) ];


  require ACIS::Web::Person;

  ACIS::Web::Person::compile_name_variations( $app, $record );


  my $reg_date = $session -> {'registration-date'};
  my $id  = make_person_handle ( $app, $record, $reg_date );
#  my $sid = make_short_id      ( $app, $record );

  $app -> sevent ( -class => 'new-user', 
                      -id => $id,
 #                   -sid => $sid,
               -humanname => $record -> {name}{full},
                   ($record->{name}{latin})? ( -latinname => $record ->{name}{latin}): ()
                 );

  ###  assign temporary short id -- use session id for that
  $record -> {sid} = $session -> id;

  $app -> redirect_to_screen( 'affiliations' );

  $app -> userlog ( "initial: additional processed, moving towards affilations" );
    
}





### is this ok?  Do we allow new users to submit institutions?
### yes, it is ok.  The email will be sent out only after the confirmation.

sub new_institution {
  my $app = shift;
  
  my $session = $app -> session;
  if ( $session-> type ne 'new-user' ) {
    $app -> error( 'session-wrong-type' );
    $app -> clear_process_queue;
    $app -> set_presenter( 'sorry' );
    return;
  }

  ACIS::Web::Affiliations::submit_institution( $app );
  
  $app -> redirect_to_screen( 'affiliations' );
}
 



#################  initial registration complete, but not yet confirmed  ###

sub complete {

  debug "running new user registration complete service screen";
  
  my $app = shift;

  my $session = $app -> session;
  
  if ( $session-> type ne 'new-user' ) {
    $app -> error( 'session-wrong-type' );
    $app -> clear_process_queue;
    $app -> set_presenter( 'sorry' );
    return;
  }


  my $path = $app -> {home} . '/unconfirmed/';

  my $filename;
  my $confirmation_id = $session -> {'confirmation-id'};
  
  if ( not defined $confirmation_id ) {
    $confirmation_id = generate_id();
    if ( -f "$path$confirmation_id" ) { redo; }
  }
  
  $filename = "$path$confirmation_id";
  if ( open LOCK, ">$filename" ) {
    print LOCK "lock";
    close LOCK;
  }

  debug "confirmation-id: '$confirmation_id'";

  $session -> {'confirmation-id'} = $confirmation_id;

  my $old_session_file = $session -> filename;
  $session -> {'remove-old-session-file'} = $old_session_file;
  $session -> save( $filename );


  my $confirmation_url = $app -> config( 'base-url' )
        . '/confirm%21' . $confirmation_id;

  $app -> userlog ( "initial: next step is confirming through $confirmation_url" );

  my $vars =   $app -> variables;
  $vars -> {'confirmation-url'} = $confirmation_url;
  $vars -> {record} = $session -> current_record;

  debug "the <a href='$confirmation_url'>confirmation url</a>";
  
  $app -> send_mail ('email/confirmation.xsl');

}


###  handler of the "confirm" screen 

sub confirm {
  my $app = shift;
  
  debug "running new user confirmation screen";
  my $confirmation_id = $app -> request -> {'session-id'} || '';

  my $session;

  if ( $confirmation_id ) {

    my $path = $app -> {home} . '/unconfirmed/';
    
    my $filename = "$path$confirmation_id";
    
    debug "received '$confirmation_id', try load unconfirmed session $filename";

    if ( -e $filename ) {
      $session = ACIS::Web::Session -> load( $app, $filename );
    }
  }

  if ( not $session ) {
    $app -> errlog( "bad confirmation attempt: $confirmation_id" );
    $app -> error ( 'confirmation-bad' );
    $app -> clear_process_queue;
    return;
  }

  assert( $session -> type() eq 'new-user' );

  my $userdata_file = $session -> object_file_save_to;
  if ( -e $userdata_file ) {
    $app -> errlog ( "$userdata_file exists" );
    $app -> error ( 'confirmation-account-clash' );
    $app -> clear_process_queue;
    return;
  }

  $app -> session( $session );

  my $udata = $session -> object;
  my $login = $session -> owner ->{login};

  my $records = $udata  ->{records};

  ### the following assumes that initially there is only one record in the
  ### userdata, and that record is of type 'person'

  my $record  = $udata  ->{records} ->[0];

  my $old_sid = $session -> id;
  my $new_sid = make_short_id ( $app, $record );

  $record -> {'about-owner'} = 'yes';

  if ( $new_sid ) {
    fix_temporary_sid( $app, $old_sid, $new_sid );
    $record -> {temporarysid} = $old_sid;
    $app -> logoff_session;

  } else { 

    ###  "Your registration cannot be finalized now.  You did everything
    ###  correctly, but an internal technical problem happened.  Administrator
    ###  will have to clear the issue.  We logged details of the problem and
    ###  your email address.  Administrator will contact you as soon as the
    ###  issue is resolved."

    $app -> errlog( "[$login] registration obstructed" );
    $app -> error( "confirmation-obstructed" ); 
    $app -> clear_process_queue;

    require Web::App::Email;
    Web::App::Email::send_mail( $app,
                                "email/notify-admin-problem.xsl",
                              );
    
  }
}




sub make_short_id {
  my $app    = shift;
  my $record = shift;

  if ( $record ->{sid} 
       and $record ->{sid} =~ m/^p/ ) {
    return $record ->{sid};
  }

  my $login  = $app ->session ->owner ->{login};

  # get short-id for the person record
  my $id   = $record ->{id};

  if ( not $id ) {
    debug "short-id creation attempted, while there's no id";
    return undef;
  }


  my $namest  = $record -> {name};
  my $id_name = $namest -> {last};
  if ( $namest -> {latin} ) {
    $id_name .= $namest -> {latin};
  }
  if ( $namest -> {first} ) {
    $id_name .= $namest -> {first};
  }
  if ( $namest -> {email} ) {
    $id_name .= $namest -> {email};
  } 
  

  ###  Call ACIS::ShortIDs, create and register the short-id
  my $sid;
  eval q!
      use ACIS::ShortIDs;
      $sid = ACIS::ShortIDs::make_short_id( $id, 'p', $id_name, 2 );
    !;

  
  if ( not defined $sid ) {
    $app ->errlog ( "[$login] can't get short-id, id: $id, name: '$id_name'" );
    $app ->error( "short-id-make-problem" );
#    critical "we tried to make a short-id, but no luck";
    return undef;
  }
  
  $app -> userlog ( "for id $id and name '$id_name', short-id: $sid" );
  $record -> {sid} = $sid;
  
  return $sid;
}




sub make_person_handle {

  my $app = shift;
  my $record = shift;

  if ( $record -> {id} ) {
    return $record ->{id};
  }

  my $date = shift;

  ### make handle for the person record

  my $handle;
  my $prefix = $app -> config( 'person-id-prefix' );
  my $suffix = '';

  ###  registration-date is user's input, as per screens.xml and
  ###  with the help of process_form_data()

  {
    my $name  = $record -> {name}; 
    
    my $handle_name;

    if ( $name -> {latin} ) {
      $handle_name = $name->{latin};
    } else {
      $handle_name = $record ->{name}{full};
    }

    $handle_name = uc $handle_name;
    $handle_name =~ s/[^A-Z]/_/g;
    $handle_name =~ s/_+/_/g;

    ###  name characters check
    
    if ( $handle_name !~ /[A-Z]/ ) {
      $app -> error( "cant-make-person-id" );
      return;
    }
    

    my $year  = $date -> {year};
    my $month = $date -> {month} + 0;
    my $day   = $date -> {day} + 0;
    
    assert( $year  );
    assert( $month );
    assert( $day   );

    $month = "0$month" if $month < 10;
    $day   = "0$day"   if $day   < 10;
    
    while ( 1 ) {

      $handle = "$prefix$year-$month-$day:$handle_name$suffix";

      ### Here we check for handle uniqueness
      ### and we can use Short-IDs database for that

      my $sid ;

      eval q!
        use ACIS::ShortIDs;
        $sid = ACIS::ShortIDs::resolve_handle( $handle );
      !;

      if ( $sid ) {
        my $login = $app -> username;
        $app -> errlog ( "a non-unique handle generated: $handle, login $login; retrying" );
        if ( $suffix ) { 
          my $num = substr( $suffix, 1 );
          $num ++;
          $suffix = "_$num";
        } else { $suffix = "_2"; }
  
      } else {
        ###  the handle is unique
        last; 
      } 
    }

    $handle = lc $handle;
    $record->{id} = $handle;
    
    $app -> userlog ( "record id: $handle" );
  }

  return $handle;
}


sub fix_temporary_sid {
  my $app     = shift;
  my $old_sid = shift;
  my $new_sid = shift;

  if ( $new_sid 
       and $new_sid ne $old_sid ) {
    ###  fix acis.suggestions and acis.threads tables accordingly
    ###  XX  we need a cleaner way to do that 
    my $sql = $app -> sql_object;
    foreach ( qw( suggestions/psid sysprof/id ) ) {
      my ( $table, $field ) = split '/', $_;
      $sql -> do( "update $table set $field='$new_sid' where $field='$old_sid'" );
    }
  }

}

1;
