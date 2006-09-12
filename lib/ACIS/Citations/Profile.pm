package ACIS::Citations::Profile;

use strict;
use warnings;

use Carp;
use Carp::Assert;

use ACIS::Web::SysProfile;

use ACIS::Citations::Utils qw( today cid );

sub last_cit_search_date($;$) {
  my ( $psid, $update ) = @_;
  if ( $update ) {
    put_sysprof_value( $psid, 'last-cit-search-date', today );
    put_sysprof_value( $psid, 'last-cit-search-time', time );

  } else {
    my $d = get_sysprof_value( $psid, 'last-cit-search-date' );
    my $t = get_sysprof_value( $psid, 'last-cit-search-time' );
    return ( $d, $t );
  }
}

sub last_cit_sug_maintenance_date($;$) {
  my ( $psid, $update ) = @_;
  if ( $update ) {
    put_sysprof_value( $psid, 'last-cit-sug-maintenance-date', today );
    put_sysprof_value( $psid, 'last-cit-sug-maintenance-time', time );

  } else {
    my $d = get_sysprof_value( $psid, 'last-cit-sug-maintenance-date' );
    my $t = get_sysprof_value( $psid, 'last-cit-sug-maintenance-time' );
    return ( $d, $t );
  }
}


use Web::App::Common;

sub profile_check_and_cleanup () {

  my $acis   = $ACIS::Web::ACIS;
  return undef
    if not $acis->config( 'citations-profile' );
  
  debug "citations profile_check_and_cleanup()";

  my $record = $acis -> session->current_record;
  my $sql    = $acis -> sql_object;
  my $citations         = $record ->{citations} ||= {};
  my $research_accepted = $record ->{contributions}{accepted} || [];
  my $identified = $citations ->{identified};

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
    $sql -> prepare_cached( "select srcdocsid from citations where srcdocsid=? and checksum=?" );
    my $cits = $identified->{$_};
    foreach (@$cits) {
      my $r = $sql->execute( $_->{srcdocsid}, $_->{checksum} );
      if ( $r and $r->{row} and $r->{row}{srcdocsid} ) {
        # ok
      } elsif ( $r )  {
        undef $_;
        debug "delete citation $_->{srcdocsid}-$_->{checksum}";
      } else {
        debug "can't check a citation: no result from execute()";
      }
    }
    clear_undefined $cits;
    if ( not scalar @$cits ) { 
      delete $identified->{$_};
    }
  }
  
}

sub potential_check_and_cleanup () {
  # have we already done that in SimMatrix? Check.

  # do a global check and clean-up via SQL join operation?
  # We can use join to find which rows in cit_suggestions
  # don't have a corresponding record in the citations table
}

1;

