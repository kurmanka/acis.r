use strict;

use Carp::Assert;

use RePEc::Index::UpdateClient;

if ( not scalar @ARGV ) {
  print "Usage: bin/updareq COLLECTION PATH [TOO_OLD]

Sends update request to the ACIS update daemon for file or dir PATH in
collection COLLECTION.  TOO_OLD is time in seconds.  If a file was last time
processed more than TOO_OLD seconds ago, it will be processed again.  If you
want to process every file, give TOO_OLD of 1.\n"; 
  exit; 
}

my $collection = shift || die "give a collection name";
my $dir        = shift || die "give an object to update, relative to the collection";
my $too_old    = shift;

RePEc::Index::UpdateClient::send_update_request( $collection, $dir, $too_old );
