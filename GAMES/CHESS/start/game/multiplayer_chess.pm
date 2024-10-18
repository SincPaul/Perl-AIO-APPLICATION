package multiplayer_chess;

use strict;
use warnings;
use IO::Socket;
use Tk;
use Tk::Event;

my $black_socket;
my $white_socket;

my $server_color;
my $client_name;
my $server_name;



sub start {
    my ($choose_mode, $frame) = @_;

    

    my $mode = 'Multiplayer';
    
    my $connect_frame = $frame->Toplevel();
    $connect_frame->geometry("380x380+500+500");
    $connect_frame->title("Connect to Server");

    $choose_mode->destroy();

    my $label = $connect_frame->Label(
        -text => "Host or connect to server",
        -font => ['Arial', 14]
    )->pack();

    my ($host, $port) = get_host_and_port($connect_frame);
    #my $host = '10.31.0.66';
    #my $host = 'localhost';
    #my $port = 8888;
    my $socket;

    $socket = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => "tcp",
        Type     => SOCK_STREAM,
    );
    
    if ($socket) {
        $connect_frame->geometry("+1500+0");
        $label->configure(-text => "Connected to server on port $port");
        $client_name = "HANS";#get_name($frame);
        print("Client Name: $client_name\n");

        my $server_color = <$socket>;
        chomp($server_color);
        print("Server Color: $server_color\n");
        

        print $socket "$client_name\n";

        $server_name = <$socket>;
        chomp($server_name);
        print("Server Name: $server_name\n");

        my $client_color = $server_color eq 'black' ? 'white' : 'black';
        my $theme = 'default';
        utils::set_socket($socket, $client_color, $client_name, $server_name, 1, $theme);

        utils::create_chess_board($connect_frame, $mode);
        #$connect_frame->destroy();
    } else {
        eval {
            my $server = IO::Socket::INET->new(
                LocalAddr => 'localhost',
                LocalPort => $port,
                Proto     => 'tcp',
                Listen    => 5,
                Reuse     => 1
            ) or die "Could not create server socket: $!";

            $server->blocking(0); 

            $connect_frame->geometry("+1100+0");
            $connect_frame->repeat(100, sub {
                if (my $client = $server->accept()) {
                    my $client_address = $client->peerhost();
                    my $client_port    = $client->peerport();

                    print "Client connected from $client_address:$client_port\n";
                    $label->configure(-text => "Client connected from $client_address:$client_port");

                    $server_name = "HERBERT";#get_name($frame);
                    $server_color = 'white';#get_starting_color($frame);

                    print $client "$server_color\n";

                    $client_name = <$client>;
                    chomp($client_name);
                    print("Client Name: $client_name\n");

                    print $client "$server_name\n";

                    my $theme = 'halloween';
                    utils::set_socket($client, $server_color, $client_name, $server_name, 0, $theme);
                    utils::create_chess_board($connect_frame, $mode);
                    #$connect_frame->destroy();
                }
            });

            print "Server listening on port $port...\n";
            $label->configure(-text => "Hosting server on port $port");
        };
    }
}

sub get_name {
    my ($frame) = @_;

    my $name_frame = $frame->Toplevel();
    $name_frame->geometry("380x380+900+500");
    $name_frame->title("Enter Name");
    $name_frame->attributes(-topmost => 1);

    my $name_var = '';

    $name_frame->Label(
        -text => "Enter your name",
        -font => ['Arial', 14]
    )->pack();

    $name_frame->Entry(
        -textvariable => \$name_var,
        -font => ['Arial', 14]
    )->pack();

    my $name_selected;

    $name_frame->Button(
        -text    => "Submit",
        -font    => ['Arial', 14],
        -command => sub {
            $name_selected = $name_var;
        }
    )->pack();

    $name_frame->waitVariable(\$name_selected);
    $name_frame->destroy();
    return $name_selected;
}

sub get_starting_color {
    my ($frame) = @_;

    my $color_frame = $frame->Toplevel();
    $color_frame->geometry("380x380");
    $color_frame->title("Choose Color");
    $color_frame->attributes(-topmost => 1);

    my $color_var = '';

    $color_frame->Label(
        -text => "Choose your starting color",
        -font => ['Arial', 14]
    )->pack();

    $color_frame->Radiobutton(
        -text     => "White",
        -value    => "white",
        -variable => \$color_var,
        -font     => ['Arial', 14]
    )->pack();

    $color_frame->Radiobutton(
        -text     => "Black",
        -value    => "black",
        -variable => \$color_var,
        -font     => ['Arial', 14]
    )->pack();

    my $color_selected;
    my $submit_button = $color_frame->Button(
        -text    => "Submit",
        -font    => ['Arial', 14],
        -command => sub {
            $color_selected = $color_var;
            
        }
    )->pack();

    $color_frame->waitVariable(\$color_selected);
    $color_frame->destroy();
    return $color_selected;
}

sub get_host_and_port {
    my ($frame) = @_;

    my $connect_frame = $frame->Toplevel();
    $connect_frame->geometry("380x380+900+500");
    $connect_frame->title("Connect to Server");

    my $label = $connect_frame->Label(
        -text => "Host or connect to server",
        -font => ['Arial', 14]
    )->pack();

    my $host_var = 'localhost';
    my $port_var = 8888;

    $connect_frame->Label(
        -text => "Enter Host:",
        -font => ['Arial', 12]
    )->pack();

    $connect_frame->Entry(
        -textvariable => \$host_var,
        -font => ['Arial', 12]
    )->pack();

    $connect_frame->Label(
        -text => "Enter Port:",
        -font => ['Arial', 12]
    )->pack();

    $connect_frame->Entry(
        -textvariable => \$port_var,
        -font => ['Arial', 12]
    )->pack();

    my $input_selected;
    $connect_frame->Button(
        -text    => "Submit",
        -font    => ['Arial', 12],
        -command => sub {
            if ($host_var && $port_var) {
                if ($host_var !~ /^(localhost|^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9]))$/) {
                    $label->configure(-text => "Please input valid IP address."); 
                return;
                }

                if ($port_var !~ /^\d+$/) {
                    $label->configure(-text => "Please input valid port number.");
                    return;
                }

                if ($port_var < 0 || $port_var > 65535) {
                    $label->configure(-text => "Please input valid port number.");
                    return;
                }

                unless ($host_var && $port_var) {
                    $label->configure(-text => "Please input remote host and port.");
                    return;
                }

                $input_selected = 1;
            } else {
                $label->configure(-text => "Please input remote host and port.");
                return;
            }           
        }
    )->pack();

    $connect_frame->waitVariable(\$input_selected);
    my $host = $host_var;
    my $port = $port_var;

    $connect_frame->destroy();

    return ($host, $port);
}
1;
