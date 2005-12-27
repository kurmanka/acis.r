package ARDB::Record::ReDIF;


use ReDIF::Record;


use base 'ReDIF::Record';

# this is an implementation of ARDB::Record API for ReDIF templates


# sub id inherited from ReDIF::Record

# sub type inherited from ReDIF::Record


sub view {
  my $self = shift;
  return $self->{VIEW};
}

sub set_view {
  my $self = shift;
  $self->{VIEW} = shift;
}


# sub get_value inherited from ReDIF::Record


sub add_relationship {
  my $self = shift;

  my $relationship = shift;
  my @things = @_;

  $self->add_property( $relationship . "_rel", @things );

}

1;
