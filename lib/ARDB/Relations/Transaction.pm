package ARDB::Relations::Transaction;

use strict;
use Carp::Assert;

use ARDB::Common;

use Data::Dumper;

sub new {
  my $class     = shift;
  my $id    = shift;
  my $relations = shift;
  
  my $self = 
    {
     relations_object => $relations,
     id               => $id,
     to_be_deleted    => {},
     to_be_inserted   => {},
     relation_records => [],
     new_relations    => {},
    };
  
  bless $self, $class;
  return $self;
}

sub fetch {
  my $self = shift;
  return $self ->{relations_object} -> fetch( @_ );
}

sub prepare {
  my $self = shift;

  my $id   = $self->{id};

  debug "search relations for '$id' id";
  
  my @relation_records;

  @relation_records  = $self -> {relations_object} -> fetch ( [undef, undef, undef, $self -> {'id'} ] );

  $self-> {relation_records} = \@relation_records;

  foreach ( @relation_records )
   {
    my ($subject, $relation, $object, $source) = @$_;

    assert( $subject );
    assert( $relation );
    assert( $object );
    assert( $source );
    
    my $packed_relation =
       pack_relation ( $subject, $relation, $object, $source);
     
    debug "found relation: $subject -> $object / $relation from $source";
    
    $self -> {to_be_deleted} -> {$packed_relation} = 1;


    # 
   }
}


sub store {
  my $self     = shift;

  foreach ( @_ ) {
    my ($subject, $relation, $object, $source) = @$_;

    assert( $subject );
    assert( $relation );
    assert( $object );
    assert( $source );
    
    my $packed_relation =
     pack_relation ( $subject, $relation, $object, $source);

    if ( $self -> {to_be_deleted} -> {$packed_relation} ) {
      delete $self -> {to_be_deleted} -> {$packed_relation};
      debug "relation '$relation' from '$source' found in 'relations' table, no changes";

    } else {
      $self -> {to_be_inserted} -> {$packed_relation} = 1;
      debug "relation '$relation' from '$source' inserted to 'relations' table after commit";
    } 
  }  
     
}

sub pack_relation {

 my ($subject, $relation, $object, $source) = @_;
 
 my @len = ( length ($subject),
             length ($relation),
             length ($object),
             length ($source) );
                   
 return pack "S4 a$len[0] a$len[1] a$len[2] a$len[3]", 
             @len, 
             $subject, $relation, $object, $source;
}

sub unpack_relation {
  my $packed = shift;
  my @len = unpack "S4 a*", $packed;
  $packed = pop @len;

#  my ($subject, $relation, $object, $source) = 
  unpack "a$len[0] a$len[1] a$len[2] a$len[3]", $packed;
}

sub commit {
  my $self = shift;
  
  my $old_relations = $self -> {to_be_deleted};
  my $new_relations = $self -> {to_be_inserted};
  my $relations_object = $self -> {relations_object};
  

  assert( $old_relations and $new_relations and $relations_object );
  assert( ref $old_relations eq 'HASH' );
  assert( ref $new_relations eq 'HASH' );

  debug "commit changes in 'relations' table";
  
  foreach ( keys %$old_relations )
   {
    my @relation_fields = unpack_relation ($_);
    
    debug "removing '$relation_fields[1]' relation";
    # my ($subject, $relation, $object, $source) = @relation_fields;
    $relations_object -> remove ( [ @relation_fields] );
   }
  
  foreach ( keys %$new_relations )
   {
    my @relation_fields = unpack_relation ($_);
    
    debug "storing '$relation_fields[1]' relation";
    # my ($subject, $relation, $object, $source) = @relation_fields;
    $relations_object -> store ( [ @relation_fields ] );
   }
}

1;              

=pod

=head1 NAME

ARDB::Relations::Transaction - class to process set of relations

=head1 SYNOPSIS

  use ARDB::Relations;
  use ARDB::Relations::Transaction;
  use sql_helper;
 
  my $sql_object = new sql_helper ( 'HoPEc', $user, $pass );
  my $table_name = 'relations';

  my $relations = new ARDB::Relations ( $sql_object, $table_name );

  my $transaction = new ARDB::Relations::Transaction ( $handle, $relations );
  
  $transaction -> prepare;
  $transaction -> store ( $subject, $relation, $object, $source );
  $transaction -> commit;

=head1 DESCRIPTION

=head1 EXPORT

None by default.

=head1 AUTHOR

Ivan Baktcheev and Ivan Kurmanov

=head1 SEE ALSO

L<ARDB>, L<ARDB::Relations>

=cut


