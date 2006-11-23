
use strict;
use warnings;
use ACIS::Web;

#####  MAIN PART  
my $ACIS = ACIS::Web -> new( home => $homedir );
my $sql = $ACIS -> sql_object;

my @q = (
q!insert into apu_queue (what,position,filed) 
  select what,0 as pos,filed from arpm_queue where status='' or status is null order by filed asc!,
#q!drop table arpm_queue!,
);

print "please wait while we upgrade the database...\n";

foreach ( @q ) {
  $sql -> prepare( $_ );
  $sql -> execute;
}

print "upgrade done, but please restart the update daemon ASAP!\n";
