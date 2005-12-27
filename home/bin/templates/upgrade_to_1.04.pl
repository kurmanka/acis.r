
use strict;
use warnings;

use ACIS::Web;
#use sql_helper;


#####  MAIN PART  

my $ACIS = ACIS::Web -> new( home => $homedir );

{
  my $testpdir = "$homedir/plugins/Processing/Test";
  if ( -d $testpdir ) {
    unlink( <"$testpdir/*"> );

    if ( rmdir( $testpdir ) ) {
    } else {
      warn "can't rmdir $testpdir";
      system( "rm -rf $testpdir" )
        or warn "can't rm -rf $testpdir";
    };

  }
}



