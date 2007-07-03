#!/usr/bin/perl

use strict;
our ($reclimit, $log_dir, $thisprog, $version);
our ($DBName, $username, $dbh);

$thisprog='update_amf.pl';
$version='0.1';
my $log_file = 'update_amf.log';
my $log_err  = 'update_amf.err';
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


sub slurp($) {
  my $f = shift;
  if (-f $f and open FILE, "<:utf8", $f ) {
    my $s = join '', <FILE>;
    close FILE;
    return $s;
  }
  return undef;
}


sub main {
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

  my $tempfile = "/tmp/update_amf.$$";
 
  # get references running
  get_references_started($dbh);
  use Data::Dumper;
  while (1) {
    my ( $docid, $rl ) = get_next_bunch_of_references(); 
    last if not $docid;
    last if not $rl;

    # get other data: citations
    my $cl = get_citations_from_doc( $dbh, $docid );
    my $bref = get_citations_to_doc( $dbh, $docid ); ### optional
        
    # process data, prepare it for write_amf_file()
    my $citref = join_sort_citations_and_references( $cl, $rl ); 

    my $r = write_amf_file( $tempfile, $docid, $citref, $bref );
    if (not $r) {
      warn "can't write $docid\n";
      next;
    }    

    my $rename;

    # make filename
    my $filename = make_amf_filename( $docid );
    if (not -e $filename) {
      $rename = 'new';

    } else {
      my $new = slurp( $tempfile );
      my $old = slurp( $filename );
      if ( $new and $old 
           and $new ne $old) {
        $rename = 'upd';
      } else {
        print "$filename (same)\n";
      }
    }

    if ($rename) {
      #die "$filename ($rename)\n";
      print "$filename ($rename)\n";
      system("cp $tempfile $filename");
    }

  }
}

# RUN THE SCRIPT
main();
