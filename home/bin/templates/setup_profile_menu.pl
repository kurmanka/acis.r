use strict;

chdir $homedir;

use ACIS::Web;

my $acis = ACIS::Web -> new ( home => $homedir )
  or die "Can't create ACIS::Web object";

my @f = grep {$_} split m/\s+/, qq( 
  $homedir/presentation/default/person/page.xsl
  $homedir/presentation/default/person/research/main.xsl
);

foreach my $file ( @f ) {
  my $data;
  if ( open IN, "<:utf8", $file ) {
    $data = join '', <IN>;
    close IN;
  } else {
    warn "can't open $file";
    next;
  }
  
  $data =~ s/\[if-config\(([\w\-]+)\)\](-->)?(.+?)(<!--)?\[end-if\]/ 
    "[if-config($1)]" . ( $acis->config($1) ? "-->" : "" ) . $3 . ( $acis->config($1) ? "<!--" : "" ) . "[end-if]" ;
  /exsg;
  
  if ( open OUT, ">:utf8", $file ) {
    print OUT $data;
    close OUT;
  }
}




