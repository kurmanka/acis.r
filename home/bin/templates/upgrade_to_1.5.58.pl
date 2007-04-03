
use strict;
use warnings;
use ACIS::Web;

#####  MAIN PART
my $ACIS = ACIS::Web -> new();
my $sql = $ACIS -> sql_object;
my $RDB = $ACIS -> config( 'metadata-db-name' );

my @q = (
  qq!alter table citations add srcdocsid CHAR(15) NOT NULL DEFAULT ''!,
  qq!update citations set srcdocsid=substring_index(clid,'-',1)!,
);

print "please wait while we upgrade the database...\n";

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
