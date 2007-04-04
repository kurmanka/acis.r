package ACIS::FullTextURLs;

use strict;
use warnings;

use Digest::MD5;
use Carp;
use Carp::Assert;
use Web::App::Common;
use Exporter qw(import);
use vars qw(@EXPORT_OK);
@EXPORT_OK=qw( process_urls_for_resource store_urls_for_dsid clear_urls_for_dsid get_urls_for_dsid get_choices_for_dsid save_choice );

# these functions are called from ARDB handlers

sub process_urls_for_resource {
  my ($dsid, $authlist, $autolist, $ardb) = @_;
  assert( $dsid );
  store_urls_for_dsid( $dsid, $authlist, 'authoritative', $ardb ); 
  store_urls_for_dsid( $dsid, $autolist, 'automatic', $ardb ); 

  # clear old urls (the disappeared ones)
  my $urlindex = {};
  foreach (@$authlist) { $urlindex->{$_}=1 } 
  foreach (@$autolist) { $urlindex->{$_}=1 }

  my $config = $ardb->{config};
  my $sql    = $ardb->{sql_object};
  my $table  = $config->table('acis:ft_urls');
  my $tabname = $table->realname;
  $sql->prepare( "select url from $tabname where dsid=?" );
  my $r = $sql->execute( $dsid );
  while ( $r and $r->row ) {
    my $rec = $r->row;
    my $url = $rec->{url};
    if ( not $urlindex->{$url} ) {
      $sql->prepare_cached( "delete from $tabname where dsid=? and url=?" );
      $sql->execute( $dsid, $url );
    }
    $r->next;
  }
}

sub store_urls_for_dsid {
  my ($dsid,$list,$nature,$ardb) = @_;
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
                nature => $nature
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
  $table->delete_records( 'dsid', $dsid, $sql );
}


# the following functions are called from the ACIS::Web handlers 

sub get_urls_for_dsid($) {
  my ($dsid) = @_;
  my $acis = $ACIS::Web::ACIS;
  my $sql = $acis -> sql_object;
  my @res;

  $sql -> prepare_cached( "select * from ft_urls where dsid=?" );
  my $r = $sql->execute( $dsid );
  while( $r and $r->{row} ) {
    push @res, $r->{row};
    $r->next;
  }
  return \@res;
}

sub get_choices_for_dsid($$) {
  my ($dsid,$psid) = @_;
  my $acis = $ACIS::Web::ACIS;
  my $sql = $acis -> sql_object;
  my @res;

  $sql -> prepare_cached( "select * from ft_urls_choices where dsid=? and psid=?" );
  my $r = $sql->execute( $dsid, $psid );
  while( $r and $r->{row} ) {
    push @res, $r->{row};
    $r->next;
  }
  return \@res;
}

sub save_choice($$$$) {
  my ($dsid,$url,$psid,$choice) = @_;
  my $acis = $ACIS::Web::ACIS;
  my $sql = $acis -> sql_object;
  my @res;

  $sql -> prepare_cached( "replace into ft_urls_choices (dsid,checksum,psid,choice,time) values (?,?,?,?,NOW())" );
  my $checksum = Digest::MD5::md5( $url );
  my $r = $sql->execute( $dsid,$checksum,$psid,$choice );
  return $r;
}


sub load_urls_for_rp {
  my $record = shift;
  #my $acis = $ACIS::Web::ACIS;
  #my $sql = $acis -> sql_object;
  assert( $record and $record->{type} eq 'person' ); # sanity
  my $rp = $record->{contributions}{accepted} || [];
  
  my @grouped_urls;
  foreach ( @$rp ) {
    my $sid = $_->{sid} || next;
    my @urls = get_urls_for_dsid( $sid );
    foreach (@urls) { delete $_->{dsid} }
    push @grouped_urls, [$sid,@urls]
      if scalar @urls;
  }
  return \@grouped_urls;
}

sub get_ft_urls_choices {
  my ($record) = @_;
  my $choices = undef;
}

sub load_everything {
  my $record = shift;
  my $acis = $ACIS::Web::ACIS;
  my $sql = $acis -> sql_object;
  assert( $record and $record->{type} eq 'person' ); # sanity
  my $rp = $record->{contributions}{accepted} || [];
  my $psid = $record ->{sid} || die;
  my @grouped_urls;
  debug "load_everything: " . scalar @$rp;

  #use Data::Dumper;
  #debug Dumper( $record->{contributions}{accepted} );
  foreach ( @$rp ) {
    my $sid = $_->{sid} || next;
    $sql -> prepare_cached( 
                           "select u.url,u.checksum,c.choice 
       from ft_urls u 
       left join ft_urls_choices c using(dsid,checksum) 
       where u.dsid=? and (c.psid is null or c.psid=?)" );

    my $r = $sql->execute($sid,$psid);
    if (not $r->{row}) {next;}

    my @items;
    my $i;
    while( $r and $i= $r->{row} ) {
      assert( $i );
      assert( $i->{url} );
      debug 'item '. $i->{url};
      push @items, $i;
      $r->next;
    }

    push @grouped_urls, {$sid => \@items }
  }
  return \@grouped_urls;
}


use Data::Dumper;
sub testme {
  use ACIS::Web;
  ACIS::Web->new();
  my $acis = $ACIS::Web::ACIS;
  my $sql = $acis -> sql_object;
  my $dsid = 'dana35'; #'dfun2'
  my $u = get_urls_for_dsid $dsid;
  print Dumper( $u );
  my $i = $u->[0];
  save_choice($dsid,$i->{url},'pka2','yy' ); # yc stands for "yes,that's the file" and "archive, but check for updates"
}


1;
