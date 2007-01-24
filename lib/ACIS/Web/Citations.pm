package ACIS::Web::Citations;

use strict;
use warnings;
use Carp qw( confess );
use Carp::Assert;

use Web::App::Common;

use ACIS::Citations::Utils;
use ACIS::Citations::Suggestions qw( store_cit_sug add_cit_old_sug );
use ACIS::Citations::SimMatrix;
use ACIS::Citations::Search;


my $acis;
my $sql;
my $session;
my $vars;
my $id;
my $sid;
my $record;
my $params;
my $document;
my $dsid;
my $citations;
my $research_accepted;
my $mat;

sub get_doc_by_sid ($) {
  my $dsid = $_[0] || return undef;
  foreach ( @{ $research_accepted } ) {
    if ( $_->{sid} eq $dsid ) { 
      return $_;
    }    
  }
  return undef;
}


sub prepare() {
  $acis = $ACIS::Web::ACIS;

  die "citations not enabled system-wide" 
    if not $acis->config( 'citations-profile' ) and not $acis->session->owner->{type}{citations};

  $sql  = $acis -> sql_object;

  $session = $acis -> session;
  $vars    = $acis -> variables;
  $record  = $session -> current_record;
  $id      = $record ->{id};
  $sid     = $record ->{sid};

  $params = $acis->form_input;

  $citations         = $record ->{citations} ||= {};
  $research_accepted = $record ->{contributions}{accepted} || [];
  if ( scalar @$research_accepted == 0 ) { $vars->{'empty-research-profile'} = 1; }

#  $mat = $session ->{simmatrix} ||= load_similarity_matrix( $record ); # XXX
#  $mat = $session ->{simmatrix}   = load_similarity_matrix( $record ); 
  $mat && $mat -> upgrade( $acis, $record );

  $dsid = $params->{dsid} || $acis->{request}{subscreen};
  if ( $dsid ) {
    $document = get_doc_by_sid $dsid;
  }

  # the following if causes ~2k leak per execution (on ik@ahinea.com account)
  if (0 and not $session -> {$id} {'citations-checked-and-cleaned'} ) {
    require ACIS::Citations::Profile;
    ACIS::Citations::Profile::profile_check_and_cleanup();
    $session -> {$id} {'citations-checked-and-cleaned'} = 1;
  }

#  delete $mat ->{new};
#  delete $mat ->{old};
#  delete $mat ->{citations};
#XXXXX
#  use ACIS::Debug::MLeakDetect;
#  print my_vars_report;
}


sub prepare_citations_list($) {
  # prepare new citations list
  my $srclist = shift;
  my $list = []; 
  my $index = {};
  my $minsim = min_useful_similarity;
  foreach ( @$srclist ) {
    if ( $_ ->{reason} eq 'similar'      # this condition may be unnecessary
         and $_->{similar} < $minsim ) { next; }
    my $cid = cid $_;
    if ( $index->{$cid} ) {
      $index->{$cid}{similar} += $_->{similar};
    } else {
      my $cit = { %$_ };
      push @$list, $cit;
      $index->{$cid} = $cit;
    }
  }
  @$list = sort { $b->{similar} <=> $a->{similar} } @$list;
  return $list;
}

sub count_significant_potential ($) {
  my $list = $_[0];
  my $count = 0;
  my $index = {};
  my $minsim = min_useful_similarity;
  foreach ( @$list ) {
    if ( $_ ->{reason} eq 'similar'      # this condition may be unnecessary
         and $_->{similar} < $minsim ) { next; }
    my $cid = cid $_;
    next if $index->{$cid};
    $index ->{$cid} = 1;
    $count++;
  }
  return $count;
}



sub prepare_potential {
  return if not $dsid;
#  die "no document sid to show citations for" if not $dsid;
  die "can't find that document: $dsid" if not $document;

  debug "prepare_potential()";
  my $citations_new = $mat->{new}{$dsid};
  my $citations_old = $mat->{old}{$dsid};

  $vars -> {document} = $document;
  $vars -> {potential_new} = prepare_citations_list $citations_new;
  $vars -> {potential_old} = prepare_citations_list $citations_old;

  prepare_prev_next();

  foreach ( qw( citation-document-similarity-preselect-threshold ) ) {
    $acis->variables->{$_} = $acis->config( $_ ) * 100;
  }

}




