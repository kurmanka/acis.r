
use sql_helper;
use ACIS::Web;

# $Web::App::DEBUGIMMEDIATELY = "on";
# $Web::App::DEBUG            = "on"; 

my $user = shift || die "give a user name";


my $ACIS = ACIS::Web -> new( home => $homedir );

use ACIS::Web::Admin;


ACIS::Web::Admin::userdata_offline_reload_contributions 
( $ACIS, $user );
