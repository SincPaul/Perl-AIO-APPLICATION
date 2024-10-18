package humansolver;

use strict;
use warnings;

sub grade_puzzle {
    my ($grid) = @_;

    my $total_difficulty = 0;
    my $solved = 0;
    my $pencilmarks = generate_pencilmarks($grid);
    my $first_candidate_lines = 1;
    my $first_double_pairs = 1;
    my $first_multiple_lines = 1;
    my $first_naked_pair = 1;
    my $first_hidden_pair = 1;
    my $first_naked_triple = 1;
    my $first_hidden_triple = 1;
    my $first_x_wing = 1;
    my $first_forcing_chains = 1;
    my $first_naked_quad = 1;
    my $first_hidden_quad = 1;
    my $first_swordfish = 1;
    my $retried = 0;

    while (!$solved) {
        my $is_used_technique = 0;

        if (single_candidate_technique($grid, $pencilmarks)) {
            $is_used_technique = 1;
            $total_difficulty += 100;
            $retried = 0;  
            print("Single candidate applied, difficulty: $total_difficulty\n");
        }

        if (!$is_used_technique && single_position_technique($grid, $pencilmarks)) {
            $is_used_technique = 1;
            $total_difficulty += 100;  
            $retried = 0;
            print("Single position applied, difficulty: $total_difficulty\n");
        }

        if (!$is_used_technique && candidate_lines_technique($grid, $pencilmarks)) {
            $is_used_technique = 1;
            $total_difficulty += $first_candidate_lines ? 350 : 200;  
            $first_candidate_lines = 0;
            $retried = 0;
            print("Candidate lines applied, difficulty: $total_difficulty\n");
        }

        if (!$is_used_technique && double_pairs_technique($grid, $pencilmarks)) { 
            $is_used_technique = 1;
            $total_difficulty += $first_double_pairs ? 500 : 250;
            $first_double_pairs = 0;
            $retried = 0;
            print("Double pairs applied, difficulty: $total_difficulty\n");
        }

        if (!$is_used_technique && multiple_lines_technique($grid, $pencilmarks)) { 
            $is_used_technique = 1;
            $total_difficulty += $first_multiple_lines ? 700 : 400;
            $first_multiple_lines = 0;
            $retried = 0;
            print("Multiple lines applied, difficulty: $total_difficulty\n");
        }

        if (!$is_used_technique && naked_pair_technique($grid, $pencilmarks)) { 
            $is_used_technique = 1;
            $total_difficulty += $first_naked_pair ? 750 : 500;
            $first_naked_pair = 0;
            $retried = 0;
            print("Naked pair applied, difficulty: $total_difficulty\n");
        }

        if (!$is_used_technique && hidden_pair_technique($grid, $pencilmarks)) { 
            $is_used_technique = 1;
            $total_difficulty += $first_hidden_pair ? 1500 : 1200;
            $first_hidden_pair = 0;
            print("Hidden pair applied, difficulty: $total_difficulty\n");
        }

        if (!$is_used_technique && naked_triple_technique($grid, $pencilmarks)) { 
            $is_used_technique = 1;
            $total_difficulty += $first_naked_triple ? 2000 : 1400;
            $first_naked_triple = 0;
            $retried = 0;
            print("Naked triple applied, difficulty: $total_difficulty\n");
        }

        if (!$is_used_technique && hidden_triple_technique($grid, $pencilmarks)) { 
            $is_used_technique = 1;
            $total_difficulty += $first_hidden_triple ? 2400 : 1600;
            $first_hidden_triple = 0;
            $retried = 0;
            print("Hidden triple applied, difficulty: $total_difficulty\n");
        }

        if (!$is_used_technique && x_wing_technique($grid, $pencilmarks)) { 
            $is_used_technique = 1;
            $total_difficulty += $first_x_wing ? 2800 : 1600;
            $first_x_wing = 0;
            $retried = 0;
            print("X-Wing applied, difficulty: $total_difficulty\n");
        }

        if (!$is_used_technique && forcing_chains_technique($grid, $pencilmarks)) { 
            $is_used_technique = 1;
            $total_difficulty += $first_forcing_chains ? 4200 : 2100;
            $first_forcing_chains = 0;
            $retried = 0;
            print("Forcing chains applied, difficulty: $total_difficulty\n");
        }

        if (!$is_used_technique && naked_quad_technique($grid, $pencilmarks)) { 
            $is_used_technique = 1;
            $total_difficulty += $first_naked_quad ? 5000 : 4000;
            $first_naked_quad = 0;
            $retried = 0;
            print("Naked quad applied, difficulty: $total_difficulty\n");
        }

        if (!$is_used_technique && hidden_quad_technique($grid, $pencilmarks)) { 
            $is_used_technique = 1;
            $total_difficulty += $first_hidden_quad ? 7000 : 5000;
            $first_hidden_quad = 0;
            $retried = 0;
            print("Hidden quad applied, difficulty: $total_difficulty\n");
        }

        if (!$is_used_technique && swordfish_technique($grid, $pencilmarks)) { 
            $is_used_technique = 1;
            $total_difficulty += $first_swordfish ? 8000 : 6000;
            $first_swordfish = 0;
            $retried = 0;
            print("Swordfish applied, difficulty: $total_difficulty\n");
        }

        $solved = is_solved($grid);

        if (!$is_used_technique && !$solved) {
            $pencilmarks = generate_pencilmarks($grid);
            print("No technique applied. The puzzle might be unsolvable with current techniques. retrying 1 more time\n");
            print("Current state of the grid:\n");
            for my $row (@$grid) {
            print join(" ", @$row), "\n";
            }
            print_pencilmarks($pencilmarks);
            if ($retried > 0) {
                return;
            }
            $retried ++;
        }
        
    }

    return $total_difficulty;
}

