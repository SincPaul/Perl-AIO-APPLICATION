package sudoku;

use strict;
use warnings;
use List::Util 'shuffle';
use Time::HiRes qw(time);

use GAMES::SUDOKU::humansolver;

my $timeout = 10;
my $active_button;
my @active_buttons;
my @active_cols;
my @active_rows;
my @fixed_cols;
my @fixed_rows;
my $active_row;
my $active_col;
my @missmatches = ();
my $missmatch;
my $temp_button;
my @old_missmatch_buttons = ();
my @new_grid;
my @fixed_buttons_coords = ();
my @fixed_buttons = ();
my $lives = 3;
my @number_buttons = ();
my @empty_buttons = ();
my %technique_cost = (
    sct => [100, 100],
    spt => [100, 100],
    clt => [350, 200],
    dpt => [500, 250],
    mlt => [700, 400],
    dj2 => [750, 500],
    us2 => [1500, 1200],
    dj3 => [2000, 1400],
    us3 => [2400, 1600],
    xwg => [2800, 1600],
    fct => [4200, 2100],
    dj4 => [5000, 4000],
    us4 => [7000, 5000],
    sf4 => [8000, 6000]
);

my %difficulty_ranges = (
    0   => [3600, 4500],
    1   => [4300, 5500],
    2   => [5300, 6900],
    3   => [6500, 9300],
    4   => [8300, 14000],
    5   => [11000, 25000],
);


my @working_sukodu_grid = (    
    [5, 6, 3, 8, 7, 9, 2, 1, 4],
    [7, 1, 9, 4, 2, 3, 6, 5, 8],
    [2, 8, 4, 5, 6, 1, 3, 9, 7],
    [4, 2, 6, 1, 5, 7, 9, 8, 3],
    [1, 9, 5, 6, 3, 8, 4, 7, 2],
    [8, 3, 7, 2, 9, 4, 1, 6, 5],
    [9, 4, 8, 3, 1, 5, 7, 2, 6],
    [6, 5, 1, 7, 4, 2, 8, 3, 9],
    [3, 7, 2, 9, 8, 6, 5, 4, 1]
);

sub start {
    my ($frame) = @_;

    choose_difficulty($frame);
}

sub choose_difficulty {
    my ($frame) = @_;
    my $difficulty = 0;

    my $difficulty_select = $frame->Toplevel();
    $difficulty_select->geometry("380x380");
    $difficulty_select->title("Select Difficulty");

    my $label = $difficulty_select->Label(
        -text => "Choose Difficulty?",
        -font => ['Arial', 14]
    )->pack(
        -pady => 20,
    );

    

    my $label_frame = $difficulty_select->Frame(
    -background => 'grey'
    )->pack(
        -padx => 10,
        -pady => 10,
        -fill => 'x',
        -expand => 1
    );

    # Create and pack the difficulty label in the label frame
    my $difficulty_label = $label_frame->Label(
        -text => "Difficulty: Beginner"
    )->pack(
        -padx => 10,
        -pady => 10,
        -fill => 'x',
        -expand => 1
    );

    # Create a frame to hold the buttons and use grid for layout
    my $button_frame = $difficulty_select->Frame(
        -background => 'grey'
    )->pack(
        -padx => 10,
        -pady => 10,
        -expand => 1,
        -fill => 'both'
    );

    # Define the buttons and their layout
    my @buttons = (
        { text => "Beginner", value => 0 },
        { text => "Easy", value => 1 },
        { text => "Medium", value => 2 },
        { text => "Tricky", value => 3 },
        { text => "Fiendish", value => 4 },
        { text => "Diabolical", value => 5 },
    );

    my $row = 0;
    my $col = 0;

    foreach my $button_info (@buttons) {
        my $button = $button_frame->Button(
            -text => $button_info->{text},
            -font => ['Arial', 14],
            -command => sub {
                $difficulty = $button_info->{value};
                $difficulty_label->configure(-text => "Difficulty: $button_info->{text}");
            }
        );
        
        $button->grid(
            -row => $row,
            -column => $col,
            -padx => 10,
            -pady => 10,
            -sticky => 'ew'
        );

        $col++;
        if ($col > 2) {
            $col = 0;
            $row++;
        }
    }

    my $start_button = $difficulty_select->Button(
        -text => "Start Game",
        -font => ['Arial', 14],
        -command => sub {
            generate_gui($frame, $difficulty);
            $difficulty_select->destroy();
        }
    )->pack(
        -pady => 20,
    );
}

