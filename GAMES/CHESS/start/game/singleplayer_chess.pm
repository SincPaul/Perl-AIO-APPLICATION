package singleplayer_chess;

use strict;
use warnings;
use Tk;
use Tk::Event;
use Tk::DragDrop;
use Tk::DropSite;

sub start {
    my ($frame) = @_;

    my $mode = 'Singleplayer';

    utils::create_chess_board($frame, $mode);
}
1;