package memory;

use strict;
use warnings;
use List::Util 'shuffle';

my ($first_card, $second_card) = (undef, undef);
my $turn = 0;
my $score = 0;
my $pairs_found;
my $is_playing = 0;
my $old_card_number = 17;
my $memory_label;
my @players_score;
my @found_pairs;
my $second_card_number;

sub start {
    my ($frame) = @_;

    choose_player_amount($frame);
}

sub choose_player_amount {
    my ($frame) = @_;

    my $player_select = $frame->Toplevel();
    $player_select->geometry("300x200");
    $player_select->title("Select Players");

    my $label = $player_select->Label(
        -text => "Choose Player amount?",
        -font => ['Arial', 14]
    )->pack(
        -pady => 20,
    );

    my $selection_val = 2;
    my $radio1 = $player_select->Radiobutton(
    	-text => 'Eins',
    	-value => 1,
    	-variable => \$selection_val,
    )->pack(-anchor => 'n');
    my $radio2 = $player_select->Radiobutton(
    	-text => 'Zwei',
    	-value => 2,
    	-variable => \$selection_val,
    )->pack(-anchor => 'n');

    my $button = $player_select->Button(
        -text => "Start Game",
        -font => ['Arial', 14],
        -command => sub {
            my $player_amount = $selection_val;
            start_game($frame, $player_amount);
            $player_select->destroy();
        }
    )->pack(
        -pady => 20,
    );
}

sub start_game {
    my ($frame, $player_amount) = @_;

    print ("Player Amount: $player_amount \n");

    my $memory_child = $frame->Toplevel();
    $memory_child->geometry("500x700");
    $memory_child->title("Memory");



    $memory_label = $memory_child->Label(
        -text => "Memory",
    )->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
    );

    
    my $main_frame = $memory_child->Frame()->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
    );

    my $memory_frame = $main_frame->Frame()->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
    );

    my $bottom_frame = $main_frame->Frame()->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
    );

    my $memory_deckblatt = $memory_frame ->Photo(-file => "src/memory/deckblatt.png");

    
    restart($memory_frame, $memory_deckblatt, $player_amount);
    
    my $restart_button = $bottom_frame->Button(
        -text => "Restart",
        -command => sub {
            restart($memory_frame, $memory_deckblatt, $player_amount);
        }
    )->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
    );

    my $player_choose_button = $bottom_frame->Button(
        -text => "Choose Player Amount",
        -command => sub {
            choose_player_amount($frame);
            $memory_child->destroy();
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
            $memory_child->destroy();
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
    my ($frame, $memory_deckblatt, $player_amount) = @_;
    my $buttons = 16;
    $pairs_found = 0;
    @found_pairs = ();
    $turn = 0;
    $memory_label->configure(-text => "Player 1's Turn");



    my @list = shuffle (0 .. ($buttons/2-1), 0 .. ($buttons/2-1));
    for (my $i = 0; $i < $buttons; $i++) {
        my $row = int($i / 4);
        my $column = $i % 4;

        my $card_value = $list[$i];
        my $card_number = $i;

        my $button = $frame->Button(
            -image => $memory_deckblatt,
            -height => 100,
            -width => 100,
            
        )->grid(
            -row =>  $row,
            -column => $column,
        );
        $button->configure(
            -command => sub {
                reveal_card($card_value, $button, $memory_deckblatt, $frame, $card_number, $player_amount);
                print($card_value);
            },
        )
    }
}

sub reveal_card {
    my ($card_value, $button, $memory_deckblatt, $frame, $card_number, $player_amount) = @_;

    my %card_value_to_picture = (
        0 => $frame ->Photo(-file => "src/memory/memory_card1.png"),
        1 => $frame ->Photo(-file => "src/memory/memory_card2.png"),
        2 => $frame ->Photo(-file => "src/memory/memory_card3.png"),
        3 => $frame ->Photo(-file => "src/memory/memory_card4.png"),
        4 => $frame ->Photo(-file => "src/memory/memory_card5.png"),
        5 => $frame ->Photo(-file => "src/memory/memory_card6.png"),
        6 => $frame ->Photo(-file => "src/memory/memory_card7.png"),
        7 => $frame ->Photo(-file => "src/memory/memory_card8.png"),
    );

    if ($card_number ~~ @found_pairs){
        print("hello");
        return;
    }

    if ($old_card_number == $card_number) {
        return;
    }

    $old_card_number = $card_number;

    my $card_picture = $card_value_to_picture{$card_value};

    if (!$first_card) {
        $first_card = [$card_value, $button] ;
        $button->configure(-image => $card_picture);
        #print("1");
    }
    elsif (!$second_card) {
        $second_card = [$card_value, $button];
        $button->configure(-image => $card_picture);
        #print("2");

        if ($first_card->[0] == $second_card->[0]) {
            #print("3");
            $pairs_found++;
            $players_score[$turn]++;

            push(@found_pairs, $card_number, $second_card_number);
            print("First card: ", $card_number, "\n");
            print("Second card: ", $second_card_number, "\n");
            print("Found pairs: ", @found_pairs, "\n");



            print("Pairs found: $pairs_found \n");
            $first_card = undef;
            $second_card = undef;

            $old_card_number = 17;

            if ($pairs_found == 8) {
                show_win_msg($frame);
                print("You WOn");
            }
        }
        
        else {
            #print("4");

            $frame->after (1000, sub {
                $first_card->[1]->configure(-image => $memory_deckblatt);
                $second_card->[1]->configure(-image => $memory_deckblatt);
                $first_card = undef;
                $second_card = undef;
                $old_card_number = 17;

                $turn = ($turn + 1) % $player_amount;
                $memory_label->configure(-text => "Player " . ($turn + 1) . "'s turn");
            })
            
        }
        

    }
    $second_card_number = $card_number;
}

sub show_win_msg {
    my ($frame) = @_;

    my $win_label;
    if ($players_score[0] > $players_score[1]) {
        $win_label = $frame->Label(
            -text  => "Player 1 wins!",
            -font  => ['Helvetica', 48, 'bold'],
            -fg    => 'red',
            -bg    => 'yellow',
        )->place(-x => 50, -y => 200);
        $memory_label->configure(-text => "Player 1 wins!");
    }

    elsif ($players_score[1] > $players_score[0]) {
        $win_label = $frame->Label(
            -text  => "Player 2 wins!",
            -font  => ['Helvetica', 48, 'bold'],
            -fg    => 'red',
            -bg    => 'yellow',
        )->place(-x => 50, -y => 200);
        $memory_label->configure(-text => "Player 2 wins!");
    }

    else {
        $win_label = $frame->Label(
            -text  => "DRAW!",
            -font  => ['Helvetica', 48, 'bold'],
            -fg    => 'red',
            -bg    => 'yellow',
        )->place(-x => 50, -y => 200);
        $memory_label->configure(-text => "Draw!");
    }

    $frame->after (1000, sub {
        $win_label->destroy();
    })
    #$frame->destroy();
}




1;