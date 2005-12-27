package ARDB::Record::Simple;

# This module implements the interface to metadata objects that ARDB works
# with (ARDB::Record) on top of a very simple data structure -- a one-level
# hash.

require ARDB::Record;

use base qw( ARDB::Record );

use strict;

sub id {
  my $self = shift;
  return $self -> {id};
}

sub type {
  my $self = shift;
  return $self -> {type};
}

sub get_value {
  my $self = shift;
  my $what = shift;
  if ( $self -> {$what} ) { 
    return $self -> {$what};
  }
  return undef;
}


sub add_relationship {
  my $self = shift;
  my $rel  = shift;
  my $val  = shift; ### ?
}

sub view {
  my $self = shift;

}

sub set_view {
  my $self = shift;
}



1;
