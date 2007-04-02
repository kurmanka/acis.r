
use sql_helper;
use ACIS::Web;
use ACIS::Web::Admin;

my $dest = pop @ARGV;
my $src  = [ @ARGV ];
if ( not $dest or not scalar @$src ) {
  die "Usage: $0 src1 [src2 ...] dest\n";
}

my $acis = ACIS::Web -> new();
my $login = $dest;
my $res = ACIS::Web::Admin::offline_userdata_service($acis, $login, 'ACIS::Web::Admin::move_records');


