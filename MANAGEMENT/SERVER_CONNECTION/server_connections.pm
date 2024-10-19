package server_connections;

use IO::Socket::INET;
use IO::Select;
use JSON qw(encode_json);

my $server;
my $server_ip = 'localhost';
my $server_port = 12345;

my ($mw, $select, $start_time, $label);

my $connection_status_file = "MANAGEMENT/SERVER_CONNECTION/connection.json";

sub connect_to_server {
    #my $server_ip = '217.248.106.198'; 
    #my $server_port = 12345;

    create_connection_frame();

    

    my $socket = IO::Socket::INET->new(
        PeerAddr => $server_ip,
        PeerPort => $server_port,
        Proto    => 'tcp',
        Blocking => 0
    );

    print($mw);

    if (!$socket) {
        print "Could not connect to server at $server_ip:$server_port $!\n";
        $mw->destroy();
        return 0;
    } 

    

    $start_time = time();
    $select = IO::Select->new($socket);
    my $connected = check_connection($select);
    if ($connected) {
        $server = $socket;
        return 1;
    }
    #$main->after(100, sub { check_connection($select); });
}

sub create_connection_frame {
    $mw = MainWindow->new;
    $mw->title("Establishing Connection");
    print("TEST");

    $frame = $mw->Frame()->pack();

    $label = $frame->Label(
        -text => "Trying to connect to server at $server_ip:$server_port",
        -font => ['Arial', 14]
    )->pack();

    $mw->update;  
}

sub check_connection {  
    create_connection_frame();

    my $elapsed_time = time() - $start_time;
    my $timeout = 5;

    if ($select->can_write(0.1)) {
        set_connection_true();
        print("LOL");
        $label->configure(-text => "Connected to server at $server_ip:$server_port");
        $mw->destroy();
        return 1;  
    }

    if ($elapsed_time > $timeout) {
        set_connection_false();
        print("NOPE");
        $label->configure(-text => "Could not connect to server at $server_ip:$server_port\n Try again later");
        return;  
    }


    $mw->after(100, \&check_connection);
}
sub set_connection_true {
    open my $fh, '>', $connection_status_file or die "Could not open connection_status_file '$connection_status_file' $!";
    print $fh encode_json({connected => 1});
    close $fh;
}

sub set_connection_false {
    open my $fh, '>', $connection_status_file or die "Could not open connection_status_file '$connection_status_file' $!";
    print $fh encode_json({connected => 0});
    close $fh;
}

sub get_connection_status {
    open my $fh, '<', $connection_status_file or die "Could not open connection_status_file '$connection_status_file' $!";
    my $json_text = <$fh>;
    close $fh;
    my $connection_status = decode_json($json_text);
    return $connection_status->{connected};

}
sub get_server {
    return $server if $server;
}

1;