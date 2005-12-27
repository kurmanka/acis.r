package ACIS::Web::CGI::Untaint::latinname;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use base qw( CGI::Untaint::printable );

sub _untaint_re { 
  qr/^\s*([a-z][a-z\d\-\.\'\,\s]*)\s*$/i;
}

sub is_valid {
  my $self = shift;
  return (length ($self -> value) < 200);
}


1;
