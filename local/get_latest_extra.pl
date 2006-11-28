#!/usr/bin/perl

use strict;


#older
#AMF-perl    /home/ivan/dev/AMF/AMF-perl

my $mods = {qw( 

AMF-perl    /home/ivan/proj/AMF-perl 
ReDIF-perl  /home/ivan/dev/ReDIF-perl
RePEc-Index /home/ivan/dev/RePEc-Index

)};

my $dest = 'extra/';
my $modfiles = {};

sub p { print @_, "\n"; }

foreach my $m ( keys %$mods ) {
  my $h = $mods->{$m};

  if ( not -d $h ) {
    p "$h is not a dir";
    die;
  }

  my $last_src;

  if ( opendir DIR, $h ) {
    my @f = readdir DIR;
    closedir DIR;
    my $ver;
    my %versions;
    
    foreach ( @f ) {
      if ( m/^$m\-(\d[\d\.]+)(\-[\w\d\.\-]+)?\.tar\.gz$/ ) {
        my $tv = $1;
        my $q  = $2 || '';
        $tv =~ s/\.(\d+)/ sprintf( ".%05d", $1 ) /ge;
        print "$m: $tv ($q)\n";
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
      $last_src = $versions{$ver};
      $modfiles->{$m} = "$h/$last_src";

    } else {
      die "didn't find $m in $h";
    }

  }
}

foreach my $m ( keys %$modfiles ) {
  my $f = $modfiles->{$m};
  p "Module: $m, \tfile: $f";
  system( "cp $f extra/" );
}

1;

