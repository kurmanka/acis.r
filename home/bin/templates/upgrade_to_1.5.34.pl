
use strict;
use warnings;
use ACIS::Web;

#####  MAIN PART
my $ACIS = ACIS::Web -> new( home => $homedir );
my $sql = $ACIS -> sql_object;
my $RDB = $ACIS -> config( 'metadata-db-name' );

my @q = (
  qq!alter table $RDB.res_creators_separate add fulltext index creatorsft(name)!,
  qq!alter table names add index namesindex(name)!,
);

print "please wait while we upgrade the database...\n";

foreach ( @q ) {
  $sql -> prepare( $_ );
  print "  $_\n";
  $sql -> execute;
}

print "upgrade done.\n";
