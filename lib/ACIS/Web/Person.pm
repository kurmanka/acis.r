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


use strict;

use Carp::Assert;

use Web::App::Common qw( &date_now &clear_undefined debug );
use ACIS::Web::HumanNames qw(normalize_and_filter_names);

sub parse_name_variations {
    my $string = shift;
    $string =~ s/[ \t]+/ /g;
    my $list = [ split ( /\s*[\n\r]+/, $string ) ];
    my $hash;
    foreach ( @$list ) {
        # not a single word character? 
        if ($_ !~ m/\w/ ) { undef $_; }
        # a repeated value?
        if ($hash->{lc $_}) {  undef $_; }
        $hash->{lc $_}++;
    }
    clear_undefined $list;
    return $list;
}

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

  normalize_and_filter_names( $list );
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


sub check_name_variations_for_uniqueness {
    my $app = shift;
    my $record = shift || die;

    debug "check_name_variations_for_uniqueness(): start";
    my $names = $record ->{name}{variations};
    my $profiles = [];
    foreach ( @$names ) {
        debug "search for $_";
        push @$profiles, search_profiles_by_name( $app, $_ );
    }

    # remove duplicates, if any 
    my $ids = {};
    foreach (@$profiles) {
        if ($ids->{$_->{id}}) {
            undef $_;
        } else {
            $ids->{$_->{id}} = 1;
        }
    }
    clear_undefined $profiles;

    if (not scalar @$profiles) { 
        debug "check_name_variations_for_uniqueness(): end empty", 
        return undef; 
    }
    debug "check_name_variations_for_uniqueness(): end with ", 
       scalar @$profiles,
       " items found";
    return $profiles;
}

sub search_profiles_by_name {
    my $app = shift;
    my $name = shift || die;

    my $res = [];
    my $sql = $app->sql_object;

    $sql->prepare_cached( "select * from names left join records using (shortid) where names.name=?" );
    my $d = $sql->execute( $name );

    while ($d and $d->{row}) {
        my $row = $d->{row};
        my $i = { url  => $row->{profile_url},
                  name => $row->{namefull},
                  id   => $row->{id}          # id is not necessary, i guess, but may be useful
        };
        push @$res, $i;

    } continue {
        $d->next;
    }

    return @$res;
}


sub bring_up_to_date {
  my $app    = shift || die "need \$app";
  my $record = shift || die "need a record";
#  my $udata  = shift;


  ### lower case owner 
#  $udata -> {owner} {login} = lc $udata ->{owner} {login};
  debug "bring up to date $record->{id}";

  ###  name branch
  my $name = $record -> {name};
  if ( not $name->{'variations-fixed'} or $name->{'variations-fixed'} < 2 ) {
    compile_name_variations( $app, $record );
    $name->{'variations-fixed'} = 2; # 2007-02-28 13:07
  }

  if ( not $name->{latin} ) {
    if ( $name->{full} =~ /([^a-zA-Z\.,\-\s\'\(\)])/ ) {
      my $sid = $record->{sid};
      debug "latin name is missing!";
      $app -> errlog( "[$sid] latin name is missing!" );
    }
  }

  if ( not exists $record -> {id} ) {
    $record ->{id} = $record ->{handle};
  }
  delete $record->{handle};

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


  if ( $record->{temporarysid} ) {
    my $tsid = $record->{temporarysid};
    require ACIS::Web::Background;
    my $runs = ACIS::Web::Background::check_thread( $app, $tsid );
    if ( $runs ) {
      # let it run
    } else {
      $app -> sql_object -> do( "update rp_suggestions set psid=? where psid=?", $record->{sid}, $tsid );
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


## resolve long id & short id into email address of the owner. 
# this function was initially in ACIS::APU, and was named
# get_login_from_queue_item(). Now used from mvrec.pl.
# it needs the ACIS sql_helper object.
sub get_login_from_person_id {
  my $sql  = shift || die; # ACIS db sql_helper
  my $item = shift || die; # email or id or short-id
  my $login;
 
  if ( length( $item ) > 8 
       and $item =~ /^.+\@.+\.\w+$/ ) {
    $sql -> prepare( "select owner from records where owner=?" );
    my $r = $sql -> execute( lc $item );
    if ( $r and $r -> {row} ) {
      $login = $r ->{row} {owner};      
    } 
    else {
      debug "get_login_from_person_id: email $item not found";
    }    

  } else {

     if ( length( $item ) > 15
         or index( $item, ":" ) > -1 ) {
      $sql -> prepare( "select owner from records where id=?" );
      my $r = $sql -> execute( lc $item );
      if ( $r and $r -> {row} ) {
        $login = $r ->{row} {owner};
      } 
      else {
        debug "get_login_from_person_id: id $item not found";
      }

    } elsif ( $item =~ m/^p[a-z]+\d+$/ 
            and length( $item ) < 15 ) {
      $sql -> prepare( "select owner,id from records where shortid=?" );
      my $r = $sql -> execute( $item );
      if ( $r and $r -> {row} ) {
        $login = $r ->{row} {owner};        
      } else {
        debug "get_login_from_person_id: sid $item not found";
      }
    }
  }
  return $login;
}



1;

