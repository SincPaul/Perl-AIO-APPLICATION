use strict;
use warnings;
use IO::Socket::INET;
use IO::Select;
use JSON;

$| = 1;

my $server_ip = 'localhost';
my $server_port = 12345;

my $server = IO::Socket::INET->new(
    LocalHost => $server_ip,
    LocalPort => $server_port,
    Proto     => 'tcp',
    Listen    => 5,
    Reuse     => 1
) or die "Couldn't create server on port $server_port: $!\n";

print "Server waiting for client connection on port $server_port\n";

my $select = IO::Select->new($server);

my @friends = ('uuid1', 'uuid2', 'uuid3', 'uuid4', 'uuid5');

my %uuid_data = (
    'uuid1' => { uuid => 'uuid1', username => 'Friend 1', displayname => 'Friend1.1', nickname => 'Friend1.2', status => 'online' },
    'uuid2' => { uuid => 'uuid2', username => 'Friend 2', displayname => 'Friend1.1', nickname => 'Friend1.2', status => 'offline' },
    'uuid3' => { uuid => 'uuid3', username => 'Friend 3', displayname => 'Friend1.1', nickname => 'Friend1.2', status => 'online' },
    'uuid4' => { uuid => 'uuid4', username => 'Friend 4', displayname => 'Friend1.1', nickname => 'Friend1.2', status => 'offline' },
);

while (1) {
    my @ready = $select->can_read(0.5);

    foreach my $sock (@ready) {
        if ($sock == $server) {
            my $client = $server->accept or die "Couldn't accept client connection: $!\n";
            $select->add($client);
            my $peer_address = $client->peerhost();
            my $peer_port = $client->peerport();
            print "Client connected: $peer_address:$peer_port\n";
        } else {
            my $data = '';
            $sock->recv($data, 1024);
            if ($data) {
                my $json = decode_json($data);
                if ($json->{action} && $json->{action} eq 'register') {

                    my $response = { status => 'success', uuid => get_uuid(), session_id => get_session_id(), message => 'Registered successfully' };
                    $sock->send(encode_json($response) . "\n");

                } elsif ($json->{action} && $json->{action} eq 'login') {

                    my $response = { status => 'success', uuid => get_uuid(), session_id => get_session_id(), message => 'Logged in successfully' };
                    $sock->send(encode_json($response)."\n");

                } elsif ($json->{action} && $json->{action} eq 'get_friend_list_uuids') {

                    print("TEST1");
                    my $response = { status => 'success', friends_uuids => \@friends };
                    $sock->send(encode_json($response)."\n");

                } elsif ($json->{action} && $json->{action} eq 'get_friends_data') {
                    print("Received get_friends_data action\n");
                    print("JSON Data: " . encode_json($json) . "\n");

                    my @requested_uuids = @{$json->{friends_uuids}->[0]};
                    print("Requested UUIDs: @requested_uuids\n");
                    my @friends_data;

                    foreach my $uuid (@requested_uuids) {
                        print("UUID: $uuid\n");
                        if (exists $uuid_data{$uuid}) {
                            push @friends_data, $uuid_data{$uuid};
                        } else {
                            my $error_data = { uuid => $uuid, nickname => $uuid, status => 'failed loading data' };
                            push @friends_data, $error_data;
                        }
                    }

                    my $response = { status => 'success', friends => \@friends_data };
                    $sock->send(encode_json($response)."\n");
                }
                else {
                    print("JSON:  $json->{action}\n");

                    my $response = { status => 'error', message => "Invalid action ", $json->{action},"\n" };
                    $sock->send(encode_json($response)."\n");
                }
            } else {
                my $peer_address = $sock->peerhost();
                my $peer_port = $sock->peerport();
                print "Client disconnected: $peer_address:$peer_port\n";
                $select->remove($sock);
                $sock->close();
            }
        }
    }
}

sub get_uuid {
    return time;
}

sub get_session_id {
    return time/2;
}