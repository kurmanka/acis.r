package ACIS::Citations::AutoUpdate;

use strict;
use warnings;

use Carp;
use Carp::Assert;
use Web::App::Common;

use ACIS::Citations::Search qw( personal_search_by_names personal_search_by_documents );
use ACIS::Citations::SimMatrix qw( load_similarity_matrix );
use Web::App::Email;
use ACIS::Web::SysProfile;

sub processing {
  my $acis = shift || die;

  my $session = $acis -> session || die;
  my $vars    = $acis -> variables;
  my $rec     = $session -> current_record || die; 
  my $id      = $rec ->{id};
  my $sid     = $rec ->{sid};
  my $sql     = $acis -> sql_object || die;

  debug "id: ", $rec->{id};

  my $mat   = load_similarity_matrix( $rec->{sid} );
  
  $mat -> upgrade( $acis, $rec );
  $mat -> run_maintenance();

  my $add_by_doc    = personal_search_by_documents( $rec, $mat ) || [];
  my $add_by_names  = personal_search_by_names( $rec, $mat )     || [];
  my $add_by_coauth = personal_search_by_coauthors( $rec, $mat ) || [];

  if ( scalar @$add_by_doc 
       or scalar @$add_by_names
       or scalar @$add_by_coauth ) {

    my $dsindex = {};
    foreach ( @{$rec->{contributions}{accepted}} ) {
      if ($_->{sid}) { $dsindex->{$_->{sid}} = $_; }
    }

    my $dsids = {};
    my @docs  = [];
    
    # Make a list: [ document1, document2, ... ]; where each
    # document is a usual document hash with a "citations"
    # element added. The "citations" element points to the
    # list of added citations.
    foreach ( @$add_by_doc, @$add_by_names, @$add_by_coauth ) {
      ref $_ || die;
      my $ds = $_->[0] || die;
      my $c  = $_->[1] || die;
      
      my $dh = $dsids->{$ds};
      my $dcl;
      if ( $dh ) {
        $dcl = $dh->{citations};
      } else {
        my $d = $dsindex->{$ds};
        $dh = $dsids->{$ds} = { %$d };
        $dcl = $dh ->{citations} = [];
        push @docs, $dh;
      } 
      push @$dcl, $c;
    }
    $vars->{'docs-w-cit'}   = \@docs;

    require ACIS::Web::SaveProfile;
    ACIS::Web::SaveProfile::save_profile( $acis );

    my %params = ();
    my $echoapu = $app -> config( "echo-apu-mails" );
    if ( not defined $echoapu ) {
      $echoapu =  $app -> config( "echo-arpu-mails" );
    }
    if ( $echoapu ) {
      $params{-bcc} = $app -> config( "admin-email" );
    }
    
    $acis -> send_mail( "email/citations-auto-profile-update.xsl", %params );

    foreach ( qw( doc-w-cit ) ) {
      delete $vars -> {$_};
    }
    
  }

  put_sysprof_value( $sid, "last-auto-citations-time", time );

  # XXX TODO: Add citations profile maintenance
  
}



1;
