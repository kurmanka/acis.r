
use strict;
use warnings;

use sql_helper;
use ACIS::User;
use ACIS::Web;
use ACIS::Web::Admin;

my $login = shift || die "give me a login\n";

my $acis = ACIS::Web -> new( home => $homedir );


# original rmrec way:
if (0) {
  ###  get hands on the userdata (if possible),
  ###  create a session and then do the work
  ACIS::Web::Admin::offline_userdata_service($acis, $login, 'ACIS::User::delete_current_account', 'admin' );
}

# original remove_account.pl way:
if (1) {
  #$Web::App::DEBUGIMMEDIATELY = "on";
  $Web::App::DEBUG            = "on"; 

  ACIS::User::remove_account($acis, -login => $login);
}


1;
