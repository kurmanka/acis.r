package ACIS::Web;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    ACIS core
#
#  Copyright (C) 2003 Ivan Baktcheev, (C) 2003-2007 Ivan Kurmanov for ACIS project,
#  http://acis.openlib.org/
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License, version 2, as
#  published by the Free Software Foundation.
# 
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#  ---
#  $Id$
#  ---

use strict;
use warnings;

use Carp qw( verbose cluck );
use Carp::Assert;
use Data::Dumper;
use Storable;
use Encode;

require sql_helper;
require Web::App;
use base qw( Web::App );

require Web::App::XSLT;
use Web::App::Common;
use ACIS::Data::DumpXML qw(dump_xml);
require ACIS::Web::Config;
require ACIS::Web::Session;
require ACIS::Web::Session::SNewUser;
require ACIS::Web::Session::SOldUser;
require ACIS::Web::Session::SMagic;
require ACIS::Web::Session::SAdminUser;

use vars qw ( $ACIS %SESSION_CLASS $SESSION_CLASS_MAIN );
*ACIS = *Web::App::APP;
$SESSION_CLASS_MAIN = "ACIS::Web::Session";
%SESSION_CLASS = (
 "user"     => "ACIS::Web::Session::SOldUser",
 "new-user" => "ACIS::Web::Session::SNewUser",
 "magic"    => "ACIS::Web::Session::SMagic",
 "admin-user" => "ACIS::Web::Session::SAdminUser",
);

require ACIS::Web::UserData;
require ACIS::Web::Services;

use ACIS::Web::SysVars;

sub basename { 'acis' };


require ACIS::LocalConfig;

sub new {
  my $class   = shift;
  my $params  = {@_};
  my $home    = $params -> {home};
  
  $home = $ACIS::LocalConfig::home_dir unless ( defined $home );
  assert( $home );

  $params -> {home}       = $home;
  $params -> {serializer} = \&dump_xml_serializer;
  $params -> {'presentation-builder-func'} = \&Web::App::XSLT::presentation_builder;

  debug "creating ACIS::Web object in $home";
  
  my $self = $class -> SUPER::new ( %$params );
  if ( $self -> config( "log-profiling-data" ) ) {
    $self -> {LOG_PROFILING} = 1;
    require Web::App::Profiling;
  }

  if ( $self -> config( "show-profiling-data" ) ) {
    $self -> {SHOW_PROFILING} = 1;
    require Web::App::Profiling;
  }

# we do not use Web::App::FormsProcessing, so we do not need this:
#  $self -> {CGI_UNTAINT_INCLUDE_PATH} = 'ACIS::Web::CGI::Untaint';
  return $self;
}


sub config {
  my ($self, $par) = @_;
  if ( defined $par ) {
    return $self ->{config} ->{lc $par};
  }
  $self->{config};
}


sub sql_object {
  my $self = shift;
  
  return $self -> {'sql-object'}
    if defined $self -> {'sql-object'};


  ### sql helper / driver module name
  my $class = 'sql_helper';

  $class -> set_log_filename ( $self ->{home} . '/opt/log/sql.log' );

  my $config = $self -> config;

  my $sql = $class ->
    new( $config -> {'db-name'}, 
         $config -> {'db-user'}, 
         $config -> {'db-pass'} )
      or return undef;

  $self -> {'sql-object'} = $sql;

#  $sql -> do( "SET CHARACTER SET utf8" );  ###  Set UTF8 as Perl<->Mysql
                                            ###  exchange charset.  Only works
                                            ###  for Mysql 4+
  
  return $self -> {'sql-object'};
}






sub dump_xml_serializer {
  my $data = shift;
  $ACIS::Data::DumpXML::INDENT = ' ';
  my $ret = ACIS::Data::DumpXML::dump_wo_refs( $data );
  for ( $ret ) {
    ### an optional UTF8 validity check  XX 
    if ( Encode::is_utf8( $_ ) ) {
      if ( not Encode::is_utf8( $_, 1 ) ) {
        warn "bad UTF8 dumped; recoding it safe\n";
        $_ = Encode::decode( 'utf8', $_, Encode::FB_PERLQQ );
      }
    }
  }
  return $ret;
}


sub init_presenter_data {
  my $self = shift;

  $self -> SUPER::init_presenter_data;

  ## copy some of the configuration parameters into
  ## presenter-data/system/config
  ## this includes the pitman and cardiff parameters
  my $config = $self -> config;
  my @copy = qw( institutions-maintainer-email research-auto-search-disabled 
                 above-me-propose-accept below-me-propose-refuse chunk-size 
                 service-mode
  );
  my $pconf = $self -> {'presenter-data'} -> {'system'} -> {'config'};
  foreach ( @copy ) {
    $pconf ->{$_} = $config ->{$_};
  }
}



