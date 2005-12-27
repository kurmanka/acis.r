use ExtUtils::MakeMaker;



WriteMakefile
  (
   'NAME'                => 'sql-helper',
   'VERSION_FROM'        => 'sql_helper.pm', # finds $VERSION
   'PREREQ_PM'        =>  {
                     'DBI' => '',
                     'DBD::mysql' => '',

                    },


#                     'XML::XPath'   => '',
#                     'XML::Parser'  => '',
#                     'sql_helper'   => '',
#                     'Carp::Assert' => "",
#                     'AppConfig'    => "",
#                     'RePEc::Index' => "",
#                     'Storable'     => "",
#                    }, 
   ABSTRACT      => 'DBI SQL interface helper module',
   AUTHOR        => 'Ivan Kurmanov', 
  );

