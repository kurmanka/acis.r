use strict;
use warnings;

#####  MAIN PART
use ACIS::Web;
my $ACIS = ACIS::Web -> new();
my $sql = $ACIS -> sql_object;

# the SQL to run

my @q = (
  # The key changes here are the psid size increases up to 32 bytes, 
  # for the new longer session ids to fit in there.
  qq!
     ALTER TABLE threads 
       MODIFY COLUMN psid CHAR(32) CHARACTER SET ASCII NOT NULL
     , MODIFY COLUMN type CHAR(15) CHARACTER SET ASCII NOT NULL
  !,
  qq!
     ALTER TABLE rp_suggestions 
       MODIFY COLUMN psid CHAR(32) CHARACTER SET ASCII NOT NULL
     , MODIFY COLUMN dsid CHAR(15) CHARACTER SET ASCII NOT NULL
     , MODIFY COLUMN role CHAR(15) CHARACTER SET ASCII NOT NULL
     , MODIFY COLUMN reason CHAR(30) CHARACTER SET ASCII NOT NULL
  !,
);

print "we upgrade the database...\n";

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
