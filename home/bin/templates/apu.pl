
use Carp::Assert;
use sql_helper;
use ACIS::Web;
use Web::App::Common;
use strict;
use warnings;

require ACIS::APU;
require ACIS::APU::Queue;

#####  MAIN PART  

my $acis = ACIS::Web -> new( home => $homedir );

#use Data::Dumper;
#debug Dumper( $acis->config );
#exit;

my $clearlock;
my $queue;
my $auto = 1;
my $failed = 0;
my $interactive = 0;

foreach ( @::ARGV ) {
  if ( m/^\-\-pre(t(e(nd?)?)?)?$/ ) {
    print "sorry, pretend mode is not supported\n";
    undef $_;

  } elsif ( m/^\-\-noauto$/ ) {
    # disable auto rebuilding of the queue table 
    undef $auto;
    undef $_;

  } elsif ( m/^\-\-fail(ed?)?$/ ) {
    # retry the previously failed items
    $failed = 1;
    undef $_;

  } elsif ( m/^\-\-inter(active?)?$/ ) {
    # report progress to stdout
    $interactive = 1;
    undef $_;

  } elsif ( m/^que(ue?)?$/ ) {
    $queue = 1;
    undef $_;
  }
}
clear_undefined( \@::ARGV );

if ( $queue ) {
  foreach ( @ARGV ) {
    ACIS::APU::Queue::enqueue_item($acis->sql_object, $_);
  }
  
} else {
  my $howmuch = shift @ARGV;

  if ( $howmuch +0 <= 0 ) { 
    print "give a positive numeric argument\n"; 
    exit 1;
  }

  my $lockfile = "$homedir/apu-running.lock";
  if ( mkdir $lockfile ) {
    $clearlock = $lockfile;
    system( "echo $$ >$lockfile/pid" );
    ACIS::APU::run_apu_by_queue($howmuch, -auto => $auto, 
                                  -failed => $failed, 
                                  -interactive => $interactive );
  } else {
    print "can't obtain the lock: $lockfile\n";
    exit 1;
  }
}

END {
  if ( $clearlock and -d $clearlock ) {
    #print "self pid: ", `cat $clearlock/pid`;
    system( "rm $clearlock/*" )
      if -f "$clearlock/pid";
    rmdir $clearlock;
    undef $clearlock;
  }
}
