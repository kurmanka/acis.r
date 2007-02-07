package ACIS::Citations::Suggestions;

use strict;
use warnings;

use Web::App::Common;
use Exporter;
use base qw( Exporter );
use vars qw( @EXPORT_OK );
@EXPORT_OK = qw( get_cit_doc_similarity 
                 store_cit_doc_similarity
                 clear_cit_doc_similarity
                 get_cit_sug
                 find_cit_sug
                 find_cit_sug_citations
                 store_cit_sug
                 clear_cit_sug
                 add_cit_old_sug
                 get_cit_old_status
                 clear_cit_old_sug          
                 load_similarity_suggestions
                 load_nonsimilarity_suggestions
              );

use ACIS::Citations::Utils;

### ACIS::Citations::Suggestions 

# low level:                      
# - get_cit_doc_similarity( cnid, docsid )
# - store_cit_doc_similarity( cnid, docsid, similarity )
# - clear_cit_doc_similarity( cnid, dsid )

# - get_cit_sug( cnid, docsid )
# - store_cit_sug( cnid, docsid, reason )
# - clear_cit_sug( cnid, docsid, [reason] )

# - add_cit_old_sug( psid, dsid, cnid )
# - get_cit_old_status( psid, dsid, cnid )
# - clear_cit_old_sug( psid, dsid, cnid ) - not to be used

#?:
# - suggest_citation_to_coauthors( cit, psid, docid );

my $acis;
my $sql;
my $rdbname;

sub prepare() {
  $acis = $ACIS::Web::ACIS;
  $sql  = $acis -> sql_object;
  $rdbname = $acis->config( 'metadata-db-name' );
}


sub sql_select_sug {
  my $what  = shift;
  my $from  = shift;
  my $joins = shift || '';
  my $where = shift;
  return "SELECT $what,
citations.ostring,citations.cnid,res.id as srcdocid,res.title as srcdoctitle,
res.authors as srcdocauthors,res.urlabout as srcdocurlabout
FROM $from 
  JOIN citations USING (cnid)
  JOIN $rdbname.resources as res ON (res.sid = substring_index(citations.clid,'-',1))
  $joins
WHERE $where";
}


sub get_cit_doc_similarity ($$) {
  my ( $cnid, $dsid ) = @_;
  if ( not $sql ) { prepare; }
  die if not $cnid or not $dsid;

  $sql -> prepare_cached( 
     "select similar,time from cit_doc_similarity where cnid=? and dsid=?" );
  my $r = $sql -> execute( $cnid, $dsid );

  if ( $r and $r->{row} ) {
    my $row = $r->{row};
    return ( $row->{similar}+0, $row->{time} );
  }
  return undef;
}

sub store_cit_doc_similarity ($$$) {
  my ( $cnid, $dsid, $value ) = @_;
  if ( not $sql ) { prepare; }
  die if not $cnid or not $dsid or not defined $value;
  $sql -> prepare_cached( "REPLACE INTO cit_doc_similarity VALUES (?,?,?,NOW())" );
  $sql -> execute( $cnid, $dsid, $value );
}

sub clear_cit_doc_similarity ($$) {
  my ( $cnid, $dsid ) = @_;
  if ( not $sql ) { prepare; }
  die if not $cnid and not $dsid;
  my $where = '';
  my @arg   = ();
  if ( defined $cnid ) { $where .= " cnid=? "; push @arg, $cnid; };
  if ( $dsid ) { $where .= "AND dsid=? "; push @arg, $dsid; };
  $where =~ s/^AND //;
  $sql -> prepare_cached( "DELETE FROM cit_doc_similarity WHERE $where" );
  $sql -> execute( @arg );
}


### cit_sug table

sub get_cit_sug ($$) {
  my ( $cnid, $dsid ) = @_;
  if ( not $sql ) { prepare; }
  die if not $dsid or not $cnid;

  $sql -> prepare_cached( "select reason,time from cit_sug where cnid=? and dsid=?" );
  my $r = $sql -> execute( $cnid, $dsid );

  my @res = ();
  while ( $r and $r->{row} ) {
    my $row = $r->{row};
    push @res, $row->{reason}, $row->{time};
    $r->next;
  }
  return @res;
}


