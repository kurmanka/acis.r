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
#  $Id$
#  ---


use strict;

use Data::Dumper;

use Encode;
use Carp::Assert;

use Web::App::Common;

## schmorp
#use Storable qw( thaw );
use ACIS::Data::Serialization;
## /schmorp

sub load_institution {
  my $app = shift;
  my $id  = shift;

  my $sql = $app -> sql_object;
  my $metadata_db = $app -> config( 'metadata-db-name' );
  my $statement   = "select data from $metadata_db.institutions where id=?";
  
  $sql -> prepare ( $statement );
  my $r = $sql -> execute ( $id );
  if ( not $r ) {
    $app -> errlog( "database error in Affiliations::load_institution: no result of execute" );
    $app -> error ( 'db-error' );
    debug "database query error";
    return undef;
  }
  
  debug "found $r->{rows}";
  if ( $r and $r -> {rows} ) {  
    ## schmorp
    #my $inst = eval {thaw $r->{row}{data}; };
    my $inst = inflate($r->{'row'}{'data'});
    ## /schmorp
    return $inst;
  }
  return undef;
}


sub prepare {
  my $app = shift;

  debug "prepare affiliations - reload institution records from db, if needed";
  my $config  = $app -> config;
  my $session = $app -> session;
  my $record  = $session -> current_record();
  my $id      = $record -> {id};
  
  my $affiliations = 
      $app->variables ->{affiliations} = 
        $record -> {affiliations};
  
  return
      unless defined $affiliations and scalar @$affiliations;

  if ( $session->{$id}{prepared_affiliations} ) {
      # already prepared
      return;
  }

  # reload each affiliation, which has an id from the database
  my $adjust_shares = 0;
  foreach ( @$affiliations ) {

    if ( ref $_ eq 'HASH' ) {
        
      if ( $_->{id} ) {
         my $i = load_institution( $app, $_->{id} );
         if ($i) {
             if (exists $_->{share}) { $i->{share} = $_->{share}; }
             $_ = $i;
         } else {
             undef $_;
             $adjust_shares = 1;
         }
      }
      # else: do nothing

    } else { 
      # legacy support: just a string, not a hash
      my $institution = load_institution( $app, $_ );
      if ( $institution ) {
        $_ = $institution;
      } else { 
        undef $_;
        $adjust_shares = 1;
      }
    }
  }

  # to set initial shares for the existing accounts with multiple shares
  if ( scalar @$affiliations > 1
       and not exists $affiliations->[0]{share} ) { 
      $adjust_shares = 1; 
  }

  if ($adjust_shares) {
      adjust_shares( $app );
  }
  clear_undefined( $affiliations );
  
  $session->{$id}{prepared_affiliations} = 1;
}


sub prepare_for_presenter {
    my $app = shift;
    my $affiliations = $app->session->current_record->{affiliations} || [];
    if (scalar ( @$affiliations ) > 1) {
        $app->variables->{'with-shares'} = 1;
    }
    $app -> variables->{affiliations} = $affiliations;
}




