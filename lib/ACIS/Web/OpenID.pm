package ACIS::Web::OpenID;

=pod

OpenID server, at /openid, based on the Net::OpenID::Server module

=cut

use strict;
use warnings;

use Data::Dumper;
#use Carp::Assert;

use Web::App::Common qw( debug );
use ACIS::Web;

use Net::OpenID::Server;


my $app;

# this powers the /openid/yadis screen
sub yadis {
    $app = shift;
    debug "->yadis()";
    my $sid = $app->form_input->{id};
    if ($sid) {
      $app->variables->{sid} = $sid;
      debug "->yadis(): id = $sid";
    }
}


# from https://www.grc.com/passwords.htm 
# XXX this needs to be replaced with a more 
# complicated and more secure version.
sub server_secret { "q3w6ugHDzu2lXmPs6LWjIbm9X4luzoeBSjnTIvdWbCGAETbvfFylqMCppSzdnI6" }


# important variables, set in sub is_identity(), checked in sub endpoint()
my $claimed_id;
my $is_identity;


sub openid_server {
    shift; # $app is already here
    my $args = shift || $app->form_input;
    my $base_url = $app->config( 'base-url' );

    my $nos = Net::OpenID::Server->new(
      args          => $args,
      get_user      => \&get_user,
      get_identity  => \&get_identity,
      is_identity   => \&is_identity,
      is_trusted    => \&is_trusted,
      endpoint_url  => "$base_url/openid",
      setup_url     => "$base_url/openid/setup",
      server_secret => \&server_secret,
    );

    return $nos;
}


# this function is to receive and process the OpenID requests
sub endpoint {
    $app = shift;
    my $retry = shift;
    debug "OpenID endpoint accessed";

    my $args     = $app->form_input;
    my $base_url = $app->config( 'base-url' );

    if (exists $args->{pass} and $args->{login}) {
        # process login form
        my $auth = $app->authenticate;
        if ($auth) { $app->clear_redirect; }
    } else {
        $app->load_session_if_possible;
    }
    my $session = $app->session;

    if ($retry and $session and $session->{openid_args}) { 
        $args = $session->{openid_args}; 
    }

    # let Net::OpenID::Server do it's work, and call the necessary callbacks
    my $nos = openid_server( $app, $args );
    my ($type, $data) = $nos->handle_page;

    my $string = Data::Dumper->Dump( [$data], ['data'] );
    debug "OpenID NOS: type - $type";
    debug "OpenID NOS: data - $string";
    
    if ($type eq "redirect") {
        $app->redirect( $data );

    } elsif ($type eq "setup") {
        debug "setup request";

        # setup data is in $data
#        my $url_success = $nos ->signed_return_url( %$data );
#        my $url_cancel  = $nos ->cancel_return_url( return_to => $data->{return_to} );
#        debug "openid goto: $url_success";
#        debug "openid cancel: $url_cancel";
#        if ($session) {
#            $session ->{openid_goto}   = $url_success;
#            $session ->{openid_cancel} = $url_cancel;
#        }

        if ( $session
             and $session->current_record ) {

            debug "session and record are present";

            if ($is_identity) {
                # good, can go on
                debug "prepare for the setup screen";
                $session ->{openid_args}   = $args;
                
                # prepare for the setup screen
                $app->variables->{openid} = $data;
                $app->variables->{openid_trust_root} = $data->{trust_root};
                $app->set_presenter( "openid/setup" );

            } else {
                # not good, need to stop this
                debug "The user is trying to authenticate as $claimed_id, but it is not theirs";
                #die "You are trying to authenticate as $claimed_id, but it is not yours.\n";
                $app->variables->{openid_trust_root} = $data->{trust_root};
                $app->variables->{openid_claimed_id} = $claimed_id;
                $app->variables->{'profile-url'}     = $session->current_record->{profile}{url};
                $app->set_presenter( "openid/notyours" );
            }

        } else {
            # show login form
            debug "show the login form";
            $app->set_presenter( "login" );
        }
        
    } else {
        debug "output the N:O:S' response of type $type";
        $app->print_content_type_header( $type );
        $app->response->{body} = $data;
    }
    
}



