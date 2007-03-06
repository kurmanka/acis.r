package ACIS::Resources::Suggestions;

use strict;
use warnings;

use Carp::Assert;
use Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw( 
              save_suggestions
              set_suggestions_reason
              load_suggestions
              load_suggestions_into_contributions
              clear_from_autosearch_suggestions
);

use Storable qw(freeze thaw);
use Web::App::Common;
use ACIS::Web::Background qw(logit);
use Data::Dumper;
use Carp;

my $sug_table_name = 'suggestions';
my $MAX_SUGGESTIONS_LIMIT = 1000;

sub save_suggestions {
  my $sql     = shift || die;
  my $context = shift || die;
  my $reason  = shift || die;
  my $role    = shift;

  debug "save_suggestions(): start";
  my $doclist = shift || return 0;
  if ( not scalar @$doclist ) { return 0; }
  debug "reason: $reason";
  debug "items: ", scalar @$doclist;

  my $psid   = $context -> {sid} || die;
  my $already_suggested = $context -> {already_suggested} || die;
  my $target = 'contributions';
  my $complained;
  my @replace;

  $sql -> prepare_cached ( "insert into $sug_table_name values ( ?, ?, ?, " . 
                             " ?, '$reason', '$target', now(), ? )" );
  foreach ( @$doclist ) {
    my $osid = $_ -> {sid};
    warn( "document item with no sid: " . Dumper($_) ) if not $osid;
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
    $sql -> prepare_cached( "replace into $sug_table_name values( ?, ?, ?, ".
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
  debug "save_suggestions(): end";
}
  

sub set_suggestions_reason {
  my $sql    = shift;
  my $psid   = shift;
  my $reason = shift;
  my $rsid_list = shift;

  my $target = 'contributions';
  
  if ( scalar @$rsid_list ) {
    $sql -> prepare_cached( "UPDATE $sug_table_name SET reason='$reason', " .
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
  my $target = shift || 'contributions'; ## load suggestions for what? 
  debug "load_suggestions: enter";

  my $result = []; # a list of suggest. groups
  my $reasons = {};
  my $group;  # suggestions are grouped by reason
  my $list;
  my $sql = $app -> sql_object;
  my $query = "select * from $sug_table_name where psid=?";

  if ( $target ) { 
    $query .= " and target=?";
  }
  $query .= " order by time ASC";

  $sql -> prepare ( $query ) ;
  my $r;
  if ( $target ) { 
    $r = $sql -> execute ( $sid, $target );
  } else {
    $r = $sql -> execute ( $sid );
  }

  my $count = 0;
  while ( $r -> {row} ) {
    $count++;
    my $row    = $r -> {row};
    my $item;
    my $reason = $row ->{reason};
    my $data   = $row ->{data};
    my $id     = $row ->{osid} || die;

    if ( $data ) {
      $item = thaw( $data );
    }

    if ( not $reasons -> {$reason} ) {
      # create a new group for this reason:
      $group = {};
      $group -> {reason} = $reason;
      $group -> {list}   = [];
      $reasons -> {$reason} = $group;
      push @$result, $group;
    } 

    $list = $reasons->{$reason} {list} || die;
    push @$list, $item;
  } continue {
    $r -> next;
  }

  debug "$count rows";
  debug "load_suggestions: exit";
  return $result;
}


sub load_suggestions_into_contributions {
  my $app = shift;
  my $sid = shift;    ## person short id
  my $contributions = shift; ## the contributions structure

  debug "load_suggestions_into_contributions: enter";
  debug "short id: $sid";

  my $sql = $app -> sql_object;
  # a sanity check for over-enthusiastic suggestions
  {
    $sql -> prepare ( "select count(*) as num from $sug_table_name where psid=? and target='contributions'" );
    my $r = $sql -> execute ( $sid );
    if ( $r and $r->{row} and $r->{row}{num} and $r->{row}{num} > $MAX_SUGGESTIONS_LIMIT ) {
      debug sprintf "too many suggestions for this record: %d; will clean up the inexact ones", $r->{row}{num};
      $sql->do( "delete from $sug_table_name where psid=? and target='contributions' and substr(reason,1,6)<>'exact-'" );      
    }
  }

  my $accepted         = $contributions -> {accepted};
  my $already_accepted = $contributions -> {'already-accepted'}; 
  my $already_refused  = $contributions -> {'already-refused' }; 
  my $already_suggested= $contributions -> {'already-suggested' } ||= {}; 
  my $result = [];

  my $query = "select * from $sug_table_name where psid=? and target='contributions' order by time ASC";
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
    my $row = $r -> {row};
    my $item;
    my $reason = $row ->{reason};
    my $data   = $row ->{data};
    my $id     = $row ->{osid};
    if ( not defined $id ) { warn "No id in a resource suggestion record!"; next; }

    if   ( $already_accepted ->{$id} ) { next; }
    elsif ( $already_refused ->{$id} ) { next; }

    if ( $data ) { $item = thaw( $data ); }
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
  debug "$counter items";

  debug "load_suggestions_into_contributions: exit";
  $contributions -> {suggest} = $result;   # XX ideally, we should merge it with what is there already
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
    my $query = "delete from $sug_table_name where psid=? and ($or)";
    $sql -> prepare ( $query );
    debug "query: $query";
    my $r = $sql -> execute ( $psid, @ids );
    warn if $sql->error;
    debug "error" 
      if $sql->error;
  }

  debug "clear_from_autosearch_suggestions: finished";
}




1;

