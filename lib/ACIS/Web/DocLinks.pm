package ACIS::Web::DocLinks;

use strict;
use warnings;

use Carp;
use Web::App::Common;

use ACIS::DocLinks;

sub prepare {
  my $acis = $ACIS::Web::ACIS;
  my $session = $acis->session;
  my $record = $session->current_record;
  my $vars = $acis->variables;
  my $rp   = $vars ->{contributions}{accepted} or die;
  my $links = $session->{doclinks_o} ||= get_doclinks( $record );

  my $doclinks = {};
  foreach ( @$rp ) {
    my $sid = $_->{sid} or next;
    my $l = $links -> for_document( $sid );
    if ($l and scalar @$l) {
      $doclinks ->{$sid} = $l;
    } else {
#      die $sid; 
    }
  }
  $vars ->{doclinks} = $doclinks;
  $vars ->{'doclinks-conf'} = $links->config;
}

sub process {
  my $acis = $ACIS::Web::ACIS;
  my $session = $acis->session;
  my $record = $session->current_record;
  my $vars = $acis->variables;
  my $rp   = $vars ->{contributions}{accepted} or die;
  my $input = $acis->form_input();

  my $links = $session->{doclinks_o} || die;

  my ($src,$rel,$trg);
  if ($input->{add}) {
    if ( $src=$input->{src}
         and $rel=$input->{rel}
         and $trg=$input->{trg} ) {
      if ( $links ->add($src,$rel,$trg) ) {
        save_doclinks( $record, $links );
        $acis->success(1);
        $acis->log("added link: src:$src rel:$rel trg:$trg");
        $acis->message( 'added-doclink' );
        prepare();
        return;
      }
    }
  } 
  $acis->success(0);
}


1;
