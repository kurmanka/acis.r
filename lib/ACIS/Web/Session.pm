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

use strict;
use Storable;
use Data::Dumper;
use Carp::Assert;

use ACIS::Web::UserData;
use Web::App::Common;
use base qw( Web::App::Session );
use ACIS::SessionHistory;

sub new {
  my $class = shift;
  my $acis  = shift;
  my $self  = $class -> SUPER::new( $acis, @_ ); 
  session_start( $self );
  return $self;
}

sub username {
    my $self = shift;
    my $o = $self->userdata_owner || $self->{'.owner'} || {};
    return $o->{login} || undef;
}

sub load {
  my $class = shift;
  my @param = @_;

  my $self  = $class -> SUPER::load( @param );

  return $self;
}


sub current_record { 
  my $self = shift;

  debug "->current_record";
  if ($self->{'.userdata.current_record'}) {
      debug "giving {.userdata.current_record}";
      return( $self->{'.userdata.current_record'} );
  }
  
  my $userdata = $self-> userdata || die; 

  if ( defined $userdata ) {
    my $rec_no = $self -> {'.userdata.current_record.no'} || 0;
    $self -> set_current_record_no( $rec_no );
    return $self->{'.userdata.current_record'};
  }

  return undef;
}


sub choose_record_by_id {
  my $self = shift;
  my $id   = shift || die;

  my $cr = $self->{'.userdata.current_record'};
  if ($cr) {
      if ($cr->{sid} eq $id) { return 1; }
      if ($cr->{id} eq $id)  { return 1; }
  }

  my $num  = 0;
  my $list = $self->userdata->{records};
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
  return $self -> {'.userdata.current_record.no'};
}

sub set_current_record_no {
  my $self = shift;
  my $no   = shift;

  assert( defined $no );

  my $old = $self -> {'.userdata.current_record.no'};
  if ( defined $old and ($old == $no) ) { return $old; }

  debug "->set_current_record_no( $no )";

  if ( defined $old ) {
      debug "save current record and save userdata (temp)";
      $self ->save_current_record('closeit');
      $self ->save_userdata_temp;
  }

  $self -> {'.userdata.current_record.no'} = $no;

  my $userdata = $self-> userdata;
  my $records  = $userdata ->{records};
  my $reclist  = $self->{'.userdata.record_list'};

  if ( defined $userdata
       and defined $records
       and scalar @$records 
     ) {

      my $app = $self ->{'.app'};
      my $rec = $records -> [$no]; 

      if (not $rec) { die "no such record: $no"; }
      $self->{'.userdata.current_record'} = $rec;
      
      if ( $rec->{id} ) {
          $app -> sevent( -class => 'record',
                          -descr => 'identifier',
                          -id    => $rec ->{id},
                          $rec->{sid} ? ( -sid   => $rec ->{sid} ) : ()
          );
          debug "set_current_record: id:$rec->{id}, sid:$rec->{sid}";


          # now do some compatibility checks & upgrades for the record
          if ($reclist and 
              not $reclist->[$no]->{upgradechecked}) {
              $reclist->[$no]->{upgradechecked} = 1;
              require ACIS::Web::Person;
              ACIS::Web::Person::bring_up_to_date( $ACIS::Web::ACIS, $rec );
          }

      }
      return $old;

  } else { 
      # WTF?
      return undef; 
  }
    
}


sub set_default_current_record {
    my $self = shift;
    my $userdata = $self->userdata;
    my $records = $userdata->{records};

    if ($self->{'.userdata.current_record'}) {
        return;
    }

    debug "->set_default_current_record()";
    if (scalar @$records == 1) {
        $self->set_current_record_no(0);

    } elsif ($records->[0]->{'about-owner'} eq 'yes') {
        $self->set_current_record_no(0);
    } else {
        debug "->set_default_current_record(): no luck";
    }
}


sub save_userdata_temp {}   # overridden in SOldUser
sub save_current_record {}  # overridden in SOldUser


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
      local $/;
      $udata_string = <USERDATA>;
      close USERDATA;

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


sub set_userdata {
  my $self   = shift;
  my $object = shift;
  my $file   = shift;

  if ( not defined $file and defined $object ) {
    $file = $object -> save_to_file;   ### XX UserData interface
  }
  
  my $login = $object->{owner}->{login};
  if ($login) {
      $self->{'.app'}->update_paths_for_login( $login );
  }

  return $self -> SUPER::object_set( $object, $file, @_ );
}


sub set_userdata_file {
  my $self    = shift;
  my $newfile = shift;
  my $inner = $self ->{_};
  $inner ->{object} -> set_save_to_file( $newfile ); ### XX UserData interface
  return $self -> SUPER::set_object_file( $newfile );
}


sub userdata {
  my $self   = shift;
  return $self -> object( @_ );
}

sub object_set {
  my $self   = shift;
  return $self -> set_userdata( @_ );
}

sub set_object_file {
  my $self   = shift;
  return $self -> set_userdata_file( @_ );
}

sub userdata_owner { 
    my $self = shift;
    if ($self->{'.userdata.owner'}) { return $self->{'.userdata.owner'}; }
    my $userdata = $self->userdata;
    if ($userdata) { return $userdata->{owner}; }
    return undef;
}

sub userdata_record_list { return undef; }

sub save_userdata {
  my $self = shift;
  my $app  = shift;
  
  my $udatadir = $app -> userdata_dir;

  ###  save the userdata
  my $udata_file = $self -> save_userdata_file;
  
  $app -> userlog ( "log off: wrote ", $udata_file );
  $app -> sevent ( -class  => 'session',
                   -action => 'saved',
                   -descr  => 'userdata',
                   -file   => $udata_file );
  
  ###  request RI update
  eval {
    my $relative = substr( $udata_file, length( "$udatadir/" ) );
    $app->send_update_request( 'ACIS', $relative );
  };
  if ( $@ ) {
    warn "sending update request for $udata_file ($udatadir) failed: $@";
  }

}


# this is overriden in the SOldUser class
sub save_userdata_file {
    my $self = shift;
    ###  save the userdata
    my $udata_file = $self -> object -> save;
}
    

sub close_without_saving {
  my $self = shift;
  my $app  = shift;
  assert( $app );
  $self->{'.discarded'} = 1;
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
      if ($@) {
        complain "a problem during run_at_close session hook: $@, original code was: `$_'";
      }
    }
  }

  if ( $self->{'.discarded'} ) {
    $app -> log( "session close without saving data" );
    $app -> sevent ( -class  => 'session',
                     -action => 'discard',
                     -startend => 0 
                   );
    session_discard( $self );
  } else {
    session_stop( $self );
  }

  $self -> SUPER::close( $app );
}


sub very_old { 0 };




1; ###    t h e   e n d    ###
