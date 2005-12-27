package ACIS::Web::Contributions::Glimpse; ## -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Interface to contributions search based on glimpse text searching
#    tool
#
#  Copyright (C) 2003 Ivan Kurmanov for ACIS project,
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
#  $Id: Glimpse.pm,v 2.0 2005/12/27 19:47:40 ivan Exp $
#  ---

use strict;

use Web::App::Common;

use ACIS::Web::Contributions;

my $command_template = '%s -H %s -%d -hy -w -i -F authors "%s"';

my $glimpse_bin;

sub search { 
  my $app     = shift;
  my $context = shift;
  my $exp     = shift;

  my $errors  = shift;


  if ( not defined $glimpse_bin ) {
    $glimpse_bin = $app -> config ( 'glimpse-binary' );

  }
  
  if( not $glimpse_bin ) {
    warn "Don't know where is glimpse to run; configure.";
    return [];
  }

  my $home = $app -> home;
  
  my $already       = $context -> {already};
  my $repeated      = $context -> {found};

  my $repeated_sids = $context -> {found_sid};
  if( not defined $repeated_sids ) {
    $repeated_sids = $context -> {found_sid} = {};
  }
  

  {
    my $original_exp = $exp;
    my $lost = ( $exp =~ s/[^\p{Latin};\-]//gi );
    my $rest = ( $exp =~ s/(\w)/$1/gi );

    if ( $lost > 3 
         or $rest < 2 ) {
      warn "glimpse search cancelled for the character set reasons ($original_exp)";
      return undef;
    }

  }
  $exp = Encode::encode( "iso-8859-1", $exp );

  my $command = sprintf ( $command_template, $glimpse_bin, $home, $errors, $exp );

##  $command = Encode::encode( "iso-8859-1", $command );

  my $found = `$command`;
  my @lines = split /\n/, $found;
  my @sids;
  my @handles;

  debug sprintf "glimpse command '%s'", $command;

  foreach ( @lines ) {
    my ( $sid ) = m/^(\w+\d+)\s/ ;

    if ( not defined $sid ) {
      warn "bad glimpse search results: '$_'";
      next;
    }

    if ( not exists $repeated_sids-> {$sid} ) {
#      $repeated_sids-> {$sid} ++;
      push @sids, $sid;
    }
#    debug "match: $sid (line: $_)";
    
  }

  debug sprintf "glimpse found %d new results ", scalar @sids;

  if ( not scalar @sids ) {
    return undef;
  }


  my $db = $context->{db};
  my $query_template = 
  "$ACIS::Web::Contributions::select_what from $db.resources where ( %s ) %s";
  my $sid_condition = " " x 200;
  my $excl_condition = " " x 200;


  ###  exclusion condition
  $excl_condition = '';
  foreach ( keys %$repeated, keys %$already ) {
    $excl_condition .= ' id="' . $_ . '" or';
  }
  
  if ( $excl_condition ) {
    substr( $excl_condition, "-2", 2 ) = '';
    $excl_condition = " and not ( $excl_condition )";
  }
  my $sql = $app -> sql_object;


  my @final;


  ###  LOOP START

  while ( scalar @sids ) {
    ### each the @sids array by small batches

    my @sid_portion = splice( @sids, 0, 10 );
    
    $sid_condition = '';
    foreach ( @sid_portion ) {
      $sid_condition .= ' sid="' . $_ . '" or';
    }
    substr( $sid_condition, "-2", 2 ) = '';


    $sql -> prepare( sprintf( $query_template, $sid_condition, $excl_condition ) ) ;

    debug "sql: "  . sprintf( $query_template, $sid_condition, $excl_condition );

    my $res = $sql -> execute;
    warn "SQL: " . $sql->error if $sql->error;
  
    my $results = [];

    if ( $res ) {
      ACIS::Web::Contributions::process_resources_search_results( $res, 
                                                                  $context, 
                                                                  $results );
    }

    debug sprintf "so far, %d new items found", scalar @$results;

    my $approximate = $context -> {approximate};
    if ( not defined $approximate ) {
      $approximate = $context -> {approximate} = [];
    }
    push @$approximate, @$results;
    push @final, @$results;
  }

  ###  LOOP END 

  ### count
  foreach ( @sids ) {
    $repeated_sids->{$_} ++;
  }
  
  return \@final;
}


1;

