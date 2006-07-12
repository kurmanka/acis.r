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
#     * reason: ‘similar’ | ‘preidentified’, ‘coauth:pau432’: reason CHAR(20) NOT NULL
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

  my $sug = { %$cit, reason => $reason, similar => $sim, time => today() };
  push @$l, $sug;
  delete $sug->{nstring};
  delete $sug->{trgdocid};

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

sub _docs {
  my $self = shift || die;
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
    $self->{docs} = $docs;
  }
  return $docs;
}

sub compare_citation_to_documents {
  my $self = shift || die;
  my $cit  = shift || die;

  debug "compare_citation_do_documents()";

  my $docs = $self -> _docs;
  debug "documents: ", join ' ', keys %$docs;

  my $psid = $self->{psid} || die;
  my $acis = $self->{acis} || die;
  my $func = $acis->config( 'citation-document-similarity-func' ) 
    || 'ACIS::Citations::Utils::cit_document_similarity';

  debug "will use similarity function: $func";

  while ( my( $dsid, $doc ) = each %$docs ) {
    no strict 'refs';
    debug "comparing to $dsid (", $doc->{title}, ")";

    my $similarity = sprintf( '%u', &{$func}( $cit, $doc ) * 100 );
    debug "similarity: $similarity";

#    my $sug = check_suggestions( $cit, $psid, $dsid, 'similar' );
    my ($no, $sug) = $self->find_sugg(  $cit, $dsid, 'similar' );

    if ( $sug ) {
      debug "replacing";
      my $newsug = ( $no eq 'new' ) ? 1 : 0;
      $sug->{similar} = $similarity;
      $sug->{time}    = today();
      replace_suggestion( $cit, $psid, $dsid, "similar", $similarity, $newsug );
#      $self->set_similarity( $cit, $dsid, $similarity, $newsug );

    } else {
      debug "adding";
      $self->add_sugg( $cit, $dsid, "similar", $similarity );
    } 
  }

  return 1;
}

use POSIX qw(strftime);
sub today {
  strftime '%F', localtime( time );
}


sub add_new_citations {
  my $self = shift || die;
  my $list = shift || die;
  my $dsid = shift;
  my $reason = shift;

  my $psid = $self->{psid} || die;
  
  if ( $dsid ) {
    foreach ( @$list ) {
      $self->add_sugg( $_, $dsid, "preidentified", undef );
    }

  } else {
    ### run comparisons
    foreach ( @$list ) {
      $self->compare_citation_to_documents( $_ );
    }
  }

  $self -> _calculate_totals;
  # XX DEBUGGING
  $self->check_consistency;
  
}


sub run_maintenance { 
  my $self = shift || die;

  my $acis = $self->{acis} || die;
  my $rec  = $self->{rec}  || die;
  my $psid = $self->{psid} || die;
  my $sql  = $acis->sql_object() || die;

  my $new  = $self->{new};
  my $old  = $self->{old};

  # should we really run maintenance now?  Maybe we did this
  # just recently? XXX
 
  # check every citation for still being present in the
  # citations table
  $sql -> prepare_cached( "select checksum from citations where srcdocsid=? and checksum=?" );
  my $citations = $self->{citations};
  my @gone = ();
  foreach my $cid ( keys %$citations ) { 
    my ( $sid, $chk ) = split '-', $cid, 2;
    my $r = $sql->execute( $sid, $chk );
    if ( not $r ) { die; }
    if ( not $r->{row} or not $r->{row}{checksum} ) {
      # citation is no longer present, it is gone; it is
      # sad, but we have to keep on
      push @gone, $cid;
      my $docs = $citations->{$cid};
      foreach ( @$docs ) {
        warn "citation's document list is corrupt" if not ref $_;
        my $sug = $_->[1];
        $sug ->{gone} = 1;
      }
      delete $citations->{$cid};

      my $s = $sql->other;
      $s -> do( "delete from cit_suggestions where srcdocsid=? and checksum=?", {}, $sid, $chk );
    }
  }
  debug "citations gone: ", join( ' ', @gone );


  # remove the suggestions for documents, which are no
  # longer in the research profile
  my $docs = $self->_docs;

  foreach my $hash ( $new, $old ) {
    while ( my ( $docsid, $list ) = each %$hash ) {
      if ( not $docs->{$docsid} ) { 
        $sql -> do( "delete from cit_suggestions where dsid=? and psid=?", {}, $docsid, $psid );
        delete $hash->{$docsid}; 
        debug "document gone: ", $docsid;
        next; 
      }

      # also remove those which are gone (see the previous step)
      foreach ( @$list ) {
        if ( $_->{gone} ) { undef $_; }
      }
      clear_undefined $list;
    }
  }

  # clean $self->{citations} also
  foreach my $cid ( keys %$citations ) { 
    my ( $sid, $chk ) = split '-', $cid, 2;
    my $cdocs = $citations->{$cid} || die;
    foreach ( keys %$cdocs ) {
      if ( not $docs->{$_} ) {
        delete $cdocs->{$_};
      }
    }
  }


  # re-run citation/document comparisons
  # for those suggestions which are more then the
  # time-to-live days old, store them in db
  
  # CONDITION: if cit->time is less than now() -
  # citation-document-similarity-ttl days

  use Date::Manip; # qw( DateCalc ParseDate Date_Cmp );
  my $ttl = $acis-> config( 'citation-document-similarity-ttl' ) || die;
  my $bell = Date::Manip::DateCalc( "today", "- $ttl days" ) || die;

  foreach my $hash ( $new, $old ) {
    while ( my ( $docsid, $list ) = each %$hash ) {
      foreach my $sug ( @$list ) {
        my $stime = $sug ->{time} || die;
        next if $stime eq 'today';
        my $sdate = Date::Manip::ParseDate( $stime );
        if ( Date::Manip::Date_Cmp( $sdate, $bell ) < 0 ) {
          # too old
          $self->compare_citation_to_documents( $sug );
          debug "suggestion too old: ", $sug;
        }
      }
    }
  }
  
  # recalculate totals now
  $self -> _calculate_totals();
  # XX DEBUGGING
  $self->check_consistency;

  # record the current date in the profile
  # XXX
}