sub generate_gui {
    my ($frame, $difficulty) = @_;
    
    my $sudoku_child = $frame->Toplevel();
    $sudoku_child->title("Sudoku");
    $sudoku_child->geometry("560x750");

    $sudoku_child->raise();      # Bring Sudoku window to the front
    $sudoku_child->deiconify();

    #$frame->Lower();

    $sudoku_child->update(); 

    main_gui($frame, $sudoku_child, $difficulty);   
}

sub main_gui {
    my ($frame, $sudoku_child, $difficulty) = @_;

    destroy_childs($sudoku_child);

    my $main_frame = create_main_frame($sudoku_child);

    my $top_frame = create_top_frame($main_frame);

    my $sudoku_label = create_sudoku_label($top_frame);

    my $difficulty_label = create_difficulty_label($top_frame, $difficulty);

    my $lives_label = create_lives_label($top_frame, $lives);

    my $sudoku_frame = create_sudoku_frame($main_frame);

    my $number_frame = create_number_frame($main_frame);

    create_number_buttons ($number_frame, $sudoku_child, $sudoku_frame, $lives_label);

    my $utility_frame = create_utility_frame($main_frame);

    my $restart_button = create_restart_button($utility_frame, $sudoku_child, $difficulty, $sudoku_frame, $lives_label, $sudoku_label, $difficulty_label  );

    my $choose_difficulty_button = create_choose_difficulty_button($utility_frame, $sudoku_child, $frame);

    my $exit_button = create_exit_button($utility_frame, $sudoku_child);


    start_game($difficulty, $sudoku_frame, $sudoku_label, $lives_label, $frame, $difficulty_label, $sudoku_child);
}

sub destroy_childs {
    my ($sudoku_child) = @_;

    if ($sudoku_child->children) {
        foreach my $child ($sudoku_child->children) {
            print("Child $child destroyed\n");
            $child->destroy();

        }
    }
}

sub create_main_frame {
    my ($frame) = @_;

    my $main_frame = $frame->Frame(
        -borderwidth => 2,
        -relief => 'raised',
        -background => 'yellow',
    )->pack(
        -side => 'top',
        -anchor => 'nw',
        #-padx => 10,
        #-pady => 10,
        -fill => 'both',
    );

    return $main_frame;
}

sub create_top_frame {
    my ($frame) = @_;

    my $top_frame = $frame->Frame(
        -borderwidth => 2,
        -relief => 'raised',
        -background => 'red',
    )->pack(
        -side => 'top',
        -anchor => 'nw',
        #-padx => 10,
        #-pady => 10,
        -fill => 'x',
    );

    return $top_frame;
}

sub create_sudoku_label {
    my ($frame) = @_;

    my $sudoku_label = $frame->Label(
        -text => "Sudoku ",
    )->pack(
        -side => 'left',
        -anchor => 'nw',
        -padx => [40, 0],
        #-pady => 10,
        #-fill => 'x',
    );

    return $sudoku_label;
}

sub create_difficulty_label {
    my ($frame, $difficulty) = @_;

    my $difficulty_written =    $difficulty == 0 ? "beginner" :
                                $difficulty == 1 ? "easy" :
                                $difficulty == 2 ? "medium" : 
                                $difficulty == 3 ? "tricky" :
                                $difficulty == 4 ? "fiendish" :
                                $difficulty == 5 ? "diabolical" : "undef";

    my $difficulty_label = $frame->Label(
        -text => "Difficulty: ".  $difficulty_written,

    )->pack(
        -side => 'left',
        -anchor => 'nw',
        -padx => [10, 10],
        #-pady => 10,
        -fill => 'x',
        -expand => 1
    );

    return $difficulty_label;
}

sub create_lives_label {
    my ($frame, $lives) = @_;

    my $lives_label = $frame->Label(
        -text => "Lives: $lives",
    )->pack(
        -side => 'right',
        -anchor => 'nw',
        -padx => [0, 40],
        #-pady => 10,
        #-fill => 'x',
    );

    return $lives_label;
}

sub create_sudoku_frame {
    my ($frame) = @_;

    my $sudoku_frame = $frame->Frame(
        -borderwidth => 2,
        -relief => 'raised',
        -background => 'black',
        -width => 528,
        -height => 528,
    )->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => [10, 10],

        -fill => 'both',
    );

    return $sudoku_frame;
}

sub create_number_frame {
    my ($frame) = @_;

    my $number_frame = $frame->Frame(
        -borderwidth => 2,
        -relief => 'raised',
        -background => 'blue',
    )->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
    );
    

    return $number_frame;
}

