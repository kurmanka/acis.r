package ACIS::Citations::Input;

use strict;
use warnings;
use Carp::Assert;

require ARDB::Local;
my $ardb;
my $config;
my $sql;
my $adb;

use Digest::MD5;
use ACIS::Citations::Utils qw( normalize_string make_citation_nstring );

use Storable;

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


sub DEBUG { 0; }
sub process_record {
  shift;

  my $id     = shift;
  my $type   = shift;
  my $record = shift;
  
  my $srcdocid = $record -> id;
  print "src doc id: $srcdocid\n"
    if DEBUG;

  # prepare
  prepare;
  assert( $ardb );
  
  # find srcdocsid and URL
  my $srcdocsid = find_doc_details( $srcdocid );

  if ( $srcdocsid ) {
    print "srcdocsid: $srcdocsid\n"
      if DEBUG;
  } else {
    print "srcdocsid:no\n"
      if DEBUG;
  }

  if ( not $srcdocsid ) { return undef; }

  my $cit = { srcdocsid => $srcdocsid, };

  my $table  = $config -> table( 'acis:citations' );

  # build index of already known citations (originating from
  # this doc)
  my $index = {};
  {
    $sql -> prepare_cached( "select checksum from $adb.citations where srcdocsid=?" );
    my $res = $sql -> execute( $srcdocsid );
    while ( $res and $res->{row} ) {
      my $s = $res->{row}{checksum};
      $index ->{$s} = 1;
    } continue { 
      $res->next;
    }
  }
  print "citations already known: ", scalar keys %$index, "\n"
    if DEBUG;
  print "citations now: ", scalar( @$record )-1, "\n"
    if DEBUG;

  # process and save citations
  foreach ( @$record ) {
    next if not ref $_;

    my $trg = $_->{trgdocid};
    my $ost = $_->{ostring};
    
    my $nst = make_citation_nstring $ost;
    my $md5 = Digest::MD5::md5_base64( $ost );

    delete $index->{$md5};

    $cit -> {ostring}  = $ost;
    $cit -> {trgdocid} = $trg;
    $cit -> {nstring}  = $nst;
    $cit -> {checksum} = $md5;
    
    $table -> store_record ( $cit, $sql );
  }

  # delete the records that were in this doc before, but not
  # anymore (i.e. which disappeared)
  $sql -> prepare_cached( "delete from $adb.citations where srcdocsid=? and checksum=?" );
  foreach ( keys %$index ) {
    $sql -> execute( $srcdocsid, $_ );
  }
  print "citations disappeared: ", scalar keys %$index, "\n"
    if DEBUG;

  return 1;
}




sub delete_record {
  shift;
  my $id = shift;

  prepare;
  assert( $ardb );

  $id =~ s/#citations$//g;
  my ( $sid ) = find_doc_details( $id );
  
  $sql -> prepare_cached( "delete from $adb.citations where srcdocsid=?" );
  $sql -> execute( $sid );
}




1;

