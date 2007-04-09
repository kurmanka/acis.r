
use strict;
use warnings;
use ACIS::Web;

#####  MAIN PART
my $ACIS = ACIS::Web -> new();
my $sql = $ACIS -> sql_object;
my $RDB = $ACIS -> config( 'metadata-db-name' );

my @q = (
  qq!delete from ft_urls!,
  qq!alter table ft_urls add source VARCHAR(255) NOT NULL!,
  qq!alter table ft_urls drop primary key!,
  qq!alter table ft_urls add primary key(dsid,checksum,source)!,
);

print "please wait while we upgrade the database...\n";

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
