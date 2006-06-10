package ACIS::Web::CGI::Untaint::simpleemail;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use base qw( CGI::Untaint::printable );

sub _untaint_re { 
  qr/^\s*([\&\+a-z\d\-\.\=\_\']+\@(?:[a-z\d\-\_]+\.)+[a-z]{2,})\s*$/i;
}


sub is_valid {
  my $self = shift;
  return (length ($self -> value) < 300);
}


1;

