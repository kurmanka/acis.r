package ACIS::Web::Site;  ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    This module is responsible for managing local site's pages, serving them,
#    when needed.
#
#
#  Copyright (C) 2003-4 Ivan Kurmanov
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
#  $Id$
#  ---


use strict;

use Web::App::Common;
use ACIS::Web;

sub serve_local_document {
  my $app = shift;
  
  my $request = $app -> request;

  my $screen = $request ->{screen}    || '';
  my $sub    = $request ->{subscreen} || '';
  my $doc;

  $doc = "$screen/$sub";
  $doc =~ s!//!/!g;
  $doc =~ s!(^/|/$)!!g;
  if ( $doc eq '/' ) { return undef; }

  my $sitehome = ( $app -> home ) . "/site";

  my $file;
  if ( $doc ) {
    my $xml = "$sitehome/$doc.xml";

    if ( -d  "$sitehome/$doc" ) {
      $xml = "$sitehome/$doc/index.xml";
    }

    debug "document: $xml?";
    if ( -e $xml and -f _ and -r _ ) { 
      $file = $xml;
      debug "yes"; 
    } else { debug "no"; }
  }

  if ( $file and -f $file and -r _ ) {
    $app -> variables -> {filename} = $file;

    $app -> response -> {'allow-cache'} = 1;
#    $app -> set_presenter( "local-document" );
#    $app -> clear_process_queue;
    return 1;
  }
  return undef;
}





sub homepage {
  my $app = shift;
  my $vars = $app -> variables;

  require ACIS::Web::User;

  if ( &ACIS::Web::User::normal_login( $app ) ) {
    return;
  }

  my $seid = $app -> request -> {'session-id'};

  if ( $seid ) {
    my $try = $app -> load_session( 1 );
    if ( $try eq 'no-good-password' ) {
      ###  could have logged-in, but need a valid password.
      ###  here I need information about that session to give it to the user:
      ###  who's session?  (what type it was of?)

    } elsif ( not $app -> session ) {
      $app -> set_cookie( -name  => 'session',
                          -value => '' );
    } else {
      return 1;
    }
  }

  # try authenticating
  $app -> authenticate;

  # prepare the remember-me checkbox value
  my $remember_me = $app->get_cookie('remember-me');
  $remember_me = not defined $remember_me or ($remember_me ne 'notnow');
  $app->set_form_value( 'remember-me', $remember_me );
}


1;
