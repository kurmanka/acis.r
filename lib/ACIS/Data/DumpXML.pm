package ACIS::Data::DumpXML;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Dump a data structure into simple XML-based language string.
#
#  This module is based on Data::DumpXML, but simplified slightly and
#  adapted for ACIS by Ivan Baktcheev.  Minor tweaks by Ivan Kurmanov
#  (marked in source as IKu:).
# 
#  The Data::DumpXML module is written by Gisle Aas <gisle@aas.no>,
#  based on Data::Dump module.
# 
#  The Data::Dump module was written by Gisle Aas, based on
#  Data::Dumper by Gurusamy Sarathy <gsar@umich.edu>.
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
#  $Id$
#  ---



use strict;
use vars qw(@EXPORT_OK $VERSION $LEVEL);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK=qw(dump_xml dump_wo_refs dump);

$VERSION = "0.03";  # $Date$

# configuration
use vars qw($INDENT $INDENT_STYLE $XML_DECL $NAMESPACE $NS_PREFIX
            $SCHEMA_LOCATION $DTD_LOCATION $ROOT_NAME $SIMPLE_VIEW
            $HASH_ELEMENT $ARRAY_ELEMENT $REF_ELEMENT $ENCODING
            $KEY_AS_HASH_ELEMENT $NOTE_CIRCULAR_REFS
            $LIST_ITEM_POS_ATTRIBUTE
           );

$KEY_AS_HASH_ELEMENT = 1
  unless defined $KEY_AS_HASH_ELEMENT;

$NOTE_CIRCULAR_REFS = 1
  unless defined $NOTE_CIRCULAR_REFS;

$LIST_ITEM_POS_ATTRIBUTE = 1;


$ENCODING = 'UTF-8'
  unless defined $ENCODING;

$ROOT_NAME = 'data'
  unless defined $ROOT_NAME;

$SIMPLE_VIEW = 0
  unless defined $SIMPLE_VIEW;

$HASH_ELEMENT = 'hash-item'
  unless defined $HASH_ELEMENT;

$ARRAY_ELEMENT = 'list-item'
  unless defined $ARRAY_ELEMENT;

$REF_ELEMENT = 'reference'
  unless defined $REF_ELEMENT;

$INDENT_STYLE = "XML"
  unless defined $INDENT_STYLE;

$XML_DECL = 1
  unless defined $XML_DECL;

$INDENT = " " x 4
  unless defined $INDENT;

$NAMESPACE = ''
  unless defined $NAMESPACE;

$NS_PREFIX = ''
  unless defined $NS_PREFIX;

$SCHEMA_LOCATION = ''
  unless defined $SCHEMA_LOCATION;

$DTD_LOCATION = ''
  unless defined $DTD_LOCATION;

$LEVEL = -1;

# other globals
use vars qw($NL);

use utf8;


use overload ();
use vars qw(
            %reserved_elements
            %seen %ref $count $prefix %ref2 %references %used $depth 
           );


my @reserved_elements = qw(
  list-item 
  hash-item 
  undef     
  empty-array
  empty-hash
  data
  reference
);

foreach ( @reserved_elements ) {
  $reserved_elements{ $_ } = 1;
}


sub dump_wo_refs {
  local ( $NOTE_CIRCULAR_REFS ) = 0;
  return dump_xml( @_ );
}

sub dump_no_bullshit {
  local ( $NOTE_CIRCULAR_REFS ) = 0;
  local ( $INDENT ) = '';
  local ( $LIST_ITEM_POS_ATTRIBUTE ) = 0;
  return dump_xml( @_ );
}



sub simple_dump ($$;$$);

sub analyze {

  my $structure = shift;
  
  return unless defined $structure;
  
  if ( ref $structure 
       and overload::StrVal($structure) =~ /^(?:([^=]+)=)?([A-Z]+)\(0x([^\)]+)\)$/
     )  {
    if ( defined $references{$3} ) { 
      if ( $references{$3} ) { return; }
      
      $references{$3} = ++$count;
      return;

    } else {

      $references{$3} = 0;
      if ( $2 eq 'HASH' ) {

        foreach ( values %$structure ) {
          analyze( $_ );
        }

      } elsif ( $2 eq 'ARRAY' ) {

        foreach ( @$structure ) {
          analyze( $_ );
        }

      } elsif ( $2 eq 'REF' ) {
        analyze( $$structure );
      }
      return; 
    }
  }
}