sub create_number_buttons {
    my ($frame, $sudoku_child, $sudoku_frame, $lives_label) = @_;

    my $numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    for my $number (@$numbers) {
        my $padx = 1;
            if ($number % 3 == 0 && $number != 9) {
                 $padx = [1, 5];
            }
        my $button = $frame->Button(
            -image => $sudoku_child->Photo(-file => "src/sudoku/".$number.".png"),
            -font => ['Arial', 14],
        )->pack(-side => 'left', -padx => $padx);
        $button->configure(
            -command => sub {
                #$number_frame->destroy();
                print "$number clicked\n";
                set_number($number, $sudoku_frame, $lives_label, $frame);
            }
        );
        $number_buttons[$number] = $button;
    }
}

sub create_utility_frame {
    my ($frame) = @_;

    my $utility_frame = $frame->Frame(
        -borderwidth => 2,
        -relief => 'raised',
        -background => 'green',
    )->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
    );

    return $utility_frame;
}

sub create_restart_button {
    my ($frame, $sudoku_child, $difficulty, $sudoku_frame, $lives_label, $sudoku_label, $difficulty_label) = @_;

    my $restart_button = $frame->Button(
        -text => "Restart",
        -font => ['Arial', 14],
        -command => sub {
            light_reset_active_state($lives_label);
            unlock_buttons($sudoku_frame);
            kill_toplevels($sudoku_frame);
            $sudoku_label->configure(
                -text => "Generating field..."
            );
            $sudoku_label->update();
            print("LUL");
            # ! TODO ! AHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH  
            create_empty_test_grid($sudoku_frame);
            start_game($difficulty, $sudoku_frame, $sudoku_label, $lives_label, $frame, $difficulty_label, $sudoku_child);
            #reset_gui($frame, $sudoku_child, $difficulty);

            print "Restart clicked\n";
        }
    )->pack(
        -side => 'left',
        -padx => 20
    );

    return $restart_button;
}

sub kill_toplevels {
    my ($frame) = @_;
    
    foreach my $child ($frame->children) {
        if ($child->isa('Tk::Toplevel')) {
            $child->destroy;
        }
    }
}

sub create_choose_difficulty_button {
    my ($utility_frame, $sudoku_child, $frame) = @_;

    my $choose_difficulty_button = $utility_frame->Button(
        -text => "Change difficulty",
        -font => ['Arial', 14],
        -command => sub {
            reset_active_state();
            
            $sudoku_child->destroy();
            choose_difficulty($frame);
        }
    )->pack(
        -side => 'left',
        -padx => 20
    );

    return $choose_difficulty_button;
}

sub create_exit_button {
    my ($frame, $sudoku_child) = @_;

    my $exit_button = $frame->Button(
        -text => "Exit",
        -font => ['Arial', 14],
        -command => sub {
            $sudoku_child->destroy();
        }
    )->pack(
        -side => 'left',
        -padx => 20
    );
}
sub start_game {
    my ($difficulty, $sudoku_frame, $sudoku_label, $lives_label, $frame, $difficulty_label, $sudoku_child) = @_;

    #print ("Difficulty: $difficulty \n");
    #my $difficulty_written =    $difficulty == 0 ? "easy" :
    #                            $difficulty == 1 ? "medium" :
    #                            $difficulty == 2 ? "hard" : "undef";
    #$difficulty_label->configure(
    #    -text => "Difficulty: ". $difficulty_written. " \n"
    #);

    #$sudoku_child->deiconify();  # Make sure it's not minimized
    #$sudoku_child->raise();      # Bring the frame to the front
    #$sudoku_child->update(); 

    my $start_creation_time = start_creation_stopwatch();
    print ("Start creation time after stopwatch: $start_creation_time \n");

    #$sudoku_child->after(100, sub {
        generate_field($difficulty, $sudoku_frame, $sudoku_label, $frame, $start_creation_time);
    #});

}

sub start_creation_stopwatch {
    my $start_creation_time = time();
    print "Start creation time 1: $start_creation_time\n";
    return $start_creation_time;
}
sub reset_active_state {
    $active_button = undef;
    $active_row = undef;
    $active_col = undef;
    @old_missmatch_buttons = ();
    $active_button = undef;
    @active_buttons = ();
    @active_cols = ();
    @active_rows = ();
    @fixed_cols = ();
    @fixed_rows = ();
    $active_row = undef;
    $active_col = undef;
    @missmatches = ();
    $missmatch = undef;
    $temp_button = undef;
    @old_missmatch_buttons = ();
    @new_grid = ();
    @fixed_buttons_coords = ();
    @fixed_buttons = ();
    @number_buttons = ();
    $lives = 3;
    @empty_buttons = ();

}

