package ACIS::Web::Contributions;  ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    The Contributions profile.
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
#  $Id: Contributions.pm,v 2.4 2006/03/26 10:04:11 ivan Exp $
#  ---

use strict;

use Carp::Assert;

use Web::App::Common;

use ACIS::Data::DumpXML::Parser;



my $already_there_count;

my $Conf;

use vars qw( $DB $SQL );

###########################################################################
###   s u b   g e t   c o n f i g u r a t i o n
###
sub get_configuration {
  my $app = shift;

  if ( $Conf ) { return $Conf; }

  my $file = $app -> home;
  $file .= '/contributions.conf.xml';

  $Conf = ACIS::Data::DumpXML::Parser -> new -> parsefile ( $file );

  if ( not $Conf ) {
    die "the contributions configuration problem";
  }

  my $types = $Conf ->{types};
  my $aliases = {};

  foreach ( keys %$types ) {
    my $name = $_;
    my $type = $types ->{$_};
    
    foreach ( @{ $type->{aliases} } ) {
      if ( defined $aliases->{$_} ) {
        die "bad contributions configuration";
      }
      $aliases ->{$_} = $name;
    }
  }
  $Conf ->{aliases} = $aliases;

  my $roles = {};
  my @roles = ();
  
  foreach ( keys %$types ) {
    my $name = $_;
    my $type = $types ->{$_};
    
    foreach ( @{ $type->{roles} } ) {
      my $role = $_;
      for ( $roles ->{$_} ) {
        if ( not defined $_ ) {
          $_ = [ $name ];
          push @roles, $role;
        } else {
          push @$_, $name;
        }
      }
    }
  }
  $Conf ->{roles}      = $roles;
  $Conf ->{roles_list} = \@roles;


  ### XXX in place-test
  assert( $roles ->{author} );
  assert( $roles ->{editor} );
  assert( ref $roles ->{editor} );
  assert( scalar ( @{ $roles ->{editor} } ) > 1 );


  $app -> variables ->{'contributions-config-file'} = $file;

  return $Conf;
}




use vars qw( $acis );
*acis = *ACIS::Web::ACIS;

my $accepted;
my $refused;
my $contributions;

sub prepare {
  my $app = shift;

  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record  -> {id};

  $contributions = $session -> {$id} {contributions} || {};

  $accepted = $record ->{contributions} {accepted} || [];
  $refused  = $record ->{contributions} {refused } || [];

  $record -> {contributions} {accepted}  = $accepted;
  $record -> {contributions} {refused}   = $refused;
  

  $SQL = $app -> sql_object;
  $DB  = $app -> config( 'metadata-db-name' );

  if ( not $session -> {$id} {'reloaded-accepted-contributions'} ) {
    if ( scalar @$accepted ) {
      reload_accepted_contributions( $acis );
    }
  }



  ###  make a hash of already accepted contributions and store it into
  ###  'already-accepted' in the session

  my $already_accepted = {}; 

  foreach ( @$accepted ) {
    my $id   = $_ ->{id};
    my $type = $_ ->{type};
    my $role = $_ ->{role};
    
    if ( $already_accepted ->{$id} ) {
      undef $_;  ### double item
    } else {
      $already_accepted ->{$id} = $role;
    }
  }

  clear_undefined $accepted;

  my $already_refused = {}; 
  foreach ( @$refused ) {
    my $id = $_ ->{id};
    if ( $already_refused->{$id} ) {
      undef $_;
    } else { $already_refused -> {$id} = 1; }
  }
  clear_undefined $refused;


  $contributions ->{'already-accepted'} = $already_accepted; 
  $contributions ->{'already-refused' } = $already_refused ; 

  $contributions ->{accepted} = $accepted;
  $contributions ->{refused}  = $refused;
  
  if ( $record -> {contributions} {autosearch} ) {
    $contributions -> {autosearch} = $record -> {contributions} {autosearch};
  }

  ###  make contributions visible
  $vars ->{contributions}
    = $session ->{$id} {contributions} = $contributions;

  delete $contributions -> {actions};

  debug "the contributions accepted and refused are prepared.";

}


sub prepare_the_role_list {
  my $app = shift;

  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record -> {id};
  
  my $conf = get_configuration( $app );

  my $role_list = $conf -> {roles_list};

  $vars -> {'role-list'} = $role_list;
}



sub prepare_configuration {
  my $app = shift;
  
  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record -> {id};

  my $conf = get_configuration( $app );

  $contributions ->{config} {types} = $conf -> {types};
}


use ACIS::Web::SysProfile;

sub get_last_autosearch_time {
  my $app     = $Web::App::APP;
  my $session = $app -> session;
  my $rec     = $session -> current_record;

  my $result  = get_sysprof_value( $rec -> {sid}, "last-autosearch-time" );
  
  if ( not defined $result ) {
    my $contrib = $rec -> {contributions};
    my $as      = $contrib -> {autosearch};
    $result     = $as -> {'last-time-epoch'};
  }
  return $result;
}

########################################################################
########               m a i n    s c r e e n                  #########
########################################################################

