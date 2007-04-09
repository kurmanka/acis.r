package ACIS::Citations::Input;

use strict;
use warnings;

require ARDB::Local;
my $ardb;
my $config;
my $sql;
my $adb;

use Digest::MD5;
use ACIS::Citations::Utils qw( make_citation_nstring );
sub DEBUG() { 1 }

sub prepare() {
  if ( not $ardb ) { 
    $ardb = ARDB -> new();
    $config = $ardb -> {config};
    $sql = $ardb -> sql_object();
    $adb = $ardb -> {site_config} -> resolve_db_alias( 'acis' );
  }
}


sub find_doc_details($) { 
  my $id  = shift;
  $id = lc $id; ### XXX RePEc-specific?

  # find srcdocsid
  my $srcdocsid = '';
  {
    $sql -> prepare( "select sid from resources where id=?" );
    my $res = $sql -> execute( $id );
    if ( $res -> {row} and $res -> {row} ->{sid} ) {
      $srcdocsid = $res -> {row} ->{sid};
    }
  }

  return $srcdocsid;
}


sub process_record {
  shift;
  my $id     = shift;
  my $type   = shift;
  my $record = shift;
  my $srcdocid = $record -> id;
  print "src doc id: $srcdocid\n"
    if DEBUG;

  prepare;
  
  # find srcdocsid and URL
  my $srcdocsid = find_doc_details( $srcdocid );
  if ( $srcdocsid ) {
    print "srcdocsid: $srcdocsid\n" if DEBUG;
  } else {
    print "srcdocsid:no\n"   if DEBUG;
    # so, if a document disappears from rdb.resources, it's citations would stick around. XXX
    return undef;
  }

  my $cit = {};  
  my $table  = $config -> table( 'acis:citations' );

  # build index of already known citations (originating from this doc)
  my $index = {};
  {
    $sql -> prepare_cached( "select clid from $adb.citations where clid like ?" ); 
    my $res = $sql -> execute( "$srcdocsid-\%" );
    while ( $res and $res->{row} ) {
      my $s = $res->{row}{clid}; 
      $index ->{$s} = 1;
      $res->next;
    }
  }

  # build index of previously known, but then deleted citations,
  # originating from this doc
  my $delindex = {};
  {
    $sql -> prepare_cached( "select cnid,clid from $adb.citations_deleted where clid like ?" ); 
    my $res = $sql -> execute( "$srcdocsid-\%" );
    while ( $res and $res->{row} ) {
      my $l = $res->{row}{clid}; 
      my $n = $res->{row}{cnid}; 
      $delindex ->{$l} = $n;
      $res->next;
    }
  }

  print "citations already known: ", scalar keys %$index, ' (', scalar keys %$delindex, ")\n"
    if DEBUG;
  print "citations now: ", scalar( @$record )-1, "\n"
    if DEBUG;

  # process and save citations
  foreach ( @$record ) {
    next if not ref $_;
    my $ost = $_->{ostring};
    my $md5 = Digest::MD5::md5_base64( $ost );
    my $clid = "$srcdocsid-$md5";
    delete $index->{$clid};
    $cit -> {clid}     = $clid;
    $cit -> {srcdocsid} = $srcdocsid;
    $cit -> {ostring}  = $ost;
    $cit -> {trgdocid} = $_->{trgdocid};
    $cit -> {nstring}  = make_citation_nstring $ost;
    $cit -> {cnid} = (exists $delindex->{$clid}) ? $delindex->{$clid} : undef;
    
    $table -> store_record ( $cit, $sql );
  }

  # delete the records that were in this doc before, but not
  # anymore (i.e. which disappeared)
  $sql -> prepare_cached( "replace into $adb.citations_deleted select cnid,clid from $adb.citations where clid=?" ); 
  foreach ( keys %$index ) {
    $sql -> execute( $_ );
  }
  $sql -> prepare_cached( "delete from $adb.citations where clid=?" ); 
  foreach ( keys %$index ) {
    $sql -> execute( $_ );
  }
  print "citations disappeared: ", scalar keys %$index, "\n"
    if DEBUG;

  return 1;
}



sub delete_record {
  shift;
  my $id = shift;
  prepare;
  $id =~ s/#citations$//g;
  my $sid  = find_doc_details( $id );
  my $mask = "$sid-%";
  $sql -> prepare_cached( "replace into $adb.citations_deleted select cnid,clid from $adb.citations where clid like ?" ); 
  $sql -> execute( $mask );
  $sql -> prepare_cached( "delete from $adb.citations where clid like ?" ); 
  $sql -> execute( $mask );
}


1;