sub parse_request_url {
  my $self = shift;
  my $url  = shift;
  my $full = shift;

  my ( $screen, $session ) = $self -> SUPER::parse_request_url( $url, $full );

  my $req  = $self -> {request};
  if ( $screen and $screen =~ m!^(\w+\d+)/(.+)! ) {  ### (p\w+\d+) XXX
    $screen = $2;
    $req -> {screen}     = $screen;
    $req -> {'short-id'} = $1;
  }

  my $cooki = $self -> get_cookie( 'session' );
  if ( $cooki ) {
    debug "session id cookie: $cooki";
    if ( $session ) {
      if ( $cooki ne $session ) { ###  Conflict. Which one should we obey?
        $self -> set_cookie( -name  => 'session',
                             -value => $session );
      }
    } 
    else {
        $session = $cooki;
        $req -> {'session-id'} = $session;
        $req -> {'session-id-from-cookie'} = 1;
    }
  }
  return ( $screen, $session );
}


sub find_right_screen {
  my $self = shift;
  my $scr = shift;
  debug "find_right_screen: enter";
  my $res = $self -> SUPER::find_right_screen( $scr );

  if ( not $res ) {
    require ACIS::Web::Site;
    my $r = ACIS::Web::Site::serve_local_document( $self );
    if ( $r ) {
      debug "find_right_screen: exit with putting responsibility on <local-document>";
      $self -> request -> {responsibility_of} = "local-document";
      return $scr;
    }
  }
  no warnings;
  debug "find_right_screen: exit with <$res>";
  return $res;
}
    


sub handle_request {
  my $self = shift;
  # refuse to handle if service.blocked flag is set
  if ( $self->sysflag( 'service.blocked' ) ) {
    if ( my $msg = $self->sysvar( 'service.blocked.message' ) ) {
      return print $msg;
    }
    return print "Status: 503\nCache-Control: no-cache\nPragma: no-cache\nContent-Type: text/plain\n\nService Unavailable\n";
  } 
  $self->SUPER::handle_request( @_ );
}

sub post_process_content {
  my $self = shift;
  my $out  = shift;
  my $body;
  # assume $out is a string reference; even if not, make it so
  if ( not ref $out ) { $body = \$out; } else { $body = $out; }
  
  if ( my $msg = $self->sysvar( 'service.announcement' ) ) {
    my $mark = '<!-- service.announcement go here -->';
    my $index = index( $$body, $mark );
    if ( $index > -1 ) {
      substr( $$body, $index+length($mark), 0, "<div class='PSA'>$msg</div>" );
    }
  }

  $self->SUPER::post_process_content( $out );
}


sub set_auth_cookies { 
  my $self  = shift;
  my $login = shift;
  my $pass  = shift;

  if ( defined $login ) {
    $self -> set_authentication_cookie( 'login', $login );
  }
  if ( defined $pass ) {
    $self -> set_authentication_cookie( 'pass' , $pass  );
  }
  debug "authentication cookies set:" . ( ($login) ? " login" : "" ) . 
    ( ($pass) ? " pass": "" );
}


sub clear_auth_cookies { 
  my $self = shift;
  $self -> set_authentication_cookie( 'login', '', 1 );
  $self -> set_authentication_cookie( 'pass' , '', 1 );
}

sub get_auto_logon_mode {
  my $self = shift;
  my $session = $self -> session;

  if ( $session ) {
    my $owner = $session -> userdata_owner;
    my $login = $owner -> {login};
    my $pass  = $owner -> {password};
    my $resp_cookies = $self ->{response}{cookies};

    my $cookie_login = $resp_cookies->{login} || $self -> get_cookie( 'login' );
    my $cookie_pass  = $resp_cookies->{pass}  || $self -> get_cookie( 'pass'  );

    if ( $cookie_login and $cookie_login eq $login ) {
      if ( $cookie_pass
#          and $cookie_pass eq $pass
         ) { return 'full' ; }
      else { return 'login'; }

    } else { return 'off'  ; }

  }
  return undef;
}


sub set_authentication_cookie { 
  my ($self, $name, $value, $clear) = @_;
  $self -> set_cookie( -name  => $name,
                       -value => $value,
                     -expires => ($clear) ? '+0m' : '+6M', );
}


sub prepare_presenter_data {
  my $self = shift;
  $self -> SUPER::prepare_presenter_data();
  
  my $session = $self->session;
  if ($session) {
      my $rec = $session->current_record;
      if ($rec) { $self->set_current_record ($rec); }
  }

  if ( defined $self->{request}{'short-id'} ) {
    $self->{'presenter-data'}{request}{'short-id'} = $self->{request}{'short-id'};
  }
}

