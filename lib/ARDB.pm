package ARDB;  #  Abstract RePEc Database


use strict;

use Data::Dumper;
use Carp::Assert;
#use Storable qw( &nstore &retrieve );

use sql_helper;

# use ARDB::Configuration; ### ---
use ARDB::SiteConfig;    ### ---



use ARDB::Common;
use ARDB::ObjectDB;
use ARDB::Relations;
use ARDB::Relations::Transaction;


use vars qw( $VERSION );

# $VERSION = do { my @r=(q$Revision$=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
# $Id$;

use vars qw( $ARDB );



sub new { 
  my $class = shift;

  my $home = $ARDB::Local::home;

  my $site_config = $ARDB::Local::site_config;
  my $plugins     = $ARDB::Local::plugins;

  # create a structure and bless it:
#  my $self = { %$ARDB::Local::itself };
#  bless $self, $class;

  # create a structure and bless it:
  my $self = {
    site_config => $site_config,

    db_name     => $site_config -> db_name,
    db_user     => $site_config -> db_user,
    db_pass     => $site_config -> db_pass,
    
    config      => undef,
    sql_object  => undef,
    relations   => undef,
    plugin_index => $plugins,

    home        => undef,
  };
    
  $self -> {log_file} = "$home/ardb.log";
  $ARDB::Common::LOGFILENAME = $home . '/ardb.log';


  bless $self, $class;
  $ARDB::ARDB = $self;

  $self->{home}           = $home;
#  $self->{object_db_file} = $home . '/objects/data.db';
  $self->{config_file}    = $home . '/configuration.xml';


  $self -> {config} = $ARDB::Local::config; ### XXX bad, breaks OO style
  $plugins-> {ardb} = $self;


  ###############
  # init object #
  ###############
  
  debug "try to connect to mysql database";

  sql_helper -> set_log_filename ( $home . '/sql.log' );

  my $sql_helper = sql_helper -> new( $self -> {db_name}, 
                                      $self -> {db_user},
                                      $self -> {db_pass} );

  if ( not $sql_helper ) {
    die "Can't establish database connection";
  }

  $self -> {sql_object} = $sql_helper;
#  $sql_helper -> do( "SET CHARACTER SET utf8" );  ### XXX UTF8 in Mysql
  $sql_helper -> {dbh} -> {mysql_auto_reconnect} = 1;

  $self -> {relations} = new ARDB::Relations ( $sql_helper );

  return $self;
}



sub relations  {  return $_[0]->{relations};   }
sub sql_object {  return $_[0]->{sql_object};  }
sub config     {  return $_[0]->{config};      }


###################################################################################
###  sub  P U T    R E C O R D 
###################################################################################


my $stored = {};

sub put_record { # store and process record

  my $self   = shift;
  my $record = shift;

  my $result;

  # receive all relations, where source = id of this record
  # delete all non-longer-existing relations of this record
  # replace all changed relations
  # create new relations

  ###  creating new relations
  ###  map attributes by field attribute mapping
  
  assert( $record );

  my $id   = $record -> id;
  my $type = $record -> type;

  assert( $id and $type );

  $self -> {record} = $record;

  $stored->{$id} = 1;


  my $record_types      = $self -> {config} -> {record_types};
  my $processing_object = $record_types -> { $type };

  unless ( defined $processing_object ) {
    $self -> logerr(
             "can't process record '$id' because '$type' is not configured"
                   );
    return undef;
  }
  

  $result = 1;

  my $code = $processing_object -> {'put-process-ref'};

  if ( $code ) {
    debug "going to execute put-processing code";

    my $relations = $self -> {relations};
    my $transaction = new ARDB::Relations::Transaction ( $id, $relations );
    
    $transaction -> prepare;

    eval {
      &$code ( $self, $record, $transaction );
    };
    
    if ( $@ )  { 
      log_warn "put-process-ref: {" . $processing_object -> {'put-process-text'} . "}";
#      critical "an error while running the processing code: $@";
      $self -> logerr( "while processing rec $id: $@" );
      return undef;
      $result = 0;
    }

    debug "try to save new relations and delete old";
    
    $transaction -> commit;
  }


  $record = $self -> {record};
  undef $self -> {record};

  if ( $record ) {
    debug "try to store record object";
    if ( not ARDB::ObjectDB::store_record( $record, $id ) ) {
      $self -> logerr( "cannot store record '$id' in ObjectDB" );
      die "cannot store record '$id' in ObjectDB";
      return undef;
    }
    
    $self -> log( "stored record $id of type $type successfully" );

  } else {
    $self -> logerr( "not saving record '$id' in ObjectDB" );
    $result = 0;
  }    

  return $result;
}


################################################################################
###  sub  D E L E T E    R E C O R D 
################################################################################

