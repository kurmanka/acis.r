package ACIS::Data::DumpXML::Parser;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Parse an ACIS::Data::DumpXML-dumped XML string and recreate the
#    data structure.
#
#  This module is tightly related to ACIS::Data::DumpXML, which is
#  based on Data::DumpXML, and it is accordingly based on
#  Data::DumpXML::Parser.
# 
#   Copyright 2003 Ivan Baktcheev, Ivan Kurmanov
#   Copyright 1998-2003 Gisle Aas.
#   Copyright 1996-1998 Gurusamy Sarathy.
#
#  XXX use of GNU GPL here is questionable. 
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
#  $Id: Parser.pm,v 2.0 2005/12/27 19:47:39 ivan Exp $
#  ---



use strict;
use vars qw( $VERSION @ISA );


$VERSION = "0.02";

require XML::Parser;
@ISA=qw( XML::Parser );


sub new {
    my($class, %arg) = @_;
    $arg{Style} = "ACIS::Data::DumpXML::ParseStyle";
    $arg{Namespaces} = 1;
    return $class->SUPER::new(%arg);
}

package ACIS::Data::DumpXML::ParseStyle;

use Carp::Assert;

use vars qw($ROOT_NAME $HASH_ELEMENT $ARRAY_ELEMENT $REF_ELEMENT
            $KEY_AS_HASH_ELEMENT);

$KEY_AS_HASH_ELEMENT = 1
 unless defined $KEY_AS_HASH_ELEMENT;
$ROOT_NAME = 'data'
 unless defined $ROOT_NAME;
$HASH_ELEMENT = 'hash-item'
 unless defined $HASH_ELEMENT;
$ARRAY_ELEMENT = 'list-item'
 unless defined $ARRAY_ELEMENT;
$REF_ELEMENT = 'reference'
 unless defined $REF_ELEMENT;

sub Init
 {
  my $p = shift;
  
  $p -> {'dump'} -> {'data'} = undef;
  push( @{ $p -> {'dump'} -> {'stack'} }, \$p -> {'dump'} -> {'data'} );
  
  $p -> {'dump'} -> {'increment'} = 0;
 }


