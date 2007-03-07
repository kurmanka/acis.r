package Web::App::EmailFormat;

use strict;

#####   INTERFACE

#####   This module can nicely format email messages from the intermediary
#####   strings, as produced by format-email XSLT template from HTML source.
#####   (format-email is in presentation/default/email/general.xsl)
#####
#####   Basically, every single line in the input is one paragraph.  If a
#####   paragraph has any breaks in it, they must be replaced with "^^^"
#####   sequence.
#####   
#####   If your paragraph is a list bullet, prefix it with the bullet.
#####   It will be taken into account.
#####

sub format_email {
  my $in = shift;
  my $out = '';

  my @lines = split( /\n/, $in );
  foreach ( @lines ) {
    $out .= format_para( $_ );
    $out .= "\n";
  }

  return $out;
}


####  IMPLEMENTATION 


my $right_margin = 73;
my $left_margin  = 0;

sub wrap {
  my $line   = shift;
  my $prefix = shift;

  if ( length( $line ) > $right_margin ) {
    my $first_line_end = rindex( $line, " ", $right_margin );

    if ( $first_line_end > 1
         and $first_line_end > $left_margin ) {
      ###  the line can be safely wrapped
    } else {
      $first_line_end = index( $line, " ", $right_margin );
    }
    
    if ( $first_line_end > -1 ) {
      ###  normal case
      my $first_line = substr( $line, 0, $first_line_end );
      my $rest       = $prefix . substr( $line, $first_line_end+1 );
      return "$first_line\n" . wrap( $rest, $prefix ) . "\n";
    } else {
      ### can't wrap this line -- nowhere we can break
    }
  } 
  
  return $line;
} 


sub format_para {
  my $str = shift;
  my $para = '';
  
  my $start  = '';
  my $prefix = '';

  if ( $str =~ /^(\s+\W?\s*)(.+)/ ) {
    # \W stands for a possible bullet in front of an list item
    $start = $1;
    $str   = $2;
    $prefix = ' ' x length( $1 );
  }

  my @lines = split( m!\^\^\^!, $str );
  foreach ( @lines ) {
    $para .= $start;
    $para .= wrap( $_, $prefix );
    $para .= "\n";
    $start = $prefix;
  }

  return $para;
}



## &test();

sub test {
my $test = q!Dear %/1Äékoi8-rÁ¡◊“…Ã¡ %/1Äékoi8-rÏ¡ƒœ€…Œ,
Sorry, we didn't find anything interesting this time. We won't send such email in real life.
Just for a sample here are some items, listed:
  * Dynamic Effects of Trade Liberalization and Currency Overevaluation under Increasing Returns^^^paper by J. Ros & Peter Skott^^^http://econpapers.hhs.se/paper/aahaarhec/1995-8.htm  
  * DYNAMICS OF A KEYNESIAN ECONOMY UNDER DIFFERENT MONETARY REGIMES^^^paper by Peter Skott^^^http://econpapers.hhs.se/paper/aahaarhec/1988-16.htmfjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
http://authors.repec.org/research/pref^^^(will ask for login and password)
BTW, you still have 6 other documents which were found earlier but still wait for your decision. See them on your Research profile.
This message was automatically generated. There's no need to reply. If you don't want to get further notices of this kind, you may disable Automatic maintenance of the research profile at the same address as above:
http://authors.repec.org/research/pref^^^(will ask for login and password)
!;

print "-----\n", 
  format_email( $test )
  , "-----\n";

}


1;