sub main_screen {
  my $app = shift;

  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record -> {id};
  my $sid     = $record -> {sid};
  my $input   = $app -> form_input;

  assert( $contributions );
#  my $contributions = $session -> {$id} {contributions};

  my $laststatus = $contributions -> {laststatus} || '';

  my $status = get_search_status( $app );
  ### check search status

  my $last_search = get_last_autosearch_time(); 
  $vars -> {'last-autosearch-time'} = $last_search;

  ### if no search, do this:
  if ( $status ne 'running' ) {

    undef $contributions -> {searching};

    ###  so may be start a search?  will find out.
    debug "may be start a search?";

    my $start = 0;

    {{  #### complex condition check block; last operator exits such block

      debug "did user request it?";
      if ( $input -> {'start-auto-search'} ) { $start = 1; last; }

      debug "is it the first time ever?";
      my $rec_contrib = $record -> {contributions};
      if ( not exists $rec_contrib ->{autosearch} ) { $start = 1; last; }

      ###  a catch
      if ( $rec_contrib ->{autosearch} == 1 ) {
        $rec_contrib ->{autosearch} = {};
      }
      
      debug "never searched before?";
      if ( not defined $last_search )  { $start = 1; last; }
      
      my $time = time;
      debug "last time searched more than two weeks ago? ($time - $last_search)";
      my $diff = $time - $last_search;
      my $day  = 60 * 60 * 24;
      if ( $diff > 14 * $day ) { $start = 1; last; }

      my $last_init = $contributions -> {autosearch} {'for-names-last-changed'};
      my $last_name_change = $record ->{name} {'last-change-date'};

      debug "names changed?";
      if ( defined $last_name_change
           and ( not defined $last_init 
                 or $last_init != $last_name_change) ) {
        $start = 1; last;
      }
      
      debug "none of the above";
    }}

    if ( $start ) {
      debug "yes, do search!";

      $record ->{contributions} {autosearch} = 1;


      require ACIS::Web::Contributions::Back;
      my $r = ACIS::Web::Contributions::Back::start_auto_search( $app );

      if ( $r ) {

        debug "started fine";
        $contributions -> {'auto-search-initiated-in-this-session'} = 1;

        $status = 'auto-search-started';
        $app -> clear_process_queue;
        $app -> redirect_to_screen_for_record( 'research/auto/status' );

        $vars -> {$status} = 1;
        $contributions -> {laststatus} = $status;
        return 1;

      } else {
        debug "start failed";

        $app -> error ( 'auto-search-start-failed' );
        $status = 'auto-search-start-failed';
      }

    } else {

      if ( $laststatus eq 'running' 
           or $laststatus eq 'auto-search-started' ) {
        $status = 'auto-search-finished';
      }

    }

  } else {
    ### if a search is running

    if ( not scalar @$accepted ) {
      $app -> refresh( 60 );
    }
  }

  if ( not $status ) {
    $status = 'auto-search-not-needed';
  }    


  $vars -> {$status} = 1;
  $contributions -> {laststatus} = $status;
  $contributions -> {previousstatus} = $laststatus;


  $vars -> {'current-time-epoch'} = time;

 
  ACIS::Web::Contributions::show_whats_suggested( $app );
}


sub prepare_for_auto_search {
  my $app     = shift;

  debug "prepared for autosearch: enter";

  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};

  assert( $record );
  assert( $id );

  assert( $contributions );
#  my $contributions = $session ->{$id} {contributions} ;

  my $autosearch    = $contributions -> {autosearch};
  { 
    if ( not exists $contributions -> {autosearch} 
         or $autosearch == 1 ) {
      $contributions ->{autosearch} = $autosearch = {}
    }
    $record -> {contributions} {autosearch} = $autosearch;
  }


  debug "preparing namelist";
  my @namelist;

  {
    my $variations = $record -> {name}{variations};
    assert( $variations );
    assert( ref $variations eq 'ARRAY' );
    @namelist = sort { length( $b ) <=> length( $a ) } @$variations;
  }

  $autosearch -> {'names-list'} = \@namelist;

  debug "prepare for auto search: exit";
}


sub auto_search_done {
  my $app     = shift;
  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};

  assert( $contributions );
#  my $contributions = $session ->{$id} {contributions} ;
  my $autosearch    = $contributions -> {autosearch};


  my $time = time;
  use ACIS::Web::SysProfile;
  put_sysprof_value( $record -> {sid}, 
                     'last-autosearch-time', 
                     $time );

  #  $vars -> {'last-autosearch-start-time'} = $time;
  
  my $names_last_change_date = $record -> {name}{'last-change-date'};
  $autosearch -> {'for-names-last-changed'} = $names_last_change_date;
  
}


sub automatic_search {
  my $app = shift;

#  my $sql = $app -> sql_object;

  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};
  my $sid     = $record ->{sid};

  assert( $contributions );
