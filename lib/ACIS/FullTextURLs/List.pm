package ACIS::FullTextURLs::List; 

# This implements the RePEc::Index record interface for the full-text
# url links records.  It is used implicitly by RePEc::Index and
# explicitly by RePEc::Index::Collection::FullTextUrlsAMF and by
# ACIS::FullTextURLs::Input modules.

use strict;
use warnings;
use Digest::MD5;


sub create {
  my ($id,$auth,$auto) = @_;
  $id = lc $id;
  my $ul = ["$id#fturls", $auth, $auto];
  bless $ul, "ACIS::FullTextURLs::List";
}

sub id {
  my $self = shift;
  return $self->[0];
}

sub type { "fturls" }

sub authoritative {
  my $self = shift;
  return $self->[1];
}

sub automatic {
  my $self = shift;
  return $self->[2];
}

sub md5checksum {
  my $self = shift;
  my $id  = $self->[0];
  my $ctx = Digest::MD5->new;
  $ctx ->add( "$id\n" );

  foreach ( @{$self->authoritative} ) { $ctx->add("$_ "); }
  $ctx->add("\n");
  foreach ( @{$self->automatic} )     { $ctx->add("$_ "); }
  return $ctx->b64digest;
}

1;
