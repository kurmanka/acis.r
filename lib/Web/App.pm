package Web::App;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Core of the web application framework, the Web::App module
#
#
#  Copyright (C) 2003 Ivan Baktcheev, Ivan Kurmanov for ACIS project,
#  http://acis.openlib.org/
#
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
#  $Id: App.pm,v 2.4 2006/01/27 09:56:46 ivan Exp $
#  ---


use strict;
use warnings;

use open ":utf8";

#use Carp qw( verbose );
use Carp qw( cluck );

use Carp::Assert;
use CGI;
use CGI::Untaint;
use Data::Dumper;
use Encode;
use Storable;

# use CGI::Carp qw( fatalsToBrowser set_message carpout );


use sql_helper;


#BEGIN { set_message( \&Web::App::Common::critical_message ); }

#use Web::App::Config;

BEGIN { 
  use Web::App::Common qw( debug debug_as_is );
  if ( $ENV{HTTP_HOST} ) {
    eval " use CGI::Carp qw( fatalsToBrowser set_message ); ";
#  set_message( sub { print '<h1>fuck!</h1><p>', \$_[0], '</p>'; } ); ";
#  set_message( \&Web::App::Common::critical_message ); ";
    if ( $@ ) { 
      warn "Problem when I tried to use CGI::Carp: $@";
    }

  } else {
    eval "use Carp qw( verbose );";
  }
}


require Web::App::Common;
import  Web::App::Common 'date_now';



use vars qw( $APP );


sub basename { 'app' }

sub new {
  my $class   = shift;
  my $params  = {@_};
  my $home    = $params -> {home};
  
  my $screen_file = $params -> {'screens-file'} || 'screens.xml';
  my $config_file = $params -> {'config-file'};

  my $basename = $class -> basename;

  if ( not $config_file ) { $config_file = "$basename.conf"; }

  debug "creating Web::App object in $home";
  
  my $self    =   {
                   %$params, 
    'config-file' => $config_file,
    'screens-file' => $screen_file,
    'home'        => $home,
    'session'     => undef,
    'sessionfile' => undef,
    'variables'   => {},
    'username'    => undef,

    'response'    => {},
  };
  
  bless $self, $class;

  debug 'load configuration';
  
  if ( $params -> {PARSE_CONFIG} ) {
    $self -> parse_config;
  } else {
    $self -> get_config;
  }
  
  my $screenconf = $self -> {screenconf};
  foreach my $module ( @{ $screenconf -> {modules} } ) {
    eval "use $module;";
    warn $@ if $@;
  }


  my $config = $self->{config};

  my $template_set = $config -> {'template-set'};
  my $shared       = $config -> {'static-base-dir'};
  my $static       = $config -> {'static-base-url'};

  my $paths = {
    'home'        => $home,
    'shared'      => $shared,
    'static'      => $static,
    'presenters'  => "$home/presentation/$template_set",
    'log'         => "$home/$basename.log",
    'errlog'      => "$home/$basename-err.log",
    'sessions'    => "$home/sessions",
  };


  $self -> {paths} = $paths;

  ###  set umask, if defined
  if ( $config -> {umask} ) {
    umask( $config -> {umask} );
  }

  if ( $config -> {'require-modules'} ) {
    my @list = split /\s+/, $config -> {'require-modules'};
    foreach ( @list ) {
      if ( m/::/ 
           or not( $_ =~ m!\.! )
         ) {
        $_ =~ s!::!/!g;
        $_ .= '.pm';
      }
      require $_;
    }
  }


  $self -> init_presenter_data();

  $APP = $self;
  return $self;
}


###  Some configuration parameters in $self:

#    PARSE_CONFIG -- parse the configuration files or, as by default, use the
#    binary images if they are there.

#    NO_TRIMMING -- do not trim leading/trailing whitespace off the form input
#    values

#    CGI_UNTAINT_INCLUDE_PATH -- the module prefix to use when
#    CGI::Untait-checking form input.

#    'presentation-builder-func' -- the func to call for presenter

#    'presentation-params -- additional parameters for the presenter func

#    ...
#    to be continued

#  and now those similar / related via $self->{config}:

