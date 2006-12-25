package ACIS::Citations::Suggestions;

use strict;
use warnings;

use Exporter;
use base qw( Exporter );
use vars qw( @EXPORT_OK );
@EXPORT_OK = qw( get_cit_doc_similarity 
                 store_cit_doc_similarity
                 clear_cit_doc_similarity
                 get_cit_sug
                 find_cit_sug
                 store_cit_sug
                 clear_cit_sug
                 add_cit_old_sug
                 get_cit_old_status
                 clear_cit_old_sug          
                 load_similarity_suggestions
              );


### ACIS::Citations::Suggestions 

# low level:                      
# - get_cit_doc_similarity( citid, docsid )
# - store_cit_doc_similarity( citid, docsid, similarity )
# - clear_cit_doc_similarity( citid, dsid )

# - get_cit_sug( citid, docsid )
# - store_cit_sug( citid, docsid, reason )
# - clear_cit_sug( citid, docsid, [reason] )

# - add_cit_old_sug( psid, citid, dsid )
# - get_cit_old_status( psid, citid, dsid )
# - clear_cit_old_sug( psid, citid, [dsid] )

#?:
# - suggest_citation_to_coauthors( cit, psid, docid );

my $acis;
my $sql;
my $rdbname;
my $select_suggestions;

sub prepare() {
  $acis = $ACIS::Web::ACIS;
  $sql  = $acis -> sql_object;
  $rdbname = $acis->config( 'metadata-db-name' );
  $select_suggestions = 
 "SELECT sug.*,citations.ostring,
   res.id as srcdocid,res.title as srcdoctitle,res.authors as srcdocauthors,res.urlabout as srcdocurlabout
  FROM cit_suggestions as sug LEFT JOIN citations USING (srcdocsid,checksum)
  LEFT JOIN $rdbname.resources as res ON citations.srcdocsid=res.sid ";
  ### Maybe also res.type? - at this time we don't need it
}

sub sql_select_sug {
  my $what  = shift;
  my $from  = shift;
  my $where = shift;
  return "SELECT $what,
citations.ostring,res.id as srcdocid,res.title as srcdoctitle,
res.authors as srcdocauthors,res.urlabout as srcdocurlabout
FROM $from 
  LEFT JOIN citations USING (citid)
  LEFT JOIN $rdbname.resources as res ON citations.srcdocsid=res.sid 
WHERE $where";
}


sub get_cit_doc_similarity ($$) {
  my ( $citid, $dsid ) = @_;
  if ( not $sql ) { prepare; }
  die if not $citid or not $dsid;

  $sql -> prepare_cached( 
     "select similar,time from cit_doc_similarity where citid=? and dsid=?" );
  my $r = $sql -> execute( $citid, $dsid );

  if ( $r and $r->{row} ) {
    my $row = $r->{row};
    return ( $row->{similar}+0, $row->{time} );
  }
  return undef;
}

sub store_cit_doc_similarity ($$$) {
  my ( $citid, $dsid, $value ) = @_;
  if ( not $sql ) { prepare; }
  die if not $citid or not $dsid or not defined $value;
  $sql -> prepare_cached( "REPLACE INTO cit_doc_similarity VALUES (?,?,?,NOW())" );
  $sql -> execute( $citid, $dsid, $value );
}

sub clear_cit_doc_similarity ($$) {
  my ( $citid, $dsid ) = @_;
  if ( not $sql ) { prepare; }
  die if not $citid and not $dsid;
  my $where = '';
  my @arg   = ();
  if ( defined $citid ) { $where .= " citid=? "; push @arg, $citid; };
  if ( $dsid ) { $where .= "AND dsid=? "; push @arg, $dsid; };
  $where =~ s/^AND //;
  $sql -> prepare_cached( "DELETE FROM cit_doc_similarity WHERE $where" );
  $sql -> execute( @arg );
}


### cit_sug table

sub get_cit_sug ($$) {
  my ( $citid, $dsid ) = @_;
  if ( not $sql ) { prepare; }
  die if not $dsid or not $citid;

  $sql -> prepare_cached( "select reason,time from cit_sug where citid=? and dsid=?" );
  my $r = $sql -> execute( $citid, $dsid );

  my @res = ();
  while ( $r and $r->{row} ) {
    my $row = $r->{row};
    push @res, $row->{reason}, $row->{time};
    $r->next;
  }
  return @res;
}


