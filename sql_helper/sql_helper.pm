package sql_helper;
# $Id: sql_helper.pm,v 2.1 2006/03/23 11:07:07 ivan Exp $

use DBI;
# ? just for early detection of DBD::mysql absence
use DBD::mysql; # unportable (sql-wise)


$VERSION = "0.2";

use Exporter;

@ISA = ( 'Exporter' );
@EXPORT_OK = qw( sql_prepare
                 sql_execute
                 sql_do );

#                &get_table_info 
#                &list_tables );


use strict;
use Carp::Assert;

use vars qw( 
 $DB_H $CONNECTED $ERROR $LOG
 %STATEMENTS 
 $QUERY $PARAMS
 $VERBOSE_LOG
 @OBJECTS
);

my $driver = "mysql";
$CONNECTED = 0;

my @DB_HANDLES;

=pod 

=head1 NAME

sql_helper - simple Object oriented interface to SQL (MySQL)

=head1 SYNOPSIS

    ###  set the log filename
    sql_helper -> set_log_filename ( 'sql_helper.log' );

    ###  create the object
    my $sql = sql_helper -> new ( $database, $db_user, $db_pass ); 

    ###  check the object
    if( $sql ) { 
        # connected succesfully

    } else {
        # failed to connect, look to the log file
        die;
    }

    ###  run a simple statement
    $sql -> do ( 'DROP TABLE unnecessary' )
       || warn "failed to drop unnecessary table";

    ###  run a query 
    $sql -> prepare( "SELECT * FROM resources WHERE handle LIKE 'RePEc:per:%' " );
    my $r = $sql -> execute();

    ###  check the result
    while ( $r->{row} ) {  
        ###   ->{row} contains a reference to the field => value hash
        my $record = $r -> {row};

        my ( $title, $handle, $abstract );

        ###   -> get( 'field' ) retrieves the value:
        $title = $r -> get( 'title' );
        
        ###  ... and that is equivalent to:
        $title = $record -> {'title'};

        ###  ...and equivalent to (as you may guess):
        $title = $r -> {row} {title};

        ###  get other fields
        $abstract = $record -> {abstract};
        $handle   = $record -> {handle};

        ###  iterates to the next record in the query's return set
        $r-> next();
    }


    ###  a query with a parameter
    $sql -> prepare( 'select * from author_map where handle = ? ' );
    $r = $sql -> execute( $handle );   

    ###  another one:
    $sql -> prepare( 'select * from person where lname = ? ' );
    ###  the param value is automatically quoted (!):
    $r = $sql -> execute( "O'Brien" );   

=cut

###################################################################
##    Object oriented interface for simple SQL mediation
###################################################################

use sql_result;

use constant LOG_EVERYTHING => 0;


sub log_to {   # used by log method, not for direct usage
  my $file = shift;
  no warnings;
  open LOG, ">>$file" || die "Can't open SQL log: $file";
  print LOG scalar( localtime ) , " ", @_, "\n";
  close LOG;
}





###  constructor

sub new {
  my $class = shift;
  my @par = @_;

  my $opt = {};
  if ( ref $par[0] eq 'HASH' ) {
    $opt = shift @par;
  }
 
  my $self = { %$opt };
    
  bless $self, $class;
    
  my $id = scalar @DB_HANDLES;

  $self ->{id} = $id;
  $self ->connect( @par );

  if ( LOG_EVERYTHING ) {
    $self -> {verbose_log} = 1;
  }

  return( 0 )
    if not $self->{dbh};

  return $self;
}





sub log {
  my $self = shift;
  my $id = $self->{id};

  if ( $self -> {logfile} ) {
    log_to( $self->{logfile}, "[$id] [$$-$0] " , @_ );

  } else {
    put_to_log( "[$id] [$$-$0] " , @_ );
  }
}



