package ACIS::Citations::Utils;

use strict;
use warnings;
use Carp::Assert;

use Exporter;

use base qw( Exporter );
use vars qw( @EXPORT_OK );

@EXPORT_OK = qw( normalize_string build_citations_index
                 get_document_authors get_author_sid );


use Unicode::Normalize;
use Web::App::Common;


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

sub build_citations_index($;$) {
  my ( $citlist, $index ) = @_;
  $index ||= {};
  
  foreach (@$citlist) {
    my $key = $_->{srcdocsid} . '-' . $_->{checksum};
    $index ->{$key} = $_;
  }
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
  my $authornamelist = [ split /\s+/, $authornames ];

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
    # XXX
    return 0;
  }
  

  # Find where in the citation string the first word of the
  # title is present.

  my @titlewords = split /\s+/, $ntitle;
  
  if ( scalar @titlewords < 2 ) {
    debug "one word title? ", $ntitle; 
    # XXX
    return 0;
  }
  
  my $first = $titlewords[0];
  while ( length( $first ) < 2 ) {
    shift @titlewords;
    $first .= ' ' . $titlewords[0];
  }
  debug "first word of the document's title is: '$first'";
  
  my $startpos = index $nstring, $first;
  debug "citation has title starting at: $startpos";

  if ($startpos) {
    # now compare
    my $cittitle = substr $nstring, $startpos, length( $ntitle );
    $result = similarity $ntitle, $cittitle;

  } else {
    debug "the title's begining was not found in the nstring; how do we compare?";
    # XXX

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
  my $id = shift;

  die if not $ACIS::Web::ACIS;
  my $app = $ACIS::Web::ACIS;

  my $sql = $app -> sql_object() || die;

  $sql -> prepare( "select shortid from records where id=?" );
  my $res = $sql -> execute( $id );
  if ( $res -> {row} and $res -> {row} ) {
    return $res -> {row} ->{id};
  }
  return undef;
}

1;
