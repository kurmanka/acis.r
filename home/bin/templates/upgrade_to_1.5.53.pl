
use strict;
use warnings;
use ACIS::Web;

#####  MAIN PART
my $ACIS = ACIS::Web -> new( home => $homedir );
my $sql = $ACIS -> sql_object;
my $RDB = $ACIS -> config( 'metadata-db-name' );

my @q = (
  qq!alter table citations modify clid CHAR(38) BINARY NOT NULL!,
  qq!alter table citations_deleted modify clid CHAR(38) BINARY NOT NULL!,
);

print "please wait while we upgrade the database...\n";

foreach ( @q ) {
  $sql -> prepare( $_ );
  print "  $_\n";
  $sql -> execute;
}

print "upgrade done.\n";
