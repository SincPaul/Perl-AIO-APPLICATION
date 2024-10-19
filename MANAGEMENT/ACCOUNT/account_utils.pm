package account_utils;


use JSON;

my $main;

sub register {
    my ($username, $password, $register_frame, $main_frame) = @_;

    if ($register_frame) {
        $register_frame->destroy();
    }

    my $password_hash = crypt($password, "salt");

    if (server_connections::connect_to_server()) {
        print "Connected to server\n";
        server_connections::set_connection_true();

        my $get_register_message_json = server_client_connection_messages::get_register_message($username, $password_hash);

        my $server = server_connections::get_server();
        if (!$server) {
            print "Could not connect to server\n";
            return 0;
        }

        print $server "$get_register_message_json\n";

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
        if ($server_message->{status} eq 'success') {
            my $uuid = $server_message->{uuid};
            session::set_uuid($uuid);

            my $session_id = $server_message->{session_id};
            session::set_session_id($session_id);

            my $file = "MANAGEMENT/ACCOUNT/accounts.json";
            my $accounts = {};

            if (-e $file) {
                open my $fh, '<', $file or die "Could not open file '$file' $!";
                local $/;
                my $json_text = <$fh>;
                close $fh;
                $accounts = decode_json($json_text);
            }

            $accounts->{$uuid} = {
                username => $username,
                password => $password_hash,
                display_name => $username,
            };

            open my $fh, '>', $file or die "Could not open file '$file' $!";
            print $fh encode_json($accounts);
            close $fh;

            return 1;
        } else {
            print "Registration failed: $server_message->{error}\n";
            return 0;
        }
    } else {
        print "Could not connect to server\n";
        server_connections::set_connection_false();
        return 0;
    }
}

sub login {
    my ($username, $password) = @_;

    my $password_hash = crypt($password, "salt");

    if (server_connections::connect_to_server()) {
        print "Connected to server\n";
        server_connections::set_connection_true();

        my $get_login_message_json = server_client_connection_messages::get_login_message($username, $password_hash);

        my $server = server_connections::get_server();

        if (!$server) {
            print "Could not connect to server\n";
            return 0;
        }

        print $server "$get_login_message_json\n";

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

        if ($server_message->{status} eq 'success') {
            my $uuid = $server_message->{uuid};
            session::set_uuid($uuid);

            my $session_id = $server_message->{session_id};
            session::set_session_id($session_id);

            return 1;
        } else {
            print "Login failed: $server_message->{error}\n";
            return 0;
        }
    } else {
        print "Could not connect to server\n";
        server_connections::set_connection_false();
        return 0;
    }

    return 0;
}

sub change_password {
    my ($new_password) = @_;

    my $uuid = session::get_uuid();

    my $file = "GAMES/ACCOUNT/accounts.json";

    open my $fh, '<', $file or die "Could not open file '$file' $!";
    local $/; # Enable 'slurp' mode
    my $json_text = <$fh>;
    close $fh;

    my $accounts = decode_json($json_text);

    $accounts->{$uuid}->{password} = $new_password;

    open my $fh, '>', $file or die "Could not open file '$file' $!";
    print $fh encode_json($accounts);
    close $fh;
}

sub get_username {
    my ($uuid) = @_;

    my $file = "GAMES/ACCOUNT/accounts.json";

    open my $fh, '<', $file or die "Could not open file '$file' $!";
    local $/; # Enable 'slurp' mode
    my $json_text = <$fh>;
    close $fh;

    my $accounts = decode_json($json_text);

    return $accounts->{$uuid}->{username};
}

sub get_display_name {
    my ($uuid) = @_;

    my $file = "GAMES/ACCOUNT/accounts.json";

    open my $fh, '<', $file or die "Could not open file '$file' $!";
    local $/; # Enable 'slurp' mode
    my $json_text = <$fh>;
    close $fh;

    my $accounts = decode_json($json_text);

    return $accounts->{$uuid}->{display_name};
}

sub change_display_name {
    my ($new_display_name) = @_;

    my $uuid = session::get_uuid();

    my $file = "GAMES/ACCOUNT/accounts.json";

    open my $fh, '<', $file or die "Could not open file '$file' $!";
    local $/; # Enable 'slurp' mode
    my $json_text = <$fh>;
    close $fh;

    my $accounts = decode_json($json_text);

    $accounts->{$uuid}->{display_name} = $new_display_name;

    open my $fh, '>', $file or die "Could not open file '$file' $!";
    print $fh encode_json($accounts);
    close $fh;
    
}

sub delete_account {
}

sub get_uuid_from_username {
    my ($username) = @_;

    return "STHIDONTHAVEITYET";
}
1;