sub light_reset_active_state {
    my ($lives_label) = @_;

    $active_button = undef;
    $active_row = undef;
    $active_col = undef;
    @old_missmatch_buttons = ();
    $active_button = undef;
    @active_buttons = ();
    @active_cols = ();
    @active_rows = ();
    @fixed_cols = ();
    @fixed_rows = ();
    $active_row = undef;
    $active_col = undef;
    @missmatches = ();
    $missmatch = undef;
    $temp_button = undef;
    @old_missmatch_buttons = ();
    @new_grid = ();
    @fixed_buttons_coords = ();
    @fixed_buttons = ();
    $lives = 3;
    @empty_buttons = ();

    $lives_label->configure(
        -text => "Lives: ". $lives
    );
}

sub generate_field {
    my ($difficulty, $sudoku_frame, $sudoku_label, $frame, $start_creation_time) = @_;

    #create_empty_test_grid($sudoku_frame);
     print "Passed start_creation_time: $start_creation_time\n";
    
    print "Generating field...\n";
    $sudoku_label->configure(
        -text => "Generating field..."
    );

    $sudoku_frame->update();

    generate_random_field($difficulty, $sudoku_frame, $sudoku_label, $frame);

    my $creation_time = stop_creation_time($start_creation_time);
    print("Time to create field: $creation_time seconds \n");
    $sudoku_label->configure(
        -text => "Sudoku"
    );

}

sub stop_creation_time {
    my ($start_creation_time) = @_;

    my $stop_creation_time = time();
    print "Start creation time: $start_creation_time \n";
    print "Stop creation time: $stop_creation_time \n";

    my $creation_time = $stop_creation_time - $start_creation_time;
    return $creation_time;
}
sub create_empty_test_grid {
    my ($sudoku_frame) = @_;
    my $field_id = 0;
    for my $row (1..9) {
        for my $col (1..9) {
            my $padx = 1;
            if ($col % 3 == 0 && $col != 9) {
                 $padx = [1, 5];
            }
            
            my $pady = 1;
            if ($row % 3 == 0 && $row != 9) {
                $pady = [1, 5];
            }
           
            my $button = $sudoku_frame->Button(
                -image => $sudoku_frame->Photo(-file => "src/sudoku/blank.png"),
                -background => 'white',
                -font => ['Arial', 14],
            )->grid(
                -row => $row -1,
                -column => $col -1,
                -padx => $padx,
                -pady => $pady
            );

            $button->configure(
                -command => sub {
                    print "$row, $col clicked\n";
                    set_active($row-1, $col-1, $button, $sudoku_frame);
                }
            );

            $empty_buttons[$row-1][$col-1] = $button;
           $field_id++;
       }
    }
}

