
use strict;
use warnings;
use Data::Dumper;
use ACIS::Web;
use Web::App::Common;
use Storable;
use ACIS::Resources::Learn::Refused;

my $acis = ACIS::Web -> new( home => $homedir );

my $to_do=$ARGV[0];
if(not $to_do) {
  print "fatal: no psid to do\n";
  exit
}

&ACIS::Resources::Learn::Refused::sort_refused($acis,$to_do);
if($@) {
  print "error: $@";
}


