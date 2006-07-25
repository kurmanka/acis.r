package ACIS::Web::ARPM;        ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Automatic Research Profile Update (old: Maintenance)
#
#
#  Copyright (C) 2004 Ivan Kurmanov for ACIS project, http://acis.openlib.org/
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
#  $Id: ARPM.pm,v 2.1 2006/07/25 14:14:55 ivan Exp $
#  ---



use strict;
use ACIS::Web;

use ACIS::Web::SysProfile;

require ACIS::Web::Contributions;
require ACIS::Web::Contributions::Back;

use Web::App::Common qw( debug );

*APP = *ACIS::Web::ACIS;
use vars qw( $APP @ISA @EXPORT_OK $interactive );


require Exporter;
@ISA       = qw( Exporter );
@EXPORT_OK = qw( logit );

my $app = $APP;

my $session;
my $vars   ;
my $record ;
my $id     ;
my $sid    ;
my $sql    ;

my $contributions ;
my $accepted      ;
#my $refused       ;

my $already_accepted;
my $already_rejected;

my $autosearch      ;
my $pref            ;

my $suggestions;
my $original ;

my $pretend;


sub interactive { $interactive = 1; }

my $logfile;

sub logit (@);

sub logit (@) {

  if ( not $logfile and $APP ) {
    $logfile = $APP -> home . "/arpu.log";
  }

  if ( $logfile ) {
    open LOG, ">>:utf8", $logfile;
    print LOG scalar localtime(), " [$$] ", @_, "\n";
    close LOG;
  } else {
    warn "can't logit: @_";
  }

  if ( $interactive ) {
    print @_, "\n";
  }
}
  



