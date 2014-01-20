
use strict;
use warnings;

print "starting ", scalar localtime, "\n";

use Scalar::Util qw( blessed );

use ACIS::Web;
use ACIS::Sessions;
use ACIS::Web::UserPassword;

my $acis = ACIS::Web-> new( home => $homedir );

ACIS::Sessions::cleanup();

ACIS::Web::UserPassword::cleanup_tokens( $acis );

