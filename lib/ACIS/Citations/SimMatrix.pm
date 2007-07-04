package ACIS::Citations::SimMatrix;

use strict;
use warnings;

use Carp;
use Carp::Assert;

#  get_most_interesting_document( psid );

use Exporter;
use base qw( Exporter );
use vars qw( @EXPORT );
@EXPORT = qw( load_similarity_matrix );


use Web::App::Common;
use ACIS::Web::SysProfile;
use ACIS::Citations::Suggestions qw(
                 get_cit_sug
                 store_cit_sug
                 clear_cit_sug
                 add_cit_old_sug
                 clear_cit_old_sug           
                 get_cit_old_status
                 load_similarity_suggestions
                 load_nonsimilarity_suggestions
                                  );
use ACIS::Citations::Utils qw( today min_useful_similarity 
                               coauthor_suggestion_similarity
                               preidentified_suggestion_similarity 
                               build_citations_index
                            );

sub DEBUG_SIMMATRIX_CONSISTENCY { 1; } ### YYY debug until we are 100% sure


sub make_identified_n_refused ($) {
  my $rec = shift || die;
  my $identified = {};
  my $refused    = {};
  my $identified_hl = $rec->{citations}{identified} || {};
  my $refused_l     = $rec->{citations}{refused}    || [];
    
  foreach ( keys %$identified_hl ) {
    my $list = $identified_hl ->{$_};
    build_citations_index $list, $identified;
  }
  $refused = build_citations_index $refused_l;
  return( $identified, $refused );
}

use Data::Dumper;
use Web::App::Common;

sub load_similarity_matrix($) {
  my $record = shift || die;
  my $psid = $record->{sid};

  debug "load_similarity_matrix() for rec $psid";
  my ($f1, $f2) = make_identified_n_refused($record); # each ($f1,$f2) is a hash of numeric cit ids (cnid)

  my $rp = $record->{contributions}{accepted} ||= [];
  my $dsid_list = [ grep {defined} map { $_->{sid} } @$rp ];
#  debug "dsid_list: ", join( ' ', @$dsid_list );

  # these caused leak
  my $sug1 = load_similarity_suggestions( $psid, $dsid_list );
  my $sug2 = load_nonsimilarity_suggestions( $psid, $dsid_list );

  my $coauth = "coauth:$psid";
  @$sug2 = grep { not $_->{reason} eq $coauth } @$sug2;

  my $mat  = { new => {}, old => {}, psid => $psid, citations=>{} };
  bless $mat;

  my @sug = grep { my $id = $_->{cnid}; 
                   $id and (not exists $f1->{$id}) and (not exists $f2->{$id}) } @$sug1, @$sug2;

  my $before_filter = scalar(@$sug1) + scalar( @$sug2);
  my $after_filter  = scalar @sug;
  debug "filtering: before:$before_filter after:$after_filter";
  $mat ->{sugs} = $after_filter;

  $mat -> _add_sugs( \@sug );
  $mat -> _calculate_totals;
  return $mat;
}



# for internal usage: add the suggestions to the matrix
sub _add_sugs {
  my ( $self, $sugs ) = @_;
  debug "_add_sugs()";
  die if not $self;
  die if not $sugs;

  my $preid_sim = preidentified_suggestion_similarity; 
  my $coau_sim  = coauthor_suggestion_similarity; 
  my $known = $self->{citations};
  my $i = 0;

  foreach (@$sugs) {
    if ( not $_->{cnid} ) {  Carp::croak "citation without cnid"; }

    my $d      = $_->{dsid} || die;
    my $newold = ($_->{new}) ? 'new' : 'old';
    my $reason = $_->{reason};

    if ( $reason eq 'preidentified' ) {
      $_->{similar} = $preid_sim; 
    } elsif ( $reason eq 'similar' ) {
    } elsif ( $reason =~ m!^coauth! ) { 
      $_->{similar} = $coau_sim;
    }
    
    # clear redundant bits
    delete $_->{dsid};
    delete $_->{psid};
    delete $_->{new};
    delete $_->{nstring};
    
    my $dlist = $self->{$newold}{$d} ||= [];
    push @$dlist, $_;
    
    # maintain an index
    my $cnid = $_->{cnid}; 
    my $cindex = $known->{$cnid}{$d} ||= [];
    my $pair = [ $newold, $_ ];
    push @$cindex, $pair;
    
    $i ++;
  }
  debug "added $i suggestions";
}

