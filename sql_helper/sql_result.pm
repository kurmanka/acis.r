package sql_result;

use strict;
use DBI;


sub new {
    my $class = shift;
    my $statement = shift;
#    my $encoding = shift; # 2004-03-25 19:26

    my $self = {
        sth   => $statement, 
        error => $statement -> errstr,
        rows  => $statement -> rows  ,
#       encoding => $encoding,
    };
    bless $self, $class;


    if ( $statement 
         and not $statement ->errstr
         and $statement -> {Active} ) {
      $self->{data} = $statement ->fetchall_arrayref( {} );
      $self->{i} = -1;
      $self-> next;
    }
    return $self;
}

require Encode;
sub decode_utf8 {
  my ( $self, @f ) = shift;
  my $d = $self->{data} || die;
  foreach my $r ( @$d ) {
    foreach ( @f ) {
      $r->{$_} = Encode::decode_utf8( $r->{$_} );
    }
  }
  return 1;
}

sub rows {
  my $self = shift;
  return $self->{rows};
}

use Carp qw( confess );

sub row { 
  my $self = shift;
  return $self->{row};
}

sub data { 
  my $self = shift;
  return $self->{data};
}

sub next {
  my $self = shift;
  my $st = $self->{sth} || die;
  my $d  = $self->{data};
  my $i  = ++$self->{i};
  
  undef $self->{row};
  if ( not $d ) { return undef; }

  if ( $#$d == $i ) {
    delete $self->{data};
    undef $self->{i};
  }
  if ( $#$d >= $i ) {
    return $self->{row} = $d->[$i];
  } else {
    return undef;
  }
}

sub next_old {
    my $self = shift;
    my $st = $self->{sth};
    my $row;
    if ( $@ ) {
      confess "err: $@";
    }
    eval {  $row = $st -> fetchrow_hashref();  }; 

    if ( $@ ) {
      if ( $@ =~ m/without execute\(\)/ ) {
        undef $@;
        goto NEXT_GO_ON;
      }

      my $e = $st->errstr;
      confess "err: $@ ($e)";
      $self -> {row} = undef;
      $st -> finish;
      return undef;
    }
  NEXT_GO_ON:
    $self -> {row} = $row;

# 2004-03-25 19:26 
#    if ( $self ->{encoding} ) {
#      my $en = $self ->{encoding};
#      my $k;
#      my $v;
#      while ( ($k, $v) = each %$row ) {
#       $row -> {$k} = &{ 'decode' } ( $en, $v );
#      }
#    }
    return $row;
}


sub get {
  my $self = shift;
  my $field = shift;
  
  my $row = $self->{row};
  return $row->{$field};
}


sub finish {
 shift->{sth} -> finish;
}

sub DESTROY {
  my $s = shift;
  delete $s->{row};
  delete $s->{error};
  delete $s->{rows};
  delete $s->{data};
  if ( $s->{sth} ) {
    $s->{sth} -> finish;
    undef $s->{sth};
  }
}

1;

__END__



###############################################################################
###############################################################################
###############################################################################
###############################################################################
###############################################################################
###############################################################################