sub single_candidate_technique {
    my ($grid, $pencilmarks) = @_;

    for my $row (0..8) {
        for my $col (0..8) {
            if ($grid->[$row][$col] == 0 && scalar(@{$pencilmarks->[$row][$col]}) == 1) {
                $grid->[$row][$col] = $pencilmarks->[$row][$col][0];
                my $number = $pencilmarks->[$row][$col][0];
                #print("SINGLE CANDIDATE at ($row, $col): ", $number, "\n");

                update_pencilmarks($pencilmarks, $grid, $number, $row, $col);

                return 1;
            }
        }
    }               
    return 0;
}

sub single_position_technique {
    my ($grid, $pencilmarks) = @_;

    if (find_single_position_in_row ($pencilmarks, $grid)) {
        return 1;
    }

    if (find_single_position_in_col ($pencilmarks, $grid)) {
        return 1;
    }

    if (find_single_position_in_box ($pencilmarks, $grid)) {
        return 1;
    }

    return 0;
}

sub candidate_lines_technique {
    my ($grid, $pencilmarks) = @_;
    my $changes = 0;

    for my $box_row (0..2) {
        for my $box_col (0..2) {
            my @box_num;

            for my $i (0..2) {
                for my $j (0..2) {
                    my $row = $box_row * 3 + $i;
                    my $col = $box_col * 3 + $j;

                    if ($grid->[$row][$col] != 0) {
                        next;
                    }

                    for my $number (@{$pencilmarks->[$row][$col]}) {
                        push @{$box_num[$number-1]} , [$row, $col];
                    }
                }
            }

            for my $number (1..9) {
                my $positions = $box_num[$number-1];

                if (!$positions) {
                    next;
                }

                my %row_count;
                my %col_count;

                foreach my $position (@$positions) {
                    my ($row, $col) = @$position;
                    $row_count{$row}++;
                    $col_count{$col}++;
                };

                my @single_rows = grep { $row_count{$_} == scalar @$positions } keys %row_count;
                if (@single_rows == 1) {
                    my $single_row = $single_rows[0];
                    #print("Single Row ($single_row): ", $number, "\n");

                    for my $col (0..8) {
                        if ($col >= $box_col * 3 && $col < ($box_col + 1) * 3) {
                            next;
                        }
                        my @new_pencilmarks = grep { $_ != $number } @{$pencilmarks->[$single_row][$col]};
                        if (@new_pencilmarks != @{$pencilmarks->[$single_row][$col]}) {
                            #print "Updating pencilmarks for row $single_row, col $col\n";
                            #print "For Number: ", $number, "\n";
                            $pencilmarks->[$single_row][$col] = \@new_pencilmarks;
                            $changes = 1;
                        }
                    }
                }

                my @single_cols = grep { $col_count{$_} == scalar @$positions } keys %col_count;
                if (@single_cols == 1) {
                    my $single_col = $single_cols[0];
                    #print("Single Col ($single_col): ", $number, "\n");

                    for my $row (0..8) {
                        if ($row >= $box_row * 3 && $row < ($box_row + 1) * 3) {
                            next;
                        }
                        my @new_pencilmarks = grep { $_ != $number } @{$pencilmarks->[$row][$single_col]};
                        if (@new_pencilmarks != @{$pencilmarks->[$row][$single_col]}) {
                            #print "Updating pencilmarks for row $row, col $single_col\n";
                            #print "For Number: ", $number, "\n";
                            $pencilmarks->[$row][$single_col] = \@new_pencilmarks;
                            $changes = 1;
                        }
                    }
                }
            }
        }
    }
    return $changes;
}

