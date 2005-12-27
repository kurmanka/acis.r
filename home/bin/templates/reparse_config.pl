
use strict;

chdir $homedir;

my $class = shift;

eval " use $class; ";
die "Error: something is not ready for $class ($@)"
  if $@;


my $object =  $class -> new ( home => $homedir, 
                              PARSE_CONFIG => 1 )
  or die "Class $class didn't produce an object";

###  The object shall parse its configuration and store it for future use
