
use strict;
use warnings;

use ACIS::Web;


#####  MAIN PART  

my $ACIS = ACIS::Web -> new( home => $homedir );
my $sql = $ACIS -> sql_object;
my $db  = $ACIS -> config( 'metadata-db-name' );
my $restable = "$db.resources";

my @alters = (
  "ALTER TABLE $restable ADD COLUMN authors TEXT NOT NULL",
  "ALTER TABLE $restable ADD COLUMN urlabout TEXT",
  "ALTER TABLE citations DROP COLUMN srcdocdetails",              
  "ALTER TABLE cit_suggestions DROP COLUMN ostring, DROP COLUMN srcdocdetails",              
);

foreach ( @alters ) {
  $sql -> prepare( $_ );
  $sql -> execute;
}
