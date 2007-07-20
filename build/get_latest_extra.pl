#!/usr/bin/perl
use strict;

# this script looks up additional components for ACIS in their own
# directories, chooses the latest packaged version and makes a copy in
# the extra/ directory.  Then it is ready to be repackaged in a new
# complete ACIS release.



my $mods = {qw( 
AMF-perl    ../AMF-perl;/home/ivan/proj/AMF-perl 
ReDIF-perl  ../ReDIF-perl;/home/ivan/dev/ReDIF-perl
RePEc-Index ../RePEc-Index;/home/ivan/dev/RePEc-Index
)};

#AMF-perl    /home/ivan/dev/AMF/AMF-perl # older

my $dest = 'extra/';
my $modfiles = {};

sub p { print @_, "\n"; }

foreach my $m ( keys %$mods ) {
  my $file;
  my $h = $mods->{$m};
  my @dirs = split( ';', $h );
  
  foreach my $dir (@dirs) {
    if ( not -d $dir ) {
      p "$dir is not a dir";
      next;
    }
    my $fname = get_latest_version_file( $m, $dir );
    if ($fname) {$file = "$dir/$fname"; last;}
  }
 
  $modfiles->{$m} = $file 
    or die "can't find the latest release of $m";
}

foreach my $m ( keys %$modfiles ) {
  my $f = $modfiles->{$m};
  p "Module: $m, \tfile: $f";
  system( "cp $f $dest" );
}


# find latest tar-gzipped versioned package in the given directory

sub get_latest_version_file($$) {
  my ($module, $dir) = @_;
  if ( opendir DIR, $dir ) {
    my @f = readdir DIR;
    closedir DIR;
    
    my $ver; # that version would be the latest
    my %versions;
    
    foreach ( @f ) {
      if ( m/^$module\-(\d[\d\.]+)(\-[\w\d\.\-]+)?\.tar\.gz$/ ) {
        my $tv = $1;
        my $q  = $2 || '';
        $tv =~ s/\.(\d+)/ sprintf( ".%05d", $1 ) /ge;
#        print "$module: $tv ($q)\n";
        $versions{$tv} = $_;
        if ( $ver 
             and $tv gt $ver ) {
          $ver = $tv;
        } 
        if ( not $ver ) { $ver = $tv; }
      } else {
#        print "$m: $_ ?\n";
      }
    }  
    if ( $ver and
         $versions{$ver} ) {
      return $versions{$ver};
    }
  }
  return undef;
}
  
  

1;

