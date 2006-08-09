package ACIS::Citations::AutoUpdate;

use strict;
use warnings;

use Carp;
use Carp::Assert;
use Web::App::Common;

use ACIS::Citations::Utils;
use ACIS::Citations::Search qw( personal_search_by_names 
                                personal_search_by_documents 
                                personal_search_by_coauthors );
use ACIS::Citations::SimMatrix qw( load_similarity_matrix );
use Web::App::Email;
use ACIS::Web::SysProfile;

sub auto_processing {
  my $acis = shift || die;

  my $pretend = shift; # XXX

  my $session = $acis -> session || die;
  my $vars    = $acis -> variables;
  my $rec     = $session -> current_record || die; 
  my $id      = $rec ->{id};
  my $sid     = $rec ->{sid};
  my $sql     = $acis -> sql_object || die;

  debug "id: ", $rec->{id};

  my $mat   = load_similarity_matrix( $rec->{sid} );
  
  $mat -> upgrade( $acis, $rec );
  $mat -> run_maintenance( $pretend );

  my $add_by_doc    = personal_search_by_documents( $rec, $mat, $pretend ) || [];
  my $add_by_names  = personal_search_by_names(     $rec, $mat, $pretend ) || [];
  my $add_by_coauth = personal_search_by_coauthors( $rec, $mat, $pretend ) || [];

  if ( scalar @$add_by_doc 
       or scalar @$add_by_names
       or scalar @$add_by_coauth ) {

    debug "by doc: ",    scalar @$add_by_doc;
    debug "by names: ",  scalar @$add_by_names;
    debug "by coauth: ", scalar @$add_by_coauth;

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
      my $dsid = $_->[0] || die;
      my $cita = $_->[1] || die;

      debug "about to add to doc $dsid citation ". cid $cita;
      
      my $dhash = $dsids->{$dsid};
      my $dcl;
      if ( $dhash ) {
        $dcl = $dhash->{citations};
      } else {
        my $d = $dsindex->{$dsid};
        if ( not $d ) {
          debug "no document, sid:$dsid";
          $dcl = undef;
          next;
        } 
        $dhash = $dsids->{$dsid} = { %$d };
        if ( !$dhash->{title} ) { debug "no title in doc!, sid:$dsid"; $dcl=undef; next; }        
        $dcl = $dhash ->{citations} = [];
        push @docs, $dhash;
      } 
      push @$dcl, $cita;
    }
    $vars->{'docs-w-cit'}   = \@docs;

    require ACIS::Web::SaveProfile;
    ACIS::Web::SaveProfile::save_profile( $acis );

    my %params = ();
    my $echoapu = $acis -> config( "echo-apu-mails" );
    if ( not defined $echoapu ) {
      $echoapu =  $acis -> config( "echo-arpu-mails" );
    }
    if ( $echoapu ) {
      $params{-bcc} = $acis -> config( "admin-email" );
    }

    if ( $pretend ) {
      $params{-to} =  $acis -> config( "admin-email" );
      undef $params{-bcc};
      $params{'-pretend-mode'} = 'yes';
    }
    
    require Web::App::Email;
    Web::App::Email::send_mail( $acis, "email/citations-auto-profile-update.xsl", %params );
    debug "email sent";

    foreach ( qw( docs-w-cit ) ) {
      delete $vars -> {$_};
    }
    
  }

  put_sysprof_value( $sid, "last-auto-citations-time", time )
    if not $pretend;

}



1;
