package ARDB;  ### -*- mode: perl -*- 

###  ARDB::Setup


use strict;

use Carp::Assert;
use Data::Dumper;
use Storable qw( &store &retrieve );

use sql_helper;

use ARDB::Configuration; ### ---
use ARDB::SiteConfig;    ### ---

use ARDB::Common;
use ARDB::ObjectDB;
use ARDB::Relations;
use ARDB::Plugins;
use ARDB::Relations::Transaction;



sub new_bootstrap { 

  my $class = shift;
  my $home  = shift;

  assert( $home );

  $ARDB::Common::LOGFILENAME = $home . '/ardb.log';


  debug "try to retrieve configuration from ARDB::SiteConfig";
  my $site_config = new ARDB::SiteConfig( $home );

  # create a structure and bless it:
  my $self = {
    site_config => $site_config,

    db_name     => $site_config -> db_name,
    db_user     => $site_config -> db_user,
    db_pass     => $site_config -> db_pass,
    
    config      => undef,
    sql_object  => undef,
    relations   => undef,
    plugins     => undef,

    home        => undef,
  };
    
  bless $self, $class;
  

  $self->{home}           = $home;
#  $self->{object_db_file} = $home . '/objects/data.db';
  $self->{config_file}    = $home . '/configuration.xml';


  ###############
  # init object #
  ###############
  
  debug "try to connect to mysql database";

  sql_helper -> set_log_filename ( $home . '/log/sql.log' );

  my $sql_helper = sql_helper -> new( $self -> {db_name}, 
                                      $self -> {db_user},
                                      $self -> {db_pass} );

  if ( not $sql_helper ) {
    die "Can't establish database connection";
  }

  $self -> {sql_object} = $sql_helper;
#  $sql_helper ->  do( "SET CHARACTER SET utf8" );  ### XXX UTF8 in Mysql
  $sql_helper -> {dbh} -> {mysql_auto_reconnect} = 1;


  $self -> {relations} = new ARDB::Relations ( $sql_helper );

  $self -> init_config;

  return $self;
}


my $output;

sub p (@) {
  print FILE @_;
}

sub init ($) {
  if ( not defined $_[0] ) {
    $_[0] = '';
  } 
}


