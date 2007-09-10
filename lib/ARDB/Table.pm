package ARDB::Table

use strict;
use warnings;

our $VERSION = '0.01';

use Carp::Assert;


# constructor

sub new { 
  my $class      = shift;
  my $table_name = shift;
 
  my $self = {
    name     => $table_name,
    create_statement_body => '',
    realname => $table_name,
    
    ##################################
    ### obsolete, but still using: ###
    ##################################
    fields   => {},
    fields_list => [],
    
  };
    
  bless $self, $class;
  return $self;
}


#
# The charset and collation are utf-8.
# This is a mysql snippet that sets these, with blanks!
# 
my $char_coll=" character set utf8 collate utf8_general_ci ";

sub realname { $_[0]->{realname}; }


sub add_field {
  my $self   = shift;
  my $name   = shift;
  my $type   = shift;

  my $need_char_col='';
  my @charfields=('char','varchar','text');


  $self -> {fields} -> {$name} = $type;
  push @{ $self->{fields_list} }, $name;

  $self -> {create_statement_body} .= "$name $type,\n";
  #
  # if the type accepts a collation, add this as well
  # 
  foreach my $field_that_uses_chars (@charfields) {
    if($type=~m|$field_that_uses_chars\s*\(|i) {
      $self -> {create_statement_body} .= $char_coll;
      # char and varchar overlapp
      last;
    }
  }
  $self -> {create_statement_body} .= ",\n";
}

sub create_table_statement {
  my $self = shift;
  my $data = shift;
  $self -> {create_statement_body} .= "$data\n";
}


sub store_values {
  my $self       = shift;
  my $sql_object = shift;
  my $data       = shift;

  my $sql_data;
  my @params = ();
  
  foreach ( sort keys %$data ) {
    my $val = $data -> { $_ };

    next unless $val;

    $sql_data .= " $_=?, ";
    push @params, $val;
  }

  $sql_data =~ s/(.*), *$/$1/;

  my $name = $self->{realname};
  #print 'insert into '. $name . ' set ' . $sql_data;
  $sql_object -> prepare ( 'insert into '. $name . ' set ' . $sql_data );
  $sql_object -> execute ( @params );
}



sub perform_create {
  my $self       = shift;
  my $sql_object = shift;
  $self -> {create_statement_body} =~ s/\s*,\s*$//;
  my $creation_params = $self -> {create_statement_body} ;
  my $table_name = $self -> {realname} ;
  $sql_object -> prepare ( "CREATE TABLE $table_name $char_coll ( $creation_params )" );
  my $r = $sql_object -> execute;
  if ( $r ) { return undef;
  } else {
    return $sql_object -> error;
  }
}


sub perform_delete {
  my $self       = shift;
  my $sql_object = shift;
  my $table_name = $self -> {realname};
  $sql_object -> prepare ( "DROP TABLE $table_name" );
  $sql_object -> execute ();
}



sub store_record {
  my $self   = shift;
  my $record = shift;
  my $sql    = shift;
  
  my $table_name = $self -> {realname};

  my @fields;
  my @values;
  while ( my ($field, $value) = each %$record ) {
#    assert( $field !~ m/\-/ , "field name contains a dash! ($field)" );
    push @fields, $field;
    push @values, $value;
  }

  my $statement = "REPLACE $table_name SET " . join ', ', grep {$_ .= '=?'} @fields;
  $sql -> prepare ( $statement );
  $sql -> execute ( @values );

#  print "Stored to $table_name\n";
  #XXX check for SQL errors
}



sub delete_records {
  my $self   = shift;
  my $column = shift;
  my $id     = shift;
  my $sql    = shift;
  assert( $sql );

  my $table = $self -> {realname};
  $sql -> prepare ( "DELETE FROM $table WHERE $column=?" );
  $sql -> execute ( $id );
}


sub delete_where {
  my $self   = shift;
  my $sql    = shift;
  my $where  = shift;
  my @par    = @_;
  assert( $sql );

  my $table = $self -> {realname};
  $sql -> prepare ( "DELETE FROM $table WHERE $where" );
  $sql -> execute ( @par );
 
}



##################################################################
#              package ARDB::Table::Map
##################################################################


package ARDB::Table::Map;


sub new  { 
  my $class = shift;
  my $name  = shift;
 
  return undef
   unless $name;
  
  my $self =  {
    name     => $name,
    fields   => {},
  };
    
  bless $self, $class;
    
  return $self;
}


sub name {
  my $self = shift;
  return $self -> {name};
}

sub fields {
  my $self = shift;
  return $self -> {fields};
}


use Carp qw( &confess );

sub add_field {
  my $self = shift;
  my $name = shift || confess;
  my $list = shift || confess;

  # changes by Iku on 2003-05-22 19:22
  if ( $list =~ /::/ ) {
    $self ->{fields} ->{$name} = $list;

  } else {
    $self ->{fields} ->{$name} = [ split /\s*,\s*/, $list ] ;
  }
}


sub add_mapping {
  my $self = shift;
  my $map  = shift;

  my $fields   = $self ->{fields};
  my $mapfields = $map ->{fields};

  %$fields = ( %$fields, %$mapfields );
}


sub produce_record {
  my $self = shift;
  my $record = shift;
  my $fields = $self -> {fields};
  my $result = {};

  foreach my $field_name ( sort keys %$fields ) {
     my $content = $fields->{$field_name}; 

     if ( ref $content eq 'ARRAY' ) {
       $result -> {$field_name} =
         join ' ', $record ->get_value( @$content );

     } else {
       no strict;
       my @val = &{$content}( $record ) ;
       if( scalar @val ) {
         $result -> {$field_name} = join( ' ', @val );
       } else {
         $result -> {$field_name} = '';
       } 
     }
   }
  
  return $result;
}


1;

__END__


=pod

=head1 NAME

ARDB::Table - class to hold configuration data for SQL DB tables 

=head1 SYNOPSIS

  use ARDB::Table;

  # ARDB::Table::Map:

<field-attribute-mapping map-name="documents">
        <field-associations
                title="title"
                subject="title,abstract,keywords"
                authors="author/name"
                authors_emails="author/email"
                keywords="keywords"
                abstract="abstract"
                creation_date="creation-date"
                handle="handle"
                special_field="My::ARDB::special_field_filter" />

</field-attribute-mapping>


perl code:


my $template = shift;

my $record = {};

$record->{title} = $template->{'title'}[0];
$record->{subject} = $template->{'title'}[0] .
                        ' '. $template->{'abstract'}[0] . 
                        ' '. $template->{'keywords'}[0] ;

$record->{author_emails} = ... $template->{author/email} ???;

$record->{special_field} = &My::ARDB::special_field_filter( $template );

return $record;




# ARDB::Table:

sub store_record {
  my $self       = shift;
  my $sql_helper = shift;
  my $record     = shift;


  ### issue an SQL statement 
  ### which will insert the record into the table...
  ### and return success status


}




=head1 DESCRIPTION

ARDB::Configuration will create objects of this class.  An object will
be responsible for holding configuration data for an SQL table.  ARDB 
will manage those SQL tables. 

Each Table has a name, a list of field specifications and additional 
"raw SQL" lines for CREATE TABLE statements.  

Each field specification will have a field name (all field names must be unique), 
and an SQL type definition for that field.

May be, this class will also implement more than just storing configuration data.  
Later (!) it might do much more: perform table creation, deletion, and so on.

=head2 EXPORT

None by default.


=head1 AUTHOR

Ivan Baktcheev and Ivan Kurmanov

=head1 SEE ALSO

L<ARDB>, L<ARDB::Configuration>

=cut


