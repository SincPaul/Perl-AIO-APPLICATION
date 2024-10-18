package game;

use strict;
use warnings;


sub chooseGame {
    my ($frame) = @_;

    my $game_select = $frame->Toplevel();
    $game_select->geometry("300x350");
    $game_select->title("Select Game");

    my $label = $game_select->Label(
        -text => "Choose Game?",
        -font => ['Arial', 14]
    )->pack(
        -pady => 20,
    );

    my $game_frame = $game_select->Frame(
        -borderwidth => 2,
        -relief => 'raised',
        -background => 'grey',

    )->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
        #-expand => 1
    );

    

    my $memory_button = $game_frame->Button(
        -text => "Memory",
        -font => ['Arial', 14],
        -command => sub {
            memory::start($frame);
            $game_select->destroy();
        }
    )->grid(
        -pady => 20,
        -padx => 20,
        -row => 0,
        -column => 0,
    );

    my $tic_tac_toe_button = $game_frame->Button(
        -text => "Tic Tac Toe",
        -font => ['Arial', 14],
        -command => sub {
            tictactoe::start($frame);
            $game_select->destroy();
        }
    )->grid(
        -pady => 20,
        -row => 0,
        -padx => [0, 20],
        -column => 1,
    );

    my $sudoku_button = $game_frame->Button(
        -text => "Sudoku",
        -font => ['Arial', 14],
        -command => sub {
            sudoku::start($frame);
            $game_select->destroy();
        }
    )->grid(
        -pady => 20,
        -padx => 20,
        -row => 1,
        -column => 0,
    );

    my $chess = $game_frame->Button(
        -text => "Chess",
        -font => ['Arial', 14],
        -command => sub {
            chesslogin::start($frame);
            $game_select->destroy();
        }
    )->grid(
        -pady => 20,
        -row => 1,
        -padx => [0, 20],
        -column => 1,
    );

    my $exit = $game_select->Button(
        -text => "Exit",
        -font => ['Arial', 14],
        -command => sub {
            $game_select->destroy();
        }
    )->pack(
        -pady => 20,
        -padx => 10,
        -fill => 'x',
    );

    #chesslogin::start($frame, $game_select);
    #$game_select->destroy();
    #SUDOKU::start($frame);
    #$game_select->destroy();
}

1;