sub delete_record { # takes record id
  my $self = shift;
  my $id   = shift;
  
  my $record = $self -> get_record( $id );

  my $type;
  if ( $record ) {
    # get record-type
    
    if ( ref $record eq 'HASH' ) {
      $type = $record -> {type};

    } else {
      $type = $record -> type;
    }

    if ( $type ) {

      # call perl-code for record-type
      my $processing_object = $self -> {config} {record_types} { $type };
      
      if ( not defined $processing_object ) {
        log_error "no processing configured for record '$id', " 
          . "type '$type' (deleting)";

      } else {
    
        my $code = $processing_object -> {'delete-process-ref'};
        
        if ( $code ) { 
          debug "try execute delete-process-ref";
          eval { &$code ( $self, $record );  };
        
          if ( $@ ) { 
            log_warn "delete-process-ref: {" . 
              $processing_object->{'delete-process-text'} . "}";
            $self -> logerr( "problem while deleting record $id: $@" );
            #        critical "an error while running the deleting code: $@";
          }
        }
      }
    }

  }
    

  # delete all relations for record
  my $relations  = $self -> {relations};
  my $res = $relations -> remove ( [undef, undef, undef, $id ] );
 
  # delete the object from the ObjectDB
  my $r = ARDB::ObjectDB::delete_record( $id );

  $self -> log( "deleted record $id ", 
                ( $type ? "of type $type " : "" ), 
                "successfully" );
  return 'ok';
}



# retrieve a record from object storage
sub get_record {
  my $self = shift;
  my $id   = shift;
#  my $object_db_file = $self->{object_db_file} ;
  
  return ARDB::ObjectDB::retrieve_record( $id );
}


###################################################################################
###  sub  G E T   U N F O L D E D    R E C O R D 
###################################################################################

sub get_unfolded_record {
  # takes id and (optionally) view

  my $self = shift;
  my $id   = shift;
  my $view = shift || 'default';

  my $relation_types = $self -> {'config'} -> {'relation_types'};
  assert( $relation_types );

  my $record = $self -> get_record( $id );
  
  critical "cannot retrieve record by '$id' indentifier"
   unless ( $record );

  my $relations = $self -> {relations};


  debug( "going to check relationships for '$id'" );

  my @fw_rel = $relations -> fetch ( [$id, undef, undef, undef] );
  my @bw_rel = $relations -> fetch ( [undef, undef, $id, undef] );

  debug "found ".scalar @fw_rel." forward and ".scalar @bw_rel." backward relations";

  foreach my $relation ( @fw_rel, @bw_rel ) {
    
    my $relation_type;
    my $relation_target;
    my $direction;
    
    my $relation_name   = $relation->[1];
    my $relation_source = $relation->[3];
    
    if    ($relation -> [0] eq $id)  {
      $relation_target = $relation->[2];
      $direction = 'forward';
      $relation_type   = $relation_types -> {$relation_name} ;
      
      debug "found '$direction' relation named '$relation_name'";

    } elsif ($relation -> [2] eq $id) {
      $relation_target = $relation->[0];
      $direction = 'backward';
      
      my $forw_relation_type = $relation_types -> {$relation_name} ;
      my $relation_name   = $forw_relation_type->reverse_type;
      $relation_type   = $relation_types -> {$relation_name} ;
      
      debug "found $direction relation named '$relation_name'";
    }
    
    if ( not defined $relation_type ) {
      log_warn "'$relation_name' not described in configuration; next relation";
      next;
    }
       
    my $retrieve = $relation_type -> retrieve_list ( $view ) ;
    
    
    my $result = {};

    debug "with '$view' view associated '$retrieve->[0]'";

    if ( $retrieve -> [0] eq 'record' ) {
      ### XXX record now replaces 'template' in configuration.xml
      ### need to propagate this change throughout
      $result = $self -> get_record ( $relation_target ) ;

    } elsif ( $retrieve -> [0] eq 'nothing' ) {
     
    } elsif ( $retrieve -> [0] eq 'ID' ) {
      $result = $relation_target ;

    } else {
      my $referred_record = $self -> get_record ( $relation_target );
      
      foreach ( @$retrieve ) {
        my $name_to_store = $_;
        
        if ( not defined $referred_record ) {
          log_error "can't get record '$relation_target'";
          $result = $relation_target;
          last;
        }
        
        my ( $spec, @values );
        
        if ( /(.+):(.+)/ ) {
          $name_to_store = $1;
          $spec = $2;

        } else {
          $spec = $_;
        }
        
        # XXX is this safe? -- Should be pretty safe if configuration is
        # reasonably careful.
        my $val = $referred_record -> get_value( $spec ); 
        $result -> {$name_to_store} = [ $val ];
      }
    }
    
    if ( defined $result ) {
      debug "adding a relationship '$relation_name' -> '$result'";
      $record -> add_relationship( $relation_name, $result );
    }
  }
  
  debug "relations added";
  
  return $record;
}


sub logerr { 
  my $self    = shift;
  my $message = shift;
  $self -> log( "error: " . $message );
}

sub log {
  my $self    = shift;
  my $file    = $self->{log_file};

  my $timestring = scalar localtime;

  if ( not defined $file ) {
    print @_, "\n";    

  } else { 

    if ( open  LOG, ">>$file" ) {
      print LOG "[", $timestring, "] ", @_, "\n";
      close LOG ;
      
      print "\n[", $timestring, "] ", @_, "\n"
        if $self->{log_printout};
    }
  }
}


package ARDB::Configuration;

###  Accessor-methods, moved here from ARDB::Configuration module

sub mapping {
  my $self     = shift;
  my $map_name = shift || return undef;
  
  return $self -> {mappings} -> {$map_name};
}


sub table {
  my $self = shift;
  my $table_name = shift;

  return $self -> {tables} -> {$table_name};
}

sub relation_type {
  my $self = shift;
  my $relation = shift;

  return $self -> {relation_types} -> {$relation};
}






1;

################################################################################

