package ARDB::AMF::Processing;

use strict;
use Carp::Assert;
use Storable qw( freeze );
use Digest::MD5;
use ACIS::ShortIDs;
use ACIS::FullTextURLs::Input qw( process_urls_for_resource clear_urls_for_dsid );
use ACIS::Web::HumanNames;

require ARDB::ReDIF::Processing;
require AMF::2ReDIF;
require ACIS::FullTextURLs;

my $rec;
my $te;
my $id;
my $sid;
my $ardb;
my $relations;

sub prepare {
  $ardb = shift;
  $rec  = shift;
  $relations = shift;
  generate_short_id();
}



use vars qw( $acis );

*acis = *ACIS::Web::ACIS;


my $item;
my $authors;
my @authors;
my @au_emails;
my $editors;
my @editors;
my @ed_emails;


sub get ($) {
  return $rec -> get_value( @_ );
}


sub process_text {
  assert( $ardb );
  assert( $rec );
  assert( $relations );

  $id   = $rec ->id;
  my $url  = get 'displaypage';
  my $type = short_lc_record_type();
  my $do_store = 1;
  my $config = $ardb -> {config};
  my $sql    = $ardb -> {sql_object};

  if ( not $sid ) { $do_store = 0; }

  if ( not $do_store ) {
    if ($sid) {
      $config -> table( 'res_creators_bulk' ) ->delete_where( $sql, "sid=?", $sid );
      $config -> table( 'res_creators_separate' ) ->delete_where( $sql, "sid=?", $sid );
      $config -> table( 'resources' ) ->delete_where( $sql, "id=?", $id );
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
  #warn "call process_authors() and _editors()";
  process_authors();
  process_editors();

  ##
  ##  RESOURCES  table
  ##

  my $row = {
             id   => $id,
             sid  => $sid,
             type => $type,
             urlabout => $url,
             authors => $item->{authors},
             title => $item->{title},
            };

  my $location = &make_location_string($rec);
  $row -> {location} = $location;
  
  my $table  = $config -> table( 'resources' );
  $table -> store_record ( $row, $sql );
  
  ##
  ##  resource creators
  ##
  my $table  = $config -> table( 'res_creators_bulk' );
  if ( $authors ) {
    my $r = { sid  => $sid,
              role => 'author',
              names => $authors };
    $table -> store_record ( $r, $sql );
    
  }
  else {
    $table -> delete_where ( $sql, "sid=? AND role='author'", $sid );
  }
  
  if ( $editors ) {
    my $r = { sid  => $sid,
              role => 'editor',
              names => $editors };
    $table -> store_record ( $r, $sql );
    
  }
  else {
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
  
  
  ##
  ##  Rich metadata pointing to particular personal records.
  ##  This requires some processing:
  ##
  my @person_pointers;
  
  ## authors' handles
  
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
  
  
  ## editors' handles
  
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

  
  ##  check if this relation is already known and if not,
  ##  put the personal record onto the ARPU queue.
  
  ##  XXX Maybe a better checking method will be useful.
  
  foreach ( @person_pointers ) {
    my $per = $_;
    print "Resource record $id points to $per\n";
    my @back = $relations -> fetch( [ $per, undef, $id, $per ] );
    if ( not scalar @back ) {
      ##  may be that's a new relation
      if ( not $acis ) { ARDB::ReDIF::Processing::create_acis(); }
      if ( not $acis ) {
        warn "STILL NO ACIS!";
        last;
      }
      require ACIS::APU::Queue;
      print "putting $per into the ARPU queue\n";
      ACIS::APU::Queue::enqueue_item( $acis->sql_object, $per, 1 );
    }
    else {
      print "probably already claimed (or refused)\n";
    }
  }
  
  ## full-text urls
  process_fulltext_urls();
  
  ##
  ##  finishing the item
  ##
  $ardb -> {record} = $item;
  
}

sub process_text_lost {
  ## a copy of process_resource_lost() from ARDB::ReDIF::Processing
  my $ardb   = shift;
  my $record = shift;
  my $config = $ardb -> config;
  my $sql    = $ardb -> sql_object;
  my $sid    = $record -> {sid};
  if ( $sid ) {
    foreach ( qw( res_creators_bulk res_creators_separate ) ) {
      $config ->table($_) ->delete_records( 'sid', $sid, $sql );
    }
    $config -> table( "acis:rp_suggestions" ) ->delete_records( 'psid', $sid, $sql );
    ## update full-text urls table
    clear_urls_for_dsid($sid,$ardb);
  }
}


sub process_collection {
  process_text( );
}

##
## process author data
##
sub process_authors {
  $authors   = '';
  @authors   = ();
  @au_emails = ();
  my @aus = $rec -> get_value( 'hasauthor' );
  foreach ( @aus ) {
    my $name=&process_name($_);
    next if not $name;
    my $em = $_ ->get_value('email') || '';
    push @au_emails, $em;
    push @authors,   $name;
  }
  $authors = &normalize_personal_names( \@authors );
  if ( $authors ) {
    my $au = &pack_names($authors);
    $item -> {authors} = $au;
  }
}

##
## process editors the same way as authors really
##
sub process_editors {
  $editors   = '';
  @editors   = ();
  @ed_emails = ();
  my @eds = $rec-> get_value( 'haseditor' );
  foreach ( @eds ) {
    my $name=&process_name($_);
      next if not $name;
    my $em = $_ ->get_value('email') || '';
    push @ed_emails, $em;
    push @editors  , $name;
  }
  $editors = &normalize_personal_names ( \@editors );
  if ( $editors ) {
    my $ed = &pack_names($editors);  
    $item -> {editors} = $ed;
  }
}



sub extract_part_of_relationships {
  my $ARDB      = shift;
  my $record    = shift;
  my $relations = shift;
  
  assert( $record );
  assert( $relations );
  
  my $id        = $record -> id;
  

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



sub short_lc_record_type {
  my $t  = lc $rec -> type;
  my $t2 = $rec -> get_value( 'type' );
  
  if ( $t eq 'collection' ) {
    if ( $t2 eq 'serial' ) {
      return 'series';
    }
    elsif ( $t2 eq 'book' ) {
      return 'book';
    }
  } 
  elsif ( $t eq 'text' ) {
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




sub process_organization {
  my $ARDB = shift;
  my $rec  = shift;
  my $sql  = $ARDB -> sql_object;
  $te = AMF::2ReDIF::translate( $rec );
  ARDB::ReDIF::Processing::process_institution( $ARDB, $te, $relations, 1 );
}

sub process_fulltext_urls {
  my @authurls = get 'file/url';
  my @addiurls = get 'hasversion/file/url';
  process_urls_for_resource( $sid, \@authurls, \@addiurls, $id, $ardb );
}

##
## removes whitespace at the beginning and end
##
sub rem_blank {
  my $in=shift;
  $in =~ s/(^\s+|\s+$)//g;
  return $in;
}


##
## function to process name data, common to authors and editors
##
sub process_name {
  my $in=shift;
  ## first use a concatenation of individual components
  ## as name
  my $composedname='';
  my $givenname.=&rem_blank($in->get_value('givenname'));
  my $familyname.=&rem_blank($in->get_value('familyname'));
  my $additionalname.=&rem_blank($in->get_value('additionalname'));
  ## the prefix is not actually used
  ## my $nameprefix.=&rem_blank($in->get_value('nameprefix'));
  my $namesuffix.=&rem_blank($in->get_value('namesuffix'));
  ## a composed name must have given and family name
  if($givenname and $additionalname and $familyname) {
    $composedname.=$givenname.' '.$additionalname
      .' '.$familyname;
  }
  if($givenname and $familyname) {
    $composedname.=$givenname.' '.$familyname;
  }
  ## The suffix is only used for the jr, otherwise
  ## we ignore it. Not sure if I should also check
  ## for uppercase.
  if($namesuffix=~m|^Jr\.*$|) {
    $composedname.=" $namesuffix";
  }
  ## composed name has priority
  if($composedname) {
    return $composedname;
  }
  ## otherwise look at the name
  my $name = $in->get_value('name') || return;
  $name = &rem_blank($name);
  if(defined($namesuffix)) {
    $name=$name.', '.$namesuffix;
  }
  return $name;
}



##
## packs names in one string as Ivan wanted to do it
##
sub pack_names {
  my $in = shift;
  $in =~ s/(?:^\x{1}|\x{1}$)//g;
  $in =~ s/\x{1}/ & /g;
  return $in;
}



##
## originally part of ARDB::ReDIF processing
##
sub normalize_personal_names {
  my $list = shift;
  my $etal;
  my $sep = "\x1";
  my $res = '';
  ##
  ##  normalize each author name
  ##
  foreach ( @$list ) {
    next if not $_;
    next if /^\s+$/;

    if ( $_ =~ /et al(li)?/ ) {
      $_ =~ s/(?:(?:,|;)?\s*)?\bet al(li)?\b//;
      $etal = 1;
    }
    if ( $_ =~ m!et\. al\.! ) {
      $_ =~ s/(?:(?:,|;)?\s*)?\bet. al.\b//;
      $etal = 1;
    }
    ##
    ## remove control characters and symbols, if any
    ## should really be done at the level of the AMF reader
    ## maybe it is already done, at least for control chars
    ##
    $_ =~ s/[\p{C}\p{S}]//g;
    $_ =~ s/,\s*/, /g;
    $_ =~ s/\.\s*/. /g;
    $_ =~ s/\. ([-,])/.$1/g;
    $_ =~ s/(\b[A-Z]\b)([^'\w\.]|$)/$1.$2/g;
    $_ =~ s/(^\s+|\s+$)//g;
    $_ =~ s/\s+/ /g;

    if ( $_ and length( $_ ) > 1 ) {
      $res .= $sep;
      $res .= $_;
    }
    ## from the Web::HumanNames module.
    &ACIS::Web::HumanNames::normalize_name();
    $_=lc($_);
    if ( not $_ ) { $_ = 'InvalidName'; }
  }
  if ( $etal ) { $res .= "${sep}et al"; }
  if ( $res )  { $res .= $sep; }
  
  return $res;
}


##
## makes location string
##
sub make_location_string {
  my $rec=shift;
  my $location = '';
  ##
  ## Ivan's old code. not exactly a moment of glory
  ##
  ##foreach ( qw( journaltitle journalabbreviatedtitle
  ##              journalidentifier
  ##              issuedate volume part issue
  ##              season quarter startpage endpage pages
  ##             articlenumber
  ##           ) ) {
  ##  
  ## new code, draws heavily on data found in Xref
  ##
  my $journal_title=$rec -> get_value('serial/journaltitle' );
  if(not $journal_title) {
    $location =~ s/\s+/ /g;
    $location =~ s/(^\s+|\s+$)//g;
    return $location;
  }
  $location    .= $journal_title;
  my $volume    = $rec -> get_value('serial/volume');
  if($volume) {
    $location  .= ", vol. $volume";
  }
  my $part      = $rec->get_value('serial/part' );
  if($part) {
    $location  .= ", no. $part"; 
  }
  my $start_page= $rec -> get_value('serial/startpage' );
  if($start_page) {
    $location  .= ", pp. $start_page";
  }
  my $end_page  = $rec -> get_value('serial/endpage' );
  if($start_page == $end_page) {
    $location  .= ~s|, pp\. $start_page|, p. $start_page|g ;
    $location =~ s/\s+/ /g;
    $location =~ s/(^\s+|\s+$)//g;
    return $location;
  }
  if($end_page) {    
    $location  .= "\x{2013}$end_page";
  }
  $location =~ s/\s+/ /g;
  $location =~ s/(^\s+|\s+$)//g;
  return $location;
}


1;

