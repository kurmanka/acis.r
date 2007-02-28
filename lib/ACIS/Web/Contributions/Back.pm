package ACIS::Web::Contributions::Back;

use strict;
###################################################################
#########   sub search for resources (initial)    #################
###################################################################
use Exporter;
use base qw( Exporter );

use vars qw( @EXPORT_OK $back_table );
@EXPORT_OK = qw( save_suggestions );
$back_table = 'suggestions';

use Web::App::Common;
use ACIS::Web::Background qw( logit );

require ACIS::Web::Contributions::Fuzzy;


sub start_auto_search {
  my $app = shift;

  debug "start_auto_search: enter";

  my $sql = $app -> sql_object;

  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};


  my $contributions = $session ->{$id} {contributions} ;

  ACIS::Web::Contributions::prepare_for_auto_search( $app );

  my $autosearch    = $contributions -> {autosearch};

  require ACIS::Web::Background;

  my $res = ACIS::Web::Background::run_thread ( 
              $app, $sid,
             'res-autosearch', 
             'ACIS::Web::Contributions::Back::auto_search'
            );

  if ( $res ) {
    $app -> success;
    $app -> {sql_object} = undef;

    debug "back thread to search for contributions started";

    $record -> {contributions} {autosearch} = $autosearch;

    ACIS::Web::Contributions::auto_search_done( $app );
  }

  debug "start_auto_search: exit";
  return $res;
}







sub auto_search {
  my $app = shift;

  my $session = $app -> session;
  my $id      = $session -> current_record -> {id};

  my $context = prepare_search_context( $app );
  if ( not $session -> {$id} {'reloaded-accepted-contributions'} ) {
    ACIS::Web::Contributions::reload_accepted_contributions( $app );
  }
  my $search  = search_for_resources_exact( $app, $context );

  if ( $app -> config( "research-additional-searches" ) ) {
    my $add     = additional_searches( $app, $context ); 
    if ( $app->config( "fuzzy-name-search" ) ) {
      my $search  = ACIS::Web::Contributions::Fuzzy::run_fuzzy_searches( $app, $context );
    }
  }
}



sub prepare_search_context {
  my $app = shift;

  logit "prepare_search_context: start";

  my $sql = $app -> sql_object;

  ####  a work-around for a mysql/something bug when the first query after the
  ####  fork fails for no reason:
  {
    $sql -> prepare( "select 1+1" );
    $sql -> execute;
  }

  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};

  logit "for profile $sid ($id)";

  my $metadata_db = $app -> config( 'metadata-db-name' );

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

  my $context = {
    db      => $metadata_db,
    found   => {},
    already => $ignore_index,
    id      => $id, 
    sid     => $sid,
    already_suggested => $already_suggested,
  };


  return $context;
}



sub search_for_resources_exact {
  my $app     = shift;
  my $context = shift;

  logit "search_for_resources_exact: enter";

  my $sql     = $app -> sql_object;

  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};

  my $metadata_db = $app -> config( 'metadata-db-name' );

  my $contributions = $session ->{$id} {contributions} ;

  my $autosearch  = $contributions -> {autosearch};
  my $namelist    = $autosearch -> {'names-list'};


  ###  search for exact matches
  require ACIS::Web::Contributions;

  foreach ( @$namelist ) {
    my $search = 
      ACIS::Web::Contributions::search_resources_for_exact_name( $sql, $context, $_ );

    my $found = ( defined $search ) ? scalar( @$search ) : 'nothing' ;
    logit "exact name: '$_', found: $found";

    if ( $search and scalar @$search ) {
      save_suggestions( $sql, $context, 'exact-name-variation-match', '', $search );
    }
  }

  logit "search_for_resources_exact: exit";

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

  require ACIS::Web::Contributions;


  ###  NAME PART SEARCH
  my $search = 
    ACIS::Web::Contributions::search_resources_for_exact_phrases( 
        $sql, $context, $namelist );
  
  {
    my $found = ( defined $search ) ? scalar @$search : 'nothing' ;
    logit "exact phrases search for a list of names, found: $found";
    
    if ( $search and scalar @$search ) {
      if ( $found < 200 ) { 
        save_suggestions( $sql, $context, 'name-variation-part-match', '', $search );
      } else {
        logit "too many hits, ignoring";
      }
    }
  }

  ###  now search by email address 
  {
    my $email = $record -> {contact} {email};

    if ( $email ) {
      my $by_email = 
        ACIS::Web::Contributions::search_resources_by_creator_email( 
          $sql, $context, $email );
      
      save_suggestions( $sql, $context, 'exact-email-match', '', $by_email );

    }
  }


  ###  now search by surname alone as a substring 
  my $lastname = $record ->{name}{last};

  my $suggestions_3 = 
    ACIS::Web::Contributions::search_resources_for_exact_phrases( 
      $sql, $context, [ $lastname ] );
  
  {
    my $found = ( defined $suggestions_3 ) ? scalar @$suggestions_3 : 'nothing' ;
    logit "suggestions by surname as a word: $found";
    if ( $found > 0 ) {
      if ( $found < 200 ) { 
        save_suggestions( $sql, $context, 'surname-part-match', '',  $suggestions_3 );
      } else {
        logit "too many hits, ignoring";
      }
    }
  }
  

  logit "additional_searches: exit";
}


