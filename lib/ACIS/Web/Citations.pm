package ACIS::Web::Citations;

use strict;
use warnings;
use Carp::Assert;

use Web::App::Common;

use ACIS::Citations::Utils;
use ACIS::Citations::Suggestions;
use ACIS::Citations::SimMatrix qw( load_similarity_matrix );
use ACIS::Citations::Search;


my $acis;
my $sql;

sub prepare() {
  $acis = $ACIS::Web::ACIS;
  $sql  = $acis -> sql_object;
}

sub acis_citations_enabled() {
  prepare() if not $acis;
  return $acis->config( 'citations-profile' );
}

sub prepare_potential {
  shift;
  die "citations not enabled system-wide" if not acis_citations_enabled;

  my $dsid = shift || $acis->{request}{subscreen};
  if ( !$dsid ) {
    die "no document sid to show citations for";
    return;
  }

  my $session = $acis -> session;
  my $vars    = $acis -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};

  my $document;
  foreach ( @{ $record->{contributions}{accepted} } ) {
    if ( $_->{sid} eq $dsid ) { 
      $document = $_;
    }    
  }
  
  die "can't find that document: $dsid" if not $document;

  my $mat = $session ->{simmatrix} ||= load_similarity_matrix( $sid );
#  my $mat = $session ->{simmatrix} ||= load_similarity_matrix( 'ptestsid0' ); # XXXXXXXX
  my $citations_new = $mat->{new}{$dsid};
  my $citations_old = $mat->{old}{$dsid};

  $vars -> {document} = $document;
  $vars -> {potential_new} = $citations_new;
  $vars -> {potential_old} = $citations_old;

  # XXX is this the most interesting document?

  # XXX find / prepare previous and next document

#  $acis -> dump_presenter_xml;
#  undef $acis->{presenter};

  foreach ( qw( citation-document-similarity-preselect-threshold ) ) {
    $acis->variables->{$_} = $acis->config( $_ ) * 100;
  }

#  $citations_new->[1]->{similar} = 80;
#  my $cid = $citations_new->[0]->{srcdocsid} . '-' . $citations_new->[0]->{checksum};
#  $vars->{'preselect-citations'} = [ $cid ];

  return;
  
}


sub process_potential {

  
  
}


1;