sub find_cit_sug ($$) {
  my ( $cnid, $dsid ) = @_;
  if ( not $sql ) { prepare; }
  die if not $dsid and not $cnid;

  my $where = '';
  my @arg   = ();
  if ( defined $cnid ) { $where .= "cnid=? "; push @arg, $cnid; };
  if ( $dsid ) { $where .= "AND dsid=? "; push @arg, $dsid; };
  $where =~ s/^AND //;

  $sql -> prepare_cached( "select * from cit_sug where $where" );
  my $r = $sql -> execute( @arg );

  my @res = ();
  while ( $r and $r->{row} ) {
    my $row = $r->{row};
    push @res, { %$row };
    $r->next;
  }
  return \@res;
}



sub find_cit_sug_citations ($$) {
  # see also load_nonsimilarity_suggestions() below
  my ( $cnid, $dsid ) = @_;
  if ( not $sql ) { prepare; }
  die if not $dsid and not $cnid;

  my $where = '';
  my @arg   = ();
  if ( defined $cnid ) { $where .= "s.cnid=? "; push @arg, $cnid; };
  if ( $dsid ) { $where .= "AND s.dsid=? "; push @arg, $dsid; };
  $where =~ s/^AND //;

  my $select_citations = ACIS::Citations::Utils::select_citations_sql( $acis );
  $select_citations =~ s!SELECT(\s+)(\w)!SELECT s.reason,$2!i;

  $sql -> prepare_cached( "$select_citations join cit_sug as s using (cnid) where $where" );
  my $r = $sql -> execute( @arg );
  return $r;
}


sub store_cit_sug ($$$) {
  my ( $cnid, $dsid, $reason ) = @_;
  if ( not $sql ) { prepare; }
  die if not $cnid or not $dsid or not $reason;
  $sql -> prepare_cached( "REPLACE INTO cit_sug VALUES (?,?,?,NOW())" );
  $sql -> execute( $cnid, $dsid, $reason );
}

sub clear_cit_sug ($$;$) {
  my ( $cnid, $dsid, $reason ) = @_;
  if ( not $sql ) { prepare; }
  die if not $cnid and not $dsid;
  my $where = '';
  my @arg   = ();
  if ( defined $cnid ) { $where .= " cnid=? "; push @arg, $cnid; };
  if ( $dsid )   { $where .= "AND dsid=? ";      push @arg, $dsid; };
  if ( $reason ) { $where .= "AND reason=? ";    push @arg, $reason; } 
  $where =~ s/^AND //;
  $sql -> prepare_cached( "DELETE FROM cit_sug WHERE $where" );
  $sql -> execute( @arg );
}

# cit_old_sug

sub add_cit_old_sug ($$$) {
  my ( $psid, $dsid, $cnid ) = @_;
  if ( not $sql ) { prepare; }
  die if not $psid or not $cnid or not $dsid;
  $sql -> prepare_cached( "REPLACE INTO cit_old_sug (psid,dsid,cnid) VALUES (?,?,?)" );
  $sql -> execute( $psid, $dsid, $cnid );
}

sub clear_cit_old_sug_XXX_NOT_TO_BE_USED ($$$) {
  my ( $psid, $dsid, $cnid ) = @_;
  if ( not $sql ) { prepare; }
  die if not $psid or not $cnid or not $dsid;
  
  my $where = '';
  my @arg   = ();
  if ( $psid )   { $where .= "psid=? ";             push @arg, $psid; }  
  if ( defined $cnid ) { $where .= "AND cnid=? "; push @arg, $cnid; };
  if ( $dsid )   { $where .= "AND dsid=? ";         push @arg, $dsid; };
  $where =~ s/^AND //;

  $sql -> prepare_cached( "DELETE FROM cit_old_sug WHERE $where" );
  $sql -> execute( @arg );
}

sub get_cit_old_status ($$$) {
  my ( $psid, $dsid, $cnid ) = @_;
  if ( not $sql ) { prepare; }
  die if not $cnid or not $dsid or not $psid;

  $sql -> prepare_cached( "select cnid from cit_old_sug where psid=? and cnid=? and dsid=?" );
  my $r = $sql -> execute( $psid, $cnid, $dsid );
  return ( $r and $r->{row} );
}



