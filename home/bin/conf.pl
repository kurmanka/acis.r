#!/usr/local/bin/perl

use strict; 

use Carp::Assert;

use AppConfig qw(:expand :argcount);  ###  Also see an extension to that module
                                      ###  below

my $homedir = $ENV{homedir};
my $homebin = "$homedir/bin";


my $main = "main.conf";


my $acisconf = [
   "filename:acis.conf",
   "format:AppConfig",
#   { copy => "metadata-db-name db-pass db-user glimpse-binary glimpseindex-bin-path"  },
   { copy => "metadata-db-name db-pass db-user"  },
   { rename => "db-name<acis-db-name" },
   { trans  => 'ACIS_' },
];

my $ardbconf = [
   "filename:ardb.conf",
   "format:AppConfig",
  { rename => "db_name<metadata-db-name db_user<db-user db_pass<db-pass" },
  { set    => [ "db_aliases", "'acis=[[acis-db-name]] sid=[[sid-db-name]]'" ] }
];

my $shell = [
   "filename:thisconf.sh",
   "format:shell",
 { trans => '' },
];

use vars qw( $conf @srcvars );

@srcvars = ();

$conf = AppConfig -> new( {
                              CREATE => 1,
                              CASE => 1,
                              GLOBAL => {
                                         ARGCOUNT => ARGCOUNT_ONE,
                                         EXPAND   => EXPAND_ENV,
                                         ACTION   => sub { push @srcvars, $_[1]; },
                                         }
});

$conf -> define( "metadata-collections" );

###  some defaults
$conf -> set( 'perlbin', `which perl` );
$conf -> set( 'repec-index-socket', "$homedir/ri-socket" );


###  read user's file
$conf -> file( $main );

###  post conf processing
$conf -> set( 'homedir', $homedir );
$conf -> set( 'homelib', "$homedir/lib" );
$conf -> set( 'homebin', "$homedir/bin" );


### metadata configuration
###  RePEc:
if ( $conf -> get( 'RePEc-data-dir' ) ) { 
  my $data = $conf -> get( 'RePEc-data-dir' );
  my $coll = $conf -> get( 'metadata-collections' ) || '';

  $conf -> set( 'metadata-collections', "${coll} RePEc" );
  $conf -> set( 'metadata-RePEc-home',  $data );
  $conf -> set( 'metadata-RePEc-type',  'RePEcRec' );
}



{ ###  ACIS userdata collection:
  my $coll = $conf -> get( 'metadata-collections' ) || '';
  $conf -> set( 'metadata-collections', "$coll ACIS" );
  $conf -> set( 'metadata-ACIS-home'  , "$homedir/userdata" );
  $conf -> set( 'metadata-ACIS-type',   'ACIS_UD' );
}

{
  my $ri_home = "$homedir/RI";
  $conf -> set( 'ri-home', $ri_home );
  $conf -> set( 'ri-log',  "$ri_home/daemon.log" );
  $conf -> set( 'ri-pid-file', "$ri_home/daemon.pid" );
  $conf -> set( 'ri-daemon', "$homebin/control_daemon.pl" );
}
  

# ShortIDs config

$conf -> set( 'sid-home',  "$homedir/SID" );





my $task = shift @ARGV;

if ( $task eq 'mainconf' ) {
  foreach ( $acisconf, $ardbconf, $shell ) {
    make_conf( $_ );
  }
}


sub make_conf {
  my $spec = shift;

  my $context = { data => [] };
  foreach ( @$spec ) {
    my $op;
    
    if ( ref( $_ ) eq 'HASH' ) {
      $op = ( keys( %$_ ) ) [0];

    } else {
      my ( $param, $value ) = split /:/, $_;
      $context -> {$param} = $value;
      next;
    }
    
    if ( $op ) {
      no strict "refs";
      &{ "conf_op_$op" } ( $conf, $context, $_ );
    }
    
  }
  write_conf( $context );
}




##########################################################
###  ATOMIC OPERATIONS
###  -----------------------------------------------    ##
###  called implicitly through symbolic references


