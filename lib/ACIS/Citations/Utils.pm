package ACIS::Citations::Utils;

use strict;
use warnings;
use Carp::Assert;

use Exporter;

use base qw( Exporter );
use vars qw( @EXPORT );

@EXPORT = qw( normalize_string make_citation_nstring
              build_citations_index
              get_document_authors get_author_sid 
              min_useful_similarity
              today 
              identify_citation_to_doc
              unidentify_citation_from_doc_by_cid
              refuse_citation
              unrefuse_citation_by_cid
              cid
              load_citation_details
              select_citations_sql
              coauthor_suggestion_similarity
              preidentified_suggestion_similarity
             );


use Unicode::Normalize;
use Web::App::Common;
use ACIS::Citations::Events;


sub normalize_string($) {
  my $string = shift;

  for ( $string ) {
    $_ = NFD( $_ );
    $_ = uc $_;
    s/[^\w\d\s]/ /g;
#    tr/[\.,-'"`]/ /;
#    s!([,\.])!$1 !g;
#    s!\.\s+,!.,!g;
    s!\s\s+! !g;
    s!(^\s|\s$)!!g;
  }

  return $string;
}

sub make_citation_nstring {
  my $nst = $_[0];
  $nst =~ s/\b((I|i)n\W.+?\Wed\..*)$//; # cut the editors part 
  return normalize_string( $nst );
}

use Carp qw( cluck );
use Data::Dumper;

sub build_citations_index($;$) {
  my ( $citlist, $index ) = @_;
  $index ||= {};
  
  foreach (@$citlist) {
    #QQQQQ use ->{lcid} if available
    if ( not $_->{srcdocsid}
         or not $_->{checksum} ) {
      cluck "no srcdocsid or checksum!";
      debug "empty citation: " . Dumper($_);
      undef $_;
      next;
    } 
    my $key = $_->{srcdocsid} . '-' . $_->{checksum};
    $index ->{$key} = $_;
  }
  clear_undefined $citlist;
  return $index;
}


use String::Approx qw( amatch );
use String::Similarity;



sub cit_document_similarity {
  my ( $cit, $doc ) = @_;
  my $result = 0;

  assert( $cit and $doc );

  my $ostring = $cit->{ostring};
  my $nstring = $cit->{nstring};
  debug "cit_document_similarity: citation: ", $nstring;

  # Look at the author names first. Split the names of the
  # authors of the document into a list of words, strip all
  # non-letter non-whitespace characters and then strip
  # single whitespace-separated letters from it.

  my $authorslist = $doc->{authors};
  my $authornames = join ' ', @$authorslist;
  for( $authornames ) {
    s/[^\w]/ /g;
    s/\b\w\b/ /g;
    s/^\s+/ /g;
    s/\s+$/ /g;
  }
  my $authornamelist = [ split /\s+/, uc $authornames ];

  # We then search for approximate matches for each of these
  # words in the normalized citation string.  If there is a
  # match for any of the author-name-words, it is an "author
  # pass". Otherwise, the match is aborted with zero
  # similarity measure returned.

  my $pass;
  foreach ( @$authornamelist ) {
    debug "author name word $_";
    if ( amatch( "$_ ", $nstring ) ) { $pass = 1; last; }
  }
  
  if ( not $pass ) {
    debug "no author name match";
    return 0;
  }

  # If the document is an author pass, it will be ranked
  # according to the string similarity of the title only.
  # Compare titles. 

  # Take the normalized citation string and take the
  # normalized title of the research item. 
  my $ntitle = normalize_string( $doc->{title} );


  # check title length
  if ( length( $ntitle ) <= 10 ) {
    debug "too short a title: ", $ntitle;
    return 0;
  }
  

  # Find where in the citation string the first word of the
  # title is present.

  my @titlewords = split /\s+/, $ntitle;
  
  if ( scalar @titlewords < 2 ) {
    debug "one word title? ", $ntitle; 
    if ( index( $nstring, "$ntitle " ) > -1 ) {
      return 1;
    }
    if ( amatch( "$ntitle ", $nstring ) ) {
      return 0.9;
    }
    return 0;
  }
  
  my $first = $titlewords[0];
  while ( length( $first ) < 2 ) {
    shift @titlewords;
    $first .= ' ' . $titlewords[0];
  }
  debug "first word of the document's title is: '$first'";
  
  my $startpos = index $nstring, " $first ";

  if ($startpos > -1) {
    # now compare the title to the presumed title
    $startpos++; 
    debug "citation has title starting at: $startpos";
    my $cittitle = substr $nstring, $startpos, length( $ntitle );
    $result = similarity $ntitle, $cittitle;

  } else {
    debug "the title's begining was not found in the nstring";
    
    if ( amatch( "$ntitle ", $nstring ) ) {
      return 0.85;  # XXX Magic number: similarity of the aproximate match amatch()
    }
  }


  return $result;
} 