sub create_buttons {
    my ($sudoku_frame, $grid, $frame) = @_;

    my $field_id = 0;
    
    for my $row (1..9) {
        for my $col (1..9) {
            my $padx = 1;
            if ($col % 3 == 0 && $col != 9) {
                 $padx = [1, 5];
            }
            
            my $pady = 1;
            if ($row % 3 == 0 && $row != 9) {
                $pady = [1, 5];
            }
           
            #my $state = 'disabled';
            my $edited_number;
            my $number = $grid->[$row-1][$col-1];
            if ($number == 0) {
                $edited_number = "blank";
                #$state = 'normal';
                $fixed_buttons_coords[$row-1][$col-1] = 0;
            }
            else {
                $fixed_buttons_coords[$row-1][$col-1] = 1;
                
                $edited_number = "fixed".$number
            }

            my $button = $sudoku_frame->Button(
                -image => $sudoku_frame->Photo(-file => "src/sudoku/".$edited_number.".png"),
                -background => 'white',
                -font => ['Arial', 14],
                #-state => $state
            )->grid(
                -row => $row -1,
                -column => $col -1,
                -padx => $padx,
                -pady => $pady
            );

            $button->configure(
                -command => sub {
                    print "$row, $col clicked\n";
                    set_active($row-1, $col-1, $button, $sudoku_frame, $frame);
                }
            );


            $fixed_rows[$row-1][$col-1] = $number;
            $fixed_cols[$row-1][$col-1] = $number;

            $fixed_buttons[$row-1][$col-1] = $button;

            #print("Number $number at $row, $col\n");

           $field_id++;
       }
    }

}
sub generate_random_field {
    my ($difficulty, $sudoku_frame, $sudoku_label, $frame) = @_;

    @new_grid = map { [@$_] } @working_sukodu_grid ;

    
    
#   for my $row (@new_grid) {
#       print join(" ", @$row), "\n";
#   }

    rotate_grid(\@new_grid, int(rand(4)));
#    print "\nRotated grid\n";
#    for my $row (@new_grid) {
#        print join(" ", @$row), "\n";
#    }

    mirror_grid(\@new_grid, int(rand(2)), int(rand(2)));
#   print "\nMirrored grid\n";
#   for my $row (@new_grid) {
#       print join(" ", @$row), "\n";
#   }

    shuffle_blocks(\@new_grid);
#    print "\nShuffled blocks\n";
#    for my $row (@new_grid) {
#        print join(" ", @$row), "\n";
#    }


    cipher_numbers(\@new_grid);
#    print "\nCiphred grid\n";
#    for my $row (@new_grid) {
#        print join(" ", @$row), "\n";
#    }

    if (!is_valid_sudoku(\@new_grid)) {
        print "Invalid sudoku\n";
        print "Generating new sudoku\n";
        print "Invalid sudoku\n";
        print "Generating new sudoku\n";
        print "Invalid sudoku\n";
        print "Generating new sudoku\n";
        print "Invalid sudoku\n";
        print "Generating new sudoku\n";
        generate_random_field($difficulty, $sudoku_frame, $sudoku_label, $frame);
    }

    remove_numbers(\@new_grid, $difficulty, $sudoku_frame, $sudoku_label, $frame);
#    print "\nRemoved numbers\n";
#    for my $row (@new_grid) {
#        print join(" ", @$row), "\n";
#    }
    
    my @grading_puzzle = map { [@$_] } @new_grid;

    my @test_1_grid = (    
    [9, 3, 4, 0, 6, 0, 0, 5, 0],
    [0, 0, 6, 0, 0, 4, 9, 2, 3],
    [0, 0, 8, 9, 0, 0, 0, 4, 6],
    [8, 0, 0, 5, 4, 6, 0, 0, 7],
    [6, 0, 0, 0, 1, 0, 0, 0, 5],
    [5, 0, 0, 3, 9, 0, 0, 6, 2],
    [3, 6, 0, 4, 0, 1, 2, 7, 0],
    [4, 7, 0, 6, 0, 0, 5, 0, 0],
    [0, 8, 0, 0, 0, 0, 6, 3, 4]
);

    my @test_grid = map { [@$_] } @test_1_grid;

    #my $total_difficulty = HUMANSOLVER::grade_puzzle(\@test_1_grid);

    create_buttons($sudoku_frame, \@new_grid, $frame);

    
}





sub rotate_grid {
    my ($grid, $rotations) = @_;

    for my $i (1..$rotations) {
        my @rotated_grid;

        for my $row (0..8) {
            for my $col (0..8) {
                $rotated_grid[$col][8-$row] = $grid->[$row][$col];
            }
        }
        @$grid = @rotated_grid;
    }
}

sub mirror_grid {
    my ($grid, $mirror_x, $mirror_y) = @_;

    my @mirrored_grid =  map { [@$_] } @$grid;

    if ($mirror_x == 1) {
        for my $row (0..8) {
            for my $col (0..8) {
                $mirrored_grid[$row][$col] = $grid->[$row][8 - $col];
            }
        }
    }

    if ($mirror_y == 1) {
        for my $row (0..8) {
            for my $col (0..8) {
                $grid->[$row][$col] = $mirrored_grid[8 - $row][$col];
            }
        }
    } else {
        @$grid = @mirrored_grid;
    }

}

sub shuffle_blocks {
    my ($grid) = @_;
    
    shuffle_rows($grid);
    shuffle_cols($grid);
}

sub shuffle_rows {
    my ($grid) = @_;

    
    my @row_order = (0, 1, 2);  
    @row_order = shuffle(@row_order);  

    
    
    for my $i (0..2) {
        swap_rows($grid, $i, $row_order[$i]);       
        swap_rows($grid, 6 + $i, 6 + $row_order[$i]); 
    }

    my $is_swap_middle = int(rand(2));
    if ($is_swap_middle == 1) {
        swap_rows($grid, 3, 5);
    }
    
}

sub swap_rows {
    my ($grid, $r1, $r2) = @_;
    my @temp_row = @{$grid->[$r1]};
    $grid->[$r1] = [@{$grid->[$r2]}];
    $grid->[$r2] = \@temp_row;
}

