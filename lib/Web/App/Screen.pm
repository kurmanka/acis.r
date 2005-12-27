package Web::App::Screen;

use strict;

use Carp::Assert;

use Data::Dumper;


sub new {
  my $class = shift;
  my $id    = shift;
  
  my $self  =    {
    'id'            => $id,
    'init-calls'    => [],
    'process-calls' => [],
    'use-modules'   => [],
    'subscreens'    => [],
#    'presentation'  => ,
  };
  
  bless $self, $class;
   
  return $self;
}


sub add_call {
  my $self = shift;
  my @functions = @_;

  push @{$self -> {'init-calls'}}, @functions;
  push @{$self -> {'process-calls'}}, @functions;
}

sub add_init_call {
  my $self = shift;
  my @functions = @_;
  
  push @{$self -> {'init-calls'}}, @functions;
}

sub add_process_call {
  my $self = shift;
  my @functions = @_;

  push @{ $self -> {'process-calls'} }, @functions;
}


sub add_use_module {
  my $self = shift;
  my @mod  = @_;
  push @{ $self -> {'use-modules'} }, @mod;
}


sub presentation_type {
  my $self = shift;
  my $received_type = shift;

  if ( not defined $received_type ) { 
    return $self -> {presentation} {type};

  } else {
    assert( $received_type );
    $self -> {presentation} {type} = $received_type;
  }
}
 

sub presentation_file {
  my $self = shift;
  my $received_filename = shift;
  
  if ( not defined $received_filename ) {
    return $self -> {presentation} {file};

  } else {
    assert( $received_filename );
    $self -> {presentation} {file} = $received_filename;
  }

} 
 
1;
