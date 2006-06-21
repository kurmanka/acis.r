package ACIS::Citations::Input;

use strict;
use warnings;

sub process_record {
  shift;

  my $id     = shift;
  my $type   = shift;
  my $record = shift;
  
  print __PACKAGE__, ": ", $id, "\n", $type, "\n", $record, "\n\n";
}

sub delete_record {

  shift;
  my $id = shift;

}


1;

