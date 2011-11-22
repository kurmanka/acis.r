package ACIS::Sessions;

use strict;
use warnings;

use Scalar::Util qw( blessed );
use ACIS::Web::Session;

sub cleanup {
  my $acis = $ACIS::Web::ACIS;
  my $homedir = $acis->home;
  my $sessions_dir = $homedir . '/sessions';

  opendir SDIR, $sessions_dir;
  my @list = readdir SDIR;
  closedir SDIR;
  
  my $counter_logoff = 0;
  my $counter_close  = 0;
  
  foreach ( @list ) {
    my $sfile = $sessions_dir . '/' . $_ ;
    next if m/\.bad$/;
    next if not -f $sfile;
    print "session file: $sfile\n";

    my $session = ACIS::Web::Session -> load( $acis, $sfile );

    if ( not $session ) {
      my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)
        = stat($sfile);
      my $now = time;
      my $recent = $now - 10*60;
      if ($mtime < $recent) {
        # the file is old, and not likely to be updated
        $acis -> errlog( "cleanup: bad session file $sfile" );
        print "   bad session file\n";
#        unlink $sfile;
        rename $sfile, "$sfile.bad";
      } else {
        print "   unreadable session file, may be in use\n";
      }
      next;
    }

    if ( not blessed $session ) {
      print "   bad session file, not a blessed ref: $session\n";
      next;
    }
    
    if ( not $session -> expired() ) {
      print "   not yet expired\n";
      next; 
    }
    
    if ( $session -> type() eq 'user' 
        or $session -> type() eq 'admin-user' ) {
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
 
}  
  
1;
  