sub process_potential {
  shift;
  die "no document sid to process citations for" if not $dsid;
  die "can't find that document: $dsid" if not $document;

  my %cids = ();
  my @adds;
  my @refusals;
  
  foreach ( keys %$params ) {
    if ( m/add(.+)/ ) { push @adds, $1; }
    if ( m/refuse(.+)/ ) { push @refusals, $1; }
    if ( m/cid(.+)/ ) { $cids{$1} = $params->{"cid$1"}; }
  }
 
  if ( scalar @refusals ) {
    return process_refuse( \%cids, \@adds, \@refusals );
  }

  my $added = 0;
  foreach ( @adds ) {
    my $cid = $cids{$_};
    debug "add citation $cid to $dsid";
    if ( not $cid ) { debug "no cid in form data; ignoring citation add: $_"; next; }

    # identify a citation
    my $list = ($mat->{citations}{$cid}) ? $mat -> {citations}{$cid}{$dsid} : next;
    my $cit  = ($list and $list->[0]) ? $list->[0][1] : next; 

    $mat -> remove_citation( $cit );
    identify_citation_to_doc($record, $dsid, $cit);
    store_cit_sug( $cit->{citid}, $dsid, "coauth:$sid" );
    add_cit_old_sug( $sid, $dsid, $cit->{citid} );
    $added ++;
  }

  if ( $added > 1 ) {     $acis->message( "added-citations" ); }
  elsif ( $added == 1 ) { $acis->message( "added-citation"  ); }


  my $nlist = $mat->{new}{$dsid} || [];
  foreach( keys %cids ) {
    # old citations' cidX parameters are named cidXo,
    # therefore, if we have a digit at the end, it is a new
    # citation.  unless the user used a stale webform
    if ( # m/\d+$/ and 
         not defined $params->{"add$_"} ) {
      my $cid = $cids{$_};
      my $cit; 
      foreach (@$nlist) { my $id = cid $_; if ($id eq $cid) {$cit = $_;last;} }
      if ( $cit ) {
        $mat -> citation_new_make_old( $dsid, $cit );
      }
    }
  }


  my $autosug = $acis->{request}{screen} eq 'citations/autosug';
  if ( $params->{moveon} ) {
    if ( $autosug ) {
    } else {
      $acis->redirect_to_screen( 'citations/autosug' );
    }
  } 
}




# process_refuse( \%cids, \@adds, \@refusals );
sub process_refuse {
  my $cids = shift;
  my $adds = shift;
  my $refuse = shift;

  my $counter = 0;
  foreach( @$refuse ) {
    my $cid = $cids->{$_};
    debug "refuse citation $cid (for $dsid)";
    if ( not $cid ) { debug "no cid in form data; ignoring citation refuse: $_"; next; }

    # identify a citation
    my $list = ($mat->{citations}{$cid}) ? $mat -> {citations}{$cid}{$dsid} : next;
    my $cit  = ($list and $list->[0]) ? $list->[0][1] : next; 

    $mat -> remove_citation( $cit );
    refuse_citation($record, $cit);
    add_cit_old_sug($sid, $dsid, $cit->{citid});
    $counter ++;
  }

  if ( $counter > 1 ) {     $acis->message( "refused-citations" ); } 
  elsif ( $counter == 1 ) { $acis->message( "refused-citation"  ); }
  
  my $preselect = [];
  foreach( keys %$cids ) {
    if ( defined $params->{"add$_"} ) {
      my $cid = $cids->{$_};
      push @$preselect, $cid;
    }
  }
  $vars->{'preselect-citations'} = $preselect; 
}


sub prepare_identified {
  die "no document sid to show citations for" if not $dsid;
  die "can't find that document: $dsid" if not $document;

  $vars -> {document}   = $document;
  $vars -> {identified} = $citations->{identified}{$dsid};

  prepare_prev_next();
}


use Carp::Assert;

sub process_identified {
  die "no document sid to show citations for" if not $dsid;
  die "can't find that document: $dsid" if not $document;
  
  my %cids;
  my @delete = ();

  foreach ( keys %$params ) {
    if ( m/del(.+)/ ) { push @delete, $1; }
    if ( m/cid(.+)/ ) { $cids{$1} = $params->{"cid$1"}; }
  }

  my @citations;
  foreach ( @delete ) {
    my $cid = $cids{$_};
    my $cit = unidentify_citation_from_doc_by_cid( $record, $dsid, $cid );

    assert( $cit->{ostring} );
    $cit->{nstring} = make_citation_nstring $cit->{ostring};
    assert( $cit->{nstring} );
    assert( $cit->{srcdocsid} );
    add_cit_old_sug( $sid, $dsid, $cit->{citid} );
    if ( $cit ) {
      warn("gone!"), delete $cit->{gone} if $cit->{gone};
      push @citations, $cit;
    }
  }
  $mat -> consider_new_citations( \@citations );

  if ( scalar @citations > 1 )  {    $acis -> message( "deleted-citations" ); }
  elsif ( scalar @citations == 1 ) { $acis -> message( "deleted-citation"  ); }
}



