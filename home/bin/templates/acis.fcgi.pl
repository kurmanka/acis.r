use strict;
use vars qw( $acis );
use FCGI;
use ACIS::Web;

# process id file
my $pidfile = $homedir . "/fcgi.pid";
if (open PID, ">$pidfile") {
  print PID $$;
  close PID;
} else {
  warn "can't create the pid file: $pidfile";
  undef $pidfile;
}
END {
  if ($pidfile) { unlink $pidfile; }
}

## not sure why we need this
umask 0000;
## create ACIS object
$acis = new ACIS::Web( );
## the request
my $request = FCGI::Request(\*STDIN, \*STDOUT, \*STDERR, \%ENV, FCGI::OpenSocket($homedir.'/acis.socket',5) );
## this variable can alter be used as an indicator whether we are running fcgi
$ACIS::FCGIReq = $request;
while ( $request->Accept() >= 0 ) {
  ## not known what this does
  #CGI::initialize_globals();
  eval { $acis -> handle_request; };
  my $error = $@;
  $acis -> clear_after_request;
  if ($error) { 
    ## writes the error to the apache error log
    warn $error;
  }
  ## not known what this does
  #undef $CGI::Q;
}


