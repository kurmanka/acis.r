package ACIS::Citations::Suggestions;

use strict;
use warnings;

use Exporter;
use base qw( Exporter );
use vars qw( @EXPORT_OK );
@EXPORT_OK = qw( store_similarity make_suggestion_old 
                 suggest_citation_to_authors 
                 load_suggestions
                 clear_multiple_from_cit_suggestions );

### ACIS::Citations::Suggestions [90 min]

# low level:                      [45 min]
# - add_suggestion( cit, psid, docsid, reason, similarity )
# - store_update_suggestion( suggestion_record )
# - clear_cit_from_suggestions( cit, psid );
# - load_suggestions( psid );

# high level (exported):          [45 min]
# - store_similarity( cit, psid, docid, value )
# - make_suggestion_old( cit, psid, dsid )
# - suggest_citation_to_authors( cit, psid, docid );
# - clear_multiple_from_cit_suggestions( citlist, psid );


my $acis;
my $sql;

sub prepare() {
  $acis = $ACIS::Web::ACIS;
  $sql  = $acis -> sql_object;
}

#
###############   cit_suggestions table
#
# Fields:
#
#     * citation origin doc sid: srcdocsid CHAR(15) NOT NULL
#     * citation checksum: checksum CHAR(22) NOT NULL
#     * personal sid, short: psid CHAR(15) NOT NULL
#     * document sid, short: dsid CHAR(15) NOT NULL
#     * reason: ‘similar’ | ‘pre-identified’, ‘co-author:pau432’: reason CHAR(20) NOT NULL
#     * similarity: similar TINYINT UNSIGNED // (0...100)
#     * new: yes | no new BOOL
#     * original citation string: ostring TEXT NOT NULL
#     * origin doc details (URL): srcdocdetails BLOB
#     * suggestion’s creation/update date: time DATE NOT NULL
#
# PRIMARY KEY (srcdocsid, checksum, psid, dsid, reason),
# INDEX( psid ), INDEX( dsid )



sub add_suggestion($$$$$) {
  my ( $cit, $psid, $dsid, $reason, $similar ) = @_;
  if ( not $sql ) { prepare; }

  $sql -> prepare_cached( "insert into cit_suggestions values (?,?,?,?,?,?,true,?,?,NOW())" );
  $sql -> execute( $cit->{srcdocsid}, $cit->{checksum},
                   $psid, $dsid,
                   $reason, $similar,
                   $cit->{ostring}, $cit->{srcdocdetails} );

}

sub replace_suggestion($$$$$) {
  my ( $cit, $psid, $dsid, $reason, $similar ) = @_;
  if ( not $sql ) { prepare; }

  $sql -> prepare_cached( "replace into cit_suggestions values (?,?,?,?,?,?,true,?,?,NOW())" );
  $sql -> execute( $cit->{srcdocsid}, $cit->{checksum},
                   $psid, $dsid,
                   $reason, $similar,
                   $cit->{ostring}, $cit->{srcdocdetails} );

}

sub store_update_suggestion ($) {
  my $s = shift;
  if ( not $sql ) { prepare; }
  $sql -> prepare_cached( "update cit_suggestions set similar=?, new=?, time=NOW() ".
                          " where srcdocsid=? AND checksum=? AND psid=? AND dsid=? AND reason=?" );
  $sql -> execute( $s->{similar}, $s->{new}, 
                   $s->{srcdocsid},
                   $s->{checksum},
                   $s->{psid}, $s->{dsid}, $s->{reason} );
}


sub clear_cit_from_suggestions ($$) {
  my ( $cit, $psid ) = @_;
  if ( not $sql ) { prepare; }

  $sql -> prepare_cached( "delete from cit_suggestions where srcdocsid=? AND checksum=? and psid=?" );
  $sql -> execute( $cit->{srcdocsid}, $cit->{checksum}, $psid );
}

# sub hash_copy ($) {
#   my $h = shift;
#   my $r = { %$h };
# }

sub load_suggestions ($) {
  my $psid = shift;
  if ( not $sql ) { prepare; }
  my @slist = ();

  $sql -> prepare_cached( "select * from cit_suggestions where psid=?" );
  my $r = $sql -> execute( $psid );

  while ( $r and $r->{row} ) {
    my $s = { %{ $r->{row} } };  # hash copy
    push @slist, $s;
    $r-> next;
  }
  
  return \@slist;
}



sub store_similarity ($$$$) {
  my ( $cit, $psid, $dsid, $value ) = @_;
  my $reason = 'similar';
  
  replace_suggestion $cit, $psid, $dsid, $reason, $value;  
}

sub make_suggestion_old($) {
  my ( $sug ) = @_;
  $sug->{new} = 0;
  store_update_suggestion( $sug );
}


use ACIS::Citations::Utils qw( get_document_authors get_author_sid );

sub suggest_citation_to_authors($$$) {
  my ( $cit, $psid, $dsid ) = @_;
  
  my @authors = get_document_authors $dsid;
  foreach ( @authors ) {
    my $sid = get_author_sid $_;
    next if $sid eq $psid;
    # XXX what similarity value should be saved here?
    replace_suggestion $cit, $sid, $dsid, "coauth:$psid", 1;
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
  my $r = $sql ->execute(   "[[:<:]]KATZ, HARRY[[:>:]]" );
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

  $set1->[1]->{similar} = 75;
  $set1->[1]->{new} = 0;
  print "updated: ", store_update_suggestion $set1->[1];
  print "\n(similarity:75, new:0)\n";

  my $set2 = load_suggestions $psid;
  print "loaded: ", scalar @$set2, "\n";

  print "after update: similarity:", $set2->[1]{similar}, 
    " new:", $set2->[1]{new}, "\n\n";  

#  print "cleared: ", clear_cit_from_suggestions $cl[0], $psid;
#  print "\n";

  $set2 = load_suggestions $psid;
  print "loaded: ", scalar @$set2, "\n";

}









1;

