package ARDB::Common;

use strict;

require Exporter;

use Carp::Assert;


use vars qw( @ISA @EXPORT $LOGFILENAME );

@ISA = qw( Exporter );

@EXPORT = qw ( &log_error &log_warn &log_msg &log_info
               &critical &debug &eval_wrap );

my $eval_count = 0;

sub log_info;

sub eval_wrap {
  my $code = shift;
  my $name = shift;

  my ($package, $filename, $line, $subroutine, $hasargs,
    $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
  ($package, $filename, $line) = caller;

  log_info "evaling $name no. $eval_count: '$code' at $subroutine($line)";

  $eval_count ++;

  eval $code;
}


sub debug {

  return
    unless $ARDB::DEBUG;

  my $message   = shift;
  
  my ($package, $filename, $line, $subroutine, $hasargs,
     $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
  ($package, $filename, $line) = caller;
  
  print "[$subroutine($line)] $message\n";
 
}

sub log_error {
  my $message  = shift;
  log_msg ( 'error', $message );
}

sub log_info {
  my $message  = shift;
  log_msg ( 'info', $message );
}

sub log_warn {
  my $message  = shift;
  log_msg ( 'warn', $message );
}


sub log_msg {
  my $type    = shift;
  my $message = shift;

  my $log_file = $ARDB::Common::LOGFILENAME;

  my $timestring = scalar localtime;

  if ( not defined $log_file ) {
#    print "[", $timestring, "] [$type] $message\n";    
    print "[$type] $message\n";    
  } else { 
    
    open  LOG, ">> $log_file" ;
    print LOG "[", $timestring, "] [$type] $message\n";
    
    print "\n[", $timestring, "] [$type] $message\n"
      if $ARDB::LOGPRINT;
    close LOG ;
  }
}


sub critical {
  my $message  = join '', @_ ;
  my $log_file = $ARDB::Common::LOGFILENAME;

  if ( defined $log_file ) {
    open  LOG, ">> $log_file" ;
    print LOG "[", scalar localtime, "] [critical] $message\n";
    close LOG ;  
  } 

  my ($package, $filename, $line, $subroutine, $hasargs,
    $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
  ($package, $filename, $line) = caller;
  
  die "[$subroutine($line)] [critical] $message\n"
}



1;



# Below is stub documentation for the module

# object oriented

sub info {
  my $class = shift;
  &log_info ( join '', @_ )
}

sub error {
  my $class = shift;
  &log_error ( join '', @_ )
}

sub warning {
  my $class = shift;
  &log_warn ( join '', @_ )
}

=head1 NAME

ARDB::Common - common functions for ardb work 

=head1 SYNOPSIS

  use ARDB::Common;
  use Test;

  # below text of test file
  
  log_error ( 'test, non-critical' );
  
  log_warn  ( 'test' );
  
  log_info  ( 'test' );
  
  #######################################################
  
  my $template =
   {
    'template-type' => ['ReDIF-Person 1.0'],
    'handle' => ['RePEc:per:1933-03-03:EDIK_BURILKIN'],
    'workplace-institution' => [ 'RePEc:edi:someuni' ],
   };


  my @vals = ARDB::Common::get_values_by_attribute_specification ( $template, ['workplace-institution'] );

  ok( scalar @vals == 1 );

  ok( $vals[0] eq 'RePEc:edi:someuni' );


  my $rule_p = new ARDB::Rule ( 'p', [ 'ReDIF-Paper 1.0'], ['author/handle'] );

  my $paper_template =
   {
    'template-type' => ['ReDIF-Paper 1.0'],
    'handle'        => ['RePEc:wop:aarhec:some_asdf'],
    'creation-date' => [ '1999-08-12' ],
    'author' => 
    [
     { name => [ 'Edik Burilkin' ],
       handle => [ 'RePEc:per:1933-03-03:EDIK_BURILKIN'],
       workplace =>
       [
        {
         name => ['Kurchatov Institut'],
         handle => [ 'RePEc:edi:kurchru' ],
        },
        {
         name => ['Berkley'],
         handle => ['RePEc:edi:berklus'],
        }
       ]
       },

     { name => [ 'Burik Doilkin' ],
       handle => [ 'RePEc:per:1933-03-03:BURIK_DOILKIN'],
       workplace =>
       [
        {
         name => ['RTI'],
         handle => ['RePEc:edi:mrti_by'],
        }
       ]
       },
    ]

   };

  @vals = ARDB::Common::get_values_by_attribute_specification ( $paper_template, ['author/handle'] );

  ok( scalar @vals == 2 );

  ok( $vals[0] eq 'RePEc:per:1933-03-03:EDIK_BURILKIN' );

  ok( $vals[1] eq 'RePEc:per:1933-03-03:BURIK_DOILKIN' );


  @vals = ARDB::Common::get_values_by_attribute_specification ( $paper_template, ['author/work-place/handle'] );

  print '\@vals = ( ', join( ', ',  @vals ), " )\n";

  ok( scalar @vals == 0 );

  @vals = ARDB::Common::get_values_by_attribute_specification ( $paper_template, ['author/workplace'] );

  print '\@vals = ( ', join( ', ',  @vals ), " )\n";

  ok( scalar @vals == 3 );
  ok(  $vals[0] -> {'handle'} 
   and $vals[1] -> {'handle'} 
   and $vals[2] -> {'handle'} );
  
  ####################################################


=head1 DESCRIPTION

=head2 SUBS

=over 4

=item get_values_by_attribute_specification


@values = get_values_by_attribute_specification ( $template, [$attr_spec_1, $attr_spec_2, $attr_spec_3] )

gets template and reference to an array of attribute specification

returns array of matching values

how it works?

we have a template tree.  it has several levels.  If we look at it from 
the point of view of roots, first level will be where we have handle 
and template-type attributes;  
      
first we find matching branches of the first level.
      
then we cut those branches, and take a closer look at them.
I mean we check if those branches have next-level branches or the leaves 
which match the specification.


$current will hold an arrayref to the branches we study 

this will step through all the attribute specification parts,
e.g. if attr spec is 'author/handle', this will go through ['author','handle']
e.g. if attr spec is 'author/workplace/handle', this will go 
through ['author', 'workplace', 'handle']

=item log_error log_warn log_info 


log messages in this format: 

[timestamp] [msg_type] message

has two parameters - message and path to log. if path omitted, used 
$ARDB::LocalConfig::local_path

=item critical


log message in this format and dies: 

[timestamp] [critical] message

parameter - message.

=back

=head1 AUTHOR

Ivan Baktcheev, with support from Ivan Kurmanov

=head1 SEE ALSO

L<ARDB>, L<ARDB::Rule>, L<ARDB::RelationType>

=cut
