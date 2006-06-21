package ACIS::Citations::Input;

use strict;
use warnings;
use Carp::Assert;

require ARDB::Local;
my $ardb;


use Digest::MD5;
use ACIS::Citations::Utils qw( normalize_string );

use Storable;

sub process_record {
  shift;

  my $id     = shift;
  my $type   = shift;
  my $record = shift;
  
  my $srcdocid = $record -> id;

  # prepare
  if ( not $ardb ) { 
    $ardb = ARDB -> new();
  }
  assert( $ardb );

  my $config = $ardb -> {config};
  my $sql = $ardb -> sql_object();
  my $adb = $ardb -> {site_config} -> resolve_db_alias( 'acis' );

  print "src doc id: $srcdocid\n";
  
  # find srcdocsid
  my $srcdocsid = '';
  my $srcdocdetails = '';
  {

    my $rec = $ardb -> get_record( $srcdocid );

    if ( $rec ) {
      $srcdocsid =     $rec -> {sid};
      $srcdocdetails = $rec -> {'url-about'};

    } else {
      print "  ... ask resources table\n";
      $sql -> prepare( "select sid from resources where id=?" );
      my $res = $sql -> execute( $srcdocid );
      if ( $res -> {row} and $res -> {row} ->{sid} ) {
        $srcdocsid = $res -> {row} ->{sid};
      }

    }
  }

  print "src doc sid: $srcdocsid\n";
  print "src doc details: $srcdocdetails\n";

#  if ( not $srcdocsid ) { $srcdocsid = 'undef'; }
  if ( not $srcdocsid ) { return undef; }

  my $cit = { srcdocsid => $srcdocsid,
              srcdocdetails => $srcdocdetails,
              };

  my $table  = $config -> table( 'acis:citations' );

  foreach ( @$record ) {
    next if not ref $_;

    my $trg = $_->{trgdocid};
    my $ost = $_->{ostring};
    
    ### XXX cut the editors part 
    my $nst = normalize_string( $ost );
    my $md5 = Digest::MD5::md5_base64( $ost );

    $cit -> {ostring} = $ost;
    $cit -> {trgdocid} = $trg;
    $cit -> {nstring} = $nst;
    $cit -> {checksum} = $md5;
    
    $table -> store_record ( $cit, $sql );
  }

  # XXX delete the records which disappeared

  return 1;
}

sub delete_record {

  shift;
  my $id = shift;

}


1;

