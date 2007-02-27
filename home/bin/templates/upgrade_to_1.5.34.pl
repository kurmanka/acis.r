
use strict;
use warnings;
use ACIS::Web;

#####  MAIN PART
my $ACIS = ACIS::Web -> new( home => $homedir );
my $sql = $ACIS -> sql_object;
my $RDB = $ACIS -> config( 'metadata-db-name' );

my @q = (
  qq!alter table $RDB.res_creators_separate modify name varchar(255) not null!,
  qq!alter table $RDB.res_creators_separate add fulltext index creatorsft(name)!,
  qq!alter table names modify name varchar(255) not null!,
  qq!alter table names add index namesindex(name)!,
  qq!alter table users modify name varchar(255), modify login varchar(255) not null!,
);

print "please wait while we upgrade the database...\n";

foreach ( @q ) {
  $sql -> prepare( $_ );
  print "  $_\n";
  $sql -> execute;
}

print "upgrade done.\n";
