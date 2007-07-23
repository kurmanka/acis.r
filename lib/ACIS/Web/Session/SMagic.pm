package ACIS::Web::Session::SMagic;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Existing User's magic maintenance session class
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
#  $Id$
#  ---

use strict;

use Carp::Assert;

use Web::App::Common;

use ACIS::Web::Session::SOldUser;
use ACIS::Web::UserData;

use base qw( ACIS::Web::Session::SOldUser );


sub type { 'magic' }  

# sub new { 
#  my $class = shift;
#  my @para = @_;
#  my $acis  = $para[0];
#  my $owner = $para[1];
#  my $s = $class -> SUPER::new( @para );
# 
#  return $s;
#}

sub set_notify_template { 
  my $self = shift;
  my $file = shift;  assert( $file );
  $self -> {_} {notify_template} = $file;
}

sub notify_user_about_profile_changes {
  my $self = shift;
  my $app  = shift;
  my $mode = $self -> {_}{mode};
  my $file = $self -> {_}{notify_template};

  if ( $file ) { 
    $app -> send_mail( $file );
  }
}

1;
