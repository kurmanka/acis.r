package Web::App::Common;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Some basic tools for other Web::App modules.
#
#
#  Copyright (C) 2003 Ivan Baktcheev, Ivan Kurmanov for ACIS project,
#  http://acis.openlib.org/
#
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License, version 2, as
#  published by the Free Software Foundation.
# 
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#  ---
#  $Id$
#  ---



use strict;

require Exporter;

use Carp;
use Carp::Assert;

use vars qw( @ISA @EXPORT @EXPORT_OK $LOGFILENAME $LOGCONTENTS $LOGPRINT );

@ISA = qw( Exporter );

@EXPORT    = qw( debug complain generate_id force_dir clear_undefined );
@EXPORT_OK = qw( date_now debug_as_is convert_date_to_ISO );


$LOGCONTENTS = '';


sub clear_undefined ($);


###  enable debugging mode

$Web::App::DEBUG            ||= $ENV{WEBAPPDEBUG};
$Web::App::DEBUGLOGFILE     ||= $ENV{WEBAPPDEBUGLOGFILE};
$Web::App::DEBUGIMMEDIATELY ||= $ENV{WEBAPPDEBUGIMM};
# may be set to 1 in Web::App, depending on config: 
$Web::App::DEBUGWITHTIME    ||= $ENV{WEBAPPDEBUGWITHTIME};

foreach ( @::ARGV ) {
  if ( m/^--debug$/ ) {
    $Web::App::DEBUGIMMEDIATELY = "on";
    $Web::App::DEBUG = "on"; 
    undef $_;
  }
}
clear_undefined( \@::ARGV );



###
### this is for CGI::Carp's set_message, see Web::App
###
sub critical_message {
  my $msg   = shift;

  my @lines = split /\s*\n/, $msg;

  if ( scalar @lines ) {
    $msg = shift @lines;
  }

  if ( $ENV{REMOTE_ADDR} ) {

    print "<h1>Internal Error</h1>".
      "<p>Problem: $msg</p>\n";

    if ( scalar @lines ) {
      print "<ul>\n";
      foreach ( @lines ) {
        print "<li>$_</li>\n";
      }
      print "</ul>\n";
    }

  } else {

    print "Internal Error: $msg\n",
      join ( "\n", @lines ),
        "\n";
  }
}

use Bytes::Random::Secure qw(random_bytes_hex); 

sub generate_id {
  return random_bytes_hex( 16 );
}


sub complain (@) {
  carp @_;
  debug( @_ );
  $Web::App::APP->errlog( @_ );
}

use vars qw( $dumped_debug );
$dumped_debug = 0;



sub debug {
  clear_undefined \@_;
  my $message = join '', @_;

  my $subroutine = (caller(1))[3];
  my $line       = (caller)[2];

  $message = "[$subroutine($line)] $message\n";

  if ($Web::App::DEBUGWITHTIME) {
    $message = localtime() . ' ' . $message;
  }

  if ( $Web::App::DEBUGLOGFILE
       and open (DEBUGLOG, ">>:utf8", $Web::App::DEBUGLOGFILE)
     ) {
      print DEBUGLOG $message;
      close DEBUGLOG;
  }

  my $line_sep = ($ENV{REMOTE_ADDR}) ? "<br/>\n" : "";
  print $message, $line_sep
    if $Web::App::DEBUGIMMEDIATELY;

  $LOGCONTENTS .= $message;

}

sub dump_debug {
  if ( $Web::App::DEBUGLOGFILE
       and open DEBUGLOG, ">>$Web::App::DEBUGLOGFILE" ) {
    print DEBUGLOG "\n * ", scalar( localtime ), " debug log dump\n";
    print DEBUGLOG $LOGCONTENTS, "\n";
    print DEBUGLOG "------\n";
    close DEBUGLOG;
  }
}


if (0) {
  *debug= sub {
    my $message = join '', @_;
    
    my ($package, $filename, $line, $subroutine, $hasargs,
        $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);

    ($package, $filename, $line) = caller;

    if ( $Web::App::DEBUGLOGFILE
         and open DEBUGLOG, ">>$Web::App::DEBUGLOGFILE" ) {
      print DEBUGLOG "[$subroutine($line)] $message\n";
      close DEBUGLOG;
    }
    $LOGCONTENTS .= "[$subroutine($line)] $message\n";
  };
}
                                   

#$::SIG{USR1} = \&dump_debug;



sub debug_as_is {
  return unless $Web::App::DEBUG;

  my $message   = join '', @_;

  print "> $message\n" if $Web::App::DEBUGIMMEDIATELY;
  $LOGCONTENTS .= "> $message\n";
}





sub force_dir {
  my $base = shift;
  my $dir  = shift;

  $base =~ s+/$++g;
  $dir  =~ s+^/|/$++g;
  
  my @dirs = split '/', $dir;
  
  foreach ( @dirs ) {
    $base .= '/' . $_;
    next if -d $base;
    mkdir $base or die "can't create '$base' dir";
  }
  return 1;
}


### ISO-8601, see man 3 strftime
sub date_now {
  require POSIX;
  my $now = POSIX::strftime( "%F %H:%M:%S %z", localtime );
  return $now;
}

sub convert_date_to_ISO {
  my $date_in = shift;
  require Date::Manip;
  my $date = Date::Manip::ParseDate( $date_in );
  my $res  = Date::Manip::UnixDate ( $date, "%Y-%m-%d %H:%M:%S %z" );
  return $res;
}


####
####  will remove undefined values from an array
####
sub clear_undefined ($) {
  my $ar = $_[0];

  my $cc = 0;
  my $i  = 0;
  while ( $i < scalar @$ar ) {

    my $v = $ar ->[$i];
    if ( not defined $v ) {
      splice @$ar, $i, 1;
      $cc ++;
      next;
    }

    $i ++;
  }
  return $cc;
}


1;

__END__

