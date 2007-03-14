package ACIS::Web::Session;   ### -*-perl-*-  
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    ACIS session class, general
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
#  $Id: Session.pm,v 2.4 2007/03/14 18:27:49 ivan Exp $
#  ---

use strict;
use Storable;
use Data::Dumper;
use Carp::Assert;

use ACIS::Web::UserData;
use Web::App::Common;
use base qw( Web::App::Session );

sub find_userdata_record_by_sid {
  my $self = shift;
  my $id  = shift;
  
  my $userdata = $self     -> object;
  my $records  = $userdata -> {records};

  if ( scalar( @$records ) == 1 ) {

    if ( $records -> [0] {sid} eq $id ) { return 0; }
    if ( $records -> [0] {id}  eq $id )  { return 0; }
    
  } elsif ( scalar( @$records ) > 1 ) {    

    my $no = 0;
    foreach ( @$records ) {
      if ( $_ ->{sid} eq $id ) { return $no; }
      if ( $_ ->{id}  eq $id ) { return $no; }
      $no++;
    }
  }

  return undef;
}


sub load {
  my $class = shift;
  my @param = @_;

  my $self  = $class -> SUPER::load( @param );

  ### respect request parameter "short-id"
  if ( $self ) {
    my $app = $self -> {'.app'};
    if ( my $sid = $app -> {request} {'short-id'} ) {
      debug "request -> sid:$sid";
      
      my $number = $self -> find_userdata_record_by_sid( $sid );
      if ( defined $number ) {
        $self -> set_current_record_no( $number );
        
      } else {
        $app  -> error( "bad-short-id-in-request" );
      } 
    }
  }

  return $self;
}


sub current_record { 
  my $self = shift;

  my $userdata = $self-> object;

  if ( defined $userdata
       and defined $userdata   -> {records}
       and scalar @{ $userdata -> {records} } 
     ) {

    my $rec_no = $self -> {'current-record-number'};

    if ( not defined $rec_no ) {
      $rec_no = 0;
      $self -> set_current_record_no( $rec_no );
    }

    return $userdata -> {records} -> [$rec_no];
  }

  return undef;
}


sub choose_record {
  my $self = shift;
  my $id   = shift || die;

  my $num  = 0;
  my $list = $self->object->{records};

  foreach ( @$list ) {
    if ( $_ ->{id} eq $id 
         or $_ ->{sid} eq $id ) { 
      $self -> set_current_record_no( $num );
      return 1;
    }
    $num ++;
  }
  return undef;
}


sub get_current_record_no {
  my $self = shift;
  return $self -> {'current-record-number'};
}

sub set_current_record_no {
  my $self = shift;
  my $no   = shift;

  assert( defined $no );

  my $userdata = $self-> object;
  if ( defined $userdata
       and defined $userdata   ->{records}
       and scalar @{ $userdata ->{records} } 
     ) {
    my $records = $userdata ->{records};
    if ( scalar @$records ) {
      my $old = $self -> {'current-record-number'};
      $self -> {'current-record-number'} = $no;

      if ( not defined $old or $old != $no ) {

        my $app = $self ->{'.app'};
        my $rec = $userdata ->{records} [$no]; 

        if ( $rec->{id} ) {
          $app -> sevent( -class => 'record',
                          -descr => 'identifier',
                          -id    => $rec ->{id},
          $rec->{sid} ? ( -sid   => $rec ->{sid} ) : ()
                        );
          debug "set_current_record: id:$rec->{id}, sid:$rec->{sid}";
        }
      }

      return $old;
    } 
  } 
  return undef;
}



use RePEc::Index::UpdateClient qw( &send_update_request );


