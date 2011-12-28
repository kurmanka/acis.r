package ACIS::Web::Session::SOldUser;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Old User's session class
#
#
#  Copyright (C) 2003 Ivan Kurmanov, ACIS project, http://acis.openlib.org/
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

use strict;

use Carp::Assert;
use Data::Dumper;
use Digest::MD5 qw(md5 md5_base64);

use Web::App::Common qw( &date_now debug );

use ACIS::Web::Session;
use ACIS::Web::UserData;
use ACIS::Web::Affiliations;

use base qw( ACIS::Web::Session );


sub digest {
    my $data = shift;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Indent = 0;
    my $str  = Dumper( $data );
    return md5_base64( $str );
}



sub type { 'user' }

sub close {
  my $self = shift;
  my $app  = shift || die;
  debug "->close() session";
 
  ### save last login (logoff) date
  my $userdata = $self ->userdata;
  my $owner    = $self ->userdata_owner;

  if ( $userdata ) {

    # save any unsaved changes
    $self->save_current_record( 'closeit' );

    if ( $self -> has_userdata_changed ) {
      debug "->close: userdata has changed";
      $owner -> {'last-change-date'} = date_now();

      ###  handle userdata owner login change
      if ( $owner -> {'old-login'} ) {

        $app -> userlog ( "log off: login change from ", 
                          $owner->{'old-login'},
                          " to ", 
                          $owner->{login}
                        );

        # prepare data for email
        if ( $self->type eq 'admin-user' ) {
            $app->variables->{'modified-owner'} = $owner;
        }
        
        # send email
        $app -> send_mail ( 'email/user-login-changed.xsl' );

        # delete old file
        my $udata_file = $self -> {'.userdata.readfrom'};
        debug "old userdata file is: $udata_file, trying to delete it";
        if ( not unlink $udata_file ) {
          warn "can't delete $udata_file: $!";
          $app -> errlog ( "can't delete $udata_file: $!" );
        }

        delete $owner -> {'old-login'};
      }
      delete $owner -> {placeholder_file};

      eval { 
        ### generate static pages and metadata files
        if ( not $self -> {'.saved_profile'} ) {
          require ACIS::Web::SaveProfile;
          ACIS::Web::SaveProfile::save_profile( $app );
        }
      };
      my $prob = $@;

      ### write userdata and request RI update
      $self -> save_userdata( $app );
      
      if ( $prob ) { die $prob; }
      $self -> notify_user_about_profile_changes( $app );
    }
  } else {
    debug "no userdata";
  }

  &ACIS::Web::Affiliations::send_submitted_institutions_at_session_close($self);

  $self -> SUPER::close( $app );
}

sub set_userdata_saveto_file {
    my $self = shift;
    my $f = shift || die; 
    $self->{'.userdata.saveto'} = $f;
}

sub has_userdata_changed {
    my $self = shift;

    if ($self->{'.userdata.owner.modified'}) {
        return 1;
    }
    my $reclist = $self->{'.userdata.record_list'};
    foreach ( @$reclist ) {
        if ($_->{modified}) { return 1; }
    }
    return 0;
}

sub object {
    my $self = shift;
    my ($package, $filename, $line, $subr) = caller(1);
    debug "->object() from $subr";
    return $self->userdata;
}

sub notify_user_about_profile_changes {
  my $self = shift;
  my $app  = shift;
  
# do nothing
#  ### send email
#  $app -> send_mail ( 'email/user-data-changed.xsl' );
}


sub object_set { shift->set_userdata(@_); }

sub set_userdata {
    my $self = shift;
    my $ud   = shift;
    my $ud_file = shift ;
    my $owner   = $ud->{owner};
    my $records = $ud->{records};

    debug "->set_userdata(): owner $owner + ", scalar @$records, " record(s)";
    
    $self->{'.userdata.owner'} = $owner;
    my $od = $self->{'.userdata.owner.digest'} = digest( $owner );
    debug "owner digest: $od";
    my $rl = $self->{'.userdata.record_list'} = build_record_list( $records );
    my $i = 0;
    foreach (@$rl) {
        debug "record_list[$i]: ", $_->{name}, " (", $_->{sid}, ", ", $_->{digest}, ")";
        $i++;
    }

    # this will stay there until ->save()
    $self->{'.userdata'} = $ud;

    if ($ud_file) {
        $self->{'.userdata.tempfile'} = $ud_file . ".new";
        $self->{'.userdata.saveto'}   = $ud_file;
        $self->{'.userdata.readfrom'} = $ud_file;
    } else {
        die "userdata set, but the userdata filenames are not";
    }

    if ( not $self->make_lock_for( $ud_file ) ) {
        return undef;
    }
    
    return 1;
}

sub userdata_record_list { return shift->{'.userdata.record_list'}; }

