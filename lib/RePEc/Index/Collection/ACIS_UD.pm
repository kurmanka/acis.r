package RePEc::Index::Collection::ACIS_UD; ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    ...
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
#  $Id: ACIS_UD.pm,v 2.0 2005/12/27 19:47:40 ivan Exp $
#  ---



use strict;
use base 'RePEc::Index::Collection';


use Carp::Assert;
use Data::Dumper;
use Digest::MD5 'md5_hex';

use Web::App::Common;
use ACIS::Data::DumpXML::Parser;

use ACIS::UserData::User::Record;
use ACIS::UserData::Data::Record;


sub open_data_file {

  my $self = shift;
  my $file = shift;
  
  $self -> {position} = -1;
  
  debug 'try open file';

  if ( not $file =~ m/\.xml$/i ) {
    return 0;
    $self -> {ghost} = 1;
    $self -> {filename} = $file;
    return 'true';
  }
  
  eval { 
    $self -> {data}  =
      ACIS::Data::DumpXML::Parser -> new -> parsefile ( $file ); 
    $self -> {ghost} = 0;
  };
  
  if ( $@ ) {
    debug "errors: $@";
    return undef;
  }
  
  $self -> {filename} = $file;
#  debug 'all ok';
  
  return 'true';
}


sub get_next_record {
  my $self = shift;

  if ( $self ->{ghost} ) { 
    return 0;
  }

  my $data;
  my $checksum;
  
#  debug 'try getting a record';
  
  my $pos = $self -> {position};
  $self -> {position}++;

  if ( $pos < 0 ) {

#    warn 'returning ACIS user record';
#    debug 'returning ACIS user record';
    $data  = $self -> {data} {owner};
    
    return 0
     unless defined $data;
    
    $checksum = md5_hex(Dumper $data);
    
    bless $data, 'ACIS::UserData::User::Record';
    debug 'received';

  } else {
    $data  = $self -> {data} {records} [$pos];

    if ( not defined $data ) {
      return 0;
    }

    if (    not $data->{id} 
         or not $data->{type} 
         or not $data->{type} eq 'person' 
      ) {
      next;
    }
    
    $data -> {LOGIN} = $self -> {data} {owner} {login};
    $checksum = md5_hex ( Dumper $data );
    
    bless $data, 'ACIS::UserData::Data::Record';
    debug 'received';
  }
  
  $data -> {FILENAME} = $self -> {filename}; 
  

  return ( ($data->id), $data, $data -> type, 0, $checksum );
}
 

sub check_id {
  return 1;
}


sub make_monitor_file_checker { 
  return sub { 
    if ( m/\.xml$/i ) {  return 1; }
    else { return 0; }
  }
}

sub make_monitor_dir_checker { 
  return sub { 
    if ( m/^(CVS|RCS)$/i ) {  return 0; }
    else { return 1; }
  }
}

 
1;