# this is for /openid/setup, and /openid/setup is mentioned as the
# setup URL in N::O::S config above, but i have not seen N::O::S
# redirecting to it.
sub setup {
    $app = shift;

    debug "setup screen";

    $app->load_session_if_possible;
    my $session = $app->session;
    my $input = $app->form_input;

    return if not $session;

    if ( $input->{allow_trust} and $input->{trust_root} ) {
        # process setup screen: [ CONTINUE LOGIN ]
        debug "process CONTINUE button";
        my $trust_root = $input->{trust_root};

        $session->userdata_owner->{openid_trust}->{$trust_root} = 1;


    } elsif ( $input->{cancel} ) {
        # process setup screen: [ CANCEL ]
        # XXX what should I do?
        debug "process CANCEL button";

    } 


    # now let's try again
    if ( $session->{openid_args} ) {
        return endpoint( $app, 1 );        
    }

    return;
}



# doc quote
# from http://search.cpan.org/~mart/Net-OpenID-Server-1.02/lib/Net/OpenID/Server.pm
# :
#   the subref returning a defined value representing the logged in
#   user, or undef if no user. The return value (let's call it $u) is
#   not touched. It's simply given back to your other callbacks
#   (is_identity and is_trusted).

sub get_user {
    $app->load_session_if_possible;
    if ($app->session) {
        return $app->session->userdata_owner;
    }
}


# get_identity($u, $identity_url)
#
# from http://search.cpan.org/~mart/Net-OpenID-Server-1.02/lib/Net/OpenID/Server.pm
# :
#   the subref which is responsible for returning true if the logged
#   in user $u (which may be undef if user isn't logged in) owns the
#   URL tree given by $identity_url. Note that if $u is undef, your
#   function should always return 0. The framework doesn't do that for
#   you so you can do unnecessary work on purpose if you care about
#   exposing information via timing attacks.
sub get_identity {
    my $u   = shift || '';
    my $url = shift;
    
    debug "->get_identity(): user: $u, url: $url";
    

    if (not $u) { return 0; }
    
    my $session = $app->session;
    if ($session) {
        my $owner = $session->userdata_owner;
        my $rec   = $session->userdata->{records}[0];
        my $ret = 0;

        if (not $owner or not $rec or not $rec->{'about-owner'}) {
            return 0;
        } 
        
        if ($url eq 'http://specs.openid.net/auth/2.0/identifier_select') {
            $ret = $rec->{profile}{url};
        }
        
        if ($rec->{profile}{url} eq $url) {
            $ret = $url;
        }
        
        debug "->get_identity: $ret";
        return $ret;
    }
}

sub is_trusted  {
    my $u = shift || '';
    my $trust_root = shift;
    my $is_identity = shift;
    
    debug "->is_trusted( $u, $trust_root, $is_identity )";
    
    if ($u and $is_identity) {
        my $s = $app->session;
        my $owner = $s->userdata_owner;
        return exists $owner->{openid_trust}->{$trust_root};
        #return 1;
    } else {
        debug "no trust";
        return 0;
    }
    
}

sub is_identity {
    my $u = shift || '';
    my $url = shift;
    
    debug "->is_identity( $u, $url )";
    
    if (not $u) { 
        return $is_identity = 0;
    }
    
    $claimed_id = $url; # variable defined above, checked in endpoint()
    my $session = $app->session;
    if ($session) {
        my $owner = $session->userdata_owner;
        my $rec   = $session->current_record || $session->userdata->{records}[0];
        
        my $ret = 0;
        if (not $owner or not $rec or not $rec->{'about-owner'}) {
            return $is_identity = 0;
        } 
        
        debug "profile URL: " . $rec->{profile}{url};
        if ($rec->{profile}{url} eq $url) {
            $is_identity = 1;
        }
        
        debug "->is_identity: $is_identity";
        return $is_identity;
    }
    
}


1;
