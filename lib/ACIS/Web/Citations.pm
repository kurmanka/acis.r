package ACIS::Web::Citations;

use strict;
use warnings;
use Carp::Assert;

use Web::App::Common;

use ACIS::Citations::Utils;
use ACIS::Citations::Suggestions qw( suggest_citation_to_coauthors );
use ACIS::Citations::SimMatrix;
use ACIS::Citations::Search;

use constant USELESS_SIMILARITY => 30; # XXX this should be higher, I guess

my $acis;
my $sql;

sub prepare() {
  $acis = $ACIS::Web::ACIS;
  $sql  = $acis -> sql_object;
}

sub acis_citations_enabled() {
  prepare() if not $acis;
  return $acis->config( 'citations-profile' );
}


sub prepare_citations_list($) {
  # prepare new citations list
  my $srclist = shift;
  my $list = []; 
  my $index = {};
  foreach ( @$srclist ) {
    if ( $_ ->{reason} eq 'similar'      # this condition may be unnecessary
         and $_->{similar} < USELESS_SIMILARITY ) { next; }
    my $cid = $_->{srcdocsid} . '-'. $_->{checksum};
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

sub prepare_potential {
  shift;
  die "citations not enabled system-wide" if not acis_citations_enabled;

  my $dsid = shift || $acis->{request}{subscreen};
  if ( !$dsid ) {
    die "no document sid to show citations for";
    return;
  }

  my $session = $acis -> session;
  my $vars    = $acis -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};

  my $document;
  foreach ( @{ $record->{contributions}{accepted} } ) {
    if ( $_->{sid} eq $dsid ) { 
      $document = $_;
    }    
  }
  
  die "can't find that document: $dsid" if not $document;

  my $mat = $session ->{simmatrix} = load_similarity_matrix( $sid ); # XXX ||=
  my $citations_new = $mat->{new}{$dsid};
  my $citations_old = $mat->{old}{$dsid};

  $vars -> {document} = $document;
  $vars -> {potential_new} = prepare_citations_list $citations_new;
  $vars -> {potential_old} = prepare_citations_list $citations_old;

  # XXX is this the most interesting document?

  # XXX find / prepare previous and next document

  foreach ( qw( citation-document-similarity-preselect-threshold ) ) {
    $acis->variables->{$_} = $acis->config( $_ ) * 100;
  }


#  $citations_new->[1]->{similar} = 80;
#  my $cid = $citations_new->[0]->{srcdocsid} . '-' . $citations_new->[0]->{checksum};
#  $vars->{'preselect-citations'} = [ $cid ];

  return;
  
}




sub process_potential {
  shift;
  die "citations not enabled system-wide" if not acis_citations_enabled;

  my $dsid = shift || $acis->{request}{subscreen} || die;

  my $session = $acis -> session;
  my $vars    = $acis -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};

  my $document;
  foreach ( @{ $record->{contributions}{accepted} } ) {
    if ( $_->{sid} eq $dsid ) { 
      $document = $_;
    }    
  }
  
  die "can't find that document: $dsid" if not $document;

  my $mat = $session ->{simmatrix} ||= load_similarity_matrix( $sid );
#  my $mat = load_similarity_matrix( $sid );
  $mat -> upgrade( $acis, $record );

  my %cids = ();
  my @adds;
  my @refusals;
  
  my $params = $acis->form_input;
  foreach ( keys %$params ) {
    if ( m/add(.+)/ ) { push @adds, $1; }
    if ( m/refuse(.+)/ ) { push @refusals, $1; }
    if ( m/cid(.+)/ ) { $cids{$1} = $params->{"cid$1"}; }
  }
 
  if ( scalar @refusals ) {
    return process_refuse( $acis, $dsid, \%cids, \@adds, \@refusals );
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
    suggest_citation_to_coauthors( $cit, $sid, $dsid );
    $added ++;
  }

  if ( $added ) {
    # XXX show a message
    $acis->message( "added-citations" );
  }


  my $nlist = $mat->{new}{$dsid} || [];
  foreach( keys %cids ) {
    # old citations' cidX parameters are named cidXo,
    # therefore, if we have a digit at the end, it is a new
    # citation.  unless the user used a stale webform
    if ( # m/\d+$/ and 
         not defined $params->{"add$_"} ) {
      my $cid = $cids{$_};
      my $cit; 
      foreach (@$nlist) { my $id = $_->{srcdocsid}."-".$_->{checksum}; if ($id eq $cid) {$cit = $_;} }
      if ( $cit ) {
        $mat -> citation_new_make_old( $dsid, $cit );
      }
    }
  }

  

}




# process_refuse( $acis, $dsid, \%cids, \@adds, \@refusals );
sub process_refuse {
  my $acis = shift;
  my $dsid = shift;
  my $cids = shift;
  my $adds = shift;
  my $refuse = shift;

  my $session = $acis -> session;
  my $vars    = $acis -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};

  my $mat  = $session->{simmatrix};
  my $counter;
  foreach( @$refuse ) {
    my $cid = $cids->{$_};
    debug "refuse citation $cid (for $dsid)";
    if ( not $cid ) { debug "no cid in form data; ignoring citation refuse: $_"; next; }

    # identify a citation
    my $list = ($mat->{citations}{$cid}) ? $mat -> {citations}{$cid}{$dsid} : next;
    my $cit  = ($list and $list->[0]) ? $list->[0][1] : next; 

    $mat -> remove_citation( $cit );
    refuse_citation($record, $cit);
    $counter ++;
  }

  if ( $counter ) {
    # XXX show a message
    $acis->message( "refused-citations" );
  }
  
  my $params = $acis->form_input;
  my $preselect = [];
  foreach( keys %$cids ) {
    if ( defined $params->{"add$_"} ) {
      my $cid = $$cids{$_};
      push @$preselect, $cid;
    }
  }
  $vars->{'preselect-citations'} = $preselect; 
  

}


sub prepare_identified {
  shift;
  die "citations not enabled system-wide" if not acis_citations_enabled;

  my $dsid = shift || $acis->{request}{subscreen};
  if ( !$dsid ) {
    die "no document sid to show citations for";
    return;
  }

  my $session = $acis -> session;
  my $vars    = $acis -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};

  my $document;
  foreach ( @{ $record->{contributions}{accepted} } ) {
    if ( $_->{sid} eq $dsid ) { 
      $document = $_;
    }    
  }
  
  die "can't find that document: $dsid" if not $document;

  $vars -> {document} = $document;
  $vars -> {identified} = $record->{citations}{identified}{$dsid};

  # XXX is this the most interesting document?
  # XXX find / prepare previous and next document

#  $acis -> dump_presenter_xml;
#  undef $acis->{presenter};
  return;
}



1;
