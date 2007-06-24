

use strict;
use warnings;
use ACIS::Web;

# The script checks the citations_events table and dumps out identified
# citation events in a specific format.  

#  When you start the script, specify a month as a parameter on the
#  command line.  Month must be in the YYYY-MM form or 'this', 'last'.
#  Data from that month will be reported to stdout.


#####  MAIN PART  
my $ACIS = ACIS::Web -> new();
my $sql = $ACIS -> sql_object;
my $mdb = $ACIS -> config( 'metadata-db-name' );
my $func = shift;
my $where = " AND " . get_range_condition( 'ce.time', @ARGV );
my $limit = '';

if ($func) { 
  eval "get_$func(\$where,\$limit);";
}
#get_count($where,$limit);
#get_time($where,$limit);

sub get_count {
  my ($where,$limit) = @_;
  my $q =
  qq!select count(*) as c from citation_events as ce
      join citations c using (cnid)
      where (ce.event='added' or
             ce.event='unidentified' or 
             (ce.event='autoadded' and ce.reason='similar')) 
            $where
      order by time asc
      $limit!;

  $sql -> prepare( $q );
  my $r = $sql -> execute;

  if ( $r and $r->{row} ) {
    print $r->{row}->{c}, "\n";
  }
}

sub get_time {
  my ($where,$limit) = @_;
  my $q =
  qq!select ce.time from citation_events as ce
      where (ce.event='added' or
             ce.event='unidentified' or 
             (ce.event='autoadded' and ce.reason='similar')) 
            $where
      order by time asc
      $limit!;

  $sql -> prepare( $q );
  my $r = $sql -> execute;

  if ( $r and $r->{row} ) {
    while( $r->{row} ) {
      my $d = $r->{row};
      print $d->{time}, "\n";
      $r->next;
    }
  }

}

sub get_data {
  my ($where,$limit) = @_;

  my $q =
  qq!  select src.id as srcdocid,RIGHT(c.clid,22) as md5,trg.id as trgdocid,ce.event 
     from citation_events as ce
        left join citations c using (cnid)
        join ${mdb}.resources as src on (src.sid=c.srcdocsid)
        join ${mdb}.resources as trg on (trg.sid=ce.dsid)
      where (ce.event='added' or
             ce.event='unidentified' or 
             (ce.event='autoadded' and ce.reason='similar')) 
            $where
      order by time asc
      $limit!;

  $sql -> prepare( $q );
  my $r = $sql -> execute;

  if ( $r and $r->{row} ) {
    while( $r->{row} ) {
      my $d = $r->{row};
      my $srcdocid = $d->{srcdocid};
      my $md5      = $d->{md5};
      my $trgdocid = $d->{trgdocid};
      my $event    = $d->{event};
      print $srcdocid, "\t", $md5, "\t", $trgdocid, "\t", $event, "\n";
      $r->next;
    }
  }
}


#test_ranges();

sub test_ranges {
  my @ranges = ('month', 'this',
                'month', 'last',
                'month', '2006-12',
                'month', '2007-06',
                'day',   'today',
                'day',   'yesterday',
                'day',   '2004-05-23',
               );
  while ( scalar @ranges ) {
    my $l = shift @ranges || die;
    my $s = shift @ranges || die;
    my $c = get_range_condition( 'time', $l, $s );
    print "$l $s: $c\n";
  }
}
                



sub get_range_condition {
  my ($field,$length,$spec) = @_;
  my ($s,$e) = get_range( $length,$spec );
  if ($e) {
    return "$field >= $s and $field <$e";
  } else {
    return "$field >= $s";
  }
}

sub get_range {
  my ($length,$spec) = @_;
  my $start;
  my $end;
 
  if ($length eq 'month') {
    return get_month_range( $spec );
  } else {
    return get_day_range( $spec );
  }
}

