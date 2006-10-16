
use Carp::Assert;

use sql_helper;
use ACIS::Web;

use Web::App::Common;


use warnings;

require ACIS::APU;


#####  MAIN PART  

my $acis = ACIS::Web -> new( home => $homedir );

my $pretend;
my $queue;
foreach ( @::ARGV ) {
  if ( m/^\-\-pre(t(e(nd?)?)?)?$/ ) {
    $pretend = 1;
    undef $_;

  } elsif ( m/^que(ue?)?$/ ) {
    $queue = 1;
    undef $_;
  }
}
clear_undefined( \@::ARGV );

if ( $queue ) {
  foreach ( @ARGV ) {
    ACIS::APU::push_item_to_queue($acis->sql_object, $_);
  }
  
} else {
  my $howmuch = shift @ARGV;
  ACIS::APU::run_apu_by_queue($howmuch, $pretend);

}
