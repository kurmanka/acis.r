#!/usr/bin/perl


use strict;

my $dest = shift @ARGV;
my $src  = `pwd`;
chomp $src;

die if not $dest;
die if not $src;

my @failed = ();

sub p (@) { print @_, "\n"; }

sub test ($$) {
  my $name = shift;
  if ( shift ) {
    return 1;
  } else {
    die "Sorry, $name test failed.";
  }
}


sub cp ($) {
  system ( "cp " . shift ); 
}

sub mk_dir($$) {
  my $base = shift || die;
  my $dir  = shift || die;

  $base =~ s+/$++g;
  $dir  =~ s+^/|/$++g;

  my @dirs = split '/', $dir;

  foreach ( @dirs ) {
    $base .= '/' . $_;
    next if -d $base;
    mkdir $base or die "can't create '$base' dir";
  }
}

sub wrap (&$) {

  my $code = shift;
  my $step = shift;

  eval { &$code };
  if ( $@ ) {
    p "\nPROBLEM: $@\tFollow manual installation, $step instructions as in 
\tdoc/eprints-install.html";

    push @failed, $step;
  }

}


use ExtUtils::MakeMaker qw( prompt );

p q!About to install ACIS extensions to EPrints.

You should read the eprints.html document of ACIS 
documentation before you continue this installation.  
Also, you should be ready to answer some configuration 
questions along the way. 

!;

p "Destination dir: $dest";
test "destination dir", -d $dest;
p "Source ACIS distribution dir: $src";
test "source dir",      -f "$src/pidaid.js";


my $eprints_dir;
my $archive_dir  = $dest;
my $archive_name;

{ 
  my $v = reverse $dest;
  if ( $v =~ m!^([^\/]+)\/sevihcra\/(.+)!g ) {
    $eprints_dir  = reverse $2;
    $archive_name = reverse $1;
  } else {
    die "give us directory of an EPrints archive";
  }
}

test "EPrints dir", -d $eprints_dir;
test "EPrints dir", -d "$eprints_dir/perl_lib";
test "EPrints dir", -d "$eprints_dir/cgi";
test "EPrints dir", -d "$eprints_dir/cfg";
test "EPrints dir", -d "$eprints_dir/archives";

my $ep_version = `grep 'EPrints Version:' $eprints_dir/bin/configure_archive`;
if ( $ep_version =~ m/Version: (\d[\d\.]+[\w\d\.]+)\s*?\n$/ ) {
  $ep_version = $1;
}

p "Your EPrints is of version $ep_version";



