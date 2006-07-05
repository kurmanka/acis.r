package ACIS::Citations::SimMatrix;

use strict;
use warnings;

use Carp::Assert;

##  cit_suggestions table fields:
#
#     * citation origin doc sid: srcdocsid CHAR(15) NOT NULL
#     * citation checksum: checksum CHAR(22) NOT NULL
#     * personal sid, short: psid CHAR(15) NOT NULL
#     * document sid, short: dsid CHAR(15) NOT NULL
#     * reason: ‘similar’ | ‘pre-identified’, ‘co-author:pau432’: reason CHAR(20) NOT NULL
#     * similarity: similar TINYINT UNSIGNED (from 0 to 100 inclusive)
#     * new: yes | no new BOOL
#     * original citation string: ostring TEXT NOT NULL
#     * origin doc details (URL): srcdocdetails BLOB
#     * suggestion’s creation/update date: time DATE NOT NULL
#
# PRIMARY KEY (srcdocsid, checksum, psid, dsid, reason),
# INDEX( psid ), INDEX( dsid )


#  load_similarity_matrix( psid );
#  get_most_interesting_document( psid );

use Exporter;
use base qw( Exporter );
use vars qw( @EXPORT_OK );
@EXPORT_OK = qw( load_similarity_matrix );


use ACIS::Citations::Suggestions qw( load_suggestions );
use Web::App::Common;

sub load_similarity_matrix($) {
  my $psid = shift || die;
  
  debug "load_similarity_matrix( '$psid' )";
  my $sug  = load_suggestions( $psid );
  my $mat  = { new => {}, old => {}, psid => $psid, citations=>{} };

  bless $mat;

  foreach ( @$sug ) {
    $mat -> _add_sug( $_ );
  }
  
  $mat -> _calculate_totals;

  return $mat;
}

sub _add_sug {
  my $self = shift || die;
  my $sug  = shift || die;
  
  my $d      = $sug ->{dsid} || die;
  my $newold = ($sug->{new}) ? 'new' : 'old';

  my $known = $self->{citations};

  for ( $self->{$newold}{$d} ) {
    if ( not $_ ) { $_ = []; }
    push @$_, $sug;

    # maintain an index
    my $cid = $sug->{srcdocsid} . '-' . $sug->{checksum};
    my $cindex = $known->{$cid}{$d} ||= [];
    push @$cindex, [ $newold, $sug ];

    # clear redundant bits
    delete $sug->{dsid};
    delete $sug->{psid};
    delete $sug->{new};
  }
}


sub _calculate_totals {
  my $self   = shift;
  my $totals = {};
  
  my $newdoc = $self->{new};
  foreach ( keys %$newdoc ) {
    my $dsid = $_;
    my $total = 0;
    foreach ( @{ $newdoc->{$_} } ) {
      # XXX treat co-author's claims specially
      $total += $_->{similar};
    }
    $totals ->{$dsid} = $total;
  }

  $self->{totals_new} = $totals;
  
  my @doclist = keys %$newdoc;
  @doclist = grep { $totals->{$_}; } @doclist;
  @doclist = sort { $totals->{$b} <=> $totals->{$a} } @doclist;

  $self -> {doclist} = \@doclist;
}

sub most_interesting_doc {
  my $self = shift;
  my $doclist = $self->{doclist};
  if ( $doclist and ref $doclist
       and defined $doclist->[0] ) {

    return $doclist->[0];
  }
  return undef;
}


sub filter_out_known {
  my $self   = shift || die;
  my $list   = shift || die;
  my $reason = shift;

  debug "filter_out_known()";

  my $known = [];
  my $citindex = $self->{citations};

  foreach ( @$list ) {
    my $citation = $_;

    my $cid = $citation->{srcdocsid} . '-' . $citation->{checksum};
    my $found;

    if ( $citindex->{$cid} ) {
      # known 
      if ( $reason ) {
        my $a = $citindex->{$cid};
        foreach ( @$a ) {
          my $_reason = $_->[1]->{reason};
          if ( $reason eq $_reason ) { $found = 1; last; }
        }

      } else { 
        $found = 1; 
      }
    }

    if ( $found ) {
      debug "citation known: $cid";
      push @$known, $_;
      undef $_;
    }

  }

  clear_undefined $list;
  return $known;
}  




sub testme {
  require Data::Dumper;
  require ACIS::Web;
  # home=> '/home/ivan/proj/acis.zet'
  my $acis = ACIS::Web->new(  );
  
  my $psid = 'ptestsid0';
  my $m    = load_similarity_matrix( $psid );
  print Data::Dumper::Dumper( $m );

}

package ACIS::Citations::SimMatrix; # ::Manager 

use strict;
use warnings;
use Carp::Assert;
use ACIS::Citations::Suggestions qw( load_suggestions add_suggestion replace_suggestion store_similarity );
use Web::App::Common;

sub upgrade {
  my $self = shift || die;
  my $acis = shift || die;
  my $rec  = shift || die;

  assert( $acis->{home} and $acis->{screenconf} );
  assert( $rec->{name}  and $rec->{id} );

  $self->{acis} = $acis;
  $self->{rec}  = $rec;
}

