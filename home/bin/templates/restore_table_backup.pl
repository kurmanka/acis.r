
use strict;
use Carp::Assert;
use warnings;
use sql_helper;

require ACIS::Web;
require ARDB;
require ARDB::Local;
use Web::App::Common;

my $pretend = 0;
my $verbose = 0;
foreach ( @::ARGV ) {
  if ( m/^--pretend$/ ) {
    $pretend = 1;
    warn "pretend mode not implemented";
    undef $_;
  }
  if ( m/^--verbose$/ ) {
    $verbose = 1;
    undef $_;
  }
}
clear_undefined( \@::ARGV );

sub p (@) {
  print @_, "\n";
}

if ( scalar @::ARGV == 0 ) {
  p "Usage: $0 backupfile1 ...";
  exit;
}

my @list = @::ARGV;
my $acis = ACIS::Web -> new( homedir => $homedir ) || die;
my $ardb = ARDB -> new() || die;
my $sql  = $ardb -> sql_object;

use File::Temp qw( tempdir );
my $tempdir = tempdir( CLEANUP => 1 );
system "chmod go+rx $tempdir";

foreach ( @list ) {
  my $fullname = $_;
  my ($fname) = ( $fullname =~ m!^(?:.*\/)?([^/]+)$! );
  my ($dbname, $table) = split '\.', $fname;

  system "cp $fullname $tempdir/";
  
  if ( not $dbname or not $table ) {
    die "can't find out database name or table name";
    next;
  }
  
  p "file $fullname, db: $dbname, table: $table"
    if $verbose;

  $sql -> do( "LOAD DATA INFILE '$tempdir/$fname' INTO TABLE $dbname.$table" ) or warn $@;
}