sub write_local {
  my $self = shift;
  my $file = shift;

  open FILE, ">$file";


  p q!package ARDB::Local;

  use Carp::Assert;

  require ARDB;

!;

  p qq!\$home = '$self->{home}';\n\n!;

  ### load and printout SiteConfig
  my $sconf = $self -> {site_config};


  p "require ARDB::SiteConfig;\n";
  p "use ARDB::Common;\n";

  p( Data::Dumper -> Dump( [$sconf], [qw( site_config )]) );  

  ### load and printout Config
  p "require ARDB::Table;\n";
  p "require ARDB::RelationType;\n";

  my $conf = $self -> {config};

  my $rtypes = $conf -> {record_types};
  delete $conf ->{record_types};
  delete $conf ->{site_config};

  p( Data::Dumper -> Dump( [$conf], [qw( config )] ) );  

  $conf -> {record_types} = $rtypes;

  ###  Use every module of the module list
  my $modules = $conf->{'modules-to-load'};
  foreach ( @$modules ) {
#    p "use $_;\n";
    p "require $_;\n";
  }


  ###  Plugins: start_list, create, init, record_processing

  p qq!\n ###  PLUGINS \n!;

  my $plugins = $self -> {plugins};
  my $start_list = $plugins -> start_list;
  
  p( Data::Dumper -> Dump( [ $start_list ], [qw( plugins_start_list )] ) );  

  p q!
  $plugins = {};
!;

  foreach ( @$start_list ) {
    my $name = $_ ->[0];
    my $home = $_ ->[2];
    my $dpth = $_ ->[1];  ###  dependencies?

    p qq!
 { 
   use $name;
   my \$p = $name -> new( '$home' );

   if ( not \$p -> status ) {
      if ( not \$p -> init ) {
         warn "Can't initialize plugin $name";
      }
   }

   \$plugins -> {'$name'} = \$p;
 }
!;

  }

  my $plug_rt = $plugins -> {record_types};
  foreach ( keys %$plug_rt ) {
    my $t = $_;
    my $queue = $plug_rt ->{$t};

    if ( not $queue ) {
      warn "plugins, rtype: $t, no plugins for that.";
      next;
    }

    my @plugs = @$queue;
    
    my $type_def = $rtypes ->{$t};
    if ( $type_def ) {
      foreach ( @plugs ) {

        
        init $type_def -> {'put-process'};

        $type_def -> {'put-process'} .= qq!
{
  my \$p = \$ARDB -> {plugin_index} {'$_'};
  if ( \$p ) {
    \$p -> process_record( \$record, \$ARDB );
  }
}
!;
      }
    }
    
  }

  $conf -> finalize_generated_code();



  ###  per record-type processing:


  p q!
my $rt = {};
!;


  foreach ( keys %$rtypes ) {
    my $def = $rtypes->{$_};
    p q! $rt->{'!, $_, q!'} = { !, "\n";

    foreach ( qw( put-process-ref delete-process-ref ) ) {
      $_ =~ m/([-\w]+)(\-ref)$/;
      my $text = $def->{"$1-text"} || '';
      p " '$_' => sub { \n$text\n },\n\n"; 
    }
    p "};\n\n";
  }

  p q! $config -> {record_types} = $rt; !, "\n";



  ### generate ARDB itself


  p "\n1;\n" ;


  close FILE;
}



package ARDB;


sub init_config {
  my $self        = shift;
  my $config_file = $self -> {config_file};

  my $site_config = $self -> {site_config};

  my $home = $self -> {home};

  my $config_object;

  # try comparing timestamps

  my $bin_config_file = $config_file . '.binary';

  debug "compare timestamps of the config file '$config_file', "
    . "its binary dump '$bin_config_file' and module ARDB::Configuration";

  my $configuration_package_file = $INC{'ARDB/Configuration.pm'};
  
  ###########################################
  
  debug 'parsing configuration';

  $config_object = new ARDB::Configuration ( $site_config )
    || critical "ARDB::Configuration did not work";
  
  $config_object -> parse_config( $config_file );
  store ( $config_object, $bin_config_file )
    or log_error ( "cannot write binary config to '$bin_config_file'" );


  debug "retrieve information about plugins";

  my $plugins = new ARDB::Plugins ( $home, $self );
  
  $self -> {plugins} = $plugins;

  my $plugins_list = $plugins -> start_list;

  debug "retrieve configuration of plugins and parse it";

  foreach my $plugin_desc ( @$plugins_list ) {
    my $plugin_name = $plugin_desc -> [0];
    
    debug "try reading '$plugin_name' plugin configuration";
    
    my $plugin_config;
    my ($short_name) = ($plugin_name =~ /.*::(\w+)/);
    eval "\$plugin_config = $plugin_name -> config;";
    
    if ( $@ ) { critical $@;  }
    
    if ( $plugin_config ) {
      my $file = "$home/plugins/Processing/$short_name/" 
               . $plugin_config;
      $config_object -> parse_config( $file );
    }
    
  }
 
  debug "try to compile config";
  $config_object -> compile_config;
 
  $self -> {config} = $config_object;
}



package ARDB::SiteConfig;

use AppConfig qw(:expand);


sub new {
  my $class = shift;
  my $home  = shift;
  assert( $home );
 
  my $self = {};

  # read the file
 
  # create a new AppConfig object
  my $filename = $home . '/ardb.conf';

  $filename =~ s|//|/|g;

  if ( not -e $filename 
       or not -r _ ) {
    critical "Local site configuration file ($filename) doesn't exist";
  }

  debug "creating AppConfig object";
  my $config = new AppConfig( {
       GLOBAL  => {
         ARGCOUNT => 1,
         DEFAULT  => "",
       },
#       ERROR     => \&critical, 
       ERROR     => sub {},
     },
     @parameters
  );


  $config -> file( $filename );

  # go through the @parameters, requesting the values from the file
  # and storing them into $self hash
  
  foreach my $param ( @parameters ) {
    my $sparam = $param;
    $sparam =~ tr/-/_/;
    $self ->{ $sparam } = $config -> get( $param );
  }

  bless $self, $class;

  $self -> parse_db_aliases;
  
  return $self;
}



1;
