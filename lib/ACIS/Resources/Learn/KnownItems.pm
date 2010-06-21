package ACIS::Resources::Learn::KnownItems;

use strict;
use warnings;
use Data::Dumper;
use Carp::Assert;
use sql_helper;
use ACIS::Web;
use Web::App::Common;
use Storable;
use ACIS::Resources::Learn qw(form_learner learn_via_svm);

require ACIS::APU;
require ACIS::APU::Queue;

## part of cardiff

sub learn_known {
  my $acis=shift;
  my $to_do=shift;
  my $time=time();
  my $log_file_name=$acis->{'config'}->{'homedir'}."/opt/log/learn_known_items.$time.log";
  my $debug=0;
  if($debug) {
    print "opening $log_file_name\n";
  }
  ## set up sql object
  my $db_name=$acis->{'config'}->{'db-name'};
  my $db_user=$acis->{'config'}->{'db-user'};
  my $db_pass=$acis->{'config'}->{'admin-access-pass'};
  sql_helper -> set_log_filename ( $log_file_name);
  my $sql = sql_helper -> new( $db_name, 
                               $db_user,
                               $db_pass);
  my $login=ACIS::APU::get_login_from_queue_item($sql,$to_do);
  if(not $login) {
    if($debug) {
      &log_it($log_file_name,"no login for $to_do");
    }
    return;
  }
  if($debug) {
    &log_it($log_file_name,"found login: $login");
  }
  
  require ACIS::Web::Admin;
  ## define the function applied to the session
  my $apply_learning = sub { 
    my $app = $_[0];
    ## returns a referece if successful, a message on 
    ## failure
    my $learned=&learn_all_known($app,$sql,'debug');
    if(not ref($learned)) {
      if($debug) {
        &log_it($log_file_name,$learned);
      }
   ## return fail to the caller 
      return;
    }
    ## here we can could see the learning result 
    if($debug) {
      # log_it($learner);
    }
    ## return succes 
    return 1;
  };
  my $res;
  eval {
    ##  get hands on the userdata (if possible),
    ##  create a session and then do the work    
    ## LOG OUT OF ACIS before testing!!
    my $res = ACIS::Web::Admin::offline_userdata_service( $acis, $login, $apply_learning) || 'FAIL';    
    if($debug) {
      &log_it($log_file_name,$@);
    }
    if($debug) {
      &log_it($log_file_name,$res);
    }
  };
}

## wrapper to learn all accpted and refused items
sub learn_all_known {
  my $app=shift;
  my $sql=shift;
  my $debug=shift;
  ## set debug to be true
  if(not defined($debug)) {
    ###$debug=1;
  }
  my $learner=&form_learner($app,'learn_all_known',$debug);
  #print Dumper $learner;
  ## call the main learning
  my $learned;
  my $refused;
  my $accepted;
  foreach my $what_to_learn ('accepted','refused') {
    ## from ACIS/Resources/Learn.pm
    my $learned=&learn_via_svm($learner,$what_to_learn,'debug');
    if(not(ref($learned))) {      
      return "in learn_all_know, when learning $what_to_learn learn_via_svm returned: $learned\n";
      next;
    }
    ## the sort function
    my $sort_function;
    ## refused documents are shown highest to lowest relevance 
    if($what_to_learn eq 'refused') {
      $sort_function= sub {$b->{'relevance'} <=> $a->{'relevance'}};
    }
    ## accepted documents are shown lowest to highest relevance 
    if($what_to_learn eq 'accepted') {
      $sort_function= sub {$a->{'relevance'} <=> $b->{'relevance'}};
    }
    my @sorted_docs=sort $sort_function @{$learned};
    my $count_docs=$#sorted_docs;
    for(my $count=0; $count <= $count_docs; $count++) {
      if(not defined($learned->[$count])) {
        return "fatal error in learn_all_known: docment $count is not defined!";
      }
      ## I am sure there is an more compact way, sigh!
      if($what_to_learn eq 'refused')  {
        $refused->[$count]=$sorted_docs[$count];        
      }
      if($what_to_learn eq 'accepted')  {
        $accepted->[$count]=$sorted_docs[$count];
      }
    }
  }
  ## now set the variables
  my $session = $app -> session;
  my $record  = $session -> current_record;
  if(ref($accepted)) {
    $record->{'contributions'}->{'accepted'}=$accepted;
  }
  if(ref($refused)) {
    $record->{'contributions'}->{'refused'}=$refused;
  }
  return $record->{'contributions'};
}


sub log_it {
  my $log_file_name=shift;
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