sub shuffle_cols {
    my ($grid) = @_;

    my @col_order = (0, 1, 2);
    @col_order = shuffle(@col_order);

    for my $i (0..2) {
        swap_cols($grid, $i, $col_order[$i]);
        swap_cols($grid, 6 + $i, 6 + $col_order[$i]);
    }

    my $is_swap_middle = int(rand(2));
    if ($is_swap_middle == 1) {
        swap_cols($grid, 3, 5);
    }
}

sub swap_cols {
    my ($grid, $c1, $c2) = @_;

    for my $row (0..8) {
        my $temp = $grid->[$row][$c1];
        $grid->[$row][$c1] = $grid->[$row][$c2];
        $grid->[$row][$c2] = $temp;
    }

}


sub cipher_numbers {
    my ($grid) = @_;

    my %cipher;

    my @numbers = shuffle(1..9);
    @cipher{@numbers} = (1..9);

#    #print "Cipher mapping:\n";
#    while (my ($key, $value) = each %cipher) {
#        print "$key -> $value\n";
#    }


    for my $row (0..8) {
        for my $col (0..8) {
            $grid->[$row][$col] = $cipher{$grid->[$row][$col]};
        }
    }

    print "Ciphered Grid:\n";
    for my $row (0..8) {
        print join(' ', @{$grid->[$row]}) . "\n";
    }
}

sub remove_numbers {
    my ($grid, $difficulty, $sudoku_frame, $sudoku_label, $frame) = @_;

    my $pairs_to_remove = ($difficulty == 0) ? 1 : ($difficulty == 1) ? 20 : 35;
    my @previous_grid;
    my $center_cell_removed = 0;

    my $removed_pairs = 0;

    my $start_time = time();

    while ($removed_pairs < $pairs_to_remove) {
        if (time()-$start_time <! $timeout){
            generate_random_field($difficulty, $sudoku_frame, $sudoku_label, $frame)
        }
        @previous_grid = map { [@$_] } @$grid; 

        my $row = int(rand(9));
        my $col = int(rand(9));
        next if $grid->[$row][$col] == 0;

        my $sym_row = 8 - $row;
        my $sym_col = 8 - $col;

        my $val1 = $grid->[$row][$col];
        my $val2 = $grid->[$sym_row][$sym_col];

        $grid->[$row][$col] = 0;
        $grid->[$sym_row][$sym_col] = 0;

        if (!is_solvable($grid)) {
            @$grid = map { [@$_] } @previous_grid;
        } else {
            $removed_pairs++;
        }
    }

#    for (1..$pairs_to_remove) {
#        
#
#        
#
#        my $rot_row = 8 - $row;
#        my $rot_col = 8 - $col;
#
#        $grid->[$row][$col] = 0;
#        $grid->[$rot_row][$rot_col] = 0;
#
#        if (!is_solvable($grid)) {
#            
#            @$grid = map { [@$_] } @previous_grid;
#            next;
#        }
#
#    }
#
#    my $remove_center_cell = int(rand(12));
#    if ($remove_center_cell == 5) {
#        unless ($center_cell_removed) {
#            $grid->[4][4] = 0;
#        }
#    }
}

# ! need to implement solver
sub is_solvable {
    my ($grid) = @_;
    my @grid_copy = map { [@$_] } @$grid; 
    return solve_sudoku(\@grid_copy);
}

sub solve_sudoku {
    my ($grid) = @_;

    for my $row (0..8) {
        for my $col (0..8) {
            if ($grid->[$row][$col] == 0) {
                for my $num (1..9) {
                    if (is_valid($grid, $row, $col, $num)) {
                        $grid->[$row][$col] = $num;
                        if (solve_sudoku($grid)) {
                            return 1;
                        }
                        $grid->[$row][$col] = 0;
                    }
                }
                return 0;
            }
        }
    }
    print("REMOVED NUMBERS IS SOLVABLE\n");
    return 1;
    
}

sub is_valid {
    my ($grid, $row, $col, $num) = @_;

    for my $c (0..8) {
        return 0 if $grid->[$row][$c] == $num;
    }

    for my $r (0..8) {
        return 0 if $grid->[$r][$col] == $num;
    }

    my $start_row = int($row / 3) * 3;
    my $start_col = int($col / 3) * 3;
    for my $r ($start_row .. $start_row + 2) {
        for my $c ($start_col .. $start_col + 2) {
            if ($grid->[$r][$c] == $num) {
                print("Not Valid\n");
                return 0;
            }

            
        }
    }

    return 1;
}

