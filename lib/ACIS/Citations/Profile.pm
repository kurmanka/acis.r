package ACIS::Citations::Profile;

use strict;
use warnings;

use Carp;
use Carp::Assert;

use ACIS::Web::SysProfile;

use ACIS::Citations::Utils qw( today );

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






1;

