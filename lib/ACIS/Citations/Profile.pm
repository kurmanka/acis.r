package ACIS::Citations::Profile;

use strict;
use warnings;
use Carp;
use Carp::Assert;

use ACIS::Web::SysProfile;
use ACIS::Citations::Utils qw( today load_citation_details );


use Web::App::Common;

sub profile_check_and_cleanup () {
  my $acis   = $ACIS::Web::ACIS;

  my $record = $acis -> session->current_record;
  if ( not $record->{citations} ) { return undef; }
       
#  return undef if not $acis->config( 'citations-profile' );
  
  debug "citations profile_check_and_cleanup()";

  my $psid   = $record->{sid} || die;
  my $sql    = $acis -> sql_object;
  my $citations         = $record ->{citations};
  my $research_accepted = $record ->{contributions}{accepted} || [];
  my $identified = $citations ->{identified} || {};

  my $dsids = {};
  foreach ( @$research_accepted ) {
    if ( $_->{sid} ) {
      $dsids ->{$_->{sid}} = 1;
    }
  }

  $sql -> prepare_cached( 'select cnid from citations where cnid=?' );

  # make sure the document is still in research accepted and the citation is still in the citations table
  foreach ( keys %$identified ) {
    if ( not $dsids->{$_} ) {
      # cleanup
      delete $identified->{$_};
      debug "delete citations for $_";
      next;
    }

    my $cits = $identified->{$_};
    foreach (@$cits) {
      if ( not $_->{cnid} ) {
        undef $_;
        debug "citation with no id; delete";
        next;
      }
      
      my $id = $_->{cnid};
      my $r = $sql->execute( $id );
  
      if ( $r and $r->{row} and $r->{row}{cnid} ) {
        # ok 
      } elsif ( $r )  {
        undef $_;
        debug "citation $id is not found anymore";
        #$_->{notfound} = scalar localtime;
        next;
      } else {
        complain "can't check a citation: no result from execute()";
        last;
      }

      # if the citation's source document is not in the document
      # database anymore, the citation would be gone from the citations
      # table.  Citations::Input would do that, I believe.  Or
      # maybe RePEc::Index::Collection::CitationsAMF

      if ( not $_->{srcdoctitle} or not $_->{srcdocid} ) {
        # this would mean the citation hash is incomplete
        # this shouldn't happen to any recently added citations, but
        # I'll leave it here for a while for extra care
        if ( not load_citation_details( $_ ) ) {
          undef $_;
          debug "delete citation $id (can't find source doc details)";
          next;
        }
      }

      delete $_->{srcdocsid};
      delete $_->{checksum};
      delete $_->{nstring};
      delete $_->{similar};
      delete $_->{reason};
      delete $_->{new};
      delete $_->{citid};
      delete $_->{clid};
      delete $_->{trgdocid} if not defined $_->{trgdocid};
    }
    clear_undefined $cits;

    if ( not scalar @$cits ) { 
      delete $identified->{$_};
    }
  }

  update_refused();

  # mark in sysprof
  put_sysprof_value( $psid, 'last-cit-prof-check-date', today );
  put_sysprof_value( $psid, 'last-cit-prof-check-time', time );
}


sub update_refused {
  my $acis   = $ACIS::Web::ACIS;
  my $record = $acis -> session->current_record;
  if ( not $record->{citations} ) { return undef; }
      
  debug "citations update_refused()";

  my $psid   = $record->{sid} || die;
  my $sql    = $acis -> sql_object;
  my $citations         = $record ->{citations};
  my $research_accepted = $record ->{contributions}{accepted} || [];
  my $refused = $citations ->{refused} || [];

  $sql -> prepare_cached( 'select cnid from citations where cnid=?' );

  foreach (@$refused) {
    if (not $_->{cnid}) {
      undef $_;
      next;
    }

    my $id = $_->{cnid};
    my $r = $sql->execute($id);

    if ( $r and $r->{row} and $r->{row}{cnid} ) {
      # ok
    } elsif ( $r )  {
      undef $_;
      debug "delete refused citation $id (it is gone)";
      next;
    } else {
      die "can't check a citation: no result from execute()";
    }
    
    delete $_->{srcdocsid};
    delete $_->{checksum};
    delete $_->{nstring};
    delete $_->{similar};
    delete $_->{reason};
    delete $_->{new};
    delete $_->{citid};
    delete $_->{clid};
    delete $_->{trgdocid} if not defined $_->{trgdocid};
  }
  clear_undefined $refused;
}



1;

