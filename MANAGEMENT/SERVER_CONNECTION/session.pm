package session;

my $UUID;


sub set_uuid {
    my ($creation_uuid) = @_;
    $UUID = $creation_uuid;
    print("UUID V1: $UUID\n");
    return;
}


sub get_uuid {
    if (!defined $UUID) {
        print("HACKA ALLART");
        return undef;
    }
    print("UUID: $UUID\n");
    return $UUID;
}

1;