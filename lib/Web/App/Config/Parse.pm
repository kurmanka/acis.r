package Web::App::Config;

use strict;
use Carp::Assert;

use XML::XPath;
use AppConfig;

use Web::App::Common;
use Web::App::Screen;

sub read_local_configuration {
  my $app  = shift;
  my $data = shift;
  my $file = shift;

  my $params = $app -> configuration_parameters;
  my $config = new AppConfig( {
                                CREATE => 1, 
                                GLOBAL => { ARGCOUNT => 1, },
                              },
                              keys %$params );
  if ( open FILE, "<:utf8", $file ) {
    $config -> file( \*FILE );
    close FILE;
  }
  #print "Parsed $file\n";
  # get all of the parameters:
  my %c = $config -> varlist( '\w' );
  
  foreach ( keys %c ) {
    my $value = $c{$_};
    my $p = $params-> {$_};
#    print "opt: $_\tvalue: $value\n";
    if ( defined $value ) {
      $data ->{$_} = $value;
    } else { 
      # should we shout and die? 
      # do we have a default for this parameter?
      if ( $p eq 'required' ) {
        die "required configuration parameter '$_' is absent"
      } elsif ( $p eq 'not-defined' ) {
      } else {
        $data ->{$_} = $p;
      }
    }
  }

  return $data;
}



sub read_screens_file {
  my $app  = shift;
  my $data = shift;
  my $file = shift;

  debug 'loading screens configuration';
  
  my $xp = new XML::XPath( filename => $file );

  parse_screens_modules( $xp, $data );
  parse_screens_options( $xp, $data );
  parse_screens_sets(    $xp, $data );
  parse_screens_screens( $xp, $data );

  return $data;
}


sub parse_screens_modules {
  my $xp   = shift;
  my $self = shift;

  my $mods = $self -> {modules} || [];
  assert( ref $mods eq 'ARRAY' );

  my @module_nodes_list = $xp -> findnodes( '/screens/use-perl-module' );

  foreach my $module ( @module_nodes_list ) {
    $module = $module -> findvalue( "text()" );
    push @$mods, "$module";
  }
  $self -> {modules} = $mods;
  
}


sub parse_screens_screens {
  my $xp   = shift;
  my $self = shift;

  my @screen_nodes_list = $xp -> findnodes ( '/screens/screen' );
  # find all screen nodes

  foreach my $screen ( @screen_nodes_list )  {

    my $id = $screen -> getAttribute ( 'id' );
    next unless defined $id;

    my $screen_object = new Web::App::Screen( "$id" );

    if ( defined $screen -> getAttribute( 'process-on-POST' ) ) {
      $screen_object -> {'process-on-POST'} = 1;
    }

    my @use_nodes = $xp -> findnodes ( 'use[@module]', $screen );
    foreach my $use ( @use_nodes ) {
      my $module = $use -> getAttribute( 'module' );
      $screen_object -> add_use_module( "$module" );
    }
    

    if ( $xp -> findnodes ( 'presentation', $screen ) ) {    
      eval {
        my $type;
        if ( $type = $xp -> findvalue ( 'presentation/@type', $screen ) ) {
          $screen_object -> presentation_type( "$type", "$screen" );
        } else { die; }
        
        my $relative_path = $xp -> findvalue( 'presentation/@filename', $screen ) 
          || die;

        $screen_object -> presentation_file ( "$relative_path" );
      };
      
#     if ( $@ ) { undef $@; next; }
    }
    

    my @process_nodes = $xp -> findnodes ( 'descendant::call', $screen );
    foreach my $call ( @process_nodes ) {
      my $func = $call -> getAttribute( 'function' );

      if ( $xp-> exists( "parent::init", $call ) ) {
        $screen_object -> add_init_call( "$func" );        

      } elsif ( $xp -> exists( "parent::process", $call ) ) {
        $screen_object -> add_process_call( "$func" );        

      } else {
        $screen_object -> add_call( "$func" );
      }
    }
    

    my @param_nodes = $xp -> findnodes( 'param', $screen ); 
    
    my $variables = $screen_object -> {variables} ||= [];
    foreach my $node ( @param_nodes )  {

      my $param = {
        'name'     => undef,
        'required' => undef,
        'type'     => undef,
        'place'    => undef,
      };

      foreach ( qw( name required type place if-not-empty maxlen ) ) {
        my $val = $node -> getAttribute ( $_ );
        if ( $val ) {
          $param -> {$_} = $val;
        }
      }

      push @$variables, $param;
    }


    ###  now save the object
    $self -> {screens} {$id} = $screen_object;
  }
}



sub parse_screens_options {
  my $xp   = shift;
  my $self = shift;

  my $opts = $self -> {options} = [];
  assert( ref $opts eq 'ARRAY' );

  my @nodes = $xp -> findnodes( '/screens/option[@name]' );

  foreach my $node ( @nodes ) {
    my $name    = $node -> findvalue( '@name'    );
    my $default = $node -> findvalue( '@default' );
    my $type    = $node -> findvalue( '@type'    );
    my $required= $node -> findvalue( '@required' );

    my $o = { name => "$name" };
    if ( $default ) { $o -> {default} = "$default"; }
    if ( $type    ) { $o -> {type}    = "$type";    }
    if ( $required) { $o -> {required} = 1;        }

    push @$opts, $o;
  }

  $self -> {options} = $opts;
}


sub parse_screens_sets {
  my $xp   = shift;
  my $self = shift;

  my @nodes = $xp -> findnodes( '/screens/set[@var and @value]' );

  foreach my $node ( @nodes ) {
    my $var   = $node -> findvalue( '@name'  );
    my $value = $node -> findvalue( '@value' );
    if ( not defined $value ) { 
      $value = $node -> findvalue( "text()" );
    }

    $self -> {"$var"} = "$value";
  }
}






sub check {
  my $self = shift;
  
  my $presenters_dir = $self -> {home} . '/presentation/' .
                       $self -> {'template-set'} . '/';
  
  foreach ( keys %{ $self -> {screens} } ) {
    my $scr = $self -> screen ($_);
    next if not $scr ->{presentation};

    my $presentation = $scr -> presentation_file;
  }
}




sub new {
  my $class = shift;
  my $data_dir    = shift;
  my $config_file = shift;
  my $screen_file = shift;
  
  #my $data_dir =~ s/\/$//);
  
  my $self =  {
    'home'    => $data_dir,
    'file'    => $config_file,
    'screen-config' => $screen_file,
    'screens' => {},
    'modules' => [],
    'options' => [],
   };
   
  bless $self, $class;
  
  $self -> load_screens;
  
  $self -> load;
  
  $self -> check;
  
  return $self;
}







1;

