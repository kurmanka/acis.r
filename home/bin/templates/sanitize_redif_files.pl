
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
$sql -> prepare( "select id,userdata_file from records where shortid =?" );


my $count = 0;
my $redif_dir = $acis -> config( "metadata-ReDIF-output-dir" );
if ( open FLIST, "find $redif_dir -type f -name '*.rdf'|" ) {
  while ( <FLIST> ) {
    if ( m!/(p[a-z]+\d+)\.rdf! ) {
      my $rfile = $_;
      my $sid  = $1;
      my $res  = $sql -> execute( $sid );

      if ( $res and $res->{row} ) {
        my $id   = $res ->{row}{id};
        my $file = $res ->{row}{'userdata_file'};
        
        if ( not $file ) {
          p "$sid,$id - no file $file";
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
        
      } else {
        p "$sid: no such record (file $rfile should be deleted)";
      }

    }
  }
}


close FLIST;

__END__

