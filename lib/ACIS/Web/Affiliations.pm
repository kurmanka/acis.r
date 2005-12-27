package ACIS::Web::Affiliations;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    ACIS users' affiliations and submitted institutions work.
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
#  $Id: Affiliations.pm,v 2.0 2005/12/27 19:47:39 ivan Exp $
#  ---


use strict;

use Data::Dumper;

use Encode;
use Carp::Assert;

use Web::App::Common;

use Storable qw( thaw );

sub load_institution {
  my $app = shift;
  my $id  = shift;

  my $sql = $app -> sql_object;
  my $metadata_db = $app -> config( 'metadata-db-name' );

  my $statement   = "select * from $metadata_db.institutions where id=?";
  
  $sql -> prepare ( $statement );
  my $sql_res = $sql -> execute ( $id );
  
  if ( not $sql_res ) {
    $app -> errlog( "database error in Affiliations::load_institution: no result of execute" );
    $app -> error ( 'db-error' );
    # debug "error while processing request: " . $sql -> error;
    debug "database query error";
    return undef;
  }
  
  my $search_results = $sql_res -> {rows};
  
  debug "found $search_results";
  
  if ( $search_results ) {  
    my $data = $sql_res -> {row}{data};
    my $inst = thaw $data;
    
    return $inst;
  }
  return 0;
}



sub prepare {   ### XXX here is a great place for optimization in
                ### terms of unloading the server, and making the
                ### service work quicker

  my $app = shift;
  
  debug "preparing affiliations - copying unfolded and resolving handles into institutions";

  
  my $config  = $app -> config;
  my $session = $app -> session;
  my $record  = $session -> current_record();
  my $id      = $record -> {id};
  
  my $affiliations = $record -> {affiliations};
  my @handles = ();


  my $unfolded = [];
  
  return
   unless defined $affiliations and scalar @$affiliations;
   
  foreach ( @$affiliations ) {

    if ( ref $_ eq 'HASH' ) {
      push @$unfolded, $_;

    } else {
      my $institution =  &load_institution( $app, $_ );
      if ( $institution ) {
        push @$unfolded, $institution;
      } else { 
        undef $_;
      }
      
    }
  }

  clear_undefined( $affiliations );
  
 
  $app -> variables -> {affiliations} =
    $session -> {$id} {affiliations} = $unfolded;
}






sub add {
  my $app = shift;
  
  my $config      = $app -> config;
  my $metadata_db = $config->{'metadata-db-name'};

  my $instid      = $app -> get_form_value( 'id' );
  my $form_input  = $app -> form_input;
  
  debug 'try to add an affiliation';
  
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record -> {id};

  my $search_rec   = $session -> {$id} {'institution-search'} ;
  my $search_items = $search_rec -> {items};



  $record -> {affiliations} = []
   unless defined $record -> {affiliations};
  
  my $affiliations = $record  ->{affiliations};
  
  $session -> {$id} {affiliations} = []
   if not defined $session -> {$id} {affiliations};
  
  my $unfolded     = $session ->{$id} {affiliations};
  


  # xslt uses handles
  if ( $form_input ->{add} ) {
    debug 'adding institution: $instid';
    $app -> userlog( "affil: add an item, id: $instid" );
    
    foreach ( @$unfolded ) {

      if ( defined $_ -> {id}
           and $_ -> {id} eq $instid ) {
        return;
      }
    }
    
    my $institution;
  
    my $counter = 0;
    foreach ( @$search_items ) {

      if ( $_ -> {id} eq $instid ) {
        $institution = 'found';
        last;
      }
      $counter++; 
    }
    
    if ( $institution ) {
      $institution = splice @$search_items, $counter, 1;
      $search_rec -> {results} --;
      
    } else {
      $institution = load_institution( $app, $instid );
    } 

    push @$unfolded,     $institution;
    push @$affiliations, $instid;

    $app -> sevent ( -class => 'affil',
                    -action => 'add',
                     -descr => $institution ->{name},
                  -location => $institution ->{location},
       ( $instid ) ? ( -id  => $instid ) : (),
                   );


  } else {
    debug "should not be here, because..." 

  } ### if not just the institution handle


  $app -> variables ->{processed} = 1;

}



