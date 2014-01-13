# this is a special module to load all specific modules
# to be used for persistent environments, like PPerl

# external
require Carp::Assert;
require CGI::Cookie;
require CGI::Minimal;
require CGI::Untaint;
require Date::Manip;
require Exporter;
require Storable;
require XML::Parser;
require Proc::Daemon;
require MIME::Base64;
require Bytes::Random::Secure;
require Digest::SHA;

# other components
require ARDB;
require ARDB::Local;
#require RePEc::Index::Reader;
#require RePEc::Index::local_setup;
#require RePEc::Index::UpdateClient;
require sql_helper;

# ACIS
require ACIS::ShortIDs;
require ACIS::Misc;
require ACIS::Web::Admin;
require ACIS::Web::Admin::Events;
require ACIS::Web::Admin::EventsArchiving;
require ACIS::Web::Affiliations;
#require ACIS::Web::ARPM;
require ACIS::Web::Background; # ?
require ACIS::Web::Citations;
require ACIS::Web::Contributions;
require ACIS::Web::Export;
require ACIS::Web::NewUser;
#require ACIS::Web::MetaUpdate;
require ACIS::Web::Person;
require ACIS::Web::SaveProfile;
require ACIS::Web::Services;
require ACIS::Web::Session;
require ACIS::Web::Site;
require ACIS::Web::SysProfile;
require ACIS::Web::User;
require ACIS::Web::UserPassword;
require ACIS::Web::PasswordReset;

# Web::App core
require Web::App::XSLT;
require Web::App::Email;
require Web::App::Common;
require Web::App::Screen;

1;

