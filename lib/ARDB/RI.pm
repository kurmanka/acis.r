package ARDB::RI;

use Carp::Assert;

use Events;

require ARDB::Local;


my $ardb = ARDB -> new();
assert( $ardb );


sub process_record {
  shift;

  my $id     = shift;
  my $type   = shift;
  my $record = shift;
  
  assert( $record );
  assert( $ardb );

  $ardb -> put_record ( $record );
}


sub delete_record {
  shift;

  my $id = shift;

  assert( $ardb );
  assert( $id );

#  my $rec = $ardb -> get_record( $id ) ;
#  if ( $rec ) {
    $ardb -> delete_record ( $id );
#  }
}

1;