wrap { 

  p "\n *** Step 1";
  p " *** Copy perl code and other files";

  ### step no 1 - copy files
  cp "-r perl_lib cgi plugins $eprints_dir/";
  cp "-r images pidaid.js pidaid.css $archive_dir/html/en/";
  
  ### sql_helper
  cp "-r ../sql_helper/*.pm $eprints_dir/perl_lib/";

  ### ACIS::MetaUpdate::Request
  mk_dir $eprints_dir, "perl_lib/ACIS/MetaUpdate";
  cp "../lib/ACIS/MetaUpdate/Request.pm $eprints_dir/perl_lib/ACIS/MetaUpdate/";

  ### VERSION
  cp "-r ../VERSION $eprints_dir/ACIS-extensions.VERSION";
  
  ### AMF::Parser
  my $s = q?
dest=$1
file=../AMF-perl-*.tar.gz
cp $file ./
AMFPerl=`echo AMF-perl-*.tar.gz`
if [ -f $AMFPerl ]; then
   echo tar xzvf $AMFPerl 
   tar xzvf $AMFPerl > /dev/null
   directory=${AMFPerl%.tar.gz}
   cd $directory
   cp -r lib/* $dest
   echo installed it into $dest
else 
   echo Problem: AMF-perl not found.  
   echo Does this release contain an AMF-perl package\?
fi
?;

  if ( open RUN, "|-", "/bin/sh -s $eprints_dir/perl_lib/" ) {
    print RUN $s;
    close RUN;
  } else {
    die "Can't use /bin/sh for the AMF installation script";
  }

} 'step 1';


### step no 2 -- configure page template for pidaid
wrap {
  
  p "\n *** Step 2";
  p " *** Configure page template for person identification aid";

  my $success;
  my $template_file = $archive_dir . "/cfg/template-en.xml";

  p "Looking at $template_file";

  if ( open TEMPLATE, "<", $template_file ) {
    my $template = join '', <TEMPLATE>;
    close TEMPLATE;

    my $orig_template = $template;
    
    if ( $template =~ /\/pidaid.js/ ) {
      ### already fixed
      p "template already invokes pidaid.js";

    } else {
      $template =~ s[(</style>\s*)(\n\s*<link )]
        [$1\n  <script type='text/javascript' src='&base_url;\/pidaid.js' \/>$2]g;

    }

    if ( $template !~ /\/pidaid.js/ ) {
      ### already fixed
      die "automatic addition of pidaid.js did not work";
    }


    if ( $template =~ /\/pidaid.css\)/ ) {
      ### already fixed
      p "template already invokes pidaid.css";

    } else {

      $template =~ s[(\@import\s+url\(&base_url;\/eprints.css\);\s*\n)]
        [$1\@import  url\(&base_url;\/pidaid.css\);   /* PIDAID */\n]g;

    }
    if ( $template !~ /\/pidaid.css\)/ ) {
      ### already fixed
      die "automatic addition of pidaid.css did not work";
    }


    if ( $template ne $orig_template 
         and open TEMPLATE, ">", $template_file ) {
      print TEMPLATE $template;
      close TEMPLATE;
      $success = 1;
      p "Written modified file; OK!";

    } else {
      p "Already done; OK!";
    }
    
  }
    

} 'step 2';



#### step 3: Make sure id field for authors and editors is enabled

