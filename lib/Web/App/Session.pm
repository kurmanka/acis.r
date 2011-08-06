package Web::App::Session; ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Web Application's Session class.  Interacts deeply with the core
#    of the web application framework: Web::App.
#
#
#  Copyright (C) 2003 Ivan Baktcheev, Ivan Kurmanov for ACIS project,
#  http://acis.openlib.org/
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
#  ---
#  $Id$
#  ---


use strict;
use Storable;
use Carp::Assert;

use Web::App::Common;

sub type { 'default' }

sub new {
  my $class  = shift;
  my $app    = shift || die;
  my $owner  = shift;
  my %par    = @_;
  my $expire = $app -> config( 'session-lifetime' );
  my $dir    = $app -> sessions_dir;
  my $id = generate_id();

  while ( -f "$dir/$id" ) {
    $id = generate_id();
  }

  my $file = "$dir/$id";

  if ( open F, ">$file" ) {
    print F "placeholder blin $id";
    CORE::close F;

  } else {
    warn "can't write to session file: $file";
    return undef;
  }

  my $self = {
              '.id'       => $id,
              '.owner'    => $owner,
              '.filename' => $file,
              '.sticky'   => {}, 
              '.app'      => $app,
              '_'         => {},
             };
  bless $self, $class;

  if ( defined $expire ) {
    $self -> {'.lifetime'} = $expire * 60;
  }

  if ( $par{object} and $par{file} ) {
    $self->object_set( $par{object}, $par{file} );
  }

  $app -> event( -class  => 'session',
                 -action => "started",
                 -chain  => $id,
                 -stype  => $self->type,
                 -startend => 1 );

  return $self;
}

sub DESTROY {
  my $self = shift;
  undef $self->{'.app'};
}



###  class method, not object method.
###  Well, as any usual constructor.
sub load {
  my $class    = shift;
  my $app      = shift;
  my $filename = shift;
  my $self;
  
  if ( not -f $filename ) { return undef; }
  
  eval { $self = retrieve ($filename); };
  if ( $@ ) {
    debug "loading a session failed: $@";
    $app -> errlog( "fail to load a session: $filename ($@)" );
    return undef;
  }

  if (not defined $self) { 
    debug "loading a session failed with no error message";
    $app -> errlog( "fail to load a session: $filename" );
    return undef; 
  }

  $self -> {'.filename'} = $filename;
  $self -> {'.app'}      = $app;
  debug "loaded session from $filename";
  
  return $self;
}


sub expired {
  my $self       = shift;
  my $expirytime = $self ->{'.lifetime'};  ## in seconds

  return 0 if not $expirytime;

  my $filename = $self->{'.filename'};
  my $mtime    = ( stat( $filename ) )[9];
  my $now      = time();

  if ( $now - $mtime > $expirytime ) { return 1; }
  return 0;
}



sub filename {
  my $self = shift;
  return $self -> {'.filename'};
}  


sub lock {
  my $self = shift;
  my $lock = shift;

  for ( $self->{_}{lock} ) {
    if ( not $_ ) {
      $_ = [ $lock ];
    } else { 
      push @$_, $lock;
    }
  }

  return $self -> {_}{lock};
}


sub close {
  my $self = shift;
  
  return if  $self -> {'.closed'};

  my $file = $self -> {'.filename'};
  if ( -f $file ) {
    unlink $file 
      or warn "can't remove session $file";
  }

  my $lock = $self -> {_}{lock};
  if ( $lock and ref $lock eq 'ARRAY' ) {
    foreach (@$lock) {
      if ( $_ and -f $_ ) {
        unlink $_ or warn "can'r remove lock $lock";
      }
    }

  } elsif ( -f $lock ) {
    unlink $lock;
  } else {
    warn "session without lock? $lock";
  }

  $self -> { '.closed' } = 1;

  my $id  = $self ->id;
  my $app = $self ->{'.app'};
  if ($app) {
    $app -> event( -class  => 'session',
                   -action => 'closed',
                   -chain  => $id,
                   -startend => -1 );
  }
}
  