#  my $contributions = $session ->{$id} {contributions} ;

  ACIS::Web::Contributions::prepare_for_auto_search( $app );

  my $autosearch    = $contributions -> {autosearch};

  require ACIS::Web::Contributions::Back;
  ACIS::Web::Contributions::Back::auto_search( $app );
  ACIS::Web::Contributions::auto_search_done( $app );

  return 1;
}





sub get_search_status {
  my $app = shift;

  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record -> {id} ;
  my $sid     = $record -> {sid};

  my $status  = '';

  require ACIS::Web::Background;


  my $trstatus = ACIS::Web::Background::check_thread( $app, $sid );

  debug "get_search_status";

  if ( $trstatus ) {

    my $threads = {};
    foreach ( @$trstatus ) {
      my $t = $_ -> {type};
      $threads -> {$t} = 1;
    }

    if ( $threads -> {'res-autosearch'} 
         or $threads -> {'res-auto-approx'} ) {
      $status = 'running';

      $contributions = $session -> {$id} {contributions};
      $contributions -> {searching} = $threads;

      ###  since what time?
      ###  look in $contributions/... ?
    }
  }

  debug "check research-auto-search status: $status";
  
  return $status;
}




###########################################################################
########   a u t o   s e a r c h   s t a t u s    s c r e e n    ##########
###########################################################################

sub research_auto_status {
  my $app    = shift;
  my $status = get_search_status( $app );
  
  if ( $status eq 'running' ) {
    ###  what is found so far?
#    ACIS::Web::Contributions::show_whats_suggested( $app );
    $app -> refresh( 5 );

  } else {
    ###  no search is going on
    $app -> redirect_to_screen_for_record( 'research/autosuggest' );
  }

}



sub accept_item {
  my $item = shift;
  my $role = shift || $item -> {role};
  
  my $id   = $item -> {id};
  my $sid  = $item -> {sid};

  assert( $contributions );
  assert( $accepted );
  assert( $acis );
#  my $contributions =    ;
#  my $accepted      =    ;
  my $already_accepted = $contributions -> {'already-accepted'};
  my $action;

  
  if ( not exists $already_accepted ->{$id} ) {
    push @$accepted, $item;
    $acis -> userlog( "added contribution: id $id, role $role" );
    $acis -> userlog( "work title: '$item->{title}' (type: $item->{type})" );

    $action = "accepted";

  } else {

    ### do a replace, even though it might be unnecessary
    foreach ( @$accepted ) {
      if ( $_ ->{id} eq $id ) {
        $_ = $item;
        $acis -> userlog( "replaced contribution: id $id, role $role" );
        $acis -> userlog( "work title: '$item->{title}' (type: $item->{type})" );
        $action = "re-accepted";
        last;
      }
    }
  }

  $item -> {role}           = $role;
  $already_accepted ->{$id} = $role;


  if ( $action ) {
    $acis -> sevent(   -class => 'contrib',
                      -action => $action,
($role ne 'author') ? ( -role => $role ) : (),
                       -descr => $item->{title} . " ($item->{type}, $item->{id})",
                         -URL => $item ->{'url-about'},
 (exists $item->{authors}) ? ( -authors  => $item -> {authors} ) : (),
 (exists $item->{editors}) ? ( -editors  => $item -> {editors} ) : (),
                     );
  }

  return $action;
}


sub remove_item {
  my $id   = shift;
  
  assert( $contributions );
  assert( $accepted );
  assert( $acis );
  my $already_accepted = $contributions -> {'already-accepted'};
  my $action;


  ### find it
  my $item;
  my $index;
  { 
    my $i = 0;
    foreach ( @$accepted ) {
      if ( $_ ->{id} eq $id ) {
        $index = $i;
        $item  = $_;
        last;
      }
      $i++;
    }
  }
  
  if ( defined $index 
       and $item ) {

    my $role  = $item ->{role};
    my $title = $item ->{title};
    my $type  = $item ->{type};

    $acis -> userlog( "deleting a contribution: id $id, role $role" );
    $acis -> userlog( "contribution title: '$title' (type: $item->{type})" );
    
    splice @$accepted, $index, 1;

    $action = 'removed';

    $acis -> sevent( -class  => 'contrib',
                     -action => 'removed',
                     -descr  => $title . " ($type, $id)",
                     -URL    => $item ->{'url-about'},
 (exists $item->{authors}) ? ( -authors  => $item -> {authors} ) : (),
 (exists $item->{editors}) ? ( -editors  => $item -> {editors} ) : (),
                   );

  } else {
    debug "looked through accepted list and didn't find the item to delete!";
  }
  
  delete $already_accepted ->{$id};

  return $action;
}



sub refuse_item {
  my $id   = shift;
  my $item = shift;

  assert( $contributions );
  assert( $refused );
  assert( $acis );
  my $already_refused = $contributions -> {'already-refused'};


  if ( not $already_refused ->{$id} ) {

    if ( not $item ) {
      $item = { id => $id };
    }
    
    push @$refused, $item;

    $already_refused ->{$id} = 1;

    $acis -> userlog ( "refuse a contribution: id: $id" );
    
    $acis -> sevent( -class  => 'contrib',
                    -action => 'refused',
                    -descr  => $item->{title} . " ($item->{type}, $id)",
                    -URL    => $item ->{'url-about'},
 (exists $item->{authors}) ? ( -authors  => $item -> {authors} ) : (),
 (exists $item->{editors}) ? ( -editors  => $item -> {editors} ) : (),

                );
  
    return 'refused';
  }
}



