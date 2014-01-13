package ACIS::Web::UserPassword; ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Tools to generate password hashes, password salt, etc.
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

use strict;
use warnings;

# http://search.cpan.org/~mkanat/Math-Random-Secure-0.06/lib/Math/Random/Secure.pm
#use Math::Random::Secure; 
# http://search.cpan.org/~davido/Bytes-Random-Secure-0.28/lib/Bytes/Random/Secure.pm
use Bytes::Random::Secure qw(random_bytes); 
use MIME::Base64;
use Encode;

use Digest;
use Digest::SHA qw( sha256_base64 );

use Data::Dumper;
use Carp::Assert;

use Web::App::Common qw( debug );
use ACIS::Data::DumpXML qw(dump_xml);


sub generate_random_bytes {
  return random_bytes( 32 );
}

sub generate_random_bytes_base64 {
  my $bytes = generate_random_bytes();
  my $string = encode_base64( $bytes );
  # remove trailing whitespace
  chomp $string;
  return ($bytes, $string);
}

sub generate_salt {
  my $app = shift;
  my $session = $app->session or die;
  my $ud_owner = $session ->userdata_owner or die;
  my ($salt, $salt_b64) = generate_random_bytes_base64();

  # we store the base64 encoding of the salt
  $ud_owner->{password_salt_base64} = $salt_b64;
  return $salt;
}


sub make_hash($$) {
  my $password = shift;
  my $salt     = shift;
  my $hash_string;

  # prepend the salt
  my $data = $salt . encode_utf8( $password );
  # take sha256, in the base64 encoding
  # should be 44 characters long, if the data is 32 bytes long
  $hash_string = sha256_base64( $data );
  # ...
  return $hash_string; 
}

sub check_user_password {
  my $password = shift || die;
  my $ud_owner = shift || die;

  if (not exists $ud_owner->{password_hash_base64} 
      or not exists $ud_owner->{password_salt_base64}) {
        debug "fallback to the clear-text password";
        # XXX fallback to the clear-text password
        return ($password eq $ud_owner->{password});
  }

  my $salt_b64 = $ud_owner->{password_salt_base64} or die;
  my $salt     = decode_base64( $salt_b64 ) or die;

  my $given_hash    = make_hash( $password, $salt ) or die;
  my $existing_hash = $ud_owner->{password_hash_base64} or die;
  # compare
  my $result = ($given_hash eq $existing_hash);
  debug "result: $result";
  # false or true
  return $result;
}

sub ACIS::Web::check_user_password {
    my $self = shift;
    return check_user_password( @_ );
}


sub ACIS::Web::upgrade_clear_password {
  my $app = shift;
  my $session = $app->session or die;
  my $ud_owner = $session ->userdata_owner or die;

  if (exists $ud_owner->{password}) {
    debug "clear text password exsits";
    my $salt = generate_salt( $app ) or die;
    my $pass = delete $ud_owner->{password};

    my $hash = make_hash( $pass, $salt ) or die;
    $ud_owner->{password_hash_base64} = $hash;
    debug "password hash (b64): $hash";
    
    return 1;
  }

  return 0;
}

sub ACIS::Web::set_new_password {
  my $app  = shift or die;
  my $pass = shift or die;
  my $session = $app->session or die;
  my $ud_owner = $session ->userdata_owner or die;

  my $salt = generate_salt( $app ) or die;
  
  my $hash = make_hash( $pass, $salt ) or die;
  $ud_owner->{password_hash_base64} = $hash;
  debug "password hash (b64): $hash";

  if (exists $ud_owner->{password}) {
    delete $ud_owner->{password};
  }

  return 1;
}

# cookie name: rememberme
# cookie expiry time: 3 months
my $EXPIRY_MONTHS = 3;

sub ACIS::Web::create_persistent_login {
  my $app = shift or die;
  my $login = shift or die;
 
  my ($token, $token_b64) = generate_random_bytes_base64();

  my $sql = $app->sql;
  my $q = $sql->prepare( 'insert into persistent_login (login,token,created) values (?,?,NOW())' );
  my $r = $sql->execute( $login, $token );
  if ($r) {
    # good result
    $app -> set_cookie( -name  => 'rememberme',
                        -value => $token_b64,
                        -expires => "+${EXPIRY_MONTHS}M"
    );
    return 1;

  } else {
    debug "create_persistent_login: insert failed: " . $sql->error;
    return 0;
  }
}


