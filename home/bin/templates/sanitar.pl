
# This script clears old / outdated records from the objects table
# (ARDB), using the RePEc::Index record's presence as a criteria.

# use --safe switch for check mode/simulation.

use Carp::Assert;

use sql_helper;

use warnings;

use RePEc::Index::Reader;

require ARDB;
require ARDB::Local;
use Web::App::Common; 

my $safe_mode = 0;
foreach ( @::ARGV ) {
  if ( m/^--safe$/ ) {
    $safe_mode = 1;
    undef $_;
  }
}
clear_undefined( \@::ARGV );


my $ardb = ARDB -> new();
assert( $ardb );

my $collections = [ keys %$RePEc::Index::COLLECTIONS ];

assert( scalar @$collections );


my $readers = {};
foreach ( @$collections ) {
  $readers -> {$_} = RePEc::Index::Reader -> new( $_ );
}

my $sql = $ardb -> sql_object;

$sql -> prepare( "select id from objects" );
my $res = $sql -> execute( );

my $count = 0;

while ( $res and $res->{row} ) {
  my $id = $res ->{row}{id};

  my $rec;
  foreach ( @$collections ) {
    my $reader = $readers -> {$_};
    eval {
      $rec = $reader -> get_record( $id );
    }; 
    warn $@ if $@;
    if ( $rec ) { last; }
  }

  if ( defined $rec ) {
#    print ".";
  } else {
    print "$id\n";
    if ( not $safe_mode ) {
      $ardb -> delete_record( $id );
    }
    $count ++;
#    if ( $count > 20 ) { die; }
  }
  $res -> next;
}


print "records found: $count\n";