wrap { 

  my $filename = "$archive_dir/cfg/ArchiveMetadataFieldsConfig.pm";

  p "\n *** Step 3";
  p " *** Make sure id field for authors and editors is enabled";
  p "Looking at $filename";
    
  do $filename;

  my $archive_metadata_conf = get_metadata_conf();
  my $creators_field;
  my $editors_field;

  my $edit = 0;
  
  if ( $archive_metadata_conf -> {eprint} ) {
    my $eprint_fields = $archive_metadata_conf -> {eprint};
    
    foreach ( @$eprint_fields ) {
      if ( $_ -> {name} eq 'creators' ) {
        $creators_field = $_;
        
      } elsif ( $_ ->{name} eq 'editors' ) {
        $editors_field = $_;
      }
    }
    
    if ( $creators_field 
         and $creators_field->{hasid} ) {
      p "Creators field has 'hasid' enabled";

    } else {
      $edit = 1;
    }

    if ( $editors_field 
         and $editors_field->{hasid} ) {
      p "Editors field has 'hasid' enabled";

    } else {
      $edit = 1;
    }


    if ( not $edit ) {
      p "No change is needed; OK!";
      return 0;
    }

    if ( open CFG, "<", $filename ) {
      my $text = join '', <CFG>;
      my $text_orig = $text;
      close CFG;

      if ( $text =~ m/^(.+{)(\s*name\s*=>\s*['"]creators['"][^}]+)(}.+)$/s ) {
        my $pre  = $1;
        my $meat = $2;
        my $post = $3;
        
        $meat =~ s/(\s*hasid\s*=>\s*)([^,\s]+)(\s*,)/${1}1${3}/;
        $text = $pre . $meat . $post;
      }


      if ( $text =~ m/^(.+{)(\s*name\s*=>\s*['"]editors['"][^}]+)(}.+)$/s ) {
        my $pre  = $1;
        my $meat = $2;
        my $post = $3;
        
        $meat =~ s/(\s*hasid\s*=>\s*)([^,\s]+)(\s*,)/${1}1${3}/;
        $text = $pre . $meat . $post;
      }

      if ( $text ne $text_orig ) {
        if ( open CFG, ">", $filename ) {
          print CFG $text;
          close CFG;

          p "Saved modified file; OK!";
        } else { 
          die "can't open the file for writing";
        }
      } else {
        die "can't find and automatically change the hasid setting"
      }

    } else {
      die "can't read the file";
    }

  } else {
    die "can't parse the file";
  }

} 'step 3';




#### step 4: Set appropriate label for the id field

wrap { 

  my $filename = "$archive_dir/cfg/phrases-en.xml";
  my $edit  = 0;
  my $label = "Id or email";

  p "\n *** Step 4";
  p " *** Set appropriate label for the id field";
  p "Looking at $filename";
    
  my $already_done1 = 0;


  if ( open CFG, "<", $filename ) {
    my $text = join '', <CFG>;
    my $text_orig = $text;
    close CFG;
    

    if ( $text =~ 
         m/^(.+<ep:phrase\s+
            ref=['"]eprint_fieldname_creators_id['"]\s*>)
            ([^<]*)
            (<\/ep:phrase>.+)$/sx ) {
      my $pre  = $1;

      if ( $2 eq $label ) {
        $already_done1 = 1;
      }

      my $meat = $label;
      my $post = $3;
      
      $text = $pre . $meat . $post;

    } else {
      die "Can't find the phrase element.  Strange.";
    }


    if ( $text =~ 
         m/^(.+<ep:phrase\s+
            ref=['"]eprint_fieldname_editors_id['"]\s*>)
            ([^<]*)
            (<\/ep:phrase>.+)$/sx ) {
      my $pre  = $1;

      if ( $2 eq $label ) {
        if ( $already_done1 ) {
          p "Already done; OK!";
          return 0;
        }
      }

      my $meat = $label;
      my $post = $3;
      
      $text = $pre . $meat . $post;

    } else {
      die "Can't find the phrase element.  Strange.";
    }


    if ( $text ne $text_orig ) {
      if ( open CFG, ">", $filename ) {
        print CFG $text;
        close CFG;
        
        p "Saved modified file; OK!";
      } else { 
        die "can't open the file for writing";
      }
    } else {
      die "Strange; it looks like we changed nothing";
    }

  } else {
    die "can't read the file";
  }
  
} 'step 4';




#### step 5: EPrints::EPrint -- enable AMF export

wrap { 

  my $filename = "$eprints_dir/perl_lib/EPrints/EPrint.pm";
  my $edit  = 0;

  p "\n *** Step 5";
  p " *** Patch EPrints::EPrint -- enable AMF export";
  p "File: $filename";
    
  my $already_done1 = 0;
  my $already_done2 = 0;

  my $module_name = 'ACIS::EPrints::MetadataExport::AMF';

  if ( open CFG, "<", $filename ) {
    my $text = join '', <CFG>;
    my $text_orig = $text;
    close CFG;
    
    if ( $text =~ m/
sub\s+_move_from_archive\s*{
.+?
require\s+?
$module_name ;
\s+
$module_name ::clear_metadata 
/xs
       ) {
      $already_done1 = 1;
      
    } else {
      
      if ( 
          $text =~ m/^(.+)(\n\s*sub\s+_move_from_archive\s*{\s*.+?return)(.+)/sm
         ) {
        my $pre  = $1;
        my $meat = $2;
        my $post = $3;
        
        $meat =~ s/(my.+?self[^;]+;\s*?\n)/$1
    # Clear AMF metadata
    require $module_name;
    ${module_name}::clear_metadata( \$self );

/;
        $text = $pre . $meat . $post;
      }
      
    }
    

    
    if ( $text =~ m/
sub\s+generate_static\s*{
.+?
$module_name ;
.+?
$module_name ::export_metadata
.+?
return
/xs
       ) {
      $already_done2 = 1;
      
    } else {
      
      if ( 
          $text =~ m/^(.+)(\n\s*sub\s+generate_static\s*{\s*.+?return)(.+)/sm
         ) {
        my $pre  = $1;
        my $meat = $2;
        my $post = $3;
        
        $meat =~ s/(my.+?ds_id.+?=\s*\$self.+?dataset[^;]+;\s*?\n)/$1
    # Export AMF metadata
    require $module_name;
    if ( \$ds_id eq 'archive' ) {
        ACIS::EPrints::MetadataExport::AMF::export_metadata( \$self );
    }

/;
        $text = $pre . $meat . $post;
      }
      
    }
    
    if ( $already_done1 and
         $already_done2 ) {
      p "Already done.";
      return 0;
    }

    if ( $text ne $text_orig ) {
      if ( open CFG, ">", $filename ) {
        print CFG $text;
        close CFG;
        
        p "Saved modified file; OK!";
      } else { 
        die "can't open the file for writing";
      }
    } else {
      die "Strange; it looks like we changed nothing";
    }

  } else {
    die "Can't read the file!";
  }

} 'step 5';




my $aconf;  # archive configuration
my $text ;
my $text_orig;
my $filename = "$archive_dir/cfg/ArchiveConfig.pm";
my $edit  = 0;
my $prologstamp = "### ACIS/EPrints/install.pl automatic configuration section\n\n";

wrap {

  p "\n *** Steps 6-8";
  p " *** Archive configuration";
  p "File: $filename";

  if ( open CFG, "<", $filename ) {
    $text_orig = $text = join '', <CFG>;
    close CFG;
  } else {
    die "can't read the file";
  }

  
  #  push @INC, $archive_dir;
  push @INC, "$eprints_dir/perl_lib";

  require EPrints::Config;
  EPrints::Config::init();
  $aconf = EPrints::Config::load_archive_config_module( $archive_name );

  if ( $aconf ) {}
  else { 
    die "can't load the file: $@";
  }
  

  #### step 6: Archive configuration: AMF export

  wrap { 

    p "\n *** Step 6";
    p " *** Archive configuration: AMF export";

    my $amf_pre = $aconf -> {eprint_metadata_export_AMF_idprefix};
    my $amf_dir = $aconf -> {eprint_metadata_export_AMF_dir};
    my $ask    = 0;
    my $change = 0;
    
    if ( $amf_pre or $amf_dir ) {
    
      p "Your current AMF export settings:\n", 
        get_amf_settings( $aconf );
            
      my $response = 
        prompt( "Do you want to change these settings?", "no" );
      
      if ( positive_response( $response ) ) {
        $ask = 1;
      }
      
    } else { 
      $ask = 1;
    }

    if ( $ask ) {

      $amf_dir = prompt( "Directory for the AMF files?", 
                         $amf_dir );
      
      $amf_pre = prompt( "Identifier prefix for the AMF records?", 
                         $amf_pre );
      
      $change = 1;
    }

    if ( $change ) { 
      if ( $amf_dir ) {
        set_simple_config_setting( 'eprint_metadata_export_AMF_dir',
                            "'$amf_dir'" );
      }
      
      if ( $amf_pre ) {
        set_simple_config_setting( 'eprint_metadata_export_AMF_idprefix',
                            "'$amf_pre'" );
      }

      if ( $amf_dir or $amf_pre ) {
        p "Have set the AMF export settings, OK!";
      }
    }

  } 'step 6';




  #### step 7: ACIS::PIDAID

  wrap { 

    p "\n *** Step 7";
    p " *** Archive configuration: person identification aid parameters";


    my $ask    = 0;
    my $change = 0;

    my $c = $ACIS::PIDAID::CONF;
    my $db   = $c -> {db};
    my $host = $c -> {host};
    my $port = $c -> {port};
    my $user = $c -> {user};
    my $pass = $c -> {pass};
    my $mres = $c -> {max_results};
    
    if ( $ACIS::PIDAID::CONF ) {
    
      p "Your current ACIS::PIDAID settings:\n\t", 
        get_acis_pidaid_settings( $ACIS::PIDAID::CONF );
            
      my $response = 
        prompt( "Do you want to change these settings?", "no" );
      
      if ( positive_response( $response ) ) {
        $ask = 1;
      }
      
    } else { 
      $ask = 1;
    }

    if ( $ask ) {

      p "Enter the parameters of the MySQL database to use for pidaid:";

      $host = prompt( "Hostname?",    $host );

      if ( not $host ) {
        die "Hostname is required to access the MySQL database";
      }

      $port = prompt( "Port number?", $port );
      $db   = prompt( "Database name?", $db );
      $user = prompt( "Username?",    $user );
      $pass = prompt( "Password?",    $pass );

      $mres = prompt( "Max results to show?", $mres ? $mres : 15 );

      if ( $mres == 15 ) { undef $mres; }
      
      $change = 1;
    }

    if ( $change ) { 
      ### save the settings

      if ( $ACIS::PIDAID::CONF ) {
        ### delete first
        $text =~ s/^\s*\$ACIS::PIDAID::CONF\s*=\s*{\s*[^}]+};\s*?\n//sm;
      }

      my $new = "  ";
      $new .= join( ",\n  ", 
                    "host => '$host'",
                    "port => '$port'",
                    "db   => '$db'",
                    "user => '$user'",
                    "pass => '$pass'",
                    ( $mres ) 
                    ? ( "max_results => $mres" )
                    : () 
                  );
      $new = '$ACIS::PIDAID::CONF = ' . "{\n$new\n};";

      insert_config_text( $new );
      p "Added \$ACIS::PIDAID::CONF variable";
      

    }

    
  } 'step 7';






  #### step 8: Archive configuration: ACIS metadata update

  wrap { 

    p "\n *** Step 8";
    p " *** Archive configuration: ACIS metadata update";

    my $ask    = 0;
    my $change = 0;

    my $c = $aconf -> {eprint_metadata_export_AMF_metaupdate} || {};

    my $url  = $c -> {'request-target-url'};
    my $aid  = $c -> {'archive-id'};
    my $log  = $c -> {'log-filename'};
    my $lev  = $c -> {'object-dir-levels'};
    
    
    if ( $aconf -> {eprint_metadata_export_AMF_metaupdate} ) {
    
      my $url  = $c -> {'request-target-url'};
      my $aid  = $c -> {'archive-id'};
      my $log  = $c -> {'log-filename'};
      my $lev  = $c -> {'object-dir-levels'};

      p "Your current metadata update settings:\n\t", 
        join( "\n\t", 
              "request-target-url: $url",
              "        archive-id: $aid",
              "      log-filename: $log",
              " object-dir-levels: $lev" );
            
      my $response = 
        prompt( "Do you want to change these settings?", "no" );
      
      if ( positive_response( $response ) ) {
        $ask = 1;
      }
      
    } else { 

      my $res = prompt( "Do you want to setup ACIS meta update now?", "yes" );
      if ( positive_response( $res ) ) {
        $ask = 1;
      }
    }

    if ( $ask ) {

      p "Enter the ACIS metadata update parameters:";

      $url = prompt( "URL of the ACIS /meta/update screen to send requests to?", 
                      $url );
      if ( not $url ) { die "The URL is required for metadata update"; }

      $aid = prompt( "Your archive identifier (for ACIS)?", $aid );
      if ( not $aid ) { die "Archive id is required for metadata update"; }

      $log = prompt( "Log file to write?", $log );

      $lev = prompt( 
"How many levels of directory structure should we include 
into OBJECT of each update request?", (defined $lev) ? $lev : 0 );

      $change = 1;
    }

    if ( $change ) { 
      ### save the settings

      if ( exists $aconf -> {eprint_metadata_export_AMF_metaupdate} ) {
        ### delete first
        $text =~ s/^\s*\$c\s*->{\s*eprint_metadata_export_AMF_metaupdate\s*}\s*=\s*{\s*[^}]+};\s*?\n//sm;
      }

      my $new = "  ";
      $new .= join( ",\n  ", 
                    "'request-target-url' => '$url'",
                    "'archive-id'         => '$aid'",
                    "'log-filename'       => '$log'",
                    "'object-dir-levels'  =>  $lev" 
                  );
      $new = '$c ->{eprint_metadata_export_AMF_metaupdate} = ' . "{\n$new\n};";

      insert_config_text( $new );
      p "Saved the parameters.";
      

    }

    
  } 'step 8';


  

  
  if ( $text ne $text_orig )  {
    if ( open CFG, ">", $filename ) {
      print CFG $text;
      close CFG;
      p "File saved; OK!";
      p "You now probably want to restart EPrints (ie. Apache which runs EPrints).";

    } else {
      die "Can't write the file";
    }
  } else {
    p "Changed nothing.";
  }
  
  
} 'steps 5-8';


wrap {
  p "\n *** Step 9";
  p " *** Check the libwww-perl library";

  eval "require LWP::UserAgent;" 
    or die "libwww-perl library is not installed; please install it";

  eval "require HTTP::Request::Common;" 
    or die "libwww-perl library is not properly installed \n".
      "(can't load HTTP::Request::Common); please reinstall it";
    
  p "The library is fine; OK!";

} 'step 9';



sub positive_response {
  my $response = shift;
  return ( $response =~ /^(?:y(?:es?)?)/i );
}


sub get_amf_settings {
  my $c = shift;
  my $dir = $c -> {eprint_metadata_export_AMF_dir};
  my $pre = $c -> {eprint_metadata_export_AMF_idprefix};

  return "\tdirectory: $dir\n\tid prefix: '$pre'";
}


sub get_acis_pidaid_settings {
  my $c = shift;

  my $db   = $c -> {db};
  my $host = $c -> {host};
  my $port = $c -> {port};
  my $user = $c -> {user};
  my $pass = $c -> {pass};
  my $mres = $c -> {max_results};

  return join ( "\n\t", 
                "    host: $host", 
                "    port: $port",
                "database: $db",
                "    user: $user",
                "password: $pass",
                ( defined $mres ) 
                ? ( "max_results: $mres" )
                : () 
              );
}


sub set_simple_config_setting {
  my $name = shift;
  my $val  = shift;

  my $c = $aconf;

  if ( exists $c ->{$name} ) {
    ### comment out the existing setting
    $text =~ 
      s/^(\s*\$c\s*->\s*{\s*['"]?${name}['"]?\s*}\s*=\s*[^;]+;)//gms;
  } 


  ### add
  my $str = "\$c ->{$name} = $val;\n";
  insert_config_text( $str );

}

sub insert_config_text {
  my $str  = shift;
  
  if ( $text =~ 
       m!^(.+\s)
         (\#+\s*ACIS/EPrints/install.pl
         [^\n]+\n)
         (.+)$!isx ) {
    my $pre  = $1;
    my $meat = $2;
    my $post = $3;
    
    $meat = "$prologstamp$str";

    $text = $pre . $meat . $post;

  } else {

    if ( $text =~ 
         s[(sub\s+get_conf\s*\{.+?my\s*\$c\s*=\s*\{\s*\}\s*;\s+)]
          [$1$prologstamp$str\n\n\n### end\n\n]s ) {
    } else {
      die "can't find the begining of the get_conf() func";
    }
  }

}


sub eprint_status_change_setting {
q!
$c->{eprint_status_change} = sub {
   my $ep   = shift;
   my $from = shift;
   my $to   = shift;
   my $session = $ep -> {session};

   if ( $to eq 'archive' ) {
      ACIS::EPrints::MetadataExport::AMF::export_metadata( $session, $ep );

   } elsif ( $from eq 'archive' ) {
      ACIS::EPrints::MetadataExport::AMF::clear_metadata( $session, $ep );
   }
};
!;
}


if ( scalar @failed ) {
  p "\nINSTALLATION STEPS FAILED: ", 
    join ' ', @failed;

} else {
  p "\nINSTALLATION HAS SUCCESSFULLY COMPLETED.";

}


1;



