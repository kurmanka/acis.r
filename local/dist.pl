#!/usr/bin/perl

#   This is the release packaging script for ACIS.  It increments version
#   numbers and saves it (along with the current date) into the VERSION file
#   of ACIS.  It updates extra/ directory with recent versions of the extra
#   modules, if neccessary.  
#
#   Use: 
#
#      perl dist.pl [VERSION_NUMBER]
# 
#   If you do specify the VERSION_NUMBER, it makes a full release, ie. with
#   the extra modules.  If you do not, it makes just an update release.
# 

use strict;

my $newversion = shift @ARGV;

my $fullrelease = 0;
if ( $newversion ) {
  $fullrelease = 1;
}

my $fullver = `cat VERSION`;
chomp $fullver;

my $name;
my $prev_verno;
my $prev_date;
my $prev_issue;

if ( $fullver =~ 
     m!^([\w\-\,\.\s]+?)\s+(\d[\.\d\w]+)\s+(\d{4}-\d{2}-\d{2})\s\[(\w+)\]! ){
  $name        = $1;
  $prev_verno  = $2;
  $prev_date   = $3;
  $prev_issue  = $4;

} else {
  die "can't parse VERSION";
}

my $issue;
my $date;
my $verno;


my $today = `date +\%F`;
chomp $today;

my $todayfull = `date`;
chomp $todayfull;

my $today8dig = $today; 
$today8dig =~ s!-!!g;

$date = $today;


#   find version number
if ( $newversion ) {
  $verno = $newversion;

} else {

  my @ver = split /\./, $prev_verno;
  my $pos = 2;  
  $ver[$pos] ++;
  $verno = join( '.', @ver );
}


#   make issue index
if ( $today eq $prev_date ) {
  if ($issue eq 'z') {  $issue = '@';  }
  $issue = chr( ord( $prev_issue )+1 );

} else { 
  $issue = 'a';
}

print $name, " ", $verno, ' ', $date, " [$issue]", "\n", 
  $todayfull, "\n", 
  "file: $today8dig$issue", "\n";


if ( open VER, '>', 'VERSION' ) {
  print VER "$name $verno ${date} [$issue]\n",
"$todayfull\n";
  close VER;
}



system 'rm -rf extra/*';
if ( $fullrelease ) {
  require 'local/get_latest_extra.pl';
}

my $version;

$version = "$verno-$today8dig$issue";

system "perl Makefile.PL";
system "make dist VERSION=$version";
system "cvs commit -m 'release $version' VERSION";
print "$name-$version.tar.gz\n";
