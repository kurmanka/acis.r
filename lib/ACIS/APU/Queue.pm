package ACIS::APU::Queue;

use strict;
use Web::App::Common;

use Exporter;
use base 'Exporter';
use vars qw( @EXPORT );
@EXPORT = qw( fill_the_queue_table 
              get_next_queued_item
              get_next_failed_queued_item
              set_item_processing_result 
              clear_the_queue_table
              enqueue_item );


my $Qtable = "apu_queue";


# all functions get sql_helper instance as their first parameter

sub fill_the_queue_table {
  my $sql = shift;

  my @q = ( 
 qq!INSERT INTO $Qtable (what, position)
  SELECT r.shortid as what, 1 as position
    FROM records as r
      LEFT JOIN sysprof as s 
        ON s.id = r.shortid AND s.param = 'last-apu-time'
    WHERE s.data is NULL and r.shortid<>''!,
qq!INSERT IGNORE INTO $Qtable (what, position)
  SELECT id as what,(data+1) as position
    FROM sysprof 
    WHERE (param='last-autosearch-time' or param='last-auto-citations-time')
    ORDER BY data+1 ASC ! );

  foreach ( @q ) {
    $sql -> do( $_ );
  }
}

sub get_next_queued_item {
  my $sql = shift;
  my $q = qq! SELECT what,class from $Qtable WHERE status=''  ORDER BY position ASC, filed ASC LIMIT 1 !;
  $sql -> prepare_cached( $q ); 
  my $r = $sql -> execute( );
  if ($r and $r->{row}) {
    return( $r->{row}{what}, $r->{row}{class} );
  }
  return undef;
}

sub get_next_failed_queued_item {
  my $sql = shift;
  my $q = qq! SELECT what,class from $Qtable WHERE status='fail' ORDER BY position ASC, filed ASC LIMIT 1 !;
  $sql -> prepare_cached( $q ); 
  my $r = $sql -> execute( );
  if ($r and $r->{row}) {
    return( $r->{row}{what}, $r->{row}{class} );
  }
  return undef;
}

sub set_item_processing_result {
  my $sql = shift    || die;
  my $what = shift   || die;
  my $status = shift || die;
  my $notes  = shift;
  my $q = qq!UPDATE $Qtable SET status=?,notes=?,worked=NOW() WHERE what=?!;
  $sql -> prepare_cached( $q ); 
  my $r = $sql -> execute( $status, $notes, $what );
  return $r;
}

sub clear_the_queue_table {
  my $sql = shift || die;
  my $q = qq! delete from $Qtable WHERE status<>'' and status is not null !;
  return $sql -> do( $q );
}

sub enqueue_item {
  my $sql    = shift || die;
  my $what   = shift || die;
  my $class  = shift || '';
  my $position = shift || 0;
  my $q = qq!REPLACE INTO $Qtable (what,class,position) VALUES (?,?,?) !;
  $sql -> prepare_cached( $q ); 
  my $r = $sql -> execute( $what, $class, $position );
  return $r;
}


sub testme {
  require ACIS::Web;
  my $acis = ACIS::Web->new();
  my $sql = $acis-> sql_object();
  $sql->{verbose_log} = 1;

  print "clear the queue table: ",
    clear_the_queue_table( $sql );
  print "\n";

  print "fill the queue table: ",
    fill_the_queue_table( $sql );
  print "\n";

  my ($item, $class) = get_next_queued_item( $sql );
  print "next item: $item ($class)\n";

  set_item_processing_result( $sql, $item, 'done' );
  
  ($item, $class) = get_next_queued_item( $sql );
  print "next item: $item ($class)\n";

  print "enqueue new item\n";
  ($item, $class) = enqueue_item( $sql, 'newitem' );

  ($item, $class) = get_next_queued_item( $sql );
  print "next item: $item ($class)\n";

}






1;
