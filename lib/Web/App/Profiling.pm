package Web::App;

use strict;


### this is for time-profiling an application

sub time_checkpoint {
  my $self  = shift || die;
  my $point = shift || die;

  require Time::HiRes;

  my $time = $self ->{time};
  if ( not $time ) { 
    $self ->{time} = $time = { -list => [] };
  }
  my $now = [ Time::HiRes::gettimeofday() ];
  my $list = $time ->{-list};
  my $last = $time ->{-last};

  $time ->{-last} = $now;
  if ( $time ->{-start} ) {
    my $interval = Time::HiRes::tv_interval( $last, $now );
    push @$list, [ $point, $interval ];

  } else {
    $time ->{-start} = $now;
  }
}

sub report_timed_checkpoints {
  my $self   = shift;
  my $time   = $self ->{time} || die;
  my $list   = $time ->{-list};
  my $start  = $time ->{-start};
  my $fin    = $time ->{-last};

  my $total  = Time::HiRes::tv_interval( $start, $fin );

  my $rep = '';
  foreach ( @$list ) {
    my $point = $_->[0];
    my $t     = $_->[1];
    my $percent = $t * 100 / $total;
    $rep .= sprintf( "%20s: %4.1f%% %5.2fs\n", $point, $percent, $t );
  }

  $rep .= sprintf( "----------------\n  total: %02.2fs\n", $total );

  return $rep;
}


sub log_profiling {
  my $self   = shift;
  my $request   = shift;
  my $presenter = shift;
  my $data_len  = shift;
  my $page_len  = shift;

  my $time   = $self ->{time} || die;
  my $list   = $time ->{-list};
  my $start  = $time ->{-start};
  my $fin    = $time ->{-last};

  my $total  = Time::HiRes::tv_interval( $start, $fin );

  my $date = localtime time;
  my $rep = "> $request ($date)\n";
  $rep .= "presenter: $presenter\n";

  foreach ( @$list ) {
    my $point = $_->[0];
    my $t     = $_->[1];
    my $percent = $t * 100 / $total;
    $rep .= sprintf( " %18s: %4.1f%% %5.2fs\n", $point, $percent, $t );
  }

  $rep .= sprintf( "total: %02.2fs\n", $total );
  $rep .= sprintf( "data: %03.3fkb\n", $data_len );
  $rep .= sprintf( "page: %03.3fkb\n", $page_len );

  my $home = $self->{home};
  if ( open L, ">>$home/profiling.log" ) {
    print L $rep;
    close L;
  }
  return;
}


1;
