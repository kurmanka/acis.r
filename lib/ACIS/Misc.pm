package ACIS::Misc;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Miscelaneous functions for ACIS
#
#
#  Copyright (C) 2003-2004 Ivan Kurmanov for ACIS project,
#  http://acis.openlib.org/
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License, version 2, as
#  published by the Free Software Foundation.
# 
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#  ---
#  $Id$
#  ---



sub contains_non_ascii {
  my $str = shift;
  if ( $str =~ /^[\0-\x80]*$/ ) {
    return 0;
  }
  return 1;
}


sub contains_non_latin {
  my $str = shift;
  if ( $str =~ /[\x100-\xffff]/ ) {
    return 1;
  }
  return 0;
}

sub transliterate {
  my $str = shift;

  # http://ahinea.com/en/tech/accented-translate.html

  use Unicode::Normalize;
  
  for ( $str ) {

    s/\xe4/ae/g; # 228
    s/\xf1/ny/g; # 241
    s/\xf6/oe/g; # 246
    s/\xfc/ue/g; # 252
#    s/\xfe/th/g; # 254
    s/\xff/yu/g;  # 255

    $_ = NFD( $_ );
    s/\pM//g; ### strip combining characters

    s/\x{00c6}/AE/g;
    s/\x{00e6}/ae/g;
    s/\x{0132}/IJ/g;
    s/\x{0133}/ij/g;
    s/\x{0152}/Oe/g;
    s/\x{0153}/oe/g;
    s/\x{00df}/ss/g;

    tr/\x{00d0}\x{0110}\x{00f0}\x{0111}\x{0126}\x{0127}\x{0131}\x{0138}\x{013f}\x{0141}\x{0140}\x{0142}\x{014a}\x{0149}\x{014b}\x{00d8}\x{00f8}\x{017f}\x{00de}\x{0166}\x{00fe}\x{0167}/DDddHhikLLllNnnOosTTtt/;

   s/[^\0-\x80]//g;  ### clear everything else

  }


  return $str;
}

sub transliterate_safe {
  my $str = shift;

  use Unicode::Normalize;
  
  for ( $str ) {

    s/\xe4/ae/g; # 228
    s/\xf1/ny/g; # 241
    s/\xf6/oe/g; # 246
    s/\xfc/ue/g; # 252
#    s/\xfe/th/g; # 254
    s/\xff/yu/g;  # 255

    $_ = NFD( $_ );
    s/\pM//g; ### strip combining characters

    s/\x{00c6}/AE/g;
    s/\x{00e6}/ae/g;
    s/\x{0132}/IJ/g;
    s/\x{0133}/ij/g;
    s/\x{0152}/Oe/g;
    s/\x{0153}/oe/g;
    s/\x{00df}/ss/g;

    tr/\x{00d0}\x{0110}\x{00f0}\x{0111}\x{0126}\x{0127}\x{0131}\x{0138}\x{013f}\x{0141}\x{0140}\x{0142}\x{014a}\x{0149}\x{014b}\x{00d8}\x{00f8}\x{017f}\x{00de}\x{0166}\x{00fe}\x{0167}/DDddHhikLLllNnnOosTTtt/;

  }


  return $str;
}


sub counter_with_limit {
  my $limit = shift;
  my $count = 0;
  
  return sub { my $f = shift; 
               if ($f eq 'add') { 
                 my $n = shift;
                 $count+= $n;
               } elsif ($f eq 'inc') { $count++;
               } elsif( $f eq 'over') {
                 return ($count > $limit);
               }
             };
}


sub testme {
  my $c = counter_with_limit( 4 );
  foreach ( 1..6 ) {
    &$c('inc');
    print "$_: ", (&$c('over')?'y':'n'), "\n";
  }
}


1;

