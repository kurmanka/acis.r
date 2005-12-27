package ACIS::PIDAID::XML;

use strict;
use Encode;


sub make_xml {
  my $data = shift;
  
  if ( not ref $data 
       and $data eq 'too many' ) {
    return "<toomany/>";
  }

  my $res  = "<list>\n";

  foreach ( @$data ) {
    my $row = $_;

    $res .= "  <person>\n";
    
    foreach ( keys %$row ) {
      my $v = $row->{$_};

      my $element = $_;
      $res .= "    <$element>";
      $res .= escape( $v );
      $res .= "</$element>\n";
    }

    $res .= "  </person>\n";
    
  }
  $res .= "</list>\n";
  
  return $res;
}

sub escape {
  my $s = shift;
  for ( $s ) { 
    s/&/&amp;/g;
    s/>/&gt;/g;
    s/</&lt;/g;
  }
  return $s;
}

1;

