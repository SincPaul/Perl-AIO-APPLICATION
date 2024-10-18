package utils;

use strict;
use warnings;
use Tk;
use Tk::DragDrop;
use Tk::DropSite;
use IO::Socket;
use IO::Select;
use Tk::Event;

my %theme_colors = (
        'classic'       => ["white", "black"],
        'default'       => ["#ebecd0", "#739552", "#f5f681", "#b9ca42", "#cacbb3", "#638046","#f5f681"], 
        'halloween'     => ["#deeaba", "#d88c34", "#a6f5a5", "#a3c663", "#bfc9a0", "#ba782d", "#a3c663"],
    );

my $old_background_color;
my $old_active_button;
my $active_button;
my @marked_fields;
my $marked_fields_piece;
my $old_pos_button;
my %marked_fields_color;
my %buttons;
my %pieces;
my %images;
my @rows = (1..8);
my @cols = ('a'..'h');
my $old_pos_location;
my $active = 0;
my $currently_checking_if_king_in_check = 0;
my $active_color = 'white';
my $active_move_label;
my @pgn_moves;
my $pgn_move_number = 1;
my $moves_listbox;
my $gamemode;
my $socket;
my $play_color;
my $is_check = 0;
my $is_checkmate = 0;
my $client_name;
my $server_name;
my $is_client;
my $opponent_name;
my $pause_game;
my $winner;
my $was_check;
my $white_name;
my $black_name;
my $king_moved;
my $en_passant_target;
my $my_en_passant_target;
my @last_move_position;
my @last_move_position_enemy;
my %rook_moved;    
my $theme;
my ($theme_background_white, $theme_background_black, $theme_active_button_white, $theme_active_button_black, $theme_marked_fields_white, $theme_marked_fields_black, $theme_last_move);
my $is_game_over;
my %utils_button;
my $revance_text = "revance";
my $revance_accept_text = "revance_accept";
my $surrender_text = "surrender";
my $revance_accept_text_verify = "revance_accept_verify";
my $my_name;
my ($move_frame, $button_frame);
my $round = 1;
my $amount_white_wins = 0;
my $amount_black_wins = 0;
my ($is_listening_to_enemy_move, $is_listening_to_special_move);
my $revance_usage = 0;


# Set the socket, play color, client name, server name and whether the script is run on the client or server
# This function is used if multiplayer mode is chosen
# Gets Data from client and server after the connection has been established
sub set_socket {
    my ($sock, $color, $cli_name, $ser_name, $is_cli, $the) = @_;
    $socket = $sock;
    
    $play_color = $color;
    $client_name = $cli_name;
    $server_name = $ser_name;
    $is_client = $is_cli;

    if ($is_client) {
        $opponent_name = $server_name;
        $my_name = $client_name;
    } else {
        $opponent_name = $client_name;
        $my_name = $server_name;
    }

    if ($play_color eq "white" && $is_client) {
        $white_name = $client_name;
        $black_name = $server_name;
    } elsif ($play_color eq "black" && $is_client) {
        $black_name = $client_name;
        $white_name = $server_name;
    } elsif ($play_color eq "white" && !$is_client) {
        $white_name = $client_name;
        $black_name = $server_name;
    } elsif ($play_color eq "black" && !$is_client) {
        $black_name = $client_name;
        $white_name = $server_name;
    }else {
        $black_name = 'Player 2';
        $white_name = 'Player 1';
    }

    $theme = $the;

    ($theme_background_white, $theme_background_black, $theme_active_button_white, $theme_active_button_black, $theme_marked_fields_white, $theme_marked_fields_black, $theme_last_move) = get_theme_background();

    print("$play_color\n");
}

sub get_theme_background {
    if ($theme_colors{$theme}) {
        return @{$theme_colors{$theme}};
    } else {
        return @{$theme_colors{'default'}};
    }
}
# Listen for the enemy's move on the socket and handle it when it arrives.
# This function is only called in multiplayer mode.
# It is called at start of main loop if play color is 'black'
# Otherwise gets called after sending a move
# It is not blocking, so it does not hinder the rest of the program's execution.
sub listen_to_enemy_move {
    my ($frame) = @_;
    print("MOVE FRAME V22: $move_frame\n");

    $socket->blocking(0);  
    my $select = IO::Select->new($socket);
    $is_listening_to_enemy_move = 1;
    $frame->repeat(1000, sub {
        if ($select->can_read(0)) {  
            if (defined(my $move = <$socket>)) {
                chomp($move);
                if (is_pgn_move($move)) {
                    $is_listening_to_enemy_move = 0;
                    handle_enemy_move($move, $frame);    
                }
                elsif ($move eq $revance_text) {
                    show_revance_overlay($frame);
                } elsif ($move eq $revance_accept_text) {
                    send_move($revance_accept_text_verify);
                    restart_game($frame);
                } elsif ($move eq $surrender_text) {
                    show_surrender_overlay($frame);
                } elsif ($move eq $revance_accept_text_verify) {
                    restart_game($frame);
                }
                
            }
        }
});
}

