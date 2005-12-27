package ACIS::Web::CGI::Untaint::password;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use base qw(CGI::Untaint::printable);

sub is_valid {
  my $self = shift;
  
  my $len = length( $self->value );

  return ( ( $len > 5 )
           and ( $len < 100 ) );
}

1;

