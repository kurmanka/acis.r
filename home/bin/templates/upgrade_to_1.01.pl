
use strict;
use warnings;

use Carp::Assert;

use ACIS::Web;
use sql_helper;


#####  MAIN PART  

my $ACIS = ACIS::Web -> new( home => $homedir );

my $sql = $ACIS -> sql_object;

$sql -> prepare( "ALTER TABLE records DROP COLUMN brief" );
$sql -> execute;

$sql -> prepare( 
"ALTER TABLE records ADD COLUMN emailmd5 char(16) binary not null default ''" );
$sql -> execute;

$sql -> prepare( 
"ALTER TABLE records ADD INDEX emailmd5_i ( emailmd5 )"
);
$sql -> execute;