sub redirect_to_screen_for_record {
  my $self   = shift;
  my $screen = shift;
  
  my $sid = $self -> session -> current_record -> {sid};
  if ( substr( $sid, 0, 1 ) eq 'p' ) { 
    ## a real shortid
    $self -> redirect_to_screen( "$sid/$screen" );  
  } 
  else {                             
    ## a shortid placeholder
    $self -> redirect_to_screen( $screen );  
  }    
}


sub get_url_of_a_screen {
  my $self   = shift;
  my $screen = shift;
  my $rec_sid = $self -> session -> current_record -> {sid};
  if ( $rec_sid =~ m/^p/ ) { 
    $screen = "$rec_sid/$screen";
  }
  return $self -> SUPER::get_url_of_a_screen( $screen );
}


sub record {
  my $self = shift;
  if ( $self -> {session} ) {
    $self -> {session} -> current_record;
  }
}
 

sub userdata_dir {  
  my $self = shift;
  my $home = $self -> {home};
  return "$home/userdata";
}  


sub userdata_file_for_login {
  my $self  = shift;
  my $login = shift || die;
  $login = lc $login;
  my $word_login = $login;
  $word_login =~ s/[^a-z0-9]//g;
  my ( $fl, $sl ) = unpack( 'aa', $word_login );
  my $udata_dir  = $self -> userdata_dir;
  my $safe = $login;
  $safe =~ s![\s|;><\\/]!!g;  ### security - remove unsafe characters
  my $udata_file = "$udata_dir/$fl/$sl/$safe.xml";

  if ( not -f $udata_file ) { ### this sometimes creates spurious directories
    force_dir( $udata_dir, "$fl/$sl");
  }
  return $udata_file;
}


sub make_paths_for_login {
  my $self  = shift;
  my $login = shift || die;
  my $paths = shift || {};
  my $udata_file = $self -> userdata_file_for_login( $login );
  my $udata_lock = "${udata_file}.lock";

  $paths -> { 'user-data'      } = $udata_file;
  $paths -> { 'user-data-old'  } = $udata_file;
  $paths -> { 'user-data-lock' } = $udata_lock;

  my $homedir = $self -> home;
  my $safe    = lc $login;
  $safe =~ s![|;><\\/]!!g;  ### drop unsafe characters
  my $deleted = "${homedir}/deleted-userdata/${safe}.xml"; 
  $paths -> { 'user-data-deleted' } = $deleted; 

  return $paths;
}  

sub update_paths_for_login {
  my $self  = shift;
  my $login = shift || die;

  ### update paths
  my $paths = $self ->{paths} = 
    $self ->make_paths_for_login( $login, $self ->{paths} );
  return $paths;
}


sub set_current_record {
    my $self   = shift;
    my $record = shift;

    if ( $record ) {
        my $cur_rec = {
            id      => $record -> {id},
            name    => $record -> {name} {full},
            type    => $record -> {type},
            shortid => $record -> {sid},             };
        if ( $record->{'about-owner'} ) {
            $cur_rec ->{'about-owner'} = $record ->{'about-owner'};
        }
        my $preq = $self -> {'presenter-data'} {request};
        $preq -> {session} {'current-record'} = $cur_rec;
    }
}

sub session {
  my $self    = shift;
  my $session = shift;
  if ( not defined $session ) { return $self->{session}; }

  $self -> SUPER::session( $session );

  $self -> set_username( $session -> username );
    
  my $id       = $session ->id;
  my $type     = $session ->type;
#  my $userdata = $session ->object;
#  my $realuser = '';
#  if ( $userdata ) { $realuser = $userdata->{owner}->{login}; }
#  if ( $realuser ) { $realuser = " for user $realuser";  }
#  $self -> userlog ( "using session $id ($type)$realuser" );

#  $

  return $session;
}


sub update_paths {
  my $self  = shift;
  my $paths = $self ->{paths};
  if ( defined $self -> {session} ) {
    my $session = $self -> session;
    my $home    = $self -> {home};
    return undef if not $session ->userdata_owner;

    my $owner   = $session -> userdata_owner;
    
    if ( $owner ) {
      my $login    = $owner ->{login};
      my $oldlogin = $owner ->{'old-login'};
      if ( $login ) {
        $paths = $self ->update_paths_for_login( $login );
      }
      if ( $oldlogin ) {
        my $old_userdata_file = $self ->userdata_file_for_login( $oldlogin );
        $paths -> {'user-data-lock'} = "$old_userdata_file.lock";
        $paths -> {'user-data-old' } = $old_userdata_file;
      } # if $oldlogin
    }
  } 
  return $paths;
}


