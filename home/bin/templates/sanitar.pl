
use Carp::Assert;

use sql_helper;

use warnings;

use RePEc::Index::Reader;

require ARDB;
require ARDB::Local;


my $ardb = ARDB -> new();
assert( $ardb );

my $collections = [ keys %$RePEc::Index::COLLECTIONS ];

assert( scalar @$collections );

my $sql = $ardb -> sql_object;

$sql -> prepare( "select id from objects" );
my $res = $sql -> execute( );

my $count = 0;

while ( $res and $res->{row} ) {
  my $id = $res ->{row}{id};

  my $rec;
  foreach ( @$collections ) {
    eval {
      $rec = RePEc::Index::Reader::get( $_, 'records', $id );
    }; 
    warn $@ if $@;
    if ( $rec ) { last; }
  }

  if ( defined $rec ) {
#    print ".";
  } else {
    print "$id\n";
    $ardb -> delete_record( $id );
    $count ++;
#    if ( $count > 20 ) { die; }
  }
  $res -> next;
}


print "records cleared: $count\n";