sub remove_citation { 
  my $self = shift || die;
  my $cit  = shift || die; 

  # 
  my $acis = $self->{acis} || die;
  my $rec  = $self->{rec}  || die;
  my $psid = $self->{psid} || die;
  my $sql  = $acis->sql_object() || die;
  
  my $cid  = $cit->{srcdocsid} . '-' . $cit->{checksum};
  my $dhash = $self->{citations} {$cid};
  return if not $dhash;
  
  delete $self->{citations}{$cid};

  $sql -> do( "delete from cit_suggestions where srcdocsid=? and checksum=?", 
              {}, 
              $cit->{srcdocsid}, $cit->{checksum} );

  while ( my($dsid,$slist) = each %$dhash ) {
    die if not $dsid;
    die if not $slist;
    die if not ref $slist;

    foreach ( @$slist ) {
      next if not $_;
      die  if not ref $_;
      my $no = $_->[0];
      my $su = $_->[1];
      $su ->{gone} = 1;
    }
  }

  my $new = $self->{new};
  my $old = $self->{old};
  
  foreach my $hash ( $new, $old ) {
    while ( my ( $docsid, $list ) = each %$hash ) {
      # remove those which are gone 
      foreach ( @$list ) {
        if ( $_->{gone} ) { undef $_; }
      }
      clear_undefined $list;
    }
  }
  
  # XX DEBUGGING
  $self->_calculate_totals;
  $self->check_consistency;
}


sub citation_new_make_old {
  my $self = shift || die;
  my $dsid = shift || die;
  my $cit  = shift || die;
#  my $par  = shift || die;
#  my $val  = shift || die;

  my $cits = $self->{citations};
  my $new  = $self->{new};
  my $old  = $self->{old};
  
  my $src = $cit->{srcdocsid};
  my $chk = $cit->{checksum};

  my $list = $new->{$dsid} || die;

  foreach ( @$list ) {
    if ( $_->{srcdocsid} eq $src
         and $_->{checksum} eq $chk ) { 
      my $s = $_;
      undef $_; 
      push @{ $old->{$dsid} }, $s;
    }
    clear_undefined $list;
  }

  my $dh = $cits->{"$src-$chk"};
  $list = $dh->{$dsid};
  foreach ( @$list ) {
    $_->[0] = 'old';
  }
  

  my $acis = $self->{acis} || die;
  my $psid = $self->{psid} || die;
  my $sql  = $acis->sql_object() || die;
  $sql -> do( "update cit_suggestions set new=FALSE where psid=? and dsid=? and srcdocsid=? and checksum=?", 
              {}, 
              $psid, $dsid,
              $cit->{srcdocsid}, $cit->{checksum} );

  # XX DEBUGGING
  $self->_calculate_totals;
  $self->check_consistency;
}

