package friend_utils;

use Tk::LabFrame;
use JSON;

sub get_friends_list_uuids {
    my $server = server_connections::get_server();

    if ($server) {
        my $get_friend_list_uuids_message_json = server_client_connection_messages::get_friend_list_uuids();
        print $server "$get_friend_list_uuids_message_json\n";

        my $response = read_server_response($server);

        if ($response) {
            my $server_message = decode_json($response);
            print "Server message (JSON): " . encode_json($server_message) . "\n";

            my $file = 'MANAGEMENT/FRIENDS/friends_list.json';
            my $friends_uuids = { friends_only_uuids => $server_message->{friends_uuids} };

            open my $fh, '>', $file or die "Could not open file '$file': $!";
            print $fh encode_json($friends_uuids);
            close $fh;

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
    open my $fh, '<', 'MANAGEMENT/FRIENDS/friends_list.json' or die "Could not open file: $!";
    my $json_text = do { local $/; <$fh> };
    close $fh;

    my $friends_list = decode_json($json_text);
    my @friends = @{$friends_list->{friends_only_uuids}};

    foreach my $friend (@friends) {
        print("UUID: $friend\n");
    }

    my $server = server_connections::get_server();
    my $uuid = session::get_uuid();
    my $session_id = session::get_session_id();

    if ($server) {
        my $get_friends_data = server_client_connection_messages::get_friends_data($uuid, $session_id, \@friends);

        print $server "$get_friends_data\n";

        my $response = read_server_response($server);

        if ($response) {
            my $server_message = decode_json($response);

            my %friends_status;
            foreach my $friend (@{$server_message->{friends}}) {
                $friends_status{$friend->{uuid}} = {
                    username => $friend->{username},
                    displayname => $friend->{displayname},
                    nickname => $friend->{nickname},
                    status => $friend->{status},
                    uuid => $friend->{uuid}
                };
            }

            my $friends_status = {
                friends_only_uuids => \@friends,
                friends_complete_data => \%friends_status
            };

            open my $fh_out, '>', 'MANAGEMENT/FRIENDS/friends_list.json' or die "Could not open file: $!";
            print $fh_out encode_json($friends_status);
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

sub display_friend_list {
    my ($main) = @_;

    my $friend_list_overlay = $main->Toplevel();
    $friend_list_overlay->title("SINC Perl - Friends");
    $friend_list_overlay->geometry("350x300");
    
    my $ordered_friends_ref = sort_friend_list();

    my $online_frame = $friend_list_overlay->LabFrame(
        -label => "Online Friends",
        -labelside => 'acrosstop',
        -bg => 'lightgreen'
    )->pack(-side => 'top', -fill => 'both', -expand => 1, -pady => 5);

    my $offline_frame = $friend_list_overlay->LabFrame(
        -label => "Offline Friends",
        -labelside => 'acrosstop',
        -bg => 'lightyellow'
    )->pack(-side => 'top', -fill => 'both', -expand => 1, -pady => 5);

    my $error_frame = $friend_list_overlay->LabFrame(
        -label => "Error Friends",
        -labelside => 'acrosstop',
        -bg => 'lightcoral'
    )->pack(-side => 'top', -fill => 'both', -expand => 1, -pady => 5);


    foreach my $friend (@$ordered_friends_ref) {
        my $status = $friend->{status};
        my $username = $friend->{username};
        my $display_name = $friend->{display_name};
        my $nickname = $friend->{nickname};
        my $uuid = $friend->{uuid};
        my $display_text = "NAME: $username, STATUS: $status";

        my $button = $friend_list_overlay->Button(
            -text => $display_text,
            -command => sub { 
                print "Clicked on $nickname, $uuid\n", 
                open_friend_manage_menu($uuid, $friend_list_overlay, $username, $display_name, $nickname),
                },
            -bg => ($status eq 'online') ? 'green' : ($status eq 'offline') ? 'yellow' : 'red',
            -fg => 'black',
            -relief => 'flat'
        );

        if ($status eq 'online') {
            $button->pack(-in => $online_frame, -side => 'top', -fill => 'x', -padx => 5, -pady => 2);
        } elsif ($status eq 'offline') {
            $button->pack(-in => $offline_frame, -side => 'top', -fill => 'x', -padx => 5, -pady => 2);
        } else {
            $button->pack(-in => $error_frame, -side => 'top', -fill => 'x', -padx => 5, -pady => 2);
        }
    }

}

sub open_friend_manage_menu {
    my ($uuid, $friend_list_overlay, $username, $display_name, $nickname) = @_;

    my $user_mangement_overlay = $friend_list_overlay->Toplevel();
    $user_mangement_overlay->title("SINC Perl - Friend Management");
    $user_mangement_overlay->geometry("350x300");

    my $label = $user_mangement_overlay->Label(
        -text => "Friend Management: \n$nickname",
        -font => ['DejaVu Serif', 14, 'bold'],
        -background => 'lightblue',
        -foreground => 'black',
        -borderwidth => 2,
        -relief => 'raised',
        -width => 40
    )->pack(
        -padx => 10,
        -pady => 10,
        -fill => 'x'
    );

    my $sent_message_button = $user_mangement_overlay->Button(
        -text => "Sent Message",
        -font => ['DejaVu Serif', 12],
        -background => 'lightgreen',
        -foreground => 'black',
        -command => sub { sent_message($uuid) },
    )->pack(
        -padx => 10,
        -pady => 10,
        -fill => 'x'
    );

    my $change_nickname_button = $user_mangement_overlay->Button(
        -text => "Change Nickname",
        -font => ['DejaVu Serif', 12],
        -background => 'lightgreen',
        -foreground => 'black',
        -command => sub { change_nickname($uuid, $friend_list_overlay, $user_mangement_overlay, $username, $display_name, $nickname) },
    )->pack(
        -padx => 10,
        -pady => 10,
        -fill => 'x'
    );

    my $play_game_button = $user_mangement_overlay->Button(
        -text => "Play Game",
        -font => ['DejaVu Serif', 12],
        -background => 'lightgreen',
        -foreground => 'black',
        -command => sub { play_game($uuid) },
    )->pack(
        -padx => 10,
        -pady => 10,
        -fill => 'x'
    );

    my $remove_friend_button = $user_mangement_overlay->Button(
        -text => "Remove Friend",
        -font => ['DejaVu Serif', 12],
        -background => 'lightgreen',
        -foreground => 'black',
        -command => sub { remove_friend($uuid) },
    )->pack(
        -padx => 10,
        -pady => 10,
        -fill => 'x'
    );

}

sub change_nickname {
    my ($friend_uuid, $friend_list_overlay, $user_mangement_overlay, $username, $display_name, $nickname) = @_;

    if ($user_mangement_overlay) {
        $user_mangement_overlay->destroy();
    }

    my $change_nickname_overlay = $friend_list_overlay->Toplevel();
    $change_nickname_overlay->title("SINC Perl - Change Nickname");
    $change_nickname_overlay->geometry("350x300");
    my $label = $change_nickname_overlay->Label(
        -text => "Change Nickname",
        -font => ['DejaVu Serif', 14, 'bold'],
        -background => 'lightblue',
        -foreground => 'black',
        -borderwidth => 2,
        -relief => 'raised',
        -width => 40
    )->pack(
        -padx => 10,
        -pady => 10,
        -fill => 'x'
    );

    my $change_nickname_input = $change_nickname_overlay->Entry(
        -font => ['DejaVu Serif', 12],
        -background => 'lightgreen',
        -foreground => 'black',
    )->pack(
        -padx => 10,
        -pady => 10,
        -fill => 'x'
    );

    my $change_nickname_button = $change_nickname_overlay->Button(
        -text => "Change Nickname",
        -font => ['DejaVu Serif', 12],
        -background => 'lightgreen',
        -foreground => 'black',
        -command => sub { 
            sent_nickname_change_to_server();
        },
    )->pack(
        -padx => 10,
        -pady => 10,
        -fill => 'x'
    );

    my $return_button = $change_nickname_overlay->Button(
        -text => "Return",
        -font => ['DejaVu Serif', 12],
        -background => 'lightgreen',
        -foreground => 'black',
        -command => sub { 
            $change_nickname_overlay->destroy(); 
            open_friend_manage_menu($uuid, $friend_list_overlay, $username, $display_name, $nickname)    
        },
    )->pack(
        -padx => 10,
        -pady => 10,
        -fill => 'x'
    )

    
}

sub sort_friend_list {
    open my $fh, '<', 'MANAGEMENT/FRIENDS/friends_list.json' or die "Could not open file: $!";
    my $json_text = do { local $/; <$fh> };
    close $fh;

    my $friends_list = decode_json($json_text);

    foreach my $uuid (keys %{$friends_list->{friends_complete_data}}) {
        my $friend = $friends_list->{friends_complete_data}{$uuid};
        if ($friend->{status} eq 'online') {
            push @online_friends, $friend;
        } elsif ($friend->{status} eq 'offline') {
            push @offline_friends, $friend;
        } else {
            push @error_friends, $friend;
        }
    }

    @online_friends = sort { lc($a->{name}) cmp lc($b->{name}) } @online_friends;
    @offline_friends = sort { lc($a->{name}) cmp lc($b->{name}) } @offline_friends;
    @error_friends = sort { lc($a->{name}) cmp lc($b->{name}) } @error_friends;

    my @ordered_friends;
    push @ordered_friends, @online_friends, @offline_friends, @error_friends;

    # Print the sorted friends
    
    return \@ordered_friends;
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