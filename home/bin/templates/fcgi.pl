my $func = shift;
die if not $func or $func =~ m/[^a-z]/;

&{$func}();

use strict;


sub start {
  system( "nohup $homedir/bin/autorestart.sh $homedir/autorestart-fcgi.pid perl $homedir/bin/acis.fcgi &" );
}


sub stop {
}


sub restart {
  my $mask = "$homedir/fcgi*pid";
  #print "check: $mask\n";

  my $killed = 0;
  foreach ( glob($mask) ) { 
    print "file: $_\n";
    my $pid = `cat $_`;
    if ($pid) { 
      print "    pid: $pid\n";
      kill 15, $pid; 
      $killed++;
    }
  }
  if ($killed) {
    # wait for a restart?
    sleep (1);
    while( 1 ) {
      sleep( 1 );
      my @f = glob($mask);
      if ( scalar @f ) {
        print "restarted (@f)\n";
        last;
      }
    }
  }

}
