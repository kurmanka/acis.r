package ACIS::Web::Deceased;

=head1 NAME

ACIS::Web::Deceased

=head1 DESCRIPTION

feature: some profiles describe a deceased person. The admin must be
able to move such profile to the deceased account and set the date of
death to it.

=cut

use strict;

sub prepare {
  my $app = shift;
  my $input = $app->form_input;
  my $rec = $app->session->current_record || die;
  
  if (exists $rec->{deceased}) {
    $app->set_form_value( "dead", 1 );

    my ($y,$m,$d) = split( m/\-/, $rec->{deceased} );

    $app->set_form_value( "date-y", $y );
    $app->set_form_value( "date-m", $m );
    $app->set_form_value( "date-d", $d );
  }
}

sub process {
  my $app = shift;
  my $i   = $app->form_input;
  my $rec = $app->session->current_record;


  if ( $i->{'date-y'} ) {

    my $y = $i->{'date-y'};
    $rec->{deceased} = $i->{'date-y'};
    
    if($i->{'date-m'}) {
      $rec->{deceased} .= "-" . $i->{'date-m'};
      if($i->{'date-d'}) {
        $rec->{deceased} .= "-" . $i->{'date-d'};
      }
    }
    
  } elsif ($i->{dead}) {
    $rec->{deceased} = '';

  } else {
    delete $rec->{deceased};
  }

  prepare($app);
}


1;
