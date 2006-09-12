
use Carp::Assert;

use sql_helper;

use warnings;

require ACIS::Web;

my $acis = ACIS::Web -> new( homedir => $homedir );
assert( $acis );

use ACIS::Citations::Profile;

my $cleaned = ACIS::Citations::Profile::potential_check_and_cleanup( $acis );

print "Cleaned: $cleaned\n";