sub testme_tablelevel() {
  require ACIS::Web;
  my $acis = ACIS::Web->new(  );
  my $sql = $acis-> sql_object;
  $sql ->prepare( "select * from citations where nstring REGEXP ?" );
  my $r = $sql ->execute(   "[[:<:]]KATZ HARRY[[:>:]]" );
  my @cl;
  while( $r and $r->{row} ) {
    my $c = { %{$r->{row}} };
    push @cl, $c;
    $r->next;
  }

  foreach ( @cl ) {
    print "citation: \n";
    my $c = $_;
    foreach ( keys %$c ) {
      print "\t$_: ", 
        ( defined $c->{$_} ) ? $c->{$_} : ''
        , "\n";
    }
  }

  $r = store_cit_doc_similarity $cl[0]->{cnid}, 'dtestsid0', 70;
  print "Added a suggestion: $r\n";
  $r = store_cit_doc_similarity $cl[0]->{cnid}, 'dtestsid1', 40;
  print "added a suggestion: $r\n";
  $r = store_cit_doc_similarity $cl[0]->{cnid}, 'dtestsid2', 10;
  print "added a suggestion: $r\n";
  $r = store_cit_doc_similarity $cl[0]->{cnid}, 'dtestsid3', 10;
  print "added a suggestion: $r\n";

  if (0) {
#    $r = add_suggestion $cl[1], $psid, 'dtestsid0', 'similar', 40; 
#    $r = add_suggestion $cl[1], $psid, 'dtestsid1', 'similar', 30; $r |= 0;
#    print "Added another suggestion: $r\n";
#    $r = add_suggestion $cl[1], $psid, 'dtestsid2', 'similar', 15; 
#    $r = add_suggestion $cl[2], $psid, 'dtestsid2', 'similar', 40; $r |= 0;
#    print "Added another suggestion: $r\n";
#    $r = add_suggestion $cl[2], $psid, 'dtestsid0', 'similar', 40; $r |= 0;

#    my $set1 = load_suggestions $psid;
#    print "loaded: ", scalar @$set1, "\n";

#    print "before update: similarity:", $set1->[1]{similar}, 
#      " new:", $set1->[1]{new}, "\n\n";  
#    if ( $set1->[1]->{similar} == 75 ) {
#      $set1->[1]->{similar} = 40;
#    } else {
#      $set1->[1]->{similar} = 75;
#    }
#    $set1->[1]->{new} = 0;
#    print "updated: ", store_update_suggestion $set1->[1], "\n";
    
#    my $set2 = load_suggestions $psid;
#    print "loaded: ", scalar @$set2, "\n";
    
#    print "after update: similarity:", $set2->[1]{similar}, 
#      " new:", $set2->[1]{new}, "\n\n";  
    
#  print "cleared: ", clear_cit_from_suggestions $cl[0], $psid;
#  print "\n";

#    $set2 = load_suggestions $psid;
#    print "loaded: ", scalar @$set2, " items\n";
  }
}



require Encode;

sub load_similarity_suggestions ($$) {
  my $psid     = shift;
  my $dsidlist = shift;
  if ( not $sql ) { prepare; }
  my @slist = ();
  debug "load_similarity_suggestions($psid,$dsidlist)";

  my $cond = join ' or ', map { "sim.dsid='$_'" } @$dsidlist;
  $sql -> prepare( 
    sql_select_sug( "sim.*,old.dsid as oldflag", 
                    "cit_doc_similarity as sim",
                    "LEFT JOIN cit_old_sug AS old ON (old.psid=? and old.cnid=sim.cnid and old.dsid=sim.dsid)",
                    "sim.similar>0 and ($cond)" )
  );

  my $sth = $sql->{last_sth};
  $sth->execute($psid);
  my $res = $sth->fetchall_arrayref( {} );
  $sth -> finish;

  foreach ( @$res ) {
    my $s = $_;
    foreach ( qw( ostring srcdoctitle srcdocauthors ) ) {    
      $s->{$_} = Encode::decode_utf8( $s->{$_} );
    }
    if ( delete $_->{oldflag} ) { $_->{new} = 0; } 
    else { $_->{new} = 1; }
    $_->{reason} = 'similar';
  }

  return $res; 
}

sub load_similarity_suggestions_all_lowtec ($$) {
  my $psid     = shift;
  my $dsidlist = shift;
  if ( not $sql ) { prepare; }
  my @slist = ();
  debug "load_similarity_suggestions($psid,$dsidlist)";

  my $cond = join ' or ', map { "sim.dsid='$_'" } @$dsidlist;
  $sql -> prepare( 
    sql_select_sug( "sim.*,old.dsid as oldflag", 
                    "cit_doc_similarity as sim",
                    "LEFT JOIN cit_old_sug AS old ON (old.psid=? and old.cnid=sim.cnid and old.dsid=sim.dsid)",
                    "sim.similar>0 and ($cond)" )
  );

  my $r = $sql -> execute( $psid );

  while ( $r and $r->{row} ) {
    debug "found item: ", $r->{row}{cnid} , ' / ', $r->{row}{similar};
    my $s = $r->{row};  # hash copy
    foreach ( qw( ostring srcdoctitle srcdocauthors ) ) {    
      $s->{$_} = Encode::decode_utf8( $r->{row}{$_} );
    }
    if ( delete $s->{oldflag} ) { $s->{new} = 0; } 
    else { $s->{new} = 1; }
    $s->{reason} = 'similar';
    push @slist, $s; 
    $r-> next;
  }
  return \@slist;
}

