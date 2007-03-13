
use strict;
use warnings;
use ACIS::Web;

#####  MAIN PART
my $acis = ACIS::Web -> new( home => $homedir );
my $sql = $acis -> sql_object;
my $RDB = $acis -> config( 'metadata-db-name' );

my $doc_occur_limit = $acis->config( 'fuzzy-name-search-max-name-occurr-in-doc-names' );
if ( not defined $doc_occur_limit ) { $doc_occur_limit = 1; }
my $var_occur_limit = $acis->config( 'fuzzy-name-search-max-name-occurr-in-name-variations' );
if ( not defined $var_occur_limit ) { $var_occur_limit = 0; }

if ( not $doc_occur_limit and not $var_occur_limit ) {
  $acis->sysvarset( "research.search.fuzzy.rare.names.table", undef );
  
} else {
  my $having1st = '';
  if ( $doc_occur_limit ) {  $having1st = "having count(*)<= $doc_occur_limit";  }
  my $having2nd = '';
  if ( defined $var_occur_limit 
       and $var_occur_limit > -1 ) {  $having2nd = "having count(v.name)<= $var_occur_limit"; }

  # data flow:
  # RDB.res_creators_separate -> tmpnames -> tmpnames2 -> rare_names 
  my @q = (
           qq!create temporary table tmpnames ( name varchar(255) not null, index namesi(name) )
              select name from $RDB.res_creators_separate group by name $having1st!,
           qq!create temporary table tmpnames2 ( name varchar(255) not null, index namesi(name) )
              select t.name from tmpnames t left join names v using(name) group by name $having2nd!,
           qq!drop table tmpnames!,
           qq!create table rare_names (name varchar(255) not null, sid char(12) not null, role char(15) not null, primary key (name,sid))!,
           qq!replace into rare_names select t.name,r.sid,r.role from $RDB.res_creators_separate r join tmpnames2 t using(name)!,
           qq!delete from rare_names using rare_names left join tmpnames2 t using(name) where t.name is null!,
           qq!drop table tmpnames2!,
          );

  print "please wait while we build the rare names table...\n";
  foreach ( @q ) {
    $sql -> prepare( $_ );
    print "  $_\n";
    $sql -> execute;
  }
  $acis->sysvarset( "research.search.fuzzy.rare.names.table", "rare_names" );
  
  print "done.\n";
}
