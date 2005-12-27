
use Carp::Assert;

use sql_helper;
use ACIS::Web;

use warnings;

require ACIS::Web::Admin::Events;
require ACIS::Web::Admin::EventsArchiving;

#####  MAIN PART  

my $task = shift @ARGV;

my $ACIS = ACIS::Web -> new( home => $homedir );

BEGIN { $Web::App::DEBUG = "on"; }
#BEGIN { $Web::App::DEBUGIMMEDIATELY = "on"; }

ACIS::Web::Admin::EventsArchiving::archiving_run( $ACIS, 5000 );
#ACIS::Web::Admin::EventsArchiving::archive_screen( $ACIS );

