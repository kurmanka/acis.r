package ACIS::UserData::User::Record;    ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    ARDB-Record class for ACIS user records.
#    Implements ARDB::Record interface,
#    http://acis.openlib.org/dev/ardb-record.html
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
#  $Id: Record.pm,v 2.0 2005/12/27 19:47:39 ivan Exp $
#  ---



use strict;

use base qw( ARDB::Record );

sub id {
  my $self = shift;
  
  return $self -> {login};
}

# Вернуть идентификатор записи/объекта.

sub type {
  return 'acis-user';
}
# Вернуть тип записи.

sub get_value {
  my $data = shift;
  my $path  = shift;
  
  my @path  = split '/', $path;

  foreach ( @path ) {
    if ( not ref $data 
         or not exists $data ->{$_} ) {
      return ();
    } 

    $data = $data -> {$_};
  }
  
  if ( ref $data eq 'ARRAY' ) { 
    return @$data; 
  }
  
  return $data;
}

# Вернуть список значений из недр записи, соответствующих спецификации
# SPEC или пустой массив. Спецификации SPEC берутся из конфигурации
# ARDB. Сейчас мы используем простую имитацию XPath, типа author/name,
# но в общем-то это наше дело - какой синтаксис использовать -- при
# условии, что мы будем использовать его взаимно-совместимым образом.

# Методы, используемые ARDB при get_unfolded_record() вызове

sub add_relationship {

  my $self     = shift;
  my $relation = shift;
  my $object   = shift;
  
  my $relations = $self -> {'ardb-record'} {relations};
  
  if (ref $relations -> {$relation} eq 'ARRAY') {
    push @{ $relations -> {$relation} }, $object;

  } else {
    $relations -> {$relation} = [];
    push @{ $relations -> {$relation} }, $object;
  }
}

# Дополнить объект отношением с другим объектом. Только для того,
# чтобы пользователь ARDB смог воспользоваться всей чудесной
# конструкцией и узнать, что интересующий его объект вовлечён в ещё
# какие-то отношения... Как конкретно он об этом узнает -- уже не
# наше дело.

sub set_view {
  my $self = shift;
  my $view = shift;
  
  $self -> {'ardb-record'} {view} = $view;
}
# Сообщаем "развёрнутому" объекту, в каком виде он будет показан
# пользователю.

# Пользовательские методы
sub view {
  my $self = shift;
  
  return $self -> {'ardb-record'} {view};
}
# Чтобы пользователь мог узнать, в каком виде его объект. Возвращает
# строку.

sub get_relationship {
  my $self     = shift;
  my $relation = shift;
  
  my $relations = $self -> {'ardb-record'} {relations};
  
  if (ref $relations -> {$relation} eq 'ARRAY') {
    return @{ $relations -> {$relation} };

  } else {
    return undef;
  } 
}

# Чтобы пользователь мог узнать, в какие отношения вляпался его
# объект. Возвращает список объектов.

1;
