#!/usr/bin/perl 

use vars qw( $homedir $acis );
our $IDIR;
BEGIN {
    ($IDIR) = (__FILE__ =~ m,(.*)/,); $IDIR ||= '.';
    if (-d "$IDIR/../lib" ) {  unshift(@INC, "$IDIR/../lib");   }
}
BEGIN { chomp($homedir ||= `pwd`); }

use lib "$homedir/lib";
use lib qw( /home/ivan/dev/acis/lib );

use strict;

use sql_helper;
use ACIS::Web;

my $login = shift @ARGV;
my $rec   = shift @ARGV;

if ( not $login or scalar @ARGV ) {
  die "Usage: $0 user\@login [record]\n\nwhere record may be a short-id or a full id\n";
}

BEGIN { $acis = ACIS::Web -> new( home => $homedir ); }

use ACIS::Web::Admin;
my $res= ACIS::Web::Admin::offline_userdata_service( $acis, $login, 'ACIS::cit_overview', $rec, $rec );
#if ( not $res ) { print "  RESULT: $res\n"; }
$acis->clear_after_request();


package ACIS;

use strict;
use Web::App::Common;
use ACIS::Web::Citations;

use ACIS::Citations::Utils;
use ACIS::Citations::Suggestions;
use ACIS::Citations::SimMatrix;


sub p (@) { print @_, "\n"; }

sub cit_overview {
  my $acis = shift;
  my $therec = shift;

  my $session = $acis->session;
  my $crec = $session->current_record;

  my $paths = $acis ->paths;
  my $udata = $session ->object;
  my $records = $udata->{records};
  my $sql = $acis->sql_object();

  die if $session ->{simmatrix};

#  $session ->{lump} = 'x' x 10000;

#  my $r = { t => 'x'x102400, r => {} };
#  $r->{r} {g} = \$r;
#  $s .= '.'x5000000;

  ACIS::Web::Citations::prepare();

  my $m = $session->{simmatrix};
  my $c = $session->{simmatrix}{citations};

  #  p "  record: ", $crec->{sid};
  p "  research profile items: ", $#{ $crec ->{contributions}{accepted} }+1;
  #  p "  research profile items: ", scalar @{ $crec ->{contributions}{accepted} };
  p "  unique citations suggested: ", scalar keys %$c;
  p "  citation/document pairs: ", $m->{sugs};

  undef $m;

  undef $crec;
  undef $udata;
  undef $records;
  undef $sql;
  undef $session;
  undef $paths;
  undef $acis;

  1;
}

1;
