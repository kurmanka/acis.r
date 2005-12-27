
use Carp::Assert;

use sql_helper;

use warnings;

require ACIS::Web;
use Web::App::Common; 

my $safe_mode = 0;
foreach ( @::ARGV ) {
  if ( m/^--safe$/ ) {
    $safe_mode = 1;
    undef $_;
  }
}
clear_undefined( \@::ARGV );

sub p (@) {
  print @_, "\n";
}


my $acis = ACIS::Web -> new( homedir => $homedir );
assert( $acis );

my $sql = $acis -> sql_object;

my $profile_dir = $acis -> config( "profile-pages-dir" );
my $static_dir  = $acis -> paths ->{shared};

$sql -> prepare( "select id,shortid,userdata_file from records" );
my $res = $sql -> execute( );

my $count = 0;


while ( $res and $res->{row} ) {
  my $id   = $res ->{row}{id};
  my $file = $res ->{row}{'userdata_file'};
  my $sid  = $res ->{row}{shortid};

  if ( not $file ) {
    p "$id - no file $file";
    next; 
  }

  if ( not $sid ) { 
    p "no sid: $id";
    next;
  }

  if ( -e $file ) {
    if ( open UD, "<", $file ) {
      my @content = <UD>;
      my $content = join '', @content;
      close UD;
      if ( not $content ) {
        p "file is empty: $file (id: $id)";
        next;
      }

      my $test = "<sid>$sid</sid>";

      if ( index( $content, $test ) > 0 ) {
#        print ".";
        next;
      } else {
        p "didn't find right sid: $sid in file $file (id: $id)";
      }

    } else {
      p "can't open $file";
      next;
    }

  } else {
    p "no such file: $file";
  }

  if ( $sid ) {
    my @parts = split( '', $sid );
    my $iddir = join '/', @parts;
    
    my $file = $static_dir . "/$profile_dir$iddir/index.html";
    if ( -f $file ) {

      if ( $safe_mode ) {
        p "could have removed $file";

      } else {
        unlink $file;
        p "removed $file";
      }
    } else { 
      p "profile file $file does not exist";
    }
  }


  if ( not $safe_mode ) {

    $sql -> prepare( "delete from names where shortid=?");
    $sql -> execute( $sid );
    $sql -> prepare( "delete from sysprof where id=?" );
    $sql -> execute( $sid );
    $sql -> prepare( "delete from suggestions where psid=?" );
    $sql -> execute( $sid );
    $sql -> prepare( "delete from threads where psid=?" );
    $sql -> execute( $sid );

    $sql -> prepare( "delete from records where id=?");
    $sql -> execute( $id );

    p "cleared: $id ($sid)";

  } else {
    p "need to clear: $id ($sid)";
  }

  $count ++;

} continue {
  $res -> next;
}


print "total: $count record(s)\n";
