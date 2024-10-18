package tictactoe;

use strict;
use warnings;

my @active_fields;
my $turn;
my @x_moves;
my @o_moves;
my $used_fields;

sub start {
    my ($frame) = @_;

    choose_field_size ($frame);

}

sub choose_field_size {
    my ($frame) = @_;

    my $field_size_select = $frame->Toplevel();
    $field_size_select->geometry("300x300");
    $field_size_select->title("Select Field Size");

    my $label = $field_size_select->Label(
        -text => "Choose Field Size?",
        -font => ['Arial', 14]
    )->pack(
        -pady => 20,
    );

    my $selected_size = 3;  # default value

    my $radio_frame = $field_size_select->Frame(
        -borderwidth => 2,
        -relief => 'raised',
        -background => 'grey',
    )->pack(-pady => 10);

    my @sizes = (3, 4, 5, 6, 7, 8);
    my $row_count = 0;

    for (my $i = 0; $i < scalar @sizes; $i += 3) {
        my $row_frame = $radio_frame->Frame(
            -background => 'grey',
        )->pack(-side => 'top', -padx => 10, -pady => 5);
        for my $j (0 .. 2) {
 
            my $size = $sizes[$i + $j];
            $row_frame->Radiobutton(
                -text    => "${size}x${size}",
                -value   => $size,
                -variable => \$selected_size,
                -background => 'grey',
            )->pack(-side => 'left', -padx => 10);
        }
    }

    # Add an OK button to confirm the selection
    my $ok_button = $field_size_select->Button(
        -text => "OK",
        -command => sub {
            print "Selected field size: $selected_size\n";  # Output the selected size
            start_game($frame, $selected_size);
            $field_size_select->destroy;  # Close the window after selection
        }
    )->pack(
        -pady => 20,
    );
}


sub start_game {
    my ($frame, $field_size) = @_;

    
    my $width = 80+$field_size*100+($field_size)*10;
    my $height = $field_size*100+($field_size)*10+350;
    my $tictactoe_child = $frame->Toplevel();
    $tictactoe_child->geometry("$width" . "x" . "$height");
    $tictactoe_child->title("Tic Tac Toe");

   

    my $tictactoe_label = $tictactoe_child->Label(
        -text => "Tic Tac Toe",
        -font => ['Arial', 14]
    )->pack(
        -pady => 0,
    );

    my $turn_label = $tictactoe_child->Label(
        -text => "Turn: X",
        -font => ['Arial', 14]
    )->pack(
        -pady => 10,
    );

    my $blank_image = $tictactoe_child->Photo(-file => 'src/tictactoe/blank.png');

    my $tictactoe_frame = $tictactoe_child->Frame(
        -borderwidth => 2,
        -relief => 'raised',
        -background => 'black',
        -width => $field_size*100+($field_size-1)*5,
        -height => $field_size*100+($field_size-1)*5,
    )->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        #-fill => 'x',
        #-expand => 1
    );


    my $bottom_frame = $tictactoe_child->Frame()->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
    );
    
    restart($tictactoe_frame, $field_size, $blank_image, $turn_label);

    my $restart_button = $bottom_frame->Button(
        -text => "Restart",
        -command => sub {
            restart($tictactoe_frame, $field_size, $blank_image, $turn_label);
        }
    )->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
    );

    my $player_choose_button = $bottom_frame->Button(
        -text => "Change field size",
        -command => sub {
            choose_field_size($frame);
            $tictactoe_child->destroy();
        }
    )->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
    );

    my $exit_button = $bottom_frame->Button(
        -text => "Exit",
        -command => sub {
            $tictactoe_child->destroy();
        }
    )->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
    );
}

sub restart {
    my ($frame, $field_size, $blank_image, $turn_label) = @_;
    $turn = 0;
    @active_fields = ();
    @x_moves = ();
    @o_moves = ();
    $used_fields = 0;
    

    for (my $i = 0; $i < $field_size*$field_size; $i++) {
        my $row = int($i / $field_size);
        my $column = $i % $field_size;

        my $field_id = $i;

        my $button = $frame->Button(
            -image => $blank_image,
            -width => 100,
            -height => 100,
            -relief => 'flat',
        )->grid(
            -row => $row,
            -column => $column,
            -padx => 5,
            -pady => 5
        );
        $button->configure(
            -command => sub {
                place_entity($field_id, $field_size, $turn_label, $button, $frame);
            }
        )
    }
}