sub dump_xml (@) {
    local %seen;
    local %ref;
    local %references;
    local %used;
    local $count = 0;
    local $depth = 0;
    local $prefix = ($NAMESPACE && $NS_PREFIX) ? "$NS_PREFIX:" : "";

    local $NL = ($INDENT) ? "\n" : "";

    my $out = "";
    $out .= qq(<?xml version="1.0" encoding="$ENCODING"?>\n)
     if $XML_DECL;
    
    $out .= qq(<!DOCTYPE data SYSTEM "$DTD_LOCATION">\n)
     if $DTD_LOCATION;

    my $namespace = '';

    $namespace = ($NS_PREFIX ? "xmlns:$NS_PREFIX" : "xmlns") . qq(="$NAMESPACE")
     if $NAMESPACE;
    $namespace .= qq( xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="$SCHEMA_LOCATION")
     if $SCHEMA_LOCATION;

    my $structure;
    
    if ( (scalar @_) == 1) { 
      $structure = shift; 
    } else {
      $structure = \@_; 
    }
     
    if ( $NOTE_CIRCULAR_REFS ) {

      analyze ( $structure );
      foreach ( keys %references ) {
        next if $references{$_} > 0;
        delete $references{$_};
      }

    } else {
      %references = ();
    }
    
    $out .= simple_dump( $structure, $ROOT_NAME, [$namespace] );

    if ( $NOTE_CIRCULAR_REFS ) {
      $count = 0;
      $out =~ s/\01/$ref{++$count} ? qq( id="r$ref{$count}") : ""/ge;
    }

    return $out;
}

*dump = \&dump_xml;

sub simple_dump ($$;$$) {
  my $rval      = \$_[0];
  my $tag        = $_[1];
  my $attributes = $_[2] || [];
  
  local $LEVEL   = $LEVEL + 1;
  
  my $deref      = $_[3] || 0;

  if ( $deref == 2 ) {
    $rval  = $$rval;
    $LEVEL --;

  } elsif ( $deref ) {
    $rval  = $$rval;
  }

  my $indent = $INDENT x $LEVEL;

  my $attr_str = '';

  $attr_str = ' ' . join (' ', @$attributes)
   if ( defined $attributes and scalar @$attributes );

  my ( $class, $type, $id );

  if ( overload::StrVal($rval) =~ /^(?:([^=]+)=)?([A-Z]+)\(0x([^\)]+)\)$/ ) {
    $class = $1 ? " class=" . quote($1) : "";
    $type  = $2;
    $id    = $3;

  } else { 
    return qq($indent<!-- can\'t parse \") . overload::StrVal($rval) . qq(\" -->); 
  }
  
  if ( my $ref_no = $references{$id} ) {
    if ( $used{$id} ) {
      return qq($indent<${prefix}$tag$attr_str><$REF_ELEMENT to="$ref_no"/></${prefix}$tag>);
    }
    $used{$id} = 'yes';
  }

  $id = $references{$id} ? " id=" . quote ($references{$id}) : '';

  if ( $type eq "SCALAR" 
       or $type eq "REF" ) {

    if ( not defined $$rval ) {
      return "$indent<${prefix}$tag$attr_str><undef/></${prefix}$tag>";
    }
    
    if ( ref $$rval ) {

      ### XX references to references or to scalars support

      $depth++;

      if ( (ref $$rval) eq 'SCALAR'  
           or (ref $$rval) eq 'REF' ) {
        return
          "$indent<${prefix}$tag$class$id$attr_str>$NL".
          simple_dump($$rval, $REF_ELEMENT, undef, 1).
          "$NL$indent</${prefix}$tag>";
      }

      return simple_dump($$rval, $tag, $attributes, 2);
    }

    my( $str, $enc ) = esc($$rval);
    #my $enc = '';
    #my $str = $$rval;
    return "$indent<${prefix}$tag$class$id$attr_str$enc>$str</${prefix}$tag>";

  } elsif ( $type eq "ARRAY" ) {

    my @array;
    if ( not scalar @$rval ) {
      return "$indent<${prefix}$tag$class$id$attr_str><empty-array /></${prefix}$tag>"
    }
    
    my $str = "$indent<${prefix}$tag$class$id$attr_str>$NL";

    if ( $LIST_ITEM_POS_ATTRIBUTE ) {
      my $counter = 0;
      foreach ( @$rval ){
        $str .= simple_dump($_, $ARRAY_ELEMENT, ["pos=\"$counter\""]);
        if ( $NL ) { $str .= $NL; }
        $counter++;
      }

    } else { 
      foreach ( @$rval ){
        $str .= simple_dump( $_, $ARRAY_ELEMENT );
        if ( $NL ) { $str .= $NL; }
      }
    }
    $str .= "$indent</${prefix}$tag>";
    return $str;

  } elsif ( $type eq "HASH" ) {
    
    my $out = "$indent<${prefix}$tag$class$id$attr_str>";
    
    return "$out<empty-hash /></${prefix}$tag>"
     unless scalar keys %$rval;
    
    $out .= $NL;
    
    foreach my $key ( sort keys %$rval ) {

      my $val = \$rval->{$key};

      ###  IKu: Here I make key attribute optional.  We need it only if we use
      ###  $HASH_ELEMENT name or if the key itself can be confused with
      ###  anything else in parser.

      ###  It can be confused with anything else if it is a reserved element
      ###  name.  But if we put key attribute, we won't confuse it with
      ###  anything.
 
      my $element;
      my $quotedkey = quote ($key);
      my $attr = [ "key=$quotedkey" ] ;

      ###  if the key fits into XML Name production, excluding colon ":"
      if ( $key =~ /^[[:alpha:]_][\w\d\.\-_]*$/
           and $KEY_AS_HASH_ELEMENT ) {

        $element = $key;  ###  use the key as the element name

        if ( not $reserved_elements{$key} ) {
          $attr = [];  ### no need for the "key" attribute
        }

      } else {
        $element = $HASH_ELEMENT;  ### use hash-item element name
      }  

      $val = simple_dump( $$val, $element, $attr );
      ###  IKu: end

      $out .= $val . $NL;
    }

    if ( $INDENT_STYLE eq "Lisp" ) {
      # kill final NL
      substr($out, -length($NL)) = "";
    }
    $out .= "$indent</${prefix}$tag>";
    return $out;

  } elsif ( $type eq "GLOB" ) {
    return "$indent<${prefix}glob$class$id/>";

  } elsif ( $type eq "CODE" ) {
    return "$indent<${prefix}code$class$id/>";

  } else {
    #warn "Can't handle $type data";
    return "<!-- Unknown type $type -->";
  }
  die;
}


