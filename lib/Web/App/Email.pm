package Web::App::Email;

use strict;
use Exporter;

use vars qw( @EXPORT @EXPORT_OK @ISA );

@ISA = qw( Exporter );
@EXPORT_OK = qw( send_mail );

use Web::App::Common;
require Web::App::EmailFormat;
use Encode qw( encode );

##############################################################
####################   EMAIL  SENDING   ######################
##############################################################

sub send_mail {
  my $app        = shift;
  my $stylesheet = shift; # xslt stylesheet pathname 
  my $para       = shift || {}; # additional (overriding) message headers
  my $format     = shift; # apply additional formatting (Web::App::EmailFormat)? true/false

  debug "sending email with template '$stylesheet'";

  my $debug  = 0;
  my $config = $app -> config;

  ###  Default message headers:
  my %head = (
              "MIME-Version" => "1.0",
              "Content-transfer-encoding" => "8bit",
              From =>  $config-> {'system-email'},
              Subject => "default subject",
              'Content-type' => "text/plain; charset=UTF-8",
             );

  my $header = '';
  my $body;
  
  ###  Prepare for running the XSLT
  my @presenteropt = ();
  my $debug_email_data_log = $app -> config( 'debug-email-data-log' );

  if ( $debug_email_data_log ) {
    ### extra debugging: log the data passed to the presenter
    my $home = $app -> home;
    # special anonymous func
    my $feeddatastring = sub { 
      my $str = shift;
      if ( open F, ">>:utf8", $debug_email_data_log ) {
        print F scalar( localtime ), "\n";
        print F $str, "\n";
        close F;
      } else { 
        warn "can't open log: $debug_email_data_log";
      }
    };
    @presenteropt = ( -feeddatastring => $feeddatastring );
  }

  ###  Run XSLT
  my $textref = $app -> run_presenter( $stylesheet, @presenteropt );
  # run_presenter() may return a string or a reference to a string:
  if (not ref $textref) { my $t = $textref; $textref = \$t; }

  if ( $debug_email_data_log ) {
    if ( open F, ">>:utf8", $debug_email_data_log ) {
      print F scalar( localtime ), "\n";
      print F $$textref, "\n";
      close F;
    }
  }
  
  ###  Presenter can generate email headers. Split headers and body:
  my ( $pheaders, $pbody );
  if ( (my $p = index( $$textref, "\n\n" )) > -1 ) {
    $pheaders = substr( $$textref, 0, $p );
    $pbody    = substr( $$textref, $p+2 );
    
  } else {
    # this most probably means a bad email template
    die "can't find where headers end and body begins";
  }    

  $pheaders=~s|^\n||; # correct $pheaders, just in case (bad XSLT may generate an extra newline)

  ###  Parse headers
  foreach ( split /\n/, $pheaders ) {
    my ( $k, $v ) = $_ =~ /^([^:\s]+):\s+(.+)$/;
    if ( not $k or not $v ) {
      complain "bad header line: '$_'";
      next;
    }      
    $k = ucfirst $k;
    $head{ $k } = $v;
    debug "from presenter: $k=($v)";
  }


  if ($format) {
    # mail body has to be formatted before sending:
    $body = Web::App::EmailFormat::format_email( "$pbody\n" );
    debug "body formatted: ", length( $body ), " chars";
    #debug "body formatted: ", $body, "\n-------";  

  } else {
    $body = $pbody;
  }

  ###  Now the user-supplied header parameters override the default
  ###  and the presenter's ones.
  foreach ( keys %$para ) {
    if ( m/^\-(\w.+)/ ) {
      my $k = ucfirst $1;
      my $v = $para->{$_};
      $head{ $k } = $v;
      debug "from calling user: $k=($v)";
    }
  }

  ###  Now we build a header string (from a hash) and encode the
  ###  values in it.
  foreach ( sort keys %head ) {
    my $name  = $_;
    my $value = $head{$name};
    my $val   = encode( 'MIME-Q', $value );
    # a nasty hack to fix Encode's wrapping 'feature':
    $val =~ s!\"\n\s+!\"!;  
    $header .= "$name: $val\n";
  }
  
  my $sendmail = $config -> {sendmail};
  if ( not defined $sendmail 
       or not $sendmail ) {
    debug "can't send email message, because no sendmail command defined";
    return;
  }

  debug "open sendmail: $sendmail";
  if ( open MESSAGE, "|-:utf8", $sendmail ) {
    print MESSAGE $header, "\n", $body;
    close MESSAGE;
  } 
  else {
    $app -> errlog( "can't open a pipe to sendmail: $sendmail" );
    return undef;
  }
  
  my $to = $head{To};
  my $cc = $head{Cc};
  $app -> sevent ( -class => 'email',
                   -action => 'sent',
                   -template => $stylesheet,
                   -to => $to,
                   ($cc) ? ( -cc => $cc ) : ()
                 );
  return 1;
}



1;