sub p (@) { print @_, "\n"; }

sub test_cit_document_similarity() {
  
  my @docs = (
              { title=> "INEQUALITY DECOMPOSITION ANALYSIS AND THE GINI COEFFICIENT REVISITED",
                authors => ['Peter J. Lambert', 'J. Richard ARONSON', 'ANAND' ],
                },
              );

  my @ncits = (
"LAMBERT P J AND J R ARONSON 1993 INEQUALITY DECOMPOSITION ANALYSIS AND THE GINI COECIENT REVISITED ECONOMIC JOURNAL 103",
"ANAND S 1983 INEQUALITY AND POVERTY IN MALAYSIA MEASUREMENT AND DECOMPOSITION OXFORD UNIVERSITY PRESS NEW YORK",
"BRUNO MICHAEL AND JEFFREY SACHS 1985 ECONOMICS OF WORLDWIDE STAGFLATION OXFORD BASIL BLACKWELL",
              );

  p "comparing";
  foreach ( @docs ) {
    my $d = $_;
    p "\ndoc: ", $_->{title};

    foreach ( @ncits ) {
      p "cit: $_";
      my $sim = cit_document_similarity( { nstring => $_ }, $d );
      p "result: ", $sim;
    }
  }
}







sub get_document_authors($) {
  my $docsid = shift;

  die if not $ACIS::Web::ACIS;
  my $app = $ACIS::Web::ACIS;

  my $docid  = $docsid;

  my $mdb = $app -> config( "metadata-db-name" );
  my $sql = $app -> sql_object() || die;

  if ( $docsid =~ /^d\w+\d+$/ 
       and length( $docsid ) < 16 ) {
    $sql -> prepare( "select id from $mdb.resources where sid=?" );
    my $res = $sql -> execute( $docsid );
    if ( $res -> {row} and $res -> {row} ->{id} ) {
      $docid = $res -> {row} ->{id};
    }
  } 

  $sql -> prepare( "select subject from $mdb.relations where relation='accept' and object=?" );
  my $res = $sql -> execute( $docid );
  my @list;

  while ( $res->{row} ) {
    push @list, $res->{row}->{subject};
    $res->next;
  }

  return @list;
}

                         
sub test_get_document_authors () {
  require ACIS::Web;
  
  my $acis = ACIS::Web->new( home=> '/home/ivan/proj/acis.zet' );

  my @docs = qw( repec:wop:cirano:2000s06 dacc4 dtax1 );

  foreach ( @docs ) {
    my @res = get_document_authors( $_ );
    print "doc: $_\nauthors: ", join( ', ', @res ), "\n\n";
  }
}


sub get_author_sid ($) {
  my $id = shift || die;

  die if not $ACIS::Web::ACIS;
  my $app = $ACIS::Web::ACIS;
  my $sql = $app -> sql_object() || die;

  $sql -> prepare( "select shortid from records where id=?" );
  my $res = $sql -> execute( $id );
  if ( $res and $res -> {row} ) {
    return $res -> {row} ->{shortid};
  }
  return undef;
}


sub min_useful_similarity() {
  if ( not $ACIS::Web::ACIS ) {
    die "no acis object, can't access the configuration\n";
  } else {
    my $useful = $ACIS::Web::ACIS->config( 'citation-document-similarity-useful-threshold' ) || die;
    return ( $useful * 100 );
  }
}

sub coauthor_suggestion_similarity { 85; }       # XXX should be configurable?
sub preidentified_suggestion_similarity { 85; }  # XXX should be configurable?


use POSIX qw(strftime);
sub today() {
  strftime '%F', localtime( time );
}


sub cid ($) {
  my $citation = $_[0] || die;
  return $citation->{srcdocsid} . '-' . $citation->{checksum};     #QQQQQ 
}


sub select_citations_sql {
  my $acis = shift || die;
  my $rdbname = $acis->config( 'metadata-db-name' );
  return "SELECT citations.*,res.id as srcdocid,res.title as srcdoctitle,res.authors as srcdocauthors,res.urlabout as srcdocurlabout 
  FROM citations INNER JOIN $rdbname.resources as res ON res.sid=citations.srcdocsid ";
}  


sub load_citation_details {
  my $cit = shift || die;

  die if not $ACIS::Web::ACIS;
  my $app = $ACIS::Web::ACIS;
  my $sql = $app -> sql_object() || die;
  my $select_citations = select_citations_sql( $app );
  $sql -> prepare( "$select_citations where srcdocsid=? and checksum=?" );
  my $r = $sql -> execute( $cit->{srcdocsid}, $cit->{checksum} );
  if ( $r and $r->{row} ) {
    foreach ( qw( ostring srcdocid srcdoctitle srcdocauthors srcdocurlabout ) ) {    
      $cit->{$_} = Encode::decode_utf8( $r->{row}{$_} );
      #QQQQQ convert ->{checksum} and ->{srcdocsid} into ->{lcid}
    }
    return 1;
  }
  return undef;
}


