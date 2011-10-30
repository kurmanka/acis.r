package ARDB::ObjectDB;

# This is a module, which will be responsible for storing and loading
# the metadata objects into/from the objects table in Mysql, using Common::Data

use strict;
use Carp::Assert;

## schmorp
#use Storable qw( thaw nfreeze );
#use Lib32::Decode;
## /schmorp


sub store_record {
  my $sql = $ARDB::ARDB -> sql_object;
  my $rec = shift;
  my $id  = shift;

  $sql -> prepare_cached( "replace into objects (id,data) values ( ?, ? )" );

  my $data;
  if ( $rec ) {
    ## schmorp
    #$data = nfreeze( $rec );
    $data=deflate($rec);
    ## /schmorp
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
      ## schmorp
      # eval thaw
      #$rec  = eval {thaw $data; };
      #if(not $rec) {
      #  $rec=Lib32::Decode::via_daemon($data);
      #  if (not $rec ) { 
      #    warn "decode via daemon failed";
      #    return undef;          
      #  }
      #}
      $rec=inflate($data);
      ## /schmorp
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