###########################################################################
###################   s u b    p r o c e s s    ###########################
###########################################################################

sub process {
  my $app = shift;

  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record -> {id};
  my $psid    = $record -> {sid};

  assert( $contributions );
#  my $contributions = $session -> {$id} {contributions}; 
  
  &get_configuration( $app );

  my $conf = $Conf;

  my $input = $app -> form_input;

  assert( $accepted );
  assert( $refused  );
#  my $accepted = $contributions ->{accepted};
#  my $refused  = $contributions ->{refused};

  my $already_accepted = $contributions -> {'already-accepted'}; 
  my $already_refused  = $contributions -> {'already-refused' }; 

  my $statistics             = {};
  my $clear_from_suggestions = {};
  my $clear_from_suggestions_sid = {};
  

  my $processed = 0;

  my $mode   = $input -> {mode} || '';
  my $source = $input -> {source};

  my $pool;
  if ( $mode eq 'add' ) {
    return if not $source;
    $pool   = $contributions -> {$source};
    debug "suggestions source: $source";
  }


  ###  process contribution additions and deletions

  foreach ( keys %$input  ) {
    my $val = $input -> {$_};


    ########################################################
                                              ###    A D D 
    if ( $_ =~ m/^add_(.+)/ 
         and $val ) {            
      my $tid    = $1;
      my $handle = $input -> {"id_$tid"};
      my $role   = $input -> {"role_$tid"};
      
      if ( $handle
           and $role 
           and $conf -> {roles} {$role} ) {
        ### all correct, but also we could check the item type and...
        
        assert( $source );
        my $item = find_contribution ( $contributions, $handle, $source );

        if ( not $item ) {
          $app -> errlog ( 
"Can't find a contribution among our own suggestions: id: $handle" );
          next;
        }
        
        ### XXX ... should check role appropriateness for this type of object

        $item -> {role} = $role;
        my $sid = $item ->{sid};
        assert( $sid );

        assert( not ref $handle );  ### sanity

        my $action = accept_item( $item );
        $statistics -> {$action} ++;
        $processed++; 

        $clear_from_suggestions  -> {$handle} = 1;
        $clear_from_suggestions_sid -> {$sid} = 1;
      }



      ########################################################
      #####################################   E D I T I N G 
    } elsif ( $mode eq 'edit'                           
              and $_ =~ m/^role_(.+)/
              and not exists $input ->{"remove_$1"} ) {

      my $tid    = $1;
      my $handle = $input -> {"id_$tid"};
      my $role   = $input -> {"role_$tid"};
      
      if ( $handle and $val 
           and $role 
           and $conf -> {roles} {$role} ) {
        ### all correct, but also we could check the item type and

        if ( exists $already_accepted ->{$handle} ) {
           foreach ( @$accepted ) {
             if ( $_ ->{id} eq $handle ) {
               my $item = $_;
               my $action = accept_item( $item, $role );
               $statistics -> {$action} ++;
               last;
             }
           }
        }
        $processed++; 
      }

      #######################################################
    } elsif ( $_ =~ m/^remove_(.+)/ ) { ###   R E M O V E 

      debug "remove $1";

      my $tid    = $1;
      my $handle = $input -> {"id_$tid"};

      if ( $handle and $val
           and $already_accepted ->{$handle} ) {
        
        my $action = remove_item( $handle );
        if ( $action eq 'removed' ) {
          $statistics -> {removed} ++;
        }
        $processed++; 

      } else {
        $app -> errlog( "not in already accepted list: $handle!" );
      }
        

      
      ###########################################################
    } elsif ( $_ =~ m/^refuse_(.+)/ ) {   ###   R E F U S E  
      my $tid    = $1;
      my $handle = $input -> {"id_$tid"};

      if ( $handle and $val ) {

        assert( $source );
        my $item = find_contribution ( $contributions, $handle, $source );
        my $sid  = $item -> {sid};

        if ( not $item ) {
          $app -> errlog (
 "Can't find a contribution among our own suggestions: id: $handle" );
        }
        
        refuse_item( $handle, $item );

        $statistics ->{refused} ++;
        $clear_from_suggestions -> {$handle} = 1;
        if ( $sid ) {  $clear_from_suggestions_sid->{$sid}  = 1;  }

        $processed++; 
      }

    }  ###  not "add_...", not "remove_...", not "refuse_..." param
      
  }  ####  end of the main parameters pass



  if ( $mode eq 'add' ) {
    my $refuse = $input ->{'refuse-ignored'};

    foreach ( keys %$input  ) {
      my $val = $input -> {$_};
      
      if ( $_ =~ m/^id_(.+)/ ) {
        my $tid    = $1;
        my $handle = $val;
        if ( $tid and $handle and not $input -> {"add_$tid"} ) {

          assert( $source );
          ###  find it
          my $item = find_contribution ( $contributions, $handle, $source );

          if ( $refuse ) {
            refuse_item( $handle, $item );
            $statistics ->{refused} ++;
          }

          $clear_from_suggestions -> {$handle} = 1;

          if ( $item ) {
            my $sid  = $item -> {sid};
            if ( not $sid ) {
              my $id = $item ->{id};
              warn "Document $id had no sid: " . $item->{title};
            } else {
              $clear_from_suggestions_sid ->{$sid} = 1;
            }
          }

          $processed++; 
        }
      }
    }
  }

  $contributions -> {actions} = $statistics;

  my $sug_count = clear_some_suggestions ( $contributions, $clear_from_suggestions );

  require ACIS::Web::Contributions::Back;

  ACIS::Web::Contributions::Back::clear_from_autosearch_suggestions
      ( $app, $psid,
        $clear_from_suggestions_sid );


  if ( $processed ) {
    $app -> success( 1 );

    if ( $statistics -> {accepted} ) {
      $app -> message( 'research-items-added' );

    } elsif ( $statistics -> {'re-accepted'} ) {
      $app -> message( 'research-items-replaced' );

    } elsif ( $statistics -> {removed} ) {
      $app -> message( 'research-items-removed' );

    } elsif ( $statistics -> {refused} ) {
      $app -> message( 'research-items-refused' );

    } else {
      $app -> message( 'research-decisions-processed' );
    }      

    if ( $session -> type eq 'new-user' 
         and not $sug_count ) {
      $app -> set_presenter( 'research/ir-guide' );
    }

  }


}

