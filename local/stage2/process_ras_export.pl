#!/usr/bin/perl

# version 2

use strict;
use warnings;
use citec;

use vars qw($log_file $dbh $DBName $username );
do '/home/adnetec/RePEc/zzz/conf/citec.conf';

$log_file = 'process_ras_export.log';
$dbh = citec::connect($DBName,$username);

my $input = shift @ARGV;

if ( !-f $input or !-r _ ) {
  die "can't read $input";
}

open INPUT, "<$input" 
  or die "can't open $input";

my $findref_st = $dbh->prepare( "select id from REFERENCIA where docid=? and md5=?" ) or die;
my $updst = $dbh->prepare( "update CITA set ref_cita=? where cita=? and escitado=?" ) or die;
my $addst = $dbh->prepare( "replace into CITA (cita,escitado,ref_cita,fecha) values (?,?,?,NOW())" ) or die;
my $delst = $dbh->prepare( "delete from CITA where cita=? and escitado=?" ) or die;

my $count_all = 0;
my $count_added = 0;
my $count_updated = 0;
my $count_ref_not_found = 0;
my $count_deleted = 0;

while( <INPUT> ) {
  chomp;
  my ($srcdocid,$md5,$trgdocid,$event) = split( /\t/, $_ );
  if ( not $event 
       or not $srcdocid 
       or not $trgdocid ) { next; }
  $count_all++;
  $srcdocid =~ s/^repec/RePEc/;
  $trgdocid =~ s/^repec/RePEc/;

  my $r = $findref_st->execute( $srcdocid, $md5 );
  my $array = $findref_st->fetchrow_arrayref
    if $r;
  my $refid = $array->[0]
    if $array;
  
  if (not $refid) {
    print "no reference: $srcdocid $md5\n";
    $count_ref_not_found++;
  }
  $refid ||= '';
  if ( $event eq 'added' 
       or $event eq 'autoadded' ) {
    #print "add $refid -> $trgdocid\n";
    my $update = $updst-> execute( $refid, $srcdocid, $trgdocid ) or die;
    # execute() returns number of rows affected
    if ($update eq '0E0') {
      # update didn't work because there is no such record
      # so we add it
      $addst->execute( $srcdocid, $trgdocid, $refid );
      $count_added++;
    } else {
      $count_updated++;
    }

  } elsif ( $event eq 'unidentified' ) {
#    print "drop $refid -> $trgdocid\n";
    $delst->execute( $srcdocid, $trgdocid );
    $count_deleted++;
  }
}

print "all: $count_all\tadded: $count_added\tupdated: $count_updated\tremoved: $count_deleted\tref not found: $count_ref_not_found\n";