sub is_valid_sudoku {
    my ($grid) = @_;

    # Check rows and columns
    for my $i (0..8) {
        my %row_seen;
        my %col_seen;
        for my $j (0..8) {
            # Check row
            my $row_val = $grid->[$i][$j];
            return 0 if $row_seen{$row_val}++;
            
            # Check column
            my $col_val = $grid->[$j][$i];
            return 0 if $col_seen{$col_val}++;
        }
    }

    # Check 3x3 subgrids
    for my $box_row (0..2) {
        for my $box_col (0..2) {
            my %box_seen;
            for my $i (0..2) {
                for my $j (0..2) {
                    my $val = $grid->[$box_row * 3 + $i][$box_col * 3 + $j];
                    
                    return 0 if $box_seen{$val}++;
                }
            }
        }
    }

    print("VALID SUDOKU\n");
    return 1;  # Grid is valid
}


sub set_active {
    my ($row, $col, $button, $sudoku_frame, $frame) = @_;


    if ($active_button) {
        $active_button->configure(
            -background => 'white',
        )
    }

    $active_button = $button;

    $active_row = $row;
    $active_col = $col;

    $active_button->configure(
        -background => 'grey',
    )
}

sub set_number {
    my ($number, $sudoku_frame, $lives_label, $frame) = @_;

    if (!$active_button) {
        return;
    }

    my ($row, $col) = ($active_row, $active_col);

    if ($fixed_buttons_coords[$row][$col] && $fixed_buttons_coords[$row][$col] == 1) {
        print("Cant change fixed fields\n");
        return;
    }
    if (!can_place($row, $col, $number)) {

        if (@old_missmatch_buttons) {
            foreach my $missmatch_button (@old_missmatch_buttons) {
                $missmatch_button->configure(
                    -background => 'white',
                    #-image => $sudoku_frame->Photo(-file => "src/sudoku/blank.png")
                )
            }
        }

        show_interrupting_fields();

        print("Temp Button: ", $temp_button, "\n");
        if ($temp_button) {
            $temp_button->configure(
                -image => $sudoku_frame->Photo(-file => "src/sudoku/blank.png")
            );
        }


        $active_button->configure(
            -image => $sudoku_frame->Photo(-file => "src/sudoku/red".$number.".png"),
            -background => 'red'
        );
        $temp_button = $active_button;

        remove_life($lives_label, $frame, $sudoku_frame);
        # ! -1 leben
        print("Error, can't place number\n");
        return;
    }
    if ($temp_button) {
        print("TEMPPPPPPPP");
        $temp_button->configure(
            -background => 'white',
            -image => $sudoku_frame->Photo(-file => "src/sudoku/blank.png")
        )
    }
    
    $active_button->configure(
        -image => $sudoku_frame->Photo(-file => "src/sudoku/".$number.".png")
    );
    $active_buttons[$row][$col] = $active_button;

    
    

    if (@old_missmatch_buttons) {
        foreach my $missmatch_button (@old_missmatch_buttons) {
            $missmatch_button->configure(
                -background => 'white',
                #-image => $sudoku_frame->Photo(-file => "src/sudoku/blank.png")
            )
        }
    }

    check_win($sudoku_frame);
}

sub check_win {
    my ($sudoku_frame) = @_;

    for my $row (0..8) {
        for my $col (0..8) {
            if (!$active_buttons[$row][$col] && !$fixed_buttons_coords[$row][$col]) {
                print("No active or fixed button at Row: $row, Col: $col\n");
                return;  
            }
        }
    }

    if (correct_layout()) {
        show_win_screen($sudoku_frame);
    }
}

# ! need to implement
sub correct_layout {
    my $correct = 1;
    return $correct;
}

sub show_win_screen {
    my ($sudoku_frame) = @_;

    my $win_screen = $sudoku_frame->Toplevel();
    $win_screen->title("GGs");
    $win_screen->Label(
        -text => "You Won, ff15 go next.",
        -background => 'green',
        -font => ['Arial', 20]
    )->pack();

    lock_buttons();
}
sub remove_life {
    my ($lives_label, $frame, $sudoku_frame) = @_;
    $lives = $lives - 1;
    $lives_label->configure(-text => "Lives: ".$lives);

    if ($lives == 0) {
        game_over_screen($frame, $sudoku_frame);
        
    }
}
sub game_over_screen {
    my ($frame, $sudoku_frame) = @_;

    my $defeat_screen = $sudoku_frame->Toplevel();
    $defeat_screen->title("Game Over");
    $defeat_screen->Label(
        -text => "You Lost, ff15 go next.",
        -background => 'red',
        -font => ['Arial', 20]
    )->pack();
    lock_buttons($sudoku_frame); 


}

