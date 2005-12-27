package ACIS::Web::Import;

use strict;

use Carp::Assert;

use ReDIF::Parser;
use ReDIF::Record;

use Web::App::Common qw( &date_now &debug );

use ACIS::Web::Admin;
use ACIS::Web::Contributions;
use ACIS::Web::Affiliations;
use ACIS::Web::NewUser;

use vars qw( $ERROR );

sub error {
  my $message = shift;
  $ERROR = $message;
  warn "ERR: $message";
}

sub last_error {
  return $ERROR;
}

sub import_redif_file {
  my $ACIS = shift;
  my $file = shift;
  
  if ( not -e $file 
       or not -r _    
       or not ReDIF::Parser::open_file( $file ) ) {
    error "can't open file $file";
    return undef;
  }

  my $template = ReDIF::Parser::get_next_template_good_or_bad();
  return undef if not $template;

  bless $template, 'ReDIF::Record';

  my $id = $template -> id;
  my ( $end ) = ( $id =~ m/:([^:]+)$/ );  
  if ( not $end 
#       or $end =~ /\d+/ 
     ) { 
    error "bad person template id: $id";
    return undef;
  }
  
  my $res = import_redif_person( $ACIS, $template );

  if ( not $res ) {  error( undef );  }

  return $res;
}



#########################################################################
###   sub   R e D I F   I M P O R T  
### --------------------------------------------------------------------

my $buffer = '';
sub printout {
  my $msg = join '', @_;
  if ( $ENV{REMOVE_ADDR} ) {
    $buffer .= "$msg\n";
  } else {
    print "$msg\n";
  }
}


sub import_redif_person {
  my $acis = shift;
  my $template = shift;

  debug "import ReDIF person record";

  my $email  = lc $template -> {email}[0];
  debug "email: $email";
  my $handle = $template -> {handle}[0];

  my $fname  = $template ->{'name-first'} [0];
  my $lname  = $template ->{'name-last'} [0];
#  my $name   = $template ->{'name-full'} [0];
  my $name   = name_case_correct( "$fname $lname" );

  my $mode;
  my $session;
  my $userdata;
  my $paths = $acis ->paths;
  my $vars  = $acis ->variables;

  ###  create a session for that user-data
  
  my $owner = { login => $0 };
  $owner -> {'IP'} = '0.0.0.0';
  
  $session = $acis -> start_session ( "magic", $owner );



  $acis -> update_paths_for_login ( $email );
  my $userdata_file = $paths -> {'user-data'};

  $vars -> {import} {'real-user'} {email} = $email;
  $vars -> {import} {'real-user'} {name}  = $name;

  $acis -> sevent ( -class  => 'new-user',
                    -action => 'importing',
                    -login  => $email,
                 -humanname => $name,
                    );

  if ( -e $userdata_file ) {

    $userdata = ACIS::Web::Admin::get_hands_on_userdata( $acis );
    
    if ( not $userdata ) {
      debug "can't get hands on userdata; aborting"; 
      return undef;
    }

    
    my $records_list = $userdata->{records};
    my $records = {};
    
#    printout "Current records of the user:";
    foreach ( @$records_list ) {
      my $id = $_ -> {id};
      $id    = lc $id;
      $records->{$id} = $_; 
#      printout "id: $id, rec type: $_->{type}";
    }

    if ( exists $records ->{lc $handle} ) { $mode = "re"; }
    else { $mode = "new"; }

    ### generate userdata person record from template
    my $record = make_record_from_person_template( 
                                                  $acis, 
                                                  $template,
                                                  $records ->{lc $handle}
                                                 );

    $vars -> {import} {'real-user'} {name}  = $name;
    
    ### put the record into userdata
    if ( $mode eq 'new' ) {
      push @$records_list, $record;

    } else {
      foreach ( @$records_list ) {
        if ( $_->{id} eq lc $handle ) {
          $_ = $record;
          last;
        }
      }
    }

    if ( scalar @$records_list > 1 ) {
      $userdata -> {owner} {type} {advanced} = 1;
      $vars -> {'account-type-promoted'}     = "advanced";

      delete $record -> {contact} {'email-pub'};
    }

    ### if it is a new record, send email 'import/new-record'
    ### XXX if it is an existing record, send email 'import/re-record'
    $session -> set_notify_template( 'email/import/new-record.xsl' );
  
  } else {
    $mode = 'new-account';
    
    ### create new userdata
    $userdata   = $acis -> create_userdata();
    my $owner   = $userdata -> {owner};
    my $records = $userdata -> {records};
  
    assert( ref $records eq 'ARRAY' );
  
    ### build owner record
    $owner = $userdata->{owner} =
        make_owner_from_person_template( $acis, $template );

    $vars -> {import} {'real-user'} {name}  = $name;

    my $pass = $owner -> {password};

    ### generate userdata person record from template
    my $record = make_record_from_person_template( $acis, $template );
    $record -> {'about-owner'} = 'yes';
    
    ### put the record into userdata
    $records ->[0] = $record;

    $vars ->{import} {password} = $pass;

    $session -> set_notify_template( 'email/import/new-account-record.xsl' );
    ### send email (import/new-acount-record)
  }


  $session -> object_set( $userdata );


  ###  loop through the records to fill empty spaces in accepted contributions
  my $num = 0;
  foreach ( @{ $userdata->{records} } ) {
    $session -> set_current_record_no( $num );

    # reload the contributions:
    ACIS::Web::Contributions::reload_accepted_contributions( $acis );

    $num ++;
  }

  
  
  $session -> close( $acis );
  undef $acis -> {session};

  return 1;
#  printout "imported ok ($mode)";
}



