#/usr/bin/perl

use strict;
use warnings;
use citec;

use vars qw($log_file $dbh $DBName $username );
do '/home/adnetec/RePEc/zzz/conf/citec.conf';

$log_file = 'update_cita3.log';
$dbh = citec::connect($DBName,$username);

my $s = $dbh ->prepare( 
                       "select c.cita,d.tclave,d.titulo,d.docid,d.year 
   from CITA c join DOCUMENTO as d on (d.docid=c.escitado) 
   where c.ref_cita is null" );  ### YYY1
my $r = $s->execute() or die "can't execute";
if (not $r) {die}

while ( my @r = $s->fetchrow_array ) {
  my ($srcdocid,$tclave,$titulo,$docid,$year) = @r;
  process_a_document( $srcdocid,$tclave,$titulo,$docid,$year );
}

sub careful { 0 } # YYY4 
sub process_a_document {
  my ($srcdocid,$doctclave,$doctitle,$dochandle,$docyear) = @_;

  my $sDocKeyTitle = $doctclave;
  $sDocKeyTitle =~ s/[\s\r\n]+/\%/g;
  $sDocKeyTitle = '%'.$sDocKeyTitle.'%';

  logger(1, "Looking for a reference from $srcdocid to $dochandle with year=$docyear",$log_file);

  # get candidate references
  my $cite_h = $dbh->prepare("select titulo,docid,year,id,autor from REFERENCIA where docid=? and year=?");
  my $refcount = $cite_h->execute($srcdocid,$docyear) or die "can't execute the query: $cite_h->errstr";
  if ($refcount and +$refcount==0) {
    logger(1, "no reference found (docid:$srcdocid,year:$docyear)", $log_file);
  }

  my @matched_refs = ();
  my @cite;
  while ( @cite = $cite_h->fetchrow_array ) {
    my ($reftitle,$refdocid,$refyear,$refid,$refautor) = @cite;
    logger(1, "Suspect reference: $refid", $log_file);
    
    ## Esta sub compara los dos doc que se le pasan y detecta si es una cita o no
    # actually FindCite() never returns more than one item...
    my @aCitesFound = citec::FindCite($reftitle,$refyear,$doctitle,$docyear,$dochandle,$refautor,$log_file);

    foreach my $citehandle (@aCitesFound) { 
      push @matched_refs, $refid;
    }
  }

  logger(1, "matched: " . scalar(@matched_refs), $log_file);

  if ( scalar @matched_refs == 1 ) {
    $dbh->do( "update CITA set ref_cita=? where cita=? and escitado=?", {}, @matched_refs, $srcdocid, $dochandle ); 

  } elsif ( scalar @matched_refs > 1 ) {
    logger(1, "more than one match: ". join(' ',@matched_refs), $log_file);
  }

  logger(1, "", $log_file);
  
}

