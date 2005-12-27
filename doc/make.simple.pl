#!/usr/bin/perl

use strict;
my $md = `which Markdown.pl`;

if ( not $md ) { die "Markdown.pl not found"; }

chomp $md;

my $xp = `which xsltproc`;
if ( not $xp ) { die "xsltproc not found"; }
chomp $xp;


my $style;

if ( -e 'doc/style.css' ) {
  $style = `cat doc/style.css`;
}

sub p { print @_, "\n"; }

foreach ( @ARGV ) {
  my $dest = $_;
  $dest =~ s/text$/html/;

  p "$_ => $dest";
  my $text = `$md $_`;

  if ( open DE, ">$dest" ) {
    print DE preamble( $text );
    print DE $text;
    print DE "\n  </body>\n</html>\n";
    close DE;
  }
}
  

sub preamble {
  my $cnt = shift;
  
  my $title = ( $cnt =~ m!^<h1[^>]*>([^<]+)</h1>!, $1 );
  
  my $text = qq!<html>
  <head>
    <title>$title</title>
    <style type='text/css'>
$style
    </style>
  </head>
  <body>

!;

  return $text;
}
