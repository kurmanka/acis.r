package ACIS::Data::SerializeStorable;

# 2011 Oct 28, Ivan Kurmanov
# this is a plugin module for serialization via Storable;
# to be used as an alternative to Common::Data.

# See serialization-module configuration parameter, the 
# ACIS::Data::Serialization local module written by
# the home/bin/setup.data_serialization script.

use strict;
use Storable (nfreeze thaw);

use Exporter qw( import );
use vars qw( @EXPORT );
@EXPORT = qw( inflate deflate );


sub inflate { return thaw( @_ ); }

sub deflate { return nfreeze( @_ ); }

1;
