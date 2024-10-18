package chesslogin;

use strict;
use warnings;

use GAMES::CHESS::start::game::singleplayer_chess;
use GAMES::CHESS::start::game::multiplayer_chess;
use GAMES::CHESS::start::game::multiplayer_chess_randoms;
use GAMES::CHESS::start::game::utils;
use GAMES::CHESS::start::chessstart;


sub start {
    my ($frame, $game_select) = @_;

    if ($game_select) {
        $game_select->destroy();
    }

    my $login_frame = $frame->Toplevel();
    $login_frame->geometry("646x646");
    $login_frame->title("Choose Login Method");

    my $uuid = session::get_uuid();
    if ($uuid) {
        print("TESTV2");
        #my $username = account_utils::get_username($uuid);
        my $display_name = account_utils::get_display_name($uuid);
        chessstart::start($login_frame, $frame, $display_name);
    } else {
        login_page($login_frame, $frame);
    }
    #chessstart::start($frame);
}

sub login_page {
    my ($login_frame, $frame) = @_;

    reset_to_background($login_frame);

    my $sign_up_button = $login_frame->Button(
        -text => "Sign Up",
        -background => 'blue',
        -foreground => 'white',
        -font => ['Arial', 12, 'bold'],
        -command => sub {
            sign_up($login_frame, $frame);
        },
    )->place(
        -x => 121,
        -y => 187,
        -width => 80,
        -height => 30,
    );

    my $login_button = $login_frame->Button(
        -text => "Login",
        -background => 'green',
        -foreground => 'white',
        -font => ['Arial', 12, 'bold'],
        -command => sub {
            login($login_frame, $frame);
        },
    )->place(
        -x => 283,
        -y => 187,
        -width => 80,
        -height => 30,
    );

    my $guest_button = $login_frame->Button(
        -text => "Continue \nas Guest",
        -background => 'orange',
        -foreground => 'white',
        -font => ['Arial', 12, 'bold'],
        -command => sub {
            continue_as_guest($login_frame, $frame);
        },
    )->place(
        -x => 445,
        -y => 172,
        -width => 80,
        -height => 60,
    );

    my $exit_button = $login_frame->Button(
        -text => "Exit",
        -background => 'red',
        -foreground => 'white',
        -font => ['Arial', 12, 'bold'],
        -command => sub { exit },
    )->place(
        -x => 283,
        -y => 349,
        -width => 80,
        -height => 30,
    );
}

sub sign_up {
    my ($login_frame, $frame) = @_;

    reset_to_background($login_frame);

    

    my $username_label = $login_frame->Label(
        -text => "Username:",
        -font => ['Arial', 12],
    )->pack(
        -pady => [170, 10],
    );
    my $username_entry = $login_frame->Entry(
        -font => ['Arial', 12]
    )->pack(
        -pady => 10,
    );

    my $password_label = $login_frame->Label(
        -text => "Password:",
        -font => ['Arial', 12]
    )->pack(
        -pady => 10,
    );

    my $password_entry = $login_frame->Entry(
        -font => ['Arial', 12],
        -show => '*'
    )->pack(
        -pady => 10,
    );

    my $confirm_password_label = $login_frame->Label(
        -text => "Confirm Password:",
        -font => ['Arial', 12]
    )->pack(
        -pady => 10,
    );

    my $confirm_password_entry = $login_frame->Entry(
        -font => ['Arial', 12],
        -show => '*'
    )->pack(
        -pady => 10,
    );
    my $sign_up_play_button = $login_frame->Button(
        -text => "Sign Up and Play",
        -background => 'blue',
        -foreground => 'white',
        -font => ['Arial', 12, 'bold'],
        -command => sub {
            my $username = $username_entry->get();
            my $password = $password_entry->get();
            if ($username && $password) {
                my $is_success = account_utils::register($username, $password);
                if ($is_success) {
                    multiplayer_chess_randoms::start($login_frame, $frame, $username);
                }
            }
        },
    )->place(
        -x => 122+80,
        -y => 434,
        -width => 150,
        -height => 30,
    );

    my $return_button = $login_frame->Button(
        -text => "Return",
        -background => 'red',
        -foreground => 'white',
        -font => ['Arial', 12, 'bold'],
        -command => sub {
            login_page($login_frame, $frame);
        },
    )->place(
        -x => 284+80,
        -y => 434,
        -width => 80,
        -height => 30,
    );
}

