package server_client_connection_messages;

use JSON;

sub get_register_message {
    my ($username, $password_hash) = @_;

    my $register_message = {
        action   => "register",
        username => $username,
        hashed_pw => $password_hash,
    };

    my $json_message = encode_json($register_message);
    
    return $json_message;
}

sub get_friend_list_uuids {
    my ($uuid, $session_id) = @_;

    my $friend_list_uuids = {
        action => "get_friend_list_uuids",
        uuid => $uuid,
        session_id => $session_id,
    };

    my $json_message = encode_json($friend_list_uuids);

    return $json_message;
}

sub get_friends_data {
    my ($uuid, $session_id) = @_;

    my $friends_data = {
        action => "get_friends_data",
        uuid => $uuid,
        session_id => $session_id,
        friends_uuids => \@friends_uuids,
    };

    my $json_message = encode_json($friends_data);

    return $json_message;
}
1;
