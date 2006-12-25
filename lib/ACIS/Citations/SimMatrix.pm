package ACIS::Citations::SimMatrix;

use strict;
use warnings;

use Carp;
use Carp::Assert;
use Scalar::Util qw( weaken );

#  load_similarity_matrix( psid );
#  get_most_interesting_document( psid );

use Exporter;
use base qw( Exporter );
use vars qw( @EXPORT );
@EXPORT = qw( load_similarity_matrix );


use Web::App::Common;
use ACIS::Web::SysProfile;
use ACIS::Citations::Suggestions qw( get_cit_doc_similarity 
                 store_cit_doc_similarity
                 clear_cit_doc_similarity
                 get_cit_sug
                 store_cit_sug
                 clear_cit_sug
                 add_cit_old_sug
                 clear_cit_old_sug           
                 load_similarity_suggestions
                 load_nonsimilarity_suggestions
                                  );
use ACIS::Citations::Utils qw( today cid min_useful_similarity 
                               coauthor_suggestion_similarity
                               preidentified_suggestion_similarity );

sub DEBUG_SIMMATRIX_CONSISTENCY { 1; } ### YYY debug until we are 100% sure


sub load_similarity_matrix($$;$) {
  my $psid      = shift || die;
  my $dsid_list = shift || die;
  my $filters   = shift || []; # each item is a hash of long cit ids ("srcdocsid-checksum")

  debug "load_similarity_matrix() for rec $psid";
  my $sug1  = load_similarity_suggestions( $psid, $dsid_list );
  my $sug2  = load_nonsimilarity_suggestions( $psid, $dsid_list );
  my $mat  = { new => {}, old => {}, psid => $psid, citations=>{} };
  bless $mat;

  my @sug;
  foreach my $f ( @$filters ) { 
    @sug = grep { not exists $f->{ $_->{srcdocsid} . '-' . $_->{checksum} } } @$sug1, @$sug2;
  }

  foreach ( @sug ) {
    $mat -> _add_sug( $_ );
  }
  
  $mat -> _calculate_totals;
  return $mat;
}




# for internal usage: add a suggestion to the matrix
sub _add_sug {
  my $self = shift || die;
  my $sug  = shift || die;
  
  my $d      = $sug ->{dsid} || die;
  my $newold = ($sug->{new}) ? 'new' : 'old';

  if ( $sug->{reason} eq 'preidentified' ) {
    $sug->{similar} = preidentified_suggestion_similarity; 
  } elsif ( $sug->{reason} =~ m!co\-?auth! ) { 
    $sug->{similar} = coauthor_suggestion_similarity; 
  }

  my $known = $self->{citations};

  for ( $self->{$newold}{$d} ) {
    if ( not $_ ) { $_ = []; }
    push @$_, $sug;

    # maintain an index
    my $cid = $sug->{srcdocsid} . '-' . $sug->{checksum};
    my $cindex = $known->{$cid}{$d} ||= [];
    my $pair = [ $newold, $sug ];
    weaken( $pair->[1] );
    push @$cindex, $pair;

    # clear redundant bits
    delete $sug->{dsid};
    delete $sug->{psid};
    delete $sug->{new};
  }
}