#sub format_list {
#    my @elem = @_;
#    if ($INDENT) {
#        for (@elem) { s/^/$INDENT/gm; }
#    }
#    return join($NL, @elem );
#}



# put a string value in double quotes
sub quote {
  local( $_ ) = shift;
#    $_ = pack('U*', unpack('U*', $_ ));
    
  s/&/&amp;/g;
  s/</&lt;/g;
  s/>/&gt;/g;

  if ( m/[\x00-\x08\x0B\x0C\x0E-\x1F]/ ) {
    warn "DumpXML warning: some XML-invalid characters in data";
    ###  encode invalid characters
    s/([\x00-\x08\x0B\x0C\x0E-\x1F])/ sprintf( '\x{%x}', ord( $1 ) )/eg;
  }

  s/([^\040-\176])/sprintf('&#x%x;', ord($1))/ge
    unless ( $ENCODING eq 'UTF-8' );

  return qq("$_");
}


sub esc {
  local( $_ ) = shift;
    
#  $_ = pack('U*', unpack('U*', $_ ));

  if ( $ENCODING eq 'UTF-8' ) {
    s/&/&amp;/g;
    s/</&lt;/g;
    s/]]>/]]&gt;/g;

    if ( m/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\xFF]/ ) {
#      warn "DumpXML warning: some XML-invalid characters in data";
      ###  encode invalid characters

      s/([\x00-\x08\x0B\x0C\x0E-\x1F])/./g;  ### XXX Arguable translation
      if ( not Encode::is_utf8( $_ ) ) {
        s/([\x7F-\xFF])/ sprintf( '\x{%x}', ord( $1 ) )/ge;  ### XXX not
                                                             ### decoded in the parser
      }

#      s/([\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\xFF])/ sprintf( '\x{%x}', ord( $1 ) )/ge;

#      s/([\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\xFF])/?/g;
    }

