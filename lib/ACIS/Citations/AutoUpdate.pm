package ACIS::Citations::AutoUpdate;

use strict;
use warnings;

use Carp;
use Carp::Assert;
use Web::App::Common;
require Web::App::Email;

use ACIS::Citations::Utils;
use ACIS::Citations::Search qw( personal_search_by_names 
                                personal_search_by_documents 
                                personal_search_by_coauthors );
use ACIS::Citations::Profile;
use ACIS::Web::SysProfile;
use ACIS::APU qw(&logit);

sub auto_processing {
  my $acis = shift || die;

  my $session = $acis -> session || die;
  my $vars    = $acis -> variables;
  my $rec     = $session -> current_record || die; 
  my $id      = $rec ->{id};
  my $sid     = $rec ->{sid};
  my $sql     = $acis -> sql_object || die;

  debug "id: ", $rec->{id};

  logit "citations auto processing for ", $rec->{sid};

  my $now = time;
  {
    my $abstinence_days = 3;  # profile maintenance doesn't have to be carried out too often
    my $abstinence_seconds = 60*60*24* $abstinence_days;
    # profile check and cleanup, i.e. maintentance
    my $last = get_sysprof_value( $rec->{sid}, 'last-cit-prof-check-time' );
    if ( not $last 
         or ($last < $now - $abstinence_seconds ) ) {  # a while ago?
      logit "profile check and cleanup";
      ACIS::Citations::Profile::profile_check_and_cleanup();
    }
  }

  $session -> {'citations-auto-search-found'} = 0;
  $session -> {'citations-auto-search-limit'} = $acis->config('apu-citations-auto-add-limit');

  my $add_by_doc    = personal_search_by_documents( $rec ) || [];
  my $add_by_names  = personal_search_by_names(     $rec ) || [];
  my $add_by_coauth = personal_search_by_coauthors( $rec ) || [];

  if ( scalar @$add_by_doc 
       or scalar @$add_by_names
       or scalar @$add_by_coauth ) {

    debug "by doc: ",    scalar @$add_by_doc;
    debug "by names: ",  scalar @$add_by_names;
    debug "by coauth: ", scalar @$add_by_coauth;
    logit "by doc: ",    scalar @$add_by_doc;
    logit "by names: ",  scalar @$add_by_names;
    logit "by coauth: ", scalar @$add_by_coauth;

    my $dsindex = {};
    foreach ( @{$rec->{contributions}{accepted}} ) {
      if ($_->{sid}) { $dsindex->{$_->{sid}} = $_; }
    }

    my $dsids = {};
    my @docs  = ();
    
    # Make a list: [ document1, document2, ... ]; where each
    # document is a usual document hash with a "citations"
    # element added. The "citations" element points to the
    # list of added citations.
    foreach ( @$add_by_doc, @$add_by_names, @$add_by_coauth ) {
      ref $_ || die;
      my $dsid = $_->[0] || die;
      my $cita = $_->[1] || die;

      debug "about to add to doc $dsid citation ". $cita->{cnid};
      
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
  
    if ( $acis->config( "citations-profile" ) 
         and not $acis->config( "disable-citation-mails" ) ) {

      my %params = ();
      my $echoapu = $acis -> config( "echo-apu-mails" );
      if ( not defined $echoapu ) {
        $echoapu =  $acis -> config( "echo-arpu-mails" );
      }
      if ( $acis->config( "test-citations" ) ) {
        $params{-to} = $acis -> config( "admin-email" );
      } elsif ( $echoapu ) {
        $params{-bcc} = $acis -> config( "admin-email" );
      }
      
      require Web::App::Email;
      Web::App::Email::send_mail( $acis, "email/citations-auto-profile-update.xsl", %params );
      debug "email sent";
      logit "email sent";
    }

    foreach ( qw( docs-w-cit ) ) {
      delete $vars -> {$_};
    }
    
  }

  put_sysprof_value( $sid, "last-auto-citations-time", time );
  put_sysprof_value( $sid, "last-auto-citations-date", today );
}



1;
