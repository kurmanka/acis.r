package ACIS::Resources::Search;

# Low-level search for resources (i.e. academic contribution items,
# research, etc.) functions

use strict;
use warnings;

use Carp::Assert;
use Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw( 
              make_resource_item_from_db_row 
              reload_contribution 
              load_resources_by_ids
              process_resources_search_results
              query_resources
              search_resources_for_exact_name
              search_resources_by_creator_email
              search_resources_for_exact_phrases
           );
## schmorp
#use Storable qw(thaw);
use Common::Data;
## /schmorp
use Web::App::Common;
use Data::Dumper;

sub make_resource_item_from_db_row {
  my $row = shift;
  assert( $row );
  my $data = $row ->{data} || return undef;
  my $id   = $row ->{id};
  my $role = $row ->{role};
  my $item;
  ## schmorp
  #eval { $item = thaw ( $data ); };
  #if ( $@ ) { 
  #  complain "failed to thaw() a database-loaded resource record: $@";
  #  $item = $row; 
  #  delete $row ->{data}; 
  #  undef $@; 
  #}
  $item = &Common::Data::inflate($data);
  ## /schmorp
  $item -> {'id'}  = $id;
  if ( $role ) { $item -> {role} = $role; }
  return $item;
}

sub reload_contribution {       
  my $app  = shift;
  my $id   = shift || die;
  my $db   = $app ->config("metadata-db-name")|| die;
  my $sql  = $app ->sql_object;
  my $item;
  $sql -> prepare_cached ( "select data from $db.objects where id=?" );
  warn "SQL: " . $sql->error if $sql->error;
  my $res = $sql -> execute ( $id );
  warn "SQL: " . $sql->error if $sql->error;
  my $row = $res -> {row};
  if ( $row ) {
    if ( $row->{data} ) {
      ## schmorp
      #$item = eval {thaw( $row->{'data'} ); };
      $item=&Common::Data::inflate($row->{'data'});
      ## /schmorp
    }
  } 
  else {
    debug "didn't find object for $id";
  }
  return $item;
}


sub load_resources_by_ids {
  my $app  = shift;
  my $ids  = shift;
  assert( $ids and ref $ids );
  my @list;
  my $db   = $app ->config("metadata-db-name") || die;
  my $sql  = $app ->sql_object;
  $sql -> prepare_cached ( "SELECT data FROM ${db}.objects WHERE id=?" );
  foreach ( @$ids ) {
    my $res = $sql -> execute( $_ );
    if ( $sql ->error ) { 
      warn "SQL: " . $sql-> error ;
      next;
    }
    my $row = $res -> {row};
    if ( $row and $row->{'data'} ) {
      ## schmorp
      #my $item = eval { thaw $row->{'data'}; };
      my $item = &Common::Data::inflate($row->{'data'});
      ## /schmorp
      push @list, $item;
    } else {
      debug "didn't find $_";
    }
  }
  return \@list;
}

# this is used by functions below and by the SearchFuzzy module
sub process_resources_search_results {
  my $sqlres  = shift || die;
  my $context = shift;
  my $result  = shift;  ## array ref

  my $found_hash   = $context ->{found};
  my $filter_hash  = $context ->{already};

  my $row;
  while ( $row = $sqlres->{row} ) {
    # for some reason, the $row is sometimes empty; at least it doesn't
    # contain any useful data
    my $id  = $row -> {id} || next;
  
    if ( $id and $found_hash->{$id}++ ) { next; }
    if ( $filter_hash->{$id} ) { next; }
    
    # for performance reasons put make_resource_.. inline:
    #    my $item = make_resource_item_from_db_row( $row ); 
    #my $item = eval { thaw( $row ->{'data'} ); };
    ## schmorp
    my $item = &Common::Data::inflate($row->{'data'});
    #my $error=$@;
    ## evcino 
    #if ( not $item) {
    #  complain "could not thaw record $id: $error," . $row->{'data'};
    #  use Lib32::Decode;
    #  $item=Lib32::Decode::via_daemon($row->{'data'});
    #  $error=$@;
    #}
    #if ( not $item) {
    #  complain "Lib32 could not thaw record $id: erorr $@" . $row->{'data'};
    #}
    ## /schmorp
    if(not $item->{'id'} or not $item->{'sid'}) {
      complain "bad document record found: (id: $id)\n" . Dumper( $row );
    } 
    else {
      $item ->{'role'} = $row->{'role'} 
        if $row->{'role'};
      push @$result, $item;
    }    
  } 
  continue {
    $sqlres -> next;
  }  
  $sqlres -> finish;
}


