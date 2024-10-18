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

my @friends = ('uuid1', 'uuid2', 'uuid3', 'uuid4');

my %uuid1 = (
    'name' => 'Alice',
    'status' => 'online',
);
my %uuid2 = (
    'name' => 'Bob',
    'status' => 'offline',
);
my %uuid3 = (
    'name' => 'Charlie',
    'status' => 'online',
);
my %uuid4 = (
    'name' => 'David',
    'status' => 'offline',
);

while (1) {
    my @ready = $select->can_read(0.5);

    foreach my $sock (@ready) {
        if ($sock == $server) {
            my $client = $server->accept or die "Couldn't accept client connection: $!\n";
            $select->add($client);
        } else {
            my $data = '';
            $sock->recv($data, 1024);
            if ($data) {
                my $json = decode_json($data);
                if ($json->{action} && $json->{action} eq 'register') {
                    my $response = { status => 'success', message => 'Registered successfully' };
                    $sock->send(encode_json($response) . "\n");
                } elsif ($json->{action} && $json->{action} eq 'login') {
                    my $response = { status => 'success', message => 'Logged in successfully' };
                    $sock->send(encode_json($response)."\n");
                } elsif ($json->{action} && $json->{action} eq 'get_friend_list_uuids') {
                    print("TEST1");
                    my $response = { status => 'success', friends => \@friends };
                    $sock->send(encode_json($response)."\n");
                } elsif ($json->{action} && $json->{action} eq 'get_friends_data') {
                    print("TEST1");
                    
                    my @requested_uuids = @{$json->{friends_uuids}};
                    my @friends_data;
                    
                    foreach my $uuid (@requested_uuids) {
                        if ($uuid eq 'uuid1') {
                            push @friends_data, { uuid => $uuid, %uuid1 };
                        } elsif ($uuid eq 'uuid2') {
                            push @friends_data, { uuid => $uuid, %uuid2 };
                        } elsif ($uuid eq 'uuid3') {
                            push @friends_data, { uuid => $uuid, %uuid3 };
                        } elsif ($uuid eq 'uuid4') {
                            push @friends_data, { uuid => $uuid, %uuid4 };
                        } else {
                            push @friends_data, { uuid => $uuid, status => 'unknown' };
                        }
                    }
                    print("FRIENDS DATA: " . encode_json(\@friends_data) . "\n");
                    my $response = { status => 'success', friends => \@friends_data };
                    $sock->send(encode_json($response)."\n");
                }
                else {
                    print("JSON:  $json->{action}\n");

                    my $response = { status => 'error', message => "Invalid action ", $json->{action},"\n" };
                    $sock->send(encode_json($response)."\n");
                }
            } else {
                print "Client disconnected\n";
                $select->remove($sock);
                $sock->close();
            }
        }
    }
}