###  log file name
sub set_log_filename {  
  my $self = shift;
  my $name = shift;

  assert( $name ); ### XXX
  if ( ref $self ) {
    $self -> {logfile} = $name;

  } else {
    $LOG = $name;
  }
}




sub query_log {
  my $self = shift;

  $self->log ( "query: '$self->{query}'" );
  if ( $self->{qparams} ) {
    $self->log ( "values: '$self->{qparams}'" );
  }
  if ( scalar @_ ) { 
    $self->log ( @_ );
  }
  return 0;  
}


sub connect {
  my $self = shift;

  my $database = shift;
  my $user = shift;
  my $pass = shift;
  my $host = shift;
  my $port = shift;

  my $connect_string = "DBI:$driver:$database";

  if ( defined $host ) {
    $connect_string .= ":$host";
    if( defined $port ) {
      $connect_string .= ":$port";
    }
  }
  
  $self -> {connect_string} = $connect_string;
  $self -> {user} = $user;
  $self -> {pass} = $pass; 
  $self -> {database} = $database;

  return $self -> real_connect;
}


sub real_connect {
  my $self = shift;
  my $user = $self->{user};
  my $pass = $self->{pass};

  my $connect_string = $self->{connect_string};
  my $database       = $self->{database};

  my $dbh;
  
  eval {
    $dbh = DBI -> connect( $connect_string, $user, $pass,
                             {
#                             'RaiseError'=>1,
                              'PrintError'=>0, 
                              'RaiseError'=>1,
#                             'PrintError'=>1 
                             } );
  };
    

  if ( not $@ and $dbh ) {
    $self->{dbh} = $dbh;
    $self->log ( "Connected to a server (db: $database)" );
    
    push @DB_HANDLES, $dbh;
    
  } else {
    $self->log ( 
"Failed attempt to connect to a server ($connect_string, $user, $pass) ($@)" );
    warn $@;
    return undef;
  }
  
  return $dbh;

}

sub reconnect {
  my $self = shift;
  my $user = $self->{user} || die;
  my $pass = $self->{pass} || die;
  my $connect_string = $self->{connect_string} || die;

  my $counter = $self->{reconnected} || 0;
  if ( $counter > 7 ) {
    $self->log( "too many reconnection attempts" );
    die;
  }

  my $dbh = $self -> real_connect;

  if ( $dbh ) {
    $self->log( "reconnected" );
  }
  $self->{reconnected} = ++$counter;
  
  return $dbh;
}


sub query { }


sub do {
  my $self = shift;
  my $dbh = $self->{dbh};
  
  $self->{query}  = join ", ", @_;
  $self->{qparams} = '';

  my $r;
  eval { 
    $r = $dbh->do ( @_ );
  };

  if ( not $r or $@ or $self->{verbose_log} ) {
    $self->query_log ( "do: " , $dbh->errstr() );
  }
  if ( not $r or $@ ) { return undef; }

  $self->{last_sth} = undef;

  return $r;
}


sub prepare {
    my $self = shift;

    $self->{query}  = join ", ", @_;
    $self->{qparams} = '';

  TRY:
    my $dbh = $self->{dbh};
    my $errstr;
    my $r;
    
    eval {
      $r = $dbh->prepare ( @_ );
    };    
    $errstr = $dbh->errstr;
    if ( defined $errstr 
         and $errstr =~ /server has gone away/ ) {
      $self->reconnect;
      goto TRY;
    }
    if ( not $r or $@ 
#        or $VERBOSE_LOG 
       ) {
      $self->query_log ( "prepare result: " , $errstr );
    }
    if ( not $r or $@ ) { return undef; }

    $self->{last_sth} = $r;

    return $r;
}


sub prepare_cached {
    my $self = shift;
    my $dbh = $self->{dbh};

    $self->{query}  = join ", ", @_;
    $self->{qparams} = '';

    my $r;
    eval {
      $r = $dbh->prepare_cached ( @_ )
    };

    if ( not $r or $@ or $self->{verbose_log}  ) {
      $self->query_log ( "prepare cached: " , $dbh->errstr() );
    }
    if ( not $r or $@ ) { return undef; }

    $self->{last_sth} = $r;

    return $r;
}


