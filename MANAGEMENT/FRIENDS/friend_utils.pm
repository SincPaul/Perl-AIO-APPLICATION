package friend_utils;

use JSON;

sub get_all_friends {
    my $uuid = session::get_uuid();
    #my $session_id = session::get_session_id();

    my $get_friend_list_uuids_message_json = server_client_connection_messages::get_friend_list_uuids($uuid, "123");

    my $server = server_connections::get_server();

    if ($server) {
        print $server "$get_friend_list_uuids_message_json\n";

        my $response = read_server_response($server);

        if ($response) {
            my $server_message = decode_json($response);
            print "Server message (JSON): " . encode_json($server_message) . "\n";

            # Save the friends list to a JSON file
            my $file = 'MANAGEMENT/FRIENDS/friends_list.json';
            if (-e $file) {
                open my $fh, '>', $file or die "Could not open file '$file': $!";
                print $fh encode_json($server_message);
                close $fh;
                #local $/; 
                #my $json_text = <$fh>;
                #close $fh;
                #$friends_list = decode_json($json_text);
            } else {
                # Create the file if it does not exist
                open my $fh, '>', $file or die "Could not create file '$file': $!";
                print $fh encode_json($friends_list);
                close $fh;
            }

            return $server_message;
        } else {
            print "No response from server\n";
            return 0;
        }
    } else {
        print "Could not connect to server\n";
        server_connections::set_connection_false();
        return 0;
    }
}

sub get_friends_online_status {
    # Read the UUIDs from the previously saved JSON file
    open my $fh, '<', 'MANAGEMENT/FRIENDS/friends_list.json' or die "Could not open file: $!";
    my $json_text = do { local $/; <$fh> };
    close $fh;

    my $friends_list = decode_json($json_text);
    my @friends = @{$friends_list->{friends}};

    print("FRIENDS: $friends\n");

    my $server = server_connections::get_server();

    if ($server) {
        my $get_friends_data = server_client_connection_messages::get_friends_data($uuid, "123", \@friends);

        print $server "$get_friends_data\n";

        my $response = read_server_response($server);

        if ($response) {
            my $server_message = decode_json($response);

            # Save the online status to a new JSON file
            open my $fh_out, '>', '/tmp/friends_online_status.json' or die "Could not open file: $!";
            print $fh_out encode_json($server_message);
            close $fh_out;

            return $server_message;
        } else {
            print "No response from server\n";
            return 0;
        }
    } else {
        print "Could not connect to server\n";
        server_connections::set_connection_false();
        return 0;
    }
}


sub read_server_response {
    my ($server) = @_;
    my $response = '';
    my $selector = IO::Select->new($server);

    if ($selector->can_read(5)) {
        $response = <$server>;
        chomp($response);
        print "Response: $response\n";
        return $response;
    } else {
        print "No response from server\n";
        return;
    }
}


sub add_friend {
    my ($friend_uuid) = @_;

    my $uuid = session::get_uuid();
    my $session_id = session::get_session_id();

    my $add_friend_message = {
        action => "add_friend",
        uuid => $uuid,
        session_id => $session_id,
        friend_uuid => $friend_uuid,
    };

    my $json_message = encode_json($add_friend_message);

    my $server = server_connections::get_server();

    print $server "$json_message\n";

    my $response = '';
    my $selector = IO::Select->new($server);
    if ($selector->can_read(5)) {
        $response = <$server>;
        chomp($response);
        print "Response: $response\n";
    } else {
        print "No response from server\n";
        return 0;
    }

    my $server_message = decode_json($response);

    return $server_message;
}

sub remove_friend {
    my ($friend_username) = @_;

    my $friend_uuid = account_utils::get_uuid_from_username($friend_username);

    my $uuid = session::get_uuid();
    my $session_id = session::get_session_id();

    my $remove_friend_message = {
        action => "remove_friend",
        uuid => $uuid,
        session_id => $session_id,
        friend_uuid => $friend_uuid,
    };

    my $json_message = encode_json($remove_friend_message);

    my $server = server_connections::get_server();

    print $server "$json_message\n";

    my $response = '';
    my $selector = IO::Select->new($server);
    if ($selector->can_read(5)) {
        $response = <$server>;
        chomp($response);
        print "Response: $response\n";
    } else {
        print "No response from server\n";
        return 0;
    }

    my $server_message = decode_json($response);

    return $server_message;
}


1;