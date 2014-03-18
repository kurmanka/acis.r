package ACIS::Web::User; ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Main registered user's screens' code, excluding affiliations and
#    contributions.
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
use warnings;

use Data::Dumper;
use Carp::Assert;

use Web::App::Common qw( debug );
use ACIS::Data::DumpXML qw(dump_xml);

use ACIS::Web::Person;
use ACIS::Web::SysProfile; 


sub login {
  debug "running login user screen";
  
  my $app = shift;
}



sub welcome {  
  my $app = shift;
  my $session  = $app -> session || die 'must have a session';


  my $reclist  = $session ->userdata_record_list;
  my $owner    = $session ->userdata_owner;

  if ( $owner->{type}{advanced} 
       or $owner->{type}{'deceased-list-manager'} 
       or scalar( @$reclist ) > 1 ) {

      # the following line is needed to make recent changes to the current
      # record visible on the menu page. For example, changing the
      # deceased date.
      if ($session->current_record) { 
          $session->save_current_record('closeit'); 
          $session->save_userdata_temp;
      }

      my $records =  $session->userdata->{records};

      my @list = map { name => $_->{name}{full}, 
                       id   => $_->{id},
                       sid  => $_->{sid},
                       (exists $_->{deceased})
                           ? ( deceased => $_->{deceased} )
                           : (),
      }, @$records;


      # XXX load research and citation suggestions from sysprof
      load_suggestion_counts_for_records( $app, \@list );

      $app -> variables -> {records} = \@list; 
      $app -> set_presenter( 'records-menu' );

  } else {
      $session -> set_current_record_no( 0 );
  }
}

sub load_suggestion_counts_for_records {
    my $app =  shift;
    my $list = shift;

    # use SysProfile functions and session...
    my $session = $app->session;
    
    foreach ( @$list ) {
        my $sid = $_->{sid};
        my $r = get_sysprof_value( $sid, "research-suggestions-exact" );
        my $c = get_sysprof_value( $sid, "citation-suggestions-new-total" );
        # an optimization
        if (defined $r or defined $c) {
            $session->{$sid}{"research-suggestions-exact"} = $r;
            $session->{$sid}{"citation-suggestions-new-total"} = $c;
            $session->make_sticky( $sid );
        }
    }

    # XXX: or bypass the SysProfile tools and directly query the sysprof
    # table for these two parameters for all these records, and only
    # get those that are non-zero.
    
}


sub name_screen_init {
  my $app = shift;
  
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $variations;
  
  my $list  = $record ->{name} {'additional-variations'};
  my $list2 = $record ->{name} {variations};

  if    ( $list  and ref $list  ) { $variations = join "\n", @$list;  }
  elsif ( $list2 and ref $list2 ) { $variations = join "\n", @$list2; }
  else                            { $variations = ""; }

  $app -> set_form_value( 'name-variations', $variations );


  if ( $app -> request ->{params} ->{back} ) {
    my $back = $app -> request ->{params} ->{back};
    $app -> variables -> {'screen-back'} = $back;
  }

}