sub has_userdata_changed {
  my $self = shift;
  my $app  = shift;
  
  my $udata_file = $self ->object ->read_from_file;
  my $udata_string;

  if ( not defined $udata_file ) { return 1; } ###  quite logical, isn't it?


  ### compare the copy of userdata in session and in file
  if ( -f $udata_file ) {

    if ( open USERDATA, "<:utf8", $udata_file ) {  ### XX PERL5.8 dependency
      # load the userdata file
      my $irs = $/; undef $/;
      $udata_string = <USERDATA>;
      close USERDATA;
      $/ = $irs;

#      $udata_real  = ACIS::Data::DumpXML::Parser ->new ->parse( $udata_string );
# that could be useful if we wanted to check each individual record for change
      debug "loaded old userdata file";

    } else {
      $udata_string = undef;
      warn "can't open userdata file for reading: $!";
      $app -> errlog( "can't open userdata file '$udata_file' for reading: $!" );
      return 1;
    }

    
  } else {
    debug "there's no old user-data file";
    ###  that would happen for all new users

    return 1;
  } 

  my $ses_udata        = $self -> object;
  my $ses_udata_string = $ses_udata -> dump_xml;

  if ( not $ses_udata_string ) {
    debug "empty ses_udata dump";
    die "empty ses_udata dump";
  }

  if ( $ses_udata -> {owner} {'last-login-date'} ) {
    my $d = $ses_udata -> {owner} {'last-login-date'};
    debug "last-login-date is in the sessions's udata: $d";
  }

  for ( $ses_udata_string, $udata_string ) {
    $_ =~ s/(\n\s+)?<last\-login\-date.+//;
    $_ =~ s/(\n\s+)?<last\-change\-date.+//;
  }
  if ( $udata_string =~ m/last\-login\-date(.+)/ ) {
    debug "udata_string still has the login date: $1";
  }
  if ( $ses_udata_string =~ m/last\-login\-date(.+)/ ) {
    debug "ses_udata_string still has the login date: $1";
  }
  
  

  debug 'comparing the userdatas'; 

  if ( $ses_udata_string ne $udata_string )   {
    debug 'found some changes';

#    debug "ses_udata_string: $ses_udata_string\n---------";
#    debug "udata_string: $udata_string\n--------";
    return 1;

  } else {
    debug 'found no changes';
    return 0;
  }

}


sub object_set { 
  my $self   = shift;
  my $object = shift;
  my $file   = shift;

  if ( not defined $file and defined $object ) {
    $file = $object -> save_to_file;   ### XX UserData interface
  }

  return $self -> SUPER::object_set( $object, $file, @_ );
}


sub set_object_file {
  my $self    = shift;
  my $newfile = shift;

  my $inner = $self ->{_};
  $inner ->{object} ->  set_save_to_file( $newfile ); ### XX UserData interface
  return $self -> SUPER::set_object_file( $newfile );
}



sub save_userdata {
  my $self = shift;
  my $app  = shift;
  
  my $udatadir = $app -> userdata_dir;
  ###  save the userdata

  
  my $udata_file = $self -> object -> save;
  
  $app -> userlog ( "log off: wrote ", $udata_file );
  $app -> sevent ( -class  => 'session',
                   -action => 'saved',
                   -descr  => 'userdata',
                   -file   => $udata_file );
  
  ###  XXX write out the metadata ?

  ###  request RI update
  eval {
    my $relative = substr( $udata_file, length( "$udatadir/" ) );
    $app -> log( "requesting RI update for $relative" );
    send_update_request( 'ACIS', $relative );
  };
  if ( $@ ) {
    warn "sending update request failed: $@";
  }

}


sub close_without_saving {
  my $self = shift;
  my $app  = shift;
  assert( $app );
  $self -> close( $app );
}

sub run_at_close {
  my $self = shift;
  my $code = shift || die;
  my $list = $self->{'.run_at_close'} ||= [];
  push @$list, $code;
}

sub close {
  my $self = shift;
  my $app  = shift;
  if (my $l = $self->{'.run_at_close'}) {
    foreach (@$l) {
      # that's a trick
      eval $_;
    }
  }
  $self -> SUPER::close( $app );
}

1; ###    t h e   e n d    ###
