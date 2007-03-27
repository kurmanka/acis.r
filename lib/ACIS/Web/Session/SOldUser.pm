package ACIS::Web::Session::SOldUser;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Old User's session class
#
#
#  Copyright (C) 2003 Ivan Kurmanov, ACIS project, http://acis.openlib.org/
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
#  $Id: SOldUser.pm,v 2.4 2007/03/27 12:16:49 ivan Exp $
#  ---

use strict;

use Carp::Assert;

use Web::App::Common qw( &date_now debug );

use ACIS::Web::Session;
use ACIS::Web::UserData;

use base qw( ACIS::Web::Session );


sub type { 'user' }  

sub close {
  my $self = shift;
  my $app  = shift || die;
  
  ### save last login (logoff) date
  my $userdata = $self  -> object ;

  if ( $userdata ) {
    my $owner = $userdata -> {owner};
    if ( $self -> has_userdata_changed ) {

      $owner -> {'last-change-date'} = date_now();
      ###  process userdata owner login change
      if ( $owner -> {'old-login'} ) {
        $app -> userlog ( "log off: login change from ", 
                          $owner->{'old-login'},
                          " to ", 
                          $owner->{login}
                        );
        
        $app -> send_mail ( 'email/user-login-changed.xsl' );
        
        my $udata_file = $self -> object_file_read_from();
        
        debug "old userdata file is: $udata_file, trying to delete it";
        
        if ( not unlink $udata_file ) {
          warn "can't delete $udata_file: $!";
          $app -> errlog ( "can't delete $udata_file: $!" );
        }
        delete $owner -> {'old-login'};
      }
      delete $owner -> {placeholder_file};

      
      eval { 
        ### generate static pages and metadata files
        if ( not $self -> {'.saved_profile'} ) {
          require ACIS::Web::SaveProfile;
          ACIS::Web::SaveProfile::save_profile( $app );
        }
      };
      my $prob = $@;

      ### write userdata and request RI update
      $self -> save_userdata( $app );
      
      if ( $prob ) { die $prob; }
      $self -> notify_user_about_profile_changes( $app );
    }
  }


  ### - send submitted institution emails -
  ### XXX This code is repeated here and in ::SNewUser.  It should be
  ### removed after a while, when all existing sessions are processed.
  my $submitted = $self -> {'submitted-institutions'};
  if ( ref $submitted ) {
    foreach ( @$submitted ) {
      next if not $_;
      $app -> variables ->{institution} = $_;
      $app -> send_mail( 'email/new-institution.xsl' );
      undef $_;
    }
  }

  $self -> SUPER::close( $app );
}




sub notify_user_about_profile_changes {
  my $self = shift;
  my $app  = shift;
  
# do nothing
#  ### send email
#  $app -> send_mail ( 'email/user-data-changed.xsl' );
}


1;
