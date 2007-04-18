package ARDB::Plugin::Processing::ACIS_UD;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    ARDB's plugin for processing ACIS userdata records
#
#  It is responsible for processing the ACIS user-data files, although
#  main logic is in home/plugins/Processing/ACIS_UD/configuration.xml
#  file.
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
#  $Id: ACIS_UD.pm,v 2.2 2007/04/18 17:00:51 ivan Exp $
#  ---



use strict;

use base ( 'ARDB::Plugin::Processing' );

use Carp::Assert;


sub config {
  return 'configuration.xml';
}


sub get_record_types {
  my $self = shift;

  return [ 
    'acis-user', 
    'acis-record-person', 
  ];
}


###  standard plugin interface 

sub process_record {
  my $self   = shift;
  my $record = shift;
  my $ardb   = shift;

  my $relations = $ardb -> relations;
  
  my $record_type = $record -> type;
  my $record_id   = $record -> id;
  
  my $config     = $ardb -> {config};
  my $sql_object = $ardb -> {sql_object};

  assert( $record_id );
  
  if ( $record_type eq 'acis-record-person' ) {

    ###  persona profile processing
    my @nameset = get_name_set( $record );
    my $sid     = $record -> get_value( 'sid' );

    if ( $sid ) {
      my $record = {
                    name    => $_,
                    shortid => $sid, 
                    probability => 0xFF,
                   };
      
      foreach ( @nameset ) {
        $record -> {name} = $_;
        $config -> table( 'acis:names' ) 
          -> store_record( $record, $sql_object );
      }
    } else {
      warn "a personal record has no short-id: $record_id";
    }
  }
  
  return 1;
} 


sub record_delete_cleanup {
  my $ardb   = shift;
  my $record = shift;
  my $relations = $ardb -> relations;
  my $record_type = $record -> type;
  my $config     = $ardb -> {config};
  my $sql_object = $ardb -> {sql_object};

  if ( $record_type eq 'acis-record-person' ) {
    ###  Personal profile processing
    my $sid     = $record -> get_value( 'sid' );
    my $id      = $record -> get_value( 'id' );

    if ( $sid ) {
      # clean personal database records by sid
      my @clean = qw( acis:names       shortid
                      acis:sysprof     id
                      acis:rp_suggestions psid
                      acis:threads     psid
                      acis:apu_queue   what
                      acis:cit_old_sug psid
                      acis:cit_sug     psid
                      acis:ft_urls_choices psid
                    );
      while( scalar @clean ) {
        my $tname = shift @clean;
        my $field = shift @clean;
        if (my $table = $config->table( $tname )) {
          $table->delete_records( $field, $sid, $sql_object );
        } else {
          warn "can't clean rec $sid from table $tname";
        }
      }
    }

    $config -> table( 'acis:apu_queue' )
      -> delete_records( 'what', $id, $sql_object );

  }
  return 1;
} 



sub get_name_set {
  my $record = shift;

  my $record_type = $record -> type;
  my $record_id   = $record -> id;
  
  assert( $record_id );

  my $set = {};
  
  if ( $record_type eq 'acis-record-person' ) {

    ###  Personal profile processing

    my $nameset; 

    {
      my $name = $record -> {name};
      
      $set -> { $name -> {full} } = 1;
      if ( $name -> {latin} ) {
        $set -> { $name -> {latin} } = 1;
      }
      foreach ( @{ $name -> {variations} } ) {
        $set -> {$_} = 1;
      }
    }
  }
  
  return keys %$set;
} 



sub get_name_last {
  my $record = shift;

  my ( $name )= $record -> get_value( 'name' );
  
  my $last  = $name ->{last};
  my $first = $name ->{first};
  my $middle= $name ->{middle};
  my $suffix= $name ->{suffix};

  my $join = "$last, $first $middle";
  if ( $suffix ) {
    $join .= ", $suffix";
  }

  $join =~ s/\s+/ /g;

  return $join;
}


require Digest::MD5;

sub get_emailmd5 {
  my $record = shift;
  my $email  = $record -> get_value( 'contact/email' );
  return Digest::MD5::md5( lc $email );
}


sub generate_nameset {
  my $self   = shift;
  my $record = shift;
  
}
 
1;

