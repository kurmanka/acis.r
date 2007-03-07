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
  my $stylesheet = shift;
  my %para       = @_;

  debug "sending email with template '$stylesheet'";

  my $config = $app -> config;

  my %head = (
              "MIME-Version" => "1.0",
              "Content-transfer-encoding" => "8bit",
              From =>  $config-> {'system-email'},
              Subject => "default subject",
              'Content-type' => "text/plain; charset=UTF-8",
             );

  my $header = '';
  my $body;

  {
    my @presenteropt = ();
    if ( my $log = $app -> config( 'debug-email-data-log' ) ) {
      ###  Logging the generated email text
      my $home = $app -> home;
      my $feeddatastring = sub { 
        my $str = shift;
        if ( open F, ">>:utf8", $log ) {
          print F scalar( localtime ), "\n";
          print F $str, "\n";
          close F;
        } else { 
          warn "can't open log: $log";
        }
      };
      @presenteropt = ( -feeddatastring => $feeddatastring );
    }
             
    my $textref = $app -> run_presenter( $stylesheet, @presenteropt );
    # run_presenter() may return a string or a reference to a string:
    if (not ref $textref) { my $t = $textref; $textref = \$t; }
    debug "presenter generated: '''$$textref'''";

    ###  Presenter can generate email headers.  Here they are:
    my ( $pheaders, $pbody );
    if ( my $p = index( $$textref, "\n\n" ) > -1 ) {
      $pheaders = substr( $$textref, 0, $p );
      $pbody = substr( $$textref, $p+2 );

    } else {
      complain "can't find where headers end and body begins";
      die "can't find where headers end and body begins";
    }

#    debug "header part: '''$pheaders'''";
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

    # mail body has to be formatted before sending:
    $body = Web::App::EmailFormat::format_email( "$pbody\n" );
  }
  debug "body formatted: ", length( $body ), " chars";

  #  Now the user-supplied header parameters override the default and the
  #  presenter's ones.
  foreach ( keys %para ) {
    if ( m/^\-(\w.+)/ ) {
      my $k = ucfirst $1;
      my $v = $para{$_};
      $head{ $k } = $v;
      debug "from calling user: $k=($v)";
    }
  }

  #  Now we build a header string (from a hash) and encode the values in it
  foreach ( sort keys %head ) {
    my $name  = $_;
    my $value = $head{$name};
    my $val   = encode( 'MIME-Q', $value );
    ### XX a nasty hack to fix Encode's "feature":
    $val =~ s!\"\n\s+!\"!;  
    $header .= "$name: $val\n";
  }
  
  my $sendmail = $config -> {sendmail};
  if ( not defined $sendmail 
       or not $sendmail ) {
    debug "can't send email message, because no sendmail prog defined";
    return;
  }

  debug "open sendmail: $sendmail";
  if ( open MESSAGE, "|-:utf8", $sendmail ) {
    print MESSAGE $header, "\n", $body;
    close MESSAGE;
  } else {
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

}



1;