sub remove {
  my $app = shift;
  
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record -> {id};

  my $affiliations = $record -> {affiliations};
  my $unfolded     = $session -> {$id} {affiliations};
  
  return 
    unless defined $affiliations and scalar @$affiliations;

  my $instid = $app -> get_form_value ( 'id' );
  my $name   = $app -> get_form_value ( 'name'   );
  
  debug "remove institution id: $instid, n: $name";

  $app -> userlog( "affil: request to remove an item, id: $instid, n: $name" );

  my @old_affs = @$affiliations;
  my @old_unfolded = @$unfolded;
  @$affiliations = ();
  @$unfolded = ();

  my $removed_inst;

  debug "copying affiliations, skipping removed";

  foreach my $institution ( @old_affs ) {
    my $unfolded_i = shift @old_unfolded;

    if ( ref $institution ) {
      debug "checking $institution->{name}";
      if ( $institution -> {id} 
           and $institution -> {id} eq $instid ) {
        $removed_inst = $unfolded_i;
        debug "skipped";
        next;
      }

      if ( $institution -> {name} eq $name ) {  
        debug "skipped";
        $removed_inst = $unfolded_i;
        next;
      }
      
    } else {
      debug "checking $institution";
      if ( $institution eq $instid ) {
        debug "skipped";
        $removed_inst = $unfolded_i;
        next;
      }
    }
    
    push @$affiliations, $institution;
    push @$unfolded,     $unfolded_i;
  }
  
  if ( scalar @$affiliations < scalar @old_affs ) {
    $app -> userlog( "affil: removing success" );

    $app -> sevent ( -class => 'affil',
                     -action=> 'remove',
                     -descr => $removed_inst ->{name},
                  -location => $removed_inst ->{location},
                       -id  => $removed_inst ->{id},
                   );

  } else {
    $app -> userlog( "affil: removing didn't work" );
    $app -> error  ( "affil-remove-failed" );

  }

  $app -> variables ->{processed} = 1;
} 
  

##########################################################################
#########      s e a r c h   for institutions, order results by relevance
########################################################################## 

