use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

print "Preparing to install ACIS.\n";

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



WriteMakefile
  (
   'NAME'               => 'ACIS',
   'VERSION'    => '0.1', # finds $VERSION
   'PREREQ_PM'  =>  {
                     'Carp::Assert' => "0.17",
                     'Storable'     => "1.013",
                     'CGI::Untaint' => '',
                     'XML::XPath'   => '1.12',
                     'XML::LibXSLT' => "",
                     'AppConfig'    => "1.52",

                    }, 
   DIR => [ @dirs ],
   ABSTRACT      => 'Academic Contributor Information System',
   AUTHOR        => 'Ivan Baktcheev & Ivan Kurmanov', 

#   dist => { PREOP => '$(CP) /home/ivan/dev/Index/Index/RePEc-Index-0.4.tar.gz $(DISTVNAME)', },

  );



# copied from AxKit's Makefile.PL, http://axkit.org


sub have_module {
    my ($module, $version) = (@_, 0);
    printf("checking for module %s >= version %s... ", $module, $version);


    if ( $version eq '0' ) { 
      $version = '';
    }
    print "eval(\"package Foo; use $module $version;\")\n" if $DEBUG;
    eval "package Foo; use $module $version;";
    if ($@) {
        print $@ if $DEBUG;
        print "no\n";
        return 0;
    }
    print "yes\n";
    return 1;
}

