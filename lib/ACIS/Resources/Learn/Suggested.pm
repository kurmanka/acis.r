package ACIS::Resources::Learn::Suggested;

use Carp;
use Carp::Assert;
use Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
use File::Path;
use Web::App::Common;
use ACIS::Web::Background qw(logit);
use ACIS::Resources::Learn qw(learn_via_svm);
use Data::Dumper;
use XML::LibXML;
use sql_helper;

@EXPORT = qw( learn_suggested );

use strict;


# part of cardiff

# evcino


## we set not to debug
my $debug=0;

#
# changes to this  file must be followed by a daemon restart
#
# we get a learner and send it to the ACIS::Resources::Learn
# module. That module adds a relevance estimationn to each suggestion,
# and returns the suggestions. This module then stores the result in
# the suggestions table.

sub learn_suggested {
  my $learner = shift;
  my $sql=shift;
  ## search context, used when the functionn is 
  ## called by background searches
  my $context=shift;
  ## reason for all, if we have no reason in a 
  ## suggestion, assume that reason
  my $default_reason=shift;
  my $id=$learner->{'id'};
  my $psid=$learner->{'psid'};
  my $config=$learner->{'config'};
  my $time=time();
  #print LOG Dumper $learner;
  # log
  my $home_dir=$config->{'homedir'};
  if($debug) {
    my $debug_file_name;
    $debug_file_name="/tmp/learn_suggested";
    open(LOG,"> $debug_file_name");
    print LOG "the learner is \n";
    print LOG Dumper $learner;
  }
  ## we are now calling the learner itself
  my $suggested=&learn_via_svm($learner,'suggested',$debug);
  # return value is an error message, if not a reference
  if(not ref($suggested)) {
    if($debug) {
      print LOG "learning failed: $suggested";
    }
    ## write a report before leaving
    &write_report($learner, { 'note' => $suggested });
    ## return undef to signal a caller from autoseach that
    ## it has to save the results
    return undef;
  }
  elsif($debug) {
    print LOG "learning succeeded. \$suggested is\n";
    print LOG Dumper $suggested;
  }
  ## create sql object, if such an object has not been 
  ## handled down through the second argumnet
  ## this could be because it is run in the foreground without
  ## the daemon, on because it is called befer saving results
  ## to 
  if(not ref($sql)) {
    my $sql_log="$home_dir/opt/log/learn_suggested_sql.log";
    sql_helper -> set_log_filename ( $sql_log );
    $sql = sql_helper -> new ( $config->{'db-name'}, 
                               $config->{'db-user'},
                               $config->{'db-pass'});
    if($debug) {
      print LOG "this is sql\n";
      print LOG Dumper $sql;
    }
  }
  my $suggested_count=0;
  #print LOG "$suggested_count suggestions\n";
  ## to save the suggestions, we have to group the $suggestions
  ## variable back to its reasons
  ## first let us count how many suggestions we have for each
  my $reason_size;
  foreach my $suggestion (@{$suggested}) {
    ## if we don't know the reason for a suggestion
    ## make it the default_reason
    if(not defined($suggestion->{'reason'})) {
      $suggestion->{'reason'}=$default_reason;
    }
    $reason_size->{$suggestion->{'reason'}}++;
  }
  if($debug) {
    print LOG Dumper $reason_size;
  }
  ## now save the suggestions
  foreach my $reason (sort {$reason_size->{$a} <=> $reason_size->{$b}}
                      keys %{$reason_size}) {
    # the group of suggentions having that reason
    my $suggestions_for_reason;
    my $suggestions_for_reason_count=0;
    # compose the $suggestions_for_reason
    foreach my $suggestion (@{$suggested}) {
      if($suggestion->{'reason'} eq $reason) {
        $suggestions_for_reason->[$suggestions_for_reason_count]=$suggestion;
        $suggestions_for_reason_count++;
      }
    }
    ## this can not be used at the start, otherwise a circular
    ## dependence prevents the learning daemon from running
    require ACIS::Resources::AutoSearch;
    ## 2010-03-09
    if(not defined($context)) {
      $context->{'sid'}=$psid;
      $context->{'sql'}=$sql;
    }
    ## /2010-03-09
    ACIS::Resources::AutoSearch::save_search_results($context,$reason,$suggestions_for_reason);    
  }
  if($debug) {
    print LOG "learning ended normally\n";
    close LOG;
  }
  ## write report
  &write_report($learner);
  return 1;
}

## formulates a reporting structure from the 
## document data and writes it out
sub write_report {
  my $learner=shift;
  ## additional hash to report
  my $extra=shift;
  my $doc=XML::LibXML::Document->new('1.0','utf-8');
  my $report_element=XML::LibXML::Element->new('report');
  ## report attributes
  foreach my $attribute ('psid','sid','start_time','origin') {
    if(defined($learner->{$attribute})) { 
      $report_element->setAttribute($attribute,$learner->{$attribute});
    }
  }
  ## report extra parameters
  foreach my $name (keys %{$extra}) {
    my $extra_element=XML::LibXML::Element->new($name);
    $extra_element->appendTextNode($extra->{$name});
    $report_element->appendChild($extra_element);
  }
  my @states=('accepted','refused','suggested');
  foreach my $state (@states) {
    my $item_count=0;
    ## skip state if it is not there
    if(not ref($learner->{$state})) {
      next;
    }
    foreach my $item (@{$learner->{$state}}) {
      my $element_name=substr($state,0,1);
      my $item_element=XML::LibXML::Element->new($element_name);
      foreach my $attribute ('id','sid','relevance') {
        if(defined($item->{$attribute})) { 
          $item_element->setAttribute($attribute,$item->{$attribute});
        }
      }
      ## save
      $item_element->setAttribute('pos',$item_count++);
      $report_element->appendChild($item_element);
    }
  }
  $doc->setDocumentElement($report_element);
  my $psid=$learner->{'psid'};
  ## determing the log directory
  my $log_dir;
  $log_dir=$learner->{'log_dir'};
  if($debug) {
    open(LOGLOG,"> /tmp/logdir_later");
    print LOGLOG "log_dir is $log_dir\n";
    close LOGLOG;
  }
  if(not -d $log_dir) {
    mkpath( $log_dir, {'mode' => 0755 });
  }
  ## use start_time of learner
  my $time;
  if(defined($learner -> {'start_time'})) {
    $time=$learner -> {'start_time'};
  }
  else {
    $time=time();
  }
  my $log_file="$log_dir/".$time.'.xml';
  $doc->toFile($log_file,2);
}

# Cheers!
1;