sub conf_op_copy {
  my $conf = shift;
  my $context = shift;
  my $oper = shift;

  my @list = split /\s+/, $oper -> {copy};

  my $data = $context -> {data};
  foreach ( @list ) {
    my $v = $conf -> get( $_ );
    push @$data, [ $_, $v ];
  }
}

sub conf_op_set { 
  my $conf = shift;
  my $context = shift;
  my $oper = shift;

  my $set = $oper -> {set};
  my $att = $set ->[0];
  my $tem = $set ->[1];
  
  $tem =~ s/\[\[([\w\-\_]+)\]\]/ my $l = $1; $conf->get( $l ); /eg;

  my $data = $context -> {data};

  assert( $att );
  push @$data, [ $att, $tem ];
}
  

sub conf_op_rename {
  my $conf = shift;
  my $context = shift;
  my $oper = shift;

  my @list = split /\s+/, $oper -> {rename};
  
  my $data = $context -> {data};
  foreach ( @list ) {
    my $att;
    my $v  ; 
    if ( $_ =~ m/([\w\_\-]+)<(.+)/g ) {
      $att = $1;
      my $what = $2;
      $v   = $conf -> get( $what );
#      print "$what='$v' to be saved as $att\n";
    }
    if ( $att ) {
      push @$data, [ $att, $v ];
    }
  }

}


sub conf_op_trans {
  my $conf = shift;
  my $context = shift;
  my $oper = shift;

  my $expr = $oper-> {trans};

  $expr = "(?i)^$expr";
  
  my %vars = $conf -> _iku_varhash( $expr, 1 );

  my $data = $context -> {data};
  foreach ( sort keys %vars ) {
    my ( $k, $v ) = ( $_, $vars{$_} );
    push @$data, [ $k, $v ];
  }
}

##  ---------------------------------------------------
#######################################################

#######################################################
###  W R I T E   C O N F 
#######################################################

sub write_conf {
  my $conf   = shift;
  
  my $file   = $conf ->{filename};
  my $format = $conf ->{format};

  my $data   = $conf ->{data};

  assert( $file );

  if ( open FILE, ">$file" ) {
    no strict "refs";
    my $value = &{ "dump_config_data_$format" } ( $data );
    print FILE $value;
    close FILE;

  } else {
    warn "Can't open file $file";
  }
}


sub dump_config_data_AppConfig {
  my $data = shift;
  my $res  = "# generated from global configuration by $0\n\n";
  
  foreach ( @$data ) {
    my $row = $_;
    if ( ref $_ eq 'ARRAY' ) {
      my $att = $_ ->[0];
      my $val = $_ ->[1];
      
      if ( $val =~ /"/ ) {
        $val = "'$val'";
      }
      if ( $val =~ /\n/ ) {
        $val =~ s!\n!\\\n !g;
      }

      if ( not $val ) {
        $res .= "-$att\n";
      } else {
        $res .= "$att \t= $val\n";
      }

    }
  }
  return $res;
}


sub dump_config_data_shell {
  my $data = shift;
  my $res  = "# generated from global configuration by $0\n\n";
  
  foreach ( @$data ) {
    my $row = $_;
    if ( ref $_ eq 'ARRAY' ) {
      my $att = $_ ->[0];
      my $val = $_ ->[1];
      
      if ( $val =~ /[" ]/ ) {
        $val = "'$val'";
      }
      if ( $val =~ /\n/ ) {
        $val =~ s!\n!\\\n !g;
      }
      $att =~ tr/-/_/;
      $res .= "$att=$val\n";
    }
  }
  return $res;
}



package AppConfig::State;
use strict; 

###  copied from AppConfig::State module, but changed function name to make
###  script future-proof, because author AppConfig::State was going to change
###  this interface.

sub _iku_varhash {
    my $self     = shift;
    my $criteria = shift;
    my $strip    = shift;

    $criteria = "" unless defined $criteria;

    # extract relevant keys and slice out corresponding values
    my @keys = grep(/$criteria/, keys %{ $self->{ VARIABLE } });
    my @vals = @{ $self->{ VARIABLE } }{ @keys };
    my %set;

    # clean off the $criteria part if $strip is set
    @keys = map { s/$criteria//; $_ } @keys if $strip;

    # slice values into the target hash
    @set{ @keys } = @vals;
    return %set;
}


1;
