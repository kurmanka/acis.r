package ACIS::Resources::Learn;


use Exporter;
use base qw(Exporter);
use vars qw(@EXPORT @EXPORT_OK);
use File::Temp ();
use Web::App::Common;
use ACIS::Web::Background qw(logit);
use Data::Dumper;
use strict;

# part of cardiff


#
# global variables
#
my $train_bin="/usr/bin/svm-train -q -b 1";
my $predict_bin="/usr/bin/svm-predict -b 1";


## run parameters

my $debug=0;

## should temporary files be deleted?
my $unlink_tmp=0;
if($debug) {
  $unlink_tmp=1;
}


@EXPORT_OK = qw( learn_via_svm form_learner);


## RESTART daemon when changing iths file

##
## general learning function, takes a learner
## and changes relevance key is the elemnet to
## learn about. no sorting. 
sub learn_via_svm {
  my $learner=shift;
  my $what_to_learn=shift;
  ## use global debug parementer in module
  ##my $debug=shift;
  ## switch on debuggin
  if(not defined($debug)) {
    $debug=0;
  }
  $debug=undef;
  ##for debugging, save train file, save time
  my $time=time();
  if($debug) {
    open(DEBUGLOG,"> /tmp/$time.learn");
  }
  ## single_sided indicator
  my $single_sided='';
  my $accepted=$learner->{'accepted'};
  if(not ref($accepted)) {
    return "Error: \$accepted is not a reference.";
  }
  my $count_accepted=scalar @$accepted;
  if(not $count_accepted) {
    ## only refused documents for learning
    $single_sided='refused';
    if($debug) {
      print DEBUGLOG "no accepted documents, single_sided is refused\n";
    }
  }
  if($debug) {
    print DEBUGLOG "count_accepted is $count_accepted.\n";
  }
  my $refused=$learner->{'refused'};
  if(not ref($refused)) {
    return "Error: \$refused is not a reference.";
  }
  my $count_refused=scalar @$refused;
  if(not $count_refused) {
    ## only accepted documents for learning
    $single_sided='accepted';
    if($debug) {
      print DEBUGLOG "no refused documents, single_sided is accepted\n";
    }
  }
  if(not $count_refused and not $count_accepted) {
    return "There are neither refused nor accepeted items, therefore no learning.";
  }
  if($debug) {
    print DEBUGLOG "count_refused is $count_refused\n";
  }
  my $suggested=$learner->{'suggested'};
  ## the variable above may not be defined
  ## when the caller is known_items
  my $count_suggested;
  if(defined($suggested)) {
    $count_suggested=scalar @$suggested;
  }
  else {
    $count_suggested=0;
  }
  if($single_sided and not $count_suggested) {
    return "There can be no single_sided=$single_sided learning with no suggested documents";
  }
  if($debug) {
    print DEBUGLOG "count_suggested is $count_suggested\n";
  }
  ## the target of learning
  my $target;
  ## how many elements in the target
  my $count_target;
  ## indicator of what the start of the line to learn is
  my $start_of_line_to_learn;
  if($what_to_learn eq 'suggested') {
    if($count_suggested < 2) {
      return "$count_suggested is not enough suggested items to learn them";
    }
    $target=$suggested;
    ## the single_sided case 
    if($single_sided eq 'accepted') {
      $count_target=$count_refused;
      $start_of_line_to_learn='-1';
    }
    elsif($single_sided eq 'refused') {
      $count_target=$count_accepted;
      $start_of_line_to_learn='+1';
    }
    else {
      $count_target=$count_suggested;
      $start_of_line_to_learn='0';
    }
  }
  elsif($what_to_learn eq 'refused') {
    $target=$refused;
    $count_target=$count_refused;
    $start_of_line_to_learn='-1';
    if($count_refused < 2) {
      return "$count_refused is not enough suggested items to learn them";
    }
  }
  elsif($what_to_learn eq 'accepted') {
    $target=$accepted;
    $start_of_line_to_learn='+1';
    $count_target=$count_accepted;
    if($count_accepted < 2) {
      return "$count_accepted is not enough accepted items to learn them";
    }
  }
  else {
    return "invalid option for what to learn: $what_to_learn";
  }
  ## build the dataset
  my $data;
  foreach my $doc (@{$accepted}) {
    $data=&add_document_to_data($data,$doc,'+1');
  }
  foreach my $doc (@{$refused}) {
    $data=&add_document_to_data($data,$doc,'-1');
  }
  if($single_sided eq 'accepted') {
    foreach my $doc (@{$suggested}) {
      $data=&add_document_to_data($data,$doc,'-1');
    }
  }
  elsif($single_sided eq 'refused') {
    foreach my $doc (@{$suggested}) {
      $data=&add_document_to_data($data,$doc,'+1');
    }
  }
  else {
    foreach my $doc (@{$suggested}) {
      $data=&add_document_to_data($data,$doc,'0');
    }
  } 
  ## now the document data lines are in $data->{'ds'}
  my @ds=@{$data->{'ds'}}; 
  ## training data for accepted and refused documnet
  my $train_fh = File::Temp->new( UNLINK => $unlink_tmp );
  my $train_file=$train_fh->filename;
  ## the model file stores the results of training
  my $model_fh=File::Temp->new( UNLINK => $unlink_tmp );
  my $model_file=$model_fh->filename();
  ## the test file contains the documents we want 
  ## to learn about
  my $test_fh = File::Temp->new( UNLINK => $unlink_tmp );
  my $test_file=$test_fh->filename; 
  ## create out file, it contains the results
  my $out_fh = File::Temp->new( UNLINK => $unlink_tmp );    
  my $out_file=$out_fh->filename();
  ## write the training and testing files
  foreach my $doc_line (@ds) {
    ## training file, with '+1' and '-1' lines
    if(not $doc_line=~m|^0|) {
      print $train_fh "$doc_line\n";
    }
    ## the \Q and \E are needed for the '+1'
    if($doc_line=~m|^\Q$start_of_line_to_learn\E|) {
      ## replace the +1 or -1 with 0
      ## the indication will probably be ignored but
      ## it is nice to be precise.
      $doc_line=~s|^\Q$start_of_line_to_learn\E|0|;
      print $test_fh "$doc_line\n";
    }
  }
  $train_fh->close;
  $test_fh->close;
  ## create system command to fire up training
  my $s="$train_bin ".$train_fh->filename;
  $s.=" $model_file";
  ## for debuing, keep a copy of the intermediate files
  if(defined($debug)) {    
    $s.="; cp $train_file /tmp/$time.$what_to_learn.train";
    $s.="; cp $model_file /tmp/$time.$what_to_learn.model";
  }
  system($s);
  ## model is now trained, build the testing set
  $s="$predict_bin $test_file $model_file $out_file";
  ## for debuing, keep a copy of the intermediate files
  if(defined($debug)) {
    $s.="; cp $out_file /tmp/$time.$what_to_learn.out";
    $s.="; cp $test_file /tmp/$time.$what_to_learn.test"; 
  }
  ## for the output, REQUIRED
  $s.="; cat $out_file";
  #print "doing: $s\n";
  my $count_to_learn=0;
  ## read output and find the score for earch document
  my $result;
  foreach my $line (`$s`) {
    if(not $line=~m|^[+-]*1|) {
      next;
    }
    my @data=split(' ',$line);
    my $score=$data[1];
    ## add the score to the target
    $target->[$count_to_learn]->{'relevance'}=$score;
    $count_to_learn++;
  } 
  ## check that we have got all documents covered
  if(not $count_to_learn == $count_target) {
    my $error="count_to_learn is $count_to_learn";
    $error.=" but count_target is $count_target";
    if($debug) {
      print DEBUGLOG $error;
    }
    return "$error";
  }
  if($debug) {
    print DEBUGLOG "done\n";
  }
  return $target;
}