#    'default-screen-name', "index",
#    'screen-not-found',    "sorry",

#    'character-encoding',  'utf-8',
#    'input-space-normalize', 'true',
    



sub configuration_parameters {

  return {
    # global parameters
    'site-name',        'required',
    'site-name-long',   'required',
    'admin-email',      'required',
    'log-verbosity',    'not-defined',

#    'production-mode',  'true',
    'debug',            'not-defined',

    'require-modules',  'not-defined',
    
    # web interface
    'base-url',         'required',
    'template-set',     'default',
    'debug-info-visible', '',
    'debug-log',          '',
    'home-url', "not-defined",
    'debug-transformations', '',
    'umask',   'not-defined',           # '0022'
    'requests-log',     '*stderr*',

    'default-screen-name', "index",
    'screen-not-found',    "sorry",

    'character-encoding',  'utf-8',
    'input-space-normalize', 'true',
    
    


    # email-related
    'system-email',     'required',
    'sendmail',         'required',

    # database parameters
    'db-name',          'required',
    'db-user',          'required',
    'db-pass',          'required',

    # debug 
    'debug-email-data-log',  'not-defined',


   };


}




sub init_presenter_data {
  my $self = shift;

  my $config = $self -> config;

  my $data = $self -> {'presenter-data'} =  {

    system => {
      config => {
        debug        => $Web::App::DEBUG,
      },
    },

    request => {
    },

    response => {
      data    => $self -> {variables},
    },
  };


  ###  copy some of the configuration parameters into
  ###  $presenter-data/system/config
  {
    my @config_params_copy =
      qw( base-url site-name site-name-long 
          admin-email 
          system-email 
          static-base-url home-url );

    my $data_conf = $data -> {system} {config};

    foreach ( @config_params_copy ) {
      if ( $config -> {$_} ) {
        $data_conf -> {$_} = $config -> {$_};
      }
    }

    $data_conf-> {home} = $self -> {home};
  }

}





##############################################################
###  here come some small but important tools
##############################################################

sub error {
  my $self     = shift;
  my $error_id = shift;
  my $add      = shift;

  if ( $error_id ) {
    $self -> set_error( $error_id );
    $self -> sevent (
                     -type  => 'error',
                     -class => 'processing',
                     -code  => $error_id,
                     (ref $add) ? ( %$add ) : (),
                    );

  } else {
    return $self -> {'presenter-data'} {response} {error};
  }
}

sub set_error {
  my $self = shift;
  my $errid = shift;
  $self -> {'presenter-data'} {response} {error} = $errid;
}

sub message {
  my $self = shift;
  my $message_id = shift;

  if ( defined $message_id ) {

    if ( $message_id ) {
      $self -> {'presenter-data'} {response} {message} = $message_id;
    } else {
      delete $self -> {'presenter-data'} {response} {message};
    }

  } else {
    return $self -> {'presenter-data'} {response} {message};
  }
}


sub success {
  my $self = shift;
  my $success = shift;

  if ( $success ) {
    $self -> {'presenter-data'} {response} {success} = $success;
  } else { 
    return $self -> {'presenter-data'} {response} {success};
  }
}


sub refresh {
  my $self = shift;
  my $time = shift;
  my $url  = shift;

  my $refresh = {
       time => $time,
      };

  my $urlpart = '';
  if ( defined $url ) {
    $refresh -> {url} = $url;
    $urlpart = "; url=$url";
  }

  $self -> {'presenter-data'} {response} {refresh} 
    = $refresh;

  my $header = "Refresh: $time$urlpart\n";

  my $o =  $self -> {http_headers} || '';
  $self -> {http_headers} = $o . $header;

}


####################################################################33
#  configuration


sub get_config {
  my $self = shift;

  return undef
      if $self -> {config};
  
  my $home = $self -> {home};

  my $config_bin = "$home/config.bin";

  if ( -f $config_bin ) {

    eval { 
      use Storable qw( retrieve );
                              
      my $list = retrieve $config_bin;
      
      my $sc = $self -> {screenconf} = $list->[0];
      my $mc = $self -> {config}     = $list->[1];

      assert( $mc ->{'base-url'}    );
      assert( $mc ->{'site-name'}   );
      assert( $mc ->{'admin-email'} );
    };

    if ( not $@ ) { return; }
    else {
      warn "Can't load compiled config snapshot: $@\n";
    }
  } 

  $self -> parse_config;
}


