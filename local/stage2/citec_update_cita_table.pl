#/usr/bin/perl

use strict;
use warnings;
use citec;

use vars qw($log_file $dbh $DBName $username );
do '/home/adnetec/RePEc/zzz/conf/citec.conf';

$log_file = 'update_cita.log';
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
  $sDocKeyTitle =~ s/\s+/\%/g;
  $sDocKeyTitle = '%'.$sDocKeyTitle.'%';

  logger(1, "Looking for a reference from $srcdocid to $dochandle...",$log_file);

  # get candidate references
  my $cite_h = $dbh->prepare("select titulo,docid,year,id,autor from REFERENCIA where docid=? and titulo like ?");
  my $refcount = $cite_h->execute($srcdocid,$sDocKeyTitle) or die "can't execute the query: $cite_h->errstr";
  if ($refcount and +$refcount==0) {
    logger(1, "no matching references found (title:$doctclave,like $sDocKeyTitle)", $log_file);
  }
  my @cite;
  while ( @cite = $cite_h->fetchrow_array ) {
    my ($reftitle,$refdocid,$refyear,$refid,$refautor) = @cite;
    logger(1, "Suspect reference: $refid", $log_file);
    
    ## Esta sub compara los dos doc que se le pasan y detecta si es una cita o no
    # actually FindCite() never returns more than one item...
    my @aCitesFound = citec::FindCite($reftitle,$refyear,$doctitle,$docyear,$dochandle,$refautor,$log_file);

    foreach my $citehandle (@aCitesFound) { 
      logger(1, "This doc has been cited by $refid", $log_file);

      if(careful) { # XXX this is not really needed:
        my $sth = $dbh->prepare( "select cita,ref_cita,fecha from CITA where cita=? and escitado=?" );  # YYY3
        $sth->execute( $refdocid, $dochandle );
        my @cita = $sth->fetchrow_array();
        my ($cita,$ref,$fecha) = @cita;
        warn 'no fecha date' if not $fecha;
        if ($fecha and not $ref) {
          logger(1, "CITA: set ref_cita to $refid ********************", $log_file);
          $dbh->do( "update CITA set ref_cita=? where cita=? and escitado=?", {}, $refid, $refdocid, $dochandle ); ## YYY2
        } else {
          if ($ref ne $refid) {
            logger(1, "CITA: ref_cita mismatch: $ref vs. $refid (fecha: $fecha)", $log_file);
          } else {
            logger(1, "CITA: ref_cita match", $log_file);
          }
        }
      } else {
        $dbh->do( "update CITA set ref_cita=? where cita=? and escitado=?", {}, $refid, $refdocid, $dochandle ); ## YYY2

      }
    }
  }
  
}

