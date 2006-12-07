



use strict;
use warnings;
use ACIS::Web;

#####  MAIN PART  
my $ACIS = ACIS::Web -> new( home => $homedir );
my $sql = $ACIS -> sql_object;
my $RDB = $ACIS -> config( 'metadata-db-name' );

my @q = (

qq!alter table $RDB.resources modify authors TEXT!,
qq!alter table $RDB.resources drop index title_i!,

);

print "please wait while we upgrade the database...\n";

foreach ( @q ) {
  $sql -> prepare( $_ );
  print " $_\n";
  $sql -> execute;
}

print "upgrade done.\n";
