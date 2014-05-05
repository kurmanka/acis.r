package ACIS::Web::Contributions;  ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    The Contributions profile.
#
#
#  Copyright (C) 2003-2009 Thomas Krichel for ACIS project,
#  http://acis.openlib.org/
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

use strict;
use Carp qw( cluck );
use Carp::Assert;
use Data::Dumper;

use Web::App::Common;
require ACIS::Data::DumpXML::Parser;


use sql_helper;
use ACIS::Resources::AutoSearch;
use ACIS::Resources::Search;
use ACIS::Resources::Suggestions;
use ACIS::Web::Citations;

use IO::Socket::UNIX;

use Storable;
my $Conf;

use vars qw( $DB $SQL );

###########################################################################
###   s u b   g e t   c o n f i g u r a t i o n
###
sub get_configuration {
  my $app = shift;
  if ( $Conf ) { 
      return $Conf; 
  }
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
        } 
        else {
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

  $app -> variables ->{'contributions-config-file'} = $file;

  return $Conf;
}


use vars qw( $acis );
*acis = *ACIS::Web::ACIS;

my $accepted;
my $refused;
my $contributions;

sub cleanup {
  undef $contributions;
  undef $accepted;
  undef $refused;
}


sub prepare {
  my $app = shift;

  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;

  return if not $record;
  my $id      = $record ->{'id'}; 
  my $sid     = $record ->{sid};
  assert( $id );
  
  # suggestions counts: get from sysprof, put into session (but only do that once)
  if ($sid) {
      if ( not $session->{$sid} 
           or not defined $session->{$sid}{"research-suggestions-total"} ) {
          my $counts = get_sysprof_values( $sid, 'research-suggestions-' );
          my $count_total = $counts->{'research-suggestions-total'} || 0;
          my $count_exact = $counts->{'research-suggestions-exact'} || 0;
          debug "got suggestions counts for $sid: total: $count_total, exact: $count_exact";
          $session->{$sid}{"research-suggestions-total"} = $count_total;
          $session->{$sid}{"research-suggestions-exact"} = $count_exact;

          # make the above always available to the presenter:
          $session->make_sticky( $sid );
      }
  }

  #
  # process the chunk information
  #
  &change_or_delete_chunk($app);

  $contributions = $session -> {$id} -> {'contributions'} || {};

  $accepted = $record ->{'contributions'} -> {'accepted'} || [];
  $refused  = $record ->{'contributions'} -> {'refused' } || [];


  $record -> {'contributions'} -> {'accepted'}  = $accepted;
  $record -> {'contributions'} -> {'refused'}   = $refused;
  
  $SQL = $app -> sql_object;
  $DB  = $app -> config( 'metadata-db-name' );

  if ( not $session -> {$id} {'reloaded-accepted-contributions'} ) {
    if (scalar @$accepted ) {      
      reload_accepted_contributions( $acis );
    }
  }

  ###  make a hash of already accepted contributions and store it into
  ###  'already-accepted' in the session

  my $already_accepted = {}; 
  foreach my $key ( @$accepted ) {
    my $id   = $key ->{'id'};
    my $type = $key ->{'type'};
    my $role = $key ->{'role'};
    
    if (not $id) {
	debug Dumper( $key );
	next;
    }
    
    if ( $already_accepted ->{$id} ) {
        undef $key;  ### double item
    } 
    else {
        $already_accepted ->{$id} = $role;
    }
  }

  clear_undefined $accepted;

  my $already_refused = {}; 
  foreach my $item ( @$refused ) {
    my $id = $item ->{'id'};
    if ( not defined $id ) {
      undef $item;
    } elsif ( $already_refused->{$id} ) {
      undef $item;
    } 
    else { 
        $already_refused -> {$id} = 1; 
    }
  }
  clear_undefined $refused;


  $contributions->{'already-accepted'} = $already_accepted; 
  $contributions->{'already-refused' } = $already_refused ; 

  $contributions->{'accepted'} = $accepted;
  $contributions->{'refused'}  = $refused;
  
  if ( $record -> {'contributions'} -> {'autosearch'} ) {
    $contributions -> {'autosearch'} = $record -> {'contributions'} -> {'autosearch'};
  }
  
  ###  make contributions visible
  $vars ->{'contributions'} = $session ->{$id}->{'contributions'} = $contributions;
  
  delete $contributions -> {'actions'};
  
  debug "the contributions accepted and refused are prepared in prepare()";
  
}


#sub prepare_accepted {
#  my $app = shift;
#  my $rec = $app -> session -> current_record;
#  my $vars = $app-> variables;
#  # prepare citations data, if citations are enabled in configuration and if there are some
#  if ( $app ->config( 'citations-profile' ) or $app->session->owner->{type}{citations} ) {
#    ACIS::Web::Citations::prepare();
#    ACIS::Web::Citations::prepare_research_identified();
#  }
#}

sub prepare_the_role_list {
  my $app = shift;
  
  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record -> {'id'};
  
  my $conf = get_configuration( $app );
  
  my $role_list = $conf -> {roles_list};
  
  $vars -> {'role-list'} = $role_list;
}



sub prepare_configuration {
  my $app = shift;
  
  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record -> {'id'};
  
  my $conf = get_configuration( $app );
  
  $contributions ->{'config'} -> {'types'} = $conf -> {'types'};
}


use ACIS::Web::SysProfile;


########################################################################
########               m a i n    s c r e e n                  #########
########################################################################

