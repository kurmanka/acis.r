package ACIS::Resources::Learn;

use Carp;
use Carp::Assert;
use Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
use Storable qw(nfreeze thaw);
use Web::App::Common;
use ACIS::Web::Background qw(logit);
use Data::Dumper;
use strict;


@EXPORT = qw( 
              sort_suggestions_through_learning();
);


#
# learn from suggestions
# here it manipulates $app as to 
# change the order of the suggestion
sub sort_suggestions_through_learning {
  my $app    = shift;

  # these may be passed from the calling function
  # but I am listing them separately here
  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record -> {id};
  my $psid    = $record -> {sid};
  my $contributions=$app->{'variables'}->{'contributions'};
  my $sql = $ACIS::Web::ACIS->sql_object;

  # suggestions are grouped by reasons
  my @groups=@{$contributions->{'suggest'}};
  my $suggestion_count=0;
  # suggestions united with no respect for reason 
  my $suggestions;
  foreach my $group (@groups) {
    my $reason=$group->{'reason'};
    foreach my $suggestion (@{$group->{'list'}}) {
      # add the reason to earch suggestion so that we don't loose it      
      $suggestion->{'reason'}=$reason;
      # extremely primitive learning: relevance is the suggestion count
      # this way learning will reverse the appearance of suggestions
      $suggestion->{'relevance'}=$suggestion_count;
      # add to an aggregaet $suggestions variable
      $suggestions->[$suggestion_count]=$suggestion;
      $suggestion_count++;
    }
  }

  # now for some better learning, over to you Ilya...


  # to save the suggestions, we have to group the $suggestions
  # variable back to its reasons
  # first let us count how many suggestions we have for earch
  my $reason_size;
  foreach my $suggestion (@{$suggestions}) {
    $reason_size->{$suggestion->{reason}}++;
  }

  #
  # now save the suggestions, again grouped by reason
  # 
  foreach my $reason (sort {$reason_size->{$a} <=> $reason_size->{$b}}
                      keys %{$reason_size}) {
    # the group of suggentions having that reason
    my $suggestions_for_reason;
    my $suggestions_for_reason_count=0;
    # compose the $suggestions_for_reason
    foreach my $suggestion (@{$suggestions}) {
      if($suggestion->{'reason'} eq $reason) {
        $suggestions_for_reason->[$suggestions_for_reason_count]=$suggestion;
        $suggestions_for_reason_count++;
      }
    }
    # save it
    ACIS::Resources::Suggestions::save_suggestions( $sql, $psid, 
                                                    $reason, undef, 
                                                    $suggestions_for_reason );
  }
}

1;