sub name_screen_process1 {
  my $app = shift;
  
  my $session = $app -> session;
  my $record  = $session -> current_record;
  $session -> {'name-data-old'} = { %{$record ->{name}} };

  # a check for latin name
  my $input     = $app -> form_input;
  my $full_name = $input ->{'full-name'};
  ###  name characters check
  if ( $full_name =~ /([^a-zA-Z\.,\-\s\'\(\)])/ ) {
    debug ( "need latin name, because of '$1' char" );

    if ( not $input -> {'name-latin'} ) {
      $app -> userlog( "require latin name" );
      $app -> form_required_absent ( 'name-latin' );
      $app -> clear_process_queue;
    } 
  }  
}


###  XXX this code really belongs to the ACIS::Web::Person module
sub name_screen_process2 {
  my $app = shift;
  
  debug "running personal data screen";
  
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $name    = $record -> {name};

  my $variations = ACIS::Web::Person::parse_name_variations( $app->get_form_value('name-variations') );
  $record -> {name} {'additional-variations'} = $variations;
  $app->set_form_value( 'name-variations', join( "\n", @$variations ));

  my $varcount = scalar @$variations;
  if ($varcount < 4) {
      $app -> error( 'need-4-variations' );
      $app -> clear_process_queue;
      return;
  }

  ACIS::Web::Person::compile_name_variations( $app, $record );

  ###  check if anything really changed
  my $old_name = $session ->{'name-data-old'};
  foreach ( qw( full latin last ) ) {
    if (     defined $name    ->{$_}  
         and defined $old_name->{$_}  
         and $old_name->{$_} eq $name->{$_} ) { next; }
    if (     not defined $name->{$_} 
         and not defined $old_name->{$_} ) { next; }
    
    # else:
    ###  note the difference, remember the change
    $name ->{'last-change-date'} = time;
    debug "name data changed: $_";
  }
  delete $session ->{'name-data-old'};

  if ( $app -> request ->{params} ->{back} ) {
    my $back = $app -> request ->{params} ->{back};
    $app -> redirect_to_screen( $back );
    return;
  }

  if ( $app -> request ->{params} ->{gotoresearch} ) {
    $app -> redirect_to_screen( 'research' );
    return;
  }

  if ( $session-> type eq 'new-user' ) {
    ### XXX will stay on the same screen, which is ok sometimes, but
    ### it could be better to move on to next registation screen

  } else {
    $app -> redirect_to_screen_for_record( 'menu' );
  }

}




sub contact_screen_process {
  my $app = shift;

  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $owner   = $session -> object -> {owner};

  if ( 
      $record -> {'about-owner'} 
      and $record -> {'about-owner'} eq 'yes'
      and (
           not $owner -> {type} 
           or not $owner ->{type} {advanced}
          )
     ) {
    
    ### simple user mode
    
    my $login = $record -> {contact}{email};
    my $full_name = $record -> {name}{full};
    
    if ( $owner -> {name} ne $full_name ) {
      $owner -> {name} = $full_name;
    }
    
    $login = set_user_login( $app, $login );
  }

  if ( not $app->error ) {
    $app -> redirect_to_screen_for_record( 'menu' );
  }
}



sub set_user_login {
  my $app  = shift;
  my $new  = shift;
  
  my $session = $app -> session;
  my $owner   = $session -> userdata_owner;

  my $old      = $owner -> {login};
  my $original = $owner -> {'old-login'};

  if ( not defined $new ) {
    return $old;
  }

  my $newlc = lc $new;
  my $oldlc = lc $old;

  if ( $newlc ne $oldlc ) {
    debug "set_user_login: new login $newlc";

    my $f = $app -> userdata_file_for_login( $newlc );

    my $welcome_back; ### switched back to the same login she used to enter the system
    if ( $newlc eq lc $original ) {
      $welcome_back = 1;
      delete $owner->{'old-login'};
      if ( $owner->{placeholder_file} ) { 
        unlink $owner->{placeholder_file}; 
        delete $owner->{placeholder_file}; 
      }

    } else {
      if ( -e $f or -e "$f.lock" ) {
        debug "login change cancelled by lock file $f.lock";
        $app -> error( "login-taken" );
        return $old;
      }

      if ( open HOLDER, ">$f" ) {
        print HOLDER "placeholder";
        close HOLDER;
        if ( $owner->{placeholder_file} ) {  unlink $owner->{placeholder_file};  }
        $owner->{placeholder_file} = $f;

      } else {
        $app -> error( "login-taken" );
        return $old;
      }

      if ( not defined $owner -> {'old-login'} ) {
        $owner -> {'old-login'} = $old;
      }
    }

    debug "login change successful";
    $owner   -> {login} = $new;
    $session -> set_userdata_saveto_file( $f );
    $app     -> update_paths_for_login( $newlc );

    require ACIS::Web::SysProfile;
    ACIS::Web::SysProfile::rename_sysprof_id( $oldlc, $newlc );
    
    # XXXXX if there is a persistent login cookie, we may need to
    # update the login in the table. 
    
  } 

  $owner -> {login} = $new;

  return $new;
}


use ACIS::User;

sub remove_account {
  my $app = shift;

  my $paths   = $app -> paths;
  my $session = $app -> session;
  my $input   = $app -> form_input;
  my $owner   = $session -> userdata_owner;
  
  my $pass = $input ->{'pass'};
  if ( $app->check_user_password( $pass, $owner ) ) {
    # password is valid
    # we can continue
  } else {
    $app -> error( 'bad-old-pass' ); ### 'bad-old-pass' ?
    return;
  }

  if ( not $input ->{'confirm-it'} ) {
    ### request the confirmation 
    return ;
  }

  my $ret = ACIS::User::delete_current_account( $app, 'user' );

  if ($ret) {
    $app -> message( 'account-deleted' );
    $app -> success( 1 );
    $app -> set_presenter( "account-deleted" );
  }

}


sub profile_overview {
  my $app = shift;
  
  $app -> variables -> {record} = $app -> session -> current_record();
}




use ACIS::Web::SysProfile;
use Web::App::Common;

sub normal_login {
  my $app = shift;

  my $login = $app -> get_form_value( 'login' );
  my $success;

  if ( $login ) {
    $success = $app -> authenticate; 
    if ( $success ) {
      $app -> redirect_to_screen( 'welcome' );
    }

  }
  return $success;
}


sub check_session_type {
  my $app = shift;
  
  my $session = $app -> session || die 'must have a session';
  
  if ( $session -> type ne 'user'
       and $session -> type ne 'admin-user' ) {
    $app -> error( 'session-wrong-type' );
    $app -> set_presenter( 'sorry' );
    $app -> clear_process_queue();
  }

}


sub settings_prepare {
  my $app    = shift;
  
  my $vars    = $app -> variables;
  my $session = $app -> session;
  my $login = $session -> userdata_owner-> {login};
  my $persistent_login = $app -> check_persistent_login || '';
  debug "Persistent login: $persistent_login";
  
  my $persistent_login_mode = ($persistent_login eq $login);

  $app -> set_form_value( "email", $login );

  my $mode = ($persistent_login_mode ? 'true' : undef);
  debug "Persistent login mode: $mode";
  $app -> set_form_value( "remember-me", $mode );
  #$vars -> {'remember-me'} = $mode;

}


sub settings {
  my $app = shift;

  my $input   = $app -> form_input;
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $owner   = $session -> userdata_owner;
  my $persistent_login = $app -> check_persistent_login || '';
  my $persistent_login_mode = ($persistent_login eq $owner->{login});

  my $OK  = 1;

  my $oldp  = $input -> {pass};
  my $login = $input -> {email};
  my $pass;

  if ( $app->check_user_password( $oldp, $owner ) ) {
      # password is valid
      # we can continue
  } else {
    $app -> error( 'bad-old-pass' ); ### 'bad-old-pass' ?
    undef $OK;
    return;
  }

  my $old_login = $owner->{login};
  $login = set_user_login( $app, $login );
  $app -> set_form_value( "email", $login );

  my $login_changed = ($old_login ne $login);
  debug "Login changed: <$login_changed>";

  if ( $login_changed 
       and $record -> {'about-owner'} 
       and $record -> {'about-owner'} eq 'yes'
       and $input -> {'record-email'} 
      ) {

    ### simple user mode
    $record -> {contact} {email} = $login;
    
  } else {

    if ( defined $record -> {'about-owner'} 
         and $record -> {'about-owner'} eq 'yes'
         and $login ne $record -> {contact} {email}
         and not $input -> {'record-email'} ) {
      delete $record -> {'about-owner'}; ### XXX this is arguable      
    }
  }

  ### setting the password 
  if ( $input -> {'pass-new'} 
       or $input -> {'pass-confirm'} ) { 
           
    my $new  = $input -> {'pass-new' };
    my $conf = $input -> {'pass-confirm'};
      
    if ( $new eq $conf ) {
        $app->set_new_password( $new );
    } else {
        $app -> form_invalid_value( 'pass-new' );
        $app -> form_invalid_value( 'pass-confirm' );
        undef $OK;
    }
  }
  
  # handle the remember me checkbox
  my $remember_me_input = $input->{'remember-me'} || '';
  debug "remember-me: $remember_me_input";

  if ( not $remember_me_input ) {
    $app -> remove_persistent_login;
    $persistent_login_mode = undef;

  } else { # $remember_me_input == true

    if ( $login_changed ) {
      # if login has changed, remove the old login cookie, 
      $app ->remove_persistent_login;
    }
    if ( not $persistent_login_mode or $login_changed ) {
      # create a new one.
      $persistent_login_mode = $app ->create_persistent_login( $login );
    } else {
      # renew the existing one
      $persistent_login_mode = $app ->renew_persistent_login();
    }
  }
  $app -> set_form_value( "remember-me", $persistent_login_mode );


  if ( not $app -> error 
       and $OK ) {
    $app -> message( "saved" );
  }
  
}



sub rebuild_profile_url {
  my $app    = shift;
  my $record = shift || $app ->session ->current_record;
  delete $record -> {settings} {static_url};
  $app -> personal_static_url;
  if ( $record -> {settings} {static_url} ) {
    $app -> success( 1 );
  }
}

use ACIS::Web::UserPassword;
sub ACIS::Web::userdata_bring_up_to_date {
    my $app = shift or die;
    $app -> upgrade_clear_password();
}



############################################################################
###  PHOTO AND INTERESTS SCREENS PROCESSORS, NOT USED ANYMORE
############################################################################


sub photo {  # XXX throw this away

  debug "photo screen";
  
  my $app = shift;

  my $session = $app -> session;
  my $record  = $session -> current_record;

  my $request = $app -> request;
  my $query   = $request -> {CGI};
  my $input   = $app -> form_input;

  $CGI::POST_MAX = 2097152;  # ;-)  XX
  
  my $url  = $app -> personal_static_url();
  my $path = $app -> personal_static_file();

  if ( $url =~ m!/$! and $path =~ m!/index$! ) {
    $path =~ s/index$/pic/;
    $url .= 'pic';
  }
  
  if ( not $url or not $path ) {
    return undef;
  }

  assert( $url );
  assert( $path );

  my $photo = $record ->{photo};

  if ( $photo ) {
    if ( ref $photo ) { # just be sure
      if ( $photo -> {file}
           and -f $photo -> {file} ) {
        $app -> variables -> {photo} = $photo ->{url};
      }

      if ( $input -> {'clear-photo'} ) {  ### XX give user access to this
        my $file = $photo ->{file};
        delete $record -> {photo};
        delete $app -> variables -> {photo};
        unlink $file;
      }

    } else {  ### COMPATIBILITY 
      $app -> variables -> {photo} = "$url$photo";
    }
  } 
  
  
  return unless $input ->{photo};
  
  my $file = $query -> upload( 'photo' );
  if ( not $file 
       or $query -> cgi_error ) {
    $app -> error( 'photo-cgi-error' ); #$query -> cgi_error;
    return;
  }

  $file =~ m/^.*\.([^.]+)$/;  
  my $extension = $1;
  if ( not $extension
       or $extension !~ /^(jpe?g|gif|png|bmp)$/i ) {
    $app -> error ('photo-image-unknown-format');
    $app -> clear_process_queue;
    return;
  }


  if ( ref $photo ) {
    ### delete old photo file
    my $oldfile = $photo -> {file};
    if ( $oldfile and -f $oldfile ) {
      unlink $oldfile;
      debug "remove previous picture file $oldfile";
    }
  }
  
  debug "try to save file into '$path.$extension'";
  
  my $out_file = "$path.$extension";
  if ( open PHOTO, '>', $out_file ) {
    binmode PHOTO;
    my $buffer;
    while ( read ($file, $buffer, 1024) ) {
      print PHOTO $buffer;
    }
    close PHOTO;

    $app -> userlog ( "uploaded a photo image file ($out_file)" );
    
  } else {

    $app -> errlog ( "can not save uploaded photo to a file: $out_file" );
    $app -> error ( 'photo-cannot-open-file' );
    return;
  } 

  if ( not $record -> {photo} 
       or not ref $record->{photo} ) {
    $photo = $record ->{photo} = {};
  }

  $photo -> {ext}  = $extension;
  $photo -> {file} = $out_file;
  $photo -> {url}  = "$url.$extension";

  $app -> variables -> {photo} = $photo ->{url};

  $app -> message( "photo-uploaded" );

}






sub interests {

  debug "running interests service screen";
  
  my $app = shift;
  
  $app -> redirect_to_screen_for_record( 'menu' );
}




1;
