package ACIS::Web::SysProfile;


use strict;
use warnings;

use Carp::Assert;

use Exporter;
use vars qw( @ISA @EXPORT @EXPORT_OK $APP );

@ISA =   qw( Exporter );
@EXPORT    = qw( get_sysprof_value 
                 get_sysprof_values
                 get_all_sysprof_values
                 put_sysprof_value 
                 del_sysprof_value );
@EXPORT_OK = qw( rename_sysprof_id );

*APP = *Web::App::APP;


sub get_sysprof_value {
  my $id    = shift;
  my $param = shift;
  my $value;

  assert( $id and $param );
  assert( $APP );
  my $sql = $APP -> sql_object;

  $sql -> prepare( "SELECT data FROM sysprof WHERE id = ? AND param = ?" );
  my $r = $sql -> execute( $id, $param );

  if ( $r and $r -> {row} ) {
    $value = $r -> {row} -> {data};
    ###  XX UTF8 decoding?
  }
  return $value;
}


sub get_all_sysprof_values {
  my $id    = shift;
  my $res = {};

  assert( $id );
  assert( $APP );
  my $sql = $APP -> sql_object;

  $sql -> prepare( "SELECT param,data FROM sysprof WHERE id = ?" );
  my $r = $sql -> execute( $id );

  if ( $r and $r -> {row} ) {
    my $row;
    while ( $row = $r -> {row} ) {
      my $pa = $row -> {param};
      my $va = $row -> {data};

      $res -> {$pa} = $va;
      ###  XX UTF8 decoding?
    }
  }
  return $res;
}


sub get_sysprof_values {
  my $id    = shift;
  my $param = shift;
  my $res = {};

  assert( $id );
  assert( $APP );
  my $sql = $APP -> sql_object;

  $sql -> prepare( "SELECT param,data FROM sysprof WHERE id = ? AND param like ?" );
  my $r = $sql -> execute( $id, "$param%" );

  if ( $r and $r -> {row} ) {
    my $row;
    while ( $row = $r -> {row} ) {
      my $pa = $row -> {param};
      my $va = $row -> {data};

      $res -> {$pa} = $va;
      ###  XX UTF8 decoding?
      $r->next;
    }
  }
  return $res;
}



sub put_sysprof_value {
  my $id    = shift;
  my $param = shift;
  my $value = shift;

  assert( $id and $param );
  assert( $APP );

  my $sql = $APP -> sql_object;

#  warn "Saving $param = $value for $id";

  $sql -> prepare( "REPLACE INTO sysprof VALUES ( ?, ?, ? )" );
  $sql -> execute( $id, $param, $value );
  
}



sub del_sysprof_value {
  my $id    = shift;
  my $param = shift;

  assert( $id  );
  assert( $APP );

  my $sql = $APP -> sql_object;
  $sql -> prepare( "DELETE FROM sysprof WHERE id = ?" . 
                   ($param)? " AND param = ?" : "" );

  if ( $param ) {
    $sql -> execute( $id, $param );
  } else {
    $sql -> execute( $id );
  }
}




sub rename_sysprof_id {
  my $oldid = shift;
  my $newid = shift;

  assert( $oldid  );
  assert( $newid  );
  assert( $APP );

  my $sql = $APP -> sql_object;
  $sql -> prepare( "UPDATE sysprof SET id=? WHERE id=?" );
  $sql -> execute( $newid, $oldid );
}





1;