#####################################################################
#####################################################################
########     S U G G E S T I O N S    S T U F F     #################
#####################################################################
#####################################################################


use Storable qw( freeze thaw );


use Carp;

require Data::Dumper;
sub save_suggestions {
  my $sql     = shift || die;
  my $context = shift || die;
  my $reason  = shift || die;
  my $role    = shift;
  my $doclist = shift || die;

  my $psid   = $context -> {sid} || die;
  my $already_suggested = $context -> {already_suggested} || die;

  my $target = 'contributions';
  my $complained;
  
  my @replace;

  if ( scalar @$doclist ) {
    $sql -> prepare_cached ( "insert into $back_table values ( ?, ?, ?, " . 
                             " ?, '$reason', '$target', now(), ? )" );
    foreach ( @$doclist ) {
      my $osid = $_ -> {sid};
      warn( "document item with no sid: " . Data::Dumper::Dumper($_) ) if not $osid;
      next if not $osid;

      my $type = $_ -> {type};
      my $ro = $role;
      if ( $_ ->{role} ) {
        $ro = $_ ->{role};
      } 
      if ( $already_suggested->{$osid} ) {
        push @replace, $_;
        next;
      }

      my $data = freeze( $_ );

      my $r = $sql -> execute( $psid, $osid, $type, $ro, $data );
      if ( $sql -> error
           and not $complained ) {
        logit Carp::longmess( "save_suggestions(): ". $sql->error );
        $complained = 1;
      }
    }

    if ( scalar @replace ) {
      $sql -> prepare_cached( "replace into $back_table values( ?, ?, ?, ".
                              " ?, '$reason', '$target', now(), ? )" );
      foreach ( @replace ) {
        my $osid = $_ -> {sid};
        my $type = $_ -> {type};
        my $ro = $role;
        if ( $_ ->{role} ) {
          $ro = $_ ->{role};
        } 
        
        my $data = freeze( $_ );

        my $r = $sql -> execute( $psid, $osid, $type, $ro, $data );
        if ( $sql -> error
             and not $complained ) {
          logit Carp::longmess( "save_suggestions(): ". $sql->error );
          $complained = 1;
        }
        
      }
    }
  }
}
  

sub set_suggestions_reason {
  my $sql    = shift;
  my $psid   = shift;
  my $reason = shift;
  my $rsid_list = shift;

  my $target = 'contributions';
  
  if ( scalar @$rsid_list ) {
    $sql -> prepare_cached( 
                     "UPDATE $back_table SET reason='$reason', " .
                     "time=NOW() WHERE psid='$psid' AND osid=?" 
                          );
    
    foreach ( @$rsid_list ) {
      my $r = $sql -> execute( $_ );
    }
  }
}
  




