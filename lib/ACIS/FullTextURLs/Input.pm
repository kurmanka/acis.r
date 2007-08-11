package ACIS::FullTextURLs::Input;

# the update daemon (RePEc::Index::*) would supply us input data for
# the FullTextUrlsAMF collections and we would handle it.

use strict;
use warnings;

use Carp::Assert;
use ACIS::FullTextURLs;
use ACIS::FullTextURLs::List;
# see also: RePEc::Index::Collection::FullTextUrlsAMF module
use Exporter qw(import);
use vars qw(@EXPORT_OK);
@EXPORT_OK=qw( process_urls_for_resource store_urls_for_dsid clear_urls_for_dsid clear_urls_from_source);


my ($ardb);
sub prepare() {
  if ( not $ardb ) { 
    require ARDB::Local;
    $ardb = ARDB -> new();
  }
}

sub p(@) { print @_, "\n"; }

sub process_record {
  my (undef,$id,$type,$rec) = @_;
  # $id   = 'repec:som:ething:blahblah007#fturls'
  # $type = fturls
  prepare();

  # get dsid via $id
  my $dsid;
  my ($resourceid) = ($id =~ m!(.*)#fturls$!);
  my $sql = $ardb->{sql_object};
  $sql->prepare( 'select sid from resources where id=?');
  my $result = $sql->execute($resourceid);
  if ($result and $result->{row}) {
    $dsid = $result->{row}{sid};
    p "resource: $resourceid \tdsid: $dsid";
  } else {
    p "resource: $resourceid \tis not known";
  }
  if ($dsid) {
    process_urls_for_resource( $dsid, $rec->authoritative, $rec->automatic, $id, $ardb );    
  } else {
    clear_urls_from_source( $id, $ardb ); # correct?
  }
}

sub delete_record {
  my (undef,$id) = @_;
  prepare();
  clear_urls_from_source( $id, $ardb );
}



sub process_urls_for_resource {
  my ($dsid, $authlist, $autolist, $source, $ardb) = @_;
  assert( $dsid );
  assert( $source );
  store_urls_for_dsid( $dsid, $authlist, 'authoritative', $source, $ardb ); 
  store_urls_for_dsid( $dsid, $autolist, 'automatic',     $source, $ardb ); 

  # clear old urls (the disappeared ones)
  my $urlindex = {};
  foreach (@$authlist) { $urlindex->{$_}=1 } 
  foreach (@$autolist) { $urlindex->{$_}=1 }

  my $config = $ardb->{config};
  my $sql    = $ardb->{sql_object};
  my $table  = $config->table('acis:ft_urls');
  my $tabname = $table->realname;
  $sql->prepare( "select url from $tabname where dsid=? and source=?" );
  my $r = $sql->execute( $dsid, $source );
  while ( $r and $r->row ) {
    my $rec = $r->row;
    my $url = $rec->{url};
    if ( not $urlindex->{$url} ) {
      $sql->prepare_cached( "delete from $tabname where dsid=? and source=? and url=?" );
      $sql->execute( $dsid,$source,$url );
    }
    $r->next;
  }
}

sub store_urls_for_dsid {
  my ($dsid,$list,$nature,$source,$ardb) = @_;
  die if not $ardb;
  assert( $nature eq 'authoritative' or $nature eq 'automatic' );
  my $config = $ardb -> {config};
  my $sql    = $ardb -> {sql_object};
  my $table  = $config -> table( 'acis:ft_urls' );
  foreach ( @$list ) {
    next if not $_;
    my $item = {
                dsid => $dsid,
                url  => $_,
                checksum => Digest::MD5::md5( $_ ),
                nature => $nature,
                source => $source
               };
    $table ->store_record( $item, $sql );
  }
}

sub clear_urls_for_dsid {
  my ($dsid,$ardb) = @_;
  my $sql    = $ardb -> {sql_object};
  my $config = $ardb -> {config};
  my $table  = $config -> table( 'acis:ft_urls' );
  die if not $sql or not $table;
  my $tabname = $table->realname;
  $sql->do( "delete from $tabname where dsid=?", undef, $dsid );
}

sub clear_urls_from_source {
  my ($source,$ardb) = @_;
  my $sql    = $ardb -> {sql_object};
  my $config = $ardb -> {config};
  my $table  = $config -> table( 'acis:ft_urls' );
  die if not $sql or not $table;
  my $tabname = $table->realname;
  $sql->do( "delete from $tabname where source=?", undef, $source );
}





1;
