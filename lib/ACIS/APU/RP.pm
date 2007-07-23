package ACIS::APU::RP;        ### -*-perl-*-  
# previously was known as ACIS::Web::ARPM
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Automatic Profile Update (APU) for Research Profile
#
#  Copyright (C) 2004-2007 Ivan Kurmanov for ACIS project, http://acis.openlib.org/
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
use ACIS::Web;
use ACIS::Web::SysProfile;

require ACIS::Web::Contributions;
use ACIS::Resources::Suggestions;
use ACIS::Resources::AutoSearch;
use ACIS::Resources::Search;

use Web::App::Common qw( debug );

*APP = *ACIS::Web::ACIS;
use vars qw( $APP @ISA @EXPORT_OK $interactive );

use ACIS::APU qw( logit );

my $app = $APP;
my $session;
my $vars   ;
my $record ;
my $id     ;
my $sid    ;
my $sql    ;

my $contributions ;
my $accepted      ;
my $already_accepted;
my $already_rejected;
my $pref            ;
my $suggestions;
my $original ;
my $pretend;


sub interactive { $interactive = 1; }

sub search {
  $app = shift;
  $pretend = shift; ### XXX not implemented yet

  debug "enter RP::search()";

  $session = $app -> session;
  $vars    = $app -> variables;
  $record  = $session -> current_record;
  $id      = $record ->{id};
  $sid     = $record ->{sid};
  $sql     = $app -> sql_object;

  logit "research search for $sid";

  ####  general preparations
  ACIS::Web::Contributions::prepare( $app );
  $contributions = $vars -> {contributions};
  $accepted      = $contributions ->{accepted};
  $already_accepted = $contributions -> {'already-accepted'};
  $already_rejected = $contributions -> {'already-refused'};
  $pref        = $contributions -> {preferences} {arpm};

  my $send_email;
 
  debug "prepare";
  prepare_for_auto_search( $app );
  debug "original load";
  $suggestions = load_suggestions( $app, $sid );
  $original = get_suggestions_ids( $suggestions );

  if ( scalar keys %$original ) {
    $vars -> {'original-suggestions'} = $original;
  }

  ###  Handle search
  {
    debug "handle search";
    my @new_ids = ();
    my $rel_tab_db = $app -> config('metadata-db-name');
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
      my $new_full = load_resources_by_ids( $app, \@new_ids );
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
          clear_from_autosearch_suggestions( $app, $sid, $clear_sids );
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
          save_suggestions($sql, $sid, 'exact-person-id-match', undef, \@add_to_suggest_table);
        }
        
        if ( scalar @reset_reason_sids ) {
          set_suggestions_reason($app, $sid, "exact-person-id-match", \@reset_reason_sids);
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
       or $pref -> {'name-search'} ) {{ # double braces for the last statement used inside it
  
    my $add = [];
    my @suggest_exact;
    my @suggest_approx;
    my $handler = sub { # auto-add handler
      my ($sql,$context,$reason,$role,$results) = @_;
      if ($reason eq 'exact-name-variation-match'
          or $reason eq 'exact-email-match') {
        if ($add) {
          push @$add, @$results;
          return;
        } else {
          push @suggest_exact, @$results;
        }
      } else {
        push @suggest_approx, @$results;
      }
      # default action:
      save_suggestions(@_);
    };
    if ( not $pref->{'add-by-name'} ) {
      undef $add; 
    }

    automatic_resource_search_now( $app, { save_result_func => $handler, via_apu => 1 } );

    if ( $add and scalar @$add ) {
        $send_email = 1;
        ###  add to accepted contributions
        my $c = 0;
        foreach ( @$add ) {
          ACIS::Web::Contributions::accept_item( $_ );
          $c++;
        }
        logit "name search: added ", $c;
    } 
    elsif (scalar @suggest_exact) { $send_email = 1; }
    else { last; }

    if ($add and scalar @$add) { $vars->{'added-by-name'} = $add; }
    my $s = \@suggest_exact;
    if ($app->config('apu-research-mail-include-approx-hits')) { # include approximate matches also
      push @$s, @suggest_approx; 
      $vars->{'suggest-by-name-includes-approx'}= scalar @suggest_approx;
    }
    
    if (my $max = $app->config('apu-research-max-suggestions-in-a-mail')) {
      if ( (my $all = scalar @$s) > $max ) {
        $#$s = $max-1;
        $vars->{'suggest-by-name-listed-first'}=$max;
        $vars->{'suggest-by-name-total-number'}=$all;
      }
    }

    $vars->{'suggest-by-name'} = $s;
  }} ### double braces intentional -- needed for the "last" statement
  

  
  if ( $send_email ) {
    delete $vars -> {contributions} {suggest};

    if ( $vars -> {'added-by-name'} 
         or $vars -> {'added-by-handle'} ) {
      require ACIS::Web::SaveProfile;
      ACIS::Web::SaveProfile::save_profile( $app );
    }

    my %params = ();
    if ( $app -> config( "echo-apu-mails" ) ) {
      $params{-bcc} = $app -> config( "admin-email" );
    }

    require Web::App::Email;
    Web::App::Email::send_mail( $app, "email/arpm-notice.xsl", %params );
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


1;