sub prepare_doclist {

  my $sort = $acis -> {request}{subscreen} || 'by-new';

  my $docsidlist = $mat->{doclist};
  my $doclist = $vars ->{doclist} = [];
  my $ind = {};
  foreach ( @$docsidlist ) {
    my $d = get_doc_by_sid $_;
    confess "document not found: $_" if not $d;
    my $new = prepare_citations_list $mat->{new}{$_};
    my $old = prepare_citations_list $mat->{old}{$_};
    my $id  = $citations->{identified}{$_} || [];
    my $simtotal = $mat->{totals_new}{$_};
    
    push @$doclist, { doc => $d, 
                      new => scalar @$new, 
                      old => scalar @$old, 
                      id  => scalar @$id,
                      similarity => $simtotal };
    $ind->{$_} = 1;
  }

  my @tmp;
  foreach ( @$research_accepted ) {
    my $d   = $_;
    my $dsid = $_->{sid};
    next if $ind->{$dsid};

    my $id  = $citations->{identified}{$dsid} || [];
    my $old = prepare_citations_list $mat->{old}{$dsid};
    push @tmp, { doc => $d, 
                 old => scalar @$old, 
                 id  => scalar @$id,
               };
  }
  @tmp = sort { $b->{id} <=> $a->{id} 
                or $b->{old} <=> $a->{old} } @tmp;
  push @$doclist, @tmp;
  
  if ( $sort eq 'by-id' ) {
    @$doclist = sort { $b->{id} <=> $a->{id} } @$doclist;
  }

  my $identified_num = 0;
  foreach (@$doclist) {
    $identified_num += $_->{id};
  }
  $vars ->{'identified-number'} = $identified_num;
  $vars ->{'potential-new-number'} = $mat->number_of_new_potential;  
}

sub prepare_autosug {

  if ( $dsid and $params->{moveon} 
       or not $dsid ) {
    my $docsidlist = $mat->{doclist};
    $dsid = $docsidlist->[0];
    if ( $dsid ) {
      $document = get_doc_by_sid $dsid;
    }
  }
  
  if ( $document ) {
    prepare_potential();
  } else {
    $vars->{'most-interesting-doc'} = 't';
  }

  debug "not the most interesting!" if not $vars->{'most-interesting-doc'};
}

sub process_autosug {
  process_potential;
}

sub prepare_overview {

  # redirect to autosug on the first visit, if there are interesting docs to see
  if ( not $session ->{citations_first_screen} ) {
    $session->{citations_first_screen} = 1;
    
    my $docsidlist = $mat->{doclist};
    my $_dsid = $docsidlist->[0];
    if ( $_dsid ) {
      $document = get_doc_by_sid $_dsid;
    }
    if ( $document ) {
      $acis->redirect_to_screen( 'citations/autosug' );
      return;
    }
  }

  prepare_doclist;
  my $ref = $citations->{refused} ||=[];  
  $vars ->{'refused-number'} = scalar @$ref;
  
  # leave only interesting documents, clear the rest
  my $doclist = $vars->{doclist};
  foreach ( @$doclist ) {
    if ( $_->{new} or $_->{old} or $_->{id} ) { next; }
    undef $_;
  }
  clear_undefined $doclist;
}


sub prepare_refused {
  $vars ->{refused} = $citations->{refused} ||=[];
}

sub process_refused {
  my %cids;
  my @delete = ();

  foreach ( keys %$params ) {
    if ( m/del(.+)/ ) { push @delete, $1; }
    if ( m/cid(.+)/ ) { $cids{$1} = $params->{"cid$1"}; }
  }

  my @citations;
  foreach ( @delete ) {
    my $cid = $cids{$_};
    my $cit = unrefuse_citation_by_cid( $record, $cid );

    assert( $cit->{ostring} );
    $cit->{nstring} = make_citation_nstring $cit->{ostring}
      if not $cit->{nstring};
    assert( $cit->{nstring} );
    assert( $cit->{srcdocsid} );
    if ( $cit ) {
      warn("gone!"), delete $cit->{gone} if $cit->{gone};
      push @citations, $cit;
    }
  }
  $mat -> consider_new_citations( \@citations );

  if ( scalar @citations > 1 )  {    $acis -> message( "unrefused-citations" ); }
  elsif ( scalar @citations == 1 ) { $acis -> message( "unrefused-citation" );  }

}


sub prepare_prev_next {
  die "no document sid to show citations for" if not $dsid;
  die "can't find that document: $dsid" if not $document;

  debug "prepare_prev_next()";

  my $docsidlist = $mat->{doclist};
  my $prev;
  my $next;
  my $found;
  foreach ( @$docsidlist ) {
    if ( $found ) {
      $next = $_;
      last;
    }
    if ( $_ eq $dsid ) {
      $vars->{previous} = $prev  if $prev;
      $found = 1;
    }
    $prev = $_;
  }
    
  $vars ->{next} = $next  if $next;

  if ( $found and not $vars->{previous} ) {
    $vars->{'most-interesting-doc'} = 't';
    debug "most interesting doc";
  }

  if ( scalar @$docsidlist ) {
    $vars->{'anything-interesting'} = 't';
  }
}

sub prepare_research_identified {
  my $rc = {}; # reseach citations
  my $ci = $citations->{identified};
  my $ri = $vars->{contributions}{accepted};
  foreach ( @$ri ) {
    my $dsid = $_->{sid};
    next if not $dsid;
    if ( $ci->{$dsid} ) {
      $rc->{identified}{$dsid} = scalar @{ $ci->{$dsid} };
    }
    my $pot = count_significant_potential $mat->{new}{$dsid};
    if ( $pot ) {
      $rc->{potential}{$dsid} = $pot;
    }
  }
  if ( scalar keys %$rc ) {
    $vars -> {contributions}{citations} = $rc;
  }
}

sub process_autoupdate {
  my $acis = shift;
  $acis-> message( "saved-citations-autoupdate-pref" );
}

1;
