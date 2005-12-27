package ACIS::Web::Events;

use strict;

use Exporter;
use Carp::Assert;
use Encode;

use Web::App::Common;


use vars qw( @EXPORT @ISA );

@ISA = ( 'Exporter' );
@EXPORT = qw( 
             make_event_from_db_row 
             dates_near date_add_one_day 
             date_add_one_second
            );


my @events_fields_all = qw( date type class action descr data chain startend packed );
my $events_unicode_fields = {
                             descr => 1, 
                             data  => 1,
#                             class => 1 
};

sub make_event_from_db_row ($) {
  my $row = shift;
  assert( $row );

  foreach ( @events_fields_all ) {
    my $ov = $row ->{$_};
    my $rv = $ov;
    if ( not $ov ) { delete $row->{$_}; next; }
    if ( $_ eq 'descr' or $_ eq 'data' ) {
      $row->{$_} = decode( 'utf8', $ov );
    }
  }

  my $data = $row->{data};
  if ( $data ) {
    my @att = split "\n", $data;
    foreach ( @att ) {
      my ( $at, $v ) = split ( ": ", $_ );
      $row->{$at} = $v;
    }
#    delete $row ->{data};
  }

  return $row;
}








###
###   DATES
###

sub dates_near ($$$) { 
  my $sql   = shift;
  my $date1 = shift; 
  my $date2 = shift || die; ### date2 assumed to be later than date1

  if ( $date1 eq $date2 ) {
    return 1;
  }
  
  my $st = "select ( ? - INTERVAL 1 MINUTE ) < ? as close";
  $sql -> prepare_cached( $st );
  my $r = $sql -> execute( $date2, $date1 );

  if ( $r ) {
    return $r -> {row} {close};
  }
  return undef;
}


sub date_add_one_day ($$) {
  my $sql  = shift;
  my $date = shift || die;
  
  my ( $y, $m, $d ) = split( '-', $date );
  for ( 1 ) {
    if ( $d < 28 ) { $d++; last; }
    if ( $m != 2 and $d <30 ) { $d++; last; }

    $sql -> prepare( "select ('$y-$m-$d' + INTERVAL 1 DAY) as day" );
    my $r = $sql->execute();
    if ( $r and $r->{row} ) {
      return $r->{row}{day};
    }
    return undef;
  }
  return sprintf( '%04d-%02d-%02d', $y, $m, $d );
}


sub date_add_one_second ($$) {
  my $sql  = shift;
  my $date = shift || die;
  
  my ( $day, $h, $m, $s ) = 
    ( $date =~ /^(\d+\-\d+\-\d+) (\d{2}):(\d{2}):(\d{2})$/ );

  for ( 1 ) {
    if ( $s < 59 ) { $s++; last; }
    if ( $m < 59 ) { $m++; last; }
    if ( $h < 23 ) { $h++; last; }

    $sql -> prepare( "select ('$date' + INTERVAL 1 SECOND) as time" );
    my $r = $sql->execute();
    if ( $r and $r->{row} ) {
      return $r->{row}{time};
    }
    return undef;
  }
  return sprintf( '%s %02d:%02d:%02d', $day, $h, $m, $s );
}




1;
