use strict;
use warnings;

#####  MAIN PART
use ACIS::Web;

my $ACIS = ACIS::Web -> new();
my $sql = $ACIS -> sql_object;

#  the SQL to run
my @q = (
  qq!
     ALTER TABLE reset_token MODIFY COLUMN created TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP 
  !,
#  qq!!,
);

print "we upgrade the database...\n";

use Data::Dumper;
foreach ( @q ) {
  $sql -> prepare( $_ );
  print "  $_\n";
  my $r = $sql -> execute;
  if ($r) {
    print "  - result: modified ", $r->rows, " rows\n";
  }
  if ($sql->error) {
    print "  - error: " , $sql->error, "\n";
    last;
  }
}

print "upgrade done.\n";
