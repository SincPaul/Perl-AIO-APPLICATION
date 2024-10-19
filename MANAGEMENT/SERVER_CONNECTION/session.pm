package session;

my $UUID;
my $SESSION_ID;

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

sub get_session_id {
    if (!defined $SESSION_ID) {
        print("HACKA ALLART V2");
        return undef;
    }

    return $SESSION_ID;
}

sub set_session_id {
    my ($active_session_id) = @_;

    $SESSION_ID = $active_session_id;
    return;
}
1;