sub find_cit_sug ($$) {
  my ( $citid, $dsid ) = @_;
  if ( not $sql ) { prepare; }
  die if not $dsid and not $citid;

  my $where = '';
  my @arg   = ();
  if ( defined $citid ) { $where .= "citid=? "; push @arg, $citid; };
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


sub store_cit_sug ($$$) {
  my ( $citid, $dsid, $reason ) = @_;
  if ( not $sql ) { prepare; }
  die if not $citid or not $dsid or not $reason;
  $sql -> prepare_cached( "REPLACE INTO cit_sug VALUES (?,?,?,NOW())" );
  $sql -> execute( $citid, $dsid, $reason );
}

sub clear_cit_sug ($$;$) {
  my ( $citid, $dsid, $reason ) = @_;
  if ( not $sql ) { prepare; }
  die if not $citid and not $dsid;
  my $where = '';
  my @arg   = ();
  if ( defined $citid ) { $where .= " citid=? "; push @arg, $citid; };
  if ( $dsid )   { $where .= "AND dsid=? ";      push @arg, $dsid; };
  if ( $reason ) { $where .= "AND reason=? ";    push @arg, $reason; } 
  $where =~ s/^AND //;
  $sql -> prepare_cached( "DELETE FROM cit_sug WHERE $where" );
  $sql -> execute( @arg );
}

# cit_old_sug

sub add_cit_old_sug ($$$) {
  my ( $psid, $citid, $dsid ) = @_;
  if ( not $sql ) { prepare; }
  die if not $psid or not $citid or not $dsid;
  $sql -> prepare_cached( "REPLACE INTO cit_old_sug VALUES (?,?,?)" );
  $sql -> execute( $psid, $citid, $dsid );
}

sub clear_cit_old_sug ($$$) {
  my ( $psid, $citid, $dsid ) = @_;
  if ( not $sql ) { prepare; }
  die if not $psid or not $citid or not $dsid;
  
  my $where = '';
  my @arg   = ();
  if ( $psid )   { $where .= "psid=? ";             push @arg, $psid; }  
  if ( defined $citid ) { $where .= "AND citid=? "; push @arg, $citid; };
  if ( $dsid )   { $where .= "AND dsid=? ";         push @arg, $dsid; };
  $where =~ s/^AND //;

  $sql -> prepare_cached( "DELETE FROM cit_old_sug WHERE $where" );
  $sql -> execute( @arg );
}

sub get_cit_old_status ($$$) {
  my ( $psid, $citid, $dsid ) = @_;
  if ( not $sql ) { prepare; }
  die if not $citid or not $dsid or not $psid;

  $sql -> prepare_cached( "select citid from cit_old where psid=? and citid=? and dsid=?" );
  my $r = $sql -> execute( $psid, $citid, $dsid );
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

  $r = store_cit_doc_similarity $cl[0]->{citid}, 'dtestsid0', 70;
  print "Added a suggestion: $r\n";
  $r = store_cit_doc_similarity $cl[0]->{citid}, 'dtestsid1', 40;
  print "added a suggestion: $r\n";
  $r = store_cit_doc_similarity $cl[0]->{citid}, 'dtestsid2', 10;
  print "added a suggestion: $r\n";
  $r = store_cit_doc_similarity $cl[0]->{citid}, 'dtestsid3', 10;
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
  
  $sql -> prepare_cached( 
    sql_select_sug( "sim.*,old.dsid as oldflag", 
                    "cit_doc_similarity as sim 
                     LEFT JOIN cit_old_sug AS old ON (old.psid=? and old.citid=sim.citid and old.dsid=sim.dsid)",
                    "sim.dsid=?" )
  );

  foreach ( @$dsidlist ) {
    my $r = $sql -> execute( $psid, $_ );

    while ( $r and $r->{row} ) {
      my $s = { %{ $r->{row} } };  # hash copy
      foreach ( qw( ostring srcdoctitle srcdocauthors ) ) {    
        $s->{$_} = Encode::decode_utf8( $r->{row}{$_} );
      }
      if ( delete $s->{oldflag} ) { $s->{new} = 0; } 
      else { $s->{new} = 1; }
      $s->{reason} = 'similar';
      push @slist, $s;
      $r-> next;
    }
  }
  return \@slist;
}

sub load_nonsimilarity_suggestions ($$) {
  my $psid     = shift;
  my $dsidlist = shift;
  if ( not $sql ) { prepare; }
  my @slist = ();
  
  $sql -> prepare_cached( 
    sql_select_sug( "csug.*,old.dsid as oldflag", 
                    "cit_sug as csug 
                     LEFT JOIN cit_old_sug AS old ON (old.psid=? and old.citid=csug.citid and old.dsid=csug.dsid)",
                    "csug.dsid=?" )
  );

  foreach ( @$dsidlist ) {
    my $r = $sql -> execute( $psid, $_ );

    while ( $r and $r->{row} ) {
      my $s = { %{ $r->{row} } };  # hash copy
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

__END__


sub load_coauthor_suggestions_new($) {
  my $psid = shift || die;
  if ( not $sql ) { prepare; }
#  debug "load_coauthor_suggestions: $psid";

  $sql -> prepare_cached( "$select_suggestions where reason like 'coauth:%' and psid=? and new=TRUE" );
  my $r = $sql -> execute( $psid );
  my @cl = ();
  while ( $r and $r->{row} ) {
    my $s = { %{$r->{row}} };
    foreach ( qw( ostring srcdoctitle srcdocauthors ) ) {    
      $s->{$_} = Encode::decode_utf8( $r->{row}{$_} );
    }
    push @cl, $s;
    $r->next;
  }
#  debug "load_coauthor_suggestions: found ", scalar @cl, " items";
  return \@cl;
}



sub store_similarity ($$$$) {
  my ( $cit, $psid, $dsid, $value, $new ) = @_;
  my $reason = 'similar';
  
  replace_suggestion $cit, $psid, $dsid, $reason, $value, $new;  
}

sub make_suggestion_old($) {
  my ( $sug ) = @_;
  $sug->{new} = 0;
  store_update_suggestion( $sug );
}


use Web::App::Common;
use ACIS::Citations::Utils qw( get_document_authors get_author_sid coauthor_suggestion_similarity );

sub suggest_citation_to_coauthors($$$) {
  my ( $cit, $psid, $dsid ) = @_;
  
  my @authors = get_document_authors $dsid;
  foreach ( @authors ) {
    debug "suggest to author: $_?";
    my $sid = get_author_sid $_;
    next if not $sid;
    next if $sid eq $psid;
    my $sug = check_suggestions( $cit, $sid, $dsid, "coauth:$psid" ); 
    if ( $sug ) {
      # do nothing, already suggested
    } else {
      add_suggestion $cit, $sid, $dsid, "coauth:$psid", coauthor_suggestion_similarity;
    }
  }
}

sub clear_multiple_from_cit_suggestions($$) {
  my ( $citlist, $psid ) = @_;
  foreach ( @$citlist ) {
    clear_cit_from_suggestions( $_, $psid );
  }
}




sub testme_lowlevel() {
  require ACIS::Web;
  # home=> '/home/ivan/proj/acis.zet'
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
  
  my $psid = 'ptestsid0';
  $r = add_suggestion $cl[0], $psid, 'dtestsid0', 'similar', 70;
  $r |= 0;
  print "Added a suggestion: $r\n";
  $r = add_suggestion $cl[0], $psid, 'dtestsid1', 'similar', 40; 
  $r = add_suggestion $cl[0], $psid, 'dtestsid2', 'similar', 10; 


  $r = add_suggestion $cl[1], $psid, 'dtestsid0', 'similar', 40; 
  $r = add_suggestion $cl[1], $psid, 'dtestsid1', 'similar', 30; $r |= 0;
  print "Added another suggestion: $r\n";
  $r = add_suggestion $cl[1], $psid, 'dtestsid2', 'similar', 15; 


  $r = add_suggestion $cl[2], $psid, 'dtestsid2', 'similar', 40; $r |= 0;
  print "Added another suggestion: $r\n";

  $r = add_suggestion $cl[2], $psid, 'dtestsid0', 'similar', 40; $r |= 0;


  my $set1 = load_suggestions $psid;
  print "loaded: ", scalar @$set1, "\n";

  print "before update: similarity:", $set1->[1]{similar}, 
    " new:", $set1->[1]{new}, "\n\n";  

  if ( $set1->[1]->{similar} == 75 ) {
    $set1->[1]->{similar} = 40;
  } else {
    $set1->[1]->{similar} = 75;
  }
  $set1->[1]->{new} = 0;
  print "updated: ", store_update_suggestion $set1->[1], "\n";

  my $set2 = load_suggestions $psid;
  print "loaded: ", scalar @$set2, "\n";

  print "after update: similarity:", $set2->[1]{similar}, 
    " new:", $set2->[1]{new}, "\n\n";  

#  print "cleared: ", clear_cit_from_suggestions $cl[0], $psid;
#  print "\n";

  $set2 = load_suggestions $psid;
  print "loaded: ", scalar @$set2, " items\n";

}









1;