sub find_suggested_item {  # look in suggestions or search results
  my $contributions = shift;
  my $id            = shift;
  my $source        = shift;
  assert( $id ,    '$id is untrue');
  assert( $source, '$source is untrue');

  my $suggest = $contributions ->{'suggest'};

  my $search  = $contributions ->{'search'} ;
  #debug "\$search is";
  #debug Dumper $search;
  #my $listlist = ($source eq 'suggestions')
  #                    ? $suggest
  #                    : [ $search ];

  my $listlist;
  if($source eq 'suggestions') {
    #debug "the source is suggestions";
    $listlist=$suggest;
    #debug "\$suggest is";
    #debug Dumper $suggest; 
  }
  else {
    #debug "the source is search";
    $listlist= [ $search ];
    #debug "\$search is";
    #debug Dumper $search;
  }
  foreach my $list ( @$listlist ) {
    foreach my $item ( @{ $list -> {'list'} } ) {
      if( $item ->{'id'} eq $id ) {
        return $item; 
      }
    }
  }
  return undef;
}


#
#  look in suggestions or search results
#
sub find_refused_item {
  my $id = shift;
  assert( $id ,    '$id is untrue');
  assert( $refused,'$refused is untrue');

  #debug "find_refused_item: $id";

  foreach my $key ( @{ $refused } ) {
    #debug "key is" . Dumper $key;
    my $my_id=$key -> {'id'};
    if( $my_id eq $id ) {
      return $key; 
    }
  }
  return undef;
}



#
# look in suggestions or search results
#
sub find_accepted_item { 
  my $id = shift;
  assert( $id, '$id is untrue');
  #assert( $accepted,'$accepted is untrue');
  debug "find_accepted_item: $id";

  foreach my $item ( @{ $accepted } ) {
    #debug "item is" . Dumper $item;
    next if not $item->{id};
    if( $item ->{'id'} eq $id ) {
      #debug "id is $item->{'id'}";
      return $item; 
    }
  }
  return undef;
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

  } 
  else { 
      die; 
  }
  
  
  my $suggest = $contributions -> {suggest};
  my $count_total = 0;
  my $removed_total = 0;
  my $removed_exact = 0;
  my @clean_suggest = ();

  foreach my $key ( @$suggest ) {
    my $count = 0;
    my $listlist = $key ->{'list'};
    
    foreach my $item ( @$listlist ) {
      my $id = $item ->{'id'};
      if ( exists $hash_to_clear ->{$id} ) {
        undef $item;
        $removed_total++;
        if ($key->{exact}) { $removed_exact++; }
      } else {
        $count++;
        $count_total++;
      }
    }
    clear_undefined $listlist;
    
    if ( not $count ) {
      undef $key;
    }
  }

  clear_undefined $suggest;

  # suggestions counts: update the counters after clearing some suggestions
  $contributions->{'suggestions-count-total'} -= $removed_total;
  $contributions->{'suggestions-count-exact'} -= $removed_exact;

  return $count_total;
}


sub research_auto_status {
  my $app    = shift;
  my $status = get_bg_search_status( $app );
  if ( $status eq 'running' ) {
    # maybe show what is found so far?
    #show_whats_suggested( $app );
    $app -> refresh( 5 );
  } else {
    ## no search is going on, old code
    #$app -> redirect_to_screen_for_record( 'research/autosuggest' );
    # no search is going on, old code
    $app -> redirect_to_screen( 'research/autosuggest' );
  }
}



