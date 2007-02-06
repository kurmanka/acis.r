package ARDB::AMF::Processing;

use strict;
use Carp::Assert;

use ACIS::ShortIDs;

require ARDB::ReDIF::Processing;

use Storable qw( freeze );

require AMF::2ReDIF;

my $rec;
my $te ;
my $sid;

my $ardb;
my $relations;

sub prepare {
  $ardb = shift;
  $rec  = shift;
  $relations = shift;
  generate_short_id();
}


sub get ($);

use vars qw( $acis );

*acis = *ACIS::Web::ACIS;


my $item;
my $authors;
my @authors;
my @au_emails;

my $editors;
my @editors;
my @ed_emails;


sub process_text {

  assert( $ardb );
  assert( $rec );
  assert( $relations );

  my $id   = $rec ->id;
  my $url  = get 'displaypage';
  my $type = short_lc_record_type();

  my $do_store = 1;

  my $config = $ardb -> {config};
  my $sql    = $ardb -> {sql_object};

  if ( not $sid ) { $do_store = 0; }
  
  if ( not $do_store ) {
    if ( $sid ) {
      my $table  = $config -> table( 'res_creators_bulk' );
      $table -> delete_where ( $sql, "sid=?", $sid );
      
      $table  = $config -> table( 'res_creators_separate' );
      $table -> delete_where ( $sql, "sid=?", $sid );
      
      $table  = $config -> table( 'resources' );
      $table -> delete_where ( $sql, "id=?", $id );
    }

    $ardb -> {record} = { id => $id, type => $rec -> type };
    return;
  }

  my $title = get 'title';

  $item = {
     id    => $id,
     sid   => $sid,
     type  => $type,
     title => $title,
  };

  if ( $url ) { $item -> {'url-about'} = $url; }

  if ( not $title ) {
    my $name = get 'name';
    if ( $name ) { $item -> {title} = $name; }
  }


  process_authors();
  process_editors();
  

  ###
  ###  RESOURCES  table
  ###

  {
    my $row = {
               id   => $id,
               sid  => $sid,
               type => $type,
               urlabout => $url,
               authors => $item->{authors},
               title => $item->{title},
              };
    
    my $location = '';
    foreach ( qw( journaltitle journalabbreviatedtitle
                  journalidentifier 
                  issuedate volume part issue 
                  season quarter startpage endpage pages 
                  articlenumber
                  ) ) {
      $location .= ' ' . $rec -> get_value( "serial/$_" );
    }
    $location =~ s/\s+/ /g;
    $location =~ s/(^\s+|\s+$)//g;
    $row -> {location} = $location;

    my $table  = $config -> table( 'resources' );
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
  
  $table  = $config -> table( 'res_creators_separate' );
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
    
  ####  authors' handles
  {
    my @h = $rec -> get_value( "hasauthor/ID" );
    push @h, $rec -> get_value( "hasauthor/REF" );
    push @h, $rec -> get_value( "hasauthor/identifier" );

    ARDB::ReDIF::Processing::resolve_shortids( \@h );
    
    foreach ( @h ) {
      if ( $_ ) {
        $relations -> store( [ $_, 'wrote', $id, $id ] );
        push @person_pointers, $_;
      }
    }
    
  }
  
  ####  editors' handles
  {
    my @h =  $rec -> get_value( "haseditor/ID" );
    push @h, $rec -> get_value( "haseditor/REF" );
    push @h, $rec -> get_value( "haseditor/identifier" );
    
    ARDB::ReDIF::Processing::resolve_shortids( \@h );
    
    foreach ( @h ) {
      if ( $_ ) {
        $relations -> store( [ $_, 'edited', $id, $id ] );
        push @person_pointers, $_;
      }
    }
  }
  
  
  ###  check if this relation is already known and if not, put the personal
  ###  record onto the ARPU queue.  
    
  ###  XXX Maybe a better checking method will be useful.
  
  foreach ( @person_pointers ) {
    my $per = $_;
    print "Resource record $id points to $per\n";
    my @back = $relations -> fetch( [ $per, undef, $id, $per ] );
    if ( not scalar @back ) {
      ###  may be that's a new relation 
      if ( not $acis ) { ARDB::ReDIF::Processing::create_acis(); }
      if ( not $acis ) {
        warn "STILL NO ACIS!";
        last;
      }
      require ACIS::Web::ARPM;
      require ACIS::Web::ARPM::Queue;
      print "putting $per into the ARPU queue\n";
      ACIS::Web::ARPM::Queue::push_item_to_queue( $acis -> sql_object, $per, 1 );
        
    } else {
      print "probably already claimed (or refused)\n";
    }
  }
  
  
  ### 
  ###  finishing the item
  ###
  
  #  $item -> {jel}   = join ' ', $record ->get_value( 'classification-jel' );
  
  #  bless $item, "ARDB::Record::Simple";
  
  $ardb -> {record} = $item;

}

sub process_collection {
  process_text( );
}


sub process_authors {
  $authors = '';
  @authors   = ();
  @au_emails = ();

  {
    my @aus = $rec -> get_value( 'hasauthor' );

    foreach ( @aus ) {
      my $name = $_->{name}[0] || next;
      $name =~ s/(^\s+|\s+$)//g;
      next if not $name;
      my $em = $_ ->{email}[0][0] || '';
      push @au_emails, $em;
      push @authors,   $name;
    }
    $authors = ARDB::ReDIF::Processing::normalize_personal_names ( \@authors );

    if ( $authors ) {
      my $au = $authors;
      $au =~ s/(?:^\x{1}|\x{1}$)//g;
      $au =~ s/\x{1}/ & /g;
      $item -> {authors} = $au;
    }
  }
}

sub process_editors {
  $editors   = '';
  @editors   = ();
  @ed_emails = ();

  {
    my @eds = $rec-> get_value( 'editor' );

    foreach ( @eds ) {
      my $name = $_->{name}[0] || next;
      $name =~ s/(^\s+|\s+$)//g;
      next if not $name;
      my $em = $_ ->{email}[0][0] || '';
      push @ed_emails, $em;
      push @editors  , $name;
    }
    $editors = ARDB::ReDIF::Processing::normalize_personal_names ( \@editors );
    
    if ( $editors ) {
      my $ed = $editors;  
      $ed =~ s/(?:^\x{1}|\x{1}$)//g;
      $ed =~ s/\x{1}/ & /g;
      $item -> {editors} = $ed;
    }
  }

}



sub extract_part_of_relationships {
  my $ARDB      = shift;
  my $record    = shift;
  my $relations = shift;

  assert( $record );
  assert( $relations );

  my $id        = $record -> id;

  { 
    my @part_of = $record -> get_value( 'ispartof' );
    
    my @whole;
    foreach ( @part_of ) {
      my $id = $_ ->id || $_->ref;
      if ( $id ) {
        push @whole, $id;
      }
    }

    foreach ( @whole ) {
      $relations -> store( [ $id, 'part-of', $_, $id ] );
    }
  }
  
  {
    my @has_part = $record -> get_value( 'haspart' );
    
    my @parts;
    foreach ( @has_part ) {
      my $id = $_ ->id || $_->ref;
      if ( $id ) {
        push @parts, $id;
      }
    }
    
    foreach ( @parts ) {
      $relations -> store( [ $id, 'has-part', $_, $id ] );
    }
  }

}



sub short_lc_record_type {
  my $t  = lc $rec -> type;
  my $t2 = $rec -> get_value( 'type' );

  if ( $t eq 'collection' ) {
    if ( $t2 eq 'serial' ) {
      return 'series';
    } elsif ( $t2 eq 'book' ) {
      return 'book';
    }

  } elsif ( $t eq 'text' ) {
    if ( $t2 and $t2 eq 'bookitem' ) { return 'chapter';  }
    if ( $t2 ) { return $t2;  }
  }
  return $t;
}



sub generate_short_id {

  undef $sid;

  my $id   = $rec -> id;
  my $type = $rec -> type;
  my $key  = join '', $rec -> get_value( 'title' );

  if ( not $key ) {
    $key = join '', $rec -> get_value( 'name' );
  }

  if ( $type eq 'person' ) {
    $key = join '', $rec -> get_value( 'familyname' ),
        $rec -> get_value( 'givenname' ),
        $rec -> get_value( 'email' );
  } 

  if ( not $key ) {
    $key = join '', $rec -> get_value( 'abstract' );
  }

  if ( not $key ) {
    $key = join '', $rec -> get_value( 'email' );
  }

  if ( $type eq 'text' ) { $type = 'document'; }

  if ( $id and $type and $key ) {
    eval {
      $sid = ACIS::ShortIDs::make_short_id( $id, $type, $key );
    };
    if ( $@ ) {  warn $@;  }
  }

  return $sid;
}



sub get ($) { return $rec -> get_value( @_ ); }


sub process_organization {
  my $ARDB = shift;
  my $rec  = shift;
  my $sql  = $ARDB -> sql_object;

  $te = AMF::2ReDIF::translate( $rec );

  ARDB::ReDIF::Processing::process_institution( $ARDB, $te, $relations, 1 );
}


1;

