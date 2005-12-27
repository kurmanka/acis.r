package ARDB::Plugins;

use strict;
use warnings;

use Carp;

use Carp::Assert;

use ARDB::Common;

#########################################################################
##                          constructor                                ##
#########################################################################

sub new {
  my $class = shift;
  my $home  = shift;
  my $ardb  = shift;

  my $plugins_path = $home . '/plugins';
  $plugins_path    =~ s!//!/!g;
  
  my $self =  {
    'prefixes'     => {},
    'record_types' => {},
    'plugin-path'  => $plugins_path,
    'home'         => $plugins_path,
    'start-list'   => undef,
    'ok'           => 'ok',
    'ardb'         => $ardb,
    'all_plugins'  => [],
  };

  bless $self, $class;

  $self -> init;

  return $self;
}


  ########################################################
  #       s t a r t    l i s t 
  ########################################################

sub start_list {
  my $self = shift;
  
  if ( $self -> {'start-list'} ) {
    return $self -> {'start-list'};
  }
  
  
  my $plugin_path = $self -> {'plugin-path'};

  debug "reading plugin directories from '$plugin_path'";

  my @independent_plugins;
  
  opendir ( PROCESSING_PLUGINS, $plugin_path . '/Processing/' );
  
  my @plugins;
  my %plugin_homes;

  my @plugin_ids =
    grep { 
        !/^\.+$/ 
        and -d "$plugin_path/Processing/$_" 
          and !/^CVS$/
      } readdir ( PROCESSING_PLUGINS );
  

  foreach ( @plugin_ids ) {
    push @plugins, "ARDB::Plugin::Processing::$_";
    $plugin_homes{"ARDB::Plugin::Processing::$_"} = "$plugin_path/Processing/$_";
  }

  closedir ( PROCESSING_PLUGINS );

  my %plugins;
  my @start_list = ();

  debug "found plugins: ". join (", ", @plugins);
    
  
  foreach my $plugin_name ( @plugins ) {
    my $id = shift @plugin_ids;
    
    debug "using $plugin_name";
    eval "use $plugin_name;";

    if ( $@ ) {
      critical ( "cannot load plugin $plugin_name, error: '$@'" );
      die "Cannot load ARDB plugin $plugin_name: $@";
      next;
    }

    if ( 1 ) {
      my $plugins_list;
      
      debug "try read dependencies of '$plugin_name'";
      
      eval "\$plugins_list =  $plugin_name -> require";
      if ( not $@ ) {

        if ( scalar @$plugins_list ) {

          foreach ( @$plugins_list ) {
            debug "plugin '$plugin_name' require '$_'";
            push @{ $plugins{$_} -> {prerequisite} }, $plugin_name;
            $plugins{$plugin_name} -> {required} -> {$_} = 1;
          }

        } else {
          debug "plugin '$plugin_name' have no dependecies";
          push @independent_plugins, $plugin_name;
        }
      }

    } else {
      debug "strange plugin '$plugin_name'";
      push @independent_plugins, $plugin_name;
    }

  }
  
  debug "push plugins into start list";
  
  my $deep = 0;

  while ( scalar @independent_plugins ) {

    debug "at $deep level found independent plugins: ".
     join (", ", @independent_plugins);
    my @independent_candidate = ();

    foreach my $plugin_name ( @independent_plugins ) {
      my $the_plugin = $plugins{$plugin_name};
      my $home = $plugin_homes{$plugin_name};
      push @start_list, [ $plugin_name, $deep, $home ];

      my $pre = $the_plugin ->{prerequisite};
      foreach my $prerequisite ( @$pre ) {

        delete $plugins{$prerequisite} -> {required} {$plugin_name};
        
        if ( not scalar %{ $plugins{$prerequisite} {required} } ) {
          push ( @independent_candidate, $prerequisite );
        }
      }
    }

    $deep++;
    @independent_plugins = @independent_candidate;
    
  }
  
  $self -> {'start-list'} = \@start_list;
  
  return $self -> {'start-list'};
}



  ########################################################
  #     i n i t i a l i z e 
  ########################################################

sub init {
  my $self = shift;
  
  my $start_list = $self -> start_list;
  my $array      = $self -> {all_plugins};
  my $registry   = {};

  foreach my $plugin_ref ( @$start_list ) {

    my $name = $plugin_ref -> [0];
    my $deep = $plugin_ref -> [1];
    my $home = $plugin_ref -> [2];

    my $plugin = "$name" -> new ( $home ) ;

    unless ( defined $plugin ) {
      critical ( "cannot create $name object, error: $@");
    }
    
    if ( not $plugin -> status ) {
      if ( not $plugin -> init ) {
        critical ( "cannot initialize $name object, error: $@");
      }
    }
    
    push @$array, $plugin;
    $registry->{$name} = $plugin;

    {
      my $record_types = "$name" -> get_record_types;

      foreach ( @$record_types ) {
        push @{ $self -> {record_types} -> {$_} }, $name ;
      }
    }

  }
  
}



sub process_record {
  my $self   = shift;
  my $record = shift;

  my $result = 'ok';

  my $record_type = $record -> type;

  debug "search for a plugin, responsible for this record-type: $record_type";
  
  my $plugins = $self -> {record_types} -> {$record_type};
  assert( $plugins );
  
  foreach my $plugin ( @$plugins ) {

    if ( not $plugin ) {
      warn "rec type: $record_type, id: " . $record->id . "; plugin is absent";
      use Data::Dumper;
      warn Dumper( $self );
      next;
    }

    assert( $plugin );

    debug "try storing record with $plugin";
    $plugin -> process_record ( $record, $self->{ardb} )
      or $result = undef;
    
  }
  return $result;
}


1;

=pod

=head1 NAME

ARDB::Plugin - class for ARDB plugins support

=head1 methods

=over 1

=item get_start_list

Processing plugins each have method ``required'', it returns ARRAY of required
plugin names.



этот метод возвращает список plugins так, как они должны стартовать. тип
возвращаемого значения - ARRAY, значения элементов - ARRAY, первый элемент
которого - название plugin, второе - вложенность.

! имена plugins в секции required configuration.xml и имена plugins
возвращаемые методом get_start_list не имеют префикса ARDB::Plugins

=back

=cut