sub place_entity {
    my ($field_id, $field_size, $turn_label, $button, $frame) = @_;

    my $x_image = $frame->Photo(-file => "src/tictactoe/red_cross.png");
    my $o_image = $frame->Photo(-file => "src/tictactoe/black_circle.png");

    #print($field_id);
    if ($field_id ~~ @active_fields) {
        print("already selected \n");
        return;
    }

    push(@active_fields, $field_id);
    #print(@active_fields);

    
    my $active_mover;

    if ($turn == 0) {
        $button->configure(
        -image => $x_image,
        );
        $turn_label->configure(-text => "Turn: O");
        push(@x_moves, $field_id);
        $turn = 1;
        $active_mover = "X";
    } else {
        $button->configure(
        -image => $o_image,
        );
        $turn_label->configure(-text => "Turn: X");
        push(@o_moves, $field_id);
        $turn = 0;
        $active_mover = "O";
    }

    $used_fields++;
    
    if (check_winner($active_mover, $field_size, $field_id, @x_moves, @o_moves)) {
        my $winner;
        if ($active_mover eq "X") {
            $turn_label->configure(-text => "Winner: X");
            print("x won");
            $winner = 'x';
            
        } else {
            $turn_label->configure(-text => "Winner: O");
            print("o won");
            $winner = 'o';
        }
        show_win_msg($winner, $frame);
    }
    elsif (no_moves_left($field_size, $used_fields)) {

        $turn_label->configure(-text => "Draw");
        show_win_msg('draw', $frame);
    }


}

sub check_winner {
    my ($active_mover, $field_size, $field_id, $x_moves, $o_moves) = @_;

    my @player_moves = $active_mover eq "X" ? @x_moves : @o_moves;
    my $row = int($field_id / $field_size);
    my $column = $field_id % $field_size;  

    my $in_a_row = 0;
    for (my $i = $row*$field_size; $i < $field_size * ($row +1); $i++) {
        if ($i ~~ @player_moves) {
            $in_a_row ++;

            if ($in_a_row == $field_size) {
                print ("Winner: ", $active_mover, " \n");
                return 1;
            }
        }
    }
   
    $in_a_row = 0;
    for (my $i = $column; $i < $field_size * $field_size; $i += $field_size) {
        if ($i ~~ @player_moves) {
            $in_a_row ++;
            if ($in_a_row == $field_size) {
                print ("Winner: ", $active_mover, " \n");
                return 1;
            }
        }
    }
    
    
    #if (!$field_id % ($field_size + 1) == 0) {
     #   return 0;
    #}

    $in_a_row = 0;
    for (my $i = 0; $i < $field_size * $field_size; $i += ($field_size+1)) {
        print("I: ", $i, "\n");
        print("Player Moves: ", @player_moves, "\n");
        if ($i ~~ @player_moves) {
            $in_a_row ++;

            if ($in_a_row == $field_size) {
                print ("Winner: ", $active_mover, " \n");
                return 1;
            }
        }
    }


    $in_a_row = 0;
    for (my $i = $field_size - 1; $i < $field_size * $field_size; $i += ($field_size-1)) {
        if ($i ~~ @player_moves) {
            $in_a_row ++;
            if ($in_a_row == $field_size) {
                print ("Winner: ", $active_mover, " \n");
                return 1;
            }
        }
    }
    
#    for (my $i = $column * $field_size; $i < $field_size * ($column + 1); $i++) {
#        for my $move (@player_moves) {
#            if ($move+$field_size == $i) {
#                $in_a_row ++;
#
    #            if ($in_a_row == $field_size) {
    #                print ("Winner: ", $active_mover, " \n");
    #                return 1;
    #            }
    #        }   
    #    }
    #}



    #for (my $i = 0; $i < $field_size; $i++) {
    #    for (my $j = 0; $j < $field_size; $j++) {
    #        if ($row == $i && $column == $j) {
    #            if (($x_moves_row == $i && $x_moves_column == $j) || ($o_moves_row == $i && $o_moves_column == $j)) {
    #                return 1;
    #            }
    #        }
    #    }
    #}
    #print ("Row: ", $row, ", Column: ", $column, " \n");

}

sub no_moves_left {
    my ($field_size, $used_fields) = @_;
    if ($used_fields == $field_size*$field_size) {
        return 1;
    }

}

sub show_win_msg {
    my ($winner, $frame) = @_;
    my $win_label;

    if ($winner eq 'x') {
        $win_label = $frame->Label(
            -text  => "X wins!",
            -font  => ['Helvetica', 48, 'bold'],
            -fg    => 'red',
            -bg    => 'yellow',
        )->place(-x => 50, -y => 200);

    } elsif ($winner eq 'o') {
        $win_label = $frame->Label
        (-text  => "O wins!",
        -font  => ['Helvetica', 48, 'bold'],
        -fg    => 'red',
        -bg    => 'yellow',
        )->place(-x => 50, -y => 200);

    } else {
        $win_label = $frame->Label
        (-text  => "Draw",
        -font  => ['Helvetica', 48, 'bold'],
        -fg    => 'red',
        -bg    => 'yellow',
        )->place(-x => 50, -y => 200);
    }

    $frame->after (1000, sub {
        $win_label->destroy();
    })
    
}

1;