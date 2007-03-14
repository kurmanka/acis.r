
use strict;
use warnings;

use Carp::Assert;

use ACIS::Web;
use sql_helper;


#####  MAIN PART  

my $acis = ACIS::Web -> new( home => $homedir );
my $sql = $acis->sql_object;



my $owner = { login => $0 };
$owner -> {'IP'} = '0.0.0.0';
  
my $session = $acis -> start_session( "magic", $owner );
assert( $acis ->session );


$sql -> prepare( "select login,userdata_file from users" );
my $r = $sql -> execute();


require ACIS::Web::Admin;

while( $r->{row} ) {
  my $udf   = $r->{row} {'userdata_file'};
  my $login = $r->{row} {login};
  
  if ( $udf and -r $udf ) {
    $acis -> update_paths_for_login( $login );
    assert( $acis->session, "no session in acis object 1" );
    my $userdata = ACIS::Web::Admin::get_hands_on_userdata( $acis );
    assert( $acis->session, "no session in acis object 2" );
    if ( not $userdata ) { next; }
    $session -> object_set( $userdata );
    assert( $acis->session, "no session in acis object 3" );

    ###  do maintenance
    require ACIS::Web::SaveProfile;
    ACIS::Web::SaveProfile::save_profile( $acis );
    print "$login\n";
  }

} continue {
  $r -> next;
}

###  close session
$session -> close( $acis );
  