sub search {
  my $app     = shift;
  
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record -> {id};
  my $affiliations = $session -> {$id} {affiliations};

  my $cgi     = $app -> request -> {CGI};
  my $input   = $app -> form_input;
  my $sql     = $app -> sql_object;

  my $db = $app -> config( 'metadata-db-name' );


  my $key   = $input ->{ 'search-what' };
  my $field = $input ->{ 'search-by' };

  $field =~ s/[^a-z]//g;

  $app -> userlog( "affil: search: by $field, key: '$key'", );

  return unless ( $field =~ /^(location|name)$/ );

  if ( not $key 
       or not $field ) {
    die;
  }


  ###  building a list of already chosen affiliations to exclude them from the
  ###  result set
  my $already_there = {};

  foreach ( @$affiliations ) {
    next unless $_ ->{id};
    my $h = $_ ->{id};
    $already_there -> {$h} = 1;
  }

  my $already_found = {};
  ###  examine the search expression

  $key =~ s/(^\s+|\s+$)//g;
  my @words = split /\s+/, lc $key;
  
  my @realwords;
  my @ignore_words = qw( of the in and for );
  my %ignore_words;
  foreach ( @ignore_words ) { $ignore_words{$_} = 1; }
  foreach ( @words ) { 
    if ( not $ignore_words{$_} ) {
      push @realwords, $_;
      debug "real query word: $_";
    }
  }

  my $word_count     = scalar @words;
  my $realword_count = scalar @realwords;


#  $sql_helper::VERBOSE_LOG = 1;

  ####################  THE PLAN  ############################################

  ###   now check the search options, if any

  ###   --  options: search-mode: only-exact | all-words | loose-match 

  ###   do the exact key expression search

  ###   --  "select from institutions where $the_field like '%$key%'"
  
  ###       --  shall we include word-boundary condition into the where block?  
  ###           Yes, we shall!  But how?  RFTM!

  ###                  file:///shared/RTFM/Mysql/4.1/manual_Regexp.html

# mysql> SELECT "a word a" REGEXP "[[:<:]]word[[:>:]]";      -> 1
# mysql> SELECT "a xword a" REGEXP "[[:<:]]word[[:>:]]";     -> 0

  ###   filter the results -- remove those, which are already_there

  ###   decide: is it enough or shall we search for more?  (search options?)

  ###   -- if there's more than 10 results and the search-mode is not
  ###      "all-words" or "loose-match", we stop at this

  ###   -- independently of the amount of hits, we shall stop if search-mode is
  ###      "only-exact".  Or we may do the all-words search and say to the user, 
  ###      that it might (or might not) be useful.

  ###   if we shall search further, build a list of already_found handles

  ###   execute full-text search and then filter out already_there,
  ###   already_found

  ###   unless we run a really permissive search, we shall leave out those
  ###   items, which don't contain at least one word of the @words

  ###   present the results

  my $mode = 'all-words';
  if ( $input -> {'exact-only'} ) {
    $mode = 'exact-only';

  } elsif ( $input -> {'loose-match'} ) {
    $mode = 'loose-match';
  }

  my $context = {};
  $context -> {already_there} = $already_there;
  $context -> {already_found} = $already_found;


  ###   the exact search:

  my @exact_matches;
  {
    my $select_what = "select data from $db.institutions ";
    my $where;
    my $_field = $field;
    if ( $_field eq 'name' ) {
      $_field = 'concat( name )';
    }
    $where = "where $_field regexp ?";
    my $exp = "[[:<:]]$key";  ### XX  undocumented and inobvious

    my $query = "$select_what$where limit 101";
    debug "query: $query";

    $sql -> prepare ( $query );
    my $sql_res = $sql -> execute ( $exp );
    
    if ( $sql_res ) {
      my $items = extract_institution_search_results( $sql_res, $context );
      @exact_matches = @$items;
    } 

    if ( $sql->error ) {
      debug "err: ". $sql->error;
      $app -> error( 'db-select-error' );
    }

  }

#  debug "found these: ". join ', ', keys %{ $already_found };

  ###   decide: is it enough or shall we search for more?  (search options?)

  ###   -- if there's more than 10 results and the search-mode is not
  ###      "all-words" or "loose-match", we stop at this

  ###   -- independently of the amount of hits, we shall stop if search-mode is
  ###      "only-exact".  Or we may do the all-words search and say to the user, 
  ###      that it might (or might not) be useful.


  ##    prepare search results

  my $search = {};
  $search ->{key}   = $key;
  $search ->{field} = $field;
  if ( $mode ) { 
    $search ->{mode}  = $mode;
  }
  
  my $results = $search ->{results} = {};

  $results ->{exact} = \@exact_matches;
  
  $app -> variables -> {'institution-search'} = $search;
  

  ###  Is that enough searching?

  if ( scalar @exact_matches > 10 
       and $mode ne 'loose-match' 
       and not $input ->{'show-all-results'} 
     ) {
    return;
  }
    
  if ( $mode eq 'only-exact' 
       and scalar @exact_matches > 4 ) {
    return;
  }    

  
  
  ###   execute full-text search and then filter out already_there,
  ###   already_found

  ###   unless we run a really permissive search, we shall leave out those
  ###   items, which don't contain at least one word of the @words


  my @fulltext_matches;
  {
    my $select_what = "select data from $db.institutions ";
    my $where;
    my $_field = $field;
    if ( $_field eq 'name' ) {
      $where = 'where match( name ) against( ? )';
    } else {
      $where = "where match( $_field ) against( ? )";
    }
    my $query = "$select_what$where limit 101";
    debug "query: $query";

    $sql -> prepare ( $query );
    my $sql_res = $sql -> execute ( $key );
    
    if ( $sql_res ) {
      my $items = extract_institution_search_results( $sql_res, $context );
      @fulltext_matches = @$items;
    } 

    if ( $sql->error ) {
      debug "err: ". $sql->error;
      $app -> error( 'db-select-error' );
    }

  }

  debug "before filtering there are " . scalar( @fulltext_matches ) . " fulltext matches";

  
  ###  filter out
  if ( $word_count == 1 ) {
    $results -> {fulltext} = \@fulltext_matches; 

  } else { 
    my @loose;
    my @good_ones;

    my $cut_loose = 0;
    
    foreach ( @fulltext_matches ) {
      my $inst = $_;

      if ( $cut_loose >= 3 ) {
        push @loose, $inst;
        next;
      }

      my $match = 0;
      my $value = $inst -> {$field};
      if ( $field eq 'name' ) {
        $value = $inst -> {name} . ' '. $inst ->{name_en};
      }
      $value = lc $value;

      foreach my $word ( @realwords ) {
        if ( index( $value, $word ) > -1 ) {
          $match ++;
        }
      }
      
      if ( $match == $realword_count ) {
        push @good_ones, $inst;

      } else {
        push @loose, $inst;
        $cut_loose ++;
      }
    }

    $results -> {fulltext} = \@good_ones; 
    if ( scalar @loose ) {
      $results -> {loose} = \@loose; 
    }
  }


  return 1;
}


