package ARDB::RelationType;

# $Id$

use strict;
use warnings;


# Preloaded methods go here.

# constructor

sub new { 
    my $class    = shift;
    my $relation_name = shift;

    # create a structure and bless it:
    my $self = {
      name  => $relation_name,
      views => {},
      reverse_type => undef,
    };
    
    bless $self, $class;
    
    return $self;
    
}

# param must be equal reverse name

sub set_reverse_type {
  my $self         = shift;
  my $reverse_type = shift;

  $self -> {reverse_type} = $reverse_type;
}


# view_name must be equal 'default', 'full', 'brief'...

sub add_view {
  my $self      = shift;
  my $view_name = shift;
  my $retrieve  = shift || die;

  $self -> {views} -> {$view_name} -> {retrieve} = [ split ( /,/, $retrieve ) ];

}

sub set_default_view {
  my $self      = shift;
  my $view_name = shift;

  $self -> {default_view} = $view_name;
}

sub reverse_type {
  my $self = shift;
  return $self->{reverse_type};
}

sub retrieve_list {
  my $self = shift;
  my $view = shift || 'default';

  if ( $self -> {views} -> {$view} )
   { return $self -> {views} -> {$view} -> {retrieve};  }
  elsif ( $self -> {views} -> {default} )
   { return $self -> {views} -> {default} -> {retrieve}; }
  else
   { return []; }
}


sub views_list {
  my $self = shift;
  
  return sort keys %{ $self -> {views} };
}


1;           

__END__

=head1 NAME

ARDB::RelationType - it is about relation classes

=head1 SYNOPSIS

  use ARDB::RelationType;
  blah blah blah

=head1 DESCRIPTION

Each RelationType object describe some class of 
relationships between ARDB records (templates).  

RelationType objects are created by the ARDB::Configuration class.

Each RelationType object must have a unique id.  
That id will be used in the 'relation' field of the 
relations table records. It is a bad idea 
to give relation type an id equal to any existing 
ReDIF attribute.  That's because of the way we going to use
the relation type ids: we may want to use them
as attributes in unfolded templates.  
Another approach may be to stick to a special 
convention on relation type ids: e.g. using Title-Like 
First-Caps case. (?)

A relation type may have several additional properties.  
First is directedness: that is relation directed or undirected.
Undirected relations do not differ between object and subject. 
A simple example is relation "colleague": if you are my colleage
then I'm yours.  A simple example of a directed relationship is 
being someone's parent. If you are my parent, I am your child, 
but certainly not your parent.

If relation is directed, it must specify a reverse counterpart
("child-of" in case of "parent-of").  The counterpart must be a
defined relation type.


=head2 ARDB processing a get_full_template request

Main excuse of relation types existence is to help ARDB interprete
relations data.  Upon a get_full_template() request ARDB will do the
following:

=over 4

=item step 1

Extract the requested template from its primary storage:
Handle-Template Service (HTS).

=item step 2

Look-up the relations table for records, where subject equals the
requested object's handle

=item step 3

Look-up the relations table for records, where object equals the handle

=item step 4

Reverse the relationships where the relation type is directed and
where object eq the handle (fetched at step 3).  
I.e. after this step "A is parent-of B"
will become "B is child-of A", where B is the requested handle.

=item step 5

On this stage ARDB will use the relationships resulted from steps 2
and 4 to build "full" template (another way to name it is "unfolded
template").

To do that, ARDB will use RelationType objects for corresponding 
relations.

Therefore, RelationType object must specify how to express a relation
of that type in a resulting unfolded template.  It is the most
interesting part with several possible outcomes.

Some relations will be represented by including the corresponding
(related) object into an attribute of unfolded template.  The object
can be fetched from primary storage (HTS).  The attribute name will be
made from the relation name.  If the relationship is "B is child-of
A", then the "child-of" attribute can be created in unfolded template
B and will include whole template A. (e.g. C<$B-E<gt>{'child-of'} = [ $A
]>). It is the first way to express a relation.

Another way to express a relation is to fetch no data about the
related object, but simply store its handle in the requested full
template.  C<$B-E<gt>{'child-of'} = [ 'A' ];>

Third basic way is to not express the relationship.  Ignore it.

Although the listed ways would cover many cases, many more would
require special processing.  For instance, the system may need to
extract only certain fields from the related template and include them
into a specially built pseudo-template hash.

Another option is to run custom-written user-provided perl code for
that relation.  The code then will be passed a reference to the full
template being built and the related object and the relation data.  It
will be responsible for expressing the relationship.

=item step 6

The previous step should result in building the unfolded template
object.  Now ARDB will return its reference to the application.

=back


=head2 Views

To give different applications power to control the way they get the
unfolded templates, we introduce a notion of view.

A view is a set of rules about the ways by which different relation
types are expressed in unfolded templates.

Optionally, an application requesting a full object from ARDB may
specify its desired view.  I<(???: or an ordered list of views to fall
back to in case of the preferred view being absent in a relation
type?)>.  Each relation type will define some default representation
and may define any number of alternative representations, designated
by the view name.  If the get_full_template() request had a view
preference, that view will be used whenever possible on step 5 of
request processing.






A relation type defined must provide some clues about how to process 
a relation upon a get_full_template() request.  A list of "retrieve" items 
will do the main job. 



Another kind of thing we need ser-provided code must 


have some clues about how to process a relation on the 




=head1 AUTHOR

Ivan Baktcheev and Ivan Kurmanov

=head1 SEE ALSO

=cut
