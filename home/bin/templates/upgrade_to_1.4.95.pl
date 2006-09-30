
use strict;
use warnings;

use ACIS::Web;


#####  MAIN PART  

my $ACIS = ACIS::Web -> new( home => $homedir );
my $sql = $ACIS -> sql_object;

my @alters = (
  "ALTER TABLE events MODIFY COLUMN packed mediumblob",              
);

print "please wait while we upgrade the database structure...\n";

foreach ( @alters ) {
  $sql -> prepare( $_ );
  $sql -> execute;
}

print "upgrade done!\n";
