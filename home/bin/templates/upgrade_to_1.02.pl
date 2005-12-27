
use strict;
use warnings;

use ACIS::Web;
#use sql_helper;


#####  MAIN PART  

my $ACIS = ACIS::Web -> new( home => $homedir );

my $sql = $ACIS -> sql_object;

$sql -> prepare( 
"ALTER TABLE records ADD COLUMN homepage char(130) binary not null default ''" );
$sql -> execute;


