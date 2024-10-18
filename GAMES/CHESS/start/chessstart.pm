package chessstart;

use strict;
use warnings;

#use GAMES::CHESS::singleplayer_chess;
#use GAMES::CHESS::multiplayer_chess;
#use GAMES::CHESS::utils;

my $width = 560;
my $height = 300;


sub start {
    my ($login_frame, $frame, $username) = @_;

    $login_frame->destroy();

    my $choose_mode_frame = $frame->Toplevel();
    $choose_mode_frame->geometry("${width}x${height}");
    $choose_mode_frame->title("Choose Mode");

    choose_mode($frame, $username, $choose_mode_frame);
}

sub choose_mode {
    my ($frame, $username, $choose_mode_frame) = @_;

    my $label_frame = $choose_mode_frame->Frame(
        -background => 'lightblue',
    )->pack(
        -padx => 10,
        -pady => 10,
        -fill => 'x',
        -side => 'top'
    );

    my $account_button = $choose_mode_frame->Button(
        -text => "Account: $username",
        -font => ['Arial', 10],
        -command => sub {
            show_account_info($username);
        }
    )->place(
        -x => $width- 10,
        -y => 10,
        -anchor => 'ne'
    );

    my $label = $label_frame->Label(
        -text => "Choose Mode",
        -font => ['Arial', 16],
        -background => 'lightblue'
    )->pack(
        -pady => 20,
    );

    my $button_frame = $choose_mode_frame->Frame(
        -background => 'lightblue'
    )->pack(
        -padx => 10,
        -pady => 10,
        -fill => 'x',
        -side => 'top',
    );

    my $single_player_button = $button_frame->Button(
        -text => "Single Player",
        -font => ['Arial', 14],
        -command => sub {
            singleplayer_chess::start($choose_mode_frame);
        }
    )->pack(
        -pady => 20,
        -padx => 20,
        -side => 'left',
    );

    my $multiplayer_friend_button = $button_frame->Button(
        -text => "Versus Friend",
        -font => ['Arial', 14],
        -command => sub {
            multiplayer_chess::start($choose_mode_frame, $frame);       
        }
    )->pack(
        -pady => 20,
        -padx => 20,
        -side => 'left',
    );

    my $multiplayer_random_button = $button_frame->Button(
        -text => "Versus Random",
        -font => ['Arial', 14],
        -command => sub {
            multiplayer_chess_randoms::start($choose_mode_frame);
        }
    )->pack(
        -pady => 20,
        -padx => 20,
        -side => 'left',
    );

    my $logout_frame = $choose_mode_frame->Frame(
        -background => 'lightblue'
    )->pack(
        -padx => 10,
        -pady => 10,
        -fill => 'x',
        -side => 'top',
    );

    my $logout_button = $logout_frame->Button(
        -text => "Logout",
        -font => ['Arial', 14],
        -command => sub {
            chesslogin::start($frame, $choose_mode_frame);
        }
    )->pack(
        -pady => 20,
        -padx => 20,
        -side => 'top',
    );
}

sub show_account_info {
    my ($username) = @_;
    # Implement the logic to show account information
}



    #singleplayer_chess::start($frame);
    #$choose_mode->destroy();

    #multiplayer_chess::start($frame, $choose_mode);
    #$choose_mode->destroy();
    





1;