sub add {
  my $app = shift;
  my $instid = shift || die;
  
  my $config      = $app -> config;
  my $metadata_db = $config->{'metadata-db-name'};
  my $form_input  = $app -> form_input;
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $id      = $record -> {id};

  my $search_rec   = $session -> {$id} {'institution-search'} ;
  my $search_items = $search_rec -> {items};
  my $affiliations = $record ->{affiliations}   ||= [];
  
  debug "adding institution: $instid";
  $app -> userlog( "affil: add an item, id: $instid" );
    
  # already present?
  foreach ( @$affiliations ) {
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
  
  push @$affiliations, $institution;

  adjust_shares( $app );

  $app -> sevent ( -class => 'affil',
                  -action => 'add',
                   -descr => $institution ->{name},
                -location => $institution ->{location},
     ( $instid ) ? ( -id  => $instid ) : (),
                 );

  $app -> variables ->{processed} = 1;
}



sub remove {
  my $app = shift;
  my $instid = shift || '';
  my $name   = shift || '';
  
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $affiliations = $record -> {affiliations};
  
  return 
    unless defined $affiliations and scalar @$affiliations;
  
  assert( $name or $instid );
  debug "remove institution id: $instid, n: $name";
  $app -> userlog( "affil: request to remove an item, id: $instid, n: $name" );

  my $remove;
  foreach $_ ( @$affiliations ) {

      #debug "remove $_->{id} / $_->{name}?";
      if ( $instid and $_->{id} 
           and $_->{id} eq $instid ) {
          $remove = $_;

      } elsif ( $name and not $_->{id} and $_->{name} 
           and $name eq $_->{name} ) {
          $remove = $_;
      }

      if ($remove) {
          undef $_;
          
          $app -> userlog( "affil: removed affiliation " . ( $instid ? $instid : $name )  );
          $app -> sevent ( -class => 'affil',
                           -action=> 'remove',
                           -descr => $remove ->{name},
                        -location => $remove ->{location},
                             -id  => $remove ->{id},
                   );
          last;
      }

  }

  clear_undefined( $affiliations );

  if ( not $remove ) {
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
  my $affiliations = $session -> current_record->{affiliations};

  my $input   = $app -> form_input;
  my $sql     = $app -> sql_object;
  my $db = $app -> config( 'metadata-db-name' );
  my $key   = $input ->{ 'search-what' } || '';
  my $field = $input ->{ 'search-by' }   || '';
  $field =~ s/[^a-z]//g;  # untaint

  $app -> userlog( "affil: search: by $field, key: '$key'", );

  return unless ( $field =~ /^(location|name)$/ );

  if ( not $key or not $field ) { die; }

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

  # THE PLAN IS:
  #
  # - check the search options, if any
  #   --  options: search-mode: only-exact | all-words | loose-match 
  # - do the exact key expression search
  #   --  "select from institutions where $the_field like '%$key%'"
  #       --  shall we include word-boundary condition into the where block?  
  #           Yes, we should!  But how?  
  #   > SELECT "a word a" REGEXP "[[:<:]]word[[:>:]]";      -> 1
  #   > SELECT "a xword a" REGEXP "[[:<:]]word[[:>:]]";     -> 0
  #
  # - filter the results -- remove those, which are already_there
  #   decide: is it enough or shall we search for more?  (search options?)
  #   -- if there's more than 10 results and the search-mode is not
  #      "all-words" or "loose-match", we stop at this
  #   -- independently of the amount of hits, we shall stop if search-mode is
  #      "only-exact".  Or we may do the all-words search and say to the user, 
  #      that it might (or might not) be useful.
  # - if we shall search further, build a list of already_found handles
  # - execute full-text search and then filter out already_there,
  #   already_found
  # - unless we run a really permissive search, we shall leave out those
  #   items, which don't contain at least one word of the @words
  # - present the results


  my $mode = 'all-words';
  if ( $input->{'exact-only'} ) {       $mode = 'exact-only';
  } elsif ( $input->{'loose-match'} ) { $mode = 'loose-match';  }

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

  # - decide: is it enough or shall we search for more?  (search options?)
  #   -- if there's more than 10 results and the search-mode is not
  #      "all-words" or "loose-match", we stop at this
  #   -- independently of the amount of hits, we shall stop if search-mode is
  #      "only-exact".  Or we may do the all-words search and say to the user, 
  #      that it might (or might not) be useful.


  ###    prepare search results
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
       and not $input ->{'show-all-results'} ) {
    return;
  }
  if ( $mode eq 'only-exact' and scalar @exact_matches > 4 ) {
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
    # eval thaw
    ## schmorp
    #my $institution = eval { thaw $data; };
    my $institution = inflate($data);
    ## /schmorp
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



sub general_handler {
  my $app   = shift;
  
  debug "running affiliation service screen";
  my $session = $app -> session;
  my $record  = $session -> current_record;
  my $input   = $app -> form_input;
  my $affiliations = $record -> {affiliations};
   
  if ( $input -> {continue} ) { 
    if ( $session -> type eq 'new-user' ) {
      $app -> redirect_to_screen_for_record ( 'research' );
      
    } else {
      $app -> message( "saved" );
      $app -> redirect_to_screen_for_record ( 'menu' );
    }
    
  } else {  
    my $cha;
    if ( $input -> {add}
         and $input->{id} ) { add( $app, $input->{id} ); $cha = 1; }
    if ( $input -> {search} ) { search( $app ); }

    # cycle through the input params (from the form), analyse them,
    # understand, what the user wants.
    #
    # parameters that we expect here: id<N>, remove<N>, name<N>,
    # share<N>, where <N> is an integer number.

    my $form = [];
    my $save_shares = 0;
    foreach my $k (keys %$input) {
        my $v = $input->{$k};
        if( $k =~ m/^(\w+)(\d+)/ ) { $form->[$2]{$1} = $v; debug "affiliations form: param $1 of $2 ='$v'"; next; }
        if( $k eq 'saveshare' ) {    $save_shares = 1;  }
    }

    foreach ( @$form ) {
        my $idorname = $_->{id} || $_->{name};
        if (not $idorname) {
            debug "no id and no name item";
            next;
        }
        if ( $_->{remove} ) { 
            debug "remove $idorname";
            remove( $app, $_->{id}, $_->{name} );
            next;
        }
        if ( $_->{share} ) {
            my $input = $_;
            debug "set share of $idorname to " . $_->{share};            
            foreach ( @$affiliations ) {
                # set the share
                if ( ($_->{id} and ($_->{id} eq $idorname))
                     or ($_->{name} eq $idorname )) {
                    $_->{share} = $input->{share};
                    last;
                }
            }
        }
    }
    
    if ($save_shares) {
        debug "Saved shares; need checking";
        adjust_shares( $app );
        sort_by_share( $app );
    }

    if ( $session -> type eq 'new-user' and $cha ) {
      $app -> message( "saved" );
      $app -> set_presenter( 'affiliations-ir-guide' );
    }
    
  }
}


sub adjust_shares {
    my $app = shift || die;
    my $affiliations = $app->session->current_record->{affiliations};

    return if scalar @$affiliations == 0;
    return if scalar @$affiliations == 1; # with just one affiliation there's nothing to adjust, really

    debug "affiliations share adjustment";

    # rules:
    #  1. total must be exactly 100
    #  2. each item must be in the 1..99 range, inclusively
    #  3. if we adjust the values, we adjust them proportionally

    # set undef values to a default
    my $share_default = 20;
    foreach (@$affiliations) {
        my $idorname = $_->{id} || $_->{name};
        debug "  " . $idorname  . ": " . $_->{share};
        if (not $_->{share}) {
            $_->{share} = $share_default;
        }
    }

    # calculate current total
    my $init_total = 0;
    foreach (@$affiliations) {
        $init_total += $_->{share};
    }
    debug "initial total: $init_total";

    if ($init_total == 100) { return 1; }

    # adjustment coefficient? (rule 3)
    my $adjust_by = 100 / $init_total;

    foreach (@$affiliations) {
        $_->{share} *= $adjust_by;
    }

    my $total;
    foreach (@$affiliations) {
        $total += $_->{share};
    }
    debug "total after coefficient adjustment: $total";
    
    # smart rounding, rule 2
    $total = 0;
    foreach (@$affiliations) {
        if ($_->{share} < 1) { $_->{share} = 1; }
        elsif ($_->{share}>99) { $_->{share} = 99; }
        else { $_->{share} = sprintf( "%u", $_->{share} ); }
        $total += $_->{share};
    }


    # final adjustments, rule 1
    while ( $total != 100 ) {
        if ( $total > 100 ) {
            # find largest and cut it
            my $max;
            my $max_i;
            my $index = 0;
            foreach (@$affiliations) {
                if ( not $max ) {
                    $max = $_->{share};
                    $max_i = 0;
                } elsif ( $_->{share} > $max ) {
                    $max = $_->{share};
                    $max_i = $index;
                    last;
                }
                $index ++;   
            }
            $affiliations->[$max_i]->{share}--;
            
        } else {
            # find smallest and add to it
            my $min;
            my $min_i;
            my $index = 0;
            foreach (@$affiliations) {
                if ( not $min ) {
                    $min = $_->{share};
                    $min_i = 0;
                } elsif ( $_->{share} < $min ) {
                    $min = $_->{share};
                    $min_i = $index;
                    last;
                }
                $index ++;   
            }
            $affiliations->[$min_i]->{share}++;
        }

    } continue {
        $total = 0;
        foreach (@$affiliations) {
            if ($_->{share} < 1) { $_->{share} = 1; }
            elsif ($_->{share}>99) { $_->{share} = 99; }
            else { $_->{share} = sprintf( "%u", $_->{share} ); }
            $total += $_->{share};
        }
    }

    debug "result: ";
    foreach (@$affiliations) {
        my $idorname = $_->{id} || $_->{name};
        debug "  " . $idorname  . ": " . $_->{share};
    }
    
    return 1;
    
}


sub sort_by_share {
    my $app = shift;
    my $affiliations = $app->session->current_record->{affiliations};
    
    @$affiliations = sort { $b->{share} <=> $a->{share} } @$affiliations;
}



sub submit_institution {
  my $app = shift;
  my $session = $app -> session;
  my $institution = {};
  my $input = $app -> form_input;
  my $name    = $input -> {name};
  my $id      = $input -> {id} || '';

  assert( $name );
  debug "submit: name: $name";
  debug "submit:   id: $id";

  foreach ( qw( name name-english location homepage 
                email phone fax   postal   note id
                add-to-profile ) ) {
    if ( defined $input->{$_} ) {
      $institution -> {$_} = $input->{$_};
    }
  }
  for ( $institution ) {
    if ( $_ ->{note} 
         and length( $_->{note} ) > 750 ) {
      substr( $_->{note}, 750 ) = '...';
    }
    $_ -> {'submitted-by'} = $session -> owner -> {login};
  }

  if ( $session -> {'submitted-institutions'} ) {
    ### append or replace an institution in the submitted list
    my $list = $session -> {'submitted-institutions'};
    my $replace;
    my $counter = 0;

    foreach ( @$list ) {
      if( $_ -> {name} eq $name 
          or ( $_->{id} and $id and ( $_->{id} eq $id ) )  ) {
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
    $session->{'submitted-institutions'} = [ $institution ];
    $session->run_at_close( 'require ACIS::Web::Affiliations; 
ACIS::Web::Affiliations::send_submitted_institutions_at_session_close( $self );' );
  }

  # adding an institution to the profile
  if ( $input -> {'add-to-profile'} ) {
    debug "adding a submitted institution ($name) to the record";
    $app -> userlog( "affil: add a submitted institution, name: $name", $id ? " id: $id" : '' );
  
    my $record  = $session -> current_record;
    assert( $record->{type} eq 'person' );
    if ( not defined $record -> {affiliations} ) {
        $record -> {affiliations} = [];
        $app -> variables ->{affiliations} = $record->{affiliations};
    }
    my $affiliations = $record->{affiliations};

 
    ### additional check
    my $replace;
    my $counter = 0;
    foreach ( @$affiliations ) {
      if ( ($_->{name} eq $name) 
           or ( defined $_->{id} 
                and $id
                and ($_->{id} eq $id) )
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
      
    } else {
      debug "adding new item";
      push @$affiliations, $institution;
      adjust_shares( $app );
      sort_by_share( $app );

    $app -> sevent ( -class => 'affil',
                    -action => 'submit-add',
                     -descr => $institution ->{name},
                  -location => $institution ->{location},
($institution->{id})? ( -id => $institution ->{id} ): (),
                   );
    }
  
  } else {
    debug "not needed to add";
    $app -> userlog( "affil: submited an institution, but asked not to add it, name: $name", 
                     ($id ? " id: $id" : '') );
    $app -> sevent ( -class => 'affil',
                    -action => 'submit-not-add',
                     -descr => $institution ->{name},
                  -location => $institution ->{location},
($institution->{id})? ( -id => $institution ->{id} ): (),
                   );
  }

  $app  -> message( "institution-submission-accepted" );

  if ( $session -> type eq 'new-user' ) {
    $app -> set_presenter( 'affiliations-ir-guide' );
    
  } else {
    $app -> redirect_to_screen_for_record ( 'affiliations' );
  }
}


sub send_submitted_institutions_at_session_close {
  my $session = shift;
  my $acis = $ACIS::Web::ACIS;
  my $submitted = $session->{'submitted-institutions'};
  my $template = 'email/new-institution.xsl';
  if ($acis->config( 'service-mode' ) eq 'ras') { $template = 'email/new-institution-ras.xsl'; }

  if ( $submitted and ref $submitted ) {
    foreach ( @$submitted ) {
      next if not $_;
      $acis ->variables ->{institution} = $_;
      $acis ->send_mail( $template );
      undef $_;
    }
  }
}



1; 
