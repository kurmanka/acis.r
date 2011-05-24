package Common::Data;

## common data handling routines

use strict;
use warnings;
use Storable qw(freeze nfreeze thaw);
use Carp::Assert;

use YAML::XS;
use Data::Dumper;
use JSON::XS;
use Lib32::Decode;


sub inflate {
  my $in=shift;
  my $out;
  ## first try YAML
  $out = eval {
    Load $in;
  };
  if(defined($out)) {
    #  warn "decoding YAML suceeded";
    return $out;
  }
  #warn "decoding YAML failed";
  ## second try JSON
  $out=eval {     
    decode_json($in);
  };
  if(defined($out)) {
    #  warn "decoding JSON suceeded";
    return $out;
  }
  #warn "decoding JSON failed";
  ## third: legacy data of Storable
  $out = eval {
    thaw($in);
  };    
  if(defined($out)) {
    #  warn "thaw suceeded";
    return $out;
  }
  #warn "thaw failed";
  if( $@ ) { 
    # warn "Storage: $@";                                                                                                                  
    #warn "decoding via daemon";
    $out=Lib32::Decode::via_daemon($in);
    #if (not $out ) { 
    #  warn "decode via daemon failed";
    return undef;          
    #}
  }
  return $out;
}


sub deflate {
  my $in=shift;
  my $out; 
  #$out = eval {
  #  encode_json($in);
  #};
  #if(defined($out)) {
  #  warn "encoding JSON suceeded";
  #  return $out;
  #}
  #warn "encoding JSON failed";
  ## if this fails use YAML
  $out=Dump $in;
  if(defined($out)) {
    #warn "encoding YAML suceeded";
    return $out;
  }
  assert($out);
  return undef;
}


1;
