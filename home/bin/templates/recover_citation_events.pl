
use strict;
use warnings;
use Carp::Assert;
use ACIS::Web;
use sql_helper;
use Web::App::Common;

sub get_profile_details($);

# get $acis object, prepare a session
my $acis = ACIS::Web -> new() || die;
my $sql = $acis->sql_object;
my $s2 = $sql->other;
my $session = $acis -> start_session( "magic", { login => $0, IP => '0.0.0.0' } );
assert( $acis ->session );

my $switches = {};
my $queue = [];
foreach ( @ARGV ) {
  if ( m!^-(\w.*)! ) { $switches->{$1}=1; next; }
  if ( m!^--(\w*)! ) { $switches->{$1}=1; next; }
  push @$queue, get_profile_details( $_ );
}


if ( $switches->{a} ) {
  $sql -> prepare( "select login,userdata_file from users" );
  my $r = $sql -> execute();
  push @$queue, @{$r->data};
}

sub get_profile_details($) {
  my $in = shift;
  my $where = '';
  my @params;

  for ($in) {
    if (m!\w\@[\w\-\.]+\.\w+! ) { # login / email
      $where = 'login=?';
      push @params, $_;
      next;
    } elsif (m!^p\w+\d+! ) { # short-id
      warn "do not support shortids yet: $_\n";
    } else {
      warn "what is this: $_?\n";
    }
  }
  if ( $where ) { $where = "where $where"; }
  $sql->prepare( "select login,userdata_file from users $where" );
  my $r = $sql->execute( @params );
  return $r->{row};
}

require ACIS::Web::Admin;

my $VERBOSE = $switches->{verbose};
my $CLEAN   = $switches->{clean};

foreach my $p (@$queue)  {
  my $udf   = $p -> {'userdata_file'};
  my $login = $p -> {login};
  
  if ($switches->{qdebug} or $switches->{find}) {
    print "u file: $udf\t\tlogin: $login\n";
    next;
  }
  
  if ( $udf and -r $udf ) {
    $acis -> update_paths_for_login( $login );
    my $userdata = ACIS::Web::Admin::get_hands_on_userdata( $acis );
    if ( not $userdata ) { 
      if (-f "$udf.lock") {
        print "locked $login\n";
      }
      next; 
    }
    $session -> object_set( $userdata );

    # do things
    my $no = 0;
    foreach my $rec ( @{$userdata->{records}} ) {
      $session->set_current_record_no( $no );
      die if $rec ne $session->current_record;
      my $psid = $rec->{sid};
      my $cit = $rec->{citations};
      my $ide = $cit->{identified} 
        if $cit;
      if (not $cit or not $ide) { next; }

      my $count = 0;
      my $notfound = 0;
      my $q = "select cnid from citations where clid=?";
      if ($switches->{deleted}) { $q = "select cnid from citations_deleted where clid=?"; }
      $sql -> prepare_cached( $q );
      $s2 -> prepare_cached( "insert into citation_events (cnid,psid,dsid,event,reason,time) VALUES (?,?,?,?,?,?)" );
      foreach my $dsid ( keys %$ide ) {
        my $list = $ide->{$dsid};
        foreach ( @$list ) {
          my $srcdocsid = $_->{srcdocsid} || next;
          my $checksum  = $_->{checksum}  || next;
          my $date      = $_->{autoadded};
          my $reason    = $_->{autoaddreason};
          my $clid = "$srcdocsid-$checksum";
          my $r = $sql->execute($clid);
          if ($r and $r->{row} and $r->{row}{cnid} ) {
            my $cnid = $r->{row}{cnid};
            my $in=$s2->execute($cnid,$psid,$dsid,'autoadded',$reason,$date);
            print "$cnid,$psid,$dsid,event,$reason,$date: $in\n"
              if $VERBOSE;
            $count++;

            if ($in) {
              $_->{cnid} = $cnid;
              delete $_->{srcdocsid};
              delete $_->{checksum};
              delete $_->{nstring};
              delete $_->{similar};
              delete $_->{reason};
              delete $_->{new};
              delete $_->{citid};
              delete $_->{clid};
              delete $_->{trgdocid} if not defined $_->{trgdocid};
            }
          } else {
            $notfound++;
            print "- $srcdocsid-$checksum\n"
              if $VERBOSE;
            undef $_ if $CLEAN;
          }
        }
        clear_undefined($list) if $CLEAN;
      }

      print "$login $psid ($count/$notfound)\n";
    } continue { $no++;
    }
    $session->object->save;
    if (-f "$udf.lock") { unlink "$udf.lock"; } 
  }
}

$session->object_set(undef,undef);
###  close session
$session -> close( $acis ) if $session;  ### this fails because
                                         ### session_history writer
                                         ### wants an account name
  

