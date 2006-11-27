
use strict;
use warnings;
use ACIS::Web;

#####  MAIN PART  
my $ACIS = ACIS::Web -> new( home => $homedir );
my $sql = $ACIS -> sql_object;
my $mdb = $ACIS -> config( 'metadata-db-name' );
my $where = '';


my @q = (
qq!select res.id as docid,rec.id as pid,citedres.id as citeddocid from citation_events 
   join records as rec ON rec.shortid=citation_events.psid
   join ${mdb}.resources as res ON res.sid=citation_events.srcdocsid
   left join ${mdb}.resources as citedres ON citedres.sid=citation_events.dsid
   $where
   order by pid,citation_events.time asc!,
);

#print "please wait while we upgrade the database...\n";

$sql -> prepare( @q );
my $r = $sql -> execute;

if ( $r and $r->{row} ) {
  while( $r->{row} ) {
    my $d = $r->{row};
    my $pid        = $d->{pid};
    my $docid      = $d->{docid};
    my $citeddocid = $d->{citeddocid};
    $pid        =~ s/^repec:/RePEc:/gio;
    $docid      =~ s/^repec:/RePEc:/gio;
    $citeddocid =~ s/^repec:/RePEc:/gio;

    print "$pid $docid||$citeddocid\n";
    $r->next;
  }
}


#print "upgrade done, but please restart the update daemon ASAP!\n";