sub current_process {
  my $app = shift;
  if ( $app -> success() ) {
  }
}



sub switch {
  my $app = shift;

  my $session = $app -> session;
  my $vars    = $app -> variables;

  my $input   = $app -> form_input;

  if ( $input ->{continue} 
       or $input ->{'move-on'} ) {
    if ( $session->type eq 'new-user' ) {
      $app -> redirect_to_screen( 'new-user/complete' );
    } else {
      $app -> redirect_to_screen_for_record( 'menu' );
    }
  }
  
}




sub find_contribution {  ###  among suggestions
  my $contributions = shift;
  my $id            = shift;
  my $source        = shift;

  assert( $id ,    '$id is untrue');
  assert( $source, '$source is untrue');

  my $item;

  my $suggest = $contributions ->{suggest};
  my $search  = $contributions ->{search} ;

  if ( $source eq 'suggestions' ) {
    foreach my $list ( @$suggest ) {
      foreach $item ( @{ $list -> {list} } ) {
        if( $item ->{id} eq $id ) { return $item; }
      }
    }

  } elsif ( $source eq 'search' ) {
    foreach $item ( @{ $search -> {list} } ) {
      if( $item ->{id} eq $id ) { return $item }
    }
  }

  return $item;
}





sub clear_some_suggestions {
  my $contributions = shift;
  my $to_clear      = shift;

  my $hash_to_clear = {};
  if ( ref $to_clear eq 'ARRAY' ) {
    foreach ( @$to_clear ) {
      $hash_to_clear -> {$_} = 1;
    }

  } elsif ( ref $to_clear eq 'HASH' ) {
    $hash_to_clear = $to_clear;

  } else { die; }
  
  
  my $suggest = $contributions -> {suggest};
  my $count_total = 0;
  my @clean_suggest = ();

  foreach ( @$suggest ) {
    my $count = 0;
    my $listlist = $_ ->{list};
    
    foreach ( @$listlist ) {
      my $id = $_ ->{id};
      if ( exists $hash_to_clear ->{$id} ) {
        undef $_;
      } else {
        $count++;
        $count_total++;
      }
    }
    clear_undefined $listlist;
    
    if ( not $count ) {
      undef $_;
    }
  }

  clear_undefined $suggest;

  return $count_total;
}





sub reload_if_nothing_to_suggest {
  my $app = shift;

  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record -> {id};
  
  assert( $contributions );
#  my $contributions = $session -> {$id} {contributions};
  
  my $sug = $contributions -> {suggest};

  if ( not $sug
       or not scalar @$sug ) {
    reload_to_main_after_a_while( $app );

  } else {
    ###  I need this because process() might have set another presenter and
    ###  might have set a message which we don't really need on this screen

    $app -> message( 0 );
    $app -> set_presenter( "research/autosuggest-1by1" );
  }

}


sub reload_to_main_after_a_while {
  my $app = shift;
  my $url = $app -> get_url_of_a_screen( 'research' );
  $app -> refresh( 20, $url );
}



############################################################################
###   s u b    S E A R C H    #
############################################################################

