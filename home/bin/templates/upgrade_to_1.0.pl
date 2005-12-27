
use strict;
use warnings;

use Carp::Assert;

use ACIS::Web;
use sql_helper;


#####  MAIN PART  

my $ACIS = ACIS::Web -> new( home => $homedir );

BEGIN { $Web::App::DEBUG = "on"; }

my $sql = $ACIS -> sql_object;

$sql -> prepare( "ALTER TABLE events ADD packed BLOB" );
$sql -> execute;

$sql -> prepare( 
"update events set packed=descr, descr=NULL where length(descr) > 200 and startend=1"
);
$sql -> execute;

$sql -> do( 
"update events set startend=-1 where class='session' and startend=0"
);

$sql -> do( 
"update events set startend=0 where length(chain) > 0 and startend is null"
);

