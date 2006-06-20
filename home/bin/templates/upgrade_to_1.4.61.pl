
use strict;
use warnings;

use ACIS::Web;


#####  MAIN PART  

my $ACIS = ACIS::Web -> new( home => $homedir );
my $sql = $ACIS -> sql_object;
my $db  = $ACIS -> config( 'metadata-db-name' );
my $restable = "$db.resources";

my @alters = (
  "ALTER TABLE $restable CHANGE id id CHAR(255) NOT NULL",
  "ALTER TABLE $restable CHANGE sid sid CHAR(15) NOT NULL",
  "ALTER TABLE $restable ADD COLUMN location TEXT" 
);

foreach ( @alters ) {
  $sql -> prepare( $_ );
  $sql -> execute;
}
