package ARDB::Plugin::Processing;

use strict;

sub new {
  my $class = shift;

  my $home = shift;

#  my $plugins_path = $class;
#  $plugins_path =~ s/\w+::/::/;
#  $plugins_path = $ARDB::LocalConfig::local_path . $plugins_path;
#  $plugins_path =~ s/::(\w+)/\/$1/g;
#  $plugins_path =~ s|\/\/|\/|s;

  my $self = {
              home   => $home,
              ok     => 'ok'
  };

  bless $self, $class;

}


sub status {
  return 1;
}

sub init {
  return 1;
}


sub get_record_types {
  return [];
}

sub process_record {
}


sub require {
  return [];
}


sub config {
  return undef;
}
 

1;
 
