# -*- Mode:perl -*-

use strict;

# $homedir will be defined

use ARDB::Local;

use Getopt::Std;

use vars qw( %options );

getopts( "dFh", \%options );

my $replace_flag;


if ( $options{'h'} ) { # help
  print <<ENDEND;
This is ARDB's create tables tool.

Usage: $0 [options] 

It will create the necessary tables, as specified 
in the ARDB configuration.

Options: 

  -d debug mode
  -F remove tables before trying to create them
ENDEND
 exit;
}

if ( $options{'d'} ) {   # debug
  $ARDB::DEBUG = 1;
}

if ( $options{'F'} ) { # remove tables before creation
  $replace_flag = 1;
}



my $ardb_object = new ARDB ( $homedir );

my $sql_object = $ardb_object -> {sql_object};

my $relations_object = $ardb_object -> {relations};

$relations_object -> delete_table  if ( $replace_flag );
$relations_object -> create_table;

my @created;
foreach my $table_ref ( values %{ $ardb_object -> {config} -> {tables} } )  {
  my $name = $table_ref -> {name};
  $table_ref -> perform_delete ( $sql_object )
    if ( $replace_flag );
  my $res = $table_ref -> perform_create ( $sql_object );
  if ( $res ) {
  } else {
    push @created, $name;
  }

}

if ( scalar @created ) {
  print "Created tables: ", join( " ", @created ), "\n";
}

