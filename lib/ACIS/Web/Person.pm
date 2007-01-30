package ACIS::Web::Person;  ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    This module is to be responsible for some person record
#    maintanance.  In the future, it should replace parts of
#    ACIS::Web::NewUser and ACIS::Web::User.
#
#
#  Copyright (C) 2003 Ivan Kurmanov for ACIS project,
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
#  $Id: Person.pm,v 2.5 2007/01/30 14:07:00 ivan Exp $
#  ---

use strict;

use Carp::Assert;

use Web::App::Common qw( &date_now &clear_undefined debug );

sub compile_name_variations {
  my $app    = shift;
  my $record = shift;

  my $session = $app -> session;

  if ( not $record ) {
    $record = $session -> current_record; 
  }

  my $name = $record ->{name};
  my $old_names = $name ->{variations};
  my $old_names_string = '';

  ###  remember for a later comparison 
  if ( defined $old_names ) {
    my @o = sort { length( $b ) <=> length( $a ) } @$old_names;
    $old_names_string = join "\n", @o;
  }


  my $list = [];

  
  push @$list, @{ $name ->{'additional-variations'} };
  push @$list, $name ->{full};
  push @$list, $name ->{latin};

  
  require ACIS::Misc;

  my $hash = {};
  foreach ( @$list ) {
    # exclude empty 
    if ( not $_ ) { undef $_; next; }

    # normalize
    s/\s+/ /g;
    s/\b(\p{Lu})(\s|$)/$1.$2/g;  # initials
    s/([\.,])(\w)/$1 $2/g;       # initials

    # exclude repeated items
    if ( $hash->{$_} ) { undef $_; next; }

    # remember the item
    $hash ->{$_} = 1;

    # if accent-translation is possible, add it too
    if ( ACIS::Misc::contains_non_ascii( $_ ) ) {
      my $trans = ACIS::Misc::transliterate_safe( $_ );
      if ( $trans and not $hash->{$trans} ) {
        push @$list, $trans;
      }
    }
  }

  clear_undefined $list;
  $name ->{variations} = $list;


  ### now sort by length: longer items come first
  my @sl = sort { length( $b ) <=> length( $a ) } @$list;
  my $names_string = join "\n", @sl;


  ### compare to notice substantial change
  if ( $names_string ne $old_names_string ) {
    $name -> {'last-change-date'} = time;
    $app -> userlog( "name data changed: variations" );
  }
}


sub auto_fix_name_variations {
  my $app = shift;
  my $rec = shift;

  my $name = $rec ->{name};
  my $first = $name->{first};

  if ( $rec -> {imported} ) { 
    if ( not $name->{middle} ) {
      if ( $first =~ /^(\w+)\s(\w.+)/ ) {
        $name->{first}  = $1;
        $name->{middle} = $2;
      }
    }
  }

  $name -> {'additional-variations'} = generate_name_variations( $rec );
}