sub lock_buttons {
    my ($frame) = @_;
    print("Locking Buttons\n");
    for my $num (1..9) {
        $number_buttons[$num]->configure(-state => 'disabled');
    }
    

    for my $row (0..8) {
        for my $col (0..8) {
            
            
            if ($active_buttons[$row][$col]) {
                $active_buttons[$row][$col]->configure(
                    -background => 'purple',
                    -state => 'disabled'
                );
            } elsif ($fixed_buttons_coords[$row][$col]) {
                $fixed_buttons[$row][$col]->configure(
                    -background => 'green',
                    -state => 'disabled'
                );
            }
            elsif ($fixed_buttons[$row][$col]) {
                $fixed_buttons[$row][$col]->configure(
                    -background => 'yellow',
                    -state => 'disabled',
                    -image => $frame->Photo(-file => "src/sudoku/blank.png")
                );
            }
            else {
                $empty_buttons[$row][$col]->configure(
                    -background => 'black',
                    -state => 'disabled',
                    -image => $frame->Photo(-file => "src/sudoku/blank.png")
                )
            }  
        }
    }
}

sub unlock_buttons {
    my ($frame) = @_;
    print("UnLocking Buttons\n");
    for my $num (1..9) {
        $number_buttons[$num]->configure(-state => 'normal');
    }
}
sub can_place {
    my ($row, $col, $number) = @_;
    $missmatch = undef;
    
    if (($active_rows[$row][$col] && $active_rows[$row][$col] == $number) || 
        ($fixed_rows[$row][$col] && $fixed_rows[$row][$col] == $number)) {
        print("Number already exists at ($row, $col), ignoring.\n");
        return 1;  
    }


    for my $i(0..8) {
        if (($active_rows[$row][$i] && $active_rows[$row][$i] == $number) || ($fixed_rows[$row][$i] && $fixed_rows[$row][$i] == $number)) {
            print("Error, Missmatch at ", $row+1, ", ", $i+1, ", row \n");
            print("Number for missmatch is: ", $number, "\n");
            print("At position ");
            #print("Active Rows: ", $active_rows[$row] ,"I: ", $i, "\n");
            push @missmatches, [$row, $i];
            $missmatch = 1;
            #return 0;
        }
    }
   
    for my $i(0..8) {
        if (defined $active_cols[$i][$col] && $active_cols[$i][$col] == $number) {
            print("Error, Missmatch at ", $i+1, ", ", $col+1, ", Column, Active \n");
            print("Number for missmatch is: ", $number, "\n");
            print("At position ");
            #print("Active Cols: ", $active_cols[$col] ,"I: ", $i, "\n");
            
            push @missmatches, [$i, $col];
            $missmatch = 1;
        }
        elsif (defined $fixed_cols[$i][$col] && $fixed_cols[$i][$col] == $number) {
            print("Error, Missmatch at ", $i+1, ", ", $col+1, ", Column, Fixed \n");
            print("Number for missmatch is: ", $number, "\n");
            print("At position ");
            #print("Fixed Cols: ", $fixed_cols[$col] ,"I: ", $i, "\n");
            push @missmatches, [$i, $col];
            $missmatch = 1;
        }
    }

    my $start_row = int($row/3) *3;
    my $start_col = int($col/3) *3;

    print("Start Row: ", $start_row, "Start Col: ", $start_col, "\n");


    for my $i($start_row .. $start_row+2) {
        for my $j($start_col .. $start_col+2) {
            if ($active_rows[$i][$j] && $active_rows[$i][$j] == $number || $fixed_rows[$i][$j] && $fixed_rows[$i][$j] == $number) {
                print("Error, Missmatch at ", $i+1, ", ", $j+1, ", 3x3 \n");
                print("Number for missmatch is: ", $number, "\n");
                print("At position ");
                push @missmatches, [$i, $j];
                $missmatch = 1;
            }
        }
    }

    if ($missmatch) {
        return 0;
    }

    print("Allowed Move");
    
    $active_rows[$row][$col] = $number;
    $active_cols[$row][$col] = $number;
    return 1;

}


sub show_interrupting_fields {
    foreach my $missmatch (@missmatches) {
        my ($row, $col) = @$missmatch;

        print("coloring Missmatch: ", $row+1, ", ", $col+1, "\n");

         my $missmatch_button = $active_buttons[$row][$col]
            ? $active_buttons[$row][$col]
            : $fixed_buttons[$row][$col];

        if ($missmatch_button) {
            $missmatch_button->configure(
                -background => 'orange',
            );
            push @old_missmatch_buttons, $missmatch_button;
        }
    }
    @missmatches = ();
    

}
1;