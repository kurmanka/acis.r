package ACIS::Resources::Learn;

use Carp;
use Carp::Assert;
use Exporter;
use File::Temp ();
use base qw(Exporter);
use vars qw(@EXPORT);
use Storable qw(freeze thaw);
use Web::App::Common;
use ACIS::Web::Background qw(logit);
use ACIS::Resources::Suggestions;
use Data::Dumper;
use sql_helper;
use strict;

# part of cardiff

#
# global variables
#
my $train_bin="/usr/bin/svm-train -q -b 1";
my $predict_bin="/usr/bin/svm-predict -b 1";

@EXPORT = qw( 
              sort_suggestions_through_learning();
              learn_via_svm();
);


#
# general learning function, 
# takes accepetd, refused, suggested
#
sub learn_via_svm {
  my $accepted=shift;
  my $refused=shift;
  # may be left out, then we learn about the 
  # refused documents
  my $suggested=shift;
  my @accepted_docs=@{$accepted};
  my $count_accepted=$#accepted_docs;
  # there should be at least one accepted documet
  if($count_accepted<0) {
    return "no accepted documents";
  }
  # save memory
  @accepted_docs=();
  ##print "count_accepted is $count_accepted\n";
  my @refused_docs=@{$refused};
  my $count_refused=$#refused_docs;
  ##print "count_refused is $count_refused\n";
  my @suggested_docs;
  my $count_suggested;
  if(defined($suggested)) {
    @suggested_docs=@{$suggested};
    $count_suggested=$#suggested_docs;
    @refused_docs=();
  } 
  else {
    @suggested_docs=@{$refused};
    $count_suggested=$#refused_docs;
  }
  # make sure it's worth proceeding
  if($count_suggested < 1) {
    return "not enough suggested documents";
  }
  # build the dataset
  my $data;
  foreach my $doc (@{$accepted}) {
    $data=&add_document_to_data($data,$doc,'+1');
  }
  foreach my $doc (@{$refused}) {
    $data=&add_document_to_data($data,$doc,'-1');
  }
  if($suggested) {
    foreach my $doc (@{$suggested}) {
      $data=&add_document_to_data($data,$doc,'0');
    }
  }
  # now the document data lines are in $data->{'ds'}
  my @ds=@{$data->{'ds'}};
  # start with the trainingfile
  my $train_fh = File::Temp->new();
  my $train_file=$train_fh->filename;
  # write the training set, leaving out docs
  # that start with "0"
  foreach my $doc_line (@ds) {
    if(not $doc_line=~m|^0|) {
      print $train_fh "$doc_line\n";
    }
  }
  $train_fh->close;
  # create model file
  my $model_fh=File::Temp->new();
  my $model_file=$model_fh->filename();
  # create system command to fire up training
  my $s="$train_bin ".$train_fh->filename;
  $s.=" $model_file";
  # for debugging, save train file
  ##$s.="; cp $train_file /tmp/train";
  ##print "doing $s\n";
  system($s);
  # model is now trained, build the testing set
  # organize test file
  my $test_fh = File::Temp->new();
  my $test_file=$test_fh->filename; 
  # find the start of the suggested document
  my $learn_doc_start;
  if($suggested) {
    $learn_doc_start=$count_accepted+$count_refused+1;
  }
  # if there are no suggested, start with the refused docs
  else {
    $learn_doc_start=$count_accepted+1
  }  
  foreach my $count_to_learn (0..$count_suggested) {
    my $learn_doc=$data->{'ds'}->[$learn_doc_start+$count_to_learn];
    # in case it was a refused document
    $learn_doc=~s|^-1|0|;
    ##print "wrote testing set line $count\n";
    print $test_fh "$learn_doc\n";
  }
  $test_fh->close();
  # organize out file
  my $out_fh = File::Temp->new();    
  my $out_file=$out_fh->filename();
  # generate and read output file
  $s="$predict_bin $test_file $model_file $out_file";
  # for debuing
  ##$s.="; cp $out_file /tmp/out";
  ##$s.="; cp $test_file /tmp/test"; 
  # for the output, REQUIRED
  $s.="; cat $out_file";
  ##print "doing: $s\n";
  my $count_to_learn=0;
  # read output and find the score for earch document
  my $result;
  foreach my $line (`$s`) {
    ##print "$line";
    if(not $line=~m|^[+-]*1|) {
      next;
    }
    my @data=split(' ',$line);
    my $score=$data[1];
    ##print "score is $score\n";
    push(@{$result->{$score}},$count_to_learn);
    $count_to_learn++;
  }  
  my $docs_sorted;
  my $docs_count;
  # if there are no suggested documents, from here onwards consider
  # the refused documents to be the suggested ones
  if(not defined($suggested)) {
    $suggested=$refused;
  }
  foreach my $number (sort {$b <=> $a} keys %{$result}) {
    foreach my $doc_number (@{$result->{$number}}) {
      push(@{$docs_sorted},$suggested->[$doc_number]);
      if(not defined($suggested->[$doc_number])) {
        print "fatal: document $doc_number is not defined!\n";
        exit;
      }
    }
  }
  for(my $count=0; $count <= $count_suggested; $count++) {
    if(not defined($docs_sorted->[$count])) {
      print "fatal: docment $count is not defined!\n";
      exit;
    }
    $suggested->[$count]=$docs_sorted->[$count];
  }
  ##my $out=Dumper $suggested;
  ##print "$out" ;
  return $suggested;
}

#
# creates a line in the document
#
sub add_document_to_data {
  my $data=shift;
  my $doc=shift;
  my $label=shift;
  # form terms to look at
  my @terms=split('\W',$doc->{'authors'});
  push(@terms,split('\W',$doc->{'title'}));
  # empty $data for this document;
  #print "empty\n";
  $data->{'doc'}={};
  delete $data->{'doc'}->{'terms'};
  delete $data->{'doc'}->{'position'};
  foreach my $term (@terms) {
    if(not length($term)>1) {
      next;
    }
    $term=lc($term);
    #print "term is '$term'\n";
    # new term
    my $term_number;
    # new term 
    if(not $data->{'terms'}->{'known'}->{$term}) {
      $term_number=$data->{'terms'}->{'total_number'}++;
      #print "term number is $term_number\n";
      $data->{'terms'}->{'number'}->{$term}=$term_number;
      $data->{'terms'}->{'known'}->{$term}=1;
    }
    else {
      $term_number=$data->{'terms'}->{'number'}->{$term};
    }
    # count occurances of term
    $data->{'doc'}->{'terms'}->[$term_number]++;
    # keep track which term is actually used
    $data->{'doc'}->{'position'}->{$term_number}=$term;
    # length, as measure by terms, of the document
    $data->{'doc'}->{'total'}++;
  }
  # now calculate weights such as the euclidean sum is one
  my $line="$label ";
  foreach my $position (sort {$a <=> $b} keys %{$data->{'doc'}->{'position'}}) {
    my $raw_frequency=$data->{'doc'}->{'terms'}->[$position];
    my $total=$data->{'doc'}->{'total'};
    my $adjusted_frequency=sqrt($raw_frequency/$total);
    $data->{'doc'}->{'terms'}->[$position]=$adjusted_frequency;
    ###$data->{'doc'}->{'terms'}->[$position]=$raw_frequency;
    $line.=$position.':'.$adjusted_frequency.' ';
  }
  chop $line;
  delete $data->{'doc'}->{'position'};
  ##print Dumper $data->{'doc'};
  ##print "$line\n";
  push(@{$data->{'ds'}},$line);
  return $data;
}



# cheers!
1;

