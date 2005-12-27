
use strict;
use warnings;

print "starting ", scalar localtime, "\n";

use ACIS::Web;
use ACIS::Web::Session;

my $acis = ACIS::Web-> new( home => $homedir );

my $sessions_dir = $homedir . '/sessions';



opendir SDIR, $sessions_dir;
my @list = readdir SDIR;
closedir SDIR;

my $counter_logoff = 0;
my $counter_close  = 0;

foreach ( @list ) {
  my $sfile = $sessions_dir . '/' . $_ ;

  next if not -f $sfile;

  print "session file: $sfile\n";

  my $session = ACIS::Web::Session -> load ( $acis, $sfile );

  if ( not $session ) {
    $acis -> errlog( "cleanup: bad session file $sfile" );
    print "   bad session file\n";
    unlink $sfile;
    next;
  }

  if ( not $session -> expired() ) {
    print "   not yet expired\n";
    next; 
  }

  if ( $session -> type() eq 'user' ) {

    print "   user type\n";
    $acis -> log( "cleanup: going to log off session $_" );

    $acis -> session( $session ) ;
    $counter_logoff ++;
    
    $session -> close( $acis );

  } else {

    print "   not user type\n";
    if( $session -> very_old ) {
      print "   very old -- closing\n";
      $acis -> log( "cleanup: closing an old session $_" );

      ### XXX do we want to know why user didn't finish her
      ### registration?  Or at least, who was that user?  But who it
      ### was we will find through the logs.

      $acis -> session( $session ) ;
      $session -> close_without_saving( $acis );
      $counter_close ++;

    } else {
      print "   not yet very old\n";
    }
  }


  $acis -> clear_after_request();


}

if ( $counter_logoff or $counter_close ) {
  $acis -> log( "cleanup: logged-off: $counter_logoff; closed: $counter_close" );
}


