package ACIS::Web::SysVars;

# an ACIS::Web extension for System Variables and Flags

use strict;
use warnings;
use Exporter;

use base qw( Exporter );
use vars qw( @EXPORT );

@EXPORT = qw( sysvar sysflag sysvarset sysflagsetto sysflagset sysflagdrop );

use Web::App::Common;

# get a system variable value from a file in HOME/state/
sub sysvar {
  my ($self, $name) = @_;
  my $d = $self->{home} . '/state/';
  debug "sysvar( $name )";
  $name =~ s!(?:\.\.|/|\||\>|\<)!!g;
  if ( not -r "$d$name" ) { return undef; }
  if ( open V, "<:utf8", "$d$name" ) {
    # extract first line of the file
    my $v = join( '', <V>);
    close V;
    return $v
  } else {
    return 0;
  }
}

# check if the flag file exists
sub sysflag {
  my ($self, $name) = @_;
  my $d = $self->{home} . '/state/';
  debug "sysflag( $name )";
  $name =~ s!(?:\.\.|/|\||\>|\<)!!g;
  if ( -f "$d$name" ) { return 1; }
  return undef;
}

sub sysvarset {
  my ($self, $name, $value) = @_;
  $name =~ s!(?:\.\.|/|\||\>|\<)!!g;  
  my $d = $self->{home} . '/state/';
  if ( not defined $value ) {
    unlink "$d$name";
    return 1;
  }
  if ( open V, ">:utf8", "$d$name" ) {
    # put $value into the file
    print V $value;
    close V;
    return 1;
  } else {
    return undef;
  }
}

sub sysflagsetto {
  my ($self, $name, $value) = @_;
  $name =~ s!(?:\.\.|/|\||\>|\<)!!g;  
  my $d = $self->{home} . '/state/';
  if ( not $value ) {
    if ( -f "$d$name" ) { unlink "$d$name"; }
    return 1;
  } 
  if ( open V, ">:utf8", "$d$name" ) {
    close V;
    return 1;
  } else {
    return undef;
  }
}


sub sysflagset  { $_[0]->sysflagsetto($_[1],1) }
sub sysflagdrop { $_[0]->sysflagsetto($_[1],0) }




1;

