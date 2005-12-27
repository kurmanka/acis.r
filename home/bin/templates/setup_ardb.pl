

my $ardb_local = "$homedir/lib/ARDB/Local.pm";

### XXX shall be an option for a case when Local.pm is not usable.
#
# system( "echo '1;' > $ardb_local" );  

eval { 
  use ARDB;
  use ARDB::Setup;
};

my $ardb = ARDB -> new_bootstrap( $homedir );

$ardb -> write_local( $ardb_local );

