package ARDB::Relations;

use strict;
use warnings;
use Carp::Assert;

use sql_helper;

use ARDB::Table;
use ARDB::Common;


sub new { 
  my $class      = shift;
  my $sql_object = shift;
  my $table_name = shift || 'relations';
 
  my $self = 
   {
    sql        => $sql_object,
    table_name => $table_name,
    fields     => 
     [
      ['subject',  ' char (120) NOT NULL '],
      ['relation', ' char (120) NOT NULL '],
      ['object',   ' char (120) NOT NULL '],
      ['source',   ' char (120) NOT NULL ']
     ],
    create_statement => 'primary key ( subject, relation, object, source ),
    index ( source ), index ( object )',
    delete_statement => '',
   };
    
  bless $self, $class;
  return $self;
}

sub create_table {
  my $self = shift;
  
  my $table = new ARDB::Table ( $self -> {table_name} );

  foreach ( @{ $self -> {fields} } ) {
    $table -> add_field ( $_ -> [0], $_ -> [1] );
  }

  $table -> create_table_statement ( $self -> {create_statement} )
    if ($self -> {create_statement});
  return $table -> perform_create ( $self -> {sql} );
}

sub delete_table {
  my $self = shift;

  my $table = new ARDB::Table ( $self -> {table_name} );
  $table -> perform_delete ( $self -> {sql} );
}

sub store {
  my $self     = shift;
  my @relation_refs = @_;

  my $result = 1;

  my $sql = $self -> {sql};
  $sql -> prepare ('replace into '. $self -> {table_name} . ' values ( ?, ?, ?, ? )');

  foreach ( @relation_refs ) {
    assert( $_->[0] );
    assert( $_->[1] );
    assert( $_->[2] );
    assert( $_->[3] );
    $sql -> execute ( @$_ )
      or $result = 0;
  }
  return $result; 
}


sub remove {
  my $self     = shift;
  my $relation = shift;

  my @condition = ('subject = ?', 'relation = ?', 'object = ?', 'source = ?');
  
  my $remains = 3;
  
  for ( my $counter = 0; $counter <= $remains; $counter++ ) {

    if ( not defined ( $relation -> [$counter] ) ) {
      splice ( @$relation, $counter, 1 );
      splice ( @condition, $counter, 1 );
      $remains--;
      $counter--;
    }
  }
 
  if ( scalar @condition )  {
    my $sql = $self -> {sql};
    my $tabname = $self ->{table_name};
   
    my $where_statement = join ' and ', @condition;
    
    my $res = $sql -> do (
              "delete from $tabname where $where_statement", 
                          undef, 
                          @$relation );
    return $res;
  }
  return undef;
}

sub fetch {

  my $self     = shift;
  my $relation = shift;

  my $sql_res;

  my $sql = $self->{sql};
  my $tabname = $self ->{table_name};

  if ( not defined $relation ) {
    $sql -> prepare ( 'select * from '. $tabname );
    $sql_res = $sql -> execute ( );

  } else {
    my @condition_p = ( 'subject = ?', 'relation = ?', 
                        'object = ?',  'source = ?' );

    my @conditions = ();
    my @values     = ();
    my $counter    =  0;
    
    foreach my $v ( @$relation ) {

      if ( defined $v ) {
        push @conditions, $condition_p[$counter];
        push @values, $v;
      }
      $counter ++;
    }

    my $where_statement = join ' and ', @conditions;

    $sql -> prepare_cached
     ( 'select * from '. $tabname . ' where ' . $where_statement );
    $sql_res = $sql -> execute ( @values );
  }
  
  my @result;

  while ( $sql_res and $sql_res -> {row} ) {  
    
    my $subject  = $sql_res -> get ('subject');
    my $relation = $sql_res -> get ('relation');
    my $object   = $sql_res -> get ('object');
    my $source   = $sql_res -> get ('source');

    debug "found '$relation' relation";
    push ( @result, [$subject, $relation, $object, $source] );
    
    $sql_res -> next;
  }

  if ( $sql_res ) {
    $sql_res -> next;
  }

  return @result;
}

1;

=pod

=head1 NAME

ARDB::Relations - class to hold relations between objects in a SQL DB table

=head1 SYNOPSIS

  use ARDB::Relations;
  use sql_helper;
 
  my $sql_object = new sql_helper ('HoPEc', 'root', 'pass');
  my $table_name = 'relations';

  my $relations = new ARDB::Relations ( $sql_object, $table_name );

  $relations -> create_table();

=head1 DESCRIPTION


=head2 EXPORT

None by default.


=head1 AUTHOR

Ivan Bahcheyev and Ivan Kurmanov

=head1 SEE ALSO

L<ARDB>, L<ARDB::Configuration>

=cut