sub check_consistency {
  my $self = shift || die;

  my $acis = $self->{acis} || die;
  my $rec  = $self->{rec}  || die;
  my $psid = $self->{psid} || die;
  my $sql  = $acis->sql_object() || die;

  my $old  = $self->{old};
  my $new  = $self->{new};
  my $cits = $self->{citations};
  
  #  $self->_calculate_totals;

  # reload it from the database and see that it produces the
  # same matrix 
  my $copy = load_similarity_matrix( $psid );

  my $str1 = $self->as_string;
  my $str2 = $copy->as_string;

  if ( $str1 eq $str2 ) {
    debug "the matrix is consistent as hell";
    return "OK";
  }
 
  foreach ( qw( new old citations ) ) {
    my $my = $self->{$_};
    my $co = $copy->{$_};
    my $diff = compare_hash_keys( $my, $co );
    if ( $diff ) {
      warn "$_ differs by keys";
    }
  }
  
  use File::Temp;
  my $f1 = File::Temp->new( TEMPLATE=> 'acis_sim_matrix_memory_XXXXX', UNLINK=> 0 );
  print $f1 $str1;
  close $f1;

  my $f2 = File::Temp->new( TEMPLATE=> 'acis_sim_matrix_db_XXXXX', UNLINK=> 0 );
  print $f2 $str2;
  close $f2;

  print "matrices are different; see " . $f1->filename . " and " . $f2->filename, "\n";
  die "matrices are different; see " . $f1->filename . " and " . $f2->filename;
 

  # the tests:

  # for each document in $new and $old, check that each
  # citation-suggestion is properly well-formed, ie. has all
  # the necessary data fields in it

  # for each document in $new and $old, check that each
  # citation-suggestion is present in $cits with the same
  # new/old status

  # check that each citation is either new or old for each
  # document, but not both
}

sub compare_hash_keys {
  my ( $h1, $h2 ) = @_;
  my $h1k = join ' ', sort keys %$h1;
  my $h2k = join ' ', sort keys %$h2;
  return $h1k cmp $h2k;
}


sub as_string {
  my $self = shift;
  my @keys = qw( psid new old citations doclist totals_new );
  my $s = "- SIMILARITY MATRIX -\n";
  foreach ( @keys ) {
    $s .= "- MATRIX:$_ -\n";
    $s .= make_string( $self->{$_} );
    $s .= "- MATRIX:$_ end -\n";
  }
  return $s;
}

use UNIVERSAL qw( isa );

sub make_string ($;$);
sub make_string ($;$) {
  my $obj = $_[0];
  my $prefix = $_[1] || "";

  if ( not defined $obj ) { return "undef"; }
  if ( ref $obj ) {
    my $class = ":" . ref $obj;
    if ( $class eq ':HASH' or $class eq ':ARRAY' ) {
      $class = '';
    }
    my $s = '';
    if ( UNIVERSAL::isa( $obj, 'HASH' ) ) {
      $s .= "HASH$class\n";
      my @ks = sort keys %$obj;
      foreach ( @ks ) {
        $s .= "$prefix$_: ";
        $s .= make_string( $obj->{$_}, "$prefix  " );
        $s .= "\n";
      }
      $s .= "${prefix}HASH END\n";

    } elsif ( UNIVERSAL::isa( $obj, 'ARRAY')  ) {

      $s .= "ARRAY$class\n";
      my $n = 0;
      my $l = $obj;
      my $first = $obj->[0];
      if ( not defined $first ) {
        $s .= "${prefix}unsorted\n"; 

      } elsif ( ref $first eq 'HASH' and defined $first->{checksum} ) {
        my @l = sort { $a->{checksum} cmp $b->{checksum}
                       || $a->{reason} cmp $b->{reason} } @$obj;
        $l = \@l;

      } elsif ( ref $first eq 'ARRAY' and defined $first->[1] and $first->[1]{reason} ) {
        my @l = sort { $a->[0] cmp $b->[0]
                      || $a->[1]{checksum} cmp $b->[1]{checksum} 
                      || $a->[1]{reason} cmp $b->[1]{reason} } @$obj;
        $l = \@l;

      } else { 
        $s .= "${prefix}unsorted\n"; 
      }
        
      
      foreach ( @$l ) {
        $s .= "${prefix}$n: ";
        $s .= make_string( $_, "$prefix  " );
        $s .= "\n";
        $n ++;
      }
      $s .= "${prefix}ARRAY END\n";
      
    } else { return "unknown"; };
  } else { 
    return $obj;
  }
}

sub test_advanced {
  require ACIS::Citations::Search;
  require ACIS::Web;
  require ACIS::Web::UserData;
  

}


1;