####
###   EXTRACT INSTITUTION SEARCH RESULTS  
##
sub extract_institution_search_results {
  my $sqlres  = shift;
  my $context = shift;

  assert( $sqlres );

  my @items = ();

  my @exclude_sets;
  if ( $context ) {
    foreach ( $context ->{already_there},  
              $context ->{already_found} ) {
      if ( $_ and ref $_ and ref( $_ ) eq 'HASH' ) {
        push @exclude_sets, $_;
      }
    }
  }

  my $counter;

 ROW: 
  while ( $sqlres -> {row} ) {
    
    my $data = $sqlres -> {row}{data};
    my $institution = thaw $data;
    
    my $instid = $institution -> {id};
    
    ###  check if we need to exclude this
    foreach ( @exclude_sets ) {
      if ( $_->{$instid} ) {
        debug "already found: $instid";
        next ROW;
      }
    }
          
    push @items, $institution;

    if ( $context ) {
      $context ->{already_found} ->{$instid} = 1;
    }
    
  } continue {
    $sqlres -> next;
    $counter ++;
    if ( $counter > 500 ) {
      die;
    }
  }

  if ( $sqlres ) {
    $sqlres -> finish;
  }
  
  return \@items;
}





sub make_it_visible {
  my $app = shift;
  
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record -> {id};

#  my $search = $session -> {$id} {'institution-search'};
#  $app -> variables -> {'institution-search'} = $search
#    if defined $search 
#      and ref( $search->{items} ) 
#      and scalar @{ $search -> {items} };
  
  my $affiliations = $session -> {$id} {affiliations};
  $app -> variables -> {affiliations} = $affiliations
    if defined $affiliations 
      and scalar @$affiliations;
}


sub general_handler {
  my $app   = shift;
  
  debug "running affiliation service screen";
  

  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record -> {id};
  my $cgi     = $app -> request -> {CGI};

  my $input   = $app -> form_input;
   
  if ( $input -> {continue} ) { 

    if ( $session -> type eq 'new-user' ) {
      $app -> redirect_to_screen_for_record ( 'research' );
      
    } else {
      $app -> message( "saved" );
      $app -> redirect_to_screen_for_record ( 'menu' );
    }
    
  } else {
    
    my $cha;
    if ( $input -> {add}    ) { add( $app );    $cha = 1; }
    if ( $input -> {remove} ) { remove( $app ); $cha = 1; }
    if ( $input -> {search} ) { search( $app ); }

    if ( $session -> type eq 'new-user' and $cha ) {
      $app -> message( "saved" );
      $app -> set_presenter( 'affiliations-ir-guide' );
    }
    
  }
  
  make_it_visible( $app );

}