#    s/[\x00-\x08\x0B\x0C\x0E-\x1F]/sprintf("&#x%x;", ord($1))/ge;
#    s/([^\x0a\x0d\040-\176])/sprintf("&#x%x;", ord($1))/ge;

    return $_, "";

  } elsif (/[\x00-\x08\x0B\x0C\x0E-\x1F\x7f-\xff]/) {
      # \x00-\x08\x0B\x0C\x0E-\x1F these chars can't be represented in XML at all
      # \x7f is special
      # \x80-\xff will be mangled into UTF-8
    require MIME::Base64;
    my $nl = (length($_) < 40) ? "" : $NL;
    my $b64 = MIME::Base64::encode($_, $nl);
    return $nl.$b64, qq( encoding="base64");
  }
}

1;

__END__

=head1 NAME

ACIS::Data::DumpXML - Dump a simple data structure into a simple XML document

=head1 SYNOPSIS

 use ACIS::Data::DumpXML qw(dump_xml);
 $xml = dump_xml( $ref );

=head1 DESCRIPTION

This module is very much like Data::Dumper with the following differences:

=over 

=item Output is in XML

Has to be parsed back by ACIS::Data::DumpXML::Parser.

=item Only relatively simple data structures can be dumped

...

=item Not suitable for binary data

Safe for text.

=item Has just one simple interface -- the dump_xml function

No object-oriented interface.

=back


=head2 C<dump_xml()> function

The C<dump_xml()> function takes any perl data structure reference as an
argument.  The string returned is an XML document that represents the data.
Reference loops are handled correctly.

As an example of the XML documents produced; the following call:

  $a = bless [1,2], "Foo";
  dump_xml($a);

will produce:
  
  <?xml version="1.0" encoding="UTF-8"?>
  <data class="Foo">
   <list-item>1</list-item>
   <list-item>2</list-item>
  </data>
  


......

=head1 BUGS

Class names with 8-bit characters will be dumped as Latin-1, but
converted to UTF-8 when restored by the Data::DumpXML::Parser.

The content of globs and subroutines are not dumped.  They are
restored as the strings; "** glob **" and "** code **".

LVALUE and IO objects are not dumped at all.  They will simply
disappear from the restored data structure.

=head1 SEE ALSO

L<Data::Dumper>, L<ACIS::Data::DumpXML::Parser>, L<Data::DumpXML>

=head1 AUTHORS

The C<ACIS::Data::DumpXML> module is written by Ivan Bahcheyev, based on
C<Data::DumpXML> and now maintained by Ivan Kurmanov.

The C<Data::DumpXML> module is written by Gisle Aas,
based on C<Data::Dump>.

The C<Data::Dump> module was written by Gisle Aas, based on
C<Data::Dumper> by Gurusamy Sarathy.

 Copyright 2003 Ivan Bahcheyev.
 Copyright 1998-2003 Gisle Aas.
 Copyright 1996-1998 Gurusamy Sarathy.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut



__DATA__




# этот модуль появился вследствие неудобства представления данных в XML,
# генерируемом Data::DumpXML. полностью сохранена функциональность, как в
# dumper так и в parser. интерфейс модуля изменен для более изменяемого
# namespace - т.е. теперь можно задавать имя для root элемента, элементов
# массива, хэша, ссылок. документация для модуля остается прежней, за
# исключением изменений косметического характера, добавления новых переменных
# в configuration variables и описания различия в секции DIFFERENCE.



# The following data model is used:

#    data : scalar*
#    scalar = undef | str | ref | alias
#    ref : scalar | array | hash | glob | code
#    array: scalar*
#    hash: (key scalar)*

# As an example of the XML documents produced; the following call:

#   $a = bless [1,2], "Foo";
#   dump_xml($a);

# will produce:
  
#   <?xml version="1.0" encoding="UTF-8"?>
#   <data class="Foo">
#    <list-item>1</list-item>
#    <list-item>2</list-item>
#   </data>
  
# If dump_xml() is called in void context, then the dump will be printed
# on STDERR automatically.  For compatibility with C<Data::Dump> there
# is also an alias for dump_xml() simply called dump().

# The C<ACIS::Data::DumpXML::Parser> is a class that can restore
# data structures dumped by dump_xml().


# =head2 Configuration variables

# The generated XML is influenced by a set of configuration variables.
# If you modify them, then it is a good idea to localize the effect. E.g.:

#   sub my_dump_xml {
#       local $Data::DumpXML::INDENT = "";
#       local $Data::DumpXML::XML_DECL = 0;
#       local $Data::DumpXML::DTD_LOCATION = "";
#       local $Data::DumpXML::NS_PREFIX = "dumpxml";

