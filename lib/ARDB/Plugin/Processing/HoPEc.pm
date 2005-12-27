package ARDB::Plugin::Processing::HoPEc;

use ARDB::Plugin::Processing;

use strict;
use vars qw ( @ISA );

@ISA = qw( ARDB::Plugin::Processing );

sub get_record_types {
  return []; #'ReDIF-Person 1.0', 'ReDIF-Paper 1.0', 'ReDIF-Article 1.0'];
}

sub require  {
  return [ 'ARDB::Plugin::Processing::ShortIDs' ];
}

sub process_record  {
  my $self = shift;
  my $record = shift;
  
  ACIS::ShortIDs::process_record ( $record, 1 );
  my $short_id = ACIS::ShortIDs::resolve_handle ( $record -> {handle} -> [0] );
  $record -> {SHORT_ID} = $short_id
   if ( defined ( $short_id ) );
 }


1;
