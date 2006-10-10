package ACIS::Web::Session::SNewUser;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    New User's session class
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
#  $Id: SNewUser.pm,v 2.1 2006/10/10 15:05:08 ivan Exp $
#  ---

use strict;

use Carp::Assert;

use ACIS::Web::Session;
use ACIS::Web::UserData;

use base qw( ACIS::Web::Session );

use Web::App::Common qw( &date_now );

sub new {
  my $class = shift;
  my $acis  = shift;
  my $login = shift;

  my $self  = $class -> SUPER::new( $acis, @_ ); 

  if ( $self ) { 
    $acis    -> update_paths_for_login ( $login );
    my $udata = $acis -> create_userdata();
    $self    -> object_set( $udata );
    $udata -> {owner} = $self ->{'.owner'};
  }

  return $self;
}


sub type { 'new-user' }


sub close {
  my $self = shift;
  my $app  = shift;
  assert( $app );

  ### save initial registration date
  my $userdata = $self  -> object ;
  my $owner = $userdata -> {owner};
  $owner -> {'initial-registered-date'} = date_now();

  ### generate static pages and metadata files
  require ACIS::Web::SaveProfile;
  ACIS::Web::SaveProfile::save_profile( $app );

  ### write userdata
  $self -> save_userdata( $app );

  ### send emails

  ### send submitted institution emails
  ### XXX This code is repeated.  Should not be so:
  my $submitted = $self -> {'submitted-institutions'};
  foreach ( @$submitted ) {
    if ( $_ ->{note} 
         and length( $_->{note} ) > 750 ) {
      substr( $_->{note}, 750 ) = '...';
    }
    $app -> variables -> {institution} = $_;
    $app -> send_mail ( 'email/new-institution.xsl' );
  }

  ### remove registration session
  my $old_session_file = $self ->{'remove-old-session-file'};
  unlink $old_session_file;

  $self -> SUPER::close( $app );
}



sub close_without_saving {
  my $self = shift;
  my $app  = shift;
  assert( $app );

  $app -> log( "session close without saving data" );

  $app -> sevent ( -class  => 'session',
                   -action => 'discard',
                 -startend => 0 
                 );

  my $sql = $app -> sql_object;

  my $id  = $self -> id;
  foreach ( qw( suggestions/psid threads/psid sysprof/id ) ) {
    my ( $table, $field ) = split '/', $_;
    $sql -> do( "delete from $table where $field='$id'" );
  }

  $self -> SUPER::close( $app );
}

1;
