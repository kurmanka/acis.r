package ARDB::ObjectDB;

# This is a module, which will be responsible for storing and loading
# the metadata objects into/from the objects table in Mysql, using Storable.

use strict;

use Carp::Assert;

use Storable qw( thaw freeze );

sub store_record {
  my $sql = $ARDB::ARDB -> sql_object;
  my $rec = shift;
  my $id  = shift;

  $sql -> prepare_cached( "replace into objects values ( ?, ? )" );

  my $data;
  if ( $rec ) {
    $data = freeze( $rec );
  }

  my $r = $sql -> execute( $id, $data );
  return (not $sql -> error);
}


sub retrieve_record {
  my $id   = shift;
  assert( $id );

  my $rec;
  my $sql = $ARDB::ARDB -> sql_object;

  $sql -> prepare_cached( "select data from objects where id = ?" );
  my $r = $sql -> execute( $id );
  
  if ( not $sql->error and $r ) {
    my $data = $r -> {row} {data};
    if ( $data ) {
      $rec  = thaw $data;
    }
  }

  return $rec;
}


sub delete_record {
  my $id   = shift;
  assert( $id );

  my $sql = $ARDB::ARDB -> sql_object;
  $sql -> prepare_cached( "delete from objects where id=?" );
  return $sql -> execute( $id );
}


1;

