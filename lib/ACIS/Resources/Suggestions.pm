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

use Storable qw(nfreeze thaw);
use Web::App::Common;
use ACIS::Web::Background qw(logit);
use Data::Dumper;
use Carp;

my $MAX_SUGGESTIONS_LIMIT = 1000;

sub save_suggestions {
  my $sql     = shift || die;
  my $psid    = shift || die;
  my $reason  = shift || die;
  my $role    = shift;
  my $doclist = shift || return 0;

  debug "save_suggestions(): start";
  if ( not scalar @$doclist ) { return 0; }
  debug "reason: $reason";
  debug "items: ", scalar @$doclist;

  my $complained;
  my @replace;

  # change for cardiff: added ? at the end
  $sql -> prepare_cached ( "replace into rp_suggestions values (?,?,?,'$reason',now(),?)" );
  # end change for cardiff: added ? at the end
  foreach ( @$doclist ) {
    my $dsid = $_->{sid} || next;
    my $ro   = $_->{role} || $role;
    # change for cardiff: added relevance
    my $relevance   = $_->{relevance} || '';
    my $r = $sql -> execute( $psid, $dsid, $ro, $relevance );
    # end of change for cardiff: added relevance
    my $r = $sql -> execute( $psid, $dsid, $ro );
    if ( $sql -> error
         and not $complained ) {
      logit Carp::longmess( "save_suggestions(): ". $sql->error );
      $complained = 1;
    }
  }
  debug "save_suggestions(): end";
}
  

sub set_suggestions_reason {
  my $sql    = shift;
  my $psid   = shift;
  my $reason = shift;
  my $dsid_list = shift;
  if ( scalar @$dsid_list ) {
    $sql -> prepare_cached( 
     "UPDATE rp_suggestions SET reason='$reason',time=NOW() WHERE psid='$psid' AND dsid=?" );
    foreach ( @$dsid_list ) {
      my $r = $sql -> execute( $_ );
    }
  }
}
  


sub run_load_suggestions_query {
  my $app    = shift;
  my $psid   = shift;
  debug "run_load_suggestions_query: enter";
  my $sql = $app ->sql_object;
  my $db  = $app ->config("metadata-db-name") || die;
  # cardiff change: adding sug.relevance, and order by it (see end) 
  my $q = 
  qq!select sug.dsid,sug.reason,sug.role,sug.relevance,lib.data from rp_suggestions sug
    join $db.resources as lookup on sug.dsid=lookup.sid
    join $db.objects as lib using (id)
    where sug.psid=?
    order by sug.relevance DESC!;
  # end of cardiff change: adding sug.relevance, and order by it (see end) 
  $sql -> prepare( $q );
  my $r = $sql -> execute( $psid );
  if ( not $r or $sql->error ) {
    complain $sql->error;
  }
  return $r;
}

