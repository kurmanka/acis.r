package ACIS::EPrints::MetadataExport::ReDIF; # -*-perl-*-  
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
#  Copyright (C) 2006 Ivan Kurmanov for ACIS project, http://acis.openlib.org/
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
#  $Id: ReDIF.pm,v 2.3 2006/06/07 07:36:59 ivan Exp $
#  ---


use strict;
use warnings;

use Encode;

use Carp qw( confess );
use Carp::Assert;

require EPrints::Utils;

use Data::Dumper; 
                                 

### ReDIF generation

use vars qw( $te $prefix $src );

sub attr ($@) {
  my $at = shift;
  my @va = @_;

  if ( not scalar @va 
       or not defined $va[0] ) {
    return;
  }

  foreach ( @va ) {
    $_ = Encode::decode_utf8( $_ );
    $te .= "$prefix$at: $_\n";
  }
}

sub transf ($;$) {
  my $name = shift;
  my $what = shift || $name;
  
  if ( UNIVERSAL::isa( $src, "EPrints::EPrint" ) ) {
    attr $name, Encode::decode_utf8( $src -> get_value( $what ) );

  } else {
    confess "Extract $what from $src--HOW??";
  }
}



# other tools

sub resolve_sid ($);


my $log = '/opt/eprints2/acis-metadata-export.redif.log';

sub logit (@) {
  if ( open LOG, ">>", $log ) {
    print LOG scalar( localtime ), " ", @_, "\n";
    close LOG;
  }
}

logit( __PACKAGE__, " loaded" );




sub decode_person {
    my $epcreator = shift;
    $prefix       = shift;

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


    my $fullname = EPrints::Utils::make_name_string( $main, 1 );
    

    attr 'name',       $fullname;
    attr 'name-first', $main ->{given} ;
    attr 'name-last',  $main ->{family};

    if ( $email ) {
      attr 'email', $email;
    }

    if ( $sid ) {
      attr 'person', $sid;
    }
    
    $prefix = '';
}




sub get_redif_from_eprint {
  $src = my $eprint = shift;
  my $handle = shift;
  $te   = '';
  $prefix = '';

  my $templatetype;
  my $eptype = $eprint ->get_value( 'type' );
  my $eprinttype2tt =  {
     article          => 'Article',
     book             => 'Book',
     book_section     => 'Chapter',
     conference_item  => 'Paper',
  };
  my $monographtype2tt = {
     technical_report => 'Paper',
     discussion_paper => 'Paper',
     working_paper    => 'Paper',
  };

  $templatetype = $eprinttype2tt ->{$eptype};

  if ( $eptype eq 'monograph' ) {
    my $mtype = $eprint -> get_value( 'monograph_type' );
    $templatetype = $monographtype2tt->{$mtype};
  }

  if ( not $templatetype ) { $templatetype = 'Paper'; }
  
  attr 'template-type', "ReDIF-$templatetype 1.0";
  transf "title";
  transf "abstract";

  my $creators = $eprint ->get_value( "creators" );
  foreach ( @$creators ) {
    decode_person( $_, "author-" );
  }

  my $editors = $eprint ->get_value( "editors" );
  foreach ( @$editors ) {
    decode_person( $_, "editor-" );
  }

  my $url = $eprint -> get_url();
  if ( $url ) {
    attr 'order-url', $url;
  }

  attr 'handle', $handle;

  logit "template: $te";

  return $te;
}



sub export_metadata_real {
  my $eprint  = shift;

  my $session = $eprint -> {session};
  my $archive = $session -> get_archive;
  my $id      = $eprint -> get_value( 'eprintid' );

  logit "export_metadata($eprint)";
  logit "id: ", $id;

  my $dir    = $archive 
     -> get_conf( "eprint_metadata_export_ReDIF_dir" );

  if ( not $dir ) { return; }
  logit "dir: $dir";

  my $idfunc = $archive 
     -> get_conf( "eprint_metadata_export_ReDIF_id_func" ) || '';

  my $filefunc = $archive 
     -> get_conf( "eprint_metadata_export_ReDIF_filename_func" ) || '';

  my $prefix = $archive 
     -> get_conf( "eprint_metadata_export_ReDIF_idprefix" ) || '';
 
  my $mupdate = $archive 
     -> get_conf( "eprint_metadata_export_ReDIF_metaupdate" );
  
  if ( not -d $dir ) { mkdir $dir; }
  if ( not -d $dir ) { logit "can't create dir $dir"; return 0; } 


  my $handle;
  if ( $idfunc ) {
    $handle = &{ $idfunc }( $eprint );
  } else {
    $handle = "$prefix$id";
  }

  my $file = $id;
  if ( $filefunc ) {
    $file = &{ $filefunc }( $eprint, $handle );
  }
  my $filename = $dir . "/" . $file . ".rdf";

  
  ### get ReDIF from $eprint
  my $text = get_redif_from_eprint( $eprint, $handle );

  ### save it
  if ( open FILE, ">:utf8", $filename ) {
    print FILE "\x{FEFF}", $text;
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
          -> get_conf( "eprint_metadata_export_ReDIF_dir" );

  return if not $dir;

  logit "clear_metadata()";
  logit "id: $id, dir: $dir";

  if ( not -d $dir ) { logit "can't find dir $dir"; return 0; } 

  my $filename = $dir . "/" . $id . ".rdf";
  
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


EPrints eprint types:

Article

    An article in a journal, magazine, newspaper. Not necessarily
    peer-reviewed. May be an electronic-only medium, such as an online journal
    or news website.

Book Section

    A chapter or section in a book.

Monograph

    A monograph. This may be a technical report, project report,
    documentation, manual, working paper or discussion paper.

Conference or Workshop Item

    A paper, poster, speech, lecture or presentation given at a conference,
    workshop or other event. If the conference item has been published in a
    journal or book then please use "Book Section" or "Article" instead.

Book

    A book or a conference volume.

Thesis

    A thesis or dissertation.

Patent

    A published patent. Do not include as yet unpublished patent applications.

Other

    Something within the scope of the repository, but not covered by the other
    categories.