sub query_resources ($$) {
  my $table = shift;
  my $where = shift;
  my $q;
  my $DB = $ACIS::Web::ACIS->config('metadata-db-name');

  if ( $table eq 'resources' ) {
    ### by resources from objects
    $q = qq!SELECT catch.id as id,lib.data as data
FROM $DB.resources as catch
JOIN $DB.objects as lib
 ON catch.id = lib.id
WHERE $where
!;

  } else {
    ### by some other table (catch) via resources (lookup) from objects 
    $q = qq!SELECT lookup.id as id,lib.data as data,catch.role as role
FROM $DB.$table as catch 
JOIN $DB.resources as lookup
 ON catch.sid = lookup.sid
JOIN $DB.objects as lib
 ON lookup.id = lib.id
WHERE $where
!;
  }

  if ( $q !~ m/\sLIMIT\s+\d+\s*$/i ) {
    $q .= ' LIMIT 2000'; ## magic number: maximum records returned from a search
  }
  return $q;
}



sub search_resources_for_exact_name {
  my $sql     = shift;
  my $context = shift;
  my $name    = shift;

  return undef if not $name or length( $name ) < 2;
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
  $sql -> prepare_cached(query_resources 'res_creators_separate', 'catch.email=?');
 
  my $res = $sql->execute ( lc $email );
  if ( $res ) {
    debug "query for exact creator email: '$email', found: " . $res -> rows . " items";
    process_resources_search_results( $res, $context, $result );
  }

  return $result;
}
  




####   There's very little point in such search.  I guess fulltext search
####   would have been more reasonable.

sub search_resources_for_exact_phrases {
  my $sql      = shift;
  my $context  = shift;
  my $namelist = shift;
  my $result = [];
  my $q = '';

  my $names_notsuitable = []; # some names may be too short for this search
                              # method; then we have to use _regexp variant
                              # for them
  foreach ( @$namelist ) {
    my $name = $_;

    next if not $name or length( $name ) < 2;
    if ( not m/\w{4,}/ ) {  # the phrase must contain at least a 4-letter
                            # word (or longer) to find anything, given the
                            # default mysql settings (ft_min_word_len server
                            # system variable)
      push @$names_notsuitable, $_;
      next;
    }

    $name =~ s/\.$//g; # remove final dot (or word boundary won't match)
    next if not $name or length( $name ) < 2;

    # escape unsafe chars
    $name =~ s!([\.*?+{}()|^[\];])!\\$1!g;
    $q .= '"';
    $q .= $name;
    $q .= '" ';
  }

  if ( $q ) {
    chop $q;

    ###  the query
    $sql -> prepare_cached( 
                           query_resources 'res_creators_separate', "match (catch.name) against (? IN BOOLEAN MODE)"
                          );
    
    warn "SQL: " . $sql->error if $sql->error;
    my $res = $sql->execute( $q );
    warn "SQL: " . $sql->error if $sql->error;
    
    if ( $res ) {
      debug "ft phrase search in creators' names, found: " . $res -> rows . " items";
      process_resources_search_results( $res, $context, $result );
    }
  }

  if ( scalar @$names_notsuitable ) {
    debug "some phrases are not suitable for fulltext search: " . join( ' * ', @$names_notsuitable);
    search_resources_for_exact_phrases_regexp( $sql, $context, $names_notsuitable, $result );
  }
  return $result;
}

sub search_resources_for_exact_phrases_regexp {
  my $sql      = shift;
  my $context  = shift;
  my $namelist = shift;
  my $result   = shift || [];

  my $re = ' ' x 500; # pre-allocate some space

  $re = '[[:<:]]('; # regular expression: at word start

  foreach ( @$namelist ) {
    my $name = $_;
    $name =~ s/\.$//g; # remove final dot (or word boundary won't match)
    next if not $name or length( $name ) < 2;

    # escape unsafe chars
    $name =~ s!([\.*?+{}()|^[\];])!\\$1!g;
    $re .= $name;
    $re .= '|';
  }

  # clear the last '|', put "at word end" special construct
  substr( $re, -1 ) = ')[[:>:]]';

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
  

sub search_resources_for_exact_phrase_NEVER_ACTUALLY_USED {
  my $sql  = shift;
  my $context = shift;
  my $name = shift;

  my $result = [];

  ###  regular expression
  $name =~ s/\.$//g; # remove final dot (or word boundary won't match)
  return undef if not $name;
  return undef if length ($name) < 2;

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
  

sub search_resources_for_name_word_fulltext_UNUSED {
  my $sql     = shift;
  my $context = shift;
  my $query   = shift;

  return undef if not $query or length( $query ) < 2;
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
  


sub search_resources_for_a_name_substring_NEVER_ACTUALLY_USED {
  my $sql     = shift;
  my $context = shift;
  my $substr  = shift;

  return undef if not $substr or length( $substr ) < 4;

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
  








1;
