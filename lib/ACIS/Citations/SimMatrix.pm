package ACIS::Citations::SimMatrix;

use strict;
use warnings;

use Carp::Assert;

use ACIS::Citations::Suggestions;

##  cit_suggestions table fields:
#
#     * citation origin doc sid: srcdocsid CHAR(15) NOT NULL
#     * citation checksum: checksum CHAR(22) NOT NULL
#     * personal sid, short: psid CHAR(15) NOT NULL
#     * document sid, short: dsid CHAR(15) NOT NULL
#     * reason: ‘similar’ | ‘pre-identified’, ‘co-author:pau432’: reason CHAR(20) NOT NULL
#     * similarity: similar TINYINT UNSIGNED
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
@EXPORT_OK = ( load_similarity_matrix );

sub load_similarity_matrix($) {
  my $psid = shift;
  
  
}

sub most_interesting_doc {

}














1;