sub search {
  my $app = shift;
  
  my $sql     = $app -> sql_object;

  my $input   = $app -> form_input;
  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{id};


  ###  preparations

  my %found_ids;
  my $search ;

  ###  prepare( ) is run by screen config

  get_configuration( $app );
  my $conf = $Conf;

  assert( $contributions );
#  my $contributions = $session ->{$id} {contributions} ;

  my $current_index   = $contributions -> {'already-accepted'};
  my $already_refused = $contributions -> {'already-refused' };

  my $ignore_index = {};
  foreach ( keys( %$current_index ), keys %$already_refused ) {
    $ignore_index ->{$_} = 1;
  }

  my $metadata_db = $app -> config( 'metadata-db-name' );

  assert( $metadata_db, "metadata-db-name must be defined" );
  my $context = {
    db      => $metadata_db,
    found   => \%found_ids,
    already => $ignore_index,
  };

  

  ###  analyse the input 

  my $search_type = 'resources';
  my $objects     = 'resources';
  my $table;

  my $search_key = $input -> { q };    
  my $field      = $input -> { field } || '';
  my $phrasematch= $input -> { phrase } || 0;
  
  if ( $field eq 'id' ) {
    $phrasematch = 1;
  }

  ###  do the search

  if ( $search_type eq 'resources'
       and $search_key 
       and $field ) {
    my $res = search_documents( $sql, $context, $search_key, $field, $phrasematch );

    $search = {
                reason => "res-search-$field",
                field  => $field,
                list   => $res,
#                role   => 'author',
                key    => $search_key,
           phrasematch => ( $phrasematch ) ? 'yes' : 'no',
               objects => $objects,
               };

    $contributions ->{search} = $search;

  }
  

  $contributions ->{config} {types} = $conf -> {types};
}






############################################################################
###   s u b    r e l o a d   a c c e p t e d   c o n t r i b u t i o n s   #
############################################################################

sub reload_accepted_contributions {
  my $app = shift;

  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record -> {id};

  my $metadata_db = $app -> config( 'metadata-db-name' );

  if ( $session ->{$id}{contributions}{reloaded} ) { return 1; }
  $session ->{$id}{contributions}{reloaded} = 1;


  my $accepted = $record ->{contributions}{accepted};

  my $accepted_size_before = scalar @$accepted;

  foreach ( @$accepted ) {
    my $item = $_;
    my $id   = $_ ->{id};
    my $type = $_ ->{type};
    my $role = $_ ->{role};
    
    $_ = reload_contribution( $app, $id, $type, $metadata_db );
    if ( $_ ) {
      $_ ->{role} = $role;
      
    } else {
      debug "contribution $id can't be reloaded";

      my $title = $item ->{title};

      $app -> userlog( "clearing a contribution: id $id, role $role" );
      $app -> userlog( "contribution: '$title' (type: $item->{type})" );
      
      $app -> sevent( -class  => 'contrib',
                      -action => 'cleared lost',
                      -descr  => $title . " ($type, $id)",
                      -URL    => $item ->{'url-about'},
 (exists $item->{authors}) ? ( -authors  => $item -> {authors} ) : (),
 (exists $item->{editors}) ? ( -editors  => $item -> {editors} ) : (),
                    );
      
    }
  }
  
  clear_undefined $accepted;

  my $accepted_size_after = scalar @$accepted;
  if ( $accepted_size_after < $accepted_size_before ) {
    debug "some lost items removed";
  }

  if ( scalar @$accepted ) {
    debug "the contributions accepted are reloaded from the database.";
  }
  
  $session -> {$id} {'reloaded-accepted-contributions'} = 1;
}



############################################################################
###   h e l p f u l   s q l   s e a r c h   u t i l i t y   f u n c s    ###
############################################################################

use Encode;
use Storable qw( freeze thaw );

use vars qw( $select_what );

$select_what = "select id,sid,data ";
my $SELECT_WHAT = $select_what;



sub make_resource_item_from_db_row {
  my $row = shift;
  assert( $row );

  my $data = $row ->{data};
  my $id   = $row ->{id};
  my $role = $row ->{role};
#  my $sid  = $row ->{sid};

  if ( not $data ) {
#    warn "'data' field is empty, that's db problem";
    return undef;

  } else {
    my $item;
    eval { $item = thaw ( $data ); };

    if ( $@ ) { 
      warn "failed to thaw() a database-loaded resource record: $@";
      $item = $row; 
      delete $row ->{data}; 
      undef $@; 
    }

    $item -> {id}  = $id;
    if ( $role ) { $item -> {role} = $role; }

    return $item;
  }
}




sub reload_contribution {
  my $app  = shift;
  my $id   = shift;
  my $type = shift;
  my $db   = shift;

  assert( $id   );
  assert( $db   );

  my $sql  = $app ->sql_object;

#  ###  now, useless
#  my $document_types = {
#    'paper'    => 1,
#    'article'  => 1,
#    'software' => 1,
#    'book'     => 1,
#    'chapter'  => 1,
#  };

  my $item;
    
#  $sql -> prepare_cached ( "$select_what from $db.resources where id=?" );
  $sql -> prepare_cached ( "select data from $db.objects where id=?" );
  warn "SQL: " . $sql->error if $sql->error;
  my $res = $sql -> execute ( $id );
  warn "SQL: " . $sql->error if $sql->error;
  
  my $row = $res -> {row};
  if ( $row ) {
    if ( $row->{data} ) {
      $item = thaw $row->{data};
    }

  } else {
    debug "didn't find $id";
  }

  return $item;
}



