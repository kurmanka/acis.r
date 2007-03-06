package ACIS::Web::SaveProfile;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Module, responsible for updating static files when 
#    a profile has changed.
#
#  Copyright (C) 2003 Ivan Kurmanov, ACIS project, http://acis.openlib.org/
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
#  $Id: SaveProfile.pm,v 2.3 2007/03/06 22:37:09 ivan Exp $
#  ---

use strict;

use Carp::Assert;

use Web::App::Common;

use ACIS::Web::SysProfile;


sub save_profile {
  my $app = shift;

  my $session          = $app       -> session ;
  my $ses_udata        = $session   -> object  ;
  my $ses_udata_string = $ses_udata -> dump_xml;

  my @profiles = ();
  my $number   =  0;

  my $variables = $app -> variables;

  use Storable qw( dclone );
  
  $variables ->{'profile-owner'} = dclone $session -> object -> {owner};

  my $login      = $session -> object -> {owner} {login};
  my $last_login = get_sysprof_value( $login, "last-login-date" );
  if ( $last_login ) {
    $variables ->{'profile-owner'} {'last-login-date'} = $last_login;
  }

  foreach my $record ( @{ $ses_udata ->{records} } ) {
    my $id = $record ->{id};
    $session -> set_current_record_no( $number );

    {
      use ACIS::Web::Export;
      my $res = ACIS::Web::Export::redif( $app, $record );
      debug( "ReDIF export: ", (($res) ? "OK" : "FAILED") );
      if (not $res) {
        debug "res: $res";
      }

      $res = ACIS::Web::Export::amf( $app, $record );
      debug( "AMF export: ", (($res) ? "OK" : "FAILED") );
    }

    if ( $record ->{type} eq 'person' ) {
      my $sid   = $record ->{sid};

      ### update the personal profile
      if ( $sid ) {
        my $link = &write_outside_personal_profile( $app );
        push @profiles, { name => $record->{name} {full}, 
                          link => $link };

      }
                                 
      ###  has this particular record changed recently?  
#        my $orig_record   = $userdata_records ->{$id};
#        my $record_string = dump_xml( $record );

      ###  if so, notify the person it is about (by email)
      ###  (of course, if we have the email)

    } # if type == "person"

  } continue {
    $number ++;
      
  } # for each of the records in session
    
  $variables -> {'saved-profiles'} = \@profiles;
  $app -> success( 1 );
  $session -> {'.saved_profile'} = 1;
  
}



sub write_outside_personal_profile {
  my $app    = shift;

  my $variables = $app ->variables;
  my $session   = $app ->session;
  my $record    = $session ->current_record;

  assert( $record ->{type} eq 'person' );

  debug 'preparing the profile to write';

  $variables ->{record} = $record;


  ###  prepare affiliations 
  $variables ->{affiliations} = undef;

  require ACIS::Web::Affiliations;

  ACIS::Web::Affiliations::prepare( $app );

  ###  prepare photo
  if ( $record ->{photo} ) {
    $variables ->{photo}     = $record ->{photo} {url};
  }


  ###  prepare contributions 
  require ACIS::Web::Contributions;

  ACIS::Web::Contributions::prepare_the_role_list( $app );
#  ACIS::Web::Contributions::prepare( $app );
  $variables ->{contributions} = undef;


  my $url  = $app -> personal_static_url ;
  my $file = $app -> personal_static_file;

  if ( not $url or not $file ) {
    $app -> errlog ( "how am I supposed to save personal profile,"
                     . " when I can't get the url and file?" );

  } else {

    my $second_try;
    while ( 1 ) {  ###  save the profile

      my $profile_file = "${file}.html";
      my $profile_url;
      if ( $url =~ m(/$) ) {
        $profile_url = $url;
      } else {
        $profile_url = "${url}.html";
      }

      $record -> {profile}{url}  = $profile_url;
      $record -> {profile}{file} = $profile_file;
      $variables ->{permalink}   = $profile_url;
      debug "profile file: $profile_file";
      debug "profile url : $profile_url";
      
      
      ### generate the page
      my $pageref = $app -> run_presenter( 'person/profile-static.xsl',
                                           -hideemails => 1 ); 
      # run_presenter() returns a string or a reference to a string:     
      if ( not ref $pageref ) { my $p = $pageref; $pageref = \$p; }
      
      if ( open HTML, '>:utf8 ', $profile_file ) {
        print HTML $$pageref;
        close HTML;
        $app -> userlog ( "log off: wrote $profile_file" );
        $app -> sevent (
                        -class  => 'profile',
                        -action => 'written',
                        -URL    => $profile_url,
                        -file   => $profile_file,
                       );
        last;

      } else {
        $app -> errlog ( "Can't write profile page to $profile_file" );

        if ( $second_try ) {
          $app -> error ('outside-profile-cannot-store');
          last;
        }

        $url  = $app -> personal_static_url ( 1 );
        $file = $app -> personal_static_file( 1 );
        $second_try = 1;
      }

      debug "profile page contains ". length( $$pageref ) . " chars";
    }
  }
  
  ### clean up after myself

  delete $variables ->{record};
  delete $variables ->{affiliations};
  delete $variables ->{contributions};
  delete $variables ->{photo};

  return $variables ->{permalink};
}



1;
