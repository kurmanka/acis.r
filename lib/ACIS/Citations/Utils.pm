package ACIS::Citations::Utils;

use strict;
use warnings;

use Exporter;

use base qw( Exporter );
use vars qw( @EXPORT_OK );

@EXPORT_OK = qw( normalize_string get_document_authors );

use Unicode::Normalize;

sub normalize_string($) {
  my $string = shift;

  for ( $string ) {
    $_ = NFD( $_ );
    $_ = uc $_;
    s!([,\.])!$1 !g;
    s!\.\s+,!.,!g;
    s!\s\s+! !g;
    s!(^\s+|\s+$)!!g;
  }

  return $string;
}

sub get_document_authors($) {
  die if not $ACIS::Web::ACIS;

  my $app = $ACIS::Web::ACIS;
  my $docsid = shift;
  my $docid  = $docsid;

  my $mdb = $app -> config( "metadata-db-name" );
  my $sql = $app -> sql_object() || die;

  if ( $docsid =~ /^d\w+\d+$/ 
       and length( $docsid ) < 16 ) {
    $sql -> prepare( "select id from $mdb.resources where sid=?" );
    my $res = $sql -> execute( $docsid );
    if ( $res -> {row} and $res -> {row} ->{id} ) {
      $docid = $res -> {row} ->{id};
    }
  } 

  $sql -> prepare( "select subject from $mdb.relations where relation='accept' and object=?" );
  my $res = $sql -> execute( $docid );
  my @list;

  while ( $res->{row} ) {
    push @list, $res->{row}->{subject};
    $res->next;
  }

  return @list;
}

                         
sub test_get_document_authors () {
  require ACIS::Web;
  
  my $acis = ACIS::Web->new( home=> '/home/ivan/proj/acis.zet' );

  my @docs = qw( repec:wop:cirano:2000s06 dacc4 dtax1 );

  foreach ( @docs ) {
    my @res = get_document_authors( $_ );
    print "doc: $_\nauthors: ", join( ', ', @res ), "\n\n";
  }
}


1;