sub parse_config {
  my $self = shift;

  return if $self -> {config_parsed};

  my $home = $self -> {home};

  my $conf_file   = $home . '/' . $self -> {'config-file'};
  my $screen_file = $home . '/' . $self -> {'screens-file'};

  if ( not -f $conf_file ) {
    die "Can't read application config from file $conf_file: file not found";
  }

 
  require Web::App::Config::Parse;

  my $screenconf = Web::App::Config::read_screens_file( $self, {}, $screen_file );
  $self -> {screenconf} = $screenconf;
  
  my $siteconf    = Web::App::Config::read_local_configuration( $self, {}, $conf_file );
  assert( $siteconf );
  $self -> {config} = $siteconf;
  

  use Storable qw( store );
  store [ $screenconf, $siteconf ], "$home/config.bin.new";
  rename( "$home/config.bin.new", "$home/config.bin" );

  $self -> {config_parsed} = 1;
}


sub get_screen {
  my $self = shift;
  my $name = shift;
  return $self->{screenconf} {screens} {$name};
}



sub config {
  my $self = shift;

  my $par  = shift;
  if ( defined $par ) {
    return $self ->{config} ->{$par};
  }
  
  return $self -> {config}
      if $self -> {config};
  
}


##
######################################################################


sub paths { 
  my $self = shift;
  
  if ( $_[0] ) {
    my $par = shift;
    return $self ->{paths} -> {$par};
  }

  return $self -> {paths};
}



sub home {
  my $self = shift;
  return $self -> {home};
}

sub sessions_dir { 
  my $self = shift;
  my $home = $self -> {home};
  return "$home/sessions";
}


sub variables {
  my $self = shift;
  return $self -> {variables};
}


sub request {
  my $self = shift;
  return $self -> {request};
}

sub response {
  my $self = shift;
  return $self -> {response};
}

sub form_input { 
  my $self = shift;
  return $self -> {request} {params};
}

# caution: not only returns form values, but also cookies

sub request_input {
  my $self = shift;
  my $name = shift;

  my $request = $self -> {request};
  if ( exists $request -> {params} {$name} ) {
    return $request -> {params} {$name};

  } else {
    return $self -> get_cookie( $name );
  }
}



###  helper 2004-07-08 11:55
sub record {
  my $self = shift;
  if ( $self -> {session} ) {
    $self -> {session} -> current_record;
  }
}
 

sub session {
  my $self    = shift;
  my $session = shift;

  if ( defined $session ) {

    if ( $self->{session} ) {
      assert( $session == $self->{session} );

    } else {
      assert( not ( $self->{session} ), "overwriting a session in Web::App object?" );
    }

    $self -> {session} = $session;
    $self -> update_paths;

    my $prequest =  $self -> {'presenter-data'} {request};

    $prequest -> {session} =  {
       'id'   => $session -> id,
       'type' => $session -> type,
    };
    
    $prequest -> {user}    = $session -> owner;

    return $session;
  }

  return $self -> {session};
}