sub make_lock_for { 
  my $self   = shift;
  my $file   = shift || die;

  my $lock = "$file.lock";
  if ( open L, '>', $lock ) {
      print L $self->id;
      CORE::close L;
      $self ->{'.userdata.lock'} = $lock;
  } else {
      warn "can't create lock $lock";
      return undef;
  }
  return 1;
}


sub save {
    my $self = shift;
    delete $self->{'.userdata'};
    return $self->SUPER::save;
}

sub prepare_userdata_for_save {
    my $self = shift;
    
    my $reclist = $self->{'.userdata.record_list'};

    # load from tempfile, if not loaded yet
    my $ud = $self->userdata;
    
    # update it with latest changes from the session
    if ( $ud ) {

        # Save owner details, if modified.
        # This can probably be omitted. Why do this every time we
        # switch a record?
        if ( my $o = $self->{'.userdata.owner'} ) { 
            my $digest_old = $self->{'.userdata.owner.digest'};
            my $digest_new = digest( $o );
            if ($digest_new ne $digest_old) {
                # the owner details have changed, and need to be overwritten
                $ud->{owner} = $o;
                $self->{'.userdata.owner.digest'} = $digest_new;
                $self->{'.userdata.owner.modified'} = 1;
            }
        }

        # do the same with the current_record
        $self->save_current_record;
    }

    return $ud;
}

sub userdata {
    my $self = shift;
    if ($self->{'.userdata'}) { return $self->{'.userdata'}; }
    return( $self->{'.userdata'} = $self->load_userdata_temp );
}

sub load_userdata_temp {
    my $self = shift;
    my $file = $self->{'.userdata.tempfile'} || die "no tempfile defined";
    if (not -f $file) {
        $file = $self->{'.userdata.readfrom'} || die "no readfrom file defined";
    }
    debug "->load_userdata_temp(): $file";
    return ACIS::Web::UserData->load( $file );
}

sub save_userdata_temp {
    my $self = shift;
    my $ud = $self->prepare_userdata_for_save;
    # store it to the tempfile
    debug "->save_userdata_temp()";
    return $ud -> save( $self->{'.userdata.tempfile'} );
}

sub save_userdata_final {
    my $self = shift;
    # store it to the tempfile
    my $ud = $self->save_userdata_temp;

    # move it to the final destination
    my $tmp   = $self->{'.userdata.tempfile'};
    my $final = $self->{'.userdata.saveto'};

    debug "->save_userdata_final(): move $tmp to $final";
    my $success = rename( $tmp, $final );
    if (not $success) {
        debug "can't move temporary file to the final: $tmp -> $final",
    }

    return $success;
}

sub save_userdata_file {
    my $self = shift;
    return $self->save_userdata_final();
}


sub set_current_record_no {
    my $self = shift;
    my $no   = shift;
    debug "->set_current_record_no( $no )";

    my $reclist = $self->{'.userdata.record_list'};
    my $cur_no  = $self->{'.userdata.current_record.no'};

    if (defined $cur_no) {
        if ($cur_no == $no) {
            return $cur_no;
        } else {
            debug "save current record and save userdata (temp)";
            $self ->save_current_record('closeit');
            $self ->save_userdata_temp;
        }
    }
    
    if ($reclist->[$no]) {
        my $rec  = $self->userdata->{records}->[$no];
        $self->{'.userdata.current_record'}    = $rec;
        $self->{'.userdata.current_record.no'} = $no;

        debug "record $no is now current";

        # now do some compatibility checks for the record
        if (not $reclist->[$no]->{upgradechecked}) {
            $reclist->[$no]->{upgradechecked} = 1;
            require ACIS::Web::Person;
            ACIS::Web::Person::bring_up_to_date( $ACIS::Web::ACIS, $rec );
        }
    }
    
    return $cur_no;
}


sub save_current_record {
    my $self = shift;
    my $closeit = shift; # boolean
    
    my $ud      = $self->userdata;
    my $reclist = $self->{'.userdata.record_list'} || die;
    my $cr      = $self->{'.userdata.current_record'};
    my $cur_no  = $self->{'.userdata.current_record.no'};

    my $ret; # return value

    if (defined $cr and defined $cur_no) {
        my $digest_old = $reclist ->[$cur_no]->{digest};
        my $digest_new = digest( $cr );
        
        if ( $digest_old eq $digest_new ) {
            # unchanged
            $ret = 0;
        } else {
            $ud ->{records}->[$cur_no] = $cr;
            $reclist ->[$cur_no]{digest} = $digest_new;
            $reclist ->[$cur_no]{name}   = $cr->{name}{full};
            $reclist ->[$cur_no]{modified} = 1;
            $ret = 1;
        }

        if ($closeit) {
            undef $self->{'.userdata.current_record'};
            undef $self->{'.userdata.current_record.no'};
        }
    }
    return $ret;
}



sub build_record_list {
    my $records = shift;
    my @list = map { name => $_->{name}{full}, 
                     id   => $_->{id},
                     sid  => $_->{sid},
                     digest => digest( $_ )
    }, @$records;
    return \@list;
}

1;
