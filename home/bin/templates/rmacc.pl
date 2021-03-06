
use strict;
use warnings;

use sql_helper;
use ACIS::User;
use ACIS::Web;
use ACIS::Web::Admin;

my $login = shift || die "give me a login\n";

my $acis = ACIS::Web -> new( home => $homedir );

$Web::App::DEBUGIMMEDIATELY = "on";
$Web::App::DEBUG            = "on"; 

# original rmrec way:
# this is safer: will fail in case a user has a running session.
if (1) {
  ###  get hands on the userdata (if possible),
  ###  create a session and then do the work
  ACIS::Web::Admin::offline_userdata_service($acis, $login, 'ACIS::User::delete_current_account', undef, 'admin' );
}

# original remove_account.pl way:
# this is harder; will just remove the account, 
# no checks for an existing session
# (hmm, and an account may actually survive this deletion, i guess; not checked)
if (0) {
  ACIS::User::remove_account($acis, -login => $login);
}


1;
