
use strict;
use Carp::Assert;
use warnings;
use sql_helper;

require ACIS::Web;
require ARDB;
require ARDB::Local;
use Web::App::Common;

my $tables = {
              # the default list for tables to backup
              acis => [ qw( sysprof suggestions cit_suggestions ) ],
              sid  => [ qw( sid_id_to_handle sid_last_numbers   ) ],
             };


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

if ( scalar @::ARGV == 1 ) {
  p "Usage: $0 [db table1 table2 ...]";
  exit;
}

if ( scalar @::ARGV ) {
  my $db = shift @::ARGV;
  my @list = @::ARGV;
  $tables = { $db => \@list };
}

my $acis = ACIS::Web -> new( homedir => $homedir ) || die;
my $ardb = ARDB -> new() || die;
my $sql  = $ardb -> sql_object;

my $directory = $acis->config( "db-backup-directory" ) || die; ### XXX default to $home/backup instead, but complain

if ( not -d $directory ) { die "backup directory $directory doesn't exist"; }

use File::Temp qw( tempdir );
my $tempdir = tempdir( CLEANUP => 1 );
require POSIX;
my $datepart  = POSIX::strftime( "%Y/%m/%d", localtime ) || die;
my $arcdir    = "$directory/$datepart";

#my $yearpart  = POSIX::strftime( "%Y", localtime ) || die;
#my $tempdir   = $acis->config( 'temp-directory' ) || "/tmp";
#my $tempsub   = POSIX::strftime( "%Y-%m-%d-acis-database-backup", localtime );
#force_dir( $tempdir, $tempsub ) or die;
#my $tempsubdir = $tempdir . "/" . 
system "chmod go+xw $tempdir";

p "temporary directory: $tempdir"
  if $verbose;

force_dir( $directory, $datepart ) or die "can't create date-named directory: $arcdir";
my $ardb_config =  $ardb -> {site_config};

foreach ( keys %$tables ) {
  my $dbalias = $_;
  my $dbname  = $ardb_config -> resolve_db_alias( $dbalias );
  my $tablelist = $tables->{$dbalias};
  
  if ( not $dbname ) {
    warn "database alias $dbalias is not known; skipping";
    next;
  }
  
  foreach ( @$tablelist ) {
    my $table = "$dbname.$_";
    p "table: $table"
      if $verbose;

    eval {
      $sql -> do( "LOCK TABLE $table READ" ) or die;
      $sql -> do( "FLUSH TABLE $table" )     or die;
      $sql -> do( "SELECT * FROM $table INTO OUTFILE '$tempdir/$table.backup'" ) or die;
      $sql -> do( "UNLOCK TABLES" ) or die;
    };
    if ( $@ ) {
      warn "$@";
      last;
    }
    system "mv $tempdir/$table.backup $arcdir/";
  }
}

p "saved backups to $arcdir" 
  if $verbose;
