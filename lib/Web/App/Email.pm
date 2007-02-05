package Web::App::Email;

use strict;
use Exporter;

use vars qw( @EXPORT @EXPORT_OK @ISA );

@ISA = qw( Exporter );
@EXPORT_OK = qw( send_mail );

use Web::App::Common;

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

    if ( $app -> config( 'debug-email-data-log' ) ) {
      my $log = $app -> config( 'debug-email-data-log' );
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
             
    my $text = $app -> run_presenter( $stylesheet,
                                      @presenteropt );
    if ( ref $text ) { $text = $$text; }

    ###  Presenter can generate email headers.  Here they are:

    debug "presenter generated: '''$text'''";
    
    my ( $pheaders, $pbody );
    if ( $text =~ m/^(.+?)\n\n+(.+)$/s ) {
      $pheaders = $1;
      $pbody    = $2;

    } else {
      die "presenter's text doesn't match: $text";
    }

#    debug "header part: '''$pheaders'''";

    foreach ( split /\n/, $pheaders ) {
      my ( $k, $v ) = $_ =~ /^([^:\s]+):\s+(.+)$/;
      
      if ( not $k
           or not $v ) {
        warn "bad header line: '$_'";
        next;
      }
      
      $k = ucfirst $k;
      $head{ $k } = $v;
      debug "from presenter: $k=($v)";
    }

    ###  Email body has to be formatted before sending though.
    require Web::App::EmailFormat;
    $body = Web::App::EmailFormat::format_email( "$pbody\n" );
  }


  ###  Now the user-supplied header parameters override the default and the
  ###  presenter's ones.
  foreach ( keys %para ) {
    if ( m/^\-(\w.+)/ ) {
      my $k = ucfirst $1;
      my $v = $para{$_};
      $head{ $k } = $v;
      debug "from calling user: $k=($v)";
    }
  }


  ###  Now building a header string (from a hash) and encoding the values in
  ###  it.

  use Encode qw( encode );

  foreach ( sort keys %head ) {
    my $name  = $_;
    my $value = $head {$name};

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
