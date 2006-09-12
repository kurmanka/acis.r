use strict;

chdir $homedir;

use ACIS::Web;

my $acis = ACIS::Web -> new ( home => $homedir )
  or die "Can't create ACIS::Web object";

my $file = "$homedir/presentation/default/person/page.xsl";
my $data;

if ( open IN, "<:utf8", $file ) {
  $data = join '', <IN>;
  close IN;
}

$data =~ s/\[if-config\(([\w\-]+)\)\](-->)?(.+?)(<!--)?\[end-if\]/ 
  "[if-config($1)]" . ( $acis->config($1) ? "-->" : "" ) . $3 . ( $acis->config($1) ? "<!--" : "" ) . "[end-if]" ;
/exsg;

if ( open OUT, ">:utf8", $file ) {
  print OUT $data;
  close OUT;
}