sub Start
 {
  my($p, $tag, %attr) = @_;
  
  my $increment = \$p -> {'dump'} -> {'increment'};
  $$increment++;
  
  my $blesser;
  $blesser = $p->{Blesser}
   if (exists $p->{Blesser} and ref($blesser) eq "CODE");
  
  $p -> {'dump'} -> {'max-depth'} = $$increment;
  
  my $attr = shift @{$p -> {'dump'} -> {'attr'}};
  my $parent_class = $attr -> {'class'};
  my $parent_id    = $attr -> {'id'};
    
  my $ref = $p -> {'dump'} -> {'stack'} -> [-1];

  
  push ( @{$p -> {'dump'} -> {'attr'}}, \%attr);
  
  if ( $tag eq $HASH_ELEMENT 
       or ($attr{key} and $KEY_AS_HASH_ELEMENT and ($attr{key} eq $tag)))
   {

    assert( ( not defined $$ref 
              or overload::StrVal( $$ref ) =~ /^(?:[^=]+=)?HASH\(/ ),
              "hash element '$tag' must appear in hash context" );

    my $key = $attr{key};
    die "hash element '$key' already present" if exists $$ref -> {$key};
    ${$ref} -> {$key} = undef;
    
    push @{$p -> {'dump'} -> {'stack'}}, \( ${$ref} -> {$key} );
  
    $blesser ? &$blesser ($$ref, $parent_class) : bless ($$ref, $parent_class)
      if defined $parent_class;
   }
  elsif ($tag eq $ROOT_NAME)# and not defined $ref)
   {
   }
  elsif ($tag eq $ARRAY_ELEMENT)
   {


     ###  check the data type
     assert( ( not defined $$ref 
               or overload::StrVal( $$ref ) =~ /^(?:[^=]+=)?ARRAY\(/ ),
             "'$tag' elements only appear in list elements" );


    push @{$$ref}, undef;
    push @{$p -> {'dump'} -> {'stack'}}, \($$ref -> [-1]);
    
    $blesser ? &$blesser ($$ref, $parent_class) : bless ($$ref, $parent_class)
     if defined $parent_class;          

   }
  elsif ($tag eq $REF_ELEMENT)
   {
    my $value = undef;
    $$ref = \$value;
    
    $$ref = ${$p -> {'dump'} -> {'id'} -> [$attr{'to'}]}
     if (defined $attr{'to'});

    push @{$p -> {'dump'} -> {'stack'}}, $$ref;
   }
  elsif ($tag eq 'undef')
   {
    $$ref = undef;
    push @{$p -> {'dump'} -> {'stack'}}, undef;
   }
  elsif ($tag eq 'empty-hash' ) 
   {
    $$ref = {};
    push @{$p -> {'dump'} -> {'stack'}}, undef;
   }
  elsif ($tag eq 'empty-array' ) 
   {
    $$ref = [];
    push @{$p -> {'dump'} -> {'stack'}}, undef;
   } 
  ###  IKu: begin

  ###  If the element is not anything known above, we assume it is a
  ###  hash item, whose key is its name.

  elsif ( $KEY_AS_HASH_ELEMENT ) {

    ###  this is copied from the above, and tweaked afterwards
    
    assert( ( not defined $$ref 
              or overload::StrVal( $$ref ) =~ /^(?:[^=]+=)?HASH\(/ ),
              "hash element '$tag' must appear in hash context" );

    die "hash element '$tag' already present" if exists $$ref -> {$tag};
    ${$ref} -> {$tag} = undef;
    
    push @{$p -> {dump} {stack}}, \(${$ref} -> {$tag});
  
    $blesser ? &$blesser ($$ref, $parent_class) : bless ($$ref, $parent_class)
     if defined $parent_class;

  ###  IKu: end

  } else {
    warn "found unknown element $tag";
  }

  $p -> {dump} {char} = '';
  
  $p -> {dump} {id} -> [$parent_id] = $ref
   if ($parent_id);
 }



sub Char
{
    my($p, $str) = @_;
    $p -> {'dump'} -> {'char'} .= $str;
}

sub End
 {
  
  my($p, $tag) = @_;
  my $increment = \$p -> {'dump'} -> {'increment'};
  my $str = $p -> {'dump'} -> {'char'};
  my $ref = pop @{ $p -> {'dump'} -> {'stack'} };
  
  $p -> {'dump'} -> {'char'} = '';
    
  if( $$increment < $p -> {'dump'} -> {'max-depth'})
   {
    #print ' 'x $$increment, "- this element had children\n";
   }
  elsif ( $tag ne 'undef')
   {
    if ($tag eq $REF_ELEMENT and $p -> {'dump'} -> {'attr'} -> [0] -> {'to'})
     {
#      print "'", $p -> {'dump'} -> {'attr'} -> [0] -> {'to'}, "'\n";
#      my $place = $p -> {'dump'} -> {'attr'} -> [0] -> {'to'};
#      
#      $$ref = ${$p -> {'dump'} -> {'id'} -> [$place]}
#       if (defined $place);
      
     }
    else
     {
      #print ' 'x $$increment, "element '$tag' holds a string value ('$str')\n";
      $$ref = $str;
     }
   }
  $$increment--;
 }

sub Final
 {
  my $p = shift;
  my $data = $p -> {'dump'} -> {'data'};
  return $data;
 }

1;

__END__

=head1 NAME

ACIS::Data::DumpXML::Parser - Restore data dumped by Data::DumpXML

=head1 SYNOPSIS

 use ACIS::Data::DumpXML::Parser;

 my $p = ACIS::Data::DumpXML::Parser->new;
 my $data = $p->parsefile(shift || "test.xml");

=head1 DESCRIPTION

The C<ACIS::Data::DumpXML::Parser> is an C<XML::Parser> subclass that
will recreate the data structure from the XML document produced by
C<ACIS::Data::DumpXML>.  The parserfile() method returns a reference
to an array of the values dumped.

The constructor method new() takes a single additional argument to
that of C<XML::Parser> :

=over

=item Blesser => CODEREF

A subroutine that is invoked for blessing of restored objects.  The
subroutine is invoked with two arguments; a reference to the object
and a string containing the class name.  If not provided the built in
C<bless> function is used.

For situations where the input file cannot necessarily be trusted and
blessing arbitrary Classes might give the ability of malicious input
to exploit the DESTROY methods of modules used by the code it is a
good idea to provide an noop blesser:

  my $p = ACIS::Data::DumpXML::Parser->new(Blesser => sub {});

=back

=head1 SEE ALSO

L<ACIS::Data::DumpXML>, L<XML::Parser>

=head1 AUTHORS

The C<ACIS::Data::DumpXML::Parser> module is written by Ivan
Baktcheev <arglebarle@tut.by>, with support Ivan Kurmanov 
<kurmanov@openlib.og>.

Based on C<Data::DumpXML::Parser> written by Gisle Aas
<gisle@aas.no>.

 Copyright 2003 Ivan Baktcheev
 Copyright 2001 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
