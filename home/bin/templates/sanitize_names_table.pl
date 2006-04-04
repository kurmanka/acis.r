
use Carp::Assert;

use sql_helper;

use warnings;

require ACIS::Web;


my $acis = ACIS::Web -> new( homedir => $homedir );
assert( $acis );

my $sql = $acis -> sql_object;

$sql -> prepare( "select shortid from names group by shortid" );
my $res = $sql -> execute( );

my $count = 0;
my $remove;

while ( $res and $res->{row} ) {
  my $sid = $res ->{row}{shortid};
  undef $remove;

  if ( $sid =~ /^p[a-z]+\d+$/ ) {
  } else { 
    print "bad shortid: $sid\n";
    $remove = 1;
  }

  ### no check sid validity
  my $id;
  $sql -> prepare( "select id from records where shortid=?" );
  my $r = $sql -> execute( $sid );
  if ( $r ) {
    $id = $r->{row}{id};
  }

  if ( $id and not $remove ) {
#    print ".";
  } else {
    print "$sid\n";
    $sql -> prepare( "delete from names where shortid=?");
    $sql -> execute( $sid );
    $sql -> prepare( "delete from sysprof where id=?" );
    $sql -> execute( $sid );
    $sql -> prepare( "delete from suggestions where psid=?" );
    $sql -> execute( $sid );
    $sql -> prepare( "delete from threads where psid=?" );
    $sql -> execute( $sid );

    $count ++;
  }
} continue {
  $res -> next;
}

print "records cleared: $count\n";
