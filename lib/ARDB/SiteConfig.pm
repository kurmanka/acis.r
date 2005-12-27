package ARDB::SiteConfig;

use strict;
use Carp::Assert;

use ARDB::Common;

use vars qw(  @parameters $AUTOLOAD );

@parameters = qw( db_port db_host db_user db_pass db_name db_aliases daemon_socket );


sub AUTOLOAD {
  my $self = shift;
  my $routine = $AUTOLOAD;
  substr( $routine, 0, length( __PACKAGE__ ) + 2 )= ''; 
  return $self->{$routine};
}




sub parse_db_aliases {
  my $self = shift;
  my $list = $self -> {db_aliases};

  if ( not $list ) {
    return;
  }

  my %aliases;

  $list =~ s/(^\s+|\s+$)//g;
  my @alist = split( /\s+/, $list );
  
  foreach ( @alist ) {
    if ( /^(\w[\w\d]+)\=(\w[\w\d]+)$/ ) {
      $aliases{$1} = $2;
#      warn "alias: $1 = $2";
    }
  }

  $self -> {db_aliases} = \%aliases;
}


sub resolve_db_alias { 
  my $self = shift;
  my $alia = shift;

  if ( $self -> {db_aliases} ) {
#    warn "resolve: $alia";
    return $self ->{db_aliases} -> {$alia};

  } else {
    return undef;
  }
}


1;

=pod

=head1 name

ARDB::SiteConfig - module provides local configuration, such as database params

=head1 synopsis

use ARDB::SiteConfig;

my $site_config = new SiteConfig;

my $db_name = $site_config -> db_name;
# or
$db_name = $site_config -> {db_name};

=cut
