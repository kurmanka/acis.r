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

  # make sure the document is still in research accepted and the citation is still in the citations table
  foreach ( keys %$identified ) {
    if ( not $dsids->{$_} ) {
      # cleanup
      delete $identified->{$_};
      debug "delete citations for $_";
      next;
    }

    my $a_cit = $identified->{$_}->[0];
    my $q; 
    # XXX this is a backwards-compatible upgrade code; should be
    # removed after a while
    # XXX this assumes that all citations here have the same
    # identification in them and thus it reuses the prepared SQL
    # statement
    if ( $a_cit->{srcdocsid} and $a_cit->{checksum} ) {
      $q = 'select cnid from citations where clid=?';
    } elsif ( $a_cit ->{citid} or $a_cit->{cnid} ) {
      $q = 'select cnid from citations where cnid=?';
    } elsif ( $a_cit->{clid} ) {
      $q = 'select cnid from citations where clid=?';
    } else {
      die "how do I upgrade this citations: " . Dumper( $a_cit ) . "?";
    }
    $sql -> prepare_cached( $q );

    my $cits = $identified->{$_};
    foreach (@$cits) {
      my $id;
      # XXX this is a backwards-compatible upgrade code; should be
      # removed after a while
      if ( $_->{srcdocsid} and $_->{checksum} ) {
        $id = $_->{srcdocsid}. '-'. $_->{checksum};
      } elsif ( $_ ->{citid} or $_->{cnid} ) {
        $id = $_->{citid} || $_->{cnid};
      } elsif ( $_->{clid} ) {
        $id = $_->{clid};
      } 
      my $r = $sql->execute( $id );
  
      if ( $r and $r->{row} and $r->{row}{cnid} ) {
        # ok; update cnid
        $_->{cnid} = $r->{row}{cnid};
      } elsif ( $r )  {
        undef $_;
        debug "delete citation $id (it is gone)";
        next;
      } else {
        die "can't check a citation: no result from execute() (q:$q)";
      }

      if ( not $_->{srcdoctitle} or not $_->{srcdocid} ) {
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
      
  debug "citations profile_check_and_cleanup()";

  my $psid   = $record->{sid} || die;
  my $sql    = $acis -> sql_object;
  my $citations         = $record ->{citations};
  my $research_accepted = $record ->{contributions}{accepted} || [];
  my $refused = $citations ->{refused} || [];

  foreach (@$refused) {
    # XXX this is a backwards-compatible citation upgrade code; should
    # be simplified after it is ran for every existing profile; then
    # only cnid should be expected and used.
    my $id;
    my $q;
    if ( $_->{srcdocsid} and $_->{checksum} ) {
      $id = $_->{srcdocsid}. '-'. $_->{checksum};
      $q = 'select cnid from citations where clid=?';
    } elsif ( $_ ->{citid} or $_->{cnid} ) {
      $id = $_->{citid} || $_->{cnid};
      $q = 'select cnid from citations where cnid=?';
    } elsif ( $_->{clid} ) {
      $id = $_->{clid};
      $q = 'select cnid from citations where clid=?';
    } 
    
    $sql -> prepare_cached( $q );
    my $r = $sql->execute( $id );        
    
    if ( $r and $r->{row} and $r->{row}{cnid} ) {
      # ok; update cnid
      $_->{cnid} = $r->{row}{cnid};
    } elsif ( $r )  {
      undef $_;
      debug "delete citation $id (it is gone)";
      next;
    } else {
      die "can't check a citation: no result from execute() (q:$q)";
    }
    
    if ( not $_->{srcdoctitle} or not $_->{srcdocid} ) {
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
  clear_undefined $refused;
}



1;

