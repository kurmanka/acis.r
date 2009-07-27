package ACIS::Resources::Learn::Refused;

use strict;
use warnings;
use Data::Dumper;
use Carp::Assert;
use sql_helper;
use ACIS::Web;
use Web::App::Common;
use Storable;
use ACIS::Resources::Learn;

require ACIS::APU;
require ACIS::APU::Queue;


#####  MAIN PART  
##my $homedir='/home/awho/acis';
##my $acis = ACIS::Web -> new( home => $homedir );


##my $to_do='pkr1';

##&sort_refused($acis,$to_do);

# the log file, a global variable
my $log_file_name='';


sub sort_refused {
  my $acis=shift;
  my $to_do=shift;
  $log_file_name=$acis->{'config'}->{'homedir'}.'/opt/log/sort_refused_sql.log';
  # set up sql object
  my $db_name=$acis->{'config'}->{'db-name'};
  my $db_user=$acis->{'config'}->{'db-user'};
  my $db_pass=$acis->{'config'}->{'admin-access-pass'};
  sql_helper -> set_log_filename ( $log_file_name);
  my $sql = sql_helper -> new( $db_name, 
                               $db_user,
                               $db_pass);
  my $login=ACIS::APU::get_login_from_queue_item($sql,$to_do);
  if(not $login) {
    &log("no login for $to_do");
    return;
  }
  &log("found login: $login");

  require ACIS::Web::Admin;
  my $apply_learning = sub { 

    my $app = $_[0];
    
    my $record = $app -> session -> current_record;
    if(not $record) {
      &log('no record');
    }
    my $psid = $record -> {'sid'};
    my $refused  = $record ->{'contributions'} -> {'refused'};
    if(not $refused ) {
      &log("no refused contributions");
      return 1;
    }
    my $accepted  = $record ->{'contributions'} -> {'accepted'};
    if(not $accepted ) {
      &log("no accepted contributions");
      return 1;
    }
    my $refused_sorted=&learn_all_refused($accepted,$refused,$psid);
    if(ref($refused_sorted)) {
      my $out=Dumper $refused_sorted;
      &log("$out");
      $refused=$refused_sorted;
    }
    else {
      &log("learn all refused returned false");
    }
    return 1;
  };
  my $res;
  eval {
    #  get hands on the userdata (if possible),
    #  create a session and then do the work    
    $res = ACIS::Web::Admin::offline_userdata_service( $acis, $login, $apply_learning) || 'FAIL';    
    &log($@);
    &log($res);
  }
}


#
# wrapper to test all refused documents
#
sub learn_all_refused {
  my $accepted=shift;
  my $refused=shift;
  # person short id, only used for logging purposes
  my $psid=shift;
  &log(Dumper $refused);
  # call the main learning
  my $suggested=&ACIS::Resources::Learn::learn_via_svm($accepted,$refused);
  if(not defined($suggested)) {
    &log("learn_via_svm returned false");
    return;
  }
  if(not ref($suggested)) {
    &log($suggested)
  }
  return $suggested;
}


sub log {
  my $message = join '', @_;
  if(not $message) {
    return;
  }
  my $date = localtime time;
  open  LOG, '>>:utf8', $log_file_name
    or die "Can't open log file $log_file_name: $!\n";
  print LOG $date, " [$$] ", $message, "\n"; 
  close LOG;
}

# cheers!
1;