sub is_pgn_move {
    my ($move) = @_;

    return $move =~ /^[RNBQK]?[a-h]?[1-8]?[x-]?[a-h][1-8](=[RNBQ])?[+#]?$/;
}

sub listen_to_enemy_special_commands {
    my ($frame) = @_;
    
    $socket->blocking(0);  
    my $select = IO::Select->new($socket);
    $is_listening_to_special_move = 1;

    $frame->repeat(1000, sub {
        if ($select->can_read(0)) { 
            my $special_command; 
            if (defined($special_command = <$socket>)) {
                print("RECEIVED SPECIAL COMMAND: $special_command\n");
                chomp($special_command);
                if ($special_command ne is_pgn_move($special_command)) {
                    if ($special_command eq $revance_text) {
                        show_revance_overlay($frame);
                    } elsif ($special_command eq $revance_accept_text) {
                        send_move($revance_accept_text_verify);
                        restart_game($frame);
                    } elsif ($special_command eq $surrender_text) {
                        show_surrender_overlay($frame);
                    } elsif ($special_command eq $revance_accept_text_verify) {
                        restart_game($frame);
                    } 
                elsif (is_pgn_move($special_command)) {
                    $is_listening_to_enemy_move = 0;
                    handle_enemy_move($special_command, $frame);    
                }
                }
            }
        }
    });
}

sub show_surrender_overlay {
    my ($board_frame) = @_;

    my $overlay = $board_frame->Toplevel();
    my $x = $board_frame->rootx + ($board_frame->width / 2) - 150;
    my $y = $board_frame->rooty + ($board_frame->height / 2) - 50;
    $overlay->geometry("500x200+" . int($x) . "+" . int($y));
    $overlay->attributes(-topmost => 1);

    $is_game_over = 1;

    my $frame = $overlay->Frame(
        -background => 'black',
        -relief => 'flat',
        -borderwidth => 0
    )->pack(
        -fill => 'both',
        -expand => 1
    );

    my $surrender_color = $active_color eq 'white' ? 'black' : 'white';
    $winner = $active_color eq 'white' ? 'white' : 'black';
    my $surrender_name = $active_color eq 'white' ? $black_name : $white_name;


    my $label = $frame->Label(
        -text => "$surrender_name surrendered, $winner won",
        -font => ['Arial', 14],
        -background => 'black',
        -foreground => 'white'
    )->pack(
        -fill => 'both',
        -expand => 1
    );

    my $button = $frame->Button(
        -text => 'OK',
        -font => ['Arial', 12],
        -background => 'black',
        -foreground => 'white',
        -command => sub {
            $overlay->destroy();
        }
    )->pack(
        -fill => 'both',
        -expand => 1
    );

    show_winner_overlay($board_frame);

}

sub restart_game {
    my ($board_frame) = @_;

    clear_all_toplevels($board_frame);

    $active_color = 'white';
    $pgn_move_number = 1;
    $moves_listbox->delete(0, 'end');
    $round = $round + 1;
    $revance_usage = 0;

    $is_game_over = undef;
    $is_check = undef;
    $is_checkmate = undef;
    $en_passant_target = undef;
    $my_en_passant_target = undef;
    $was_check = undef;
    $winner = undef;
    $pause_game = undef;
    $king_moved = undef;
    $currently_checking_if_king_in_check = undef;
    $active = undef;

    

    @marked_fields = ();
    @last_move_position = ();
    @pgn_moves = ();
    %rook_moved = (); 

    print("MOVE FRAME: $move_frame\n");
    create_move_gui();
    update_turn_label();
    create_pieces($board_frame);

}

sub clear_all_toplevels {
    my ($frame) = @_;
    foreach my $child ($frame->children()) {
        if ($child->isa('Tk::Toplevel')) {
            $child->destroy();
        }
    }
}
# Handle a move from the enemy, given as a string pgn move.
# Adds the move to the PGN list and updates the move listbox.
# Moves the enemy's piece according to the move.
# Updates the active color and the label showing whose turn it is.
sub handle_enemy_move {
    my ($move, $frame) = @_;

    add_to_pgn_moves($move);
    update_move_listbox(@pgn_moves);
    move_enemy_piece($move, $frame);
    
    if ($play_color eq "black") {
        $active_color = "black";
    } else {
        $active_color = "white";
    }
    update_turn_label();
}

# Add a move to the list of moves in PGN notation.
# If the player is black, just add the move as a new element to the list.
# If the player is white, add the move to the last element of the list.
sub add_to_pgn_moves {
    my ($pgn_move) = @_;

    if ($play_color eq "black") {
        push @pgn_moves, "$pgn_move_number. $pgn_move";
        print("Pgn move number: $pgn_move_number. $pgn_move\n");
    } else {
        $pgn_move_number++;
        $pgn_moves[-1] .= " $pgn_move ";
    }

}

# Move the enemy's piece according to the given move, given in PGN notation.
# If the move ends with a '+' or '#', show a check or checkmate message and
# show a winner overlay with the active color.
# If the move is a castling move, handle_castling is called to move the pieces.
# If the move is an en passant move, set the en passant target to the end position
# of the move.
# If a pawn moves two squares, the en passant target is set to the position
# of the pawn after the move.
# If the en passant target is set before the move, the piece at the target is
# removed and the button at the target is updated.
# The pieces at the start and end positions of the move are swapped.
# The image of the buttons at the start and end positions are updated.
# The background color of the buttons at the start and end positions are
# updated to show the move.
sub move_enemy_piece {
    my ($move, $board_frame) = @_;

    $en_passant_target = undef;

    if ($move =~ /\+$/) {
        print "Check!\n";
    } elsif ($move =~ /#$/) {
        print "Checkmate!\n";
        $winner = $active_color;
        show_winner_overlay($board_frame);
    }

    $move =~ s/[+#]$//;

    my $promotion_piece;
    if ($move =~ /(.*)=(.)$/) {
        $move = $1;
        $promotion_piece = $2;
    }

    if ($move eq 'O-O' || $move eq '0-0') {
        handle_castling('short', $board_frame, 1);
        return;
    } elsif ($move eq 'O-O-O' || $move eq '0-0-0') {
        handle_castling('long', $board_frame, 1);
        return;
    }

    my $end_pos = substr($move, -2);
    my $piece_symbol = substr($move, 0, 1);
    my $start_pos;

    my %letter_abbreviations = (
        'R' => 'rook',
        'N' => 'knight',
        'B' => 'bishop',
        'Q' => 'queen',
        'K' => 'king',
        ''  => 'pawn'
    );

    my $piece_type = $letter_abbreviations{$piece_symbol} || 'pawn';

    print("ACTIVE COLOR: $active_color");

    foreach my $pos (keys %pieces) {
        if ($pieces{$pos} && $pieces{$pos} =~ /$piece_type/ && is_valid_move($pieces{$pos}, $pos, $end_pos) && get_piece_color($pieces{$pos}) eq $active_color) {
            print("PIECE ",$pieces{$pos}, "AT POS: $pos\n");
            $start_pos = $pos;
            last;
        }
    }

    if ($piece_type eq 'pawn') {
        my ($start_row, $start_col) = get_pos($start_pos);
        my ($end_row, $end_col) = get_pos($end_pos);
        
        if ($start_row - $end_row == 2 || $start_row - $end_row == -2) {
            $en_passant_target = $end_pos;
            print("En PASSANT ADDED AT $end_pos\n");
        }
    }

    my $capture_pos = $play_color eq 'white' ? substr($end_pos, 0, 1) . (substr($end_pos, 1, 1) + 1) : substr($end_pos, 0, 1) . (substr($end_pos, 1, 1) - 1);

    if ($my_en_passant_target && $capture_pos eq $my_en_passant_target) {
        $pieces{$my_en_passant_target} = undef;
        my $old_image = $board_frame->Photo(-file => "src/chess/blank.png");
        $buttons{$my_en_passant_target}->configure(-image => $old_image);
    }

    if ($start_pos) {
        my $piece = $pieces{$start_pos};
        $pieces{$start_pos} = undef;
        $pieces{$end_pos} = $promotion_piece ? "${active_color}_$letter_abbreviations{$promotion_piece}" : $piece;

        my $old_image = $board_frame->Photo(-file => "src/chess/blank.png");
        $buttons{$start_pos}->configure(-image => $old_image);

        my $new_image = $board_frame->Photo(-file => "src/chess/$theme/" . $pieces{$end_pos} . ".png");
        $buttons{$end_pos}->configure(-image => $new_image);
    }

    show_and_remove_last_move($start_pos, $end_pos);
}

sub show_and_remove_last_move {
    my ($start_pos, $end_pos) = @_;

    @last_move_position_enemy = ($start_pos, $end_pos);

    $buttons{$start_pos}->configure(-background => $theme_last_move);
    $buttons{$end_pos}->configure(-background => $theme_last_move);

    if (@last_move_position) {
        my ($last_start_pos, $last_end_pos) = @last_move_position;
        $buttons{$last_end_pos}->configure(-background => ((($last_end_pos =~ /^[aceg][1357]$/) || ($last_end_pos =~ /^[bdfh][2468]$/)) ? $theme_background_black : $theme_background_white));
        $buttons{$last_start_pos}->configure(-background => ((($last_start_pos =~ /^[aceg][1357]$/) || ($last_start_pos =~ /^[bdfh][2468]$/)) ? $theme_background_black : $theme_background_white));

        @last_move_position = ();
    }
}

# Handle a castling move. This function is called by move_enemy_piece if the
# move is a castling move. It moves the king and rook to the end positions of
# the move and updates the images of the buttons at the start and end positions
# of the move. The $is_enemy_move parameter specifies if the move is an enemy
# move or a player move. If it is an enemy move, the king and rook of the active
# color are moved. If it is a player move, the king and rook of the opponent's
# color are moved. The $type parameter specifies if the castling is a short or
# long castling. The function calls move_piece_on_board to move the pieces.
sub handle_castling {
    my ($type, $board_frame, $is_enemy_move) = @_;
    my ($king_start, $king_end, $rook_start, $rook_end, $king_color);

    if ($is_enemy_move) {
        $king_color = $active_color;
    } else {
        $king_color = $active_color eq 'white' ? 'black' : 'white';
    }
    if ($type eq 'short') {
        if ($king_color eq 'white') {
            ($king_start, $king_end, $rook_start, $rook_end) = ('e1', 'g1', 'h1', 'f1');
        } else {
            ($king_start, $king_end, $rook_start, $rook_end) = ('e8', 'g8', 'h8', 'f8');
        }
    } elsif ($type eq 'long') {
        if ($king_color eq 'white') {
            ($king_start, $king_end, $rook_start, $rook_end) = ('e1', 'c1', 'a1', 'd1');
        } else {
            ($king_start, $king_end, $rook_start, $rook_end) = ('e8', 'c8', 'a8', 'd8');
        }
    }

    move_piece_on_board($king_start, $king_end, $board_frame);
    move_piece_on_board($rook_start, $rook_end, $board_frame);

    show_and_remove_last_move($king_start, $king_end);
}

# Move a piece from $start_pos to $end_pos on the board. 
sub move_piece_on_board {
    my ($start_pos, $end_pos, $board_frame) = @_;

    my $piece = $pieces{$start_pos};
    
    print("UPDATING $piece, MOVING FROM $start_pos TO $end_pos\n");
    $pieces{$start_pos} = undef;
    $pieces{$end_pos} = $piece;

    my $old_image = $board_frame->Photo(-file => "src/chess/blank.png");
    $buttons{$start_pos}->configure(-image => $old_image);

    my $new_image = $board_frame->Photo(-file => "src/chess/$theme/" . $pieces{$end_pos} . ".png");
    $buttons{$end_pos}->configure(-image => $new_image);

    
}

# Checks if a move is valid according to the rules of chess.
# Takes a piece type, start position, and end position as arguments.
# Returns 1 if the move is valid, 0 if it is not.
# Doesnt check if king would be in check, only used to recreate pgn moves;
sub is_valid_move {
    my ($piece, $start_pos, $end_pos) = @_;
    my @possible_moves = get_possible_moves($piece, $start_pos, 0, 0);

    foreach my $move (@possible_moves) {
        my ($r, $c) = @$move;
        my $pos = turn_to_field($r, $c);
        return 1 if $pos eq $end_pos;
    }

    my $capture_pos = $play_color eq 'white' ? substr($end_pos, 0, 1) . (substr($end_pos, 1, 1) + 1) : substr($end_pos, 0, 1) . (substr($end_pos, 1, 1) - 1);

    if ($piece =~ /pawn/ && $my_en_passant_target && $capture_pos eq $my_en_passant_target) {
        my ($start_row, $start_col) = get_pos($start_pos);
        my ($end_row, $end_col) = get_pos($end_pos);
        return 1 if abs($start_row - $end_row) == 1 && abs($start_col - $end_col) == 1;
    }

    return 0;
}

# Creates the chess board window for a game of chess. If the player is black, starts
# listening for moves from the enemy. Sets up the chess board with the pieces in their
# starting positions. Flips Chess Board for black, makes Pieces clickable to be able to move.
sub create_chess_board {
    my ($frame, $mode) = @_;
 
    print("Mode: $mode\n");
    $gamemode = $mode;
    my $chess_frame = $frame->Toplevel();
    $chess_frame->geometry("1000x900");
    $chess_frame->title("$mode Chess");
    $chess_frame->attributes(-topmost => 1);

    my ($left_frame, $turn_frame, $board_frame) = create_base_gui($chess_frame);
    create_move_gui($board_frame);

    create_pieces($board_frame);


}

sub create_pieces {
    my ($board_frame) = @_;

    

    if ($gamemode eq "Multiplayer") {
        if ($play_color eq "black" && !$is_listening_to_enemy_move) {
            listen_to_enemy_move($board_frame);
        }
        if (!$is_listening_to_special_move) {
            listen_to_enemy_special_commands($board_frame);
            print("$play_color is listening to special commands");
        }
    }
    
    

    my %initial_positions = (
        'a1' => 'white_rook', 'b1' => 'white_knight', 'c1' => 'white_bishop', 'd1' => 'white_queen',
        'e1' => 'white_king', 'f1' => 'white_bishop', 'g1' => 'white_knight', 'h1' => 'white_rook',
        'a2' => 'white_pawn', 'b2' => 'white_pawn', 'c2' => 'white_pawn', 'd2' => 'white_pawn',
        'e2' => 'white_pawn', 'f2' => 'white_pawn', 'g2' => 'white_pawn', 'h2' => 'white_pawn',
        'a7' => 'black_pawn', 'b7' => 'black_pawn', 'c7' => 'black_pawn', 'd7' => 'black_pawn',
        'e7' => 'black_pawn', 'f7' => 'black_pawn', 'g7' => 'black_pawn', 'h7' => 'black_pawn',
        'a8' => 'black_rook', 'b8' => 'black_knight', 'c8' => 'black_bishop', 'd8' => 'black_queen',
        'e8' => 'black_king', 'f8' => 'black_bishop', 'g8' => 'black_knight', 'h8' => 'black_rook',
    );

    my @rows = $play_color eq 'black' ? reverse(1..8) : (1..8);
    my @cols = $play_color eq 'black' ? reverse('a'..'h') : ('a'..'h');

    for my $row (0..7) {
        for my $col (0..7) {
            my $position = $cols[$col] . $rows[7 - $row];
            my $piece = $initial_positions{$position};
            my $file = $piece ? "src/chess/$theme/".$piece.".png" : "src/chess/blank.png";
            $images{$position} = $board_frame->Photo(-file => $file);

            my $button = $board_frame->Button(
                -width => 75,
                -height => 75,
                -image => $images{$position},
                -background => (($row + $col) % 2 == 0) ? $theme_background_white : $theme_background_black,
            )->grid(-row => $row + 1, -column => $col + 1);

            $pieces{$position} = $piece;
            $buttons{$position} = $button;

            $button->configure(
                -command => sub {
                    #print "$position clicked\n";
                    my $piece = $pieces{$position} ? $pieces{$position} : "empty";
                    #print("Piece: ", $piece,"\n");
                    click_button($button, $position, $board_frame);
                }
            );
        }
    }

    for my $row (0..7) {
        $board_frame->Label(
            -text => $rows[$row],
            -font => ['Arial', 14]
        )->grid(-row => 8 - $row, -column => 0);
    }

    for my $col (0..7) {
        $board_frame->Label(
            -text => $cols[$col],
            -font => ['Arial', 14]
        )->grid(-row => 9, -column => $col + 1);
    }
}

# Creates the base GUI for the Chess game
# 
# Parameters:
#   $chess_frame - The main frame of the Chess game
# 
# Returns:
#   A list of five elements: the left frame, the turn frame, the board frame,
#   the move frame, and the bottom frame.
sub create_base_gui {
    my ($chess_frame) = @_;

    my $bottom_frame = $chess_frame->Frame(
        -width => 1000,
        -height => 160,
        -background => 'green',
    )->pack(
        -side => 'bottom',
        -anchor => 's',
    );

    my $left_frame = $chess_frame->Frame(
        -background => 'orange',
        -width => 650,
        -height => 800,
    )->pack(
        -side => 'left',
        -anchor => 'nw',
    );

    my $turn_frame = $left_frame->Frame(
        -background => 'green',
        -width => 650,
        -height => 50,
    )->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => [30, 50],
        -pady => [0, 10],
        -fill => 'both',
    );

    my $board_frame = $left_frame->Frame(
        -width => 650,
        -height => 800
    )->pack(
        -side => 'left',
        -anchor => 'nw',
        -padx => [10, 50],
    );

    $move_frame = $chess_frame->Frame(
        -width => 350,
        -height => 800,
        -background => 'yellow'
    )->pack(
        -padx => [10, 0],
        -side => 'top',
        -anchor => 'nw',
    );

     
    my $sinc_logo = $bottom_frame->Label(
        -image => $bottom_frame->Photo(-file => "src/Chess/Complete_Sinc_Logo_889x160.png"),
        -foreground => 'green',
    )->pack(   
    );

    $active_move_label = $turn_frame->Label(
        -background => 'blue',
        -font => ['Arial', 16, 'bold'],
        -height => 2,
    )->pack(
        -side => 'top',
        -anchor => 'nw',
        -fill => 'x',
        -expand => 1,
    );

    #print("Mode V2: $gamemode\n");

    update_turn_label();

    return ($left_frame, $turn_frame, $board_frame, $bottom_frame);
}

    # Creates the move GUI on the right side of the board.
    #
    # Creaes an Opponent Label and a listbox where the pgn moves are stored
    # and a button to download the pgn moves.
sub create_move_gui {
    my ($board_frame) = @_;

    my $surrender_button;
    my $download_button;

    if ($round <= 1) {
        my $opponent_frame = $move_frame->Frame(
            -background => 'brown',
            -height => 50,
            -width => 350,
        )->pack(
            -side => 'top',
            -fill => 'x',
        );

        my $opponent_label = $opponent_frame->Label(
            -text => "Opponent: $opponent_name \n(ELO: 1500)",
            -background => 'purple',
            -font => ['Arial', 14, 'bold'],
        )->pack(
            -side => 'top',
            -anchor => 'n',
            -padx => 10,
            -pady => 10,
        );

        my $moves_frame = $move_frame->Frame(
            -background => 'purple',
            -width => 350,
            -height => 600,
        )->pack(
            -side => 'top',
            -pady => [10,10],
            -fill => 'both',
            #-expand => 1,
        );

        my $scrollbar = $moves_frame->Scrollbar(
            -orient => 'vertical',
        )->pack(
            -side => 'right',
            -fill => 'y',
        );

        $moves_listbox = $moves_frame->Listbox(
            -background => 'white',
            -font => ['Courier', 12],
            -height => 30,
            -yscrollcommand => ['set', $scrollbar],
        )->pack(
            -side => 'top',
            -fill => 'both',
            #-expand => 1,
        );

        $scrollbar->configure(-command => ['yview', $moves_listbox]);

        $button_frame = $move_frame->Frame(
            -background => 'green',
            -width => 350,
            -height => 100,
        )->pack(
            -side => 'top',
        );

        $download_button = $button_frame->Button(
            -text => "Download PGN",
            -background => 'green',
            -font => ['Arial', 14, 'bold'],
            -command => \&download_pgn,
            -height => 100,
            #-width => 50,
        )->pack(
            -side => 'left',
            -pady => [0,10],
            #-fill => 'x',
        );

        $surrender_button = $button_frame->Button(
            -text => "Surrender",
            -background => 'red',
            -font => ['Arial', 14, 'bold'],
            -command => sub {
                surrender_game($board_frame),
            },
            -height => 100,
            #-width => 50,
        )->pack(
            -side => 'left',
            -pady => [0,10],
            #-fill => 'x',
        );
    } else {
        destroy_all_util_buttons();

        $download_button = $button_frame->Button(
            -text => "Download PGN",
            -background => 'green',
            -font => ['Arial', 14, 'bold'],
            -command => \&download_pgn,
            -height => 100,
            #-width => 50,
        )->pack(
            -side => 'left',
            -pady => [0,10],
            #-fill => 'x',
        );

        $surrender_button = $button_frame->Button(
            -text => "Surrender",
            -background => 'red',
            -font => ['Arial', 14, 'bold'],
            -command => \&surrender_game,
            -height => 100,
            #-width => 50,
        )->pack(
            -side => 'left',
            -pady => [0,10],
            #-fill => 'x',
        );
    }


    $utils_button{'download'} = $download_button;
    $utils_button{'surrender'} = $surrender_button;
}

sub destroy_all_util_buttons {
    foreach my $key (keys %utils_button) {
        if (exists $utils_button{$key}) {
            print "Key $key exists\n";
            print("Util Button: $utils_button{$key}\n");
            $utils_button{$key}->destroy;
            delete $utils_button{$key};
        }
        else {
            print "Key $key does not exist\n";
        }
    }

}

sub surrender_game {
    my ($board_frame) = @_;

    send_move($surrender_text);
    show_surrender_overlay($board_frame);
    $is_game_over = 1;
}

sub update_move_listbox {
    my (@pgn_moves) = @_;

    $moves_listbox->delete(0, 'end');

    foreach my $move (@pgn_moves) {
        $moves_listbox->insert('end', $move);
    }
}

sub download_pgn {
    create_pgn_file();
}

sub create_pgn_file {
    open(my $fh, '>', 'src/chess/game.pgn') or die "Could not open file 'game.pgn' $!";

    my $result;

    if ($winner) {
        $result = "$amount_white_wins-$amount_black_wins";
    } else {
        $result = '*';
    }

    # Alternative way to get the current date
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    $year += 1900;
    $mon += 1;
    my $date = sprintf("%04d.%02d.%02d", $year, $mon, $mday);

    print $fh "[Event \"Online Chess\"]\n";
    print $fh "[Site \"Sinc Chess\"]\n";
    print $fh "[Date \"$date\"]\n";
    print $fh "[Round \"$round\"]\n";
    print $fh "[White \"$white_name\"]\n";
    print $fh "[Black \"$black_name\"]\n";
    print $fh "[Result \"$result\"]\n";
    print $fh "\n";
    for my $move (@pgn_moves) {
        print $fh "$move";
    }
    close $fh;
}

sub update_turn_label {
    $active_move_label->configure(-text => "Active Move: $active_color");
}

sub click_button {
    my ($button, $position, $board_frame) = @_;

    if ($is_game_over) {
        reset_active_button();
        return;
    }

    if ($marked_fields_piece && grep { $_ eq $position } @marked_fields) {
        move_piece($position, $board_frame);
        change_active_color();
        update_turn_label();
        reset_active_button();
        return;
    }

    return unless $pieces{$position};

    clear_marked_fields();

    if ($old_active_button && $old_active_button == $button) {
        reset_active_button();
        return;
    }

    if (get_piece_color($pieces{$position}) ne $play_color && defined($play_color)) {
        return;
    }

    reset_active_button();

    set_active_button($button);

    if ($pieces{$position} =~ /$active_color/) {
        show_moves($button, $position);
    }
}

sub reset_active_button {
    if ($old_active_button  && $old_active_button->cget('-background') ne $theme_last_move) {
        $old_active_button->configure(-relief => 'raised', -background => $old_background_color);
    } elsif ($old_active_button) {
        $old_active_button->configure(-relief => 'raised');
        $old_active_button = undef;
    }
    
}

sub change_active_color {
    $active_color = $active_color eq 'white' ? 'black' : 'white';
}

sub clear_marked_fields {
    for my $pos (@marked_fields) {
        my $background = $marked_fields_color{$pos};
        $buttons{$pos}->configure(-background => $background);
    }
    @marked_fields = ();
    $marked_fields_piece = "";
    $old_pos_button = undef;
}

sub set_active_button {
    my ($button) = @_;
    my $new_bg_color = ($button->cget('-background') eq $theme_background_black) ? $theme_active_button_black : $theme_active_button_white;
    $button->configure(-relief => 'sunken', -background => $new_bg_color);
    $active_button = $button;
    $old_active_button = $button;
    $old_background_color = $button->cget('-background') eq $theme_active_button_black ? $theme_background_black : $theme_background_white;
}

sub turn_to_number {
    my ($letter) = @_;
    return (ord($letter) - 97);

}

sub get_pos {
    my ($position) = @_;
    my ($col, $row) = $position =~ /([a-h])([1-8])/;
    $row = 8 - $row;
    $col = turn_to_number($col);
    return ($row, $col);
}

sub turn_to_field {
    my ($row, $col) = @_;
    $row = 8-$row;
    $col = chr($col + 97);

    return ($col . $row);
}

sub show_moves {
    my ($button, $position) = @_;
    my $piece = $pieces{$position};

    my ($row, $col) = get_pos($position);
    #print("ROW: $row\n");
    
    my @moves = get_possible_moves($piece, $position, 0, 0);

    if (!@moves) {
        return;
    }

    for my $move (@moves) {
        
        my ($r, $c) = @$move;
        next if $r < 0 || $r > 7 || $c < 0 || $c > 7;
        my $pos = $cols[$c] . $rows[7 - $r];
        #print("MOVE: @$move\n");
        #print("POS: $pos\n");
        my $bg_color = ($buttons{$pos}->cget('-background') eq $theme_background_black) ? $theme_background_black : $theme_background_white;
        $marked_fields_color{$pos} = $bg_color;
        $buttons{$pos}->configure(-background => $bg_color eq $theme_background_black ? $theme_marked_fields_black : $theme_marked_fields_white);
        push @marked_fields, $pos;
        $marked_fields_piece = $piece;
        $old_pos_button = $button;
        $old_pos_location = $position;
    }
}

sub get_possible_moves {
    my ($piece, $position, $currently_checking_if_move_will_turn_into_check, $currently_checking_if_king_in_check) = @_;

    
    return () unless $piece;  

    if ($is_check && !$currently_checking_if_king_in_check && !$active) {
        $active = 1;
        my @moves = get_possible_king_protect_moves_piece($piece, $position);
        $active = 0;
        return @moves;
    }

    my ($row, $col) = get_pos($position);  
    my $move_color = get_piece_color($piece);

    my @moves;

    my ($from_row, $from_col) = ($row, $col);

    if (!$currently_checking_if_king_in_check && !$active) {
        $active = 1;
        if (is_own_king_in_check($move_color)) {
            $is_check = 1;
            #print("TESTV4");
            @moves = get_possible_king_protect_moves($move_color);
            $currently_checking_if_king_in_check = 0;
            $active = 0;
            return @moves;
        } else {
            $is_check = 0;
        }
        $currently_checking_if_king_in_check = 0;
        $active = 0;
        #print("TESTV3")
    } 

    #print("FROM ROW $from_row, FROM COL $from_col");

    
    
    if ($piece =~ /pawn/) {
        @moves = $piece =~ /white/ ? get_pawn_moves_white($row, $col) : get_pawn_moves_black($row, $col);
    } elsif ($piece =~ /knight/) {
        @moves = get_knight_moves($piece, $row, $col);
    } elsif ($piece =~ /bishop/) {
        @moves = get_bishop_moves($piece, $row, $col);
    } elsif ($piece =~ /rook/) {
        @moves = get_rook_moves($piece, $row, $col);
    } elsif ($piece =~ /queen/) {
        @moves = get_queen_moves($piece, $row, $col);
    } elsif ($piece =~ /king/) {
        @moves = get_king_moves($piece, $row, $col);
    }

    if (!$currently_checking_if_move_will_turn_into_check && !$active && !$currently_checking_if_king_in_check) {
        $active = 1;
        
        my @valid_moves;
        for my $move (@moves) {
            my ($to_row, $to_col) = @$move;
            if (!will_move_turn_king_into_check($move_color, $row, $col, $to_row, $to_col)) {
                push @valid_moves, $move;
            }
        }
        $active = 0;
        $currently_checking_if_move_will_turn_into_check = 0;
        return @valid_moves;
    } else {
        $currently_checking_if_move_will_turn_into_check = 0;
        return @moves;
    }
}

sub get_possible_king_protect_moves_piece {
    my ($piece, $position) = @_;

    my @protect_moves;
    my ($row, $col) = get_pos($position);
    my $move_color = get_piece_color($piece);

    my @possible_moves = get_possible_moves($piece, $position, 1, 0);

    foreach my $move (@possible_moves) {
        my ($to_row, $to_col) = @$move;
        if (!will_move_turn_king_into_check($move_color, $row, $col, $to_row, $to_col)) {
            push @protect_moves, $move;
        }
    }

    if (!@protect_moves) {
        $is_checkmate = 1;
        #print("NO PROTECT MOVES CHECK MATE LOSER\n");
    }

    return @protect_moves;
}

sub get_possible_king_protect_moves {
    my ($color) = @_;

    my @protect_moves;

    foreach my $position (keys %pieces) {
        my $piece = $pieces{$position};
        next unless $piece;
        next unless get_piece_color($piece) eq $color;

        my ($row, $col) = get_pos($position);
        my @possible_moves = get_possible_moves($piece, $position, 1, 0);

        foreach my $move (@possible_moves) {
            my ($to_row, $to_col) = @$move;
            if (!will_move_turn_king_into_check($color, $row, $col, $to_row, $to_col)) {
                push @protect_moves, [$position, $move];
            }
        }
    }

    if (!@protect_moves) {
        $is_checkmate = 1;
        print("NO PROTECT MOVES CHECK MATE LOSER\n");
    }

    return @protect_moves;
}

sub move_piece {
    my ($position, $board_frame) = @_;

    my $rochade;
    my $is_capture = 0;
    my $is_promotion = 0;
    my $promo_piece = 0;

    $my_en_passant_target = undef;


    my $is_en_passant = 0;
    my $capture_pos = $play_color eq 'white' ? substr($position, 0, 1) . (substr($position, 1, 1) - 1) : substr($position, 0, 1) . (substr($position, 1, 1) + 1);
    if ($en_passant_target && $en_passant_target eq $capture_pos) {
        $is_en_passant = 1;
        $pieces{$capture_pos} = undef;
        my $old_image = $board_frame->Photo(-file => "src/chess/blank.png");
        $buttons{$capture_pos}->configure(-image => $old_image);
    }
    $en_passant_target = undef;

    my $start_pos = $old_pos_location;
    my $end_pos = $position;


    my $piece = $pieces{$old_pos_location};

    if ($piece =~ /king/) {
        if (!$king_moved) {
            if ($end_pos eq 'g1') {
                $rochade = 'short';
                move_piece_on_board('h1', 'f1', $board_frame); 
                print("MOVING ROOK FROM H1 TO F1\n");
            } elsif ($end_pos eq 'c1') {
                $rochade = 'long';
                move_piece_on_board('a1', 'd1', $board_frame); 
            } elsif ($end_pos eq 'c8') {
                $rochade = 'long';
                move_piece_on_board('a8', 'd8', $board_frame); 
            } elsif ($end_pos eq 'g8') {
                $rochade = 'short';
                move_piece_on_board('h8', 'f8', $board_frame); 
            }
            $king_moved = 1;
        }
    }

    if ($piece =~ /rook/) { 
        $rook_moved{$start_pos} = 1;
    }

    if ($piece =~ /pawn/) {
        my ($start_row, $start_col) = get_pos($start_pos);
        my ($end_row, $end_col) = get_pos($end_pos);
        
        if ($start_row - $end_row == 2 || $start_row - $end_row == -2) {
            $my_en_passant_target = $end_pos;
            print("En PASSENT ADDED AT $end_pos\n");
        }
    }

    

    if ($pieces{$position}) {
        $is_capture = 1;
    }

    my $is_double = is_end_pos_double($end_pos, $piece);

    $pieces{$old_pos_location} = undef;
    $pieces{$position} = $marked_fields_piece;

    my $old_image = $board_frame->Photo(-file => "src/chess/blank.png");
    $old_pos_button->configure(-image => $old_image);

    my $new_image = $board_frame->Photo(-file => "src/chess/$theme/$marked_fields_piece.png");
    $buttons{$position}->configure(-image => $new_image);

    for my $pos (@marked_fields) {
        my $background = $marked_fields_color{$pos};
        $buttons{$pos}->configure(-background => $background);
    }
    @marked_fields = ();
    $marked_fields_piece = "";
    $old_pos_button = undef;

    @last_move_position = ($start_pos, $end_pos);

    $buttons{$start_pos}->configure(-background => $theme_last_move);
    $buttons{$end_pos}->configure(-background => $theme_last_move);

    if (@last_move_position_enemy) {
        my ($last_start_pos, $last_end_pos) = @last_move_position_enemy;
        $buttons{$last_end_pos}->configure(-background => ((($last_end_pos =~ /^[aceg][1357]$/) || ($last_end_pos =~ /^[bdfh][2468]$/)) ? $theme_background_black : $theme_background_white));
        $buttons{$last_start_pos}->configure(-background => ((($last_start_pos =~ /^[aceg][1357]$/) || ($last_start_pos =~ /^[bdfh][2468]$/)) ? $theme_background_black : $theme_background_white));

        @last_move_position_enemy = ();
    }


    my ($row, $col) = get_pos($position);

    if ($pieces{$position} eq "white_pawn" && $row == 0) {
        $is_promotion = 1;
        $promo_piece = choose_new_piece($position, 'white', $board_frame);
    } elsif ($pieces{$position} eq "black_pawn" && $row == 7) {
        $is_promotion = 1;
        $promo_piece = choose_new_piece($position, 'black', $board_frame);
    }

    update_check_and_checkmate_status();

    my $pgn_move = generate_pgn_notation($piece, $start_pos, $end_pos, $is_capture, $is_promotion, $promo_piece, $is_double, $rochade, $is_en_passant);

    if ($piece =~ /white/) {
        push @pgn_moves, "$pgn_move_number. $pgn_move";
    } else {
        $pgn_move_number++;
        $pgn_moves[-1] .= " $pgn_move ";
    }

    update_move_listbox(@pgn_moves);

    if ($gamemode eq 'Multiplayer') {
        reset_active_button();
        send_move($pgn_move);
    }

    if ($is_checkmate) {
        print("ACTIVE_COLOR: $active_color\n");
        $winner = $active_color;
        show_winner_overlay($board_frame);
    } elsif (!$is_checkmate && $gamemode eq 'Multiplayer') {
        listen_to_enemy_move($board_frame);
    }
}

sub choose_new_piece {
    my ($position, $color, $board_frame) = @_;

    my $overlay = $board_frame->Toplevel();
    my $x = $board_frame->rootx + ($board_frame->width / 2) - 150;
    my $y = $board_frame->rooty + ($board_frame->height / 2) - 50;
    $overlay->geometry("300x500+" . int($x) . "+" . int($y));
    $overlay->attributes(-topmost => 1);
    $pause_game = 1;

    print("POSITION: $position\nCOLOR: $color\n");

    my $frame = $overlay->Frame(
        -background => 'green',
    )->pack(-fill => 'both', -expand => 1);

    my $label = $frame->Label(
        -text => "Choose New Piece",
        -font => ['Arial', 24],
        -background => 'green',
    )->pack(-fill => 'x');

    my @pieces = qw(rook knight bishop queen);

    my $promo_var;
    
    foreach my $piece (@pieces) {
        $frame->Button(
            -text => ucfirst($piece),
            -font => ['Arial', 18],
            -background => 'red',
            -command => sub {
                $overlay->destroy();
                my $chosen_piece = "${color}_${piece}";
                $pieces{$position} = $chosen_piece;

                my $new_image = $board_frame->Photo(-file => "src/chess/$theme/$chosen_piece.png");
                $buttons{$position}->configure(-image => $new_image);

                $promo_var = $chosen_piece;
            }
        )->pack(-fill => 'x');
    }

    $overlay->waitVariable(\$promo_var);

    return $promo_var;
}

sub show_winner_overlay {
    my ($board_frame) = @_;


    my $overlay = $board_frame->Toplevel();
    my $x = $board_frame->rootx + ($board_frame->width / 2) - 150;
    my $y = $board_frame->rooty + ($board_frame->height / 2) - 50;
    $overlay->geometry("300x100+" . int($x) . "+" . int($y-200));
    $overlay->attributes(-topmost => 1);

    $is_game_over = 1;

    show_end_of_game_move_frame($board_frame);
    #listen_to_enemy_special_commands($board_frame);
    
    my $frame = $overlay->Frame(
        -background => 'green',
    )->pack(-fill => 'both', -expand => 1);
    
    my $winner_label = $frame->Label(
        -text => "Winner: $winner",
        -font => ['Arial', 24],
        -background => 'green',
    )->pack(-fill => 'x');
    
    my $close_button = $frame->Button(
        -text => 'X',
        -font => ['Arial', 18],
        -background => 'red',
        -foreground => 'white',
        -command => sub { $overlay->destroy() },
    )->pack(-side => 'right');

    if ($winner eq 'white') {
        $amount_white_wins++;
    } else {
        $amount_black_wins++;
    }
    my $result = "$amount_white_wins-$amount_black_wins";

    $active_move_label->configure(-text => "$winner WON $result");
}

sub show_end_of_game_move_frame {
    my ($board_frame) = @_;

    $utils_button{'surrender'}->destroy();
    delete $utils_button{'surrender'};

    
    
    my $revance_button = $button_frame->Button(
        -text => 'Revance',
        -font => ['Arial', 18],
        -background => 'red',
        -foreground => 'white',
        -command => sub {
            send_move($revance_text);
            #show_waiting_for_answer_revance_overlay($board_frame);
        },
    )->pack(-side => 'left');

    $utils_button{'revance'} = $revance_button;

    my $analysis_button = $button_frame->Button(
        -text => 'Analysis',
        -font => ['Arial', 18],
        -background => 'red',
        -foreground => 'white',
        -command => sub {
        },
    )->pack(-side => 'left');

    $utils_button{'analysis'} = $analysis_button;
}

sub show_revance_overlay {
    my ($board_frame) = @_;

    my $overlay = $board_frame->Toplevel();
    my $x = $board_frame->rootx + ($board_frame->width / 2) - 150;
    my $y = $board_frame->rooty + ($board_frame->height / 2) - 50;
    $overlay->geometry("300x400+" . int($x) . "+" . int($y));
    $overlay->attributes(-topmost => 1);

    my $frame = $overlay->Frame(
        -background => 'green',
    )->pack(-fill => 'both', -expand => 1);

    my $winner_label = $frame->Label(
        -text => "$winner won this game.",
        -font => ['Arial', 16],
        -background => 'green',
    )->pack(
        -fill => 'x',
        -side => 'top',
    );

    my $revance_label = $frame->Label(
        -text => "$opponent_name wants a revance",
        -font => ['Arial', 12],
        -background => 'green',
    )->pack(
        -side => 'top',
    );
    
    my $revance_button = $frame->Button(
        -text => 'Accept',
        -font => ['Arial', 18],
        -background => 'red',
        -foreground => 'white',
        -command => sub {
            send_move($revance_accept_text);
            #$overlay->destroy();
        },
    )->pack(-side => 'top');
}

sub update_check_and_checkmate_status {
    my $swapped_color = $active_color eq "white" ? "black" : "white";
    if (is_own_king_in_check($swapped_color)) {
        my @moves = get_possible_king_protect_moves($swapped_color);
        if (!@moves) {
            $is_checkmate = 1;
            print("CHECKMATE\n");
        } else {
            $is_checkmate = 0;
            $is_check = 1;
            $was_check = 1;
            print("CHECK\n");
        }
    } else {
        $is_check = 0;
        $is_checkmate = 0;
    }
}

sub send_move {
    my ($move) = @_;
    if ($socket) {
        print $socket "$move\n";  
        print("Sent $move to $socket\n");
    }
}

sub generate_pgn_notation {
    my ($piece, $start_pos, $end_pos, $is_capture, $is_promotion, $promo_piece, $is_double, $rochade, $is_en_passant) = @_;

    if ($rochade) {
        return $rochade eq 'short' ? "O-O" : "O-O-O";
    }

    my $promo_piece_symbol;

    my %letter_abbreviations = (
        'pawn' => '',
        'rook' => 'R',
        'knight' => 'N',
        'bishop' => 'B',
        'queen' => 'Q',
        'king' => 'K'
    );

    my $only_piece = extract_piece($piece);

    my $piece_symbol = $letter_abbreviations{$only_piece};

    my $capture_symbol = $is_capture || $is_en_passant ? 'x' : '';
    

    my $move;

    my $start_pos_letter = extract_position_letter($start_pos);

    if ($is_promotion) {
        my $only_promo_piece = extract_piece($promo_piece);
        $promo_piece_symbol = $letter_abbreviations{$only_promo_piece};

    }
    if ($piece_symbol) {
        $move .= $piece_symbol;
        #print("Piece Symbol $piece_symbol\n");
        if ($is_double) {
            $move .= $start_pos_letter if $start_pos_letter;
        }
    }
    if ($capture_symbol) {
        if (!$piece_symbol) {
            $move .= $start_pos_letter if $start_pos_letter;
        }
        $move .= $capture_symbol;
        #print("Capture Symbol $capture_symbol\n");
    }
    $move .= $end_pos;
    if ($promo_piece_symbol) {
        $move .= "=".$promo_piece_symbol;
        #print("Promotion Symbol $promo_piece_symbol\n");
    }
    if ($is_checkmate) {
        $move .= "#";
    } elsif ($is_check) {
        $move .= "+";
    }

    return $move;
}

sub is_end_pos_double {
    my ($end_pos, $piece) = @_;

    my @pieces_positions = get_all_positions_of_same_piece($piece);
    my $count = 0;

    foreach my $pos (@pieces_positions) {
        #print("POS: $pos, PIECE: $piece\n");
        my @possible_moves = get_possible_moves($piece, $pos, 0, 0);
        foreach my $move (@possible_moves) {
            my ($r, $c) = @$move;
            my $move_pos = turn_to_field($r, $c);
            #print("END_POS: $end_pos, POSSIBLE_MOVE: $move_pos\n");
            if ($move_pos eq $end_pos) {
                #print("COUNT: $count\n");
                $count++;
                last if $count > 1;
            }
        }
    }

    return $count > 1;
}

sub get_all_positions_of_same_piece {
    my ($piece) = @_;
    my @positions;

    foreach my $pos (keys %pieces) {
        if ($piece && $pieces{$pos} && $pieces{$pos} eq $piece) {
            push @positions, $pos;
            #print("POS: $pos, PIECE: $piece, V1V1V1\n")
        }
    }

    return @positions;
}

sub extract_position_letter {
    my ($position) = @_;

    my $extracted_letter = $1 if ($position =~ /([a-h])/);
    #print("Extracted Letter: $extracted_letter\n");

    return $extracted_letter;
}

sub extract_piece {
    my ($piece) = @_;

    my $extracted_piece = $1 if ($piece =~ /(?<=black_|white_)(.+)/);
    #print("Extracted Piece: $extracted_piece\n");

    return $extracted_piece;
}
sub get_pawn_moves_white {
    my ($row, $col) = @_;
    my @moves;


    my $white_pawn_check_pos_infront = turn_to_field($row-1, $col);

    my $white_pawn_check_pos__two_infront = turn_to_field($row-2, $col);

    my $white_pawn_check_pos_across_left = turn_to_field($row-1, $col-1);
    
    my $white_pawn_check_pos_across_right = turn_to_field($row-1, $col+1);

    if ($pieces{$white_pawn_check_pos_across_left} && not_white_piece($pieces{$white_pawn_check_pos_across_left})) {
        push @moves, [$row - 1, $col - 1];
    }

    if ($pieces{$white_pawn_check_pos_across_right} && not_white_piece($pieces{$white_pawn_check_pos_across_right})) {
        push @moves, [$row - 1, $col + 1];
    }

    if ($pieces{$white_pawn_check_pos_infront}) {# && not_white_piece($pieces{$white_pawn_check_pos_infront})) {
        
    } else {
        push @moves, [$row - 1, $col];
        push @moves, [$row - 2, $col] if ($row == 6 && !$pieces{$white_pawn_check_pos__two_infront});
    }
    
    if ($row == 3) {
        my $left_pos = turn_to_field($row, $col - 1);
        my $right_pos = turn_to_field($row, $col + 1);
        if ($col > 0 && $pieces{$left_pos} && $pieces{$left_pos} eq 'black_pawn' && $en_passant_target &&$en_passant_target eq $left_pos) {
            push @moves, [$row - 1, $col - 1];
        } elsif ($col < 7 && $pieces{$right_pos} && $pieces{$right_pos} eq 'black_pawn' && $en_passant_target && $en_passant_target eq $right_pos) {
            push @moves, [$row - 1, $col + 1];
        }
    }

    return @moves;
}

sub not_white_piece {
    my ($piece) = @_;
    return $piece !~ /white/;
}

sub get_pawn_moves_black {
   my ($row, $col) = @_;
    my @moves;


    my $black_pawn_check_pos_infront = turn_to_field($row+1, $col);

    my $black_pawn_check_pos_two_infront = turn_to_field($row+2, $col);

    my $black_pawn_check_pos_across_left = turn_to_field($row+1, $col-1);
    
    my $black_pawn_check_pos_across_right = turn_to_field($row+1, $col+1);

    if ($pieces{$black_pawn_check_pos_across_left} && not_black_piece($pieces{$black_pawn_check_pos_across_left})) {
        push @moves, [$row + 1, $col - 1];

        #return @moves;
    }

    if ($pieces{$black_pawn_check_pos_across_right} && not_black_piece($pieces{$black_pawn_check_pos_across_right})) {
        push @moves, [$row + 1, $col + 1];

        #return @moves;
    }

    if ($pieces{$black_pawn_check_pos_infront}){ #&& not_black_piece($pieces{$black_pawn_check_pos_infront})) {
        
    } else {
        push @moves, [$row + 1, $col];
        push @moves, [$row + 2, $col] if ($row == 1 && !$pieces{$black_pawn_check_pos_two_infront});
    }
    
    if ($row == 6) {
        my $left_pos = turn_to_field($row, $col - 1);
        my $right_pos = turn_to_field($row, $col + 1);
        if ($col > 0 && $pieces{$left_pos} && $pieces{$left_pos} eq 'white_pawn' && $en_passant_target eq $left_pos) {
            push @moves, [$row - 1, $col - 1];
        } elsif ($col < 7 && $pieces{$right_pos} && $pieces{$right_pos} eq 'white_pawn' && $en_passant_target eq $right_pos) {
            push @moves, [$row - 1, $col + 1];
        }
    }

    return @moves;
 
}

sub not_black_piece {
    my ($piece) = @_;
    return $piece !~ /black/;
}

sub get_knight_moves {
    my ($piece, $row, $col) = @_;
    my @moves;

    my $color = get_piece_color($piece);

    my @possible_moves = (
        [$row - 2, $col - 1], [$row - 2, $col + 1],
        [$row - 1, $col - 2], [$row - 1, $col + 2],
        [$row + 1, $col - 2], [$row + 1, $col + 2],
        [$row + 2, $col - 1], [$row + 2, $col + 1]
    );
    #print("COLOR: $color");

    for my $move (@possible_moves) {
        my ($r, $c) = @$move;
        #print("R: $r, C: $c");
        my $check_pos_for_pieces = turn_to_field($r, $c);

        next if $r < 0 || $r > 7 || $c < 0 || $c > 7;
        

        if ($pieces{$check_pos_for_pieces} && ($color eq 'white' ? not_white_piece($pieces{$check_pos_for_pieces}) : not_black_piece($pieces{$check_pos_for_pieces}))) {
            #print("R AND C: $r, $c");
            #print("CHECK POS FOR PIECES: $check_pos_for_pieces\n");
            push @moves, [$r, $c];
        } elsif (!$pieces{$check_pos_for_pieces}){
            #print("R AND C: $r, $c");
            #print("CHECK POS FOR PIECES: $check_pos_for_pieces\n"); 
            push @moves, [$r, $c];
        } 
    }

        
        
    return @moves;
    
}

sub get_bishop_moves {
    my ($piece, $row, $col) = @_;
    my @moves;

    my $color = get_piece_color($piece);

    my @directions = (
        [-1, -1], [-1, 1],
        [1, -1], [1, 1]
    );

    for my $direction (@directions) {
        my ($dr, $dc) = @$direction;
        for my $i (1..7) {
            my $r = $row + $i * $dr;
            my $c = $col + $i * $dc;
            next if $r < 0 || $r > 7 || $c < 0 || $c > 7;
            my $check_pos_for_pieces = turn_to_field($r, $c);
            if ($pieces{$check_pos_for_pieces}) {
                if ($color eq 'white' ? not_white_piece($pieces{$check_pos_for_pieces}) : not_black_piece($pieces{$check_pos_for_pieces})) {
                    push @moves, [$r, $c];
                }
                last;
            } else {
                push @moves, [$r, $c];
            }
        }
    }

    return @moves;
}

sub get_rook_moves {
    my ($piece, $row, $col) = @_;
    my @moves;

    my $color = get_piece_color($piece);

    my @directions = (
        [-1, 0], [1, 0],
        [0, -1], [0, 1]
    );

    for my $direction (@directions) {
        my ($dr, $dc) = @$direction;
        for my $i (1..7) {
            my $r = $row + $i * $dr;
            my $c = $col + $i * $dc;
            next if $r < 0 || $r > 7 || $c < 0 || $c > 7;
            my $check_pos_for_pieces = turn_to_field($r, $c);
            if ($pieces{$check_pos_for_pieces}) {
                if ($color eq 'white' ? not_white_piece($pieces{$check_pos_for_pieces}) : not_black_piece($pieces{$check_pos_for_pieces})) {
                    push @moves, [$r, $c];
                }
                last;
            } else {
                push @moves, [$r, $c];
            }
        }
    }

    return @moves;
}

sub get_queen_moves {
    my ($piece, $row, $col) = @_;
    my @moves;

    my $color = get_piece_color($piece);

    my @directions = (
        [-1, -1], [-1, 1],
        [1, -1], [1, 1],
        [-1, 0], [1, 0],
        [0, -1], [0, 1]
    );

    for my $direction (@directions) {
        my ($dr, $dc) = @$direction;
        for my $i (1..7) {
            my $r = $row + $i * $dr;
            my $c = $col + $i * $dc;
            next if $r < 0 || $r > 7 || $c < 0 || $c > 7;
            my $check_pos_for_pieces = turn_to_field($r, $c);
            if ($pieces{$check_pos_for_pieces}) {
                if ($color eq 'white' ? not_white_piece($pieces{$check_pos_for_pieces}) : not_black_piece($pieces{$check_pos_for_pieces})) {
                    push @moves, [$r, $c];
                }
                last;
            } else {
                push @moves, [$r, $c];
            }
        }
    }

    return @moves;
}

sub get_king_moves {
    my ($piece, $row, $col) = @_;
    my @moves;

    my $color = get_piece_color($piece);

    return 0 if $currently_checking_if_king_in_check;

    my @possible_moves = (
        [$row - 1, $col - 1], [$row - 1, $col], [$row - 1, $col + 1],
        [$row, $col - 1], [$row, $col + 1],
        [$row + 1, $col - 1], [$row + 1, $col], [$row + 1, $col + 1]
    );

    for my $move (@possible_moves) {
        my ($r, $c) = @$move;
        my $check_pos_for_pieces = turn_to_field($r, $c);
        next if $r < 0 || $r > 7 || $c < 0 || $c > 7;
        if ($pieces{$check_pos_for_pieces}) {
            if ($color eq 'white' ? not_white_piece($pieces{$check_pos_for_pieces}) : not_black_piece($pieces{$check_pos_for_pieces})) {
                push @moves, [$r, $c];
            }
        } else {
            push @moves, [$r, $c];
        }
    }

    if (!$is_check && !$currently_checking_if_king_in_check && !$was_check && !$king_moved) {
        if ($color eq 'white') {
            if ($row == 7 && $col == 4) {
                if (!$pieces{'f1'} && !$pieces{'g1'} && $pieces{'h1'} && $pieces{'h1'} eq 'white_rook' && !$rook_moved{'h1'}) {
                    unless (will_move_turn_king_into_check($color, $row, $col, $row, $col + 1) || will_move_turn_king_into_check($color, $row, $col, $row, $col + 2)) {
                        push @moves, [$row, $col + 2];
                    }
                }
                if (!$pieces{'d1'} && !$pieces{'c1'} && !$pieces{'b1'} && $pieces{'a1'} && $pieces{'a1'} eq 'white_rook' && !$rook_moved{'a1'}) {
                    unless (will_move_turn_king_into_check($color, $row, $col, $row, $col - 1) || will_move_turn_king_into_check($color, $row, $col, $row, $col - 2)) {
                        push @moves, [$row, $col - 2];
                    }
                }
            }
        } elsif ($color eq 'black') {
            if ($row == 0 && $col == 4) {
                if (!$pieces{'f8'} && !$pieces{'g8'} && $pieces{'h8'} && $pieces{'h8'} eq 'black_rook' && !$rook_moved{'h8'}) {
                    unless (will_move_turn_king_into_check($color, $row, $col, $row, $col + 1) || will_move_turn_king_into_check($color, $row, $col, $row, $col + 2)) {
                        push @moves, [$row, $col + 2];
                    }
                }
                if (!$pieces{'d8'} && !$pieces{'c8'} && !$pieces{'b8'} && $pieces{'a8'} && $pieces{'a8'} eq 'black_rook' && !$rook_moved{'a8'}) {
                    unless (will_move_turn_king_into_check($color, $row, $col, $row, $col - 1) || will_move_turn_king_into_check($color, $row, $col, $row, $col - 2)) {
                        push @moves, [$row, $col - 2];
                    }
                }
            }
        }
    }

    return @moves;
}

sub is_own_king_in_check {
    my ($move_color) = @_;

    return 0 if $currently_checking_if_king_in_check;

    my $is_in_check = check_if_in_check($move_color);

    return $is_in_check;
}

sub check_if_in_check {
    my ($move_color) = @_;

    my $reversed_color = $move_color eq 'white' ? 'black' : 'white';

    foreach my $pos (keys %pieces) {
        if (!$pieces{$pos}) {
            next;
        }
        my $piece = $pieces{$pos};
        my $enemy_piece_color = get_piece_color($pieces{$pos});
        
        if ($enemy_piece_color eq $reversed_color) {
            my @possible_moves_enemy = get_possible_moves($piece, $pos, 0, 1); # Pass flag to avoid recursion
            foreach my $possible_move_enemy (@possible_moves_enemy) {
                my ($r, $c) = @$possible_move_enemy;
                my $check_pos_for_pieces = turn_to_field($r, $c);
                if ($pieces{$check_pos_for_pieces} && $pieces{$check_pos_for_pieces} eq "${move_color}_king") {
                    #print("KING IN CHECK\n");
                    return 1;
                }
            }
        }
        
    }
    #print ("KING NOT IN CHECK\n");
    return 0;

}

sub will_move_turn_king_into_check {
    my ($move_color, $from_row, $from_col, $to_row, $to_col) = @_;
    
    my $is_will_be_in_check = simulate_move($move_color, $from_row, $from_col, $to_row, $to_col);

    if ($is_will_be_in_check) {
        #print("KING WILL BE IN CHECK\n");
        return 1;
    } else {
        #print("KING WILL NOT BE IN CHECK\n");
        return 0;
    }
}

sub simulate_move {
    my ($move_color, $from_row, $from_col, $to_row, $to_col) = @_;

    my $reversed_color = $move_color eq 'white' ? 'black' : 'white';

    my %pieces_copy = %pieces;

    #print("FROM ($from_row, $from_col), TO: ($to_row, $to_col)");

    move_piece_to($from_row, $from_col, $to_row, $to_col);

    foreach my $pos (keys %pieces) {
        if (!$pieces{$pos}) {
            next;
        }
        my $piece = $pieces{$pos};
        my $enemy_piece_color = get_piece_color($pieces{$pos});
        
        if ($piece && $enemy_piece_color eq $reversed_color) {
            my @possible_moves_enemy = get_possible_moves($piece, $pos, 1, 0); # Pass flag to avoid recursion
            foreach my $possible_move_enemy (@possible_moves_enemy) {
                my ($r, $c) = @$possible_move_enemy;
                my $check_pos_for_pieces = turn_to_field($r, $c);
                if ($pieces{$check_pos_for_pieces} && $pieces{$check_pos_for_pieces} eq "${move_color}_king") {
                    undo_move($from_row, $from_col, $to_row, $to_col);
                    %pieces = %pieces_copy;
                    return 1;
                }
            }
        }
        
    }

    %pieces = %pieces_copy;

    return 0;
}

sub undo_move {
    my ($from_row, $from_col, $to_row, $to_col) = @_;

    move_piece_to($to_row, $to_col, $from_row, $from_col);

    
}

sub move_piece_to {
    my ($from_row, $from_col, $to_row, $to_col) = @_;

    my $from_pos = turn_to_field($from_row, $from_col);
    my $to_pos = turn_to_field($to_row, $to_col);

    #print("FROM ROW $from_row, FROM COL $from_col, TO ROW $to_row, TO COL $to_col");

    my $piece = $pieces{$from_pos};

    #print ("Print deleting $piece at $from_pos\n");
    $pieces{$from_pos} = undef;
    #print ("ADDING BACK $piece at $to_pos\n");
    $pieces{$to_pos} = $piece;
}


sub get_piece_color {
    my ($piece) = @_;
    if ($piece) {
        return $piece =~ /white/ ? 'white' : 'black';
    }
}

1;