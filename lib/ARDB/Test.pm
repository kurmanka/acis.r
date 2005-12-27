package main;

# some small testing framework

###############################################################
#############     TESTING   FRAMEWORK     #####################
###############################################################

sub test ($;$)  {
    push @TESTS, shift;
    push @MESSAGES, shift;
}

sub ok { 
    push @TESTS, 1; 
    push @MESSAGES, shift;
}
sub nok { 
    push @TESTS, 0; 
    push @MESSAGES, shift;
}



END { 

    my $tests = scalar @TESTS;

    if( not $tests ) {
        print "1..1\nnot ok 1\n";
        exit;
    }

    print "1..$tests\n";

    my $counter = 1;
    while ( 1 ) {
        my $t = shift @TESTS;
        my $m = shift @MESSAGES;
        if( not $t ) {
            print "not ";
        }
        print "ok $counter\n";

        if( $m ) { 
            print "[$counter] $m\n";
        }
        last if not scalar @TESTS;
        $counter ++;
    }
}



1;

__END__

