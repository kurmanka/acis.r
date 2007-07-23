package ACIS::Web::MetaUpdate;   #   -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Gear that power the ACIS metadata update interface.
#
#
#  Copyright (C) 2005 Ivan Kurmanov for ACIS project,
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
#  $Id$
#  ---

use strict;

require ACIS::Web;


my $codes = {
200 => "Ok",
204 => "No Content",
403 => "Access Forbidden",
404 => "Not Found",
500 => "Internal Server Error",
};




sub produce_result {
  my $self = shift;
  my $code = shift;

  $self -> log( "/meta/update response $code" );
  
  my $status = "$code " . $codes->{$code};
  $self -> response_status( $status );
  $self -> print_http_response_headers;


  my $req_ip  = $ENV{REMOTE_ADDR};
  my $req_id  = $self -> form_input -> {id};

  my $req_str = "$req_id\@$req_ip";


  print <<PAGEPAGE;

<html><head><title>$status</title></head>
<body><h1>$status</h1>
<address>ACIS /meta/update</address></body></html>
PAGEPAGE

  $self -> clear_process_queue;
  undef $self -> {presenter};
}


sub authorize_request {
  my $self = shift;

  my $allowed_clients = $self -> config( 'meta-update-clients' );
  my @clients = split /\s+/, $allowed_clients;

  my $req_ip  = $ENV{REMOTE_ADDR};
  my $req_id  = $self -> form_input -> {id};
  my $req_o   = $self -> form_input -> {obj};

  my $req_str = "$req_id\@$req_ip";

  $self -> log( "/meta/update request: $req_str for $req_o" );

  foreach ( @clients ) {
    if ( $_ eq $req_str ) {
      return 1;
    }
  }

  produce_result( $self, '403' );
}



sub handle_request {
  my $self = shift;

  my $id   = $self -> form_input -> {id}  || die;
  my $obj  = $self -> form_input -> {obj} || die;

  my $mirroring = $self -> config( 'meta-update-object-fetch-func' );
  
  if ( not $mirroring ) {
    produce_result( $self, '500' );
    return;
  } 

  $self -> log( "/meta/update request from $id for '$obj'" );

  my $res;

  {
    no strict;
    $res = &$mirroring( $self, $id, $obj );
  }

  if ( ref( $res ) ne 'HASH' 
       or not $res ->{status} ) { 
    produce_result( $self, '500' );
    return;
  }
  
  my $codes = {
              "ok" => 200,
              "archive unknown" => 404,
              "can not fetch"   => 204,
             };

  my $mstatus = $res -> {status};
  my $file    = $res -> {pathname};
  my $coll    = $res -> {collection};

  if ( $mstatus eq 'ok' ) {
    require RePEc::Index::UpdateClient;
    RePEc::Index::UpdateClient::send_update_request( $coll, $file );
    produce_result( $self, '200' );

  } else {
    produce_result( $self, $codes->{$mstatus} );
  }
  
  return;
}




1;