sub submit_institution {
  my $app = shift;

  my $session = $app -> session;

  my $institution = {};

  my $input = $app -> form_input;

  my $name    = $input -> {name};
  my $oldname = $input -> {oldname};
  my $id      = $input -> {id};
  
  debug "submit: name: $name";
  debug "submit:  old: $oldname";
  debug "submit:   id: $id";
 

  foreach ( qw( name name-english location homepage 
                email phone fax   postal   note id
                add-to-profile ) ) {
    if( defined $input->{$_} ) {
      $institution -> {$_} = $input->{$_};
    }
  }

  $institution -> {'submitted-by'} = $session -> owner -> {login};


  if ( $session -> {'submitted-institutions'} ) {

    ### append or replace an institution in the submitted list
    my $list = $session -> {'submitted-institutions'};
    my $replace;
    my $counter = 0;

    foreach ( @$list ) {
      if( $_ -> {name} eq $name 
          or $_ -> {name} eq $oldname   ### this is when user wants to edit an institution
          or ( $_->{id} and ( $_ -> {id} eq $id ) )  ) {
        $replace = $counter; last;
      }
      $counter ++;
    }

    if ( defined $replace ) {
      $list ->[$replace] = $institution;
    } else {
      push @$list, $institution;
      debug "submit: added to the submitted list";
    }

  } else {
    ### create the submitted institutions list
    $session -> {'submitted-institutions'} = [ $institution ];
  }



  # adding an institution to the profile
  

  if ( $input -> {'add-to-profile'} ) {

    debug "adding a submitted institution ($name) to the record";
    $app -> userlog( "affil: add a submited institution, name: $name", $id ? " id: $id" : '' );
  

    my $record  = $session -> current_record;
    my $id      = $record -> {id};

    assert( $record->{type} eq 'person' );

    $record -> {affiliations} = []
      if not defined $record -> {affiliations};

    $session -> {$id} {affiliations} = []
      if not defined $session -> {$id} {affiliations} ;
  
    my $affiliations = $record  ->{affiliations};
    my $unfolded     = $session -> {$id} {affiliations};
  
    ### additional check
    my $replace;
    my $counter = 0;
    foreach ( @$unfolded ) {

      if (  
          ( $_ -> {name} eq $name ) 
          or ( $_ -> {name} eq $oldname ) 
          or (
              defined $_ -> {id} 
              and ( $_ -> {id} eq $id ) 
             )
         ) {
        ### there is already such an institution...
        $replace = $counter;
        last;
      }
      $counter++;
    }
    
    if ( defined $replace ) {
      debug "replacing item no $replace";
      $$affiliations[$replace] = $institution;
      $$unfolded[$replace]     = $institution;
      
    } else {
      debug "adding new item";
      push @$affiliations, $institution;
      push @$unfolded,     $institution;

    $app -> sevent ( -class => 'affil',
                    -action => 'submit-add',
                     -descr => $institution ->{name},
                  -location => $institution ->{location},
($institution->{id})? ( -id => $institution ->{id} ): (),
                   );

    }
  
  } # if "add-to-profile" 
  else {
    
    debug "not needed to add";

    $app -> userlog( "affil: submited an institution, but asked not to add it, name: $name", 
                     $id ? " id: $id" : '' );

    $app -> sevent ( -class => 'affil',
                    -action => 'submit-not-add',
                     -descr => $institution ->{name},
                  -location => $institution ->{location},
($institution->{id})? ( -id => $institution ->{id} ): (),
                   );

  }


  $app  -> message( "institution-submission-accepted" );

  if ( $session -> type eq 'new-user' ) {
    make_it_visible( $app );
    $app -> set_presenter( 'affiliations-ir-guide' );
    
  } else {
    $app -> redirect_to_screen_for_record ( 'affiliations' );
  }

}



1; 
