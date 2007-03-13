package ACIS::Web::DocLinks;

use strict;
use warnings;

use Carp;
use Web::App::Common;

use ACIS::DocLinks;

my ($acis,$session,$record,$input,$vars,$rp,$links);

sub prepare {
  $acis = $ACIS::Web::ACIS;
  $session = $acis->session;
  $record = $session->current_record;
  $vars  = $acis->variables;
  $input = $acis->form_input();
  $rp   = $vars ->{contributions}{accepted} or die;
  $links = $session->{doclinks_o} ||= get_doclinks( $record );

  prepare_current_links();
  $vars ->{'doclinks-conf'} = $links->config;
}

sub prepare_current_links {
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
}


sub process {
  $links = $session->{doclinks_o} || die;

  my ($src,$rel,$trg);
  if ($input->{add}) {
    if ( $src=$input->{src}
         and $rel=$input->{rel}
         and $trg=$input->{trg} ) {
      return process_add();
    }
  } elsif ($input->{del}) {
    return process_delete();
  } 
  $acis->success(0);
}

sub process_add {
  my ($src,$rel,$trg);
  if (
          $src=$input->{src}
      and $rel=$input->{rel}
      and $trg=$input->{trg} 
      and $links->add($src,$rel,$trg) ) {
    save_doclinks( $record, $links );
    $acis->success(1);
    $acis->log("added link: src:$src rel:$rel trg:$trg");
    $acis->message( 'added-doclink' );
    prepare_current_links();
  }
}

sub process_delete {
  my ($src,$rel,$trg);
  if (
          $src=$input->{src}
      and $rel=$input->{rel}
      and $trg=$input->{trg} 
      and $links->drop($src,$rel,$trg) ) {
    save_doclinks( $record, $links );
    $acis->success(1);
    $acis->log("deleted link: src:$src rel:$rel trg:$trg");
    $acis->message( 'deleted-doclink' );
    prepare_current_links();
  }
}


1;
