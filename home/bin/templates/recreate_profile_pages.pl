use strict;
use warnings;
use Carp::Assert;
use ACIS::Web;
use sql_helper;
use Data::Dumper;


## supported switches:
## a  --> do all users
## find  --> lists the queue, does notthing else


## get $acis object, prepare a session
my $acis = ACIS::Web -> new( home => $homedir );
my $sql = $acis->sql_object;

## work on arguments
my $switches = {};
my $queue = [];
my $count_argv=0;
foreach my $arg ( @ARGV ) {
  ## examine for swiches
  $count_argv++;
  if($arg=~m!^-(\w.*)! ){
    $switches->{$1}=1; 
    next; 
  }
  if($arg=~m!^--(\w*)! ) { 
    $switches->{$1}=1; 
    next; 
  }
  ## default: try find the profile and add it to a queue
  ## this will exit if nothing can be found
  push @$queue, get_profile_details( $arg );
}
if(not $count_argv) {
  print "fatal: no argument\n";
  exit;
}
if ( $switches->{'a'} ) {
  $sql -> prepare( "select login,userdata_file from users" );
  my $r = $sql -> execute();
  push @$queue, @{$r->data};
}


require ACIS::Web::Admin;

## prepare a session
my $session = $acis -> start_session( "magic", { login => $0, IP => '0.0.0.0' } );
assert( $acis ->session );

foreach my $p (@{$queue})  {
  my $udf   = $p -> {'userdata_file'};
  my $login = $p -> {'login'};
  ## find will just list the profiles
  if ($switches->{'find'}) {
    print "u file: $udf\t\tlogin: $login\n";
    next;
  }  
  if( not $udf or not -r $udf ) {
    print "could not open user data file '$udf'\n";
    next;
  }
  $acis -> update_paths_for_login( $login );
  my $userdata = ACIS::Web::Admin::get_hands_on_userdata( $acis );
  if( not $userdata ) { 
    print "could not get my hand use userdata for $login\n";
    next; 
  }
  $session -> object_set( $userdata );
  # do things
  require ACIS::Web::SaveProfile;
  ACIS::Web::SaveProfile::save_profile( $acis );
  print "data for $login saved  in $udf\n";
}


##  close session
if(defined($session)) {
  $session -> close( $acis );
}  

## was
#sub get_profile_details($) {
sub get_profile_details {
  my $in = shift;
  my $where = '';
  my @params;
  ## case of a login /email
  if($in=~m!\w\@[\w\-\.]+\.\w+! ) { 
    $where = 'login=?';
    push @params, $in;
  }
  ## case of a shortid
  elsif ($in=~m!^p\w+\d+! ) { 
    ## we have to look it up in the records first
    $sql->prepare( "select owner from records where shortid=?" );
    my $r = $sql->execute($in);
    if($r->rows == 0) {
      print "fatal: shortid '$in' not found.\n";
      exit;
    }
    $where = $r->{'row'}->{'owner'};
    push @params, $where;
  } 
  else {
    print "what is this: '$in'?\n";
  }
  $sql->prepare( "select login,userdata_file from users where login=?" );
  my $r = $sql->execute( @params );
  if($r->rows == 0) {
    print "login for '$in' not found.\n";
    if($in=~s|\.xml$||) {      
      print "I am trying again without the .xml\n";
      return &get_profile_details($in);
    }
    else {
      print "fatal: login for '$in' not found.\n";
      exit;
    }
  }  
  return $r->{'row'};
}
