use strict;
use vars qw( $acis );
use CGI::Emulate::PSGI;

use ACIS::Web;
use ACIS::Web::AllModules;

$acis = new ACIS::Web();
$acis -> prepare_for_work();

my $app = CGI::Emulate::PSGI->handler(sub {

	eval { $acis -> handle_request; };
	my $err = $@;
	$acis -> clear_after_request;
	if ($err) {die $err;}

});
