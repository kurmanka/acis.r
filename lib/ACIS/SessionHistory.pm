package ACIS::SessionHistory;

# called from ACIS::Web::Session

use strict;
use warnings;
use Exporter qw(import);
use vars qw(@EXPORT);
@EXPORT = qw(session_stop session_start session_discard);
use Web::App::Common;

sub session_history_event {
  my ($sessionid,$login,$type,$act) = @_;
  my $sql = $ACIS::Web::ACIS -> sql_object;
  $sql -> prepare_cached( "insert into session_history values (NOW(),?,?,?,?)" );
  $sql -> execute( $sessionid,$login,$type,$act );  
}

sub session_stop {
  my ($session)=@_;
  my $sessionid=$session->id;
  my $login; 
  eval { $login=$session->object->{owner}->{login}; };
  complain( "can't find session's user login: $sessionid")
    if not $login;
  $login ||='unknown';
  my $type = $session->type;
  session_history_event($sessionid,$login,$type,'stop');
}


sub session_start {
  my ($session)=@_;
  my $sessionid=$session->id;
  my $login; 
  eval { $login=$session->object->{owner}->{login}; };
  if (not $login) {
#    complain( "can't find session's user login: $sessionid");
    $login = $session->owner->{login};
  }
  if (not $login) {
    complain( "can't find session's owner login: $sessionid");
    $login = 'unknown'; # XXX 
  }
  my $type = $session->type;
  session_history_event($sessionid,$login,$type,'start');
}

sub session_discard {
  my ($session)=@_;
  my $sessionid=$session->id;
  my $login; 
  eval { $login=$session->object->{owner}->{login}; };
  $login=$session->owner->{login}
    if not $login; 
  complain( "can't find session's user login: $sessionid"), $login='unknown'
    if not $login; 
  my $type = $session->type;
  session_history_event($sessionid,$login,$type,'discard');
}




1;
