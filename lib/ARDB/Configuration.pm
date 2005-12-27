package ARDB::Configuration;  ### -*-perl-*-  
#
#  This file is part of ARDB which is part of ACIS software,
#  http://acis.openlib.org/
#
#  Description:
#
#    Abstract RePEc Database Configuration.  This module reads main
#    configuration xml file, parses it and processes all its data.
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
#  $Id: Configuration.pm,v 2.0 2005/12/27 19:47:40 ivan Exp $
#  ---


BEGIN {
  $VERSION = '0.07';
  #$VERSION = do{ my @r=(q$Revision: 2.0 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
}

use strict;
use warnings;

use vars qw( $VERSION );

use XML::XPath;

use ARDB::Table;
use ARDB::RelationType;
use ARDB::Common;

# constructor

sub new {
  my $class       = shift;
  my $site_config = shift;
#  my $filename = shift;

  debug "create structure, bless it";
 
  my $self = {
    # store  ARDB::RelationType objects
    relation_types => {},

    # procedures for record-processing
    record_types => {},

    # database aliases 
    db_aliases => {},

    # stored objects ARDB::Table
    tables => {},

    # stored objects ARDB::Table::Map
    mappings => {},
 
    site_config => $site_config,  ### only needed during parsing
   };

  bless $self, $class;

  return $self;
}


# parse file and populate $self with rules and relations and so on

sub compile_config {
  my $self = shift;

  my $modules = $self -> {'modules-to-load'};
  foreach my $module ( @$modules ) {
    debug "try using $module";
    eval "use $module;";
    
    if ( $@ ) { critical $@; }
  }
   
  my $record_types = $self -> {record_types};

  foreach ( keys %$record_types ) {
    my $type = $_;
    my $record_type = $record_types -> {$type};
    
    debug "try compile code";

    if ( defined $record_type -> {'delete-process-text'} ) {
      my $code;
#      log_warn "compiling: " . $record_type->{'delete-process-text'};
      
      eval "\$code = sub{ \n$record_type->{'delete-process-text'} }";

      if ( $@ ) {
        critical "can't compile sub because ", $@; 
        #, "code:", $record_type -> {'delete-process-text'}
      }

      $record_type -> {'delete-process-ref'} = $code;
    }

    if ( defined $record_type -> {'put-process-text'} ) {
      my $code;
      
#      log_warn "compiling: " . $record_type->{'put-process-text'};
#      eval_wrap "\$code = sub{ $record_type->{'put-process-text'} }" , "put processing for $type";
      eval "\$code = sub{ \n$record_type->{'put-process-text'} }";

      if ( $@ ) {
        critical "can't compile sub because ", $@;
      }

      $record_type -> {'put-process-ref'} = $code;
    }
    
  }
}




