package ACIS::MetaUpdate::Request; # -*-perl-*-
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Client-helper module for applications and service to send metadata update
#    requests to ACIS, to the /meta/update screen.  See
#    doc/cooperate.html#level4 for more details.
#
#
#  Copyright (C) 2005 Ivan Kurmanov for ACIS project, http://acis.openlib.org/
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
#  $Id: Request.pm,v 2.0 2005/12/27 19:47:39 ivan Exp $
#  ---

use strict;

use Exporter;
use base qw( Exporter );

use vars qw( @EXPORT $CONF $LOG );
@EXPORT = qw( acis_metaupdate_request );


use LWP::UserAgent;
use HTTP::Request::Common;

sub log_it (@) {
  if ( $LOG 
       and open L, ">>", $LOG ) {
    print L scalar( localtime ), " ", @_, "\n";
    close L;
  }
}
    


sub acis_metaupdate_request {
  my $file = shift || die;
  my $para = {@_};
  
  if ( $CONF and ref $CONF eq 'HASH' ) {
    foreach ( keys %$CONF ) {
      my $v = $CONF->{$_};
      if ( not $para->{$_} ) {  $para ->{$_} = $v;  }
    }
  }
  
  $LOG            = $para -> {'log-filename'};
  my $archive_id  = $para -> {'archive-id'}         || die;
  my $request_url = $para -> {'request-target-url'} || die;


  # Create a user agent object
  my $ua = LWP::UserAgent->new;
  $ua->agent( "ACIS::MetaUpdate::Request/0.1 ");

  # Create a request
  my $req = POST $request_url, [ id => $archive_id,
                                 obj => $file ];

  log_it "sending request to $request_url, id: $archive_id, obj: '$file'";

  # Pass request to the user agent and get a response back
  my $res = $ua -> simple_request($req);

  my $code = $res -> code;
  my $st   = $res -> status_line;
  log_it "result: $st";

  # Check the outcome of the response
  if ( $code eq '200' ) {
    return 1;
  }
  
  return undef;
}




1;
