package ACIS::Web::Config;   ### -*-perl-*-  
#
#  This file is part of ACIS software, http://acis.openlib.org/
#
#  Description:
#
#    Web Application Core configuration.  Has two main parts: general
#    configuration parameters and configuration of the application
#    screens, screens.xml.  Used by the ACIS::Web class and contains
#    some ACIS-specific details at the same time.
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
#  $Id: Config.pm,v 2.5 2006/07/24 10:53:09 ivan Exp $
#  ---


package ACIS::Web;

use strict;

sub configuration_parameters {
  my $self = shift;

  my $p = $self -> SUPER::configuration_parameters;

  return {
    %$p, 

    # web interface
    'static-base-url',  'required',
    'static-base-dir',  'required',
    'session-lifetime', '15',

    'profile-pages-dir', 'profile/',
    'compact-redirected-profile-urls', "not-defined",

    'cgi-perl-wrapper',  'not-defined',

    # cookies
#    'auth-cookie-domain',    'not-defined',
#    'auth-cookie-age-days',  '365',
    'admin-access-pass',     'not-defined',
   
    # email-related
    'institutions-maintainer-email', 'required',
    
    # The data that ACIS produces
    'person-id-prefix',    'required',
    'metadata-ReDIF-output-dir', 'not-defined',
    'metadata-AMF-output-dir',   'not-defined',
    
    # database parameters
    'metadata-db-name', 'required',

    # debugging
    'extreme-debug',         'not-defined',
    'log-profiling-data',    'not-defined',
    'show-profiling-data',   'not-defined',
    'echo-arpu-mails',       'not-defined', # deprecated? 
    'echo-apu-mails',        'not-defined',

    # disabling features
    'research-auto-search-disabled', 'not-defined',
    'research-additional-searches',  'not-defined',


    # ACIS Metadata Update (/meta/update)
    'meta-update-clients', 'not-defined',
    'meta-update-object-fetch-func', 'not-defined',

    # citations:
    'citations-profile', 'not-defined',
    'citation-document-similarity-func', 'not-defined',
    'citation-document-similarity-ttl',  '100',     
    'citation-document-similarity-preselect-threshold', '0.75',

   };

}


1;