sub parse_config {
  my $self       = shift;
  my $xml_config = shift;

  my $sconf     = $self ->{site_config};
  my $rec_types = $self ->{record_types};


  debug "try parse config from '$xml_config'";

  # get content of xml file

  my $xpath = new XML::XPath ( filename => $xml_config );

  debug "xml ok, try to read config from it";


  ###  database aliases 

  my @alias_nodes = $xpath -> findnodes( '/configuration/database[@alias]' );
  my $aliases = $self ->{db_aliases};

  foreach my $db ( @alias_nodes ) {
    my $al = $db -> getAttribute( "alias" );
    
    my $real_name = $sconf -> resolve_db_alias( $al );
    if ( not defined $real_name ) {
      warn "Database alias is not defined in site configuration: $al";
      next;
    }
    $aliases ->{$al} = $real_name;
  }
  $self -> {db_aliases} = $aliases;



  #######################################################
  #   processing xml content with relation types      ###
  #######################################################

  debug "search for 'relation-type' section";

  my @module_nodes_list = $xpath ->findnodes( '/configuration/use-perl-module/text()' );

  foreach my $module (@module_nodes_list) {
    debug "parsing prerequisite modules";
    my $m = $module -> string_value;
    push @{$self -> {'modules-to-load'}}, "$m";
  }



  my @relation_nodes = $xpath -> findnodes ('/configuration/relation-type');

  foreach my $relation ( @relation_nodes )
   {
    my $name = $relation -> getAttribute( 'name' );
    my $rel_type = new ARDB::RelationType( "$name" );
    
    critical "in configuration relation without name"
     unless ($name);
    
    my $debug_out = "stored relation type '$name'";

    my $reverse_type = $relation -> getAttribute( 'reverse' );
    
    my $undirected_relation
     = $relation -> getAttribute( 'undirected' );
    
    if ( defined $reverse_type ) { 

      $rel_type -> set_reverse_type( $reverse_type );
      $debug_out .= ", reverse type = $reverse_type";

    } elsif ( $undirected_relation =~ /yes|true|1/i ) {
      $rel_type -> set_reverse_type ( "$name" );
      $debug_out .= ", undirected";

    } else {
      critical "need defined 'reverse-type' or 'undirected' attribute";
    } 
    
    my $default_retrieve
       = $relation -> getAttribute( 'default-retrieve' );
    
    if ($default_retrieve) {
      $rel_type -> add_view ( 'default', $default_retrieve );
      $debug_out .= ", \'$default_retrieve' retrieve by default";
    }

    my @view_nodes = $xpath -> findnodes ('view', $relation);

    if ( scalar @view_nodes ) {
      $debug_out .= ", added views:";
     }
    
    foreach my $view ( @view_nodes ) {
      my $view_name     = $view -> getAttribute ('name');
      my $view_retrieve = $view -> getAttribute ('retrieve');
      
      critical "define 'name' and 'retrieve' attributes in view"
       unless ($view_name and $view_retrieve);
      
      $rel_type -> add_view ( "$view_name", "$view_retrieve" );
      $debug_out .= " $view_name";
    }
    $self -> {relation_types} -> { "$name" } = $rel_type;

    debug $debug_out;
   }
  
  ################################################
  #   processing xml content with table params ###
  ################################################

  debug "search for 'table' section";

  my @table_nodes = $xpath -> findnodes ('/configuration/table');
  
  foreach my $table ( @table_nodes )
   {
    my $table_name   = $table -> getAttribute( 'name' );
    
    critical "define 'name' attribute for table"
     unless ($table_name);

    my $realtabname;

    if ( $table_name =~ /^(\w[\w\d]+)\:(\w[\w\d]+)$/ ) {
      my $al = $1;
      my $real = $aliases->{$al};
      if ( not defined $real ) {
        warn "Table $table_name, corresponding alias not found: $al";

      } else {
        $realtabname = "$real.$2";
      }
    }
    
    my $table_object = new ARDB::Table ( $table_name );

    if ( $realtabname ) { $table_object -> {realname} = $realtabname; }

    my $debug_out;

    $self -> {tables} -> { $table_name } = $table_object;

    my @field_nodes = $xpath -> findnodes( 'field', $table );

    foreach my $field ( @field_nodes ) {
      my $field_name = $field -> getAttribute ('name');
      my $sql_type   = $field -> getAttribute ('sql-type');
      
      critical "required 'name' and 'sql-type' attributes for table fields"
       unless ($field_name and $sql_type);
      
      $table_object -> add_field ($field_name, $sql_type);
      $debug_out .= "$field_name ";
    }
    
    my $data =
        $xpath -> findvalue( 'create-table-sql', $table );
    
    $data =~ s/^\s+//gm;
    
    $table_object -> create_table_statement ($data);
    
    debug "stored '$table_name' table with ' $debug_out' fields";
   }

  ############################################
  #   processing xml content with mappings   #
  ############################################

  debug "search for 'field-attribute-mapping' section";
  
  my @mapping_nodes
   = $xpath -> findnodes ('/configuration/field-attribute-mapping');

  foreach my $mapping ( @mapping_nodes ) {

    my $map_name = $mapping -> getAttribute ('name');
    
    if ( not $map_name ) {
      log_error ( "no-name mapping at configuration root" );
      next;
    }
    
    my $map = $self -> process_xml_mapping ( $mapping );
    if ( defined $map ) {
      $self -> {mappings} -> { $map_name } = $map;
    }
  }

  ################################################
  #  processing xml content with put processing  #
  ################################################

  debug "search for 'put-processing' section";

  my @put_processing_nodes
   = $xpath -> findnodes ('/configuration/put-processing');
  
  foreach my $put_processing ( @put_processing_nodes ) {
    my $record_type = $put_processing -> getAttribute ('record-type');
    
    debug "found put-processing for '$record_type' types";
    
    unless ( $record_type )  {
      log_warn "check 'record-type' param in put-processing section";
      next;
    }
    
#    warn "\nRT: $record_type\n";
    my @record_types = split ',', $record_type;
    
    my $code = '';
    
    ##########################
    # store-to-table xml tag #
    ##########################

    my @processing_nodes
                  = $xpath -> findnodes( '*', $put_processing );
     
    foreach ( @processing_nodes ) {

      my $node_name = $_ -> getLocalName;
      
      debug "\n-----", $node_name , "------\n";
#      warn "process: $node_name\n";
      
      if ( $node_name eq 'store-to-table' ) {

        my $table_name = $_ -> getAttribute ('table');

        if ( not defined $table_name 
             or not $self->table( $table_name )  ) {
          log_error "undefined table $table_name mentioned in '$record_type' put processing";
          next;
        }

        my $map_name = $_ -> getAttribute ('field-attribute-mapping');
      
        debug "generating store-to-table code for '$table_name' table";
      
        if ( not $map_name ) {

          my @mapping_nodes = $xpath -> findnodes( 'field-attribute-mapping', $_ );
      
          debug "only one mapping per store-to-table supported, first processed,"
            ." other mappings ignored"
              if ($#mapping_nodes);
         
          my $mapping = $mapping_nodes [0];
        
          my $map = $self -> process_xml_mapping ( $mapping );

          if ( defined $map ) {
            $map_name = $map -> name;
            $self -> {mappings} -> { $map_name } = $map;
          }
        } 
      
        if ( not $map_name ) { 
          critical "mapping for store-to-table for '$record_type' is undefined";
        }

        $code .= qq[
    {
     my \$map = \$config -> mapping ( '$map_name' );
    
     critical "map '$map_name' is absent"
      if ( not \$map );
    
     my \$table_record = \$map -> produce_record( \$record );
     \$config -> table( '$table_name' ) -> store_record( \$table_record, \$sql_object );
    }
        ];
    
    #eval {
    #};
    #if( \$\@ ) {
    #   critical "processing record of type " . \$record->type . " had a problem: \$\@"
    #          . " (sql table $table_name)";
    #}          
      
      
    ###########################
    # building relations tags #
    ###########################
      } elsif ( $node_name eq 'build-forward-relation' or
                $node_name eq 'build-backward-relation' ) {
        my $relation_node = $_;
        my $relation_type = $relation_node -> getAttribute ('type');
        my $attributes = $relation_node -> getAttribute ('attributes');
        my ($direction) =
         ($node_name =~ /build-(\w+)-relation/);
      
        debug "building code for storing $direction relation named '$relation_type'";
      
        #$attributes =~ s/,/','/g;
      
        my @pathlist = split ',', $attributes;
        my $pathstr  = join( "', '", @pathlist );
        if ( $pathstr ) {
          $pathstr = "'$pathstr'";
        }

        $code .= qq[
    {
     my \$relation_name = '$relation_type';
     my \@values   = \$record -> get_value( $pathstr );

     foreach ( \@values )
      {
         die "fucken get_value of (\$record) returned zero" if not \$_;
         ];
      
        if ( $direction eq 'forward' )  {
          $code .=
            "\$relations -> store( [\$record_id, \$relation_name, \$_, \$record_id] );"
              ."\n      }\n";
          
        } elsif ( $direction eq 'backward' ) {
          $code .=
            "\$relations -> store( [ \$_, \$relation_name, \$record_id, \$record_id ] );"
              ."\n      }\n";
        }
        $code .= "\n    }\n";


    #####################
    # calling perl code #
    #####################
      } elsif ( $node_name eq 'call-perl-function' ) {
        my $function_name = $_ -> getAttribute ('name');
        $code .= "\n    &$function_name ( \$ARDB, \$record, \$relations );";
      
        debug "building code for calling '$function_name' function";

      } elsif ( $node_name eq 'eval' ) {

        my $eval = $xpath -> findvalue( "text()", $_ );
        $code .= "\n$eval\n";
      }
    }

    foreach ( @record_types ) {
      if ( defined $rec_types -> { $_ } {'put-process'} ) {
        $rec_types -> { $_ } {'put-process'} .= $code ;

      } else {
        $rec_types -> { $_ } {'put-process'}  = $code;
      } 
  
    }
  }
  
  #########################################################################
  #             processing xml content with delete processing
  #########################################################################
  
  my @delete_nodes
      = $xpath -> findnodes ('/configuration/delete-processing');
  
  foreach my $delete_processing ( @delete_nodes ) {

    my $record_type = $delete_processing -> getAttribute ('record-type');
    
    debug "found delete-processing for '$record_type' types";
    
    unless ( $record_type ) {
      log_warn "check 'record-type' param in delete-processing section";
      next;
    }

    my @record_types = split ( ',', $record_type );

    my $code = '';
    
    my @processing_nodes = $xpath ->findnodes ('*', $delete_processing);
     
    foreach ( @processing_nodes ) {

      my $node_name = $_ -> getLocalName;
      
      debug "\n----- ", $node_name , " ------\n";
    
      ##################################
      #   delete-from-table xml tag    #
      ##################################

      if (  $node_name eq 'delete-from-table' ) {
        my $table_name  = $_ -> getAttribute( 'table' );
        my $column_name = $_ -> getAttribute( 'by' );
      
        debug "generate code for delete '$table_name' table";
      
        $code .= qq [
    \$config -> table( '$table_name' ) -> delete_records
           ( '$column_name', \$record_id, \$sql_object );\n];
      }

      ########################
      #  call perl function  #
      ########################
    
      elsif ( $node_name eq 'call-perl-function' ) {
        my $function_name = $_ -> getAttribute( 'name' );
        $code .= "    &$function_name ( \$ARDB, \$record );\n";
     
        debug "generate code for '$function_name' call";
      } 
    }


    foreach ( @record_types ) {

      if ( defined $rec_types -> {$_} {'delete-process'} ) {
        $rec_types -> { $_ } {'delete-process'} .= $code ;

      } else {
        $rec_types -> { $_ } {'delete-process'}  = $code;
      }
    } 

  } 
  

}



sub finalize_generated_code {
  my $self = shift;

  my $rec_types = $self ->{record_types};


  foreach my $type ( keys %$rec_types ) {

    debug "insert into delete and put processing code text header and footer";
    
    my $put_init_code = q[
    my $ARDB      = shift;
    my $record    = shift;
    my $relations = shift;

    my $record_type = $record -> type;
    my $record_id   = $record -> id;

    my $config     = $ARDB -> {config};
    my $sql_object = $ARDB -> {sql_object};
    ];
    
    my $delete_init_code = q[
    my $ARDB        = shift;
    my $record      = shift;
    
    my $record_id;
    if ( ref $record eq 'HASH' ) {
       $record_id   = $record ->{id};       
    } else {
       $record_id   = $record -> id;
    }

    my $config     = $ARDB -> {config};
    my $sql_object = $ARDB -> {sql_object};
    ];


    my $this_rect = $rec_types -> {$type};

    my $delete_code = $this_rect -> {'delete-process'};
    my $put_code    = $this_rect -> {'put-process'};

    
    if ( defined $put_code )  {
      $this_rect -> {'put-process-text'} 
#       = "# line 1 \"$template_type-put-processing\"\n$put_init_code $put_code \n";
        = " $put_init_code $put_code \n";
    }

    if ( defined $delete_code ) {
      $this_rect -> {'delete-process-text'} 
#       = "# line 1 \"$template_type-delete-processing\"\n$delete_init_code $delete_code \n";
        = " $delete_init_code $delete_code \n";
    }

    delete $this_rect -> {'delete-process'};
    delete $this_rect -> {'put-process'}; 
  }

}


use Data::Dumper;

sub process_xml_mapping {
  my $self         = shift;
  my $mapping_node = shift;
  
  my $map_name = $mapping_node -> getAttribute ('name');
  
  unless ($map_name) {
    debug "try generate unique mapping names in #[number]# namespace";
    # any map name in this namespace maybe replaced
    my $max_generated_id = 0;
    foreach ( keys %{ $self -> {mappings} } )
     {
      next
       unless ( $self -> {mappings} -> {$_} -> name =~ /^#(\d+)#$/ );
      $max_generated_id = $1
       if ( $1 > $max_generated_id );
     }
    $max_generated_id++; 
    $map_name = "#$max_generated_id#";
  }
  
  
  debug "processing '". $map_name . "' mapping";
  
  my $mapping = new ARDB::Table::Map( $map_name );
  
  my $base_mapping = $mapping_node -> getAttribute ('based-on');
  
  if ( $base_mapping ) {
    debug "current mapping based on '$base_mapping'";
    
    if ( not $self->mapping( $base_mapping ) ) { 
      log_error "Mapping '$base_mapping' is undefined, but referenced from '" . $map_name . "'";
      return undef;
    }
 
    while ( my ($key, $value) = each %{ $self -> mapping( $base_mapping ) -> fields } )
     {
       
      $mapping -> fields -> {$key} = $value;
     }
   }
  
  my @field_name_nodes = $mapping_node -> getChildNodes;
  
  my $field_associations;
  
  debug "try to find 'field-associations'";
  
  while ( 1 ) {
    $field_associations = shift @field_name_nodes;
    last unless defined $field_associations;
    next unless ref $field_associations eq 'XML::XPath::Node::Element';
    next unless $field_associations -> getLocalName eq 'field-associations';
    last;
  }
  
  if ( defined $field_associations ) {
    my $debug_out = "found this fields: ";
    
    my @attributes = $field_associations -> getAttributes;
    foreach my $attribute ( @attributes ) {
      my $key   = $attribute -> getName;
      my $value = $attribute -> getData;

      $value =~ s/^\s+//;
      $value =~ s/\s+$//;
      $value =~ s/\s+/ /g;

      $mapping -> add_field ( "$key", "$value" );
      $debug_out .= "$key ";
    }
    debug $debug_out; 
  }
  
  return $mapping;
}

#################################################################

#################################################################


1;
__END__

# Below is stub documentation for the module

=head1 NAME

ARDB::Configuration - module responsible for reading and storing ARDB core configuration

=head1 SYNOPSIS

  use ARDB::Configuration;

  # load
  my $conf = new ARDB::Configuration( "filename.xml" );

  # check status
  die "Failed to load configuration: $ARDB::Configuration::ERROR"
    if not $conf;


  # get the rules
  my @rules = $conf->rules;

  # get the rules, which apply to the Person templates
  my @per_rules = $conf->rules( "ReDIF-Person 1.0" );


  # get the relation type details
  my $relation = $conf->relation_type( "written-by" );

  #apply rule
  $template = redif_get_next_template();
  $modified_template = $conf -> apply_rule ( $template );

=head1 DESCRIPTION

ARDB core configuration stored in an XML file.  This module will load
that and provide a simple object-oriented interface to access
configuration data.

=head1 METHODS

=over 4

=item new $filename

Creates new configuration object, parses the given file and returns a
blessed reference on success.  If a serious problem occurs, the
function sets the package variable $ERROR to a sensible message
explaining the problem and returns undef.  Serious parsing problems
are considered serious.

That is a class method.

=item $conf -> rules( [ $template_type ] )

This returns a list of ARDB::Rule objects, defined by
the configuration.  If not $template_type given, then all the reules
are returned.  Otherwise, only those which apply to the ReDIF
templates of type $template_type are returned.

=item $conf -> relation_type( $relation_name )

This looks up the relation type with the given name in the
configuration's relations table.  Returns ARDB::RelationType object if
such a relation is found, undef otherwise.

=back

=head1 CONFIG_FILE

=over 4

=item section relation-type



    Root-level relation elements define relation types.  

    Relation types are only used at get_full_template()
    operations.

    Each relation type must have a unique id. It is a bad idea 
    to give relation type an id equal to any existing 
    ReDIF attribute.  That's because of the way we going to use
    the relation type ids: they may serve as attributes in unfolded
    templates.  Another approach may be to stick to a special 
    convention on relation type ids: e.g. using Title Like 
    First-Caps Case.  

    See lib/ARDB/RelationType.pm for more details.
    

    'reverse' attribute specifies the opposite of this type of
    relation by giving its id name.

    'undirected' attribute means the relation is valid in both
    directions: both from subject to the object and from object to the
    subject.  It makes no sense in presence of the 'reverse'
    attribute, should trigger an error.  Accepts logical values: 
      yes | true | 1 | no | false | 0 (case insensitive) 

    'default-retrieve' attribute specifies what to add to the bare
    template upon get_full_template() request, which finds such a
    relationship to or from the template.  accepted values: nothing,
    template, handle

-=-=-=-=-=-=-=- part configuration.xml -=-=-=-=-=-=-=-=-=-

<relation-type name="written-by" reverse="wrote" default-retrieve="nothing" />

<relation-type 
        name="wrote"
        reverse="written-by"
        default-retrieve="template">

        <!-- 
                when we say retrieve we mean retrieve from the 
                relation object template to include 
                the retrieved data into the requested "full" template
        -->

        <view name="brief" retrieve="title,handle,authors:author/name" />

        <view name="brief-with-creation-date" retrieve="title,handle,authors:author/name,creation-date"/>

</relation-type>

<relation-type 
        name="written-by"
        reverse="wrote"
        default-retrieve="nothing"/>

<relation-type
        name="wrote"
        reverse="written-by"
        default-retrieve="template"
         />
<!--

<relation-type 
        name="cited-by"
        reverse="cites" 
        >
</relation-type>

-->

<relation-type
        name="rejected-authorship"
        undirected="yes"
        default-retrieve="handle"
         />

-=-=-=-=-=-=-=- part configuration.xml -=-=-=-=-=-=-=-=-=-

=item section table

        A table element configures an SQL table. 

        It only defines table structure and SQL details.

        What it does not define is mapping from template data to table
        records.

-=-=-=-=-=-=-=- part configuration.xml -=-=-=-=-=-=-=-=-=-

<table name="authors">
        <field name="name"   sql-type=" VARCHAR(200) NOT NULL INDEX "/>
        <field name="email"  sql-type=" VARCHAR(200) INDEX " />
        <field name="handle" sql-type=" VARCHAR(200) NOT NULL PRIMARY KEY " />

        <!-- 
                upon building create table statement this will be included
        -->
        <create-table-sql line=" "/>

</table>


<table name="documents">

        <field name="title"    sql-type=" VARCHAR(200) NOT NULL "/>
        <field name="authors"  sql-type=" CHAR(200) NOT NULL "/>
        <field name="subject"  sql-type=" TEXT NOT NULL" />
        <field name="abstract" sql-type=" TEXT " />
        <field name="creation_date"  
                               sql-type=" TIMESTAMP(14) " />
        <field name="handle"   sql-type=" CHAR(200) NOT NULL PRIMARY KEY " />

        <field name="jel"      sql-type=" CHAR(50) " />

        <field name="file"     sql-type=" int " />
        <field name="urls"     sql-type=" text "/>


        <!-- 
                upon composing SQL create table statement
                this will be included:
        -->

        <create-table-sql>
          INDEX title_i ( title ),
          INDEX authors_i ( authors ),
          INDEX creationdate_i ( creation_date ),
          FULLTEXT INDEX subj ( title, keywords, abstract )
        </create-table-sql>

</table>




=item section field-attribute-mapping


  When there is a put_template() operation, the template data 
  may need to be stored in some SQL tables.  To do that we have tables
  and we need a mapping, which would tell what data to put into which
  table fields.
  But some template types are similar and their mapping will be similar.
  Therefore we create reusable named field-to-attribute maps.


  root-level section <field-attribute-mapping> must contains
  attribute "map-name", and may contains attribute "based-on".
  
  embedded into <put-processing>, attribute "map-name"
  facultative.
  
  namespace "#number#" for attribute "map-name" reserved for
  internal puproses.
  
  "based-on" must refer to previously defined section 
  <field-attribute-mapping>

-=-=-=-=-=-=-=- part configuration.xml -=-=-=-=-=-=-=-=-=-

<field-attribute-mapping name="documents">
        <field-associations
                title="title"
                subject="title,abstract,keywords"
                authors="author/name"
                authors_emails="author/email"
                keywords="keywords"
                abstract="abstract"
                creation_date="creation-date"
                handle="handle"
                special_field="My::ARDB::special_field_filter" />

</field-attribute-mapping>

-=-=-=-=-=-=-=- part configuration.xml -=-=-=-=-=-=-=-=-=-

=item section put-processing

  put-processing configuration sections define how a template is processed
  upon a put template operation.

  Each put-processing element MUST have:

     "record-type" attribute with a list of template-types 
  
  and MAY have:

     "attribute" attribute with a list of attribute-specifications

  Then it allows following children, which specify the processing actions:

     store-to-table ...
     call-function ...
     build-forward-relation 
     build-backward-relation 

  Each put-processing section compiled by the ARDB::Configuration module to some 
  perlcode. 

-=-=-=-=-=-=-=- part configuration.xml -=-=-=-=-=-=-=-=-=-

<put-processing record-type="ReDIF-Paper 1.0,ReDIF-Article 1.0,ReDIF-Book 1.0">

    <store-to-table 
      table="documents"
      field-attribute-mapping="documents"/>
    
    <store-to-table table="catalog">
      <field-attribute-mapping based-on="documents">
        
        <!--

        This is an anonymous field-attribute-mapping.  But it must be
        stored in the configuration together with named mappings, but 
        with some made-up id, like for instance "#9", used in example 
        perl code above.  This mapping is based on "documents" mapping,
        therefore it inherits all the fields from it, but adds or replaces 
        the "notes" field:

        -->

        <field-associations
          notes="issue, year, volume" />
      </field-attribute-mapping>
    </store-to-table>
    
    <call-perl-function name="My::ARDB::put_paper"/>
    
    <build-forward-relation 
      type="written-by" 
      attributes="author/handle"
      />

</put-processing>


<put-processing record-type="ReDIF-Archive 1.0">
    <store-to-table table="archives">
      <!--
      
      here is another example of anonymous mapping.  
      This time without based-on attribute.
      
      -->

      <field-attribute-mapping>
        <field-associations
          name="name"
          handle="handle"
          URL="URL" />
      </field-attribute-mapping>
    </store-to-table>
</put-processing>

<put-processing record-type="ReDIF-Series 1.0">
    <store-to-table table="series">
      <field-attribute-mapping>
        <field-associations
          name="name"
          handle="handle"
          URL="URL" />
      </field-attribute-mapping>
    </store-to-table>
    <call-perl-function name="ARDB::Addon::series_template"/>
    <build-forward-relation 
      type="is-part-of" attributes="Archive"/>

</put-processing>

-=-=-=-=-=-=-=- part configuration.xml -=-=-=-=-=-=-=-=-=-

=back


=head1 AUTHOR

Ivan Baktcheev, with support from Ivan Kurmanov

=head1 SEE ALSO

L<ARDB>, L<ARDB::Rule>, L<ARDB::RelationType>

=cut
