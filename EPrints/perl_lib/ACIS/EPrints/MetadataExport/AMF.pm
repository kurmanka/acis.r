package ACIS::EPrints::MetadataExport::AMF; # -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/ and, at the
#  same time, an extension to EPrints software, http://www.eprints.org/
#
#  Description:
#
#    AMF metadata conversion module; produces AMF metadata from EPrints'
#    internal eprint objects.
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
#  $Id$
#  ---


use strict;

use Encode;
use Carp::Assert;

use AMF;
use AMF::Record;

require EPrints::Utils;


sub resolve_sid ($);


#my $log = '/opt/eprints2/acis-metadata-export.log';

sub logit (@) {
#  if ( open LOG, ">>", $log ) {
#    print LOG scalar( localtime ), " ", @_, "\n";
#    close LOG;
#  }
}

logit( __PACKAGE__, " loaded" );

my $amf_prolog = <<PROLOG;
<amf xmlns='http://amf.openlib.org'
     xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
     xsi:schemaLocation='http://amf.openlib.org http://amf.openlib.org/2001/amf.xsd'>

PROLOG

my $amf_epilog = <<EPILOG;

</amf>
EPILOG


my $dump;



sub decode_person {
    my $epcreator = shift;

    my $id;
    my $sid;
    my $email;
    my $main = $epcreator;

    if ( exists $epcreator ->{id} 
         and $epcreator ->{main} ) {
      $sid  = $epcreator ->{id};
      $main = $epcreator ->{main};
    }

    assert( ref $main );

    ### check $sid
    if ( $sid =~ /^\s*(p[a-z]+\d+)\s*$/i ) {
      $sid = $1;

    } else {
      if ( $sid =~ /^\s*([\&\+a-z\d\-\.\=\_]+\@(?:[a-z\d\-\_]+\.)+[a-z]{2,})\s*$/i ) {
        $email = $sid;
      }
      undef $sid;
    }      

    ### get full id 
    if ( $sid ) {
      $id = resolve_sid( $sid );
    }

    my $noun = AMF::Record -> new( ID   => $id,
                                   TYPE => 'person' );
        
    my $name = {};

# These eprint creator properties are left unused yet:
#    lineage honourific

    foreach ( qw( given/givenname 
                  family/familyname
                  ) ) {
        my ( $ep, $amf ) = split '/', $_;
        
        my $v = Encode::decode_utf8( $main ->{$ep} );
#        my $v = $main ->{$ep};
        if ( not $v ) {
          $v = $main -> {$ep};
        }
        $name ->{$amf} = $v;
        $noun -> adjective( $amf, {}, $v );
    }

    my $fullname = EPrints::Utils::make_name_string( $main, 1 );
    $fullname = Encode::decode_utf8( $fullname );
    $noun -> adjective( 'name', {}, $fullname );

    if ( $sid ) {
      $noun -> adjective( 'identifier', {}, $sid );
    }
    if ( $email ) {
      $noun -> adjective( 'email', {}, $email );
    }
    
    return $noun;
}

use Data::Dumper; 
                                 

