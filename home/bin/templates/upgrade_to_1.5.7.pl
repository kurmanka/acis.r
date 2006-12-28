
use strict;
use warnings;
use ACIS::Web;

#####  MAIN PART  
my $ACIS = ACIS::Web -> new( home => $homedir );
my $sql = $ACIS -> sql_object;
my $RDB = $ACIS -> config( 'metadata-db-name' );

my @q = (

qq!alter table citations add citid serial first!,

q!insert IGNORE into cit_doc_similarity 
select citations.citid,sug.dsid,sug.similar,sug.time from cit_suggestions as sug 
join citations USING (srcdocsid,checksum)
where sug.reason='similar' group by citations.citid,sug.dsid !,

q!insert IGNORE into cit_old_sug 
select sug.psid,sug.dsid,citations.citid from cit_suggestions as sug 
join citations USING (srcdocsid,checksum)
where sug.new=0!,

);

print "please wait while we upgrade the database...\n";

foreach ( @q ) {
  $sql -> prepare( $_ );
  print " $_\n";
  $sql -> execute;
}

print "upgrade done.\n";