sub closed {
  my $self = shift;
  return $self -> {'.closed'};
}



sub id { 
  my $self = shift;
  return $self->{'.id'};
}

sub owner { 
  my $self = shift;
  return $self->{'.owner'};
}



sub get_value_from_path {
  my $data  = shift;
  my $path  = shift;

  #require UNIVERSAL;
  
  my @path  = split '/', $path;
  foreach ( @path ) {
    
    if ( not $data 
         or not &ref($data) 
         or not &ref($data) eq 'HASH' 
         #or not UNIVERSAL::isa( $data, 'HASH' )
       ) {
      return undef;
    }

    $data = $data -> {$_};
  }

  return $data;
}



sub save_value_to_path {
  my $data  = shift || die;
  my $path  = shift || die;
  my $value = shift;

  my @path = split '/', $path;
  my $last = pop @path;

  foreach ( @path ) {
    if ( not defined $data -> {$_} ) {
      $data -> {$_} = {}; 
    }
    $data = $data -> {$_};
  }
  $data -> {$last} = $value;
}


use Carp;

sub object_set { 
  my $self   = shift;
  my $object = shift;
  my $file   = shift;
  my $expect_lock_to_be_present = shift || 0;

  my $inner = $self ->{_};
  $inner ->{object}     = $object;

  if ( defined $file ) {
    $inner ->{objectfilereadfrom} = $file;
    $inner ->{objectfilesaveto}   = $file;
  }

  if ( $file ) {
    my $lock = "$file.lock";
    my $mode = ">";

    if ( open L, "$mode$lock" ) {
      print L $self->id;
      CORE::close L;
      $self ->lock( $lock );

    } else {
      warn "can't obtain the lock $lock";
      return undef;
    }
  } 

  return 1;
}


sub object {
  my $self = shift;
  return $self -> {_}{object};
}

sub object_file_save_to {
  my $self = shift;
  return $self->{_}{objectfilesaveto};
}

sub object_file_read_from {
  my $self = shift;
  return $self->{_}{objectfilereadfrom};
}


sub set_object_file {
  my $self    = shift;
  my $newfile = shift;

  my $inner = $self ->{_};
  $inner ->{objectfilesaveto} = $newfile;

  if ( $newfile ) {
    my $lock = "$newfile.lock";
    if ( -f $lock ) {
#      warn "lock file $lock present";
      return undef;
    }

    if ( open L, ">$lock" ) {
      print L $self->id;
      CORE::close L;
      $self ->lock( $lock );

    } else {
      warn "can't obtain the lock $lock";
      return undef;
    }
  } 
}




sub save  {
  my $self     = shift;
  my $filename = shift || $self -> {'.filename'};

  if ( $self -> {'.closed'} ) {
    return;
  }
  delete $self ->{'.app'};

#  use Data::Dumper;
#  debug Data::Dumper::Dumper( $self );
  eval { store $self, $filename; };
  if ( $@ ) {
    warn "can't save session: $@";
  }
}
 


###########################
####   sticky params   ####


sub make_sticky {
  my $self = shift;
  my @par  = @_;
  my $sticky = $self -> {'.sticky'};
  foreach ( @par ) {
    $sticky ->{$_} = 'sticky';
  }
}

sub remove_stickyness {
  my $self = shift;
  my @par  = @_;
  
  my $sticky = $self -> {'.sticky'};
  
  foreach ( @par ) {
    delete $sticky ->{$_};
  }
}

sub copy_sticky_params {
  my $self = shift;
  my $to   = shift;
  
  my $sticky = $self -> {'.sticky'};
  
  foreach ( keys %$sticky ) {
    if ( exists $self ->{$_} ) {
      $to ->{$_} = $self ->{$_};

    } else {
      delete $to ->{$_};
    }
  }
}

1;