sub ACIS::Web::check_persistent_login {
  my $app = shift or die;
  my $token_b64 = $app->get_cookie('rememberme');

  if (not $token_b64 or ($token_b64 eq 'notnow')) { 
    # also check the cookies to be set
    $token_b64 = $app->response->{cookies}->{rememberme} || '';
    debug "token_b64: $token_b64";
  }
  if (not $token_b64) { return undef; }

  my $login;

  my $sql = $app->sql;

  # - check the token.
  if ($token_b64 eq 'notnow') { return undef; }
  # - decode the token.
  my $token = decode_base64( $token_b64 ) or return undef;
  my $row;

  # - get the token table row.
  # - check the expiry time.
  my $q = $sql->prepare_cached( "select * from persistent_login where token=? and timestampadd(MONTH,?,created) > NOW()" );
  my $r = $sql->execute( $token, $EXPIRY_MONTHS );
  if ($r and $r->{row}) { 
    $row = $r->{row}; 
    # - get the login.
    $login = $row->{login};
  }

  # - return the login.
  # - if the token is not there, or it has already expired, return undef.

  return $login;
}


sub ACIS::Web::renew_persistent_login {
  my $app = shift or die;
  my $token_b64 = $app->get_cookie('rememberme');

  if (not $token_b64 or ($token_b64 eq 'notnow')) { 
    # also check the cookies to be set
    $token_b64 = $app->response->{cookies}->{rememberme} || '';
    debug "token_b64: $token_b64";
  }
  if (not $token_b64) { return undef; }

  # - decode the token.
  my $token = decode_base64( $token_b64 ) or return undef;

  my $sql = $app->sql;
  $sql->prepare( "update persistent_login set created=NOW() where token=?" );
  my $r = $sql->execute($token);
  
  if ($r) {
    # reset the cookie
    $app -> set_cookie( -name  => 'rememberme',
                        -value => $token_b64,
                        -expires => "+${EXPIRY_MONTHS}M" );
    return 1;

  } else {
    debug "renew_persistent_login: update failed: " . $sql->error;
  }
  return;
}


sub ACIS::Web::remove_persistent_login {
  my $app = shift or die;
  debug "remove_persistent_login(): start";
  debug "remove_persistent_login(): cookie rememberme: " . $app->get_cookie('rememberme');
  my $token_b64 = $app->get_cookie('rememberme') or return undef;

  # - decode the token.
  my $token = decode_base64( $token_b64 ) or return undef;

  my $sql = $app->sql;
  $sql->prepare( "delete from persistent_login where token=?" );
  my $r = $sql->execute($token);
  
  if ($r) {
    # clear the cookie
    $app -> set_cookie( -name  => 'rememberme',
                        -value => '',
                        -expires => "+${EXPIRY_MONTHS}M" );
    $app -> variables -> {persistent_login_cookie_removed} = 1;
  } else {
    debug "remove_persistent_login(): failed: " . $sql->error;
  }

  return;    
}



# password reset token;
# expiry time: 12 hours
my $RESET_EXPIRY_HOURS = 12;


sub create_password_reset {
  my $app = shift;
  my $login = shift;
  my ($token, $token_b64) = generate_random_bytes_base64();

  my $sql = $app->sql;
  my $q = $sql->prepare( 'insert into reset_token (login,token,created,used) values (?,?,NOW(),NULL)' );
  my $r = $sql->execute( $login, $token );
  if ($r) {
    return $token_b64;

  } else {
    return undef;
  }
}

sub check_password_reset_token {
  my $app          = shift or die;
  my $token_b64    = shift or die;
  my $mark_as_used = shift;
  my $login;
  my $sql = $app->sql;

  # - check the token.
  # - decode the token.
  my $token = decode_base64( $token_b64 ) or return undef;

  # - get the token table row.
  # - check the expiry time.
  $sql->prepare_cached( "select * from reset_token where token=? and timestampadd(HOUR,?,created) > NOW()" );
  my $r = $sql->execute( $token, $RESET_EXPIRY_HOURS );
  if ($r and $r->{row}) { 
    my $row = $r->{row}; 
    # - get the login.
    $login = $row->{login};
    
    # - check if the token was already used in the past
    if ($row->{used}) {
      return -2;
    }
    
    # - set the used time for the token
    if ($mark_as_used) {
      $sql->prepare( "update reset_token set used=NOW() where token=?" );
      $sql->execute($token);
    }
    # - return the login
    return $login;
  }
  
  # else (not found)
  # - check if there's an expired token with this value
  $sql->prepare_cached( "select * from reset_token where token=?" );
  $r = $sql->execute( $token );
  if ($r->{row} and $r->{row}{login}) {
    return -1;
  }
  # not found at all
  return undef;
}

1;
