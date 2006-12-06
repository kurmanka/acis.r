
use strict;
use warnings;
use ACIS::Web;

#####  MAIN PART  
my $ACIS = ACIS::Web -> new( home => $homedir );
my $sql = $ACIS -> sql_object;
my $RDB = $ACIS -> config( 'metadata-db-name' );

my @q = (

q!alter table citations add fulltext index (nstring)!,
q!alter table citations add index (trgdocid)!,
q!alter table $RDB.res_creators_separate add index (name)!,

);

print "please wait while we upgrade the database...\n";

foreach ( @q ) {
  $sql -> prepare( $_ );
  $sql -> execute;
}

print "upgrade done.\n";