#############################################################################
###     R e D I F    P E R S O N    T E M P L A T E    I M P O R T
### -------------------------------------------------------------------------


my $pwgen_command = "pwgen -ac --numerals 7";

sub make_owner_from_person_template {
  my $app      = shift;
  my $template = shift;

  my $owner    = {};

  my $password = `$pwgen_command`;
  assert( $password ) ;
  chomp $password;

  $owner -> {password} = $password;
  ($owner -> {login} ) = $template -> get_value ( 'email' );

  my $fname  = $template ->{'name-first'} [0];
  my $lname  = $template ->{'name-last'} [0];
  my $name   = name_case_correct( "$fname $lname" );

  $owner -> {name} = name_case_correct( $name );

  $owner -> {imported} = {};
  $owner -> {imported} {date} = date_now();
  $owner -> {imported} {fromFile} = $template -> {FILENAME};
  $owner -> {imported} {fromTemplate} = $template -> id;
  
  return $owner;
}


sub name_case_correct {
  my $name = shift;

  my $n = join( " ", map { ucfirst(lc($_)) } split( / /, $name ) );

  for ( $n ) {
    s/-(\w)/'-'.uc($1)/eg; # get hyphenated names right!
    s/^(\w)'(\w)/$1."'".uc($2)/e; # get O'Connell right! "
    s/^Mc(\w)/'Mc'.uc($1)/ie; # get McFadden right!
    s/\b(\w)\./uc($1).'.'/ge; # fix j.g.m. Scheirs
    # fix van, der etc.
    s/\bDe\b/de/ig;
    s/\bDer\b/der/ig;
    s/\bVan\b/van/ig;
    s/\bVon\b/von/ig;
  }

  return $n;
}



sub make_record_from_person_template {
  my $app      = shift;
  my $template = shift;
  my $rec      = shift || {};

  my $id       = $template ->id;

  $rec ->{type} = 'person';
  $rec ->{id}   = $id;

  {
    my ( $full  )= $template -> get_value ( 'name-full'  );
    my ( $first )= $template -> get_value ( 'name-first' );
    my ( $last  )= $template -> get_value ( 'name-last' );
    
    $full  = name_case_correct( "$first $last" );
    $first = name_case_correct( $first );
    $last  = name_case_correct( $last );

    my $name    = {
      full  => $full,
      first => $first,
      last  => $last,
    };

    my @variations = ( $full, "$last, $first" );
    $name -> {'additional-variations'} = \@variations;
#    $name -> {'variations'} = \@variations;

    $rec -> {name} = $name;
  }
  
  ###  make or get short-id
  my $sid = ACIS::Web::NewUser::make_short_id( $app, $rec );
  if ( not $sid ) {
    warn "can't make a short id ($id)";
    return undef;
  }


  ###  copy and expand affiliations
  {
    my @affiliations = $template -> get_value( 'workplace-institution' );
    $rec -> {affiliations} = \@affiliations;
  }
  
  ###  copy contact details
  { 
    my $contact = {};
    my ( $email    )= $template -> get_value ( 'email'    ); ### XX ?
    my ( $homepage )= $template -> get_value ( 'homepage' );
    my ( $phone    )= $template -> get_value ( 'phone'    );
    my ( $postal   )= $template -> get_value ( 'postal' );
    my ( $fax      )= $template -> get_value ( 'fax' );

    $contact ->{email} = $email;
    $contact ->{'email-pub'} = 'true'; 
    ### XX consistency in specifying logical values in userdata would do good
    
    if ( defined $homepage ) { $contact->{homepage} = $homepage; }
    if ( defined $phone    ) { $contact->{phone}    = $phone;    }
    if ( defined $postal   ) { $contact->{postal}   = $postal;   }
    if ( defined $fax      ) { $contact->{fax}      = $fax;      }

    $rec ->{contact} = $contact;
  }

  ###  copy and expand contributions
  { 
    my $contributions = {};

    my @accepted = ();
    foreach ( qw( author-paper author-article 
                  author-software author-book author-chapter 
                  editor-series editor-book ) ) {
      my $att = $_;
      my @v   = $template ->get_value( $att );
      my ( $role, $type ) = ( $att =~ m!^(\w+)\-(\w+)$! );
      foreach ( @v ) {
        my $item = {
            role => $role, 
            id   => $_,
#            type => $type,
        };
        push @accepted, $item;
      }
    }
    $contributions ->{accepted} = \@accepted;
    $rec ->{contributions} = $contributions;
  }

  ### classification-jel
  {
    my ( $jel )= $template->get_value( 'classification-jel' );
    if ( $jel ) {
      $rec -> {interests} ->{jel} = $jel;
    }
  }

  
  $rec -> {imported} = {};
  $rec -> {imported} {date} = date_now();
  $rec -> {imported} {fromFile} = $template -> {FILENAME};
  $rec -> {imported} {fromTemplate} = $template -> id;

  {
    my ($registeredDate  )= $template ->get_value( 'registered-date' );
    my ($last_login_date )= $template ->get_value( 'last-login-date' );
    my ($last_mod_date   )= $template ->get_value( 'last-modified-date' );
    my $imported          = $rec ->{imported};
    if ( defined $registeredDate ) {
      $imported ->{'registered-date'}    = $registeredDate;
      $imported ->{'last-login-date'}    = $last_login_date;
      $imported ->{'last-modified-date'} = $last_mod_date;
    }
    $last_login_date = $template ->get_value( 'x-last-confirmed-update' );
    if ( $last_login_date ) {
      $imported -> {'last-login-date'} = $last_login_date;
    }

  }
  
  return $rec;  #### XX not finished?  What's left?  I don't know.
}





1;

