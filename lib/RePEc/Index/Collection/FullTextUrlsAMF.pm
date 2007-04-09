package RePEc::Index::Collection::FullTextUrlsAMF;

use strict;
use base qw( RePEc::Index::Collection::AMF );
require RePEc::Index::Collection;

use AMF::Parser;
use ACIS::FullTextURLs::List;
# see also: ACIS::FullTextURLs::Input

sub extract_fulltext_urls ($) {
  my $text = shift;
  my $id     = $text ->get_value('REF');
  my @fuauth = $text ->get_value('file/url');
  my @fuauto = $text ->get_value('hasversion/file/url');
  return ACIS::FullTextURLs::List::create( $id, \@fuauth, \@fuauto );
}

sub get_next_record {
  my $self = shift;
  while ( my $r = amf_get_next_noun ) {
    my $id = $r ->ref;
    my $ul = extract_fulltext_urls( $r );
    if ( not $id or not $ul ) { next }
    my $start = 0;
    my $md5  = $ul ->md5checksum;
    return( $ul->id, $ul, $ul->type, $start, $md5 );
  } 
  return undef;
}

sub check_id {
  return 1;
}

sub make_monitor_file_checker { 
  return sub { 
    if ( m/\.amf\.xml$/i ) {  return 1; }
    else { return 0; }
  }
}


1;

