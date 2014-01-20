use strict;
use warnings;

#####  MAIN PART
require ARDB;
require ARDB::Local;

my $ARDB = ARDB -> new() or die;
my $sql = $ARDB -> sql_object;


#  the SQL to run
my @q = (
  qq!
    alter table users 
    drop column password
  !,
  qq!
   update events 
    set 
       descr = 'login failed, password mismatch' 
    where 
       class='authenticate' 
       and descr like 'login failed, password given%'
  !,
#  qq!!,
);

print "please wait while we upgrade the database... its going to take a while.\n";

use Data::Dumper;
foreach ( @q ) {
  $sql -> prepare( $_ );
  print "  $_\n";
  my $r = $sql -> execute;
  if ($r) {
    print "  - result: modified ", $r->rows, " rows\n";
  }
  if ($sql->error) {
    print "  - error: " , $sql->error, "\n";
    last;
  }
}

print "upgrade done.\n";
