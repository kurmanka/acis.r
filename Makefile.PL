use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

#print "Preparing to install ACIS.\n";

# $DEBUG = 1;

my @dirs = ();

# if( not have_module( 'RePEc::Index' ) ) {
#   push @dirs, './RePEc-Index';
# }

# have_module( 'AppConfig'  ) ;
# have_module( 'Storable'   ) ;
# have_module( 'XML::XPath' ) ;
# have_module( 'Carp::Assert' ) ;
# have_module( 'sql_helper' ) ;


# if( not have_module( 'RePEc-Index' ) ) {
#   push @dirs, 'RePEc-Index';
# }

# do ( "configure.pl" ) or die "Configure failed, so do I";



sub MY::distdir {
  my $self = shift;
  local *distdir;
  $_ = $self->MM::distdir;
  s!\n\n$!\n\tif [ `ls extra|wc -l` -gt 0 ]; then { \$(CP) extra/* \$(DISTVNAME) && cd \$(DISTVNAME) && rm MANIFEST && find * -type f > MANIFEST && cd ..; } fi\n\n!;
  return $_;
}

sub MY::dist {
  my $self = shift;
  local *dist;
  $_ = $self->MM::dist;
  s!DISTNAME = ACIS!DISTNAME = \$\(NAME\)!;
  s!DISTVNAME = ACIS-[\d+\.]+!DISTVNAME = \$(NAME)-\$(VERSION)!;
  return $_;
}


my $modules =  {
                     'Carp::Assert' => "0.17",
                     'Storable'     => "1.013",
                     'CGI::Cookie'  => '1.25',
                     'CGI::Minimal' => '1.24',
                     'CGI::Untaint' => '1.25',
                     'XML::XPath'   => '1.12',
                     'XML::LibXML'  => "1.52",
                     'XML::LibXSLT' => "1.52",
                     'AppConfig'    => "1.52",
                     'Proc::Daemon' => "0.03",
                     'Unicode::Normalize' => '0',
                     'String::Approx' => '0',
                     'String::Similarity' => '1',
                     'Date::Manip'  => '0',
                'Scalar::Util' => 0,
                'Data::Dumper' => 0,

# debugging modules: (the list may be incomplete)
#  Debug::FaultAutoBT (Debug::DumpCore)
#  Devel::Size
#  Devel::Arena
#  Devel::Symdump
#  Data::Structure::Util
#  Data::Dump::Streamer
#  Proc::ProcessTable


                    };

print "Checking required modules...\n";
my $fine = 1;
while ( my ($m,$v) = each %$modules ) {
  if ( not have_module( $m, $v ) ) {
    my $version = '';
    if ( $v ne '0' ) { $version = " (version $v+)"; }
    print "  - $m$version is not found\n";
    $fine = 0;
  }
}
if ( $fine ) {
  print "Fine!\n";
}

die "to install ACIS, use install.sh script\n"
  unless $ENV{ACIS_INSTALL} or $ENV{ACIS_DEV};

WriteMakefile(
              NAME       => 'ACIS',
              VERSION    => '0.1',
              PREREQ_PM  => $modules,
              DIR        => [ @dirs ],
              ABSTRACT   => 'Academic Contributor Information System',
              AUTHOR     => 'Ivan Bahcheyev & Ivan Kurmanov',
             )
  if $ENV{ACIS_DEV};



# copied from AxKit's Makefile.PL, http://axkit.org

sub have_module {
    my ($module, $version) = (@_, 0);
#    printf("checking for module %s >= version %s... ", $module, $version);

    if ( $version eq '0' ) { 
      $version = '';
    }
    print "eval(\"package Foo; use $module $version;\")\n" if $DEBUG;
    eval "package Foo; use $module $version;";
    if ($@) {
        print $@ if $DEBUG;
#        print "no\n";
        return 0;
    }
#    print "yes\n";
    return 1;
}

