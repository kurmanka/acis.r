package ACIS::APU;

=head1 NAME

ACIS::APU -- Automatic Profile Update

=cut

use strict;
use warnings;
use Carp;
use Carp::Assert;
use Web::App::Common qw( debug );
use sql_helper;


use vars qw( $ACIS );
*ACIS = *ACIS::Web::ACIS;

my $QUEUE_TABLE_NAME = "arpm_queue";
my $apu_too_recent_hours = 24;  # that's what is too recent for
                                # running APU again for a
                                # particular record

my $interactive;
my $logfile;

sub logit (@) {
  if ( not $logfile and $ACIS ) {
    $logfile = $ACIS -> home . "/autoprofileupdate.log";
  }

  if ( $logfile ) {
    open LOG, ">>:utf8", $logfile;
    print LOG scalar localtime(), " [$$] ", @_, "\n";
    close LOG;

  } else {
    warn "can't logit: @_";
  }

  if ( $interactive ) {
    print @_, "\n";
  }
}


# assumes $QUEUE_TABLE_NAME, $ACIS, @queries

my @queries = ( 
    # select explicitly queue-ed records
    qq! SELECT what FROM $QUEUE_TABLE_NAME WHERE status='' 
        ORDER BY class DESC,filed ASC
        LIMIT ? !,

    # select records, which don't yet have a non-null value of
    # last-auto-citations-time for them
    qq! SELECT r.shortid as what, s.data as data
    FROM records as r LEFT JOIN sysprof as s 
       ON s.id = r.shortid  AND 
          s.param = 'last-auto-citations-time'    
    WHERE s.data is NULL
    LIMIT ? !,

    # select records, for which we ran APU most long ago
    qq! SELECT id as what,data FROM sysprof  
        WHERE param='last-autosearch-time' or param='last-auto-citations-time'
        ORDER BY data+1 ASC LIMIT ? !
);

sub prepare_to_process_queue {
  my $size = shift || die;
  my @to_process; # return value
  logit "prepare the process queue: size=$size";

  my $sql = $ACIS -> sql_object || die;
  my $get = ($size < 3) ? 6 : $size * 2;
  my @skipped; 
  my @to_process_logins;
  my @items;
  my $by_lastsearch;
  my $r;

  # first source of the queue items
  my $query = shift( @queries );
  $sql -> prepare( $query );
  $r = $sql -> execute( $get );

  # the main loop
  while ( 1 ) {
    my $item =    $r -> {row} {what};
    my $lastrun = $r -> {row} {data};

    if ( ! $item ) { next; }

    if ( $by_lastsearch ) {
      my $last = $lastrun || die;
      my $now  = time;
      if ( $now - $last <= $apu_too_recent_hours * 60 * 60 ) {
        # are we running too fast?
#       logit "skipping $item";
        push @skipped, $item;
        next;
      }
    }
    
    
    my $login = get_login_from_queue_item( $ACIS, $item );
    if ( $login ) {
      push @items, $item;
      push @to_process, [ $login, $item, $lastrun ];
      push @to_process_logins, $login;

      $get--;
      if ( not $get ) { last; }
      
    } else {
      if ( not $by_lastsearch ) {
        $sql -> prepare_cached( "delete from $QUEUE_TABLE_NAME where what=?" );
      } else {
        $sql -> prepare_cached( "delete from sysprof where id=?" );
      }
      $sql -> execute( $item );
      logit "cleared bogus queue item: $item";
    }
        

  } continue {
    
    if ( not $r -> next ) {
    QUERY:
      if ( scalar @queries ) {
        $query = shift( @queries );
        $sql -> prepare( $query );
        $r = $sql -> execute( $get );
        
        $by_lastsearch = ($query =~ /\sFROM sysprof\s/i );
      } else { last; }

      if ( not $r or !$r->{row} ) { goto QUERY; }
    }  
  }

  logit "to process: ", join( ' ', @items  );
  if ( scalar @skipped ) {
    logit "skipped   : ", join( ' ', @skipped );
  }
  return \@to_process;
}


sub get_login_from_queue_item {
  my $ACIS = shift;
  my $item = shift;
  my $login;

  if ( length( $item ) > 8 
       and $item =~ /^.+\@.+\.\w+$/ ) {

    return lc $item;

  } else {

    my $sql = $ACIS -> sql_object;

    if ( length( $item ) > 15
         or index( $item, ":" ) > -1 ) {
      $sql -> prepare( "select owner from records where id=?" );
      my $r = $sql -> execute( lc $item );
      if ( $r and $r -> {row} ) {
        $login = $r ->{row} {owner};

      } else {
        logit "get_login_from_queue_item: id $item not found";
      }

    } elsif ( $item =~ m/^p[a-z]+\d+$/ 
              and length( $item ) < 15 ) {
      $sql -> prepare( "select owner,id from records where shortid=?" );
      my $r = $sql -> execute( $item );
      if ( $r and $r -> {row} ) {
        $login = $r ->{row} {owner};

      } else {
        logit "get_login_from_queue_item: sid $item not found";
      }

    }
  }

  return $login;
}


sub testme {
  $interactive = 1;

  use ACIS::Web;
  my $acis = ACIS::Web->new();

  die if not $ACIS;
  my @queue = prepare_to_process_queue( 5 );
}



1;
