
use strict;
use warnings;

print "starting ", scalar localtime, "\n";

use Scalar::Util qw( blessed );

use ACIS::Web;
use ACIS::Sessions;

my $acis = ACIS::Web-> new( home => $homedir );

ACIS::Sessions::cleanup();