sub DESTROY {
  my $self = shift;
  delete $self->{new};
  delete $self->{old};
  delete $self->{citations};
  delete $self->{doclist};
  delete $self->{totals_new};
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



sub testme {
  require Data::Dumper;
  require ACIS::Web;
  my $acis = ACIS::Web->new;

# XXX this won't work anymore, because we now need a record to load a
#     matrix
#  my $psid = 'ptestsid0';
#  my $rplist = [ qw( dbar3 dloc11 ddec1 ) ];
#  my $m    = load_similarity_matrix( $psid, $rplist ); 
#  print Data::Dumper::Dumper( $m );
  
}



#########   Advanced Similarity Matrix part   #############

# package ACIS::Citations::SimMatrix; # ::Manager 

use strict;
use warnings;
use ACIS::Citations::Suggestions qw( get_cit_sug
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
  return $known->{ $cit->{cnid} };
}

sub find_sugg {
  my $self   = shift || die;
  my $cit    = shift || die;
  my $dsid   = shift || die;
  my $reason = shift;

  my $known = $self->{citations};
  
  # check the index
  my $cnid = $cit->{cnid}; 

  my $l = $known->{$cnid}{$dsid};
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


use ACIS::Citations::CitDocSim;

# used by consider_new_citations() method below
sub compare_citation_to_documents {
  my $self = shift || die;
  my $cit  = shift || die;
  my $force_comparison = shift;

  debug "compare_citation_do_documents()";

  delete $cit->{autoaddreason};
  delete $cit->{autoadded};

  my $docs = $self->{_docs} ||= make_docs( $rec );
  debug "documents: ", join ' ', keys %$docs;
  my $psid = $rec->{sid} || die;

  die if not $cit->{cnid};
  die if not $cit->{ostring};

  my $recalc;
  my $res = compare_citation_to_docs( $cit, $docs, 'includezero' );
  while ( $res and scalar @$res ) {
    my $dsid = shift @$res;
    my $v    = shift @$res;
    if ( $v ) {
      debug "for $dsid: $v";
    }
    warn "bad compare_citation_to_docs() result" if not $dsid or not defined $v;
    die if not $dsid or not defined $v;
    my (undef, $suggestion) = $self-> find_sugg( $cit, $dsid, 'similar' );
    if ( $suggestion ) {
      debug "found it in the matrix!";
      # update the suggestion
      if ( $suggestion->{similarity} != $v ) {
        $recalc = 1; # XX if the suggestion is old, this is not necessary
        $suggestion->{similarity} = $v;
        $suggestion->{time} = today();
      }

    } elsif ( $v >= min_useful_similarity ) {
      debug "add the suggestion";
      my $new = not get_cit_old_status( $psid, $dsid, $cit->{cnid} );
      $self->_add_sugs( [{ %$cit, dsid=> $dsid, reason=> 'similar', similar=> $v, new=>$new, time=>today() }] );
      $recalc = 1;

    } else {
      #debug "nothing";
    }
  }

  $self->_calculate_totals if $recalc;
  return 1;
}


sub consider_new_citations {
  my $self = shift || die;
  my $list = shift || die;

  ### run comparisons
  foreach ( @$list ) {
    assert( !$_->{gone} );
    $self->compare_citation_to_documents( $_ );
  }

  $self -> _calculate_totals;
  $self -> check_consistency
    if DEBUG_SIMMATRIX_CONSISTENCY;
}


sub remove_citation { 
  my $self = shift || die;
  my $cit  = shift || die; 

  die if not $acis;
  die if not $rec;
  my $psid = $self->{psid} || die;
  my $sql  = $acis->sql_object() || die;
  
  my $cnid = $cit->{cnid};
  my $dhash = delete $self->{citations}{$cnid};
  return if not $dhash;

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
      undef $_;
    }
    undef $slist;
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

  my $cits = $self->{citations};
  my $new  = $self->{new};
  my $old  = $self->{old};
  
  my $cnid = $cit->{cnid};
  my $list = $new->{$dsid} || die;

  foreach ( @$list ) {
    if ( $_->{cnid} eq $cnid ) {
      my $s = $_;
      undef $_; 
      push @{ $old->{$dsid} }, $s;
    }
  }
  clear_undefined $list;
  if ( not scalar @$list ) { delete $new->{$dsid}; }

  $list = $cits->{$cnid} {$dsid};
  foreach ( @$list ) {
    $_->[0] = 'old';
  }
  
  my $psid = $self->{psid} || die;
  add_cit_old_sug( $psid, $dsid, $cnid );

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
    my $cnid = $_;
    my $dsidh = $known->{$cnid};
    
  CITDOC: 
    foreach my $dsid ( keys %$dsidh ) {
      my $dsl = $dsidh->{$dsid}; # dsl = document suggestions list
      foreach ( @$dsl ) {
        die if not ref $_;
        die if not ref $_ eq 'ARRAY';
        if ( $_->[0] eq 'new' ) {
          if ( $_->[1] ->{similar} >= $sim_threshold 
               or $_->[1] ->{reason} ne 'similar' ) {
            #debug "a new useful potential citation ($dsid): " , $_->[1]{cnid};
            $pot_new_num++;
            next CIT;
          } else {
            #debug "new, but not good enough ($dsid): ", $_->[1]{cnid};
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
  my $copy = load_similarity_matrix( $rec );

  delete $self->{_docs};
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

  debug "matrices are different; see " . $f1->filename . " and " . $f2->filename;
  Carp::cluck scalar(localtime) . ": matrices are different; see " . $f1->filename . " and " . $f2->filename;
 

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

    if ( UNIVERSAL::isa( $obj, 'HASH' ) 
         and exists $obj->{ostring} ) {
      # special citation hash treatment
      $s .= "HASH$class\n";
      my @ks = sort keys %$obj;
      foreach ( qw( cnid ostring reason similar ) ) {
        $s .= "$prefix$_: ";
        $s .= make_string( $obj->{$_}, "$prefix  " );
        $s .= "\n";
      }
      $s .= "${prefix}HASH END\n";

    } elsif ( UNIVERSAL::isa( $obj, 'HASH' ) ) {
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

      } elsif ( ref $first eq 'HASH' and defined $first->{cnid} ) { 
        my @l = sort {    $a->{cnid}      cmp $b->{cnid} 
                       or $a->{reason}    cmp $b->{reason} 
                     } @$obj;
        $l = \@l;

      } elsif ( ref $first eq 'ARRAY' and defined $first->[1] and $first->[1]{reason} ) {
        my @l = sort {    $a->[0]            cmp $b->[0]
                       or $a->[1]{cnid}      cmp $b->[1]{cnid}
                       or $a->[1]{reason}    cmp $b->[1]{reason} 
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




1;