sub search {
  $app = shift;
  $pretend = shift; ### XXXX not implemented yet

  debug "enter ARPM::search()";

  $session = $app -> session;
  $vars    = $app -> variables;
  $record  = $session -> current_record;
  $id      = $record ->{id};
  $sid     = $record ->{sid};
  $sql     = $app -> sql_object;

  logit "ARPU search for $id ($sid)";

  ####  general preparations
  ACIS::Web::Contributions::prepare( $app );

  $contributions = $vars -> {contributions};
  $accepted      = $contributions ->{accepted};
#  $refused       = $contributions ->{refused};

  $already_accepted = $contributions -> {'already-accepted'};
  $already_rejected = $contributions -> {'already-refused'};

  $autosearch  = $contributions -> {autosearch};
  $pref        = $contributions -> {preferences} {arpm};

  my $send_email;
  
  debug "prepare";

  ACIS::Web::Contributions::prepare_for_auto_search( $app );

  debug "original load";

  $suggestions = 
    ACIS::Web::Contributions::Back::load_suggestions
       ( $app, $sid, 'contributions' );
  
  $original = get_suggestions_ids( $suggestions );


  if ( scalar keys %$original ) {
    $vars -> {'original-suggestions'} = $original;
  }

#  $vars -> {'original-already-accepted'} = join ' ', keys %$already_accepted;
#  $vars -> {'original-already-rejected'} = join ' ', keys %$already_rejected;


  ###  Handle search
  
  {
    debug "handle search";

    my @new_ids = ();
    
    my $rel_tab_db = $app -> config -> {'metadata-db-name'};
    my $rel_tab    = "$rel_tab_db.relations";
    
    my @refs  = ();
    my %roles = ();
    
    foreach ( qw( wrote/author edited/editor ) ) {
      my ( $relation, $role ) = ( m!^([^/]+)/(.+)$! );

      $sql -> prepare_cached(
       "select object from $rel_tab where subject=? and relation=? and source !=?"
                            );
      my $res = $sql -> execute( $id, $relation, $id );
      
      if ( not $res ) {        debug "bad query";     } 
      if ( not $res->{row} ) { debug "nothing found"; }             

      while ( $res and $res->{row} ) {
        my $obj = $res -> {row} {object};
        push @refs, $obj;
        $roles{$obj} = $role;
        debug "found $role for $obj";

        $res -> next;
      }
    }
    
    
    foreach ( @refs ) {
      if ( not $already_accepted -> {$_} 
           and not $already_rejected -> {$_} ) {
        push @new_ids, $_;
      }
    }

    ###  shouldn't I also check if the item is among suggestions already?
    
    ###  It may turn out that we already found the thing and already
    ###  suggested it through email, may it not?

    if ( scalar @new_ids ) {
      
      logit "id search: found ", scalar @new_ids, " items";

      $send_email = 1;

      ###  get full descriptions and build a list of short-ids

      my $new_full = ACIS::Web::Contributions::load_resources_by_ids( $app, \@new_ids );
      my @new_sids;

      
      foreach ( @$new_full ) {
        die if not $_ ->{sid};
        push @new_sids, $_ -> {sid};

        my $id = $_ ->{id};
        $_ -> {role} = $roles{$id};
        die if not $_->{role};
      }
      
      my $reread_suggestions;


      if ( not $pref 
           or not defined $pref -> {'add-by-handle'}
           or $pref -> {'add-by-handle'}  ) {
        
        # push @$accepted, 
        foreach ( @$new_full ) {
          ACIS::Web::Contributions::accept_item( $_ );
        }
        logit "id search: added";

        my $clear_sids = {};

        foreach ( @$new_full ) {
          my $id  = $_ ->{id};
          my $sid = $_ ->{sid};
          if ( $original -> {$id} ) {
             $clear_sids -> {$sid} = 1;
          }
        }


         ###  remove from suggestions, if its there
         if ( scalar keys %$clear_sids ) {

           ACIS::Web::Contributions::Back::clear_from_autosearch_suggestions
               ( $app, $sid, $clear_sids );

           $reread_suggestions = 1;
         }

         ###  add into variables as "added-by-handle"
         $vars -> {'added-by-handle'} = $new_full;
        


       } else {   ### add-by-handle disallowed
         ###  So, this means we need to simply suggest the items in an email
         ###  and add them to the suggestions table.  If they are in the
         ###  suggestions table already, we need to make sure they have reason
         ###  "exact-person-id-match".
         
         $send_email = 0;

         my @suggest;
         my @reset_reason_sids;
         my @add_to_suggest_table;


         foreach ( @$new_full ) {
           my $rid  = $_ ->{id};  ###  resource id
           my $rsid = $_ ->{sid}; ###  resource sid

           my $suggest;

           if ( $original -> {$rid} ) {
             ###  already suggested, suggest again if they had a weaker
             ###  suggestion reason.

             if ( $original ->{$rid} {reason} eq 'exact-person-id-match' ) {
               ### do not repeat
               ### do nothing at all 

             } else {
               delete $original -> {$rid};
               
               ###  set the suggestion reason to "exact-person-id-match"

               $send_email = 1;
               push @suggest, $_;
               push @reset_reason_sids, $rsid;
             }

           } else {
             $send_email = 1;

             push @suggest, $_;
             push @add_to_suggest_table, $_;

           }
         }


         if ( scalar @add_to_suggest_table ) {
           ###  add to suggestions: prepare data

           ACIS::Web::Contributions::Back::save_suggestions
               ( $sql, $sid, 'exact-person-id-match', 
                 '', \@add_to_suggest_table );
         }
         
         if ( scalar @reset_reason_sids ) {
           ACIS::Web::Contributions::Back::set_suggestions_reason
               ( $app, $sid, "exact-person-id-match", \@reset_reason_sids );
         }

         ###  add into variables as "suggest-by-handle"
         $vars -> {'suggest-by-handle'} = \@suggest;
         
       } ###  add-by-handle: true, false
    
    } ###  found something?
      else {
#        logit "id search: nothing found";
    }        
    
  }  ###  do handle search ?
  


  ###  Name search
  debug "name search";

  ###  does user want us to do a name search?
  if ( not defined $pref 
       or not defined $pref ->{'name-search'}
       or $pref -> {'name-search'} ) {

  
    $suggestions = 
      ACIS::Web::Contributions::Back::load_suggestions
          ( $app, $sid, 'contributions' );
    
    my $count1 = count_suggestions  ( $suggestions );
    my $before = get_suggestions_ids( $suggestions );
    
    ACIS::Web::Contributions::automatic_search( $app );

    $suggestions = 
      ACIS::Web::Contributions::Back::load_suggestions
          ( $app, $sid, 'contributions' );
    
    my $after  = get_suggestions_ids( $suggestions );
    my $count2 = count_suggestions  ( $suggestions );

    if ( $count1 < $count2 ) {

      logit "name search: something found";

      ### something found
      my $suggest = [];
      my $added   = [];

      my $new  = compare_hashes( $before, $after );
      my ( $exactlist, $approxlist ) = straighthen_works_hash( $new ); 
      
      if ( scalar @$exactlist ) {

        $send_email = 1;
        if ( $pref -> {'add-by-name'} ) {
          ###  add to $accepted
          foreach ( @$exactlist ) {
            ACIS::Web::Contributions::accept_item( $_ );
          }
          logit "name search: added ", scalar @$exactlist;

        } else {
          push @$suggest, @$exactlist;
        }
      }
      
      if ( scalar @$approxlist ) {
        push @$suggest, @$approxlist;
      }

      if ( scalar @$added )   { $vars -> {'added-by-name' }  = $added;   }
      if ( scalar @$suggest ) { $vars -> {'suggest-by-name'} = $suggest; }
      
    } else {
      ### nothing interesting
#      logit "name search: nothing found";
      
    }

  }


  
  if ( $send_email ) {
    delete $vars -> {contributions} {suggest};

    if ( $vars -> {'added-by-name'} 
         or $vars -> {'added-by-handle'} ) {
      require ACIS::Web::SaveProfile;
      ACIS::Web::SaveProfile::save_profile( $app );
    }

    my %params = ();
    if ( $app -> config( "echo-arpu-mails" ) ) {
      $params{-bcc} = $app -> config( "admin-email" );
    }

    require Web::App::Email;
    Web::App::Email::send_mail( $app,
                                "email/arpm-notice.xsl",
                                %params
                              );
    logit "email sent";

    foreach ( qw( added-by-handle added-by-name 
                  original-suggestions suggest-by-name suggest-by-handle ) ) {
      delete $vars -> {$_};
    }

    return "OK-1";
  }

  return "OK-0";
}


