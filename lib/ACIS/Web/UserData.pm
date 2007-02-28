package ACIS::Web::UserData;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Class, representing an ACIS user record.  Important at the core
#    level of the web application framework.  
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
#  $Id: UserData.pm,v 2.1 2007/02/28 21:45:06 ivan Exp $
#  ---



use strict;

use ACIS::Data::DumpXML; # qw( dump_xml )
use ACIS::Data::DumpXML::Parser;

use Web::App::Common;

sub new {
  my $class = shift;
  my $file  = shift;

  my $self = {
              'owner'   => { },
              'records' => [ { }, ],
              '_'       => {},
             };

  bless $self, $class;

  if ( defined $file ) {
    $self -> set_save_to_file( $file );
  }

  return $self;
}


sub load {
  my $class = shift;
  my $file  = shift;
  
  my $self;
  eval {
    $self  = ACIS::Data::DumpXML::Parser -> new -> parsefile ( $file );
  };
  
  return undef if $@;
  return undef if not $self;
  
  $self -> {_} -> {file}           = $file;
  $self -> {_} -> {file_read_from} = $file;
  $self -> {_} -> {file_save_to  } = $file;
     
  return $self;
}
 

sub read_from_file {
  my $self = shift;
  return $self -> {_} {file_read_from};
}

sub save_to_file {
  my $self = shift;
  return $self -> {_} {file_save_to};
}

sub set_save_to_file {
  my $self = shift;
  my $file = shift;
  
  $self -> {_} {file_save_to} = $file;
}

sub changed {
  my $self = shift;
  $self -> {_} -> {changed} = 1;
}


sub dump_xml {
  my $self = shift;
  my $inner = $self -> {_};
  delete $self -> {'internal-variables'};
  delete $self -> {_};

  local $ACIS::Data::DumpXML::INDENT = ' '; # for lighter userdata files
  local $ACIS::Data::DumpXML::LIST_ITEM_POS_ATTRIBUTE = 0;
  my $xml = ACIS::Data::DumpXML::dump_xml($self);

  $self -> {_} = $inner;
  return $xml;
}
 

sub save {
  my $self = shift;

  my $file = $self -> {_} {file_save_to};
  
  debug "user-data saving to '$file'";

  my $xml = $self -> dump_xml;

  if ( not open TO_SAVE, ">:utf8", $file ) {
    debug "can't open $file for writing";
    return undef;
  }

  print TO_SAVE $xml;
  close TO_SAVE;

  debug "written userdata " . length( $xml ) , " characters to $file";
  return $file;
}
 
1;