sub get_amf_from_eprint {
  my $eprint = shift;
  my $ID     = shift;
  my $text;

#  $dump = "";


  my $rec  = AMF::Record -> new( ID => $ID, TYPE => 'text' );

  my $title = $eprint -> get_value( "title" );
  $title = Encode::decode_utf8( $title );
  $rec -> adjective( 'title', {}, $title );

  my $creators = $eprint ->get_value( "creators" );
  foreach ( @$creators ) {
    my $cr = decode_person( $_ );
    $rec -> verb( "hasauthor", {}, $cr );
  }

  my $editors = $eprint ->get_value( "editors" );
  foreach ( @$editors ) {
    my $cr = decode_person( $_ );
    $rec -> verb( "haseditor", {}, $cr );
  }


  my $texttype;

  my $eptype = $eprint ->get_value( 'type' );
  my $eprinttype2amf = 
    {
     article        => 'article',
     book           => 'book',
     book_section   => 'bookitem',
     conference_item => 'conferencepaper',
    };
  my $monographtype2amf =
    {
     technical_report => 'preprint',
     discussion_paper => 'preprint',
     working_paper    => 'preprint',
    };

  $texttype = $eprinttype2amf ->{$eptype};

  if ( $eptype eq 'monograph' ) {
    my $mtype = $eprint -> get_value( 'monograph_type' );
    $texttype = $monographtype2amf->{$mtype};
  }

  if ( $texttype ) {
    $rec -> adjective( "type", {}, $texttype );
  }


  my $url = $eprint -> get_url();
  if ( $url ) {
    $rec -> adjective( "displaypage", {}, $url );
  }


      
  if ( 0 ) { 

    ### make a simple peeking dump
    
    my @fields = $eprint ->get_dataset() ->get_type_fields( $eptype );
    
    $dump .= "\n\nTYPE: $eptype\n";
    
    my @skiplist = qw( title creators editors );
    my %skiphash = {};
    
    foreach ( @skiplist ) {
      $skiphash{$_} = 1;
    }
    
    my $field;
    foreach $field ( @fields ) {
      my $fname = $field  -> get_name();
      my $value = $eprint -> get_value( $fname );
      
      if ( $skiphash{$fname} ) { next; }
    
      if ( not $value ) { 
        #      $dump .= "-$fname-\n";
        next;
      } 

      $dump .= "$fname: "; 
    
      if ( ref $value ) {
        if ( ref( $value ) eq 'ARRAY' ) {
          
          my $c = 0;
          foreach ( @$value ) {
            $dump .= "[$c] '$_'\n";
            $c++;
          }
          
        } else {
          $dump .= $value;
        }
      } else {
        $value = Encode::decode_utf8( $value );
        $dump .= $value;
      }
      
      $dump .= "\n";
    }
  }  # end of the dump branch

  
  $text = $rec -> stringify;
  $text = join( '', $amf_prolog, $text, $amf_epilog );

  return $text;
}



sub export_metadata_real {
  my $eprint  = shift;

  my $session = $eprint -> {session};
  my $archive = $session -> get_archive;
  my $id      = $eprint -> get_value( 'eprintid' );

  logit "export_metadata($eprint)";
  logit "id: ", $id;

  my $dir    = $archive 
     -> get_conf( "eprint_metadata_export_AMF_dir" );

  if ( not $dir ) { return; }
  logit "dir: $dir";

  my $prefix = $archive 
     -> get_conf( "eprint_metadata_export_AMF_idprefix" ) || '';
 
  my $mupdate = $archive 
     -> get_conf( "eprint_metadata_export_AMF_metaupdate" );
  
  if ( not -d $dir ) { mkdir $dir; }
  if ( not -d $dir ) { logit "can't create dir $dir"; return 0; } 

  my $filename = $dir . "/" . $id . ".amf.xml";
  
  
  ### get AMF from $eprint
  my $text = get_amf_from_eprint( $eprint, "$prefix$id" );

  ### save it
  if ( open FILE, ">:utf8", $filename ) {
    print FILE $text;
    close FILE;
  } else { 
    logit "Can't write $filename";
  }


  # meta update

  if ( $mupdate ) {
    metadata_update( $mupdate, $filename );
  }
  

}


### wrapper for safety

sub export_metadata {
  my $eprint  = shift;
  eval { 
      export_metadata_real( $eprint );
  }; 
  if ( $@ ) {
      logit "export_metadata failed: $@";
  }
}





sub clear_metadata {
  my $eprint  = shift;

  my $session = $eprint -> {session};
  my $id  = $eprint -> get_value( 'eprintid' );
  my $dir = $session -> get_archive 
          -> get_conf( "eprint_metadata_export_AMF_dir" );

  return if not $dir;

  logit "clear_metadata()";
  logit "id: $id, dir: $dir";

  if ( not -d $dir ) { logit "can't find dir $dir"; return 0; } 

  my $filename = $dir . "/" . $id . ".amf.xml";
  
  unlink( $filename )
    or warn "can't unlink $filename\n";

}


sub metadata_update {
  my $conf = shift || die;
  my $file = shift || die;

  require ACIS::MetaUpdate::Request;
  
  my @pars = ();
  foreach ( qw( archive-id request-target-url log-filename ) ) {
    if ( $conf ->{$_} ) {
      push @pars, $_, $conf->{$_};
    }
  }

  my $level = $conf -> {'object-dir-levels'};

  my @f = split m!/+!, $file;
  my $object = pop @f;

  for ( ; $level > 0; $level-- ) {
    $object = (pop @f) . "/$object";
  }

  ACIS::MetaUpdate::Request::acis_metaupdate_request( $object, @pars );
}




sub resolve_sid ($) {
  return '';
}



1;


__END__