sub count_suggestions { 
  my $suggestions = shift;
  my $count = 0;

  foreach ( @$suggestions ) {
    my $list = $_ -> {list};
    $count += scalar @$list;
  }
  return $count;
}


sub get_suggestions_ids { 
  my $suggestions = shift;
  my $ids = {};

  foreach ( @$suggestions ) {
    my $g      = $_; ## the group
    my $list   = $_ -> {list};

    foreach ( @$list ) {
      my $item = $_;
      my $id   = $_ -> {id};
      $ids ->{$id} = $_;

      for ( qw( reason status ) ) {
        if ( not $item ->{$_} ) {
          ##  copy from the group
          $item -> {$_} = $g -> {$_};
        }
      }
    }
  }
  return $ids;
}



sub compare_hashes {
  my $first = shift;
  my $secon = shift;
  
  my $diff  = {};

  foreach ( keys %$secon ) {
    my $k = $_;
    my $v = $secon ->{$k};
    
    if ( not $first -> {$k} ) {
      $diff -> {$k} = $v;
    }
  }
  return $diff;
}



sub straighthen_works_hash {
  my $hash = shift;
  
  ###  Group suggestions by certainty, and return in order of decreasing
  ###  certainty, in such groups.

  my @handle = ();
  my @exact  = ();
  my @approx = ();
  my @bysurname = ();

  foreach ( keys %$hash ) {
    my $v = $hash -> {$_};
    my $r = $v ->{reason};

#    logit "work: " . $v->{title} . " ($r)";
    
    if ( $r eq 'exact-person-id-match' ) {
      $v -> {status} = 1;
      push @handle, $v;
#      logit "> handle group";

    } elsif ( $r =~ m/\bexact\b/ ) {
      $v -> {status} = 1;
      push @exact, $v;
#      logit "> exact group";

    } elsif ( $r =~ m/appro/ ) {
      push @approx, $v;
#      logit "> approximate group";
      
    } elsif ( $r eq 'surname-part-match' ) {
      push @bysurname, $v;
#      logit "> just surname group";

    } elsif ( $r =~ m/\bpart\b/ ) {
      push @approx, $v;
#      logit "> approx group";

    } else {
#      logit "no reason or an unknown reason";
    }
  }

  my @list1 = ( @handle, @exact );
  my @list2 = ( @approx );

  return ( \@list1, \@list2, \@bysurname );
}



################

sub get_login_from_queue_item {

  my $acis = shift;
  my $item = shift;
  my $login;
#  print "get login for $item\n";

  if ( length( $item ) > 8 
       and $item =~ /^.+\@.+\.\w+$/ ) {

    return lc $item;

  } else {

    my $sql = $acis -> sql_object;

    if ( length( $item ) > 15
         or index( $item, ":" ) > -1 ) {

#      print "is it an identifier?\n";
      $sql -> prepare( "select owner from records where id=?" );
      my $r = $sql -> execute( lc $item );
      if ( $r and $r -> {row} ) {
        $login = $r ->{row} {owner};

      } else {
        logit "get_login_from_queue_item: id $item not found";
      }

    } elsif ( $item =~ m/^p[a-z]+\d+$/ 
              and length( $item ) < 15 ) {

#      print "is it an sid?\n";
      $sql -> prepare( "select owner,id from records where shortid=?" );
      my $r = $sql -> execute( $item );
      if ( $r and $r -> {row} ) {
        $login = $r ->{row} {owner};

      } else {
        logit "get_login_from_queue_item: sid $item not found";
      }

    }
  }

  return $login;
}

1;
