
use Carp::Assert;

use sql_helper;
use ACIS::Web;

use Web::App::Common;


use warnings;

require ACIS::Web::ARPM::Queue;



#####  MAIN PART  

my $task = shift @ARGV;

if ( not $task ) {
  die "what do you want me to do? give a command.\n";
}

my $ACIS = ACIS::Web -> new( home => $homedir );

$task =~ tr/-/_/;

eval { 
  &{ "ACIS::Web::ARPM::Queue::task_$task" }( $ACIS );
};

if ( $@ ) {
  die "bad command: $@;"
}


