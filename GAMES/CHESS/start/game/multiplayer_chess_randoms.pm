package multiplayer_chess_randoms;

use MANAGEMENT::SERVER_CONNECTION::session;
use MANAGEMENT::SERVER_CONNECTION::server_connections;



#my $session_id = session::get_session_id();


sub start {
    my $uuid = session::get_uuid();
    my $server = server_connections::get_server();

    my $data = {
        action     => "joinChessQueue",
        uuid       => $uuid,
        session_id => $session_id,
    };

    if (server_connections::check_connection()) {
        

            (sub {
            my ($response) = @_;
            if ($response->{status} eq 'success') {
                print "Successfully joined the chess queue.\n";

                $server->on_response(sub {
                    my ($new_response) = @_;
                    if ($new_response->{status} eq 'foundOpponent') {
                        print "Opponent found! Starting game...\n";
                        print "Game ID: " . $new_response->{game_id} . "\n";
                        print "Opponent ELO: " . $new_response->{opponent_elo} . "\n";
                        print "Opponent Display Name: " . $new_response->{opponent_displayname} . "\n";
                        print "Play Color: " . $new_response->{play_color} . "\n";
                        start_game();
                    } else {
                        warn "Unexpected response from server while waiting for opponent.\n";
                    }
                });

            } elsif ($response->{status} eq 'error') {
                warn "Error joining chess queue: " . $response->{error_msg} . "\n";
            } else {
                warn "Unexpected response from server.\n";
            }
        });
    } else {
        $server = undef;
        server_connections::set_connection_false();
        warn "Server is not connected. Cannot send data.";
    }
}


sub start_game {

}

1;