sub load_similarity_suggestions_one_by_one_lowtec ($$) {
  my $psid     = shift;
  my $dsidlist = shift;
  if ( not $sql ) { prepare; }
  my @slist = ();
  debug "load_similarity_suggestions($psid,$dsidlist)";

  $sql -> prepare_cached( 
    sql_select_sug( "sim.*,old.dsid as oldflag", 
                    "cit_doc_similarity as sim",
                    "LEFT JOIN cit_old_sug AS old ON (old.psid=? and old.cnid=sim.cnid and old.dsid=sim.dsid)",
                    "sim.dsid=? and sim.similar>0" )
  );

  my $sth = $sql->{last_sth};
  foreach ( @$dsidlist ) {
    $sth->execute($psid, $_);
    my $res = $sth->fetchall_arrayref( {} );

    foreach ( @$res ) {
      my $s = $_;
      foreach ( qw( ostring srcdoctitle srcdocauthors ) ) {    
        $s->{$_} = Encode::decode_utf8( $s->{$_} );
      }
      if ( delete $_->{oldflag} ) { $_->{new} = 0; } 
      else { $_->{new} = 1; }
      $_->{reason} = 'similar';
    }
    push @slist, @$res;
  }
  $sth -> finish;

  return \@slist; 
}

#sub load_similarity_suggestions ($$) {
sub load_similarity_suggestions_one_by_one ($$) { # not used now
  my $psid     = shift;
  my $dsidlist = shift;
  if ( not $sql ) { prepare; }
  my @slist = ();
  debug "load_similarity_suggestions($psid,$dsidlist)";
  
  $sql -> prepare_cached( 
    sql_select_sug( "sim.*,old.dsid as oldflag", 
                    "cit_doc_similarity as sim",
                    "LEFT JOIN cit_old_sug AS old ON (old.psid=? and old.cnid=sim.cnid and old.dsid=sim.dsid)",
                    "sim.dsid=? and sim.similar>0" )
  );

  foreach ( @$dsidlist ) {
    debug "check sugs for $_";
    my $r = $sql -> execute( $psid, $_ );

    while ( $r and $r->{row} ) {
      debug "found item: ", $r->{row}{cnid} , ' / ', $r->{row}{similar};
      my $s = $r->{row};  # hash copy
      foreach ( qw( ostring srcdoctitle srcdocauthors ) ) {    
        $s->{$_} = Encode::decode_utf8( $r->{row}{$_} );
      }
      if ( delete $s->{oldflag} ) { $s->{new} = 0; } 
      else { $s->{new} = 1; }
      $s->{reason} = 'similar';
      push @slist, $s; 
      $r-> next;
    }
    undef $r;
  }
  return \@slist;
}


sub load_nonsimilarity_suggestions ($$) {
  # see also find_cit_sug_citations() above
  my $psid     = shift;
  my $dsidlist = shift;
  
  if ( not $sql ) { prepare; }
  my @slist = ();

  $sql -> prepare_cached( 
    sql_select_sug( "csug.*,old.dsid as oldflag", 
                    "cit_sug as csug",
                    "LEFT JOIN cit_old_sug AS old ON (old.psid=? and old.cnid=csug.cnid and old.dsid=csug.dsid)",
                    "csug.dsid=?" )
  );

  foreach ( @$dsidlist ) {
    my $r = $sql -> execute( $psid, $_ );

    while ( $r and $r->{row} ) {
      my $s = $r->{row};
      foreach ( qw( ostring srcdoctitle srcdocauthors ) ) {    
        $s->{$_} = Encode::decode_utf8( $r->{row}{$_} );
      }
      if ( delete $s->{oldflag} ) { $s->{new} = 0; } 
      else { $s->{new} = 1; }
      push @slist, $s;
      $r-> next;
    }
  }
  return \@slist;
}

 

1;
