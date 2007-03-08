package ACIS::DocLinks;

use strict;
use warnings;

use Carp::Assert;
use Web::App::Common;
use ACIS::Data::DumpXML::Parser;

my $conf;
sub config {
  return $conf 
    if $conf;
  my $a = $ACIS::Web::ACIS;
  my $home = $a->home;

  my $f = "$home/doclinks.conf.xml";
  my $c = ACIS::Data::DumpXML::Parser ->new ->parsefile( $f );
  if ($c) { 
    return $conf = ACIS::DocLinks::Conf->new($c);
  }
}


sub get_doclinks {
  my ($record) = @_;
  my $links;
  $links = $record->{doclinks} ||= [];
  bless $links;
  return $links;
}

sub save_doclinks {
  my ($record, $links) = @_;
  $record->{doclinks} = $links;
  return 1;
}

sub for_document {
  my ($self, $dsid) = @_;
  # ZZZ this one could be improved to convert the backward links to
  # forward, if possible (that is: if reverse type is defined)
  my @r=();
  foreach(@$self) {
    if ($_->[0] eq $dsid) { push @r,$_; next; }
    if ($_->[2] eq $dsid) { push @r,$_; next; }
  }
  return \@r;
}

sub all_compact {
  my ($self) = @_;
  $self;
}

sub all_expanded {
  my ($self) = @_;
  my $c = $self->config;
  my @r=(@$self);
  foreach(@$self) {
    my ($src,$rel,$trg) = @$_;
    if (my $rev = $c->reverse($rel)) {
      push @r, [$trg,$rev,$src];
    }
  }
  return \@r;
}

sub add {
  my ($self,$src,$rel,$trg) = @_;
  assert( $src and $rel and $trg);
  # XXX make sure the link type $rel is defined in the config
  my $add=1;
  my $print1 = join("\0",$src,$rel,$trg);
  my $print2;
  if (my $r = $self->config->reverse($rel)) {
    $print2 = join("\0",$trg,$r,$src);
  }
  foreach(@$self) {
    my $j = join("\0",@$_);
    if ($j eq $print1) {$add=0;last}
    if ($print2 
        and $j eq $print2) {$add=0;last}
  }
  if($add) {
    push @$self,[$src,$rel,$trg];
    return 1;
  }
}

sub drop {
  my ($self,$src,$rel,$trg) = @_;

  if (not $src or not $rel or not $trg) {
    return $self->drop_selected($src,$rel,$trg);
  }

  my $print1 = join("\0",$src,$rel,$trg);
  my $print2;
  if (my $r = $self->config->reverse($rel)) {
    $print2 = join("\0",$trg,$r,$src);
  }
  foreach(@$self) {
    my $j = join("\0",@$_);
    if ($j eq $print1) {undef $_;} # ZZZ last; could be here
    if ($print2 
        and $j eq $print2) {undef $_;} # ZZZ last; could be here
  }
  clear_undefined $self;  
}

sub drop_selected {
  my ($self,$src,$rel,$trg) = @_;
  my $rev;
  if ( $rel ) { $rev = $self->config->reverse($rel); }

  foreach(@$self) {
    my ($s,$r,$t) = @$_;
    if ( 
        (($src and $s eq $src) or (not $src))
        and (($rel and $r eq $rel) or (not $rel))
        and (($trg and $t eq $trg) or (not $trg))
       ) { undef $_; next; }
    if ( $rev 
         and (($src and $t eq $src) or (not $src))
         and ($r eq $rev) 
         and (($trg and $s eq $trg) or (not $trg))
       ) { undef $_; next; }
  }
  clear_undefined $self;  
 
}


sub print {
  my ($self, $msg) = @_;
  my $i = 0;
  print "-"x10, " ", ($msg||''), "\n";
  foreach (@$self) {
    printf "  [%2d] %5s = %10s => %5s\n", ++$i, @$_;
  } 
  print "-"x50, "\n";
}  

sub testme {
  use ACIS::Web;
  ACIS::Web->new();
  my $rec = {};
  my $l = get_doclinks( $rec );
  $l ->print( "initial state" );
  $l->add( 'd1', 'love', 'd2' );
  $l->add( 'd1', 'love', 'd3' );
  $l->add( 'd1', 'respect', 'd4' );
  $l->add( 'd1', 'love', 'd2' );
  $l->add( 'd1', 'respect', 'd4' );
  $l->add( 'd4', 'respect', 'd2' );
#  $l->drop( 'd1', 'respect', undef );
#  $l->drop( undef, undef, 'd2' );
#  $l->drop( 'd4', 'respect', 'd2' );
  $l->add( 'd1', 'cites', 'd2' );
  $l->add( 'd2', 'is-cited-by', 'd1' );
  $l->drop( 'd2', 'is-cited-by', 'd1' );
  $l ->print( "state 2" );
}



package ACIS::DocLinks::Conf;

sub new {
  my $class = shift;
  my $conf  = shift;
  if ( not $conf 
       or not ref $conf 
       or not $conf->{'link-types'} ) { return undef; }
  my $self = bless $conf->{'link-types'}, $class;
  foreach ( keys %$self ) {
    my $v = $self->{$_};
    if ($v 
        and my $r = $v->{reverse}) { 
      if ( $self->{$r} ) { $self->{$r}{reverse} = $_; }
      else { # false reverse 
        die "bad reverse type of $_: $r";
        undef $v->{reverse};
      }
    }
  }
  return $self;
}

sub label {
  my ($self,$t) = @_;
  return $self->{$t}{label};
}

sub reverse {
  my ($self,$t) = @_;
  $self->{$t}{reverse};
}

sub revlabel {
  my ($self,$t) = @_;
  my $r;
  if ( ($r=$self->{$t}{reverse})
       and $self->{$r} ){
    return $self->{$r}{label};
  }
  undef;
}
       

1;