sub load_resources_by_ids {
  my $app  = shift;
  my $ids  = shift;

  assert( $ids and ref $ids );
  
  my @list;

    
#  $SQL -> prepare_cached ( "$SELECT_WHAT FROM ${DB}.resources WHERE id=?" );
  $SQL -> prepare_cached ( "SELECT data FROM ${DB}.objects WHERE id=?" );

  foreach ( @$ids ) {

    my $res = $SQL -> execute ( $_ );
    if ( $SQL ->error ) { 
      warn "SQL: " . $SQL-> error ;
      ###  XX  go next?
    }
    my $row = $res -> {row};

    if ( $row and $row->{data} ) {
      my $item = thaw $row->{data};
#      my $item = make_resource_item_from_db_row ( $row );
      push @list, $item;
      
    } else {
      debug "didn't find $_";
    }
    
  }

  return \@list;
}



sub query_resources ($$) {
  my $table = shift;
  my $where = shift;

  if ( $table eq 'resources' ) {

    return qq!SELECT catch.id as id,lib.data as data
FROM $DB.$table as catch
LEFT JOIN $DB.objects as lib
 ON catch.id = lib.id
WHERE $where
!;
  }
  
  ###  the query
  return qq!
SELECT lib.id as id,lib.data as data,catch.role as role
FROM $DB.$table as catch 
LEFT JOIN $DB.resources as lookup
 ON catch.sid = lookup.sid
LEFT JOIN $DB.objects as lib
 ON lookup.id = lib.id
WHERE $where
! ;

}



sub search_resources_for_exact_name {
  my $sql     = shift;
  my $context = shift;
  my $name    = shift;

  my $result = [];


  ###  the query
  $sql -> prepare_cached( 
     query_resources 'res_creators_separate', 'catch.name = ?'  
                        );
  
  warn "SQL: " . $sql->error if $sql->error;
  my $res = $sql->execute ( lc $name );
  warn "SQL: " . $sql->error if $sql->error;

  if ( $res ) {
    debug "query for exact creator name: '$name', found: " . $res -> rows . " items";
    process_resources_search_results( $res, $context, $result );
  }

  return $result;
}
  


sub search_resources_by_creator_email {
  my $sql     = shift;
  my $context = shift;
  my $email   = shift;

  my $result  = [];


  ###  the query
  $sql -> prepare_cached( 
     query_resources 'res_creators_separate', 'catch.email = ?'  
                        );
  
#  warn "SQL: " . $sql->error if $sql->error;
  my $res = $sql->execute ( lc $email );
#  warn "SQL: " . $sql->error if $sql->error;

  if ( $res ) {
    debug "query for exact creator email: '$email', found: " . $res -> rows . " items";
    process_resources_search_results( $res, $context, $result );
  }

  return $result;
}
  




####   There's very little point in such search.  I guess fulltext search
####   would have been more reasonable.

sub search_resources_for_exact_phrase {
  my $sql  = shift;
  my $context = shift;
  my $name = shift;

  my $result = [];

  ###  regular expression
  my $re = '[[:<:]]'. lc $name . '[[:>:]]';

  ###  the query
  $sql -> prepare_cached( 
     query_resources 'res_creators_separate', 'catch.name regexp ?'  
                        );
  
  warn "SQL: " . $sql->error if $sql->error;
  my $res = $sql->execute ( $re );
  warn "SQL: " . $sql->error if $sql->error;

  if ( $res ) {
    debug "query for exact phrase in creator names: '$name', found: " . $res -> rows . " items";
    process_resources_search_results( $res, $context, $result );
  }

  return $result;
}
  

sub search_resources_for_exact_phrases {
  my $sql      = shift;
  my $context  = shift;
  my $namelist = shift;

  my $result = [];

  my $list = join( '|', @$namelist ) ;

  ###  regular expression
  my $re = '[[:<:]]('. $list . ')[[:>:]]';

  ###  the query
  $sql -> prepare_cached( 
     query_resources 'res_creators_separate', 'catch.name regexp ?'  
                        );

  warn "SQL: " . $sql->error if $sql->error;
  my $res = $sql->execute ( $re );
  warn "SQL: " . $sql->error if $sql->error;

  if ( $res ) {
    debug "phrase search in creators' names, found: " . $res -> rows . " items";
    process_resources_search_results( $res, $context, $result );
  }

  return $result;
}
  



sub search_resources_for_name_word_fulltext {
  my $sql     = shift;
  my $context = shift;
  my $query   = shift;

  my $result = [];

  ###  the query
  $sql -> prepare_cached( 
     query_resources 'res_creators_bulk', "match( names ) against( ? )" 
                        );
  
  warn "SQL: ". $sql->error if $sql->error;
  my $res = $sql->execute ( $query );
  warn "SQL: ". $sql->error if $sql->error;
  
  if ( $res ) {
    debug "creators' names word search: '$query', found: " . $res -> rows . " items";
    process_resources_search_results( $res, $context, $result );
  }

  return $result;
}
  