sub double_pairs_technique {
    my ($grid, $pencilmarks) = @_;
    my $changes = 0;

    # Check block columns
    for my $block_col (0, 3, 6) {
        for my $number (1..9) {
            my @cols_with_number;

            for my $block_row (0, 3, 6) {
                for my $row ($block_row..$block_row+2) {
                    for my $col ($block_col..$block_col+2) {
                        next if $grid->[$row][$col] != 0;

                        if (grep { $_ == $number } @{$pencilmarks->[$row][$col]}) {
                            push @cols_with_number, $col unless grep { $_ == $col } @cols_with_number;
                        }
                    }
                }
            }

            if (@cols_with_number == 2) {
                my ($col1, $col2) = @cols_with_number;
                my $third_col = 3 - int($col1 / 3) - int($col2 / 3) + $block_col;

                for my $block_row (0, 3, 6) {
                    for my $row ($block_row..$block_row+2) {
                        next if $grid->[$row][$third_col] != 0;

                        if (grep { $_ == $number } @{$pencilmarks->[$row][$third_col]}) {
                            @{$pencilmarks->[$row][$third_col]} = grep { $_ != $number } @{$pencilmarks->[$row][$third_col]};
                            $changes++;
                        }
                    }
                }
            }
        }
    }

    # Check block rows
    for my $block_row (0, 3, 6) {
        for my $number (1..9) {
            my @rows_with_number;

            for my $block_col (0, 3, 6) {
                for my $row ($block_row..$block_row+2) {
                    for my $col ($block_col..$block_col+2) {
                        next if $grid->[$row][$col] != 0;

                        if (grep { $_ == $number } @{$pencilmarks->[$row][$col]}) {
                            push @rows_with_number, $row unless grep { $_ == $row } @rows_with_number;
                        }
                    }
                }
            }

            if (@rows_with_number == 2) {
                my ($row1, $row2) = @rows_with_number;
                my $third_row = 3 - int($row1 / 3) - int($row2 / 3) + $block_row;

                for my $block_col (0, 3, 6) {
                    for my $col ($block_col..$block_col+2) {
                        next if $grid->[$third_row][$col] != 0;

                        if (grep { $_ == $number } @{$pencilmarks->[$third_row][$col]}) {
                            @{$pencilmarks->[$third_row][$col]} = grep { $_ != $number } @{$pencilmarks->[$third_row][$col]};
                            $changes++;
                        }
                    }
                }
            }
        }
    }

    return $changes;
}
#    my ($grid, $pencilmarks) = @_;
#    my $changes = 0;
#
#    for my $box_row (0..2) {
#        for my $box_col (0..2) {
#            my @box_num;
#
#            for my $i (0..2) {
#                for my $j (0..2) {
#                    my $row = $box_row * 3 + $i;
#                    my $col = $box_col * 3 + $j;
#
#                    if ($grid->[$row][$col] != 0) {
#                        next;
#                    }
#
#                    for my $number (@{$pencilmarks->[$row][$col]}) {
#                        push @{$box_num[$number-1]} , [$row, $col];
#                    }
#                }
#            }
#            
#            for my $number (1..9) {
#                my $positions = $box_num[$number-1];
#
#                if (!$positions || scalar @$positions != 2) {
#                    next;
#                }
#
#                my ($row1, $col1) = @{$positions->[0]};
#                my ($row2, $col2) = @{$positions->[1]};
#
#                if ($row1 == $row2) {
#                    for my $col (0..8) {
#                        next if $col == $col1 || $col == $col2 || int($col / 3) == $box_col;
#                        my @new_pencilmarks = grep { $_ != $number } @{$pencilmarks->[$row1][$col]};
#                        if (@new_pencilmarks != @{$pencilmarks->[$row1][$col]}) {
#                            $pencilmarks->[$row1][$col] = \@new_pencilmarks;
#                            $changes = 1;
#                        }
#                    }
#                }
#
#                if ($col1 == $col2) {
#                    for my $row (0..8) {
#                        next if $row == $row1 || $row == $row2 || int($row / 3) == $box_row;
#                        my @new_pencilmarks = grep { $_ != $number } @{$pencilmarks->[$row][$col1]};
#                        if (@new_pencilmarks != @{$pencilmarks->[$row][$col1]}) {
#                            $pencilmarks->[$row][$col1] = \@new_pencilmarks;
#                            $changes = 1;
#                        }
#                    }
#                }
#            }
#        }
#    }
#
#    return $changes;
#}

