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
#  ---
#  $Id: User.pm,v 2.0 2005/12/27 19:47:40 ivan Exp $
#  ---


use strict;
use warnings;

use Data::Dumper;
use Carp::Assert;

use Web::App::Common qw( debug );
use ACIS::Data::DumpXML qw(dump_xml);



sub login {
  debug "running login user screen";
  
  my $app = shift;
}



sub welcome {  
  my $app = shift;
  my $session  = $app -> session;
  my $userdata = $session -> object;
  my $records  = $userdata -> {records};
  
  if ( $userdata -> {owner} {type} {advanced} 
       or scalar( @$records ) > 1 ) {
    $app -> variables -> {records} = $records; 
    $app -> set_presenter( 'records-menu' );
  }
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


use ACIS::Web::Person;


sub name_screen_process1 {
  my $app = shift;
  
  my $session = $app -> session;
  my $record  = $session -> current_record;
  
  $session -> {'name-data-old'} = $record ->{name};
}


###  XXX this code really belongs to the ACIS::Web::Person module
sub name_screen_process2 {
  my $app = shift;
  
  debug "running personal data screen";
  
  my $variations = $app -> get_form_value ('name-variations');

  $variations =~ s/ +/ /g;
  $variations = [ split /\s*[\n\r]+/, $variations ];
  
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $name    = $record -> {name};

  $name -> {'additional-variations'} = $variations;

  ACIS::Web::Person::compile_name_variations( $app, $record );


  ###  check if anything really changed
  my $change_flag = 0;
  my $old_name = $session ->{'name-data-old'};

  foreach ( qw( full latin last ) ) {
    if ( defined $name ->{$_} 
         and $old_name ->{$_} ne $name ->{$_} ) {
      $change_flag = 1;
      debug "name data changed: $_";
    }
  }

  if ( $change_flag ) {
    ###  remember the change
    $name ->{'last-change-date'} = time;
  }


  my $full_name = $name ->{full};

  ###  name characters check
  if ( $full_name =~ /([^a-zA-Z\.,\-\s\'\(\)])/ ) {
    debug ( "need latin name, because of '$1' char" );
    $app -> userlog( "need latin name, because of '$1' char" );

    if ( not $app -> form_input() -> {'name-latin'} ) {
      $app -> form_required_absent ( 'name-latin' );
      return;
    } 
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
    
    my $mode = $app -> get_auto_logon_mode;
    $login = set_user_login( $app, $login );

    if ( defined $login
         and ( $mode eq 'login' 
               or $mode eq 'full' ) ) {
      $app -> set_auth_cookies( $login );
    }

  }

  $app -> redirect_to_screen_for_record( 'menu' );
}



sub set_user_login {
  my $app  = shift;
  my $new  = shift;
  
  my $session = $app -> session;
  my $owner   = $session -> object -> {owner};

  my $old  = $owner -> {login};
  my $reallyold = $owner ->{'old-login'};

  if ( not defined $new ) {
    return $old;
  }

  my $newlc = lc $new;
  my $oldlc = lc $old;

  if ( $newlc ne $oldlc ) {

    my $f = $app -> userdata_file_for_login( $newlc );
    if ( -e $f ) {
      ### XXX this will not allow to change account login to its previous
      ### value (previous -- in the same session).  I could add a check if $f
      ### is the same file as userdata was originally read from, but its so
      ### rare occasion... I suppose there are more important things to
      ### do now.

      $app -> error( "login-taken" );
      return $old;
    }

    if ( open HOLDER, ">$f" ) {
      print HOLDER "placeholder";
      close HOLDER;

    } else {
      $app -> error( "login-taken" );
      return $old;
    }

    $owner -> {login} = $new;
    if ( not defined $owner -> {'old-login'} ) {
      $owner -> {'old-login'} = $old;
    }

    $session -> set_object_file( $f );
    $app -> update_paths_for_login( $newlc );

    require ACIS::Web::SysProfile;
    ACIS::Web::SysProfile::rename_sysprof_id( $oldlc, $newlc );
  } 

  $owner -> {login} = $new;

  return $new;

}


sub remove_account {   
  my $app = shift;

  my $paths   = $app -> paths;
  my $session = $app -> session;
  my $input   = $app -> form_input;
  
  if ( not $input ->{'confirm-it'} ) {
    ### request the confirmation 
    return ;
  }

  if ( not $session -> owner -> {type} {advanced} ) {
    ###  SHALL NOT BE HERE, THEN.  XXX

    ###  But, at the same time, this function very well can be used for
    ###  advanced users as well.
  }

  $app -> userlog( "removing the account, per user request" );
  
  $app -> sevent ( -class  => 'account', 
                   -action => 'delete request' );
  
  my $userdata = $paths -> {'user-data'};
  my $deleted_userdata = $paths -> {'user-data-deleted'};
  
  
  while ( -e $deleted_userdata ) {
    debug "backup file $deleted_userdata already exists";
    $deleted_userdata =~ s/\.xml(\.(\d+))?$/".xml." . ($2+1)/eg;
  }

  debug "move userdata from '$userdata' to '$deleted_userdata'";
  my $check = rename $userdata, $deleted_userdata;  
  
  if ( not $check ) {
    $app -> errlog ( "Can't move $userdata file to $deleted_userdata" );
    $app -> error ( "cant-remove-account" );
    return;
  }


  ###  request RI update
  require RePEc::Index::UpdateClient;
  my $udatadir = $app -> userdata_dir;
  my $relative = substr( $userdata, length( "$udatadir/" ) );
  $app -> log( "requesting RI update for $relative" );
  RePEc::Index::UpdateClient::send_update_request( 'ACIS', $relative );
  
  
  
  ### delete the profile pages
  
  my $udata = $session -> object;
  
  foreach ( @{ $udata-> {records} } ) {
    my $file = $_ -> {profile} {file};
    
    if ( $file and -f $file ) {
      unlink $file;
      $app-> userlog( "removed profile file at $file" );
    }
    
    my $exp = $_ -> {profile} {export};
    if ( $exp ) {
      foreach ( values %$exp ) {
        unlink $_;
        $app-> userlog( "removed exported profile data: $_" );
      }
    }

  }
    
  $session -> object_set( undef );

  $app -> send_mail( 'email/account-deleted.xsl' );

  $app -> sevent ( -class  => 'account', 
                   -action => 'deleted',
                   -file   => $deleted_userdata );
    
  $app -> userlog( "deleted account; backup stored in $deleted_userdata" );
    
  debug "close the session";

  $app -> logoff_session;
  
  $app -> message( 'account-deleted' );
  $app -> success( 1 );
  $app -> set_presenter( "account-deleted" );
  
}


sub profile_overview {
  my $app = shift;
  
  $app -> variables -> {record} = $app -> session -> current_record();

  require ACIS::Web::Affiliations;
  ACIS::Web::Affiliations::prepare( $app );
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
  
  my $session = $app -> session;
  
  if ( $session -> type ne 'user' ) {
    $app -> error( 'session-wrong-type' );
    $app -> set_presenter( 'sorry' );
    $app -> clear_process_queue();
  }

}


sub settings_prepare {
  my $app    = shift;

  my $vars    = $app -> variables;
  my $session = $app -> session;
  my $mode    = $app -> get_auto_logon_mode;

  my $login = $session -> object -> {owner} {login};
  $app -> set_form_value( "email", $login );

  $vars -> {'auto-log-mode'} = $mode;

  debug "Auto-logon-mode: $mode";

  if ( $mode eq 'full'
       or $mode eq 'login' ) {
    $app -> set_form_value( "remember-login", 1 );
  }
  
  $session -> {'auto-logon-mode'} = $mode;


  if ( $mode eq 'full' ) {
    $app -> set_form_value( "remember-pass", 1 );
  }
}


sub settings {
  my $app = shift;

  my $input   = $app -> form_input;
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $owner   = $session -> object -> {owner};


  my $OK  = 1;

  my $auto_logon_mode = $app -> get_auto_logon_mode;

  my $login = $input -> {email};

  $login = set_user_login( $app, $login );

  if ( defined $login ) {
    if ( $input -> {'remember-login'} ) {
      $app -> set_auth_cookies( $login );

    } else {

      my $mode = $session -> {'auto-logon-mode'};
      if ( $mode eq 'full' 
           or $mode eq 'login' ) {
        $app -> clear_auth_cookies;
        $app -> set_form_value( "remember-login", 0 );
      }
    }
  }

  if (     $record -> {'about-owner'} 
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

  ### password 

  if ( $input ->{pass} ) {{

    my $old_real = $owner -> {password};
    my $old      = $input -> {pass};

    my $pass;

    if ( $old_real eq $old ) {
      $pass = $old;
    } else {
      $app -> error( 'bad-old-pass' ); ### 'bad-old-pass' ?
      undef $OK;
      last;
    }
    
    if ( $input -> {'pass-new'} 
         or $input -> {'pass-confirm'} ) { 

      my $new      = $input -> {'pass-new' };
      my $conf     = $input -> {'pass-confirm'};
      
      if ( $old 
           and $old_real eq $old ) {
        if ( $new eq $conf ) {
          $owner ->{password} = $new;
          $pass  = $new;
          
        } else {
          $app -> form_invalid_value( 'pass-new' );
          $app -> form_invalid_value( 'pass-confirm' );
          undef $OK;
        }
        
      } else {
        die;
      }

    }
    if ( $pass 
         and $input -> {'remember-pass'} 
         and $input -> {'remember-login'} ) {
      $app -> set_auth_cookies( undef, $pass );
    }
  }}



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
