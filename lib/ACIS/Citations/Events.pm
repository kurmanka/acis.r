package ACIS::Citations::Events;

use strict;

use Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw( cit_event );

#  cit_event( $citation->{srcdocsid}, $citation->{checksum}, $rec->{sid}, $dsid, "autoadded", $citation->{autoaddreason}, $note );
sub cit_event {
  my ($srcdocsid,$checksum,$psid,$dsid,$event,$reason,$note) = @_;
  my $sql = $ACIS::Web::ACIS->sql_object;

  $sql -> prepare_cached( "insert into citation_events (srcdocsid,checksum,psid,dsid,event,reason,note,time) VALUES (?,?,?,?,?,?,?,NOW())" );
  $sql -> execute($srcdocsid,$checksum,$psid,$dsid,$event,$reason,$note);
}




1;

