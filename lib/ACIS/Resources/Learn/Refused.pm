package ACIS::Resources::Learn::Refused;

use strict;
use warnings;
use AI::Categorizer::Learner::NaiveBayes;
use AI::Categorizer::Document;
use AI::Categorizer::KnowledgeSet;
use AI::Categorizer;

#use Lingua::StopWords;
#use AI::Categorizer::Learner::SVM;
#use AI::Categorizer::Learner::KNN;
#use AI::Categorizer::Learner::DecisionTree;
#use AI::Categorizer::Learner::Guesser;
use Data::Dumper;
use Carp::Assert;
use sql_helper;
use ACIS::Web;
use Web::App::Common;
use Storable;

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
  &log("founnd login: $login");

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
      return 1;
    }
    my $accepted  = $record ->{'contributions'} -> {'accepted'};
    if(not $accepted ) {
      return 1;
    }
    &learn_all_refused($refused,$accepted,$psid) ;
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
  my $refused=shift;
  my $accepted=shift;
  # person short id, only used for logging purposes
  my $psid=shift;
  clear_undefined $refused;
  clear_undefined $accepted;
  my @refused_docs=@{$refused};
  my $count_refused=$#refused_docs;
  @refused_docs=();
  my @accepted_docs=@{$accepted};
  my $count_accepted=$#accepted_docs;
  @accepted_docs=();
  # make sure it's worth proceeding
  if($count_refused < 1 and $count_accepted > 0) {
    return;
  }
  my $test_count;
  my $result;
  my $data;
  foreach my $count_to_learn (0..$count_refused) {
    my $score=&learn_one_document($refused,$accepted,$count_to_learn);
    &log("$psid doc #$count_to_learn scores $score");
      push (@{$result->{$score}},$count_to_learn);
  }
  my $docs_sorted;
  my $docs_count;
  &log("$psid start sorting");
  foreach my $number (sort {$b <=> $a} keys %{$result}) {
    foreach my $doc_number (@{$result->{$number}}) {
      push(@{$docs_sorted},$refused->[$doc_number]);
    }    
  }
  &log("$psid end sorting");
  #print Dumper $docs_sorted;  
  for(my $count=0; $count < $count_refused; $count++) {
    $refused->[$count]=$docs_sorted->[$count];
  }
  my $out=Dumper $refused;
  &log($out);
  clear_undefined $refused;
}

#
# finds the score of one document
#
sub learn_one_document {
  my $refused=shift;
  my $accepted=shift;
  my $number=shift;
  my @accepted_docs=@{$accepted};
  my @refused_docs=@{$refused};
  my $accepted_docs=\@accepted_docs;
  my $test_doc=splice(@refused_docs,$number,1);
  my $test_sid=$test_doc->{'sid'};
  if(not $test_sid) {
    return 0;
  }
  my $refused_docs=\@refused_docs;
  my $k;
  eval {
    $k=new AI::Categorizer::KnowledgeSet();
  };
  &log($@);
  #print Dumper $k;
  #print "form documnents...\n";
  &form_documents($accepted_docs,'accepted',$k);
  #print "form documnents...\n";
  &form_documents($refused_docs,'refused',$k);
  my $nb = new AI::Categorizer::Learner::NaiveBayes();
  #print "train\n";
  $nb->train(knowledge_set => $k);
  #print "trained\n";
  #print Dumper $test_doc;
  my $test=form_document($test_doc);
  my $hypothesis;
  eval {
    $hypothesis=$nb->categorize($test);
  } ;
  &log($@);
  my $score = $hypothesis->scores('accepted');
  $k={};
  undef($k);
  $nb={};
  undef($nb);
  return $score;
}


sub form_documents {
  my $in=shift;
  my $state=shift;
  my $k=shift;
  my $my_category =  eval {
    AI::Categorizer::Category->new(name => $state);
  };
  &log($@);
  my $category=[$my_category];
  foreach my $doc (@{$in}) {
    if(not defined($doc->{'sid'})) {
      next;
    }
    my $d=form_document($doc,$category) ;
    eval {
      $k->add_document($d);
    };
    &log($@);
    $d={};
    undef($d);
  }
}
  

sub form_document {
  my $doc=shift ;
  my $category=shift or undef;
  my $sid=$doc->{'sid'};
  #print "sid is $sid\n";
  # Simplest way to create a document:
  my $authors= lc($doc->{'authors'});
  my $title= lc($doc->{'title'});
  my $d;
  if($category) {
    eval {
      $d = new AI::Categorizer::Document(name => $sid,
                                         categories => $category,
                                         content => { authors => $authors,
                                                      title => $title},
                                         content_weights => { authors => 1,
                                                              title => 1}
                                         #stopwords => Lingua::StopWords::getStopWords('en'),
                                         #stemming => 'porter',
                                        );
    };    
    &log($@);
  }
  else {
    # leave out the category
    eval {
      $d = new AI::Categorizer::Document(name => $sid,
                                         content => { authors => $authors,
                                                      title => $title},
                                         content_weights => { authors => 1,
                                                              title => 1}
                                         #stopwords => Lingua::StopWords::getStopWords('en'),
                                         #stemming => 'porter',
                                        );
    };    
    &log($@);
  }
  return $d;
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
