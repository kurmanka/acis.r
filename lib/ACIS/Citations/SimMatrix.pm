package ACIS::Citations::SimMatrix;

use strict;
use warnings;

use Carp::Assert;

##  cit_suggestions table fields:
#
#     * citation origin doc sid: srcdocsid CHAR(15) NOT NULL
#     * citation checksum: checksum CHAR(22) NOT NULL
#     * personal sid, short: psid CHAR(15) NOT NULL
#     * document sid, short: dsid CHAR(15) NOT NULL
#     * reason: ‘similar’ | ‘pre-identified’, ‘co-author:pau432’: reason CHAR(20) NOT NULL
#     * similarity: similar TINYINT UNSIGNED (from 0 to 100 inclusive)
#     * new: yes | no new BOOL
#     * original citation string: ostring TEXT NOT NULL
#     * origin doc details (URL): srcdocdetails BLOB
#     * suggestion’s creation/update date: time DATE NOT NULL
#
# PRIMARY KEY (srcdocsid, checksum, psid, dsid, reason),
# INDEX( psid ), INDEX( dsid )


#  load_similarity_matrix( psid );
#  get_most_interesting_document( psid );

use Exporter;
use base qw( Exporter );
use vars qw( @EXPORT_OK );
@EXPORT_OK = qw( load_similarity_matrix );


use ACIS::Citations::Suggestions qw( load_suggestions );


sub load_similarity_matrix($) {
  my $psid = shift;
  
  my $sug  = load_suggestions( $psid );
  my $mat  = { new => {}, old => {} };

  bless $mat;

  foreach ( @$sug ) {
    $mat -> _add_sug( $_ );
  }
  
  $mat -> _calculate_totals;

  return $mat;
}

sub _add_sug {
  my $self = shift;
  my $sug  = shift;
  
  my $d      = $sug ->{dsid};
  my $newold = ($sug->{new}) ? 'new' : 'old';

  for ( $self->{$newold}{$d} ) {
    if ( not $_ ) { $_ = []; }
    push @$_, $sug;

    # clear redundant bits
    delete $sug->{dsid};
    delete $sug->{psid};
    delete $sug->{new};
  }
}


sub _calculate_totals {
  my $self   = shift;
  my $totals = {};
  
  my $newdoc = $self->{new};
  foreach ( keys %$newdoc ) {
    my $dsid = $_;
    my $total = 0;
    foreach ( @{ $newdoc->{$_} } ) {
      # XXX treat co-author's claims specially
      $total += $_->{similar};
    }
    $totals ->{$dsid} = $total;
  }

  $self->{totals_new} = $totals;
  
  my @doclist = keys %$newdoc;
  @doclist = grep { $totals->{$_}; } @doclist;
  @doclist = sort { $totals->{$b} <=> $totals->{$a} } @doclist;

  $self -> {doclist} = \@doclist;
}

sub most_interesting_doc {
  my $self = shift;
  my $doclist = $self->{doclist};
  if ( $doclist and ref $doclist
       and defined $doclist->[0] ) {

    return $doclist->[0];
  }
  return undef;
}




sub testme {
  require Data::Dumper;
  require ACIS::Web;
  # home=> '/home/ivan/proj/acis.zet'
  my $acis = ACIS::Web->new(  );
  
  my $psid = 'ptestsid0';
  my $m    = load_similarity_matrix( $psid );
  print Data::Dumper::Dumper( $m );

}










1;
