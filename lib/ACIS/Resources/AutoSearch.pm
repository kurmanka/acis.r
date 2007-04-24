package ACIS::Resources::AutoSearch;

use strict;
use warnings;

use Carp::Assert;
use Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw( 
              automatic_resource_search_now
              prepare_for_auto_search
              get_bg_search_status
              start_auto_res_search_in_bg
              get_last_autosearch_time
           );

use Data::Dumper;
use Carp;
use Web::App::Common;
use ACIS::Resources;
use ACIS::Resources::Search;
use ACIS::Resources::Suggestions;
use ACIS::Resources::SearchFuzzy;

use ACIS::Web::Background qw(logit);
use ACIS::Web::SysProfile;
require ACIS::Web::Contributions;


sub prepare_search_context {
  my $app = shift;
  my $init = shift || {};
  logit "prepare_search_context: start";

  my $sql = $app -> sql_object;
  # a work-around for a mysql/something bug when the first query after the
  # fork() fails for no apparent reason, but the second one works fine:
  $sql -> do( "select 1+1" );

  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};
  logit "for profile $sid ($id)";

  my $contributions   = $session ->{$id} {contributions} ;
  my $current_index   = $contributions -> {'already-accepted'};
  my $already_refused = $contributions -> {'already-refused' };

  if ( not $contributions -> {'already-suggested'} ) {
    load_suggestions_into_contributions( $app, $sid, $contributions );
  }
  my $already_suggested = $contributions -> {'already-suggested'};

  my $ignore_index = {};
  foreach ( keys %$current_index, 
            keys %$already_refused 
          ) {
    $ignore_index ->{$_} = 1;
  }

  logit scalar( keys %$ignore_index ), " items in ignore list";

  return {
          %$init,
    db      => $app->config('metadata-db-name'),
    found   => {},
    already => $ignore_index,
    id      => $id, 
    sid     => $sid,
    already_suggested => $already_suggested,
  };
}

sub prepare_for_auto_search {
  my $app     = shift;
  debug "prepare_for_auto_search: enter";

  my $session = $app -> session;
  my $record  = $session -> current_record() || die;
  my $id      = $record ->{id} || die;
  my $sid     = $record ->{sid};
  my $contributions = $session ->{$id} {contributions};
  my $autosearch    = $contributions -> {autosearch};
  { 
    if ( not exists $contributions -> {autosearch} 
         or $autosearch == 1 ) {
      $contributions ->{autosearch} = $autosearch = {}
    }
    $record -> {contributions} {autosearch} = $autosearch;
  }

  my $name = $record->{name};
  my $variations = $name->{variations};
  $autosearch -> {'names-list'} = [grep {$_} @$variations];

  my $nicelist = [];
  push @$nicelist, @{ $name ->{'additional-variations'} };
  push @$nicelist, $name ->{full};
  push @$nicelist, $name ->{latin}
    if $name->{latin};
  $autosearch -> {'names-list-nice'} = $nicelist;

  debug "prepare_for_auto_search: exit";
  return $autosearch;
}


sub search_done {
  my $app     = shift;
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record ->{id} || die;
  my $sid     = $record ->{sid};
  my $contributions = $session ->{$id} {contributions};
  my $autosearch    = $contributions -> {autosearch};

  put_sysprof_value( $record -> {sid}, 'last-autosearch-time', scalar time );

  my $names_last_change_date = $record -> {name}{'last-change-date'};
  $autosearch -> {'for-names-last-changed'} = $names_last_change_date;
}

sub get_last_autosearch_time {
  my $app     = $Web::App::APP;
  my $session = $app -> session;
  my $rec     = $session -> current_record;
  my $sid    = $rec->{temporarysid} || $rec->{sid};
  my $result = get_sysprof_value( $sid, "last-autosearch-time" );
  return $result;
}


sub get_bg_search_status {
  my $app = shift;
  debug "get_bg_search_status";
  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record -> {id} ;
  my $sid     = $record -> {sid};
  my $tsid    = $record->{temporarysid};
  my $status  = '';
  my $threads;

  if ( $tsid and $sid ) {
    $threads = ACIS::Web::Background::check_thread( $app, $tsid );
    $app -> sql_object -> do( "update rp_suggestions set psid=? where psid=?", $sid, $tsid );
    if ( $threads ) {
      # let it run
    } else {
#      delete $record->{temporarysid};
      undef $tsid;
    }
  } 
  if ( not $tsid ) {
    $threads = ACIS::Web::Background::check_thread( $app, $sid );
  }
  
  if ( $threads ) {
    my $types = {};
    foreach ( @$threads ) {
      if ( $_->{type} eq 'res-autosearch' ) {
        $status = 'running';
        last;
      }
    }
  }

  debug "get_bg_search_status: $status";
  return $status;
}


