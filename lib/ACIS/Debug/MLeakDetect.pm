package ACIS::Debug::MLeakDetect;

use strict;
use warnings;
use PadWalker;
use Devel::Size;
use Data::Structure::Util qw(has_circular_ref);

use Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw( my_vars_report );

sub my_vars_report {
  my $ref_of_mys = PadWalker::peek_my(1);
  my %var_sizes;
  my %circular;
  my @sorted_vars;
  
  # Foreach my variable in the caller stack, get "name -> size" as told by Devel::Size::total_size
  foreach my $var_name ( keys(%$ref_of_mys) ) {
    my $v = $ref_of_mys->{$var_name};
    $var_sizes{$var_name} = Devel::Size::total_size($v);
    $circular{$var_name} = ref($v) eq 'REF' ? " $$v" : " \*$v";
    my $c = has_circular_ref( $v );
    if ( $c ) {
      $circular{$var_name} .= " / circular:$c";
    }
  }
  @sorted_vars = map { "$_ -> $var_sizes{$_}$circular{$_}" } sort { $var_sizes{$b} <=> $var_sizes{$a} } (keys(%var_sizes));
  
  my $o = '';
  if ( caller(1) ) {
    $o .= join ' ', '-' x 3,  scalar localtime(), 'at', @{[caller(1)]}[3], "(@{[caller(1)]}[2])", '-' x 3, "\n";
  } else {
    $o .=  join ' ', '-' x 10, scalar localtime(), '-' x 10, "\n";
  }
  
  $o .= join("\n", @sorted_vars);
  $o .= "\n";
  $o .= '-' x 30 . "\n";

  return $o;
}


sub testme {
  my $aa = [];
  $aa->[0] = { a => 'aa' };
  $aa->[1] = '0' x 500;
  my $fffffffffffffff= "f" x 125;
  my @o;

  @o = [ $aa, [\@o], {} ];

  print '$aa = ', $aa, "\n";

  my %hash = ( o => 'ooops!', a => 'aha!' );
  my $l = \%hash;

  my $v = { g=> [] };
  my $h = { vg=> $v->{g} };
  $v ->{h} = $h;

  my $f = sub { 
    my $c = {{}=>[]};
    print my_vars_report();
  };
  
  &$f();
  1;
}

1;
