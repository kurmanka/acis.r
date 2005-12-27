
use sql_helper;
use ACIS::Web;

my $dest = pop @ARGV;
my $src  = [ @ARGV ];

if ( not $dest or not scalar @$src ) {
  die "Usage: $0 src1 [src2 ...] dest\n";
}

sub get_sources { $src };

my $acis = ACIS::Web -> new( home => $homedir );


use ACIS::Web::Admin;

my $login = $dest;

###  get hands on the userdata (if possible),
###  create a session and then do the work

my $res   = ACIS::Web::Admin::offline_userdata_service
  ( $acis, $login, 'ACIS::Web::Admin::move_records' );