sub multiple_lines_technique {
    my ($grid, $pencilmarks) = @_;
    # Placeholder for actual implementation
    return 0;
}

sub naked_pair_technique {
    my ($grid, $pencilmarks) = @_;
    # Placeholder for actual implementation
    return 0;
}

sub hidden_pair_technique {
    my ($grid, $pencilmarks) = @_;
    # Placeholder for actual implementation
    return 0;
}

sub naked_triple_technique {
    my ($grid, $pencilmarks) = @_;
    # Placeholder for actual implementation
    return 0;
}

sub hidden_triple_technique {
    my ($grid, $pencilmarks) = @_;
    # Placeholder for actual implementation
    return 0;
}

sub x_wing_technique {
    my ($grid, $pencilmarks) = @_;
    # Placeholder for actual implementation
    return 0;
}

sub forcing_chains_technique {
    my ($grid, $pencilmarks) = @_;
    # Placeholder for actual implementation
    return 0;
}

sub naked_quad_technique {
    my ($grid, $pencilmarks) = @_;
    # Placeholder for actual implementation
    return 0;
}

sub hidden_quad_technique {
    my ($grid, $pencilmarks) = @_;
    # Placeholder for actual implementation
    return 0;
}

sub swordfish_technique {
    my ($grid, $pencilmarks) = @_;
    # Placeholder for actual implementation
    return 0;
}

sub generate_pencilmarks {
    my ($grid) = @_;
    my @pencilmarks;

    for my $row (0..8) {
        for my $col (0..8) {
            if ($grid->[$row][$col] != 0) {
                $pencilmarks[$row][$col] = [];
                next;
            }

            my @numbers_possible = (1..9);

            for my $i (0..8) {
                my $number_horizontal = $grid->[$row][$i];

                if ($number_horizontal > 0) {
                    $numbers_possible[$number_horizontal-1] = 0;
                }

                my $number_vertical = $grid->[$i][$col];

                if ($number_vertical > 0) {
                    $numbers_possible[$number_vertical-1] = 0;
                }
            }

            my $start_row = int($row / 3) * 3;
            my $start_col = int($col / 3) * 3;
            for my $i ($start_row .. $start_row + 2) {
                for my $j ($start_col .. $start_col + 2) {
                    my $number = $grid->[$i][$j];

                    if ($number > 0) {
                        $numbers_possible[$number-1] = 0;
                    }
                }
            }

            @numbers_possible = grep {$_ > 0} @numbers_possible;

            $pencilmarks[$row][$col] = \@numbers_possible;
        }
    }

    return \@pencilmarks;
}

sub is_solved {
    my ($grid) = @_;
    for my $row (0..8) {
        for my $col (0..8) {
            return 0 if $grid->[$row][$col] == 0;
        }
    }
    return 1;
}

