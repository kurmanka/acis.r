
use strict;
use warnings;
use ACIS::Web;

#####  MAIN PART
my $ACIS = ACIS::Web -> new( home => $homedir );
my $sql = $ACIS -> sql_object;
my $RDB = $ACIS -> config( 'metadata-db-name' );

my @q = (

q!alter table citations   change column citid cnid serial!,
q!alter table cit_doc_similarity change citid cnid BIGINT UNSIGNED NOT NULL!,
q!alter table cit_old_sug        change citid cnid BIGINT UNSIGNED NOT NULL!,
q!alter table cit_sug            change citid cnid BIGINT UNSIGNED NOT NULL!,

# this assumes srcdocsid and checksum fields in the citations table:
q!alter table citation_events add column cnid BIGINT UNSIGNED FIRST!,
q!update citation_events join citations using (srcdocsid,checksum) set citation_events.cnid=citations.cnid!,
q!alter table citation_events modify column cnid BIGINT UNSIGNED NOT NULL, 
     drop column srcdocsid, drop column checksum!,

q!alter table citations add column clid char(38) FIRST!,
q!update citations set clid = CONCAT_WS('-',srcdocsid,checksum)!,
q!alter table citations drop PRIMARY KEY, drop column srcdocsid, drop column checksum!,
q!alter table citations modify clid char(38) not null PRIMARY KEY!,

q!delete from sysprof where param='last-cit-prof-check-time'!,

);

print "please wait while we upgrade the database...\n";

foreach ( @q ) {
  $sql -> prepare( $_ );
  print " $_\n";
  $sql -> execute;
}

print "upgrade done.\n";
