
use strict;
use warnings;
use Carp::Assert;
use ACIS::Web;
use sql_helper;

sub get_profile_details($);

# get $acis object, prepare a session
my $acis = ACIS::Web -> new( home => $homedir );
my $sql = $acis->sql_object;
my $session = $acis -> start_session( "magic", { login => $0, IP => '0.0.0.0' } );
assert( $acis ->session );

my $switches = {};
my $queue = [];
foreach ( @ARGV ) {
  if ( m!^-(\w.*)! ) { $switches->{$1}=1; next; }
  if ( m!^--(\w*)! ) { $switches->{$1}=1; next; }
  push @$queue, get_profile_details( $_ );
}


if ( $switches->{a} ) {
  $sql -> prepare( "select login,userdata_file from users" );
  my $r = $sql -> execute();
  push @$queue, $r->data;
}

sub get_profile_details($) {
  my $in = shift;
  my $where = '';
  my @params;
  for ($in) {
    if (m!\w\@[\w\-\.]+\.\w+! ) { # login / email
      $where = 'login=?';
      push @params, $_;
      next;
    } elsif (m!^p\w+\d+! ) { # short-id
      warn "do not support shortids yet: $_\n";
    } else {
      warn "what is this: $_?\n";
    }
  }
  if ( $where ) { $where = "where $where"; }
  $sql->prepare( "select login,userdata_file from users $where" );
  my $r = $sql->execute( @params );
  return $r->{row};
}

require ACIS::Web::Admin;

foreach my $p (@$queue)  {
  my $udf   = $p -> {'userdata_file'};
  my $login = $p -> {login};
  
  if ($switches->{qdebug} or $switches->{find}) {
    print "u file: $udf\t\tlogin: $login\n";
    next;
  }
  
  if ( $udf and -r $udf ) {
    $acis -> update_paths_for_login( $login );
    my $userdata = ACIS::Web::Admin::get_hands_on_userdata( $acis );
    if ( not $userdata ) { next; }
    $session -> object_set( $userdata );

    # do things
    require ACIS::Web::SaveProfile;
    ACIS::Web::SaveProfile::save_profile( $acis );
    print "$login\n";
  }
}

###  close session
$session -> close( $acis ) if $session;
  

