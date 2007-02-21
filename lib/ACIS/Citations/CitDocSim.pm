package ACIS::Citations::CitDocSim;

use strict;
use Data::Dumper; # for debuggings

use Web::App::Common;
use ACIS::Citations::Suggestions qw( get_cit_doc_similarity store_cit_doc_similarity );
use ACIS::Citations::Utils;

use base qw( Exporter );
use Exporter;
use vars qw( @EXPORT );
@EXPORT = qw( make_docs compare_citation_to_docs compare_citation_to_doc );

sub make_docs ($) {
  my $rec = shift || die;
  my $docs = {};
  
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
  return $docs;
}


sub compare_citation_to_docs {
  my $cit  = shift || die;
  my $docs = shift || die;
  my $flag = shift || '';  # can be: 'includezero'
  
  my @res;
  debug "compare_citation_do_docs()";
  debug "documents: ", join ' ', keys %$docs;

  die if not $ACIS::Web::ACIS;
  my $acis = $ACIS::Web::ACIS;
  my $sql  = $acis -> sql_object;

  my $func = $acis->config( 'citation-document-similarity-func' ) 
    || 'ACIS::Citations::Utils::cit_document_similarity';

  debug "will use similarity function: $func";

  my $cnid = $cit->{cnid} || die "citation must have numeric non-zero cnid";

  my $sims = {};
  while ( my( $dsid, $doc ) = each %$docs ) {
    debug "comparing to $dsid (", $doc->{title}, ")";
    my ($similarity,$t) = get_cit_doc_similarity( $cnid, $dsid );
    
    if ( $t 
         and ACIS::Citations::Utils::time_to_recompare_cit_doc( $t ) ) {
      debug "similarity from db: $similarity, but it is outdated; recompare";
      undef $similarity;
    }

    if ( defined $similarity and $t ) {
      debug "similarity from db: $similarity";
      
    } else {
      # compare, run similarity function
      if ( not $cit->{nstring} ) { $cit->{nstring} = make_citation_nstring( $cit->{ostring} ); }
      no strict 'refs';
      $similarity = sprintf( '%u', &{$func}( $cit, $doc ) * 100 );
      debug "similarity computed: $similarity";
      store_cit_doc_similarity( $cnid, $dsid, $similarity );
    }
    $sims->{$dsid} = $similarity;
  }

  my @d = keys %$sims;
  @d = sort { $sims->{$b} <=> $sims->{$a} } @d;
  if ( $flag ne 'includezero' ) {
    @d = grep { $sims->{$_} } @d;
  }
  @res = map { $_ => $sims->{$_} } @d;

  return \@res; ### ref to a list ( dsid, simnumber, dsid, simnumber, ... )
}


sub compare_citation_to_doc($$) {
  my $cit = shift || die;
  my $doc = shift || die;
  my $dsid = $doc->{sid} || die;

  die if not $ACIS::Web::ACIS;
  my $acis = $ACIS::Web::ACIS;
  my $func = $acis -> config( 'citation-document-similarity-func' ) 
    || 'ACIS::Citations::Utils::cit_document_similarity';
  
  my $similarity;
  {
    no strict 'refs';
    $similarity = sprintf( '%u', &{$func}( $cit, $doc ) * 100 );
  }
  debug "similarity computed: $similarity";
  store_cit_doc_similarity( $cit->{cnid}, $dsid, $similarity );
  return $similarity;
}






1;
