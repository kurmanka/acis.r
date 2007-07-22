package ACIS::Web::FullTextURLs;

use strict;
use warnings;

use ACIS::FullTextURLs;

sub prepare {
  my $acis = shift;
  my $session = $acis->session;
  my $record = $session -> current_record;
  if ( $session -> type ne 'user' ) {
    $acis ->error( 'session-wrong-type' );
    $acis ->clear_process_queue;
    $acis ->set_presenter( 'sorry' );
    return;
  }
  $acis->variables->{fturls} = ACIS::FullTextURLs::load_everything( $record );
}

sub process {
  my $acis = shift;
  my $session = $acis->session;
  my $record = $session -> current_record;
  my $psid  = $record->{sid};
  my $input = $acis->form_input;
  my $dsid  = $input->{dsid};
  my $href  = $input->{href};
  my $choice= $input->{choice};
  
  my $ok;
  if ( $dsid and $psid and $href and $choice
       and ACIS::FullTextURLs::save_choice( $dsid,$href,$psid,$choice ) ) {
    $ok = 1;
  }

  my $status = $ok ? '200 Ok' : '500 Internal Error';
  $acis->response_status($status);
  $acis->set_presenter();
  $acis->response()->{body} = $ok ? '<ok/>' : '<nok/>';
}


1;

