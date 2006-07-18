package ACIS::Citations::AutoUpdate;

use strict;
use warnings;

use Carp;
use Carp::Assert;
use Web::App::Common;

use ACIS::Citations::Search qw( personal_search_by_names personal_search_by_documents );
use ACIS::Citations::SimMatrix qw( load_similarity_matrix );
use Web::App::Email;

sub processing {
  my $acis = shift || die;

  my $session = $acis -> session || die;
  my $vars    = $acis -> variables;
  my $rec     = $session -> current_record || die; 
  my $id      = $rec ->{id};
  my $sid     = $rec ->{sid};
  my $sql     = $acis -> sql_object || die;

  debug "id: ", $rec->{id};

  my $names = $rec->{contributions}{autosearch}{'names-list'} || die;
  my $mat   = load_similarity_matrix( $rec->{sid} );
  
  $mat -> upgrade( $acis, $rec );
  $mat -> run_maintenance();

  my $add_by_doc   = personal_search_by_documents( $rec, $mat ) || [];
  my $add_by_names = personal_search_by_names( $rec, $mat )     || [];

  if ( scalar @$add_by_doc 
       or scalar @$add_by_names ) {
    $vars->{'research-accepted'} = $rec->{contributions}{accepted};
    $vars->{'add-by-doc'}   = $add_by_doc;
    $vars->{'add-by-names'} = $add_by_names;

    my %doc_sids;
    my @docs = [];
    # XXXX
    # make a list: [ [document, citation1, citation2, ...], [], ];

    # XXX citations added through co-authors
    
    $acis -> send_mail( "email/citations-auto-profile-update.xsl" );
  }
  
}


1;