## creates a line in the document dataset
## each line represents a documnet in svm format
sub add_document_to_data {
  my $data=shift;
  my $doc=shift;
  my $label=shift;
  ## form terms to look at
  my @terms=split('\W',$doc->{'authors'});
  push(@terms,split('\W',$doc->{'title'}));
  ## empty $data for this document;
  #print "empty\n";
  $data->{'doc'}={};
  delete $data->{'doc'}->{'terms'};
  delete $data->{'doc'}->{'position'};
  foreach my $term (@terms) {
    if(not length($term)>1) {
      next;
    }
    $term=lc($term);
    my $term_number;
    ## new term 
    if(not $data->{'terms'}->{'known'}->{$term}) {
      $term_number=$data->{'terms'}->{'total_number'}++;
      #print "term number is $term_number\n";
      $data->{'terms'}->{'number'}->{$term}=$term_number;
      $data->{'terms'}->{'known'}->{$term}=1;
    }
    else {
      $term_number=$data->{'terms'}->{'number'}->{$term};
    }
    ## count occurances of term
    $data->{'doc'}->{'terms'}->[$term_number]++;
    ## keep track which term is actually used
    $data->{'doc'}->{'position'}->{$term_number}=$term;
    ## length, as measure by terms, of the document
    $data->{'doc'}->{'total'}++;
  }
  ## now calculate weights such as the euclidean sum is one
  my $line="$label ";
  foreach my $position (sort {$a <=> $b} keys %{$data->{'doc'}->{'position'}}) {
    my $raw_frequency=$data->{'doc'}->{'terms'}->[$position];
    my $total=$data->{'doc'}->{'total'};
    my $adjusted_frequency=sqrt($raw_frequency/$total);
    $data->{'doc'}->{'terms'}->[$position]=$adjusted_frequency;
    #$data->{'doc'}->{'terms'}->[$position]=$raw_frequency;
    $line.=$position.':'.$adjusted_frequency.' ';
  }
  chop $line;
  delete $data->{'doc'}->{'position'};
  #print Dumper $data->{'doc'};
  #print "$line\n";
  push(@{$data->{'ds'}},$line);
  return $data;
}