sub clear_after_request {
  my $self = shift;
  if ( $ACIS::Web::Citations::{cleanup} ) { eval {ACIS::Web::Citations::cleanup()}; undef $@; }
  if ( $ACIS::Web::Contributions::{cleanup} ) { eval {ACIS::Web::Contributions::cleanup()}; undef $@; }
  $self-> SUPER::clear_after_request();
}


####################   E V E N T S   ##############################

my @events_fields = qw( type class action descr data chain startend );
my %evFields;
foreach ( @events_fields ) {
  $evFields{$_} = 1;
}

my $events_question_marks = join ",", split( '', "?" x scalar @events_fields );
my $events_table_fields   = join( ',', @events_fields );
my $insert_event_query = 
        "insert into events ( date, $events_table_fields )"
      . " values ( NOW(), $events_question_marks )";

sub event {
  my $self = shift;
  my %p    = @_;
  my $sql = $self -> sql_object;
  if(not $sql) {
     return;
  }
  if ( not $p{-data} ) {
    my @data = ();
    foreach ( keys %p ) {
      my $f = substr( $_, 1 );
      if ( not $evFields{$f} ) {
        no warnings;
        push @data, "${f}: " . $p{$_};
        delete $p{$_};
      }
    }
    no warnings;
    $p{-data} = Encode::encode_utf8( join "\n", @data );
  }

  my @val = ();
  foreach ( @events_fields ) {
    push @val, $p{"-$_"};
  }
  $sql -> prepare_cached( $insert_event_query );
  $sql -> execute( @val );
}



sub get_recent_events {
   my $self = shift; 
   my $period = shift || 24; ### hours
   my $sql = $self -> sql_object();
   my $stat = "select * from events where date > DATE_SUB( NOW(), INTERVAL ? HOUR) ".
     "ORDER BY date ASC, startend DESC ";
   $sql -> prepare_cached( $stat );
   my $r = $sql -> execute( $period );
   if ( $r ) { return $r; }
   return undef;
}

################################   END OF EVENTS   ############################


sub dump_presenter_xml {
  my $self = shift;
  $self -> prepare_presenter_data;
  my $xml = $self -> serialize_presenter_data;
  my $response = $self-> {response};
  undef $response -> {HTML};
  $response -> {body} = $xml;
  $response -> {charset} = 'utf-8';
  print STDOUT "Content-type: application/xml; charset=utf-8\n";
  $response -> {'content-type-printed'} = 1;  
}


sub dump_variables_xml {
  my $self = shift;
  $self -> {'presenter-data'} = $self -> variables;  
  my $xml = $self -> serialize_presenter_data;
  my $response = $self-> {response};
  undef $response -> {HTML};
  $response -> {body} = $xml;
  $response -> {charset} = 'utf-8';
  debug "xml response: $xml";
  print STDOUT "Content-type: application/xml; charset=utf-8\n";
  $response -> {'content-type-printed'} = 1;  
}


sub sql { $_[0]->sql_object }


# send_mail() method wrapper around Web::App::Email

require Web::App::Email;
sub send_mail {
  my $self = shift;
  my $stylesheet = shift;
  my $params = shift;
  my $format = shift;
  return Web::App::Email::send_mail( $self, $stylesheet, $params, $format );
}



use RePEc::Index::UpdateClient;

sub send_update_request {
    my $self = shift;
    my $collection = shift;
    my $path = shift;

    # special handling in case of FastCGI
    my $request = $ACIS::FCGIReq;
    if ($request) {
        $request->Detach();
    }

    ###  request RI update
    $self -> log( "requesting RI update for $path in $collection" );
    RePEc::Index::UpdateClient::send_update_request( $collection, $path );
    
    if ($request) {
        $request->Attach();
    }
}

# Do not log the users' passwords to debug.log

my $UNSAFE_TO_LOG = {
    'pass'         => 1,
    'pass-confirm' => 1,
    'pass-new'     => 1,
};

sub safe_to_log_form_input { 
    shift; 
    my $input = shift;
    my $out = {};
    foreach ( keys %$input ) {
        my $k = $_;
        my $v = $input->{$k};
        if (exists $UNSAFE_TO_LOG->{$k}) { $out->{$k} = '#######'; }
        else { $out->{$k} = $v; }
    }
    return $out; 
};


 
1;

__END__

=head1 NAME

ACIS::Web

=head1 SYNOPSIS

 use ACIS::Web;
 my $acis = new ACIS::Web ( 'home' => 't/acis-home' );

 $acis -> handle_request;
 $acis -> clear_after_request;

=head1 LICENSE

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