sub load_suggestions {
  my $app    = shift;
  my $psid   = shift; # personal short-id
  debug "load_suggestions: enter";

  my $result = []; # a list of suggest. groups
  my $group;  # suggestions are grouped by reason
  my $reasons = {};
  my $list;   # temporary pointer

  my $r = run_load_suggestions_query($app,$psid);
  my $count = 0;
  while ( $r->{row} ) {
    my $data = $r->{row}{data} || next;
    my $reason = $r->{row}{reason};
    my $item = thaw( $data ) || next;
    # cardiff change: adding relevance of the item
    if($r->{'row'}->{'relevance'}) {
      $item->{'relevance'}=$r->{'row'}->{'relevance'};
    }
    # end of cardiff change: adding relevance of the item
    $count++;

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
  my $app  = shift;
  my $psid = shift;    ## person short id
  my $contributions = shift; ## the contributions structure

  debug "load_suggestions_into_contributions: enter";
  debug "short id: $psid";

  my $sql = $app -> sql_object;
  # a sanity check for over-enthusiastic suggestions
  {
    $sql -> prepare( "select count(*) as num from rp_suggestions where psid=?" );
    my $r = $sql -> execute( $psid );
    if ( $r and $r->{row} and $r->{row}{num} and $r->{row}{num} > $MAX_SUGGESTIONS_LIMIT ) {
      debug sprintf "too many suggestions for this record: %d; will clean up the inexact ones", $r->{row}{num};
      $sql->do( "delete from rp_suggestions where psid=? and substr(reason,1,6)<>'exact-'", undef, $psid );      
    }
  }

  my $accepted         = $contributions -> {accepted};
  my $already_accepted = $contributions -> {'already-accepted'}; 
  my $already_refused  = $contributions -> {'already-refused' }; 
  my $already_suggested= $contributions -> {'already-suggested' } ||= {}; 
  my $result = [];

  my $r = run_load_suggestions_query($app, $psid);
  my $counter = 0;
  my $reasons = {};
  my $group;  ### suggestions are grouped by reason (and role)
  my $list ;

  while ( $r and $r -> {row} ) {
    if ( $counter++ > $MAX_SUGGESTIONS_LIMIT ) {
      # just in case the above check & clean-up didn't work or didn't help
      debug "enough suggestions: $counter";
      last;
    }
    my $row    = $r->{row};
    my $reason = $row ->{reason};
    my $data   = $row ->{data};
    my $dsid   = $row ->{dsid};
    # cardiff change: adding relevance 
    my $relevance = $row -> {relevance};
    # end cardiff change: adding relevance 

    if ( not defined $dsid ) { warn "No dsid in a resource suggestion record!"; next; }

    if   ( $already_accepted ->{$dsid} ) { next; }
    elsif ( $already_refused ->{$dsid} ) { next; }

    my $item = thaw( $data ) or next;
    $item ->{role} ||= $row ->{role};

    # cardiff change: adding relevance
    if($relevance) {
      $item->{'relevance'}=$relevance;
    }
    # end cardiff change: adding relevance

    my $status;  # should the item be preselected for the user or not?
    if ( $reason =~ s/\-s(\d)$//g ) {  # the reason might specify this
      $status = $1;
      $item -> {status} = $status;
    }
    
    if ( not $reasons -> {$reason} ) {
      $group = {};
      $group ->{reason} = $reason;

      my $exact;
      if (    $reason eq 'exact-name-variation-match' 
           or $reason eq 'exact-person-id-match' 
           or $reason eq 'exact-email-match' 
         ) {
        # exact matches should be selected by default (this could also be done at the XSLT level)
        $group -> {status} = 1;
        $exact = 1;
      } elsif ( $reason =~ m/exact/ ) { $exact = 1; }

      $list = $group -> {list} = [];
      $reasons -> {$reason} = $group;
      if ( $exact ) {
        # add to the head of the list
        unshift @$result, $group;
      } else {
        # add to the tail of the list
        push @$result, $group;
      }

    } else {
      $list = $reasons->{$reason} ->{list};
    }

    push @$list, $item;
    $already_suggested -> {$dsid} = $reason;

  } continue {
    $r -> next;
  }
  debug "$counter items";
  debug "load_suggestions_into_contributions: exit";
  $contributions -> {suggest} = $result; # we are overwriting what was there, but that should be ok
  return $result;
}


sub clear_from_autosearch_suggestions {
  my $app  = shift;
  my $psid = shift;
  my $dsid_hash = shift;

  debug "clear_from_autosearch_suggestions: enter";
  my $sql = $app -> sql_object;
  my @dsids = keys %$dsid_hash;
  my $ids = scalar @dsids || return;
  my $or  = "dsid=? or " x ( $ids-1 ) . 'dsid=?';
  $sql -> prepare ( "delete from rp_suggestions where psid=? and ($or)" );
  my $r = $sql -> execute ( $psid, @dsids );
  warn if $sql->error;
  debug "sql error: " . $sql->error 
    if $sql->error;
  debug "clear_from_autosearch_suggestions: finished";
}




1;

