
use ACIS::ShortIDs;
use strict;

my $command = shift;

if ( $command eq 'clear' ) {
  my $ok = ACIS::ShortIDs::clear_database();
  if ( not $ok ) {
    print "failed\n";
  }

} elsif ( $command eq 'create-tables' ) {
  my $ok = ACIS::ShortIDs::create_tables();
  if ( $ok ) {
    print "created Short-ID tables\n";
  }

} elsif ( $command eq 'import' ) {
  my $file = shift;
  
  if ( -e $file ) {
    my $ids = ACIS::ShortIDs::read_logfile( $file );
    print "$ids imported\n";
  }

} elsif ( $command eq 'import-dup' ) {
  my $file = shift;
  
  if ( -e $file ) {
    my $ids = ACIS::ShortIDs::read_logfile( $file, undef, 1 );
    print "$ids imported\n";
  }

} elsif ( $command eq 'check-log' ) {
  my $file = shift;
  
  if ( -e $file ) {
    my $ids = ACIS::ShortIDs::check_logfile( $file );
    if ( $ids ) {
      print "$ids are problematic\n";
    } else {
      print "can't open file\n";
    }
  }

} elsif ( $command eq 'backup' ) {

  umask 0000;
  my $ok = ACIS::ShortIDs::database_backup( );
  if ( not $ok ) {
    print "failed\n";
  }
}