sub main_screen {
  my $app = shift;
  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record -> {'id'};
  my $sid     = $record -> {sid};
  my $input   = $app -> form_input;

  #debug "this is the input";
  #debug Dumper $input;


  assert( $contributions );
  # my $contributions = $session -> {$id} {contributions};

  my $laststatus = $contributions -> {laststatus} || '';

  my $status = get_bg_search_status( $app );
  ### check search status

  my $last_search = get_last_autosearch_time(); 
  $vars -> {'last-autosearch-time'} = $last_search;

  ### if no search, do this:
  if ( $status ne 'running' ) {

    ###  so may be start a search?  will find out.
    debug "may be start a search?";

    my $start = 0;

    {{  #### complex condition check block; last operator exits such block

      debug "did user request it?";
      ## debug $input;
      ##my $string=Dumper $input;
      ##debug $string;
      if ( $input -> {'start-auto-search'} ) {
          $start = 1; 
          last;
      }
      debug "is it the first time ever?";
      my $rec_contrib = $record -> {'contributions'};
      if ( not exists $rec_contrib ->{'autosearch'} ) {
          $start = 1; 
          last; 
      }
      ###  a catch
      if ( $rec_contrib ->{'autosearch'} == 1 ) {
        $rec_contrib ->{'autosearch'} = {};
      }
      
      debug "never searched before?";
      if ( not defined $last_search )  {
        $start = 1;
        last;
      }
      
      my $time = time;
      debug "last time searched more than two weeks ago? ($time - $last_search)";
      my $diff = $time - $last_search;
      my $day  = 60 * 60 * 24;
      if ( $diff > 14 * $day ) { 
        $start = 1;
        last;
      }
 
      my $last_init = $contributions -> {autosearch} {'for-names-last-changed'};
      my $last_name_change = $record ->{name} {'last-change-date'};

      debug "names changed?";
      if ( defined $last_name_change
           and ( not defined $last_init 
                 or $last_init != $last_name_change) ) {
        $start = 1; last;
      }
      
      debug "none of the above";
    }
   }

    if ( $start ) {
      debug "yes, do search!";
      $record ->{contributions} {autosearch} = 1;

      my $r = start_auto_res_search_in_bg( $app );

      if ( $r ) {
        debug "started fine";
        $contributions -> {'auto-search-initiated-in-this-session'} = 1;

        $status = 'auto-search-started';
        $app -> clear_process_queue;
        $app -> redirect_to_screen_for_record( 'research/auto/status' );
        $vars -> {$status} = 1;
        $contributions -> {'laststatus'} = $status;
        return 1;
      } 
      else {
        debug "start failed";
        $app -> error( 'auto-search-start-failed' );
        $status = 'auto-search-start-failed';
      }      
    } 
    else {      
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


###########################################################################
########   a u t o   s e a r c h   s t a t u s    s c r e e n    ##########
###########################################################################

# check if the personal name (from the record) is mentioned as an
# author (or an editor) of the document. Return 1 if it is, 0 otherwise.
sub check_item_names {
    my $item = shift;
    my $record = $acis->session->current_record || die;
    # XXX here we could (should?) check if the names-list is up-to-date
    my $names  = $record -> {contributions}{autosearch}{'names-list-nice'} 
       || die Dumper($record);

    my $authors = lc $item->{authors} || '';
    my $editors = lc $item->{editors} || '';

    return 0 if not $authors and not $editors; # could happen in series

    my $is_present = 0;
    foreach ( @$names ) {
        if ( index( $authors, lc $_ ) > -1 ) { $is_present = 1; last; }
        if ( index( $editors, lc $_ ) > -1 ) { $is_present = 1; last; }
        # XXX instead of using index() here we could have done a split
        # on the ampersand and make sure the user name is present in
        # the resource' data as a full string.
    }

    # Issue #24 https://github.com/kurmanka/acis.r/issues/24
    # Check the same, but this time ignore the punctuation characters.
    # "np" means "no punctuation"
    if ( not $is_present ) {
      debug "do a no-punctuation check on the contributor names";
      my $names_np = [ @$names ]; # copy the list
      my $authors_editors_np = ' ';
      for( $authors, $editors ) {
        $_ =~ s/[,\.\-]/ /g;
        $_ =~ s/\s+/ /g;
        $authors_editors_np .= $_;
      }
      
      for (@$names_np) {
        $_ =~ s/[,\.\-]/ /g;
        $_ =~ s/\s+/ /g;
      }

      debug "authors editors np: $authors_editors_np";
      debug "nice names np: ", join( "\n", @$names_np );
            
      foreach ( @$names_np ) {
        if ( index( $authors_editors_np, lc $_ ) > -1 ) { $is_present = 1; last; }
      }
    }

    # debug suspicious claim detection (now disabled):
    if ( 0 and not $is_present ) {
        my $app = $ACIS::Web::ACIS;
        $app-> log( "check_item_names: $authors" ) if $authors;
        $app-> log( "check_item_names: $editors (editors)" ) if $editors;
        foreach ( @$names ) {
            $app -> log( "name: <", lc $_, ">" );
        }
    }

    return $is_present;
}


sub accept_item {
  my $item = shift;
  my $role = shift || $item -> {'role'};
  if (not $role) { 
      debug "no role value at accept_item()";
  }
  
  my $id   = $item -> {'id'};
  my $sid  = $item -> {sid};

  assert( $contributions );
  assert( $accepted );
  assert( $acis );
  my $already_accepted = $contributions -> {'already-accepted'};
  my $action;
  my $event_type;

  my $type = $item ->{type};

  ### check role appropriateness for this type of object
  eval { 
    if ( not $Conf
         or not $Conf->{types} 
         or not $Conf->{types} {$type} ) {
      undef $Conf;
      $Conf = get_configuration( $acis );
    }
    my $roles = $Conf -> {types} {$type} {roles};
    my $ok;
    foreach ( @$roles ) {
      if ( $_ eq $role ) { $ok = 1; }
    }
    if ( not $ok ) {
      cluck "Didn't find role $role among permitted roles for type $type";
      debug "Didn't find role $role among permitted roles for type $type";
    }
  };

  if ( $role eq 'editor' 
       and $type eq 'chapter' ) {
    warn  "chapter editor again!";
    debug "chapter editor again!";
  }
  
  if ( not exists $already_accepted ->{$id} ) {
    push @$accepted, $item;
    $acis -> userlog( "added contribution: id $id, role $role" );
    $acis -> userlog( "work title: '$item->{title}' (type: $item->{type})" );
    $action = "accepted";
    require ACIS::Web::Citations;
    ACIS::Web::Citations::handle_document_addition( $item );

  } else {
    ### do a replace, even though it might be unnecessary
    foreach my $key ( @$accepted ) {
      if ( $key ->{'id'} eq $id ) {        
        $acis -> userlog( "replaced contribution: id $id, role $role" );
        $acis -> userlog( "work title: '$item->{title}' (type: $item->{type})" );
        $action = "re-accepted";
        last;
      }
    }
  }

  # check if the user's (person's) name is mentioned in the resource data.
  # if it is not mentioned, we mark this item as suspicious.
  if ($action) {
      my $name_found = check_item_names( $item );
      if (not $name_found) {
          $action .= "-suspicious";
          $event_type = 'warn';
      }
  }
      
  $item -> {'role'}         = $role;
  $already_accepted ->{$id} = $role;

  if ( $action ) {
      $acis -> sevent(  -class => 'contrib',
                       -action => $action,
 ($role ne 'author') ? ( -role => $role ) : (),
                        -descr => $item->{title} . " ($item->{type}, $item->{'id'})",
                          -URL => $item ->{'url-about'},
 (exists $item->{authors}) ? ( -authors  => $item -> {authors} ) : (),
 (exists $item->{editors}) ? ( -editors  => $item -> {editors} ) : (),
 ( $event_type ?       ( -type => $event_type ) : () ),
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
    foreach my $key ( @$accepted ) {
      if ( $key ->{'id'} eq $id ) {
        $index = $i;
        $item  = $key;
        last;
      }
      $i++;
    }
  }
  
  if ( defined $index 
       and $item ) {
    my $role  = $item ->{'role'};
    my $title = $item ->{'title'};
    my $type  = $item ->{'type'};

    $acis -> userlog( "deleting a contribution: id $id, role $role" );
    $acis -> userlog( "contribution title: '$title' (type: $item->{type})" );
    splice @$accepted, $index, 1;

    if ($item->{'sid'}) {
      require ACIS::Web::Citations;
      ACIS::Web::Citations::handle_document_removal( $item->{sid} );
    }

    $action = 'removed';
    $acis -> sevent( -class  => 'contrib',
                     -action => 'removed',
                     -descr  => $title . " ($type, $id)",
                     -URL    => $item ->{'url-about'},
                     (exists $item->{authors}) ? ( -authors  => $item -> {authors} ) : (),
                     (exists $item->{editors}) ? ( -editors  => $item -> {editors} ) : (),
                   );    
  } 
  else {
    debug "looked through accepted list and didn't find the item to delete!";
  }
  
  delete $already_accepted ->{$id};
  return $action;
}



sub refuse_item {
  my $id   = shift;
  my $item = shift;

  assert( $id );
  assert( $contributions );
  assert( $refused );
  assert( $acis );
  my $already_refused = $contributions -> {'already-refused'};

  if ( not $already_refused -> {$id} ) {
    if ( not $item ) {
      $item = { id => $id };
    }
    push @$refused, $item;
    $already_refused -> {$id} = 1;
    $acis -> userlog ( "refuse a contribution: id: $id" );
    if ($item->{sid}) {
      ACIS::Web::Citations::handle_document_removal( $item->{sid} );
    }
   
    my $title = $item -> {title} || '';
    my $type  = $item -> {type}  || '';
    my $url   = $item -> {'url-about'} || '';
    $acis -> sevent( -class  => 'contrib',
                    -action => 'refused',
                    -descr  => "$title ($type, $id)",
                    -URL    => $url,
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
  my $id      = $record -> {'id'};
  my $psid    = $record -> {sid};

  assert( $contributions );

  debug('processing starts');

  
  &get_configuration( $app );

  my $conf = $Conf;

  my $input = $app -> form_input;
  assert( $accepted );
  assert( $refused  );

  my $already_accepted = $contributions -> {'already-accepted'}; 
  my $already_refused  = $contributions -> {'already-refused' }; 

  my $statistics             = {};
  my $clear_from_suggestions = {};
  my $clear_from_suggestions_sid = {};
  
  # decisions count

  my $processed = 0;

  my $mode   = $input -> {mode} || '';
  my $source = $input -> {source};

  ## check for name variations?
  # XXX this can be used, if we make the check_item_names() call
  # optional, depending on where the item comes from. But for now we
  # better check everything.
  #my $check_names = 0;
  #if ($source == 'search') { $check_names = 1; }

  my $pool;
  if ( $mode eq 'add' ) {
    return if not $source;
    $pool   = $contributions -> {$source};
    debug "suggestions source: $source";
  }


  ###  process contribution additions and deletions

  foreach my $key ( keys %$input  ) {
    my $val = $input -> {$key};

    # main paramater processing. 
    # I don't know what it is good for.

    # prevent the processing in the (if add loop) 
    ### cardiff accept / refuse 
    ### end of cardff ar_
    ########################################################
    ### OLD   A D D 
    if ( $key =~ m/^add_(.+)/ 
         and $val ) {            
      my $tid    = $1;
      my $handle = $input -> {"id_$tid"};
      my $role   = $input -> {"role_$tid"} || die 'no role given';
      
      if ( $handle
           and $role 
           and $conf -> {roles} {$role} ) {
        ### all correct, but also we could check the item type and...
        debug(" found and ^add in legacy");
        assert( $source );
        my $item = find_suggested_item( $contributions, $handle, $source );

        if ( not $item ) {
          $app ->errlog( "Can't find a contribution among our own suggestions: id: $handle" );
          next;
        }
        
        my $type = $item ->{type};
        ### ZZZ should check role appropriateness for this type of object
        if ( $role eq 'editor' 
             and $type eq 'chapter' ) {
          complain "chapter editor again!";
        }
        my $sid = $item ->{'sid'};
        assert( $sid );
        my $action = accept_item( $item, $role );
        $statistics -> {$action} ++;
        $processed++; 

        $clear_from_suggestions  -> {$handle} = 1;
        $clear_from_suggestions_sid -> {$sid} = 1;
      }
    }
    elsif ( $mode eq 'edit'                           
              and $key =~ m/^role_(.+)/
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
            if ( $_ ->{'id'} eq $handle ) {
              my $item = $_;
               my $action = accept_item( $item, $role );
              $statistics -> {$action} ++;
              last;
            }
          }
        }
        $processed++; 
      }
    }
    #### pre-cardiff remove code
    elsif ( $key =~ m/^remove_(.+)/ ) { ###   R E M O V E 
      
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
      } 
      else {
        $app -> errlog( "not in already accepted list: $handle!" );
      }
    } 
  }  ####  end of the main parameters pass
  if( $mode eq 'add') {
    my $refuse_ignored = $input ->{'refuse-ignored'};
    if($refuse_ignored) {
      debug("refused ignored is on, this should not happen under cardiff.");
    }
    foreach my $key ( keys %$input  ) {
      my $val = $input -> {$key};
      
      if ( $key =~ m/^ar_(.+)/ and $val ) {            
        my $wid    = $1;
        my $handle = $input -> {"handle_$wid"};
        my $role   = $input -> {"role_$wid"};
        debug "found ar_, \$wid is $wid, \$handle is $handle, \$role is $role \$val is $val";
        if ( $handle
             and $role 
             and $conf -> {'roles'} -> {$role}
             and $val eq 'accept') {
          ### all correct, but also we could check the item type and...
          debug "starting to assert";
          assert( $source );
          debug "source asserted as $source";
          my $item = find_suggested_item( $contributions, $handle, $source );          
          if ( not $item ) {
            debug "no item returned by find_sugested_item";
            $app -> errlog( "Can't find a contribution among our own suggestions: id: $handle" );
            next;
          }
          debug "accepted item found";
          debug Dumper $item;
          my $type = $item ->{'type'};
          $item -> {role} = $role;
          my $sid = $item ->{'sid'};
          assert( $sid );
          my $action = accept_item( $item, $role );
          $statistics -> {$action} ++;
          $processed++; 
          
          debug "cleaning $handle from suggestions" ;          
          $clear_from_suggestions  -> {$handle} = 1;
          if ( $sid ) {  
            $clear_from_suggestions_sid -> {$sid}= 1;  
          }
          
          # start of refuse code
        }
        elsif ( $handle 
                and $val eq 'refuse' ) {
          assert( $source );
          my $item = find_suggested_item( $contributions, $handle, $source );
          my $sid  = $item -> {'sid'};          
          if ( not $item ) {
            $app -> errlog ("Can't find a contribution among our own suggestions: id: $handle" );
          }
          debug("calling refuse_item");
          refuse_item( $handle, $item );
          
          $statistics ->{refused} ++;
          $clear_from_suggestions -> {$handle} = 1;
          if ( $sid ) {  
            $clear_from_suggestions_sid -> {$sid}= 1;  
          }
          $processed++; 
        }
        else {
          debug "key $key not treated";
        }
      }      
      # legacy code of old interface
      elsif ( $key =~ m/^id_(.+)/ ) {
        my $wid    = $1;
        my $handle = $val;
        debug("legacy code in add mode");
        if ( $wid and $handle and not $input -> {"add_$wid"} ) {
          
          assert( $source );
          ###  find it
          my $item = find_suggested_item( $contributions, $handle, $source );

          if ( $refuse_ignored ) {
            refuse_item( $handle, $item );
            $statistics ->{'refused'} ++;
          }

          $clear_from_suggestions -> {$handle} = 1;

          if ( $item ) {
            my $sid  = $item -> {'sid'};
            if ( not $sid ) {
              my $id = $item ->{'id'};
              warn "Document $id had no sid: " . $item->{'title'};
            } 
            # important Cardiff change. We only clear the 
            # suggestion if the user did not press the "save_and_continue"
            # button 
            elsif(not $input->{'save_and_continue'}
                  and not $input->{'save_and_continue_next_chunk'}) {
                debug "suggestion $sid clear";
                $clear_from_suggestions_sid ->{$sid} = 1;
            }
            else {
                # before: $clear_from_suggestions_sid ->{$sid} = 1;
                debug "suggestion $sid kept";
            }
            #
            # end of Cardiff change
            #
          }
          $processed++; 
        }
      }
    }
    if ( $refuse_ignored ) {
      $app -> set_form_value( 'refuse-ignored', 1 );
    }
  }

  $contributions -> {actions} = $statistics;

  # clear from $contributions->{suggest}
  my $sug_count = clear_some_suggestions( $contributions, $clear_from_suggestions );
  # clear from the rp_suggestions table 
  clear_from_autosearch_suggestions($app, $psid, $clear_from_suggestions_sid);


  if ( $processed ) {
    $app -> success( 1 );
    if ( $statistics -> {'accepted'} ) {
      $app -> message( 'research-items-added' );
    }
    elsif ( $statistics -> {'re-accepted'} ) {
      $app -> message( 'research-items-replaced' );      
    } 
    elsif ( $statistics -> {'removed'} ) {
      $app -> message( 'research-items-removed' );      
    }
    elsif ( $statistics -> {'refused'} ) {
      $app -> message( 'research-items-refused' );      
    } 
    else {
      $app -> message( 'research-decisions-processed' );
    }

    if($app -> config( "learn-via-daemon" )) {
      ## send suggestions to learning daemon
      ## defined in ACIS/Resources/Suggestions.pm
      &send_suggestions_to_learning_daemon($app,'process');
      ## form the learner
      my $learner=&ACIS::Resources::Learn::form_learner($app);
      if(not defined($learner)) {
          complain "no learner";
      }
      else {
          my $saved_results_boolean=&ACIS::Resources::Learn::Suggested::learn_suggested($learner,$SQL,undef,'exact-name-variation-match');
          if(not defined($saved_results_boolean)) {
              complain "learrning failed";
          }
      }
    }
  }
  if ( $session -> type eq 'new-user' 
       and not $sug_count ) {
    $app -> set_presenter( 'research/ir-guide' );
  }
  
  # if the save and exit button was pressed, move
  # to the research screen
  if(exists $input->{'save'}) {
    $app -> redirect_to_screen( 'research' );
  }
  debug "end of function 'process'";
}

sub current_process {
  my $app = shift;
  if ( $app -> success() ) {
  }
}


###############    RESEARCH / REFUSED SCREENS

### this is a lighter version of sub prepare, only for the research/refused
### screens

sub prepare_refused {
  my $app = shift;
  my $session = $app -> session;  
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record  -> {'id'};
  ##
  ## process the chunk information
  ##
  &change_or_delete_chunk($app);


  $contributions = $session -> {$id} -> {'contributions'} || {};

  $accepted = $record ->{'contributions'} -> {'accepted'} || [];
  $refused  = $record ->{'contributions'} -> {'refused'} || [];

  $record -> {'contributions'} -> {'refused'}   = $refused;
  
  my $already_refused = {}; 
  foreach ( @$refused ) {
    my $id = $_ ->{'id'};
    if ( $already_refused->{$id} ) {
      undef $_;
    } 
    else { 
        $already_refused -> {$id} = 1; 
    }
  }
  clear_undefined $refused;

  ## 2009-09-16: removed the reloading because it takes
  ## too much time on a large profile
  # reload_refused_contributions( $app );

  $contributions ->{'already-refused' } = $already_refused ; 
  $contributions ->{refused}  = $refused;
  
  ##make it visible
  $vars ->{'contributions'}->{'refused'} = $refused;
  
  debug "prepared the contributions/refused";
}


#
# increment chunk number, or create one if there was none
# or delete if not required
#
sub change_or_delete_chunk {
  my $app = shift;
  # this argument increments the chunk number regardless
  my $increment= shift;

  my $session = $app -> session;
  my $screen_name = $app -> {'request'} -> {'screen'};
  my $presenter_data = $app -> {'presenter-data'};

  # remove the '-chunk' from the end of the screen name 
  my $screen_name_without_chunk=$screen_name;
  $screen_name_without_chunk =~ s|-chunk.*$||;
  debug "screen_name_without_chunk $screen_name_without_chunk";

  # if the screen does not have '-chunk' at the end
  if($screen_name_without_chunk eq $screen_name) {
    delete $session -> {'chunk'} -> {$screen_name_without_chunk};
    ## debug "no chunking";
    return;
  }
  # calculate new chunk number
  # the chunk number is stored in the session
  my $chunk_number = $session -> {'chunk'} -> {$screen_name_without_chunk};
  if(defined($chunk_number)) {
    if($screen_name =~ m|-chunk-forward$|) {
      $chunk_number++;
    } 
    if($screen_name =~ m|-chunk-backward$|) {
      if($chunk_number > 0) {
        $chunk_number--;
      }
    } 
  }
  else {
    $chunk_number=0;
  }
  # this is used to move to the next chunk 
  # with the save-and-next-chunk-input input
  if($increment) {
    $chunk_number++;
  }
  # put in the session to save
  $session -> {'chunk'} -> {$screen_name_without_chunk} = $chunk_number;
  # put into presenter data to show
  $presenter_data -> {'chunk'} -> {$screen_name_without_chunk} = $chunk_number;  
}
  




###########################################################################
##########   s u b    p r o c e s s   r e f u s e d   #####################
###########################################################################

sub process_refused {
  my $app = shift;

  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record -> {'id'};
  my $psid    = $record -> {sid};
  assert( $contributions );
  assert( $refused  );
  my $input = $app -> form_input;
  my $already_refused  = $contributions -> {'already-refused' }; 
  my $statistics = {};
  my $conf=&get_configuration( $app );
  my $processed  = 0;



  # moving to the next chunk
  if($input->{'save_and_continue_next_chunk'}) {
    ##debug('input save next chunk found');
    &change_or_delete_chunk($app,1);
  }
 
  ###  process contribution refusals
  foreach my $key ( keys %$input  ) {
    my $val = $input -> {$key};

    ########################################################
    ###   UN R E F U S E, legacy code
    if ( $key =~ m/^unrefuse_(.+)/ 
         and $val ) {            
      my $wid    = $1;
      my $handle = $input -> {"id_$wid"};
      debug( "unrefuse $handle" );

      if ( $handle ) {
        if ( $already_refused->{$handle} ) {
          # ok
          delete $already_refused->{$handle};
        } 
        else {
          debug( "Can't find an item among refused in legacy: id: $handle" );
        }
        $processed++; 
      }
    }
    # cardiff parse 
    elsif ( $key =~ m/^ar_(.+)/ 
            and $val ) {            
      my $wid    = $1;      
      my $handle = $input -> {"handle_$wid"};
      my $role   = $input -> {"role_$wid"};
      
      debug "unrefuse with $wid handle $handle role $role" ;

      if ( $handle ) {
        if ( $already_refused->{$handle} ) {
          debug "unrefusing item $handle";
          delete $already_refused->{$handle};
        } 
        else {
          debug( "Can't find an item among refused in legacy: id: $handle" );
        }

        my $item = find_refused_item( $handle);

        if ( not $item ) {
          debug( "Can't find a refused item among our own refusals: id: $handle" );
          $app ->errlog( "Can't find a refused item among our own refusals: id: $handle" );
          next;
        }
        
        my $type = $item ->{'type'};
        my $sid = $item ->{'sid'};
        if(not $item->{'role'}) {
          if($role) {
            $item->{'role'}=$role;
          }
          else {
            $item->{'role'}='author';
          }
        }
        assert( $sid );
        my $action = accept_item( $item );
        $statistics -> {$action} ++;
        $processed++; 
      }
    }
  }
  ####  end of the main parameters pass
  
  
  foreach my $key ( @$refused ) {
    my $id   = $key ->{'id'};
    if ( not $already_refused->{$id} ) {
      
      undef $key;
      
      $acis -> userlog( "unrefuse a research item: $id" );
      $acis -> sevent( -class  => 'contrib',
                       -action => 'unrefused',
                       -descr  => $id );
      
      $statistics -> {'unrefused'} ++;
      debug( "cleared refused item $id" );
      
    }
  }  
  clear_undefined $refused;
  
  
  
  $contributions -> {actions} = $statistics;
  
  
  if ( $processed ) {
    $app -> success( 1 );
    
    if ( $statistics -> {unrefused} ) {
      if ( $statistics -> {unrefused} == 1 ) {
        $app -> message( 'one-research-item-unrefused' );
      } 
      else {
        $app -> message( 'research-items-unrefused' );
      }
    }
    else {
      $app -> message( 'research-decisions-processed' );
    }      
    
  }
}


###########################################################################
##########   s u b    p r o c e s s   a c c e p t e d   ###################
###########################################################################

sub process_accepted {
  my $app = shift;

  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record -> {'id'};
  my $psid    = $record -> {sid};
  $contributions = $session -> {$id} -> {'contributions'} || {};
  #assert( $contributions );
  #assert( $refused  );
  my $input = $app -> form_input;
  my $already_accepted  = $contributions -> {'already-accepted' }; 
  my $statistics = {};
  my $conf=&get_configuration( $app );
  my $processed  = 0;

  ###  process contribution refusals form acceped scree
  foreach my $key ( keys %$input  ) {
    my $val = $input -> {$key};
    debug "key is $key val is $val";
    if ( $key =~ m/^handle_(.+)/ and
         $val ) {            
      my $wid    = $1;      
      my $ar = $input -> {"ar_$wid"};
      # if the ar is set, we move to the next
      if($ar) {
          next;
      }
      my $role   = $input -> {"role_$wid"} || '';
      my $handle = $input -> {"handle_$wid"};
      
      debug "refuse with $wid handle $handle role $role" ;
        
      if ( $handle ) {
        if ( $already_accepted->{$handle} ) {
          debug "refusing an accepted item $handle";
          delete $already_accepted->{$handle};
        } 
        else {
          debug( "Can't find an item among refused in legacy: id: $handle" );
        }

        my $item;
        $item= find_accepted_item( $handle);
        
        if ( not $item ) {
            debug( "Can't find a accepted item among our own accepted items: id: $handle" );
            $app ->errlog( "Can't find a accepted item among our own acceptions: id: $handle" );
            next;
        }
        
        my $type = $item ->{'type'};
        my $sid = $item ->{'sid'};
        if(not $item->{'role'}) {
          if($role) {
            $item->{'role'}=$role;
          }
          else {
            $item->{'role'}='author';
          }
        }
        assert( $sid );
        my $action = refuse_item( $handle, $item );
        $statistics -> {$action} ++;
        $processed++; 
      }
    }
  }
  ####  end of the main parameters pass
  
  
  foreach my $key ( @$accepted ) {
    my $id   = $key ->{'id'};
    next if not $id;
    if ( not $already_accepted->{$id} ) {
      
      undef $key;
      
      $acis -> userlog( "refuse an accepted a research item: $id" );
      $acis -> sevent( -class  => 'contrib',
                       -action => 'refused',
                       -descr  => $id );
      
      $statistics -> {'refuse_accepted'} ++;
      debug( "cleared accepted item $id" );
      
    }
  }  
  clear_undefined $accepted;
  
 
  $contributions -> {'actions'} = $statistics;
  
  
  if ( $processed ) {
    $app -> success( 1 );
    
    if ( $statistics -> {'refused_accepted'} ) {
      if ( $statistics -> {'refused_accepted'} == 1 ) {
        $app -> message( 'one-accepted-item-refused' );
      } 
      else {
        $app -> message( 'accepted-items-refused' );
      }
    }
    else {
      $app -> message( 'research-decisions-processed' );
    }          
  }
}


#
# unknown purpose
#
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




sub reload_if_nothing_to_suggest {
  my $app = shift;

  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record -> {'id'};
  
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

sub search { # research/search screen handler
  my $app = shift;
  my $sql     = $app -> sql_object;
  my $input   = $app -> form_input;
  my $session = $app -> session;
  my $vars    = $app -> variables;
  my $record  = $session -> current_record;
  my $id      = $record ->{'id'};

  ###  preparations
  my %found_ids;
  my $search ;

  ###  prepare( ) is run by screen config
  get_configuration( $app );
  my $conf = $Conf;
  assert( $contributions );
#  my $contributions = $session ->{$id} -> {'contributions'} ;

  my $current_index   = $contributions -> {'already-accepted'};
  my $already_refused = $contributions -> {'already-refused' };

  my $ignore_index = {};
  foreach ( keys( %$current_index ), keys %$already_refused ) {
    $ignore_index ->{$_} = 1;
  }

  my $metadata_db = $app -> config( 'metadata-db-name' );
  my $context = {
    db      => $metadata_db,
    found   => \%found_ids,
    already => $ignore_index,
  };
  

  ###  analyse the input 
  my $search_type = 'resources';
  my $objects     = 'resources';
  my $table;

  my $search_key = $input -> {q};    
  my $field      = $input -> {field} || '';
  my $phrasematch= $input -> {phrase} || 0;
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

use ACIS::Web::SysProfile;

sub passed_since {
  my ($period,$start) = @_;
  my $now = time;
  return ( $start+$period < $now );
}

# do not reload it twice in a same min period
my $reload_min_period = 60*60*24*6; # six days
# grace period for a disappeared document record
my $grace_period = 60*60*24*7*2; # two weeks

sub reload_accepted_contributions {
  my $app = shift;
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record -> {'id'};
  my $metadata_db = $app -> config( 'metadata-db-name' );

  # check if we did this already recently
  my $last_reload = get_sysprof_value( $record->{sid}, "last-reload-accepted-contrib" ) || 0;
  if ( not passed_since( $reload_min_period, $last_reload ) ) { return 0; }

  # check the flag to avoid double work
  if ( $session -> {$id} -> {'contributions'} -> {'reloaded'} ) {
    return 1;
  }
  my $accepted = $record ->{'contributions'} -> {'accepted'};
  my $accepted_size_before = scalar @$accepted;
  foreach my $item ( @$accepted ) {
    my $id   = $item -> {'id'};
    my $type = $item -> {'type'};
    my $role = $item -> {'role'} || '';
    
    # if there is no id the contribution, debug the contribution
    if(not $id) {
      debug "could not load a contribution, because it has no id";
      debug Dumper $item;
      next;
    }
    my $reload = reload_contribution( $app, $id, $metadata_db );
    if ( $reload and $reload->{'sid'} ) {
      $item = $reload;
      $item -> {'role'} = $role;
      delete $item -> {'frozen'};      
    }
    else {
      debug "contribution $id can't be reloaded";
      my $today = time;
      my $long_ago = $today - $grace_period;

      if ( $item ->{'frozen'} ) {
        if ( $item ->{'frozen'} <= $long_ago ) {
	  # log it
          $app -> userlog( "clearing a contribution: id $id, role $role" );
          $app -> sevent( -class  => 'contrib',
                          -action => 'cleared lost',
                          -descr  => $id,
                          -URL    => $item ->{'url-about'},
                          (exists $item->{authors}) ? ( -authors  => $item -> {authors} ) : (),
                          (exists $item->{editors}) ? ( -editors  => $item -> {editors} ) : (),
                        );

          # clear
          undef $item;
        }
      }
      else {
        $item -> {'frozen'} = $today;
      }
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
  
  # remember the current time and set the flags to avoid repeating this again
  put_sysprof_value( $record->{'sid'}, "last-reload-accepted-contrib", time );
  $session -> {$id} -> {'contributions'} -> {'reloaded'} = 1;
  $session -> {$id} -> {'reloaded-accepted-contributions'} = 1;
}



sub reload_refused_contributions {
  my $app = shift;
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record -> {'id'};
  my $metadata_db = $app -> config( 'metadata-db-name' );

  if ( $session ->{$id} ->{'contributions'} -> {'refused_reloaded'} ) {
    return 1;
  }
  $session -> {$id}->{'contributions'}->{'refused_reloaded'} = 1;
  my $list = $record ->{'contributions'}->{'refused'};
  my $list_size_before = scalar @$list;
  ## reload contributions loop
  foreach my $item ( @$list ) {
    my $id   = $item ->{'id'};
    if(not $id) {
      debug "could not load a contribution, because it has no id";
      debug Dumper $item;
      next;
    }
    ## cardiff change: if this item has a relevance, get it out
    my $relevance;
    if(defined($item->{'relevance'})) {
      $relevance=$item->{'relevance'};
    }
    ## end of cardiff change
    #debug "reloading item $id";
    my $new  = reload_contribution( $app, $id, $metadata_db );
    if ( $new ) {
      $item = $new;
    } 
    else {
      debug "refused item $id is not in the database";
    }
    ## cardiff change: add the relevance
    if(not defined($item->{'relevance'})) {
      $item->{'relevance'}=$relevance;
    }
    ## end of cardiff change
  }
  clear_undefined $list;
  if ( $list_size_before ) {
    debug "refused contributions have been reloaded from the database";
  }
  $session -> {$id} -> {'reloaded-refused-contributions'} = 1;
}



############################################################################
###   h e l p f u l   s q l   s e a r c h   u t i l i t y   f u n c s    ###
############################################################################

use Encode;

use vars qw( $select_what );

$select_what = "select id, sid, data ";


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
    } 
    else { 
        $table = 'res_creators_bulk';
        $field = 'names';  
    }
  } 
  elsif ( $field eq 'id' ) {
      $table = 'resources';
  }
  elsif ( $field eq 'title'   ) { 
      $table = 'resources'; 
  }
  
  my $where; 

  if ( $phrase ) { 
    $key = "\"$key\"";
    $where = "match ( catch.$field ) against ( ? IN BOOLEAN MODE )";

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


sub show_whats_suggested {
  my $app = shift;

  debug "show_whats_suggested: enter";
  my $vars    = $app -> variables;
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record -> {'id'};
  my $psid    = $record -> {sid};

  assert( $contributions );
  prepare_configuration( $app );

  my $suggestions = load_suggestions_into_contributions( $app, $psid, $contributions );
  my $groups = scalar @$suggestions;

  # suggestions counts: update the counter
  if ( exists $contributions->{'suggestions-count-total'} ) {
      $session ->{$psid} {'research-suggestions-total'} = $contributions->{'suggestions-count-total'};
  }
  if ( exists $contributions->{'suggestions-count-exact'} ) {
      $session ->{$psid} {'research-suggestions-exact'} = $contributions->{'suggestions-count-exact'};
  }

  debug "found groups: $groups";
  debug "show_whats_suggested: exit";
}


1; # Cheers! ;)
