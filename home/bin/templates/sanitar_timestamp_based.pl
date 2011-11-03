use strict;
use warnings;

# The resources, objects and institutions tables all have the
# timestamp column. If there was an issue in the update deamon, for
# example, a database crash, ARDB+ACIS may have unnoticed that a
# record is gone from its underlying data file. If it hasn't noticed
# such case, it wouldn't clean the record from the table, nor would it
# update it in any way. And since the update daemon have lost history
# of the record, it may never know that the record needs cleaning from
# it's related tables. Such records may pile up over time. We call
# such records 'ghost' records.
#
# So, if a record in one of these tables is getting outdated and does
# not get updated in a while, its timestamp would point to a moment in
# the past. That's how we can identify those records and clean them
# up.
# 
# See also the notes in upgrade_to_1.6.50.pl script (in
# home/bin/templates dir).

my $interval = join(' ', @ARGV)
    or die "specify the full update interval, e.g. '30 day'".

# interval should follow the MySQL INTERVAL syntax
# http://dev.mysql.com/doc/refman/5.5/en/date-and-time-functions.html

require ARDB;
require ARDB::Local;
my $ARDB = ARDB -> new() or die;
my $sql = $ARDB -> sql_object;

=head1 EXAMPLE SQL

### delete outdated 
delete from resources where timestamp    < DATE_SUB( CURDATE(), INTERVAL 30 DAY );
delete from institutions where timestamp < DATE_SUB( CURDATE(), INTERVAL 30 DAY );
delete from objects where timestamp      < DATE_SUB( CURDATE(), INTERVAL 30 DAY );

### res_creators_bulk: count & delete 
select count(*) from res_creators_bulk as rcb, resources as r where r.sid=rcb.sid and r.timestamp is null;
delete rcb, r from res_creators_bulk as rcb left join resources as r using (sid) where r.timestamp is null;

### res_creators_separate: count & delete 
select count(*) from res_creators_separate as rcs left join resources as r using (sid) where r.timestamp is null;
delete rcs from res_creators_separate as rcs left join resources as r using (sid) where r.timestamp is null;

### XXX how about the rp_suggestions table?

=cut 

#  the SQL to run
my @do1 = (
    qq!
delete from resources where timestamp    < DATE_SUB( CURDATE(), INTERVAL $interval )!,
    qq!
delete from institutions where timestamp < DATE_SUB( CURDATE(), INTERVAL $interval )!,
    qq!
delete from objects where timestamp      < DATE_SUB( CURDATE(), INTERVAL $interval )!,
    qq!
delete rcb, r from res_creators_bulk as rcb left join resources as r using (sid) where r.timestamp is null !,
    qq!
delete rcs from res_creators_separate as rcs left join resources as r using (sid) where r.timestamp is null !,
    );

print "please wait while we remove ghosts from the database...\n";

use Data::Dumper;
foreach ( @do1 ) {
  $sql -> prepare( $_ );
  print "  $_\n";
  my $r = $sql -> execute;
  if ($r) {
    print "  - result: modified ", $r->rows, " rows\n";
  }
  if ($sql->error) {
    print "  - error: " , $sql->error, "\n";
    last;
  }
}

print "clean-up done.\n";