sub search_resources_for_a_name_substring {
  my $sql     = shift;
  my $context = shift;
  my $substr  = shift;

  my $result = [];

  ###  the query
  $sql -> prepare_cached( 
     query_resources 'res_creators_bulk', 'catch.names rlike ?'  
                        );
  ###                               rlike is the same as regexp

  
  warn "SQL: " . $sql->error if $sql->error;
  my $res = $sql->execute ( lc $substr );
  warn "SQL: " . $sql->error if $sql->error;
  
  if( $res ) {
    debug "creators' names substring search: '$substr', found: " . $res -> rows . " items";
    process_resources_search_results( $res, $context, $result );
  }

  return $result;
}
  



sub search_documents {
  my $sql     = shift;
  my $context = shift;
  my $key     = shift;
  my $field   = shift;
  my $phrase  = shift || 0;

  my $result = [];

  my $table;
  if ( $field eq 'names' ) {
    
    if ( $phrase ) {
      $table = 'res_creators_separate'; 
      $field = 'name';  

    } else { 
      $table = 'res_creators_bulk';
      $field = 'names';  
    }
    
  } elsif ( $field eq 'id'      ) { $table = 'resources';    }
    elsif ( $field eq 'title'   ) { $table = 'resources';    }
  
  my $where; 

  if ( $phrase ) { 
    $key = "$key";
    $where = "catch.$field rlike ?";

  } else {
    $where = "match ( catch.$field ) against ( ? )";
  }

  my $query = query_resources $table, "$where LIMIT 501";

  ###  the query
  $sql -> prepare_cached( $query );

  debug "Q: $query";
  
  warn "SQL: " . $sql->error if $sql->error;
  my $res = $sql->execute ( $key );
  warn "SQL: " . $sql->error if $sql->error;

  if( $res ) {
    debug "query for $field match: '$key' ($phrase), found: " . 
         $res -> rows . " items";
    process_resources_search_results( $res, $context, $result );
  }

  return $result;
}





sub process_resources_search_results {
  my $sqlres  = shift;
  my $context = shift;

  my $result  = shift;  ## array ref

  my $found_hash     = $context ->{found};
  my $current_hash   = $context ->{already};

  my $row;
  while ( $row = $sqlres->{row} ) {
    my $id  = $row -> {id};
    
    if ( $found_hash  ->{$id}++ ) { next; }

    if ( $current_hash->{$id} ) {
      $already_there_count++;
      next;
    }
    
#    debug "making resource item (sid:$sid)";
    my $item = make_resource_item_from_db_row( $row );
    
    push @$result, $item;
    
  } continue {
    $sqlres -> next;
  }
    
  $sqlres -> finish;
}




sub process_resources_search_results_wo_filter {
  my $sqlres  = shift;
  my $result  = [];  ## array ref

  my $row;
  while ( $row = $sqlres->{row} ) {

#    my $id  = $sqlres -> get( 'id' );
#    my $sid = $sqlres -> get( 'sid' );

    my $data = make_resource_item_from_db_row ( $row );
    $row -> {data} = $data;
    
    push @$result, $row;
    
  } continue {
    $sqlres -> next;
  }
    
  $sqlres -> finish;

}




#############################################################################



sub show_whats_suggested {
  my $app = shift;

  debug "show_whats_suggested: enter";

  my $vars    = $app -> variables;
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record -> {id};
  my $sid     = $record -> {sid};

  assert( $contributions );
#  my $contributions = $session -> {$id} {contributions};

  ACIS::Web::Contributions::prepare_configuration( $app );

  require ACIS::Web::Contributions::Back;

  my $suggestions = ACIS::Web::Contributions::Back::load_suggestions_into_contributions ( $app, $sid, $contributions );

  my $groups = scalar @$suggestions;
  debug "found groups: $groups";

#  my $status = ACIS::Web::Background::check_thread( $app, $sid, 'contributions' );
#
#  if ( $status ) {
#    $vars -> {'back-search-status'} = $status;
#  }

  debug "show_whats_suggested: exit";
}










###############   create a new session and userdata and delete it afterwards


sub init_search_test_prepare {
  my $app = shift;

  my $vars    = $app -> variables;
  my $config  = $app -> config;
  my $request = $app -> request;
  my $cgi     = $request -> {CGI};

  my $owner = {};

  $owner -> {login} = 'contributions_init_search_test';
  $owner -> {IP}    = $ENV {'REMOTE_ADDR'};

  my $session = $app -> start_new_session ( $owner, "user" );
  
  $session -> object_set (  ACIS::Web::UserData -> new() );
}


sub fix_record {
  my $app = shift;
  my $session = $app -> session;
  my $record  = $session -> current_record;
  $record -> {sid} = 'pst007';
}


sub init_search_test_finish {
  my $app = shift;
  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;

  $session -> close;
  $app -> {session} = undef;

  $vars -> {name} = $record->{name};
}





1;

__END__

##############  THE BASEMENT  #####################################