sub load_suggestions {
  my $app    = shift;
  my $sid    = shift; ## personal short-id
  my $target = shift; ## load suggestions for what? (e.g. contributions)

  debug "load_suggestions: enter";


  my $result = [];

  my $sql = $app -> sql_object;

  my $query = "select * from $back_table where psid=?";
  if ( $target ) { 
    $query .= " and target=?";
  }
  $query .= " order by time ASC";

  my $reasons = {};

  $sql -> prepare ( $query ) ;
  my $r;

  if ( $target ) { 
    $r = $sql -> execute ( $sid, $target );
  } else {
    $r = $sql -> execute ( $sid );
  }

  my $group;  ### suggestions are grouped by reason (and role)
  my $list;

  while ( $r -> {row} ) {
    debug "a row";
    my $row    = $r -> {row};
    my $item;
    my $reason = $row ->{reason};
    my $data   = $row ->{data};
    my $id     = $row ->{osid};

    if ( not defined $id ) {
      warn "No id in a resource suggestion record!";
      next;
    }

#    if  ( $already_accepted -> {$id} ) { next; }
#    elsif ( $already_refused ->{$id} ) { next; }

    if ( $data ) {
      $item = thaw( $data );
    }

    if ( not $reasons -> {$reason} ) {
      $group = {};
      $group -> {reason} = $reason;
      $group -> {list}   = [];
      $reasons -> {$reason} = $group;
      push @$result, $group;

    } 

    $list = $reasons->{$reason} {list} || die;
    
    push @$list, $item;
    $r -> next;
  }

  ###  XX?  sort groups by relevance

  debug "load_suggestions: exit";
  return $result;
}


my $MAX_SUGGESTIONS_LIMIT = 1000;
sub load_suggestions_into_contributions {
  my $app = shift;
  my $sid = shift;    ## person short id
  my $contributions = shift; ## the contributions structure

  debug "load_suggestions_into_contributions: enter";
  debug "short id: $sid";

  my $sql = $app -> sql_object;
  # a sanity check for over-enthusiastic suggestions
  {
    $sql -> prepare ( "select count(*) as num from $back_table where psid=? and target='contributions'" );
    my $r = $sql -> execute ( $sid );
    if ( $r and $r->{row} and $r->{row}{num} and $r->{row}{num} > $MAX_SUGGESTIONS_LIMIT ) {
      debug sprintf "too many suggestions for this record: %d; will clean up the inexact ones", $r->{row}{num};
      $sql->do( "delete from $back_table where psid=? and target='contributions' and substr(reason,1,6)<>'exact-'" );      
    }
  }

  my $accepted         = $contributions -> {accepted};

  my $already_accepted = $contributions -> {'already-accepted'}; 
  my $already_refused  = $contributions -> {'already-refused' }; 
  my $already_suggested= $contributions -> {'already-suggested' } || {}; 

  my $suggest          = $contributions -> {suggest};


  my $result = [];

  my $query = "select * from $back_table where psid=? and target='contributions'";
  $query .= " order by time ASC";
  $sql -> prepare ( $query );

  my $r = $sql -> execute ( $sid );

  my $counter = 0;
  my $reasons = {};
  my $group;  ### suggestions are grouped by reason (and role)
  my $list ;

  while ( $r and $r -> {row} ) {

    if ( $counter++ > $MAX_SUGGESTIONS_LIMIT ) {
      # just in case the above check & clean-up didn't work or didn't help enough
      debug "enough suggestions: $counter";
      last;
    }

    debug "a row";
    my $row = $r -> {row};
    my $item;
    my $reason = $row ->{reason};
    my $data   = $row ->{data};
    my $id     = $row ->{osid};

    if ( not defined $id ) {
      warn "No id in a resource suggestion record!";
      next;
    }

    if  ( $already_accepted -> {$id} ) { next; }
    elsif ( $already_refused ->{$id} ) { next; }

    if ( $data ) {
      $item = thaw( $data );
    }
    if ( not $item -> {role} ) {
      $item -> {role}   = $row ->{role};
    }

    my $status;  ###  shall the item be preselected for the user or not?

    if ( $reason =~ s/\-s(\d)$//g ) {  ### reason might specify this
      $status = $1;
      $item -> {status} = $status;
    }
    
    if ( not $reasons -> {$reason} ) {
      $group = {};
      $group -> {reason} = $reason;

      my $exact;
      if (    $reason eq 'exact-name-variation-match' 
           or $reason eq 'exact-person-id-match' 
           or $reason eq 'exact-email-match' 
         ) {
        ###  exact matches must be selected by default
        $group -> {status} = 1;
        $exact = 1;

      } else {
        if ( $reason =~ m/exact/ ) { $exact = 1; }
      }

      $list = $group -> {list}   = [];
      $reasons -> {$reason} = $group;
      if ( $exact ) {
        ### add to the head of the list
        unshift @$result, $group;
      } else {
        ### add to the tail of the list
        push @$result, $group;
      }

    } else {
      $list = $reasons->{$reason} ->{list};
    }

    push @$list, $item;
    $already_suggested -> {$id} = $reason;

  } continue {
    $r -> next;
  }



  debug "load_suggestions_into_contributions: exit";

  $suggest = $result;   ### XX ideally, we would merge the sets
  $contributions -> {suggest} = $suggest;
  $contributions -> {'already-suggested'} = $already_suggested;

  return $result;
}




