#!/usr/bin/perl

use strict;

use Carp::Assert;

my $files_hash = {};
my $missing = [];
my $unknown = [];
my $listed_count = 0;

sub pr { print @_, "\n"; }


###  read manifest

my $manifest = [ split /\n/, `cat MANIFEST` ];

grep { /(^\S+)/ and $files_hash->{$1} = 0 } @$manifest;

pr "Files in manifest: ", scalar keys %$files_hash;

### read doc/internal.text, extract all <F>file</F> elements

open FILES, "<doc/internal.text";
my $f = join '', <FILES>;
close FILES;

assert( $f );

$f =~ s!\<F\>(.+?)\<\/F\>! 
  $listed_count ++;
  if ( exists $files_hash->{$1} ) {
    $files_hash->{$1}++;
  } else {
    push @$unknown, $1;
  } !ge;

foreach ( keys %$files_hash ) {
  my $v = $files_hash->{$_};
  if ( not $v ) {
    push @$missing, $_;
  }
}

pr " listed: $listed_count";
pr " not documented: \n\t", join ( "\n\t", sort @$missing );
pr " listed unknown: \n\t", join ( "\n\t", sort @$unknown );


__END__ 

my @out;
sub p  { push @out, join( '', @_ ); };

p "<dl>";

foreach ( @$files ) {

  if ( not $_ ) {
    p "</dl>\n\n<dl>";
    next;
  }

  my $d = $files_hash ->{$_};

  p "\n<dt><F>$_</F></dt>";

  if ( not $d ) { p "<dd></dd>"; next; }
    
  if ( $d =~ m/^\|\s*$/ ) { next; }

  p "<dd>$d</dd>";
  
}

p "</dl>";


$output = join "\n", @out;

my $in = `cat internal.text.in`;

if ( $in ) {

  $in =~ s/\%\%FILELIST\%\%/$output/;
  
  if ( open OUT, ">internal.text" ) {
    print OUT $in;
    close OUT;
  }
 
}