sub find_cit {
  my $self   = shift || die;
  my $cit    = shift || die;

  my $known = $self->{citations};
  
  # check the index
  my $cid = $cit->{srcdocsid} . '-' . $cit->{checksum};

  return $known->{$cid};
}

sub find_sugg {
  my $self   = shift || die;
  my $cit    = shift || die;
  my $dsid   = shift || die;
  my $reason = shift || die;

  my $known = $self->{citations};
  
  # check the index
  my $cid = $cit->{srcdocsid} . '-' . $cit->{checksum};

  my $l = $known->{$cid}{$dsid};
  foreach ( @$l ) {
    # $_->[0] new / old
    # $_->[1] suggestion itself
    if ( $_->[1]->{reason} eq $reason ) {
      return @$_;
    }
  }

  return ();
}


sub add_sugg {
  my $self   = shift || die;
  my $cit    = shift || die;
  my $dsid   = shift || die;
  my $reason = shift || die;
  my $sim    = shift;

  my $psid = $self->{psid} || die;
  my $l    = $self->{new} {$dsid} ||= [];

  my $sug = { %$cit, reason => $reason, similar => $sim };
  push @$l, $sug;

  # maintain the index
  my $known = $self->{citations};
  my $cid   = $sug->{srcdocsid} . '-' . $sug->{checksum};
  my $cindex = $known->{$cid}{$dsid} ||= [];
  push @$cindex, [ 'new', $sug ];
  
  add_suggestion( $cit, $psid, $dsid, $reason, $sim );
}

sub set_similarity_unused {
  my $self = shift || die;
  my $cit  = shift || die;
  my $dsid = shift || die;
  my $sim  = shift;
  my $new  = shift;

  my $l = $self->{new} {$dsid} ||= [];
  if ( not $new ) {
    $l = $self->{old} {$dsid} ||= [];
  }
  
  my $found;
  foreach ( @$l ) {
    if ( $_ ->{srcdocsid} eq $cit->{srcdocsid} 
         and $_->{checksum} eq $cit->{checksum} ) {
      $_ ->{similar} = $sim;
      $found = 1;
    }
  }

  if ( not $found ) {
    die "set_similarity(): suggestion was not found";
#    my $sug = { %$cit, reason => "similar", similar => $sim };
#    push @$l, $sug;
  }

  replace_suggestion( $cit, $self->{psid}, $dsid, "similar", $sim, $new );

#  warn "suggestion was not found" if not $found;
}

  

sub compare_citation_to_documents {
  my $self = shift || die;
  my $cit  = shift || die;

  debug "compare_citation_do_documents()";

  my $docs = $self-> {docs};
  if ( not $docs ) {
    ### prepare doc objects, as per Similarity assessment function interface
    $docs = {};
    my $rp = $self->{rec}{contributions}{accepted} || [];
    foreach ( @$rp ) {
      my $sid = $_->{sid} || warn && next;
      my $doc = { %$_ };
      $doc->{authors} = [ split / \& /, $doc->{authors} ];
      if ( not $doc->{location} ) { }  # XXX 
      $docs -> {$sid} = $doc;
    }
  }
  debug "documents: ", join ' ', keys %$docs;

  my $psid = $self->{psid} || die;
  my $acis = $self->{acis} || die;
  my $func = $acis->config( 'citation-document-similarity-func' ) 
    || 'ACIS::Citations::Utils::cit_document_similarity';

  debug "will use similarity function: $func";

  while ( my( $dsid, $doc ) = each %$docs ) {
    no strict 'refs';
    debug "comparing to $dsid (", $doc->{title}, ")";

    my $similarity = &{$func}( $cit, $doc ) * 100.0;
    debug "similarity: $similarity";

#    my $sug = check_suggestions( $cit, $psid, $dsid, 'similar' );
    my ($no, $sug) = $self->find_sugg(  $cit, $dsid, 'similar' );

    if ( $sug ) {
      debug "replacing";
      my $newsug = ( $no eq 'new' ) ? 1 : 0;
      $sug->{similar} = $similarity;
      replace_suggestion( $cit, $psid, $dsid, "similar", $similarity, $newsug );
#      $self->set_similarity( $cit, $dsid, $similarity, $newsug );

    } else {
      debug "adding";
      $self->add_sugg( $cit, $dsid, "similar", $similarity );
    } 
  }

  return 1;
}



sub add_new_citations {
  my $self = shift || die;
  my $list = shift || die;
  my $dsid = shift;
  my $reason = shift;

  my $psid = $self->{psid} || die;
  
  if ( $dsid ) {
    foreach ( @$list ) {
      $self->add_sugg( $_, $dsid, "pre-identified", undef );
    }

  } else {
    ### run comparisons
    foreach ( @$list ) {
      $self->compare_citation_to_documents( $_ );
    }
  }

  $self -> _calculate_totals;

  
}


sub run_maintenance {   # [60 min]
  my $self = shift || die;
}

sub remove_citation {  # [30 min]
  my $self = shift || die;
  my $cit  = shift || die; 

  # 
}


sub test_advanced {
  require ACIS::Citations::Search;
  require ACIS::Web;
  require ACIS::Web::UserData;
  

}


1;