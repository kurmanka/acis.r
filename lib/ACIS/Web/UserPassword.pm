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
use Math::Random::Secure; 

use Digest;
use Digest::SHA2;

use Data::Dumper;
use Carp::Assert;

use Web::App::Common qw( debug );
use ACIS::Data::DumpXML qw(dump_xml);


sub generate_random_string {
  my $string;
  # ...
  return $string;
}

sub make_hash($$) {
  my $passw = shift;
  my $salt  = shift;
  my $hash;
  # ...
  return $hash; 
}

sub check_user_password {
  my $app = shift;
  my $password = shift;
  my $session = $app->session or die;
  my $result;
  # ...
  return $result;
}

sub generate_salt {
  my $app = shift;
  my $session = $app->session or die;
  my $ud_owner = $session ->userdata_owner or die;
  my $salt;
  # ...
  # $ud_owner->{password_salt} = $salt;
  return;
}

sub upgrade_clear_password {
  my $app = shift;
  my $session = $app->session or die;
  my $ud_owner = $session ->userdata_owner or die;
  # ...
  return 1;
}

sub set_new_password {
  my $app = shift;
  my $pass = shift;
  my $session = $app->session or die;
  my $ud_owner = $session ->userdata_owner or die;
  # ...
  return 1;
}

sub create_password_reset {
  my $app = shift;
  my $session = $app->session or die;
  my $ud_owner = $session ->userdata_owner or die;
  my $token;

  return $token;
}

sub check_reset_token {
  my $app = shift;

}

1;