sub get_month_range {
  my $spec = shift;

  if ($spec eq 'this') {
    return( "DATE_FORMAT(CURDATE(),'\%Y\%m01')", ); 

  } elsif ($spec eq 'last') {
    my $prev_month;
    $sql->prepare( "select DATE_FORMAT(DATE_SUB(CURDATE(),INTERVAL 1 MONTH),'\%Y\%m01') as d ");
    my $r = $sql->execute();
    if ( $r and $r->{row}{d} ) {
      $prev_month = $r->{row}{d};
    }
    return( "'$prev_month'", "DATE_FORMAT(CURDATE(),'\%Y\%m01'");

  } elsif ($spec =~ m!^(\d{4}\-\d{2})!) {
    my $start = "$1-01";
    my $end;
    $sql->prepare( "select DATE_FORMAT(DATE_ADD('$start',INTERVAL 1 MONTH),'\%Y\%m01') as d ");
    my $r = $sql->execute();
    if ( $r and $r->{row}{d} ) {
      #print $r->{row}{d}, "\n";
      $end = $r->{row}{d};
    }
    return( "'$start'", "'$end'" );
  }
  die "can't get month range: $spec";
}


sub get_day_range {
  my $spec = shift;

  if ($spec eq 'this' 
      or $spec eq 'today') {
    return( "DATE_FORMAT(CURDATE(),'\%Y\%m\%d')", undef); 

  } elsif ($spec eq 'last' 
           or $spec eq 'yesterday') {
    my $y;
#    $sql->prepare( "select DATE_FORMAT(DATE_SUB(CURDATE(),INTERVAL 1 DAY),'\%Y\%m\%d') as d ");
    $sql->prepare( "select DATE_SUB(CURDATE(),INTERVAL 1 DAY) as d");
    my $r = $sql->execute();
    if ( $r and $r->{row}{d} ) {
      $y = $r->{row}{d};
    }
    return( "'$y'", "CURDATE()");

  } elsif ($spec =~ m!^(\d{4}\-\d{2}-\d{2})!) {
    my $start = $1;
    my $end;
    $sql->prepare( "select DATE_ADD('$start',INTERVAL 1 DAY) as d ");
    my $r = $sql->execute();
    if ( $r and $r->{row}{d} ) {
      $end = $r->{row}{d};
    }
    return( "'$start'", "'$end'" );
  }
  die "can't get day range: $spec";
}


#print "upgrade done, but please restart the update daemon ASAP!\n";


__END__


# get month code:

my $month = shift || '';

if ( $month eq 'this' ) {
  # current month 
  $where = "WHERE ce.time >= DATE_FORMAT(CURDATE(),'\%Y\%m01')";

} elsif ( $month eq 'last' ) {
  # prev month
  my $prev_month;
  $sql->prepare( "select DATE_FORMAT(DATE_SUB(CURDATE(),INTERVAL 1 MONTH),'\%Y\%m01') as d ");
  my $r = $sql->execute();
  if ( $r and $r->{row}{d} ) {
    #print $r->{row}{d}, "\n";
    $prev_month = $r->{row}{d};
  }
  $where = "WHERE ce.time>=$prev_month and ce.time < DATE_FORMAT(CURDATE(),'\%Y\%m01')";

} elsif ( $month eq 'last-and-all' ) {
  # preidentified citations from the previous month and
  # similar citations from all the time
  # coauthor citations -- not included
  my $prev_month;
  $sql->prepare( "select DATE_FORMAT(DATE_SUB(CURDATE(),INTERVAL 1 MONTH),'\%Y\%m01') as d ");
  my $r = $sql->execute();
  if ( $r and $r->{row}{d} ) {
    #print $r->{row}{d}, "\n";
    $prev_month = $r->{row}{d};
  }
  $where = "WHERE (ce.reason='preidentified' and ce.time>=$prev_month and ce.time < DATE_FORMAT(CURDATE(),'\%Y\%m01')) or (ce.reason='similar')";

} elsif ( $month =~ /^\d{4}\-\d{2}$/ ) {

  $month .= "-01";
  my $fin;

  $sql->prepare( "select DATE_ADD('$month',INTERVAL 1 MONTH)+0 as d ");
  my $r = $sql->execute();
  if ( $r and $r->{row}{d} ) {
    #    print $r->{row}{d}, "\n";
    $fin = $r->{row}{d};
  }
  
  $month =~ s/\-//g; # YYYYMMDD
  $where = "WHERE ce.time >= $month and ce.time < $fin";

} else {
  die "Specify month as a parameter.  Month must be in the YYYY-MM form or 'this', 'last'."; 
}