#       return dump_xml(@_);
#   }

# This variables are used from originally written Data::DumpXML:

# =over

# =item $Data::DumpXML::INDENT

# You can set the variable $Data::DumpXML::INDENT to control the amount
# of indenting.  The variable contains the whitespace you want to be
# used for each level of indenting.  The default is a single space.  To
# suppress indenting set it as "".

# =item $Data::DumpXML::INDENT_STYLE

# This variable controls where end element are placed.  If you set this
# variable to the value "Lisp" then end tags are not prefixed by NL.
# This give a more compact output.

# =item $Data::DumpXML::XML_DECL

# This boolean variable controls whether an XML declaration should be
# prefixed to the output.  The XML declaration is the <?xml ...?>
# thingy.  The default is 1.  Set this value to 0 to suppress the
# declaration.

# =item $Data::DumpXML::NAMESPACE

# This variable contains the namespace used for the the XML elements.
# The default is to let this be a URI that actually resolve to the XML
# Schema on CPAN.  Set it to "" to disable use of namespaces.

# =item $Data::DumpXML::NS_PREFIX

# This variable contains the namespace prefix to use on the elements.
# The default is "" which means that a default namespace will be declared.

# =item $Data::DumpXML::SCHEMA_LOCATION

# This variable contains the location of the XML Schema.  If this
# variable is non-empty, then an C<xsi:schemaLocation> attribute will be
# added the top level C<data> element.  The default is to not include
# this as the location can be guessed from the default XML namespace
# used.

# =item $Data::DumpXML::DTD_LOCATION

# This variable contains the location of the DTD.  If this variable is
# non-empty, then a <!DOCTYPE ...> will be included in the output.  The
# default is to point to the DTD on CPAN.  Set it to "" to suppress the
# <!DOCTYPE ...> line.

# =back

# переменные, содержащие названия имен элементов генерируемого XML.

# =over

# =item $Data::DumpXML::ROOT_NAME

# определяет название элемента root XML документа. по умолчанию
# устанавливается в 'data'

# =item $Data::DumpXML::ARRAY_ELEMENT

# определяет название элемента XML документа, содержащего элемент
# массива perl. по умолчанию устанавливается в 'list-item'

# =item $Data::DumpXML::HASH_ELEMENT

# определяет название элемента XML документа, содержащего элемент
# хэша perl. по умолчанию устанавливается в 'hash-item'

# =item $Data::DumpXML::REFERENCE

# определяет название элемента XML документа, содержащего ссылку
# на структуру perl. по умолчанию устанавливается в 'reference'

# =back

# =head1 DIFFERENCE

# различие между output Data::DumpXML и ACIS::Data::DumpXML
# заключается в том, что ACIS::Data::DumpXML генерирует упрощенные
# структуры perl.

# пример:

#   $a = bless [1,2], "Foo";
#   dump_xml($a);

# у нас имеется в переменной $a ссылка на blessed "Foo" массив,
# содержащий два элемента.

# ACIS::Data::DumpXML

#   <?xml version="1.0" encoding="UTF-8"?>
#   <data class="Foo">
#    <list-item>1</list-item>
#    <list-item>2</list-item>
#   </data>

# Data::DumpXML  
  
#   <?xml version="1.0" encoding="US-ASCII"?>
#   <data xmlns="http://www.cpan.org/.../Data-DumpXML.xsd">
#    <ref>
#     <array class="Foo">
#      <str>1</str>
#      <str>2</str>
#     </array>
#    </ref>
#   </data>

# в модуле ACIS::Data::DumpXML принимаются некие допущения, как то:
# для perl необязательно указывать ссылку, то есть структуру

# $a -> {b} -> {c} -> {d} ...

# можно записать как

# $a -> {b}{c}{d} ...

# такие же допущения принимаются и в генерируемом XML, только
# применяются они еще и с учетом специфики XML:

# так как root-level элемент может быть только один, то объект,
# который передается dumper, становится либо ссылкой на структуру
# данных perl, либо scalar.

# элемент, содержащий вложенные элементы типа 'list-item' или 'hash-item',
# трактуются как массив и хэш соответственно.

# если между открывающим и закрывающим тегом не содержится никаких
# символов (<list-item></list-item> или <list-item />), то значение
# трактуется как пустая строка.

# пустой массив и хэш экспортируются в виде <empty-array /> и
# <empty-hash />; неопределенные значения в <undef />
