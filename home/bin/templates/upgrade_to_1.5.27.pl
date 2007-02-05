
use strict;
use warnings;
use ACIS::Web;

#####  MAIN PART
my $ACIS = ACIS::Web -> new( home => $homedir );
my $sql = $ACIS -> sql_object;
my $RDB = $ACIS -> config( 'metadata-db-name' );

my @q = (

q!alter table citations   change column citid cnid serial!,
q!alter table cit_doc_similarity change citid cnid serial!,
q!alter table cit_old_sug        change citid cnid serial!,
q!alter table cit_sug            change citid cnid serial!,

);

print "please wait while we upgrade the database...\n";

foreach ( @q ) {
  $sql -> prepare( $_ );
  print " $_\n";
  $sql -> execute;
}

print "upgrade done.\n";
