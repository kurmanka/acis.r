
#
# Export the personal name variations for Jose-Manuel Barruecco Cruz, for
# CitEc project.  2006-04-04 17:03

use Carp::Assert;
use warnings;

use sql_helper;
require ACIS::Web;
use Web::App::Common; 
use Encode;

my $output;
my $c = 0;
foreach ( @::ARGV ) {
  if ( defined $_ 
       and m/^--output$/ ) {
    $output = $::ARGV[$c+1];
    undef $_;
    undef $::ARGV[$c+1];
  }
  $c++;
}
clear_undefined( \@::ARGV );


if ( $output ) {
  open OUT, ">:utf8", $output;
} else {
  *OUT = STDOUT;
  binmode OUT, ":utf8";
  binmode STDOUT, ":utf8";
}



sub p (@) {
  print @_, "\n";
}

my $countnames = 0;
my $countrecs  = 0;
my $countbadnames = 0;

my $shortid;
my @list;

sub dump_list () {
  if ( $shortid and scalar @list ) {
    print OUT "$shortid:", join( ':', @list ), "\n";
    @list = ();
    undef $shortid;
    $countrecs++;
  }
}


my $acis = ACIS::Web -> new( homedir => $homedir );
assert( $acis );

my $sql = $acis -> sql_object;

$sql -> prepare( "select * from names order by shortid" );
my $res = $sql -> execute( );

while ( $res and $res->{row} ) {
  my $id   = $res ->{row}{shortid};
  my $name = $res ->{row}{name};

  $name = Encode::decode_utf8( $name );
  
  if ( $id and $shortid
       and $id ne $shortid ) {
    dump_list();
  }
  
  if ( $id and $name ) {
    $shortid = $id;

    if ( $name =~ m![\n\r:]! ) {
      p "bad name: $name\n";
      $countbadnames++;
      next;
    }

    push @list, $name;

    $countnames++;
  }
  warn if not $id;
  warn if not $name;
    
} continue {
  $res -> next;
}
  
dump_list();

print "total: $countrecs persons, $countnames names, $countbadnames bad names\n";

