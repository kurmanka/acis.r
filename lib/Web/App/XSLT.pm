package Web::App::XSLT;

use strict;
use Carp::Assert;

use open ':utf8';

require XML::LibXML;
require XML::LibXSLT;

use Web::App::Common qw( debug );

sub presentation_builder {
  my $self      = shift;
  my $presenter = shift; ### or stylesheet file
  my @params    = @_;

  return undef if not $presenter;

  ###  run presenter
  if ( ref $presenter ) {
    assert defined $presenter->{file}, 'presenter file must be defined';
    if ( $presenter->{type} eq 'xslt' ) {
      return run_xslt_presenter( $self, $presenter ->{file}, @params );
    } 

  } else {
    ### filename as presenter
    return run_xslt_presenter( $self, $presenter, @params );

  } 

  die "unknown presenter type: $presenter->{type}";
  return undef;
}





sub run_xslt_presenter {
  my $self          = shift;
  my $presenterfile = shift;
  my $params        = { @_ };

  my $hide_emails      = $params -> {-hideemails};
  my $feed_data_string = $params -> {-feeddatastring};

  assert( $presenterfile );

  my $homedir   = $self ->{home};
  assert( $homedir );

  my $paths          = $self -> paths || die;
  my $presenters_dir = $paths -> {presenters};

  my $data        = $self ->{'presenter-data'};

  my $data_string = $self -> serialize_presenter_data;
  if ( $feed_data_string ) { 
    &$feed_data_string( $data_string );
  }
  if ( $self -> config( "debug-transformations" ) ) {
    dump_data_file( "$homedir/presenter_data.xml", \$data_string );
  }
  #assert( $data_string );

  $self -> time_checkpoint( 'serializer' );

  my $file = $presenters_dir . "/" . $presenterfile;
  my $result;
  my $error = '';
  my $msg   = '';
  
  debug "using stylesheet $file to generate some content";

  my @event = ( -class => 'presentation',
             -template => $presenterfile,
                 -file => $file,
              );
  
  if ( not -f $file ) {
    debug "we can't find stylesheet file '$file'";
    $error = 'found';
    $self -> sevent ( 
                     @event,
                     -type  => 'error',
                     -descr => "stylesheet missing",
                    );
    return undef;
  }
  
  my $parser = new XML::LibXML;
  my $xslt   = new XML::LibXSLT;

  $parser -> expand_entities (0);
  $parser -> load_ext_dtd (0);
  $parser -> validation(0);
  $parser -> keep_blanks(0);
   
  my $stylesheet;
  
  # parsing the stylesheet
  eval {
    $stylesheet   = $xslt  -> parse_stylesheet_file( $file );
    assert( $stylesheet );
  };

  if ( $@ or $XML::LibXSLT::error ) {
    $self -> errlog( "Can't parse xslt ($file): " . ($@ || $XML::LibXSLT::error) );
    $self -> sevent ( @event,
                     -type  => 'error',
                     -descr => "stylesheet XML-invalid",
                   );
    die "Can't parse stylesheet $file: " . ($@ || $XML::LibXSLT::error);
  }


  # transformation
  my $result_object;
  eval {
    $self -> time_checkpoint( 'transf_prep' );
    my $source = $parser -> parse_string ( $data_string );
    assert( $source, "Can't parse XML data string" );
    $self -> time_checkpoint( 'parsed_data' );
    $result_object = $stylesheet -> transform($source);
    $result = $stylesheet -> output_string( $result_object );
  };
    
  if ( $@ or $XML::LibXSLT::error 
       or not $result_object or not $result ) {
    my $err = $@;
    if ( not $@ ) {
      if ( $XML::LibXSLT::error ) {
        $err = "XML::LibXSLT::error: $XML::LibXSLT::error";
      } elsif ( not $result_object ) {
        $err = 'no $result_object';
      } elsif ( not $result ) {
        $err = 'no $result';
      }
    }
    $self -> errlog( "xslt transformation error, stylesheet: $file ($@)" );
    $self -> sevent ( @event,
                      -type  => 'error',
                      -descr => "stylesheet transformation problem",
                    );

    dump_data_file( "$homedir/bad_presenter_data.xml", \$data_string );

    die "Can't transform data with stylesheet: $file\n" .
      "Problem: $err";
  }

  $result = Encode::decode_utf8( $result );

  if ( not $error 
      and  ( 
            not defined $result 
            or $result eq ''
            or $result =~ m!body></body! 
           ) 
    ) {
    $self -> errlog( "xslt transformation result is empty: $file ($@)" );
    warn "presenter's transformation result is empty";
    debug "presenter's transformation result is empty";

    $self -> sevent ( @event,
                      -type  => 'error',
                      -descr => "transformation result is empty",
                    );

    dump_data_file( "$homedir/bad_trans_presenter_data.xml", \$data_string );
    dump_data_file( "$homedir/bad_trans_presenter_result.xml", \$result );
  }


  if ( $hide_emails ) {
    hide_emails( \$result );
  }

  if ( $self -> config( "debug-transformations" ) ) {
    dump_data_file( "$homedir/presenter_result.xml", \$result );
  }

  return \$result;
}



sub dump_data_file {
  my $filename = shift;
  my $dataref  = shift;

  if ( open FILE, ">$filename" ) {
    print FILE $$dataref;
    close FILE;
    
  } else {
    warn "can't open file $filename for writing: $!";
  }
}




### anti-spam email hiding

sub hide_emails {
  my $ref  = shift;
  assert( ref $ref );

#  my $data = $$ref;
  
  my $i = $$ref =~ s/(\'mailto:|\"mailto:|>)([^\@\s]+)\@([^\@\s]+)(\'|\"|<)/$1$2&#64;$3$4/g;
  
#  warn "emails hidden: $i\n";

}







1;
