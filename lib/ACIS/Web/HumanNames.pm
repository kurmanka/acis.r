package ACIS::Web::HumanNames;

use strict;
use warnings;

use base qw( Exporter );
use vars qw( @EXPORT_OK );
@EXPORT_OK = qw( normalize_name normalize_and_filter_names );

use utf8;
use Web::App::Common qw(clear_undefined);
use Unicode::Normalize;

sub normalize_name () {
  $_ = lc $_;

  s/'//g;  # remove single quote, which happens in names like "O'Brien" and "Vasil'ev"

  # from http://ahinea.com/en/tech/accented-translate.html
  s/\xe4/ae/g;  ##  treat characters ä ñ ö ü ÿ
  s/\xf1/ny/g;  ##  
  s/\xf6/oe/g;
  s/\xfc/ue/g;
  s/\xff/yu/g;

  $_ = NFD( $_ );   ##  decompose
  s/\pM//g;         ##  strip combining characters
  
  s/\x{00df}/ss/g;  ##  German beta
  s/\x{00c6}/AE/g;  ##  
  s/\x{00e6}/ae/g;  ##  
  s/\x{0132}/IJ/g;  ##  
  s/\x{0133}/ij/g;  ##  
  s/\x{0152}/Oe/g;  ##  
  s/\x{0153}/oe/g;  ##  
  
  tr/\x{00d0}\x{0110}\x{00f0}\x{0111}\x{0126}\x{0127}/DDddHh/; 
  tr/\x{0131}\x{0138}\x{013f}\x{0141}\x{0140}\x{0142}/ikLLll/; 
  tr/\x{014a}\x{0149}\x{014b}\x{00d8}\x{00f8}\x{017f}/NnnOos/; 
  tr/\x{00de}\x{0166}\x{00fe}\x{0167}/TTtt/;                   
  
  s/\W/ /g;
# old normalization, with dots after initials:
#                       s/,\s*/, /g; 
#                       s/\.\s*/. /g;
#                       s/\. ([-,])/.$1/g;
#                       s/(\b[A-Z]\b)([^'\w\.]|$)/$1.$2/g;
  s/(^\s+|\s+$)//g;
  s/\s+/ /g;
  # minimum 3 useful signs:
  if ( s/(\w)/$1/g < 3 ) { undef $_; }
}


sub normalize_and_filter_names($) {
  my ($l) = @_;
  my $h = {};
  foreach ( @$l ) {
    if (not $_) { undef $_; next; }
    normalize_name();
    if (not $_) { undef $_; next; }
    undef $_ if $h->{$_}++;
  }
  clear_undefined $l;
}

sub testme {
  my @a = split '\n', 
q!Jacob S. Fry
Matilda Belkins
Robert J. Lucas, Jr.
Rumbler, J. N.
Rumbler J.N.
Rumbler, J. N., Jr.
Rumbler, J.-N.
A. Krámli
A. Jiménez-Losada
A. Ferrer-i-Carbonell
M. Aspnäs         
M. Aubert-Frécon
Françoise MASNOU-SEEUWS
F-G.
!;
  print "--- original: \n", join( "\n", @a ), "\n--- /original ---\n";
  normalize_and_filter_names \@a;
  print "--- result: \n", join( "\n", @a ), "\n--- /result ---\n";


}


1;