sub search_for_resources_exact {
  my $app     = shift;
  my $context = shift;
  logit "search_for_resources_exact: enter";

  my $sql     = $app -> sql_object;
  my $session = $app -> session;
  my $record  = $session ->current_record;
  my $id      = $record->{id};
  my $contributions = $session ->{$id} {contributions};
  my $autosearch  = $contributions -> {autosearch};
  my $namelist    = $autosearch -> {'names-list'};

  ###  search for exact matches
  foreach ( @$namelist ) {
    next if not $_;
    my $search = search_resources_for_exact_name( $sql, $context, $_ );
    my $found = ( defined $search ) ? scalar( @$search ) : 'nothing' ;
    logit "exact name: '$_', found: $found";
    save_search_results( $context, 'exact-name-variation-match', $search );
  }

  logit "search_for_resources_exact: exit";
}

sub save_search_results {
  my ($context,$reason,$results) = @_;
  return undef if not $results or not scalar @$results;
  my $sql = $ACIS::Web::ACIS->sql_object;
  my $psid = $context->{sid};
  if ($context->{save_result_func}) {
    my $save_func = $context->{save_result_func};
    &{$save_func}   ( $sql, $psid, $reason, undef, $results );
  } else {
    save_suggestions( $sql, $psid, $reason, undef, $results );
  }
  return 1;
}

sub additional_searches {
  my $app     = shift;
  my $context = shift;
  
  logit "additional_searches: enter";

  my $sql     = $app -> sql_object;
  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};

  my $metadata_db   = $app -> config( 'metadata-db-name' );
  my $contributions = $session ->{$id} {contributions} ;
  my $autosearch    = $contributions -> {autosearch};
  my $namelist      = $autosearch -> {'names-list'};

  ###  NAME PART SEARCH
  my $search = search_resources_for_exact_phrases($sql, $context, $namelist);
  {
    my $found = ( defined $search ) ? scalar @$search : 'nothing' ;
    logit "exact phrases search for a list of names, found: $found";
    
    if ( $search and scalar @$search ) {
      if ( $found < 200 ) { 
        save_search_results( $context, 'name-variation-part-match', $search );
      } else {
        logit "too many hits, ignoring";
      }
    }
  }

  ###  now search by email address 
  {
    my $email = $record -> {contact} {email};
    if ( $email ) {
      my $by_email = search_resources_by_creator_email($sql, $context, $email);
      save_search_results( $context, 'exact-email-match', $by_email );
    }
  }


  ###  now search by surname alone as a substring 
  my $lastname = $record ->{name}{last};
  my $suggestions_3 = search_resources_for_exact_phrases($sql, $context, [$lastname]);
  {
    my $found = ( defined $suggestions_3 ) ? scalar @$suggestions_3 : 'nothing' ;
    logit "suggestions by surname as a word: $found";
    if ( $found > 0 ) {
      if ( $found < 200 ) { 
        save_search_results( $context, 'surname-part-match', $suggestions_3 );
      } else {
        logit "too many hits, ignoring";
      }
    }
  }

  logit "additional_searches: exit";
}






sub do_auto_search {
  my $app = shift;
  my $settings = shift;
  my $session = $app -> session;
  my $id      = $session -> current_record -> {id};

  my $context = prepare_search_context( $app, $settings );
  if ( not $session -> {$id} {'reloaded-accepted-contributions'} ) {
    ACIS::Web::Contributions::reload_accepted_contributions( $app );
  }

  debug "auto search initiated: ", $settings->{via_web} ? "online" : "apu";
  search_for_resources_exact( $app, $context );

  if ( $app -> config( "research-additional-searches" ) ) {
    additional_searches( $app, $context ); 
    if ( $app->config( "fuzzy-name-search" ) ) {
      # are we running search started via web interface, or started via
      # APU?  If via the web, check if that's ok for fuzzy search.
      if ( not $settings->{via_web} 
           or $app->config( "fuzzy-name-search-via-web" ) ) {
        run_fuzzy_searches( $app, $context );
      }
    }
  }
}


sub automatic_resource_search_now {
  my $app = shift;
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};
  prepare_for_auto_search( $app );
  do_auto_search( $app, @_ );
  search_done( $app );
  return 1;
}


sub start_auto_res_search_in_bg {
  my $app = shift;
  debug "start_auto_res_search_in_bg: enter";

  my $sql = $app -> sql_object;
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};
  my $autosearch    = prepare_for_auto_search( $app );

  my $res = ACIS::Web::Background::run_thread ( 
              $app, $sid,
             'res-autosearch', 
             'ACIS::Resources::AutoSearch::do_auto_search',
             { via_web => 1 },
            );

  if ( $res ) {
    $app -> success;
    $app -> {sql_object} = undef;
    debug "back thread to search for contributions started";
    $record -> {contributions} {autosearch} = $autosearch;
    search_done( $app );
  }

  debug "start_auto_res_search_in_bg: exit";
  return $res;
}





1;




