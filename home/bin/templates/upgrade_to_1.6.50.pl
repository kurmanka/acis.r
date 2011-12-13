use strict;
use warnings;

#####  MAIN PART
require ARDB;
require ARDB::Local;

my $ARDB = ARDB -> new() or die;
my $sql = $ARDB -> sql_object;

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
alter table objects
   add column timestamp TIMESTAMP default 0 on update CURRENT_TIMESTAMP !,
    qq!
alter table objects
  modify column timestamp TIMESTAMP 
    default CURRENT_TIMESTAMP 
    on update CURRENT_TIMESTAMP !,

    qq!
alter table resources
   add column timestamp TIMESTAMP default 0 on update CURRENT_TIMESTAMP !,
    qq!
alter table resources
  modify column timestamp TIMESTAMP 
    default CURRENT_TIMESTAMP 
    on update CURRENT_TIMESTAMP !,

    qq!
alter table institutions
   add column timestamp TIMESTAMP default 0 on update CURRENT_TIMESTAMP !,
    qq!
alter table institutions
  modify column timestamp TIMESTAMP 
    default CURRENT_TIMESTAMP 
    on update CURRENT_TIMESTAMP !,

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
