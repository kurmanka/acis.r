
use strict;
use warnings;
use ACIS::Web;

#####  MAIN PART
my $acis = ACIS::Web -> new;
my $sql = $acis -> sql_object;
my $RDB = $acis -> config( 'metadata-db-name' );

# the following would give us the whole history of each citation/person/document in the history field:
# select cnid,psid,dsid,group_concat(event) as history from citation_events where dsid is not null group by cnid,psid,dsid;

# get the latest current status for each citation:
# select cnid,psid,dsid,substring_index(group_concat(event),',',-1) as history from citation_events where dsid is not null group by cnid,psid,dsid;

# get only currently identified citations:
# select cnid,psid,dsid,substring(group_concat(event),-5) as last from citation_events where dsid is not null group by cnid,psid,dsid having last='added';


my @q = (
q!create temporary table citations_identified_personal  
    (cnid BIGINT UNSIGNED NOT NULL, 
     psid char(12) not null,
     dsid char(12) not null,
     last char(5) not null) !, # ,index(cnid,dsid)
q!insert into citations_identified_personal
     select cnid,psid,dsid,substring(group_concat(event),-5) as last 
     from citation_events 
     where dsid is not null 
     group by cnid,psid,dsid 
     having last='added'!,
# 
q!drop table citations_identified!,
# ?
# temporary
q!create  table citations_identified
    (cnid BIGINT UNSIGNED NOT NULL, 
     dsid char(12) not null, 
     index (dsid), index (cnid) ) 
     select distinct cnid,dsid from citations_identified_personal!,
#q!select count(*) from citations left join citations_identified ci using (cnid) where ci.cnid is null and trgdocid is not null!,
# this is to pass through the CitEc data that we didn't find use for (yet):
qq!insert into citations_identified 
   select c.cnid,r.sid from citations c 
     join $RDB.resources r on (c.trgdocid=r.id) 
     left join citations_identified ci using (cnid) 
   where ci.cnid is null and trgdocid is not null!,
);

print "please wait while we build the temporary tables...\n";
foreach ( @q ) {
  $sql -> prepare( $_ );
  print "  $_\n";
  $sql -> execute;
}

print "dumping out the data...\n";

produce_iscited();
produce_hasreferences();

print "done\n";


sub produce_iscited {
# iscited.txt file format:
#
# targethandle1 srchandle1#srchandle2#srchandle3#...
# targethandle2 srchandle7#srchandle8#...
# ...

  open CITED, ">iscited.txt"
    or die;

  $sql->prepare( 
                qq!select sr.id as s,tr.id as t from citations_identified ci 
  join citations c using (cnid)
  join $RDB.resources tr on (ci.dsid=tr.sid)
  join $RDB.resources sr on (c.srcdocsid=sr.sid)
  order by ci.dsid! );
  my $r = $sql->execute();
  my $line;
  my $last_trg = '';
  while ( $r->{row} ) {
    my $src = $r->{row}->{s};
    my $trg = $r->{row}->{t};
    if ($trg eq $last_trg) {
      $line .= '#';
      $line .= $src;
    }
    if ($trg ne $last_trg) {
      if ($line) {print CITED $line, "\n";}
      $line = "$trg $src";
      $last_trg = $trg;
    }
  } continue { 
    $r->next; 
  }
  if ($line) {print CITED $line, "\n";}
  close CITED;
}

sub produce_hasreferences {
# hasreferences.txt file format:
#
# srchandle1
# srchandle2
# ...
# srchandle89083
# ...

  open HASREF, ">hasreferences.txt" 
    or die;
  $sql->prepare( 
                qq!select distinct sr.id as s from citations_identified ci 
  join citations c using (cnid)
  join $RDB.resources sr on (c.srcdocsid=sr.sid)
  order by ci.dsid! );
  my $r = $sql->execute();
  my $line;
  my $last_trg = '';
  while ( $r->{row} ) {
    print HASREF $r->{row}->{s}, "\n";
  } continue { 
    $r->next; 
  }
  close HASREF;
}

