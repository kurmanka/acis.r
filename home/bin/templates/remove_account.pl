use strict;
use warnings;
use sql_helper;
use ACIS::Web;
use ACIS::Web::Admin;

#$Web::App::DEBUGIMMEDIATELY = "on";
$Web::App::DEBUG            = "on"; 

my $login = shift || die "give a login\n";

my $acis = ACIS::Web -> new( home => $homedir );

ACIS::Web::Admin::remove_account($acis, -login => $login, -clean=> 1);
