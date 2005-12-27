
use sql_helper;
use ACIS::Web;

my $ACIS = ACIS::Web -> new( home => $homedir );

my $sql = $ACIS -> sql_object;

my $db = $ACIS -> config( "db-name" );

$sql -> prepare( "select id,shortid,owner from records" );

my $r = $sql -> execute;

use Encode;

if ( $r and not $sql -> error ) {

  while ( $r -> {row} ) {
    my $row = $r -> {row};
    my $id  = lc $row -> {id};
    my $sid = lc $row -> {shortid};
    my $ema = $row -> {owner};

    print "$ema\t$id\t$sid\n";

    $r -> next;
  }

} else {
  print STDERR "NO RECORDS FOUND OR AN ERROR: ", $sql->error, "\n";

}