sub print_pencilmarks {
    my ($pencilmarks) = @_;
    for my $row (0..8) {
        for my $col (0..8) {
            print "[$row, $col]: @{$pencilmarks->[$row][$col]}\n" if scalar @{$pencilmarks->[$row][$col]} > 0;
        }
    }
    print("hi");
}



sub update_pencilmarks {
    my ($pencilmarks, $grid, $number, $row, $col) = @_;

    $pencilmarks->[$row][$col] = [];

    for my $i (0..8) {
        if ($i != $col) {
            @{$pencilmarks->[$row][$i]} = grep { $_ != $number } @{$pencilmarks->[$row][$i]};
        }
    }

    for my $i (0..8) {
        if ($i != $row) {
            @{$pencilmarks->[$i][$col]} = grep { $_ != $number } @{$pencilmarks->[$i][$col]};
        }
    }

    my $box_row = int($row / 3) * 3;
    my $box_col = int($col / 3) * 3;

    for my $i ($box_row..$box_row+2) {
        for my $j ($box_col..$box_col+2) {
            if ($i != $row || $j != $col) {
                @{$pencilmarks->[$i][$j]} = grep { $_ != $number } @{$pencilmarks->[$i][$j]};
            }
        }
    }

    $grid->[$row][$col] = $number;
}






sub find_single_position_in_row {
    my ($pencilmarks, $grid) = @_;

    for my $row (0..8) {
        my @numbers_possible = ([], [], [], [] ,[], [], [], [], []);
        for my $col (0..8) {
            if ($grid->[$row][$col] != 0) {
                next;
            }
            for my $number_placement_possiblities (@{$pencilmarks->[$row][$col]}) {
                push @{$numbers_possible[$number_placement_possiblities-1]}, $col;
            }
        }

        for my $number (0..8) {
            if (scalar(@{$numbers_possible[$number]}) == 1) {
                my $col = $numbers_possible[$number][0];
                $grid->[$row][$col] = $number+1;
                #print("SINGLE POSITION IN ROW at ($row, $col): ", $number+1, "\n");

                update_pencilmarks($pencilmarks, $grid, $number, $row, $col);
                
                return 1;
            }
        }
    }
    return 0;
}

sub find_single_position_in_col {
    my ($pencilmarks, $grid) = @_;

    for my $col (0..8) {
       
       my @numbers_possible = ([], [], [], [] ,[], [], [], [], []);

        for my $row (0..8) {
            if ($grid->[$row][$col] != 0) {
                next;
            }; 
            for my $number_placement_possiblities (@{$pencilmarks->[$row][$col]}) {
                push @{$numbers_possible[$number_placement_possiblities-1]}, $row;
            }
        }

        for my $number (0..8) {
            if (scalar(@{$numbers_possible[$number]}) == 1) {
                my $row = $numbers_possible[$number][0];
                $grid->[$row][$col] = $number + 1;
                #print("SINGLE POSITION IN COLUMN at ($row, $col): ", $number+1, "\n");

                update_pencilmarks($pencilmarks, $grid, $number, $row, $col);

                return 1;
            }
        }
    }
    return 0;
}

sub find_single_position_in_box {
    my ($pencilmarks, $grid) = @_;

    for my $box_row (0..2) {
        for my $box_col (0..2) {

            my @numbers_possible = ([], [], [], [] ,[], [], [], [], []);

            for my $i (0..2) {
                for my $j (0..2) {
                    my $row = $box_row * 3 + $i;
                    my $col = $box_col * 3 + $j;
                    if ($grid->[$row][$col] != 0) {
                        next;
                    };

                    for my $number_placement_possiblities (@{$pencilmarks->[$row][$col]}) {
                        push @{$numbers_possible[$number_placement_possiblities - 1]}, [$row, $col];
                    }
                }
            }

            for my $number (0..8) {
                if (scalar(@{$numbers_possible[$number]}) == 1) {
                    my ($row, $col) = @{$numbers_possible[$number][0]};
                    $grid->[$row][$col] = $number + 1;
                    #print("SINGLE POSITION IN BOX at ($row, $col): ", $number+1, "\n");

                    update_pencilmarks($pencilmarks, $grid, $number, $row, $col);

                    return 1;
                }
            }
        }
    }

    return 0;
}






1;