use strict;
use warnings;

#####  MAIN PART
use ACIS::Web;

my $ACIS = ACIS::Web -> new();
my $sql = $ACIS -> sql_object;

# Add the timestamp column to the resources, objects and institutions
# tables. 
#
# It is first added with DEFAULT 0 to make sure the initial value that
# is written into the existing records in the table is
# "0000-00-00". When we later transform it to 'DEFAULT
# CURRENT_TIMESTAMP', any subsequently inserted records would get the
# current time (date) in the column.
#
# This column is basically managed by MySQL: it would automatically
# keep the timestamp dates current on all stored records in the tables
# that have this column. And then if a record does not get an update
# in a while, we would find it by looking at this column's value. And
# kill it.
#
# See also: home/bin/templates/sanitar_timestamp_based.pl
# (bin/sanitar_timestamp_based.pl on an installed system).

#  the SQL to run
my @q = (
    qq! 
      alter table events 
      modify column chain char(32) CHARACTER SET ascii    !
    ,qq!
      alter table session_history 
      modify column sessionid char(32) CHARACTER SET ascii !
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