use constant BENCH => 0;

# use Benchmark;

sub execute {
  my $self = shift;

  my $dbh = $self->{dbh};
  my $sth = $self->{last_sth};

  if ( $sth ) {

    { no warnings;
      $self -> {qparams} = join "', '", @_;
    }

    my $r;
    my $time;
    if ( BENCH ) {
      require Benchmark;
      my $t0 = new Benchmark;
      eval { $r = $sth -> execute( @_ );  };
      my $t1 = new Benchmark;
      my $diff = timediff( $t1, $t0 );
      $time = timestr( $diff );

    } else {
      eval { $r = $sth -> execute( @_ );  };
    }

    my $dbherrstr = $dbh->errstr;
    if ( $dbherrstr and (
                         $dbherrstr =~ /server has gone away/  
                         or $dbherrstr =~ /server has gone away/ 
                         or $dbherrstr =~ /Lost connection to MySQL/i 
                        )
       ) {
      $self->reconnect;
      $self->prepare( $self->{query} );
      return $self->execute( @_ );
    }

    if ( not $r 
         or $@ 
         or $dbherrstr
         or $self->{verbose_log} 
          ) {
      $self->query_log ( "execute res: " , $dbh ->errstr , ($time ? " $time":'') );
    }

    if ( not $r or $@ ) { 
#       $sth -> finish;
      return undef; 
    }
      
    return sql_result -> new( $sth );
      
  } else {
    $self -> log ( "execute without prepare: nothing to do" );
    
  }
  return undef;
}


sub quick_execute {
  my $self = shift;

  my $res  = $self -> execute( @_ );
  if ( $res and exists $res -> {row} ) {
    return $res -> {row};
  }
  return undef;
}



sub DESTROY { 
  my $self = shift;
  my $sth = $self->{last_sth};
  if ( $sth ) { 
    $sth -> finish;
  }
  my $dbh = $self->{dbh};
  if ( $dbh ) {
    $dbh -> disconnect;
  }
}


sub error {
  return $DBI::errstr;
  return $_[0] -> {dbh} -> errstr;
}


sub escape {     # obsolete
  return shift -> {dbh} -> quote ( @_ );
}








###############################################################################
#             P U T    T O    L O G    
###############################################################################


sub put_to_log {   # used by log method, not for direct usage
    if ( $LOG ) {
        no warnings;
        open LOG, ">>$LOG" || die "Can't open SQL log: $LOG";
        print LOG scalar( localtime (time) ) , " ", @_, "\n";
        close LOG;
    } else {
        print STDERR scalar( localtime (time) ) , " ", @_, "\n";
    }
}




###############################################################################
#                S Q L    Q U E R Y    --   S C A L A R    R E S U L T 
###############################################################################

sub sql_query_scalar_result {  # obsolete
    my $q = shift || die;
    my $d = shift || die;

    my ($sth, $res ) = sql_query_execute( $q, $d, @_ );

    my @result = ();

    if( not defined $sth ) {
        return undef;
    } 
    if( not $sth -> rows ) { 
#       $sth -> finish;
        return undef; 
    }

    my $rows = $sth -> rows;
    
    if ( $rows > 1 ) {
        ### strange, because normally you would 
        die "scalar result query returned a table instead";
    }
    
    my @array = $sth -> fetchrow_array;
    if( scalar @array > 1 ) {
        ### strange
        die "scalar result query returned a multiple-value row instead";
    }

#    $sth->finish;
    return $array[0];
}



###############################################################################
#   MYSQL LAST INSERT ID
###############################################################################
sub mysql_last_insert_id {  # obsolete
    return $DB_H->{'mysql_insertid'};
}

###############################################################################


1;