##
## return a learner from an $app. called in modules that require learning
## like send_suggestions_to_learning_daemon
sub form_learner {
  my $app=shift;
  ## the name of the function that calls this function
  my $origin=shift;
  if(not defined($origin)) {
    $origin='unknown origin';
  }
  ## if a third argumnt is given, it has results to learn
  ## these results are added to the suggestions
  my $results=shift;
  ## a debug flag
  my $debug=1;
  ## gather variables
  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record -> {'id'};
  my $psid    = $record -> {'sid'};
  ## the session id, only required for reporting
  my $sid     = $session -> {'id'};
  ### if a new user session, things are different
  if(ref($session) eq 'ACIS::Web::Session::SNewUser') {
    ## the sessionn id is found in a different way
    $sid=$record -> {'sid'};
    ## the presonal short id is the session id. 
    ## this has to stay here, because the sid is 
    ## used instead of the psid in the suggestions table
    $psid=$record -> {'sid'};
  }  
  $id  = $record -> {'id'};
  ## we need to form the log directory from the full id
  ## this is in a separate function so it can be used 
  ## log analysis
  my $log_dir=&find_learn_log_directory($id,
                                        $app -> config('homedir'));
  ## record->sid contains the session id
  my $contributions;
  ## daemon calls
  if(ref($app->{'variables'}->{'contributions'})) {
    $contributions=$app->{'variables'}->{'contributions'};
  }
  ## for offline calls
  elsif(ref($record->{'contributions'})) {
    $contributions=$record->{'contributions'};
  }
  else {
    return "I can not get my hands on the contributions\n";
  }
  my $accepted=$contributions->{'accepted'};
  my $refused=$contributions->{'refused'};
  ## the suggestions
  my $suggested;
  if(ref($contributions->{'suggest'})) {
    ## suggestions are grouped by reasons
    my @groups=@{$contributions->{'suggest'}};
    my $suggested_count=0;
    ## suggestions united with no respect for reason 
    foreach my $group (@groups) {
      my $reason=$group->{'reason'};
      foreach my $suggestion (@{$group->{'list'}}) {
        ## add the reason to each suggested so that we don't loose it      
        $suggestion->{'reason'}=$reason;
        $suggested->[$suggested_count]=$suggestion;
        $suggested_count++;
      }
    }
  }
  elsif(ref($contributions->{'suggested'})) {
    ## probably pointless since this sholud only be 
    ## true of known_item offline calls
    $suggested=$contributions->{'suggested'};
  }
  else {
    $suggested=[];
  }
  ## if there are $results, they have to be added
  ## to the other suggested documents
  if(ref($results)) {
    ## merge the the results into $suggested by dsid
    ## first prepare a hash of handle if $suggestde
    my $suggested_handles;
    foreach my $suggestion (@{$suggested}) {
      $suggested_handles->{$suggestion->{'dsid'}}=1;
    }
    ## then merge
    foreach my $result (@{$results}) {
      if(not defined($suggested_handles->{$result->{'dsid'}})) {
        push(@{$suggested},$result);
      }
    }
  }
  ## the learner structure
  my $learner;
  $learner -> {'accepted'}   = $accepted;
  $learner -> {'refused'}    = $refused;
  $learner -> {'suggested'}  = $suggested;
  $learner -> {'id'}         = $id;
  $learner -> {'sid'}        = $sid;
  ## not defined for a new user
  if(defined($psid)) {    
    $learner -> {'psid'}       = $psid;
  }
  $learner -> {'start_time'} = time();
  ## this is only used by the learning of suggested
  ## documents to form the log the sql object
  $learner -> {'config'} = $app-> {'config'};
  $learner -> {'origin'} = $origin;
  ## add log_direcetory to the learner if it is defined
  $learner->{'log_dir'}=$log_dir;
  ## for debugging, 
  if($debug) {
    open(DEBUGLOG,"> /tmp/".time().'.learner');
    print DEBUGLOG Dumper $learner;
    close DEBUGLOG;
  }
  ## return the learner!
  return $learner;
}


## finds the learning log directory
sub find_learn_log_directory {
  ## a full short id 
  my $id=shift;
  my $home_dir=shift;
  my $log_dir=$id;
  ## delete everything before the date
  $log_dir=~s|.*:(\d{4})-(\d{2})-(\d{2}):(.*)|$1/$2/$3/$4|;
  $log_dir=~s|:|/|g;
  $log_dir="$home_dir/log/learn/$log_dir";
  return $log_dir;
}



# cheers!
1;

