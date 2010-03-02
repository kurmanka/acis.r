
use strict;
use vars qw( $acis );
use FCGI;
use ACIS::Web;

die if not $homedir;

$acis = new ACIS::Web( );

my $count = 0;

umask 0000;
my $socket = FCGI::OpenSocket( "$homedir/acis-fastcgi.sock", 20 ) or die;
my $request = FCGI::Request(\*STDIN, \*STDOUT, \*STDERR, \%ENV, $socket )
  or die;
#my $request = FCGI::Request();

$ACIS::FCGIReq = $request;

while ( $request->Accept() >= 0 ) {
  # CGI::initialize_globals();
  eval { $acis -> handle_request; };
  my $err = $@;
  $acis -> clear_after_request;
  if ($err) { warn $err; }
  undef $CGI::Q;
}

if ( $socket ) { FCGI::CloseSocket( $socket ); }


