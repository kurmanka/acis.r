package ACIS::Web::Export; ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Data Export module
#
#  Copyright (C) 2003 Ivan Kurmanov, ACIS project,
#  http://acis.openlib.org/
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

use Web::App::Common ;

sub redif {
  my $acis   = shift;
  my $record = shift;
  my $gendir = $acis ->config( 'metadata-redif-output-dir' ) or return undef;
  debug( "ReDIF: gendir $gendir" );

  my $sid  = $record ->{sid};
  if ( not $sid ) { 
    $acis -> error( 'no-short-id' );
    return undef; 
  }
  assert( $sid );
  
  my ( $f, $s, $t ) = unpack( "aaa", $sid );
  my $tail  = "$f/$s/$t";
  force_dir( $gendir, $tail );

  my $filename = "$gendir/$tail/$sid.rdf";
  debug( "ReDIF: filename $filename" );

  ###
  my $redif = make_redif_template( $acis, $record );

  if ( not $redif ) {
    $acis -> error( "cant-generate-redif" );
    return 0;
  }

  if ( open FILE, ">:utf8", $filename ) {
    print FILE "\x{FEFF}";
    print FILE $redif;
    close FILE;

    if ( not $record -> {profile} ) {
      $record -> {profile} = {};
    }

    $record -> {profile}{export}{ReDIF} = $filename;
  
    $acis -> variables -> {'redif-data-written'} = $filename;
    return $filename;
  }

  $acis -> error( "cant-open-redif-file" );
  return 0;
}



sub make_redif_template {
  my $acis = shift;
  my $rec  = shift;

  my $stylesheet = "export/redif.xsl";
  my $variables  = $acis ->variables;
  $variables ->{record} = $rec;

  ###  prepare contributions 
  require ACIS::Web::Contributions;
  ACIS::Web::Contributions::prepare_the_role_list( $acis );
  delete $variables ->{contributions};

  my $page = $acis -> run_presenter( $stylesheet, -hideemails => 1 );   

  delete $variables ->{record};
  if ( ref $page ) { return $$page; }
  return $page;
}








sub amf {
  my $acis   = shift;
  my $record = shift;

  my $gendir = $acis -> config( 'metadata-amf-output-dir' ) 
    or return undef;
  debug( "AMF: gendir $gendir" );

  my $sid  = $record ->{sid};
  
  my ( $f, $s, $t ) = unpack( "aaa", $sid );
  my $tail  = "$f/$s/$t";
  force_dir( $gendir, $tail );

  my $filename = "$gendir/$tail/$sid.amf.xml";
  debug( "AMF: filename $filename" );

  ###
  my $data = make_amf_record( $acis, $record );

  if ( not $data ) {
    $acis -> error ( "cant-generate-metadata" );
    return 0;
  }

  if ( open FILE, ">:utf8", $filename ) {
    print FILE $data;
    close FILE;

    if ( not $record -> {profile} ) {
      $record -> {profile} = {};
    }
    
    $record -> {profile}{export}{AMF} = $filename;
  
    $acis -> variables -> {'amf-data-written'} = $filename;
    return $filename;
  }

  $acis -> error( "cant-open-metadata-file" );
  return 0;
}



sub make_amf_record {
  my $acis = shift;
  my $rec  = shift;

  my $stylesheet = "export/amf_person_presenter.xsl";

  my $variables  = $acis ->variables;

  $variables ->{record} = $rec;

  ###  prepare contributions 
  require ACIS::Web::Contributions;
  ACIS::Web::Contributions::prepare_the_role_list( $acis );
  delete $variables ->{contributions};

  ###  prepare affiliations 
  $variables ->{affiliations} = undef;
  require ACIS::Web::Affiliations;
  ACIS::Web::Affiliations::prepare( $acis );

  ### prepare doclinks
  require ACIS::Web::DocLinks;
  ACIS::Web::DocLinks::prepare( $acis );

  my $page = $acis -> run_presenter( $stylesheet, -hideemails => 1 );   

  delete $variables ->{record};
  if (ref $page) {return $$page;}
  return $page;
}




1;