sub bring_up_to_date {
  my $app    = shift;
  my $record = shift;
#  my $udata  = shift;


  ### lower case owner 
#  $udata -> {owner} {login} = lc $udata ->{owner} {login};
  debug "bring up to date $record->{id}";

  ###  name branch
  my $name = $record -> {name};
  if ( not $name->{'variations-fixed'} ) {
    auto_fix_name_variations( $app, $record );
    compile_name_variations( $app, $record );
    $record ->{name}{'variations-fixed'} = 1;
  }
  if ( not $name->{latin} ) {
    if ( $name->{full} =~ /([^a-zA-Z\.,\-\s\'\(\)])/ ) {
      my $sid = $record->{sid};
      debug "latin name is missing!";
      $app -> errlog( "[$sid] latin name is missing!" );
    }
  }
  delete $record ->{'full-name'};
  delete $record ->{'name-variations'};

  if ( not exists $record -> {id} ) {
    $record ->{id} = $record ->{handle};
  }
  delete $record->{handle};

  
  $record ->{id} = lc $record -> {id};


  ### short id
  if ( not exists $record -> {sid} ) {
    if ( not exists $record -> {'short-id'} ) {
      require ACIS::Web::NewUser;
      ACIS::Web::NewUser::make_short_id( $app, $record );

    } else {
      $record -> {sid} = $record -> {'short-id'};
      delete $record -> {'short-id'};
    }
  }


  if ( $record->{sid} !~ /^p\w+\d+$/ ) {
    my $sid = $record ->{sid};
    delete $record->{sid};

    for ( $record->{profile} ) {
      foreach ( values %{$_->{export}} ) {
        if ( $_ ) { unlink $_; }
      }
      unlink $_->{file};
      delete $_->{url};
      delete $_->{file};
      delete $_->{export};
    }
    $record->{settings} = {};

    require ACIS::Web::NewUser;
    my $newsid = ACIS::Web::NewUser::make_short_id( $app, $record );

    if ( $newsid =~ /^p/ ) {
      ACIS::Web::NewUser::fix_temporary_sid( $app, $sid, $newsid );
      require ACIS::Web::User;
      ACIS::Web::User::rebuild_profile_url( $app, $record );
      $app -> success(0);

    } else {
      die "can't go on without a good sid";
    }
  }
 

  ###  contact branch

  if ( not exists $record ->{contact} ) {

    my $contact = {
       email => $record ->{email},
       'email-pub' => $record ->{'mail-pub'},
    };

    foreach ( qw( homepage postal phone ) ) {
      if ( exists $record ->{$_} ) {
        $contact ->{$_} = $record ->{$_};
      }
      delete $record -> {$_};
    }
    

    $record ->{contact} = $contact;

    delete $record -> {email};
    delete $record -> {'mail-pub'};
  }


  ###  photo branch
  if ( exists $record ->{'photo-url'} ) {
    $record -> {photo} {url} = $record ->{'photo-url'};
    delete $record ->{'photo-url'};
  }

  delete $record ->{'profile-url'};
  delete $record ->{'profile-file'};

  if ( $record->{temporarysid} ) {
    my $tsid = $record->{temporarysid};
    require ACIS::Web::Background;
    my $runs = ACIS::Web::Background::check_thread( $app, $tsid );
    if ( $runs ) {
      # let it run
    } else {
      $app -> sql_object -> do( "update suggestions set psid=? where psid=?", $record->{sid}, $tsid );
      delete $record->{temporarysid};
    }
  }

}




sub generate_name_variations {
  my $rec = shift;
  
  my $name         = $rec  -> {name}; 

  my $first_name   = $name -> {first};
  my $middle       = $name -> {middle} || '';
  my $last_name    = $name -> {last};
  my $suffix       = $name -> {suffix};

  my $var          = $name -> {'additional-variations'};
  

  my ( $first_i, $mid_i );
  
  if ( length( $first_name ) > 1 ) {
    $first_i  = substr $first_name,  0, 1;
    $first_i .= '.';
  }
  if ( length( $middle ) > 1 ) {
    $mid_i    = substr $middle, 0, 1;
    $mid_i   .= '.';
  }
    
  my $full_name = "$first_name $middle $last_name";

  if ( $suffix ) {  ### X Jr. suffix dot: not general, not documented,
    $full_name .= ", $suffix";

    if ( $suffix =~ /^Jr.$/i ) {
      $suffix = "Jr";
    }
  }
  $full_name =~ s/\s+/ /g;

  my $list =  [];

  if ( $var and ref $var eq 'ARRAY' ) { 
    push @$list, @$var;
  }


  # first, longish variants: with suffix and middle name

  if ( $suffix ) {

    if ( $middle ) {
      push @$list,  
        "$first_name $middle $last_name, $suffix",
        "$last_name, $suffix, $first_name $middle";                        

      if ( $mid_i ) {
        push @$list,  
          "$first_name $mid_i $last_name, $suffix",
          "$last_name, $suffix, $first_name $mid_i";

        if ( $first_i ) {
          push @$list,  
            "$last_name, $suffix, $first_i $mid_i";
        }
      }
    }

    push @$list, 
      "$first_name $last_name, $suffix",
      "$last_name, $first_name, $suffix";

    if ( $first_i ) {
      push @$list,  
        "$first_i $last_name, $suffix",
        "$last_name, $suffix, $first_i";
    }
  }


  if ( $middle ) {
    push @$list,  
      "$first_name $middle $last_name",
      "$last_name, $first_name $middle";

    if ( $mid_i ) {
      push @$list,  
        "$first_name $mid_i $last_name",
        "$last_name, $first_name $mid_i";

      if ( $first_i ) {
        push @$list, "$last_name, $first_i $mid_i"
                   , "$first_i $mid_i $last_name";
      }
    }
  }

  
  # second, simplier, shorter variants
  
  push @$list, "$first_name $last_name",
               "$last_name, $first_name";

  if ( $first_i ) {
    push @$list,  
      "$first_i $last_name",
      "$last_name, $first_i";
  }
  

  # clear duplicates, if any

  my $hash = {};
  foreach ( @$list ) { 
    if ( not $_ or $hash->{$_} ) {
      undef $_;
      next;
    }
    $hash ->{$_} = 1; 
  }
  clear_undefined $list;

  return $list;

}

1;

