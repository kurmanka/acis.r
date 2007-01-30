
use strict;
use warnings;
use ACIS::Web;

#####  MAIN PART  
my $ACIS = ACIS::Web -> new( home => $homedir );
my $sql = $ACIS -> sql_object;

my @q = (

q!alter table cit_doc_similarity add INDEX docind (dsid)!,
q!alter table cit_sug            add INDEX docind (dsid)! 

);

print "please wait while we upgrade the database...\n";

foreach ( @q ) {
  $sql -> prepare( $_ );
  print " $_\n";
  $sql -> execute;
}

print "upgrade done.\n";