sub clear_from_autosearch_suggestions {
  my $app  = shift;
  my $psid = shift;
  my $shortid_hash = shift;

  debug "clear_from_autosearch_suggestions: enter";

  my $sql = $app -> sql_object;

  my @ids = keys %$shortid_hash;
  my $ids = scalar @ids;
  my $or  = "osid=? or " x ( $ids-1 );
  if ( $ids ) {
    $or .='osid=?';
  }
  
  if ( $or ) {
    my $query = "delete from $back_table where psid=? and ($or)";
    $sql -> prepare ( $query );
    debug "query: $query";
    my $r = $sql -> execute ( $psid, @ids );
    warn if $sql->error;
    debug "error" 
      if $sql->error;
  }

  debug "clear_from_autosearch_suggestions: finished";
}








__END__ 

####  Everything below this point is not used now.  But it could, potentially.

################################################################################
################################################################################
################################################################################
################################################################################
################################################################################

################################################################################
################################################################################
###########                                                        #############
###########                       P O D V A L                      #############
###########                                                        #############
################################################################################
################################################################################

################################################################################
################################################################################
################################################################################
################################################################################


  ### Build a list of glimpse search expressions
  { 
    my @glimpse_exp;

    my %res = ();
    foreach ( @namelist ) {
      my $item = $_;
      $item =~ s/\b\w(?:\W*)\b//g;
      $item =~ s/[^\w\-\'\s]//g; # security ensure

      use Unicode::Normalize;
      $item = NFD( $item );
      $item =~ s/\pM//g; ### strip combining characters

      my @words = split /\s+/, $item;
      $item = join ';', sort @words;
      $res{ $item } = 1;
    }
    @glimpse_exp = sort { length( $b ) <=> length( $a ) } keys %res;

    debug "Glimpse search expressions: ", join( "\n", @glimpse_exp );

    $autosearch -> {'glimpse-expressions'} = \@glimpse_exp;
  }

###########                                                        #############
###########                       P O D V A L                      #############
###########                                                        #############

sub back_search_for_resources {
  my $app = shift;

  logit "back_search_for_resources: enter";


  my $sql = $app -> sql_object;

  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};

  my $metadata_db = $app -> config( 'metadata-db-name' );

  my $conf = get_configuration( $app );


  my $contributions   = $session ->{$id} {contributions} ;

  my $current_index   = $contributions -> {'already-accepted'};
  my $already_refused = $contributions -> {'already-refused' };


  my $ignore_index = {};
  foreach ( keys( %$current_index ), keys %$already_refused ) {
    $ignore_index ->{$_} = 1;
  }

  logit scalar( keys %$ignore_index ), " items in ignore list";

  
  my $autosearch  = $contributions -> {autosearch};
  my $namelist    = $autosearch -> {'names-list'};
  my @namelist    = @$namelist;
  my $glimpse_exp = $autosearch -> {'glimpse-expressions'};
  my @glimpse_exp = @$glimpse_exp;


  my %found_ids = ();

  my $context = {
    db      => $metadata_db,
    found   => \%found_ids,
    already => $ignore_index,
  };


  ###  search for exact matches

  foreach ( @namelist ) {
    my $search = search_resources_for_exact_name( $sql, $context, $_ );

    my $found = ( defined $search ) ? scalar @$search : 'nothing' ;
    logit "exact name: '$_', found: $found";

    if ( scalar @$search ) {
      save_suggestions( $sql, $context, 'exact-name-variation-match', 'author', $search );
    }
  }

  
  ###  search for approximate matches

  foreach my $err ( 1, 2 ) {
    foreach ( @glimpse_exp ) {

      ### next line will skip an expression if it is short and error treshold
      ### is high
      if ( ( length( $_ ) < 6 ) and $err == 2 ) { next; } ### XX?

      my $list = ACIS::Web::Contributions::Glimpse::search( $app, $context, $_, $err );
      
      my $found = ( defined $list ) ? ( scalar @$list ) : 'nothing';
      logit "glimpse expr: '$_', found: $found";

      if ( $list ) {
        save_suggestions( $sql, $context, "approximate-$err", 'author', $list );
      }
    }
  }



###########                                                        #############
###########                       P O D V A L                      #############
###########                                                        #############




