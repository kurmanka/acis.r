package ACIS::Citations::Events;

use strict;

use Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw( cit_event );

#  cit_event( $citation->{cnid}, $rec->{sid}, $dsid, "autoadded", $citation->{autoaddreason}, $note );
sub cit_event {
  my ($cnid,$psid,$dsid,$event,$reason,$note) = @_;
  my $sql = $ACIS::Web::ACIS->sql_object;

  $sql -> prepare_cached( "insert into citation_events (cnid,psid,dsid,event,reason,note,time) VALUES (?,?,?,?,?,?,NOW())" );
  $sql -> execute($cnid,$psid,$dsid,$event,$reason,$note);
}




1;