sub identify_citation_to_doc($$$) {
  my ( $rec, $dsid, $citation ) = @_;
  delete $citation->{reason};
  delete $citation->{time};

  my $citations   = $rec->{citations}        ||= {};
  my $cidentified = $citations->{identified} ||= {};
  my $doclist     = $cidentified->{$dsid}    ||= [];

  warn "no srcdocsid!" if not $citation->{srcdocsid}; #QQQQQ
  warn "no checksum!"  if not $citation->{checksum}; #QQQQQ
  return if not $citation->{srcdocsid} or not $citation->{checksum};#QQQQQ

  my $cid = $citation->{srcdocsid} . '-' . $citation->{checksum}; #QQQQQ

  ### be careful not to add an already identified citation
  foreach ( @$doclist ) {
    my $_cid = $_->{srcdocsid} . '-' . $_->{checksum};#QQQQQ
    if ( $_cid eq $cid ) {
      # citation is already identified; overwrite it
      warn "citation $cid is already identified for $dsid";
      $_ = $citation;
      return;
    }
  }

  if ( not $citation -> {srcdocid} 
       or not $citation ->{srcdoctitle} ) {
    load_citation_details( $citation );
  }

  push @$doclist, $citation;
  debug "added citation $cid to identified for $dsid";
  my $note;
  my $maybeauto = '';
  if ( exists $citation->{autoaddreason} ) {
    $maybeauto = 'auto';
#    $note = 'autoaddreason: $citation->{autoaddreason}';
  }
  #QQQQQ:
  cit_event( $citation->{srcdocsid}, $citation->{checksum}, $rec->{sid}, $dsid, "${maybeauto}added", $citation->{autoaddreason}, $note );
}



sub unidentify_citation_from_doc_by_cid($$$) {
  my ( $rec, $dsid, $cid ) = @_;
  
  my $citations   = $rec->{citations}    ||= {};
  my $cidentified = $citations->{identified} ||= {};
  my $clist       = $cidentified->{$dsid} ||= [];

  my $cit;
  for ( @$clist ) {
    if ( cid $_ eq $cid ) {
      $cit = $_;
      undef $_;
      last;
    }
  }
  
  clear_undefined $clist;
  if ( not scalar @$clist ) {
    delete $cidentified->{$dsid};
  }
  #QQQQQ:
  cit_event( $cit->{srcdocsid}, $cit->{checksum}, $rec->{sid}, $dsid, "unidentified" );
  return $cit;
}



sub refuse_citation($$) {
  my ( $rec, $citation ) = @_;
  delete $citation->{reason};
  delete $citation->{time};

  my $cid = $citation->{srcdocsid} . '-' . $citation->{checksum};#QQQQQ

  my $citations = $rec->{citations}     ||= {};
  my $refused   = $citations->{refused} ||= [];
  ### TODO: be careful not to add an already refused citation
  push @$refused, $citation;

  debug "refused citation $cid";
    #QQQQQ:
  cit_event( $citation->{srcdocsid}, $citation->{checksum}, $rec->{sid}, undef, "refused" );
}


sub unrefuse_citation_by_cid($$) {
  my ( $rec, $cid ) = @_;
  my $citation;

  my $ref = $rec->{citations}{refused} ||= [];
  foreach ( @$ref ) {
    if ( $cid eq cid $_ ) {
      $citation = $_;
      undef $_;
    }
  }
  clear_undefined $ref;

  if ( $citation ) {
    debug "unrefused citation $cid";
    #QQQQQ
    cit_event( $citation->{srcdocsid}, $citation->{checksum}, $rec->{sid}, undef, "unrefused" );
  }

  return $citation;
}


my $bell;  # YYY potentially a problem for long-running persistent environments
sub time_to_recompare_cit_doc($) {  # XXX Optimize it? A possible bottleneck.
  my ($lts) = shift; # last time string

  require Date::Manip;
  if ( not $bell ) { 
    die if not $ACIS::Web::ACIS;
    my $app = $ACIS::Web::ACIS;
    my $ttl = $app-> config( 'citation-document-similarity-ttl' ) || die;
    $bell = Date::Manip::DateCalc( "today", "- $ttl days" ) || die;
  }
  my $sdate = Date::Manip::ParseDate( $lts );
  if ( Date::Manip::Date_Cmp( $sdate, $bell ) < 0 ) {
    return 1;
  } 
  return 0;  
}


1;