# how much interestingness do new suggestions represent
sub _calculate_totals {
  my $self   = shift;
  my $totals = {};
  
  my $newdoc = $self->{new};
  foreach ( keys %$newdoc ) {
    my $dsid = $_;
    my $total = 0;
    foreach ( @{ $newdoc->{$_} } ) {
      if ( $_->{similar} >= min_useful_similarity ) {
        $total += $_->{similar};
      }
    }
    $totals ->{$dsid} = $total;
  }

  $self->{totals_new} = $totals;
  
  my @doclist = keys %$newdoc;
  @doclist = grep { $totals->{$_} } @doclist;
  @doclist = sort { $totals->{$b} <=> $totals->{$a} 
                    or $a cmp $b } @doclist;

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


# given a list of citations, which of them are not yet present in the
# matrix?  (remove those which are present and return the list of the
# removed items)

sub filter_out_known {
  my $self   = shift || die;
  my $list   = shift || die;

  debug "filter_out_known()";

  my $known = [];
  my $citindex = $self->{citations};

  my $acis = $ACIS::Web::ACIS;
  my $sql  = $acis -> sql_object;

  my @old = ();
  $sql->prepare( "select citid from cit_old_sug where psid=? group by citid" );
  my $r = $sql->execute( $self->{psid} );
  while( $r and $r->{row} ) {
    push @old, $r->{row}{citid};
    $r->next;
  }
  
  my %old_citids = map { $_=>1 } @old; # make a hash of old citids

  foreach ( @$list ) {
    my $citation = $_;
    my $found;
    if ( $_->{citid} and $old_citids{$_->{citid}} ) { 
      $found = 1;

    } else {
      my $clid = $citation->{srcdocsid} . '-' . $citation->{checksum};
      if ( not $citindex->{$clid} ) { next; }
      $found = 1; 
    }

    if ( $found ) {
      debug "citation known: $clid";
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
  my $acis = ACIS::Web->new;

  my $psid = 'ptestsid0';
  my $rp   = [ qw( dbar3 dloc11 ddec1 ) ];
  my $m    = load_similarity_matrix( $psid, $rp ); 
  print Data::Dumper::Dumper( $m );
}



#########   Advanced Similarity Matrix part   #############

# package ACIS::Citations::SimMatrix; # ::Manager 

use strict;
use warnings;
use ACIS::Citations::Suggestions qw( get_cit_doc_similarity 
                                     store_cit_doc_similarity   
                                     get_cit_sug
                                     store_cit_sug
                                     add_cit_old_sug
                                     clear_cit_old_sug          
                                  );
use Web::App::Common;

my $acis;
my $rec;
sub upgrade {
  my $self = shift || die;
  my $_acis = shift || die;
  my $_rec  = shift || die;

  assert( $_acis->{home} and $_acis->{screenconf} );
  assert( $_rec->{name}  and $_rec->{id} );

  $acis = $_acis;
  $rec  = $_rec;
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
  my $reason = shift;

  my $known = $self->{citations};
  
  # check the index
  my $cid = $cit->{srcdocsid} . '-' . $cit->{checksum};

  my $l = $known->{$cid}{$dsid};
  foreach ( @$l ) {
    # $_->[0] new / old
    # $_->[1] suggestion itself
    if ( not $reason ) { return @$_; }
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
  my $pretend= shift;

  my $psid = $self->{psid} || die;
  my $l    = $self->{new} {$dsid} ||= [];

  my $sug = { %$cit, reason => $reason, similar => $sim, time => today() };
  push @$l, $sug;
  delete $sug->{nstring};
  delete $sug->{trgdocid};

  if ( $reason eq 'preidentified' ) {
    store_cit_sug( $cit->{citid}, $dsid, $reason );
  } elsif ( $reason eq 'similar' ) {
  }

  # maintain the index
  my $known = $self->{citations};
  my $cid   = $sug->{srcdocsid} . '-' . $sug->{checksum};
  my $cindex = $known->{$cid}{$dsid} ||= [];
  push @$cindex, [ 'new', $sug ];
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

use Data::Dumper;
sub _docs {
  my $self = shift || die;
  my $docs = $self-> {docs};
  if ( not $docs ) {
    ### prepare doc objects, as per Similarity assessment function interface
    $docs = {};
    my $rp = $rec ->{contributions}{accepted} || [];
    foreach ( @$rp ) {
      my $sid = $_->{sid};
      if ( not $sid ) {
        warn "accepted contribution: ", Dumper( $_ ), " with no sid";
        if ( $rec ) { warn "context: $rec->{id}\n"; }
        next;
      }
      my $doc = { %$_ };
      my $authors = $doc->{authors} || '';
      $doc->{authors} = [ split / \& /, $authors ];
      if ( not $doc->{location} ) { }  # YYY - so what? 
      $docs -> {$sid} = $doc;
    }
    $self->{docs} = $docs;
  }
  return $docs;
}

sub compare_citation_to_documents {
  my $self = shift || die;
  my $cit  = shift || die;
  my $pretend = shift;
  my $force_comparison = shift;

  debug "compare_citation_do_documents()";

  my $docs = $self -> _docs;
  debug "documents: ", join ' ', keys %$docs;

  my $psid = $self->{psid} || die;
  die if not $acis;
  my $func = $acis->config( 'citation-document-similarity-func' ) 
    || 'ACIS::Citations::Utils::cit_document_similarity';

  debug "will use similarity function: $func";

  my $citid = $cit->{citid} || die "citation must have numeric non-zero citid";
  
  while ( my( $dsid, $doc ) = each %$docs ) {

    my ($no, $sug) = $self->find_sugg( $cit, $dsid, 'similar' );

    if ( $sug ) {
      debug "citation is known for $dsid";
      my $t = $sug->{time};

      if ( ACIS::Citations::Utils::time_to_recompare_cit_doc( $t ) ) {
        no strict 'refs';
        my $similarity = sprintf( '%u', &{$func}( $cit, $doc ) * 100 );
        debug "similarity: $similarity";
        store_cit_doc_similarity( $citid, $dsid, $similarity )
          unless $pretend;

        $sug -> {similar} = $similarity;
        $sug -> {time} = today();
      }

    } else {
      debug "comparing to $dsid (", $doc->{title}, ")";
      
      my ($similarity,$t) = get_cit_doc_similarity( $citid, $dsid );
     
      if ( ACIS::Citations::Utils::time_to_recompare_cit_doc( $t ) ) {
        undef $similarity;
        debug "got from db: $similarity, but it is outdated; recompare";
      }

      if ( $similarity ) {
        debug "got from db: $similarity";
        
      } else {
        no strict 'refs';
        $similarity = sprintf( '%u', &{$func}( $cit, $doc ) * 100 );
        debug "similarity: $similarity";
        store_cit_doc_similarity( $citid, $dsid, $similarity )
          unless $pretend;
      }
      $self->add_sugg( $cit, $dsid, "similar", $similarity, $pretend );
    } 
  }

  return 1;
}



sub add_new_citations {
  my $self = shift || die;
  my $list = shift || die;
  my $dsid    = shift;
  my $reason  = shift;
  my $pretend = shift; # do not add suggestions

  my $psid = $self->{psid} || die;
  
  if ( $dsid ) {
    foreach ( @$list ) {
      $self->add_sugg( $_, $dsid, "preidentified", undef, $pretend );
    }

  } else {
    ### run comparisons
    foreach ( @$list ) {
      assert( !$_->{gone} );
      $self->compare_citation_to_documents( $_, $pretend );
    }
  }

  $self -> _calculate_totals;
  $self -> check_consistency
    if not $pretend and not DEBUG_SIMMATRIX_CONSISTENCY;
  
}


sub run_maintenance { 
  my $self = shift || die;
  my $pretend=shift;

  die if not $acis;
  die if not $rec;
  my $psid = $self->{psid} || die;
  my $sql  = $acis->sql_object() || die;

  my $new  = $self->{new};
  my $old  = $self->{old};

  # should we really run maintenance now?  Maybe we did this
  # just recently?
  my $lasttime = get_sysprof_value( $psid, "last-citations-prof-maint-time" );
  if ( $lasttime and time - $lasttime < 2 * 24 * 60 * 60 ) {
    debug "last maintenance was done less then 2 days ago";
    return;
  }
 
  # re-run citation/document comparisons
  # for those suggestions which are more then the
  # time-to-live days old, store them in db
  
  # CONDITION: if cit->time is less than now() -
  # citation-document-similarity-ttl days

  require Date::Manip; # qw( DateCalc ParseDate Date_Cmp );
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

          # XXX this looks strange. the following line compares the
          # citation to all the documents, but does it update {time} of
          # those suggestions? - can we do without it?

          $self->compare_citation_to_documents( $sug, $pretend );
          debug "suggestion too old: ", $sug;
        }
      }
    }
  }
  
  # recalculate totals now
  $self -> _calculate_totals();
  $self->check_consistency
    if not $pretend and not DEBUG_SIMMATRIX_CONSISTENCY;

  # record the current date in the sysprof table
  put_sysprof_value( $psid, "last-citations-prof-maint-time", time )
    if not $pretend;
}

sub remove_citation { 
  my $self = shift || die;
  my $cit  = shift || die; 

  # 
  die if not $acis;
  die if not $rec;
  my $psid = $self->{psid} || die;
  my $sql  = $acis->sql_object() || die;
  
  my $cid  = $cit->{srcdocsid} . '-' . $cit->{checksum};
  my $dhash = $self->{citations}{$cid};
  $self->{citations}{$cid} = 5;    # XXXX for debugging
  delete $self->{citations}{$cid}; ## to make sure
  return if not $dhash;
  warn if $self->{citations}{$cid}; # XXXX for debugging

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
        if ( $_->{gone} ) { delete $_->{gone}; undef $_; }
      }
      clear_undefined $list;
      if ( not scalar @$list ) {  delete $hash->{$docsid};  }
    }
  }

  
  $self->_calculate_totals;
  $self->check_consistency if not DEBUG_SIMMATRIX_CONSISTENCY;
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
  }
  clear_undefined $list;
  if ( not scalar @$list ) { delete $new->{$dsid}; }

  my $dh = $cits->{"$src-$chk"};
  $list = $dh->{$dsid};
  foreach ( @$list ) {
    $_->[0] = 'old';
  }
  
  my $psid = $self->{psid} || die;
  add_cit_old_sug( $psid, $cit->{citid}, $dsid );

  $self->_calculate_totals;
  $self->check_consistency if not DEBUG_SIMMATRIX_CONSISTENCY;
}


