use strict;
use warnings;
use ACIS::Web;

# The script loads data from the fturls_choices table and dumps out the
# user choices in a simple format.  (Tab-delimited lines per choice.)

# You may specify a date range on the command line.  Dates should be of
# the format YYYY-MM-DD.  If you do not specify an end date, the range
# won't be end-delimited.


#####  MAIN PART  
my $ACIS = ACIS::Web -> new();
my $sql = $ACIS -> sql_object;
my $mdb = $ACIS -> config( 'metadata-db-name' );
my $func  = 'data';
my $where; 
my $name; 
my $limit = '';

if ($func) { 
  my ($sdate,$edate) = @ARGV;
  my $field = 'c.time';
  if ($sdate and $edate) {
    $where = "$field >= '$sdate' and $field <'$edate'";

  } elsif ($sdate) {
    $where = "$field >= '$sdate'";

  } else {
    $where = undef;
  }
  eval "get_$func(\$where,\$limit);";
}


sub get_data {
  my ($where,$limit) = @_;
  if ($where) {
    $where = "WHERE $where";
  } else { 
    $where = '';
  }

  my $choices1 = {y => 'correct',
                  d => 'abstractpage',
                  n => 'wrong',
                  r => 'anotherversion'};

  my $choices2 = {y => 'mayarchive',
                  c => 'checkupdates',
                  n => 'notarchive' };

  my $q =
  qq!select r.id as did,u.url,u.nature,p.id as pid,c.choice,c.time 
     from ft_urls_choices as c
        join ft_urls u using (dsid,checksum)
        join ${mdb}.resources as r on (r.sid=c.dsid)
        join records p on (p.shortid=c.psid)
      $where
      order by time asc
      $limit!;

  $sql -> prepare( $q ) or die "sql error";
  my $r = $sql -> execute or die "sql execute error";

  if ( $r and $r->{row} ) {
    while( $r->{row} ) {
      my $d = $r->{row};
      my $c = $d->{choice};
      $d->{choice1} = $choices1->{substr($c,0,1)};
      $d->{choice2} = $choices2->{substr($c,1,1)} || '';
      $d->{url} =~ s/\s+//g;
      foreach (qw(did url nature pid choice1 choice2 time)) {
        print $d->{$_}, "\t";
      }
      print "\n";
      $r->next;
    }
  }
}




