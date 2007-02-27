package ACIS::Web::Contributions::Fuzzy;

use strict;
use warnings;
use Carp;
use String::Approx qw( amatch );

use Web::App::Common;
use ACIS::Web::Contributions;
use ACIS::Web::Contributions::Back qw(save_suggestions);
use ACIS::Web::Background qw( logit );

my $rdb;
my $name_search_table;

sub run_fuzzy_searches {
  my $app     = shift;
  my $context = shift;
  my $sql     = $app -> sql_object;
  my $session = $app -> session;
  my $id      = $session -> current_record->{id};
  my $contributions = $session ->{$id} {contributions} ;
  my $autosearch  = $contributions -> {autosearch};
  my $namelist    = $autosearch -> {'names-list'};
  $rdb = $app -> config( 'metadata-db-name' );

  $name_search_table = $app->sysflag('research.search.fuzzy.rare.names.table') || "$rdb.res_creators_separate";

  logit "search_for_resources_fuzzy: enter";

  foreach ( @$namelist ) {
    my $search = search_resources_for_name_fuzzy( $sql, $context, $_ );
    my $found = ( defined $search ) ? scalar( @$search ) : 'nothing' ;
    logit "fuzzy name: '$_', found: $found";

    if ( $search and scalar @$search ) {
      save_suggestions( $sql, $context, 'fuzzy-name-variation-match', '', $search );
    }
  }

  logit "search_for_resources_fuzzy: exit";
}

my $min_name_length = 7;
my $exact_name_prefix = 3;
my $distance_level = "10%";
my $distance_level_ref = [ $distance_level ];

use Encode qw(decode_utf8);
sub search_resources_for_name_fuzzy {
  my $sql     = shift;
  my $context = shift;
  my $name    = shift;

  return undef if not $name or length( $name ) < $min_name_length;
  my $result = [];
  my $prefix = lc substr( $name, 0, $exact_name_prefix );
  $name = lc $name;
  my $dsid_list = [];

  ###  the query
  $sql -> prepare_cached( "select name,sid from $name_search_table where name like ?" );
  warn "SQL: " . $sql->error if $sql->error;
  my $res = $sql->execute ( $prefix . '%' );
  warn "SQL: " . $sql->error if $sql->error;

  if ( $res ) {
    my $data = $res ->data;
    foreach ( @$data ) {
      my $dname = decode_utf8( $_->{name} );
      my $dsid = $_->{sid};
      
      if ( $dname eq $name ) {
        # exact match, not our domain
      } else {
        if ( scalar amatch( $name, $distance_level_ref, $dname ) ) {
          logit "fuzzy match: '$dname' ($dsid) ~ $name";
          # suggest $dsid
          push @$dsid_list, $dsid;
        } else {
#          logit "no match: '$dname' ($dsid) ~ $name";
        }
      }
    }
  }

  logit "intermediate results: " . (scalar @$dsid_list) . ' ' . join( ' ', @$dsid_list );

  if ( not scalar @$dsid_list ) { return undef; }
  $sql -> prepare_cached( "select r.id,o.data from $rdb.resources r join $rdb.objects o using(id) where sid=?" );
  foreach ( @$dsid_list ) {
    my $r = $sql->execute( $_ );
    if ( $r ) {
      ACIS::Web::Contributions::process_resources_search_results( $r, $context, $result );
    }
  }

  return $result;
}




1;
