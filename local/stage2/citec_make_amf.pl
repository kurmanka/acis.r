#!/usr/bin/perl

use strict;
our ($reclimit, $log_dir, $thisprog, $version);
our ($DBName, $username, $dbh);

$thisprog='make_amf.pl';
$version='0.3';
my $log_file = 'make_amf.log';
my $log_err  = 'make_amf.err';
our $DELETE = 1;

use ReDIF::init;
use rr qw(BUG_FIX);
use citec;
use citec::AMFexport; 
use DB_File;
use IO::File;
use XML::Writer;



sub dump_list {
  my @list = @_;
  print "srcdocid\ttrgdocid\tliteral\n";
  foreach (@list) {
    print $_->srcdocid , "\t", $_->trgdocid, "\t", $_->literal, "\n";
  }
  print "\n";
}


sub main {
  open(ERR,">$log_err");

  &logger('1',"$thisprog version $version starts now",$log_file);
  $username = "adnetec";
  $DBName = "citec2";
  &logger('1',"Connecting to database",$log_file);
  $dbh = &citec::connect($DBName,$username);
  &logger('0',"Problem $DBI::err $DBI::errstr",$log_file) if $DBI::err;
  die "database connection problem" if not $dbh;

#  Go by REFERENCIA.  Get all REFERENCIA records for a document.  Then
#  all CITA records for it (if any).  Then do a manual join on them (on
#  c.ref_cita = r.id).  Sort citations and references (identified and
#  unidentified citations).
 
  # get references running
  get_references_started($dbh);
  use Data::Dumper;
  while (1) {
    my ( $docid, $rl ) = get_next_bunch_of_references(); 
    last if not $docid;
    last if not $rl;

    # make filename
    my $filename = make_amf_filename( $docid );
    if (-e $filename and not $DELETE) {
      print "File $filename already exists, skipping ...\n";
      next;
    }

    # get other data: citations
    my $cl = get_citations_from_doc( $dbh, $docid );
    #my $brl = get_back_references( $dbh, $docid ); ### optional
        
    # process data, prepare it for write_amf_file()
    my $citref = join_sort_citations_and_references( $cl, $rl ); 

    write_amf_file( $filename, $docid, $citref );
    print "$filename\n";
  }

}

# RUN THE SCRIPT
main();
