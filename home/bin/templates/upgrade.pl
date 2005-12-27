

my $name;
my $verno;
my $old;

if ( -f 'VERSION' ) {
  $old = `cat VERSION`;
}

if ( $old and     
     $old =~ 
     m!^([\w\-\,\.\s]+?)\s+(\d[\.\d\w]+)\s+(\d{4}-\d{2}-\d{2})\s\[(\w+)\]! ){
  $name  = $1;
  $verno = $2;

} else {
  warn "no old version";
  $verno = '0.0';
}

$verno = normalize( $verno );

my @call;

if ( opendir BIN, "bin/" ) {
  my @scripts = readdir BIN;
  foreach ( @scripts ) {
    if ( $_ =~ /^upgrade_to_(\d[\d\.]+)$/ ) {
      if ( normalize( $1 ) gt $verno ) {
        push @call, $_;
      }
    }
  }
}

foreach ( @call ) {

  print "Now will run: $_\n";
  system( "bin/$_" ) == 0
    or warn "failed to execute: $?";

  if ($? == -1) {
    print "failed to execute: $!\n";

  } elsif ($? & 127) {
    printf "child died with signal %d, %s coredump\n",
      ($? & 127),  ($? & 128) ? 'with' : 'without';
  }

}

exit 0;


sub normalize {
  my $v = shift;
  $v =~ s/\.(\d+)/ sprintf( ".%05d", $1 ) /ge;
  return $v;
}

