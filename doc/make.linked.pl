#!/usr/bin/perl

use strict;
use Carp::Assert;

my $md = `which markdown` || `which Markdown.pl`;
chomp $md;
if ( not $md ) { die "markdown executable not found"; }

#my $sp = './SmartyPants.pl';
my $sp = `which SmartyPants.pl`;
chomp $sp;


my $xp = `which xsltproc`;
if ( not $xp ) { die "xsltproc not found"; }
chomp $xp;

my $style;

if ( -e 'doc/style.css' ) {
  $style = `cat doc/style.css`;
}

sub p { print @_, "\n"; }

#my $index_xs = "index.xsl";


chdir "doc";

#require "make.filelist.pl";


opendir SRC, ".";
my @src = readdir SRC;
closedir SRC;

@src = grep { /\.text$/ } @src;



if ( not -e "tmp" ) {
  mkdir "tmp";
}

open IND, ">tmp/index.xml";
sub pi { print IND @_, "\n"; }

pi "<doc>";

foreach ( @src ) {
  my $name;
  my $dest = $_;
  $dest =~ s/text$/html/;

  m!([^/]+)\.(.+)$!;

  $name = $1;

#  print "Run: $md $_\n";
  my $text = `$md $_`;
  assert( $text );

  $text =~ s!<p>(</?ignore\s*>)</p>\n*!$1!gm;

  pi "  <text src='$_' name='$name' file='$dest'>";
  pi $text;
  pi "  </text>";
}

pi "</doc>";

close IND;


if ( $sp ) {
  my $typ = `$sp tmp/index.xml`;
  open IND, ">tmp/index.xml";
  pi $typ;
  close IND;
}


###  process index.xml with index.xsl

my $date = scalar localtime;

system ( "$xp xslt/010.xsl tmp/index.xml > tmp/index-2.xml" );
system ( "$xp xslt/020.xsl tmp/index-2.xml > tmp/index-3.xml" );
system ( "$xp --param date '\"$date\"' xslt/030.xsl tmp/index-2.xml > tmp/index-4.xml" );



__END__

#  p "$_ => $dest";
  
  my $file = 
  

  my $index = `$xp $index_xs $


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