sub number_of_new_potential {
  my $self = shift;

  my $sim_threshold = min_useful_similarity;

  my $known = $self->{citations};
  my $pot_new_num = 0;
 CIT: 
  foreach ( keys %$known ) {
    my $cid = $_;
    my $dsidh = $known->{$cid};
    
  CITDOC: 
    foreach my $dsid ( keys %$dsidh ) {
      my $dsl = $dsidh->{$dsid}; # dsl = document suggestions list
      foreach ( @$dsl ) {
        die if not ref $_;
        die if not ref $_ eq 'ARRAY';
        if ( $_->[0] eq 'new' ) {
          if ( $_->[1] ->{similar} >= $sim_threshold 
               or $_->[1] ->{reason} ne 'similar' ) {
            debug "a new useful potential citation ($dsid): " , cid( $_->[1] );
            $pot_new_num++;
            next CIT;
          } else {
            debug "new, but not good enough ($dsid): ", cid( $_->[1] );
          }
        }
      }
    }
  }
  return $pot_new_num;
}


sub check_consistency {
  my $self = shift || die;

  die if not $acis;
  die if not $rec;
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
  my $f1 = File::Temp->new( TEMPLATE=> 'acis_sim_matrix_memory_XXXXX', DIR=> $acis->home, UNLINK=> 0 );
  print $f1 $str1;
  close $f1;

  my $f2 = File::Temp->new( TEMPLATE=> 'acis_sim_matrix_db_XXXXX', DIR=> $acis->home, UNLINK=> 0 );
  print $f2 $str2;
  close $f2;

#  print "matrices are different; see " . $f1->filename . " and " . $f2->filename, "\n";
  Carp::cluck "matrices are different; see " . $f1->filename . " and " . $f2->filename;
 

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
        my @l = sort {    $a->{checksum}  cmp $b->{checksum}
                       or $a->{reason}    cmp $b->{reason} 
                       or $a->{srcdocsid} cmp $b->{srcdocsid} 
                     } @$obj;
        $l = \@l;

      } elsif ( ref $first eq 'ARRAY' and defined $first->[1] and $first->[1]{reason} ) {
        my @l = sort {    $a->[0]            cmp $b->[0]
                       or $a->[1]{checksum}  cmp $b->[1]{checksum} 
                       or $a->[1]{reason}    cmp $b->[1]{reason} 
                       or $a->[1]{srcdocsid} cmp $b->[1]{srcdocsid} 
                     } @$obj;
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


require Storable;


1;
