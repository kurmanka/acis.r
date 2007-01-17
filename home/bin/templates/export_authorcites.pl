
use strict;
use warnings;
use ACIS::Web;

# The script checks the citations_events table and dumps out identified
# citation events in a specific format.  The format is that of CitEc's
# authorcites.txt.  It lists cited/citing document pairs per person.
#
# Example:
#
#    <personalhandle> <citref1> [<citref2>...]
#
#  where citrefN is a string:
#
#    "<trgdocid>||<srcdocid>"
#  
#  where <trgdocid> is id of a document in the personhandle's research
#  profile and <srcdocid> is the citing document's id.
#
#  When you start the script, specify a month as a parameter on the
#  command line.  Month must be in the YYYY-MM form or 'this', 'last'.
#  Data from that month will be reported to stdout.


#####  MAIN PART  
my $ACIS = ACIS::Web -> new( home => $homedir );
my $sql = $ACIS -> sql_object;
my $mdb = $ACIS -> config( 'metadata-db-name' );
my $where = '';
my $month = shift || '';

if ( $month eq 'this' ) {
  # current month 
  $where = "WHERE ce.time >= DATE_FORMAT(CURDATE(),'\%Y\%m01')";

} elsif ( $month eq 'last' ) {
  # prev month
  my $prev_month;
  $sql->prepare( "select DATE_FORMAT(DATE_SUB(CURDATE(),INTERVAL 1 MONTH),'\%Y\%m01') as d ");
  my $r = $sql->execute();
  if ( $r and $r->{row}{d} ) {
    #print $r->{row}{d}, "\n";
    $prev_month = $r->{row}{d};
  }
  $where = "WHERE ce.time>=$prev_month and ce.time < DATE_FORMAT(CURDATE(),'\%Y\%m01')";

} elsif ( $month =~ /^\d{4}\-\d{2}$/ ) {

  $month .= "-01";
  my $fin;

  $sql->prepare( "select DATE_ADD('$month',INTERVAL 1 MONTH)+0 as d ");
  my $r = $sql->execute();
  if ( $r and $r->{row}{d} ) {
    #    print $r->{row}{d}, "\n";
    $fin = $r->{row}{d};
  }
  
  $month =~ s/\-//g; # YYYYMMDD
  $where = "WHERE ce.time >= $month and ce.time < $fin";

} else {
  die "Specify month as a parameter.  Month must be in the YYYY-MM form or 'this', 'last'."; 
}



my @q = (
qq!select res.id as docid,rec.id as pid,citedres.id as citeddocid from citation_events as ce
   join records as rec ON rec.shortid=ce.psid
   join ${mdb}.resources as res ON res.sid=ce.srcdocsid
   join ${mdb}.resources as citedres ON citedres.sid=ce.dsid
   $where
   order by pid,ce.time asc!,
);

#print "please wait while we upgrade the database...\n";

#print "q: ", @q, "\n";

$sql -> prepare( @q );
my $r = $sql -> execute;

my $buf;
my $pid_prev = '';

if ( $r and $r->{row} ) {
#  print "rows: $r->{rows}\n";
  while( $r->{row} ) {
    my $d = $r->{row};
    my $pid        = $d->{pid};
    my $docid      = $d->{docid};
    my $citeddocid = $d->{citeddocid};

    $pid = uc $pid;
    $pid        =~ s/^repec:/RePEc:/gio;
    $docid      =~ s/^repec:/RePEc:/gio;
    $citeddocid =~ s/^repec:/RePEc:/gio;

    if ( $buf and $pid ne $pid_prev ) {
      print $buf, "\n";
      $buf = "$pid $citeddocid||$docid";
      $pid_prev = $pid;

    } elsif ( $buf and $pid eq $pid_prev ) {
      $buf .= " $citeddocid||$docid";

    } else {
      $buf = "$pid $citeddocid||$docid";
      $pid_prev = $pid;
    }
    $r->next;
  }
}
if ( $buf ) {
  print $buf, "\n";
}


#print "upgrade done, but please restart the update daemon ASAP!\n";
