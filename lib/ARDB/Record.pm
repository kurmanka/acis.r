package ARDB::Record;

# this is a module to document an interface to metadata objects that
# ARDB will work with.  This interface may be implemented by many
# different classes, not necessarily inheriting from ARDB::Record, but
# here is what they must implement.


=pod 

=head1 NAME

ARDB::Record - an abstract class for metadata objects, that ARDB can store and process

=head1 SYNOPSIS

  # create an object
  my $object = ARDB::Record::Something -> new( 'identifier', 'type' );

  # basic object metadata
  my $id   = $object->id;
  my $type = $object->type;

  # getting values
  my $title  = $object->get_value( 'title' );
  my @titles = $object->get_value( 'title' );

  # getting values burried deep by a path value
  my @au_names = $object->get_value( 'author/name' );

  # telling the object about a relationship it is involved with

  $object -> add_relationship( $name, $other_obj );

=head1 DESCRIPTION

ARDB can deal with many different kinds of metadata.  To be that
flexible it needs a common interface to each piece.  This module
defines (describes) that interface.

It is assumed, that ARDB::Record objects represent an actual metadata
record, that was stored in ARDB and will be retrieved from ARDB in an
enriched form.

This interface is pretty simple, so you should be able to implement it
easily for whatever kind of metadata you have.

Basically, we (ARDB) expect a record object to implement several
methods, listed below.  We expect record objects to be given to us
already created, so it doesn't include a constuctor method, although
it is mentioned in Synopsis above.

=head2 METHODS

=over 4

=item -> id;

Return the unique identifier of the object.

=item -> type;

Return the metadata record type of the object.

=item -> get_value( PROPERTY_SPECIFICATION, ... );

Return a list of values of metadata properties that conform to the
given PROPERTY_SPECIFICATIONs.

=item -> set_view( VIEW ) ;

=item -> view ;

=item -> add_relationship( RELATIONSHIP_NAME, RELATED_THING_1, RELATED_THING_2, ... );

Notify a record about things which are in a relation with it. 

=item -> get_relationship( RELATIONSHIP_NAME );

Return a list of values of things that this metadata record is related to.

=back

=head2 LIFETIME OF AN OBJECT

The expected lifetime of an ARDB::Record-implementing object is very
long.  It will be stored into a database in its entirety and will be
restored from the database after a while.  First happens when there is
a put_record() call to an ARDB object.  Second happens when there is a
get_unfolded_record() call to ARDB object.

Upon resurrecting an object from the database we have to ensure that
it can function properly, which is not always easy because an object
may depend on some perl modules to work properly.

ARDB::ObjectDB will ensure that the module which corresponds to the
object blessed class name will be loaded, when an object is retrieved
from the database.  If your object requires other modules, don't
forget to load them in your ARDB::Record-implementing class' module.

=head1 SEE ALSO

ARDB, ARDB::ObjectDB

=cut





sub id {
  my $self = shift;
}

sub type {
  my $self = shift;
}

sub get_value {
  my $self = shift;
}

sub add_relationship {
  my $self = shift;
}

sub view {
  my $self = shift;

}

sub set_view {
  my $self = shift;
}



1;
