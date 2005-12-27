package ACIS::Web::CGI::Untaint::url;

use strict;
use base qw(CGI::Untaint::printable);

use vars qw/$VERSION/;

#taken from package ReDIF::URL_Syntax;

#   $Id: url.pm,v 2.0 2005/12/27 19:47:40 ivan Exp $
$VERSION = do { my @r=(q$Revision: 2.0 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r }; 


###  Loosely aim to comply with RFC2396

###  Taken from the URI module (c) Gisle Aas

use vars qw($reserved $mark $unreserved $uric $scheme_re $hostport );

$reserved   = q(;/?:@&=+$,);
$mark       = q(-_.!~*'());                 #'); emacs
$unreserved = "A-Za-z0-9\Q$mark\E";
$uric       = quotemeta($reserved) . $unreserved . "%";

my $uric_no_slash = $uric; 
$uric_no_slash =~ s!/!!;   ## remove slash character

my $opaque_part = "[" . $uric_no_slash. "]+";

# $pchar = $unreserved . '%' . quotemeta( ':@&=+$,' );
# $segment = '[' . $pchar . ']*' .'(?:;[' . $pchar . ']*)*' ;

my $_pchar   = $unreserved . '%' . quotemeta( ':@&=+$,;' );

my $_segment = '[' . $_pchar . ']*' ;


my $abs_path = '/' . $_segment . '(?:/' . $_segment . ')*';

my $query    = '[' . $uric . ']*';


# $scheme_re  = '[a-zA-Z][a-zA-Z0-9.+\-]*';

# Build a char->hex map
my %escapes =();

for (0..255) {
    $escapes{chr($_)} = sprintf("%%%02X", $_);
}


### based on rfc 1783:

my $alphadigit  = 'A-Za-z0-9';

my $uchar = $alphadigit . quotemeta( '$-_.+!*(),' ) . "'%";

my $uchar_ext   = $uchar . quotemeta( ';?&=' );
my $uchar_ext2  = $uchar . quotemeta( ';:@&=' );
my $uchar_ext3  = $uchar . quotemeta( '?:@&=~' ); 

# $hsegment    = "[$uchar_ext2]*";
# $search      = "[$uchar_ext2]*";
# $hpath       = $hsegment . '(?:\/' . $hsegment . ')*';

my $fsegment    = "[$uchar_ext3]*";
my $fpath       = $fsegment . '(?:\/' . $fsegment . ')*';

my $alphadigit_  = '[A-Za-z0-9]';
my $alphadigit_dash  = '[A-Za-z0-9\-]';

my $domainlabel = $alphadigit_ . '(?:' . $alphadigit_dash . '*'. $alphadigit_ . ')?';
my $topdomain   =   '[A-Za-z]' . '(?:' . $alphadigit_dash . '*'. $alphadigit_ . ')?';
my $domainname  = '(?:' . $domainlabel . '\.)+' . $topdomain;
my $hostnumber  = '\d+\.\d+\.\d+\.\d+';

my $hostport    = '(?:' . $domainname . '|' . $hostnumber . ')' . '(?:\:\d+)?' ; 

my $fragment_re = "#[$uchar]*";


# $httpurl     = "http://" . $hostport . "(?: / $hpath (?: \\? $search )? )? $fragment_re"; 

### after rfc2396:
$fragment_re = "(?:\\#[$uric]*)?";

my $httpurl      = "http(s)?://" . $hostport . "(?: $abs_path (?: \\? $query )? )? $fragment_re";  



my $user_re     = "[$uchar_ext]*";
my $password_re = "[$uchar_ext]*";

my $ftype_re    = '(?:\;type=[AIDaid])?';

my $ftpurl      = "ftp:// (?: $user_re (?: \: $password_re )? \@ )? $hostport " 
    .    " (?:/ $fpath )? $ftype_re $fragment_re"; 



sub is_valid {
  my $self = shift;
  my $url = $self->value or return;

  if ( length ($self -> value) > 400 ) {
    return undef;
  }

  if ($url =~ /\-\ [^\ \n]/ ) {
    #         error ( "A whitespace character in an URL after a dash" ) ; 
    return undef;
  }
  $url =~ s/\s+|\n+//g;
  
  
  $url =~ s/^URL://i;
  
  $url =~ s/^Ftp/ftp/i;
  $url =~ s/^Http/http/i;
  
  if ( $url =~ /^
        (?: $httpurl 
         | $ftpurl 
         |
         gopher\/\/ (?: $user_re (?: \: $password_re )? \@ )? $hostport
         (?:\/
          (?:[^\=\;\#\?\:\ \{\}\|\[\]\\\^\<\>]+)?
          (?:\?[^\;\#\?\:\ \{\}\|\[\]\\\^\~\<\>]*)?
          (?:\#[^\;\#\?\:\ \{\}\|\[\]\\\^\~\<\>]*)?
          )? 
         )$/xo
        ) { return $url; }
    else { return undef; }

}

1;