sub sql_object {
  my $self = shift;
  
  return $self -> {'sql-object'}
    if defined $self -> {'sql-object'};


  ### sql helper / driver module name
  my $class = 'sql_helper';

  $class -> set_log_filename ( $self ->{home} . '/sql.log' );

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




sub update_paths {
  my $self  = shift;
  my $paths = $self -> {paths};

  if ( defined $self -> {session} ) {
    my $session = $self -> session;
    my $home    = $self -> {home};

    ###  One could prepare itself for the comming work
    ###  in the session context

  } 

  return $paths;
}



sub set_username {
  my $self = shift;
  my $username = shift;
  assert( $username );
  $self -> {username} = $username;
  debug "username: $username";
}

sub username {
  my $self = shift;
  return $self -> {username};  
}



sub find_right_screen {

  # we have a request, we need to find out to which screen it belongs, which
  # screen is responsible for processing it.  That's the task of this method.

  my $self   = shift;
  my $screen = shift;
  
  $screen =~ s!^/!!g; ### just to be sure
  $screen =~ s!/$!!g;

  if ( $self -> get_screen( $screen ) ) { 
    return $screen; 
  }

  my $subscreen;
  my $screen_rev = reverse $screen;
  
  while ( $screen_rev =~ m!([^/]+)/(.+)! ) {
    $screen_rev = $2;
    my $substep = reverse $1;
    if ( $subscreen ) {
      $subscreen = "$substep/$subscreen";
    } else {
      $subscreen = $substep;
    }
    
    my $screen_maybe = reverse $screen_rev;
    my $the_screen   = $self -> get_screen( $screen_maybe );
    if ( $the_screen ) { 
      $self -> {request} {screen}    = $screen_maybe;
      $self -> {request} {subscreen} = $subscreen;
      return $screen_maybe;
    }
  }

  return undef;
}


sub clear_after_request {
  my $self = shift;

  debug "clearing";

  foreach ( qw( request response username session
                http_headers content_type
                presenter
                presenter_data_string
              ) ) {
    $self -> {$_}   = undef;
  }

  ###  presenter-data
  $self -> {variables} = {};
  $self -> init_presenter_data; 

  
  my $paths = $self -> {paths};
  
  foreach ( qw( personal-path session user-data 
                personal-url user-data-lock user-data-old
              ) ) {
    delete $paths -> {$_};
  }

  CGI::Minimal::reset_globals();
}




#######################################################
########     h a n d l e    r e q u e s t     #########
#######################################################
###  main processing entry point
###

sub handle_request {
  my $self    = shift;

  $APP = $self;

  my $config  = $self ->{config};
  my $homedir = $self ->{home};
  my $paths   = $self ->{paths};


  $self -> time_checkpoint( 'handle_request' );

  print "\n\n<pre>"
    if $Web::App::DEBUGIMMEDIATELY;


  ###  primary request analysis

  debug "fetch request data";

  use CGI::Minimal;
  my $query = new CGI::Minimal;

  debug "CGI object: $query";

  my $unescaped_url = $ENV{REQUEST_URI} || '';

  ### this needs to be fixed to take care of non-ascii chars (in an encoding)
  ### and unicode-specified chars (%u[\da-z]{4}) if they are to be used in
  ### screen names:
  $unescaped_url =~ s/%(\w\w)/chr(hex($1))/eg;

  my $hostname  = $ENV{HTTP_HOST} || '';
  my $requested_url = "http://$hostname$unescaped_url";

  my $request = $self -> {request} = {
    CGI     => $query,
    referer => $ENV{HTTP_REFERER},
    agent   => $ENV{HTTP_USER_AGENT},
    method  => $ENV{REQUEST_METHOD},
    querystring => $ENV{QUERY_STRING},
  };

  debug "REQUEST_METHOD: ", $request->{method} || '';


  ### some mode settings

  my $charset = lc $config->{'character-encoding'};
  my $debug_mode = $config->{debug};

  $self -> {response} = 
    { headers => [], 
      charset => $charset,
    };


  my ( $screen_name, $session_id ) = $self ->parse_request_url( $requested_url );

  if ( $config ->{'requests-log'} ) {
    my $log = $config ->{'requests-log'};
    my $the_request = $request -> {url} . " [$$]";
    if ( $log eq '*stderr*' ) {
      print STDERR "request: $the_request\n";
    } elsif ( open LOG, '>>', $log ) {
      print LOG scalar( localtime ), " ", $the_request, "\n";
      close LOG;
    }
  }


  if ( not $screen_name ) {
    ### default screen name
    $screen_name = $config -> {'default-screen-name'};
  }
  debug "this is request for screen: $screen_name";


  my @event = ( -class  => 'request', 
                -screen => $screen_name );

  if ( defined $session_id ) {
    debug "request of session: $session_id";

    $paths ->{session}    = "$homedir/sessions/$session_id";
    push @event, -session => $session_id;

  } else {
    delete $paths->{session}; 
  }


  ###  process form input parameters


  my $space_norm = $config -> {'input-space-normalize'};
  my @par_names  = $query -> param;

  my $form_input = { };

  foreach ( @par_names ) {
    my @val = $query -> param( $_ );

    foreach ( @val ) {
      $_ = Encode::decode( $charset, $_ );
      if ( $space_norm ) {
        ### starting/trailing space normalization
        $_ =~ s/(^\s+|\s+$)//g; 
      }
    }

    if ( scalar( @val ) == 1 ) {
      $form_input ->{$_} = $val[0];

    } else {
      $form_input ->{$_} = \@val;
    }
  }

  if ( $debug_mode ) {
    if ( scalar keys %$form_input ) {
      my $dump = Data::Dumper->Dump( [$form_input], ['form_input'] );
      chomp $dump;
      debug $dump;

    } else { 
      debug "\$form_input = {};"; 
    }
  }
  $request ->{params} = $form_input;


  if ( not defined $self -> get_screen( $screen_name ) ) {
    ###  something else can be here, something more general

    my $try = $self -> find_right_screen( $screen_name );

    if ( not $try ) {
 
      my $ref = $request -> {referer};
      $self -> event( -class  => 'request',
                       -type   => 'error',
#                      -screen => $screen_name,
                      -request => $request ->{url},
      ($session_id) ? ( -chain => $session_id ) : (),
           ($ref) ? ( -referer => $ref ) : (),
                      -descr  => '404' );

      $self -> response_status( "404 Not found" );
     
      $self -> set_error( 'screen-not-found' );
      $screen_name = $config -> {'screen-not-found'};

    } else {
      $screen_name = $try;
    }
  }

  my $responsible = $screen_name;

  if ( $request -> {responsibility_of} ) {
    $responsible = $request -> {responsibility_of};
  }

  $self -> add_to_process_queue( $responsible );
  $self -> set_presenter( $responsible );

  
  ###  handle the request by running the processors

  $self -> time_checkpoint( 'before_processors' );
  while ( my $processor = $self -> next_processor )  {
    debug "launch '$processor'";

    if ( $processor =~ /::/ ) {
      ###  function call
      no strict;
      &$processor ($self);

    } else {
      ###  method call
      no strict;
      $self -> $processor;
    }
  }
  
  debug "processors finished";

  $self -> time_checkpoint( 'processors' );

  {
    my $sub = $request->{subscreen};
    $self -> sevent( -class  => 'request',
                     -screen => $screen_name,
                     $sub ? ( -sub => $sub ) : (),
                     -action => 'handled' );
  }

  my $session = $self -> session;
  
  if ( $session ) {
    $session -> save;
    debug "session saved";
  }

  

  ###  prepare and send response

  ###  first send the headers
  $self -> print_http_response_headers;

  if ( $self -> {presenter} ) {

    ###  prepare presenter-data 
    $self -> prepare_presenter_data;

    $self -> {response}{body} = 
      my $content = 
        $self -> run_presenter( $self->{presenter} );

    print "</pre>\n"
      if $Web::App::DEBUGIMMEDIATELY;

    $self -> time_checkpoint( 'presenter' );

    $self -> post_process_content( \$content );

    $charset = $self->{response}{charset};

    ###  now go, print the resulting page

    if ( $charset ne 'utf-8' ) {
      binmode STDOUT, ":encoding($charset)"; 
    } else {
      binmode STDOUT, ":utf8"; 
    }
    $/=undef;
    print STDOUT $content;

  }

  $self -> post_scriptum;


}
####   e n d    o f    h a n d l e   r e q u e s t   s u b 



sub run_presenter {
  my $self      = shift;
  my $presenter = shift;
  my $params    = $self->{'presentation-params'} || [];
  
  my $presentation_builder_func = $self->{'presentation-builder-func'};

  if ( $presentation_builder_func ) {
    return &$presentation_builder_func( $self, $presenter, 
                                        @_, @$params );
  } 

  die "presentation-builder-func is not defined";
}



sub post_process_content {
  my $self = shift;
  my $out  = shift;

  
  ### add debuggings to the content

  my $vars_xml_dumped = $self -> {presenter_data_string};

  if ( $self ->{config} {'debug-info-visible'} ) {

    my $log =  $Web::App::Common::LOGCONTENTS;
    
    my $debuggings = <<_DEBUG_INCLUDE;

   <p>&nbsp;</p>
   <p><a href='#debug' 
   onclick='javascript:document.getElementById("debug").style.display="block";'
   >Show debug info</a></p>

   <div class='debug' id='debug' style='display:none'>
     <p>Debug messages:</p>
     <textarea cols='110' rows='30' 
       style='font-size: 12px;'>$log</textarea>
     <p>Presenter's data:</p>
     <textarea cols='110' rows='40'
        style='font-size: 12px;'>$vars_xml_dumped</textarea>
   </div>

_DEBUG_INCLUDE

    my $debug_mark = '<!-- debuggings go here -->';
    if ( $$out =~ /$debug_mark/ ) {
      my $mark = $debug_mark;
      $$out =~ s/$mark/$mark$debuggings/;
    } else { 
      $$out .= $debuggings; 
    }

  }

}



sub post_scriptum {
  my $self = shift;

  my $content = $self -> {response}{body} || '';

  my $vars_xml_dumped = $self -> {presenter_data_string} || '';

  my $vars_len = length( $vars_xml_dumped ) / 1000;
  my $page_len = length( $content ) / 1000;

  if ( $self ->{SHOW_PROFILING} ) {

    my $rep = $self -> report_timed_checkpoints || '';

    print 
      "\n<p>&nbsp;</p>",
      "\n<small>",
      "<p>timing:</p> <pre>" , $rep, "</pre>\n",
      "\n<p>length: $vars_len / $page_len</p>\n",
      "</small>\n";
  }

  if ( $self ->{LOG_PROFILING} ) {
    $self -> log_profiling( $self ->{request} {url}, 
                            $self ->{presenter} {file}, 
                            $vars_len, $page_len );
  }

  if ( $self ->config('debug-log') ) {
    my $logfn = $self ->config('debug-log');

    if ( open DLOG, '>>:utf8', $logfn ) { 
      print DLOG "\n* ", date_now(), " [$$]\n", $Web::App::Common::LOGCONTENTS;
      close DLOG;
      undef $Web::App::Common::LOGCONTENTS;
    }
  }


}



sub response_status {
  my $self = shift;
  my $status = shift;

  my $response = $self -> {response};
  my $headers  = $response -> {headers};

  push @$headers, "Status: $status";
}  
  

sub print_http_response_headers {
  my $self = shift;

  my $response = $self -> {response};
  
  if ( $response -> {headers_printed} ) {
    return;
  } else {
    $response -> {headers_printed} = 1;
  }

  my $headers  = $response -> {headers};

  if ( not $response-> {'allow-cache'} ) { 
    push @$headers, "Pragma: no-cache";
    push @$headers, "Cache-control: no-cache";
  }

  foreach ( @$headers ) {
    print $_, "\n";
#    debug "http header: $_";
  }

  if ( $self -> {http_headers} ) {
    my $http_add = $self ->{http_headers}; 
    print $http_add;
  }


  my $location = $response ->{'redirect-to'};

  if ( $location ) {
    debug "Location: $location";
    $Web::App::DEBUGIMMEDIATELY
                 ? print "Location: <a href='$location'>$location</a>\n\n" 
                 : print "Location: $location\n\n";

    undef $self -> {presenter};
    return;
  }


  if ( $self ->{'no-response'} ) {
    print "content-type: text/plain\n\nnothing to say\n";
    undef $self -> {presenter};
    return;
  }

  
  if ( not $self -> {response} {'content-type-printed'} ) {
    my $charset = $self -> {response} {charset};
    print "Content-Type: text/html; charset=$charset\n";
  }
  

  print "\n";

}




sub prepare_presenter_data {
  my $self    = shift;

  my $session = $self -> session;

  if ( defined $session ) {
    $session -> copy_sticky_params ( $self ->variables );
  }

  my $presenter_request = $self -> {'presenter-data'} {request};  
  my $request           = $self -> {request};

  ###  build presenter-request 
  for ( $presenter_request ) {
    $_ -> {agent}       = $request -> {agent};
    $_ -> {screen}      = $request -> {screen};
    $_ -> {form}{input} = $self -> form_input;
  }

  for ( qw( subscreen referer querystring session-id ) ) {
    if ( my $v = $request ->{$_} ) {
      $presenter_request ->{$_} = $v;
    }
  }

  ###  XX move request/session and request/user stuff here? 

}



sub parse_request_url {
  my $self = shift;
  my $url  = shift;

  my $base_url  = $self -> config( 'base-url' );


  my ( $the_request ) = ( $url =~ /^$base_url\/?(.*?)(?:\?|$)/ );
  
  if ( not defined $the_request ) {
    $the_request = '';
  }

#  warn "handling request: $the_request\n";
  debug "processing url, full: $url, relative: $the_request";
  
  my ( $screen_name, $session_id ) = split '!', $the_request;


  $self -> {request} {url}          = $the_request;
  $self -> {request} {screen}       = $screen_name;
  $self -> {request} {'session-id'} = $session_id ;

  return ( $screen_name, $session_id );
}




sub add_to_process_queue {
  my $self      = shift;
  my $screen_id = shift;

  debug "add '$screen_id' screen to processor queue";

  my $processors = [];

  my $cgi    = $self -> request -> {CGI};
  my $params = $self -> request -> {params};
  my $screen = $self -> get_screen( $screen_id );

  if ( not defined $screen ) { 
    return undef;
  }

  my $process;
  my $req_method = $self -> request ->{method} || '';

  if ( $screen -> {'process-on-POST'} ) {
    if ( $req_method eq 'POST'
         and scalar keys %$params ) {
      $process = 1;
    }

  } elsif ( scalar keys %$params ) {
    $process = 1;
  }

  if ( $process ) {
    $processors = $screen -> {'process-calls'};

  } else {
    $processors = $screen -> {'init-calls'};
  }

#  assert ref $processors eq 'ARRAY', 'expected an array of processors';


  push @{ $self -> {processors} }, @$processors;

  
  ###  load screen's modules

  my @modules = @{ $screen -> {'use-modules'} };
  foreach ( @modules ) {
    eval "use $_;";
    die "loaded module $_, got: $@" if $@;
  }

}


sub set_presenter {
  my $self = shift;
  my $screen = shift;

  if ( not $screen ) {
    $self -> {presenter} = undef;
    return;
  }

  assert( $self );
  assert( $self-> get_screen( $screen ) );
  
  $self ->{presenter} =
    $self -> get_screen( $screen ) -> {presentation};

}
 

sub clear_process_queue {
  my $self = shift;
  
  debug 'requested for clearing processor queue, processed';
  
  $self -> {processors} = [];
}


sub next_processor {
  my $self = shift;
  my $next = shift @{ $self -> {processors} };
#  debug "next processor: $next";
  return $next;
}


sub get_url_of_a_screen {
  my $self   = shift;
  my $screen = shift;
  my $base_url = $self -> {config} {'base-url'};

  my $url;
  if ( $self->session ) {
    my $session_id = $self -> session -> id;
    $url = "$base_url/$screen!$session_id";

  } else {
    $url = "$base_url/$screen";
  }

  return $url;
}


sub redirect_to_screen {
  my $self   = shift;
  my $screen = shift;

  my $base_url = $self -> {config} {'base-url'};
  my $response = $self -> {response};

  if ( $self->session ) {
    my $session_id = $self -> session -> id;
    $response -> {'redirect-to'} = "$base_url/$screen!$session_id";

  } else {
    $response -> {'redirect-to'} = "$base_url/$screen";

  }
}



sub redirect {
  my $self = shift;
  my $url  = shift;

  $self -> {response} {'redirect-to'} = $url;
}

sub print_content_type_header {
  my $self = shift;
  my $type = shift;

  if ( not $self -> {response} {'content-type-printed'} ) {
    print "Content-Type: $type\n\n";
    $self -> {response} {'content-type-printed'} = 1;
  }
}


sub set_cookie {
  my $self = shift;
#  my %par  = @_;
  
#  my $name   = $par{-name};
#  my $val    = $par{-value};
#  my $domain = $par{-domain};
#  my $path   = $par{-path};
#  my $maxage = $par{-maxage};

#  return undef if not $self -> {request} {CGI};

  require CGI::Cookie;

  my $cookie = CGI::Cookie -> new( @_ );

  my $response = $self -> {response};
  my $headers  = $response -> {headers};

  debug "Set-Cookie: $cookie";
  push @$headers, "Set-Cookie: $cookie";
}


sub get_cookie {
  my $self = shift;
  my $name = shift || die;

  require CGI::Cookie;
  if ( $self -> {request}{cookies} ) {

  } else {
    my $raw = $ENV{HTTP_COOKIE} || '';
    $self->{request}{cookies} = CGI::Cookie -> parse( $raw );
  }

  my $cookies  = $self -> {request}{cookies};

  return undef if not $cookies;
  return undef if not $cookies->{$name};
  return $cookies->{$name}->value;
}



### a helper function for some presenter types, e.g. XSLT

sub serialize_presenter_data { 
  my $self = shift;
  my $data = $self -> {'presenter-data'} || die;
  my $serializer = $self -> {serializer} || die;

  return undef if not $serializer;

  my $ret = &$serializer( $data ) || die;
 
  return $self -> {presenter_data_string} = $ret;
}



sub log {
  my $self  = shift;
  my $message = join '', @_;

  my $file = $self -> {paths} {log};
  my $date = localtime time;

  open ( LOG, '>>:utf8', $file )
    or die "Can't open logfile $file: $!\n";
  print LOG $date, " [$$] ", $message, "\n"; 
  close LOG;

  debug_as_is "$message";
}



sub errlog {
  my $self  = shift;
  my $message = join '', @_;

  my $file = $self -> {paths} {errlog};
  my $date = localtime time;

  open  LOG, '>>:utf8', $file
    or die "Can't open errlogfile $file: $!\n";
  print LOG $date, " [$$] ", $message, "\n"; 
  close LOG;

  debug_as_is "!!! $message";
#  warn $message . "\n";

  $self -> log( "[err] ", @_ );
}


sub userlog {
  my $self    = shift;
  my $message = join '', @_;

  my $user = $self->{username};
  assert( $user, "user name is not yet known to the Web::App object" );
  $self-> log( "[$user] ", $message );
}


sub event {}


sub sevent {
  my $self = shift;
  my %p    = @_;

  if ( $self -> {session} ) {
    if ( not $p{-chain} ) {
      my $id = $self ->{session} ->id;
      $p{-chain} = $id;
      if ( not defined $p{-startend} ) {
        $p{-startend} = 0;
      }
    }
  }
  return $self -> event ( %p );
}


sub time_checkpoint {};
sub report_timed_checkpoints {''};
sub log_profiling {};

 
1;

__END__

=head1 NAME

Web::App - Web Applications framework  /this documentation is far from complete/

=head1 SYNOPSIS

 use Web::App;
 my $app = new Web::App ( 'home' => '/home/user/web-app/' );

 $app -> handle_request();

=head1 DESCRIPTION

Web::App is a great web-application class.  Its greatness is in its
flexibility, simplicity and separation between application logic and
application interface.

Part of why Web::App is simple is because it is configurable.  Application
developer defines application screens.  For each screen he defines actions to
invoke (perl functions to call) and a "presenter" file to use.  Presenters are
templates to generate web pages.  Web::App uses XSLT for templates, but
support for other templating systems can be built into it with little effort.
The screens configuration is specified in an XML file, "screens.xml", which
Web::App reads from the application home directory.

This means you concentrate on the main application logic.  Also, Web::App
provides a framework for all the work you do; it provides services, which make
writing the application logic code easier.

At the same time, you can use Web::App as the base class and override some of
its methods in your own application.  That's flexibility.

=head2 METHODS

=head3 new( [PARAM, VALUE, ...] )

Creates a new Web::App object.

=head3 handle_request()

Process a user request and generate a response.  Response is printed out to
the standard output, just as usual CGI scripts do.

=head3 clear_after_request()

Optionally, you may call this method to clean up an object after processing a
request.  You have to do this if you want to process more than one request
with the same object.

....

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License, version 2, as
published by the Free Software Foundation.

=cut
