package ARDB::ReDIF::Processing;

use strict;
use Carp::Assert;

use ACIS::ShortIDs;

#require ARDB::Record::Simple;

use Storable qw( freeze );

sub normalize_personal_names {
  my $list = shift;

  my $etal;
  ###  normalize each author name
  foreach ( @$list ) {
    if( $_ =~ /et al(li)?/ ) {
      $_ =~ s/(?:(?:,|;)?\s*)?\bet al(li)?\b//;
      $etal = 1;
    }

    if ( $_ =~ m!et\. al\.! ) {
      $_ =~ s/(?:(?:,|;)?\s*)?\bet. al.\b//;
      $etal = 1;
    }

    $_ =~ s/[\p{C}\p{S}]//g;  ### XX remove control characters and symbols, if any

         ###  Should this not be checked at ReDIF-perl level?  I think it
         ###  should.  But here it may also be useful.

    $_ =~ s/,\s*/, /g;
    $_ =~ s/\.\s*/. /g;
    $_ =~ s/\. ([-,])/.$1/g;
    $_ =~ s/(\b[A-Z]\b)([^'\w\.]|$)/$1.$2/g;
    $_ =~ s/(^\s+|\s+$)//g;
    $_ =~ s/\s+/ /g
  }

  if ( $etal ) {
    push @$list, "et al";
  }

  my $sep = "\x1";

  if ( scalar @$list ) {
    return join $sep, '', @$list, '';

  } else {
    return '';
  }
}



sub extract_creation_date {
  my $record = shift;

  my ($date) = $record -> get_value( "creation-date" );

  if( $date =~ /^\d{4}\-\d{2}$/ ) {
    $date = "$date-00";
  } elsif ( $date =~ /^\d{4}$/ ) {
    $date = "$date-00-00";
  } else {
    return "0000-00-00";
  }
  return $date;
}

sub extract_revision_date {
  my $record = shift;
  my ($date) = $record -> get_value( "revision-date" );
  if( $date =~ /^\d{4}\-\d{2}$/ ) {
    $date = "$date-00";
  } elsif ( $date =~ /^\d{4}$/ ) {
    $date = "$date-00-00";
  } else {
    return "0000-00-00";
  }
  return $date;
}


sub extract_part_of_relationships {
  my $ARDB   = shift;
  my $record = shift;
  my $relations = shift;

  assert( $record );
  assert( $relations );

  # get the series part or the archive part of the handle

  my $id = $record->id;
  my $colons = $id =~ s/:/:/g;

  my $part_of;

  if( $colons == 1 ) { # archive 
    return;

  } elsif( $colons == 2 ) {
    my ( $archive ) = $id =~ /^([^:]+:[^:]+):/ ;

    $part_of = $archive;

  } elsif( $colons > 2 ) {
    my ( $series )  = $id =~ /^([^:]+(?::[^:]+){2}):/ ;

    $part_of = $series;    
  }

  if ( $part_of ) {
    $relations -> store( [ $id, 'part-of', $part_of, $id ] );
  }
}


use Carp::Assert;


sub short_lc_record_type {
  my $record = shift;
  
  my $t = $record -> type;
  $t =~ s/^ReDIF\-//i;
  $t =~ s/\s+1.0//;

  $t = lc $t;
  
  $record -> {'SHORT-TYPE'} = $t;
}

###############################################################################
###                U R L    A B O U T 
###############################################################################

sub make_url_about_resource {
  my $record = shift;
  
  my $id   = $record ->id;
  my $type = $record ->type;

  my $url;
  my $base = 'http://ideas.repec.org/';
  my $section;
  my $page;

  if ( $id !~ /^RePEc:rus:/i ) {

    if ( $id =~ /^RePEc:(.+)/i ) {
      my $idmainpart = $1;
      my ( $arc, $ser, $doc ) = $idmainpart =~ /^(...)(?::(......)(?::(.+))?)?/;
      
      $doc = lc $doc;
      $doc =~ s/://g;
      $doc =~ s!/!-!g;

      $page = $arc;
      if ( $ser ) {
        $page .= "/$ser";
        if ( $doc ) {
          $page .= "/$doc";
        }
      }
      $page .= '.html';
    }

    if ( $type =~ /ReDIF-(\w+)\s/ ) {
      my $t = lc $1;
      if ( $t eq 'article' )    { $section = 'a/'; }
      elsif( $t eq 'paper' )    { $section = 'p/'; }
      elsif( $t eq 'book' )     { $section = 'b/'; }
      elsif( $t eq 'software' ) { $section = 'c/'; }
      elsif( $t eq 'chapter' )  { $section = 'h/'; }
      elsif( $t eq 'series' )   { $section = 's/'; }
      else { return undef; }
    }
    
    if ( defined $section 
         and defined $page ) {
      $url = $base . $section . $page;
    }

  } else {
    $url = make_url_about_resource_rus_archive( $record );
  }

  if ( defined $url ) {
    $record -> {"URL-ABOUT"} = $url;
  }

  return $url;
}


sub make_url_about_resource_rus_archive {
  my $record = shift;
  
  my $id   = $record ->id;
  my $type = $record ->type;

  my $prefix = 'http://socionet.ru/RuPEc/xml/rus/';
  my $mainpart;
  my $postfix = '.xml';

  if ( $id =~ /^RePEc:(.+)/i ) {
    my $idmainpart = $1;
    my ( $arc, $ser, $doc ) = $idmainpart =~ /^(...)(?::(......)(?::(.+))?)?/;
    my $ty = lc $type;
    if ( $ty =~ /^redif\-([^\s]+) / ) {
      $ty = $1;
    }
    $doc =~ s!/!-!g;
    $mainpart = "$ty-$ser/$arc$ser$doc";
  }
  return "$prefix$mainpart$postfix";
}




sub generate_short_id {
  my $record = shift;

  my $template_type = $record -> {'template-type'} -> [0];
  my $handle = lc ( $record -> {handle} -> [0] );

  my $prefix;
  my $title;
  my $how_many_letters = 3;

  if  ( $template_type eq 'ReDIF-Person 1.0' 
        or $template_type eq 'ReDIF-Person-illusive' )  {
    $title =  $record -> {'name-last'} [0];
    
    $how_many_letters = 2;
    $prefix  = 'p'; # person type
    
  } elsif  (
            $template_type eq 'ReDIF-Paper 1.0'
            or $template_type eq 'ReDIF-Article 1.0'
            or $template_type eq 'ReDIF-Book 1.0'
            or $template_type eq 'ReDIF-Chapter 1.0'
            or $template_type eq 'ReDIF-Software 1.0'
           ) {
    $prefix = "d";  # document
    
    $title =  $record -> {'title'} -> [0];
    $title =~ s/\bthe//ig;
    
  } elsif  (
            $template_type eq 'ReDIF-Series 1.0'
            or $template_type eq 'ReDIF-Archive 1.0'
           ) {
      
    $prefix = "c";  # collection
    
    $title =  $record -> {'name'} [0];
    $title =~ s/\bthe//ig;
    
  } elsif  (
            $template_type eq 'ReDIF-Institution 1.0'
           ) {
    $prefix = "o";  # organization
    
    $title =  $record -> {primary} [0] {name} [0];
    $how_many_letters = 2;
    $title =~ s/\bthe//ig;
    
  } else  {
    $prefix = "u";  # universal type
    $title = $handle;
  }
  
  
  my $sid;
  eval { 
    $sid = ACIS::ShortIDs::make_short_id( $handle, $prefix, 
                                          $title, 
                                          $how_many_letters ); 
  };
  if ( $@ ) {
    warn $@; 
  }

  if ( $sid ) {
    $record -> {"SHORT-ID"} = $sid;
    return $sid;
  }

  return undef;
}


use vars qw( $acis );

use ACIS::Web;
sub create_acis {
  if ( not $acis ) {
#    require ACIS::Web;
    $acis = ACIS::Web -> new();
  }
}


sub resolve_shortids ($) {
  my $a = shift;

  if ( not $acis ) { create_acis(); }

  my $sql = $acis -> sql_object;

  foreach ( @$a ) {
    if ( m/^p[a-z]+\d+$/i ) {
      ### person short-id 
      $sql -> prepare_cached( "select id from records where shortid=?" );
      my $r = $sql -> execute( $_ );
      if ( $r -> {row} and $r->{row}{id} ) {
#        print "short-id: $_ = $r->{row}{id}\n";
        $_ = lc $r -> {row}{id};
      } else {
#        print "short-id: $_ not found\n";
      }        
    }
  }


}

###########################################################################
####   s u b    P R O C E S S    R E S O U R C E  
###########################################################################

sub process_resource {
  my $ardb   = shift;
  my $record = shift;
  my $relations = shift;

  assert( $ardb );
  assert( $record );
  assert( $relations );

  my $id   = $record ->id;
  my $url  = make_url_about_resource ( $record );
  my $sid  = generate_short_id       ( $record );
  my $type = short_lc_record_type    ( $record );

  my $do_store = 1;

  my $config = $ardb -> {config};
  my $sql    = $ardb -> {sql_object};
  
  if ( $id =~ m/^repec:rus:/i ) {  $do_store = 0;  }
  if ( not $sid ) { $do_store = 0; }

  if ( not $do_store ) {
    my $table;

    if ( $sid ) {
      $table  = $config -> table( 'res_creators_bulk' );
      $table -> delete_where ( $sql, "sid=?", $sid );
      
      $table  = $config -> table( 'res_creators_separate' );
      $table -> delete_where ( $sql, "sid=?", $sid );
    }

    $table  = $config -> table( 'resources' );
    $table -> delete_where ( $sql, "id=?", $id );

    $ardb -> {record} = { id => $id, type => $record -> type };
    return;
  }



  my ( $title ) = $record ->get_value( 'title' );
  my ( $name  ) = $record ->get_value( 'name'  );

  my $item = {
     id    => $id,
     sid   => $sid,
     type  => $type,
    'url-about' => $url,
     title => $title,
  };
  

  ### ??? serie's & archive's names become collection's titles
  if ( not $title 
       and $name ) { 
    $item -> {title} = $name;
  }
  
  my $authors;
  my @authors;
  my @au_emails;

  {
    my @aus = $record -> get_value( 'author' );

    foreach ( @aus ) {
      my $em = $_ ->{email}[0] || '';
      push @au_emails, $em;
      push @authors,   $_ ->{name}[0];
    }
    $authors = normalize_personal_names ( \@authors );

    if ( $authors ) {
      my $au = $authors;
      $au =~ s/(?:^\x1|\x1$)//g;
      $au =~ s/\x1/ & /g;
      $item -> {authors} = $au;
    }

  }

  my $editors;
  my @editors;
  my @ed_emails;

  {
    my @eds = $record -> get_value( 'editor' );

    foreach ( @eds ) {
      my $em = $_ ->{email}[0];
      push @ed_emails, $em;
      push @editors  , $_ ->{name} [0];
    }
    $editors = normalize_personal_names ( \@editors );
    
    if ( $editors ) {
      my $ed = $editors;  
      $ed =~ s/(?:^\x1|\x1$)//g;
      $ed =~ s/\x1/ & /g;
      $item -> {editors} = $ed;
    }
  }





  ######   CLEAR AND STORE DATA

  ###
  ###  RESOURCES  table
  ###

  {
    my $row = {
               id   => $id,
               sid  => $sid,
               type => $type,
              };
    
    my $table  = $config -> table( 'resources' );
    $row -> {title}   = $item->{title};
    $row -> {classif} = join ' ', $record ->get_value( 'classification-jel' );
    
    $table -> store_record ( $row, $sql );
  }


  ###  
  ###  RES CREATORS
  ### 
 
  my $table  = $config -> table( 'res_creators_bulk' );
  if ( $authors ) {
    my $r = { sid  => $sid, 
              role => 'author', 
              names => $authors };
    $table -> store_record ( $r, $sql );

  } else {
    $table -> delete_where ( $sql, "sid=? AND role='author'", $sid );
  }
  
  if ( $editors ) {
    my $r = { sid  => $sid, 
              role => 'editor', 
              names => $editors };
    $table -> store_record ( $r, $sql );

  } else {
    $table -> delete_where ( $sql, "sid=? AND role='editor'", $sid );
  }
  
  my $res = {
             sid => $sid,
            };
  
  my $table  = $config -> table( 'res_creators_separate' );
  $table -> delete_records( 'sid', $sid, $sql );
  
  my @emails = ( @au_emails, @ed_emails );
  
  my $role = 'author';
  foreach ( @authors, '', @editors ) {
    
    if ( $_ eq '' ) { 
      $role = 'editor';
      next;
    }
    
    $res -> {role}  = $role;
    $res -> {name}  = lc $_;
    $res -> {email} = lc shift @emails;
    $table -> store_record( $res, $sql );
  }



  ###  Rich metadata pointing to particular personal records.  This requires
  ###  some processing:

  my @person_pointers;
    
  ####  authors' handles, Author-Person attribute
  {
    my @h =  $record -> get_value( "author/person" );
    
    resolve_shortids( \@h );
    
    foreach ( @h ) {
      $relations -> store( [ $_, 'wrote', $id, $id ] );
      push @person_pointers, $_;
    }
    
  }
  
  ####  editors' handles, Editor-Person attribute
  {
    my @h =  $record -> get_value( "editor/person" );
    
    resolve_shortids( \@h );
    
    foreach ( @h ) {
      $relations -> store( [ $_, 'edited', $id, $id ] );
      push @person_pointers, $_;
    }
  }
  
  
  ###  check if this relation is already known and if not, put the personal
  ###  record onto the ARPU queue.  
    
  ###  XX Maybe a better checking method will be useful.
  
  foreach ( @person_pointers ) {
    my $per = $_;
    print "Resource record $id points to $per\n";
    my @back = $relations -> fetch( [ $per, undef, $id, $per ] );
    if ( not scalar @back ) {
      ###  may be that's a new relation 
      if ( not $acis ) { create_acis(); }
      require ACIS::Web::ARPM;
      require ACIS::Web::ARPM::Queue;
      print "putting $per into the ARPM queue!\n";
      ACIS::Web::ARPM::Queue::push_item_to_queue( $acis -> sql_object, $per, 1 );
      
    } else {
      print "probably already claimed (or refused)\n";
    }
  }
  
  
  ### 
  ###  finishing the item
  ###
    
  $ardb -> {record} = $item;

}



sub process_resource_lost {
  my $ardb   = shift;
  my $record = shift;

  my $config = $ardb -> config;
  my $sql    = $ardb -> sql_object;

  my $sid    = $record -> {sid};

  if ( $sid ) {
    foreach ( qw( res_creators_bulk
                  res_creators_separate
                ) ) {
      my $table  = $config -> table( $_ );
      $table -> delete_records( 'sid', $sid, $sql );
    }

    {
      my $table  = $config -> table( "acis:suggestions" );
      $table -> delete_records( 'osid', $sid, $sql );
    }
  }
}




sub process_institution {
  my $ARDB   = shift;
  my $record = shift;
  my $relations = shift;
  my $repec  = shift || 2;

  my $sql    = $ARDB -> sql_object;

  my $name    = $record -> {name};
  my $name_en = $record -> {'name-en'};
  
  ## \x{2014} -- &mdash;
  ## \x{00BB} -- &raquo;
  ## \x{2192} -- &rarr;  
  $name    =~ s/\n\n/\n\x{2192} /g; 
  $name_en =~ s/\n\n/\n\x{2192} /g; 

  $name =~ s/&amp;/&/g;
  $name_en =~ s/&amp;/&/g;

  $record -> {name} = $name;
  $record -> {'name-en'} = $name_en;
  
  if ( $repec >1 and $record->id =~ /ea$/ ) {
    return;
  }

  my $name_idx     = "$name $name_en";
  
  my $config = $ARDB -> config;
  my $iobj;

  { 
    my $map = $config -> mapping( 'institution_obj' );
    $iobj   = $map -> produce_record( $record );
  }

  my $location_idx = $iobj ->{location};
  if ( not $location_idx ) {
    $location_idx = $iobj ->{postal};
  }
#  $location_idx .= " " . $iobj ->{postal};

  
  my $data = freeze $iobj;
  my $struct = {
                id => $record ->id,
                name => $name_idx,
                location => $location_idx,
                data => $data 
                };
  
  my $table  = $config -> table( 'institutions' );
  $table -> store_record( $struct, $sql );
  
}


########################   Find in RePEc emulation   #########################

package ARDB::ReDIF::Processing::Fire;

sub authors {
  my $record = shift;

  my @au = $record -> get_value( "author/name" );

  return ( join( " &: ", @au ) );
}

sub urls {
  my $record = shift;

  my @f = $record -> get_value( "file" );
  my $res = '';

  foreach ( @f ) {
    my $type = uc $_->{format}->[0];
    $type =~ s/^application\///i;
    $type =~ s#/#-#g;

    if ( not $type ) { $type = 'FILE' };

    my $url  = $_->{url }->[0];
    $res .= "$type $url &";
  }

  return $res;
  
}

sub file {
  my $record = shift;

  if( scalar $record -> get_value( "file" ) ) {
    return 1;
  } else {
    return 0;
  }
}

sub jel {
  my $record = shift;

  my @l = $record -> get_value( "classification-jel" );

  return ( join( ", ", @l ) );

}

use ARDB::Common;

sub conditional_content_ft_store {
  my $ARDB   = shift;
  my $record = shift;

  my @f = $record->get_value( 'file' );

  return if not scalar @f;

  my $config     = $ARDB -> {'config'};
  my $sql_object = $ARDB -> {'sql_object'};

  my $map        = $config -> mapping ( 'fire_documents' );

  critical "map 'fire_documents' is absent"
    if ( not $map );

  my $table_record = $map -> produce_record( $record );
  $config -> table( 'Fire.content_ft' ) -> store_record( $table_record, $sql_object );
}


1;

