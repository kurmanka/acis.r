package ARDB::Plugin::Processing::ShortIDs;### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    A plugin to check or generate a short identifiers for metadata
#    records.
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




use ARDB::Plugin::Processing;
use ACIS::ShortIDs;
use ARDB::Common;

use strict;

use base ( 'ARDB::Plugin::Processing' );

sub get_record_types {
  my $self = shift;

  return [ 'ReDIF-Person 1.0', 
           'ReDIF-Software 1.0', 
           'ReDIF-Paper 1.0', 
           'ReDIF-Article 1.0', 
           'ReDIF-Chapter 1.0', 
           'ReDIF-Book 1.0', 
           'ReDIF-Archive 1.0',
           'ReDIF-Series 1.0',
];
}



sub process_record {
  my $self = shift;
  my $record = shift;
  
  my $id = $record -> id;

  debug "try to resolve short id for record '$id'";
  
#  RePEc::ShortIDs::process_record ( $record, 1 );
  
#  my $short_id = RePEc::ShortIDs::resolve_handle ( $id );
  
#  $record -> {SHORT_ID} = $short_id
#    if ( defined ( $short_id ) );
}



1;

=head1 NAME

ARDB plugin Processing::ShortIDs - interface to a RePEc::ShortIDs module

=head1 DESCRIPTION

Processing::ShortIDs - plugin который предоставляет интерфейс к модулю
RePEc::ShortIDs. он наследует модуль ARDB::Plugin::Processing и переопределяет
2 функции - get_record_types ( еще необходимо уточнение выходящих данных ) и 
process_record

=head1 AUTHOR

Ivan Baktcheev, with support from Ivan Kurmanov

=head1 SEE ALSO

L<ARDB::Plugins> L<ARDB::Plugin::Processing> and L<ACIS::ShortIDs>

=cut
