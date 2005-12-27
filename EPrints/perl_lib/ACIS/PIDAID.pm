package ACIS::PIDAID;

use strict;
use vars qw( $CONF );

use Encode;

use sql_helper;


my $fields  = [ qw( id shortid namelast namefull profile_url homepage ) ];
my $columns = join ",", @$fields;
my $rec_columns = "r." . join( ",r.", @$fields );

my $utf8_fields = [ qw( namelast namefull ) ];
my $utf8_fields_hash = {};

foreach ( @$utf8_fields ) {
  $utf8_fields_hash ->{$_} = 1;
}



sub new {
  my $class = shift;
  my $conf = shift || $CONF;

  my $self = bless {}, $class;

  if ( $conf ) {
    foreach ( keys %$conf ) {
      $self ->{$_} = $conf ->{$_};
    }
    if ( not $self->{max_results} ) {
      $self->{max_results} = 15;
    }
  } else { die; }

  my $host;
  my $port;
  my $database;
  my $user;
  my $pass;

  {
    my $c = $self;
    $host     = $c ->{host};
    $port     = $c ->{port};
    $database = $c ->{db};
    $user     = $c ->{user};
    $pass     = $c ->{pass};
  }

  my $sql = sql_helper -> new( $database, $user, $pass, $host, $port ) 
    or die "can't open database connection";

  $self ->{sql} = $sql;

  return $self;
}


# sub DESTROY {
#   my $self = shift;
#   $self ->{sql} = undef;
# }



sub find_by_name {
  my $self = shift;

  my $max_res = $self -> {max_results} + 1;
  
  my $last  = shift || '%';
  my $first = shift || '';

 
  if ( $last =~ /\*$/ ) {
    $last =~ s/\*$/\%/;
  }

  if ( $last eq '%' and $first eq '' ) {
    return "too many";
  }

  my $pattern = "$last, $first%";

  my $sql = $self->{sql};

  $sql -> prepare( 
"select distinct $rec_columns from records as r
INNER JOIN names USING( shortid )
WHERE names.name LIKE ? LIMIT $max_res" 
                 );

  my $r = $sql -> execute( $pattern );

  if ( $r 
       and $r->rows == $max_res ) {
    return "too many";
  }

  return decode_results( $r );
}


use Digest::MD5;

sub find_by_email {
  my $self = shift;

  my $max_res = $self -> {max_results} + 1;
  
  my $email  = shift || die;
  my $digest = Digest::MD5::md5( lc $email );
  
  my $sql = $self->{sql};

  $sql -> prepare( 
"select $columns from records WHERE emailmd5 = ? LIMIT $max_res" 
                 );

  my $r = $sql -> execute( $digest );

  if ( $r 
       and $r->rows == $max_res ) {
    return "too many";
  }

  return decode_results( $r );
}


sub find_by_shortid {
  my $self = shift;

  my $max_res = $self -> {max_results} + 1;
  
  my $shortid = shift || die;

  my $sql = $self->{sql};

  $sql -> prepare( 
"select $columns from records WHERE shortid=? LIMIT $max_res" 
                 );

  my $r = $sql -> execute( $shortid );

  if ( $r 
       and $r->rows == $max_res ) {
    return "too many";
  }

  return decode_results( $r );
}








sub decode_results {
  my $r    = shift;  # sql_result object, returned by sql_helper
  my $list = [];     # return list 

  if ( $r and $r->{row} ) {
    while ( $r->{row} ) {
      my $row = $r->{row};
      
      # go through each field
      foreach ( keys %$row ) {
        my $v = $row->{$_};

        if ( $utf8_fields_hash->{$_} ) {
          # decode UTF-8 from bytes
          $row->{$_} = Encode::decode_utf8( $v );
        }

        # use value of the namelast field to find
        # family name and given name
        if ( $_ eq 'namelast' ) {
          $v = Encode::decode_utf8( $v );
          my ( $f, $g ) = split( ', ', $v, 2);
          
          $row ->{familyname} = $f;
          $row ->{givenname}  = $g;
        }
      }

      # save the record
      push @$list, $row;
      $r->next;
    }
  }

  return $list;

}


1;