sub login {
    my ($login_frame, $frame) = @_;

    reset_to_background($login_frame);

    my $username_label = $login_frame->Label(
        -text => "Username:",
        -font => ['Arial', 12],
    )->pack(
        -pady => [210, 10],
    );
    my $username_entry = $login_frame->Entry(
        -font => ['Arial', 12]
    )->pack(
        -pady => 10,
    );

    my $password_label = $login_frame->Label(
        -text => "Password:",
        -font => ['Arial', 12]
    )->pack(
        -pady => 10,
    );

    my $password_entry = $login_frame->Entry(
        -font => ['Arial', 12],
        -show => '*'
    )->pack(
        -pady => 10,
    );

    my $login_play_button = $login_frame->Button(
        -text => "Login and Play",
        -background => 'green',
        -foreground => 'white',
        -font => ['Arial', 12, 'bold'],
        -command => sub {
            my $username = $username_entry->get();
            my $password = $password_entry->get();
            if (is_user_login()) {
                print("Username: $username, Password: $password\n");
                chessstart::start($login_frame, $frame, $username);
            }
        },
    )->place(
        -x => 122 + 80,
        -y => 394,
        -width => 150,
        -height => 30,
    );

    my $return_button = $login_frame->Button(
        -text => "Return",
        -background => 'red',
        -foreground => 'white',
        -font => ['Arial', 12, 'bold'],
        -command => sub {
            login_page($login_frame, $frame);
        },
    )->place(
        -x => 284 + 80,
        -y => 394,
        -width => 80,
        -height => 30,
    );
}

sub is_user_login {
    return 1;
}

sub continue_as_guest {
    my ($login_frame, $frame) = @_;

    reset_to_background($login_frame);

    my $guest_username_label = $login_frame->Label(
        -text => "Guest Username:",
        -font => ['Arial', 12],
    )->pack(
        -pady => [250, 10],
    );
    my $guest_username_entry = $login_frame->Entry(
        -font => ['Arial', 12]
    )->pack(
        -pady => 10,
    );

    my $guest_play_button = $login_frame->Button(
        -text => "Continue as Guest",
        -background => 'purple',
        -foreground => 'white',
        -font => ['Arial', 12, 'bold'],
        -command => sub {
            my $guest_username = $guest_username_entry->get();
            if ($guest_username) {
                $guest_username .= " (Guest)";
                print("Guest Username: $guest_username\n");
                chessstart::start($login_frame, $frame, $guest_username);
            }
            
        },
    )->place(
        -x => 122 + 80,
        -y => 354,
        -width => 150,
        -height => 30,
    );

    my $return_button = $login_frame->Button(
        -text => "Return",
        -background => 'red',
        -foreground => 'white',
        -font => ['Arial', 12, 'bold'],
        -command => sub {
            login_page($login_frame, $frame);
        },
    )->place(
        -x => 284 + 80,
        -y => 354,
        -width => 80,
        -height => 30,
    );
}

sub reset_to_background {
    my ($login_frame) = @_;
    
    foreach my $widget ($login_frame->children) {
        $widget->destroy();
    }

    set_background($login_frame);
}
sub set_background {
    my ($login_frame) = @_;
  
    my $background_image = $login_frame->Photo(-file => "src/chess/login/Chessboard1.png");
    my $background_label = $login_frame->Label(
        -image => $background_image,
    )->place(
        -x => 0,
        -y => 0,
        -relwidth => 1,
        -relheight => 1,
    );
}
1;