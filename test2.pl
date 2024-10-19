# SINC Perl - GUI for funny WAV manipulation
# Autor: P. Geisthardt, SINC GmbH, paul dot geisthardt at sinc dot de
# Version: 1.7
# Letzte Modifikation: 11.09.2024

# ! PAUSE AND RESUME DOESNT WORK, STARTS AT BEGINNING ALL THE TIME
# ! color picker nicht auf frame sondern farbe anwenden  


my $remote_host = "10.31.5.21"; #"10.31.4.69"; #MArcel  #"10.31.0.85"; #Noah #"10.31.4.64"; #Mahdi 10.31.5.21 #Emil
my $remote_port = 8888; #7777; #MArcel  #1337; #Noah #2222; #Mahdi

use strict;
use warnings qw( all );
use MIME::Base64;
use Tk;
use Tk::FileSelect;
use File::Temp qw/ tempfile tempdir /;
use File::Copy;
use Win32::Sound qw(SND_ASYNC SND_LOOP);
use Tk::ProgressBar;
use Tk::Photo;
use Tk::PNG;
use Tk::JPEG;
use TK::Font;
use Audio::Analyzer;
use Math::FFT;
use IO::Socket;
use Win32::SoundRec;
use Tk::Animation;
use Tk::Splashscreen;
use Tk::ColorEditor;
use Tk::Radiobutton;


use GAMES::MEMORY::memory;
use GAMES::TICTACTOE::tictactoe;
use GAMES::SUDOKU::sudoku;
use GAMES::CHESS::start::chesslogin;
use GAMES::game;

use MANAGEMENT::ACCOUNT::account_utils;
use MANAGEMENT::SERVER_CONNECTION::session;
use MANAGEMENT::SERVER_CONNECTION::server_connections;
use MANAGEMENT::SERVER_CONNECTION::server_client_connection_messages;

use MANAGEMENT::FRIENDS::friend_utils;

my $temp_dir = tempdir(CLEANUP => 1);  
my $output_file;
my $wav_file;
my $is_playing = 0;
my $duration = 0;
my $current_time = 0;
my $progress = 0;
my $wav_label = '';
my $progress_bar = '';
my $amp_input;
my $echo_input;
my $time_stretch_input;
my $fade_in_input;
my $button_logo;
my $logo_frame;
my $spectrogram_canvas;
my $spectrogram_frame;
my $start_time;
my $pause_time;
my $is_paused;
my $playing_wav;
my $recording;
my $counter = 0;
my $utility_frame;
my $button_color = "#84c7e8";
my $middle_background_color = "#a0d2eb";
my $middle_field_background_color = "#e5eaf5";
my $middle_text_color = "#8458B3";
my $middle_field_background_color2 = "#90cbe8";
my $left_background_color = "#494d60";
my $left_field_background_color = "#a0a7d2";
my $left_field_background_color2 = "#bdc5f8";
my $left_text_color = "#181920";
my $left_button_color = "#8389ac";
my $right_background_color = "#494d60";
my $color_picker_color ;
my $splash;
my $color_change_button;
my ($register_login_frame, $register_button, $login_button);
my $logged_in_frame;
my ($username, $password, $display_name);
my $user_button;

my @target_freqs = (64.599609375, 150.732421875, 409.130859375, 1012.060546875, 2411.71875, 15008.642578125);
my @plot_shown_frequencies = (64, 150, 409, 1012, 2411, 15008);
my @test_amps = (0.4, 0.5, 0.3, 0.6, 0.4, 0.5);

my $fft_size = 1024*2*2*2;

my $main = MainWindow->new();
$main->geometry("975x905");
$main->title("SINC Perl - Cool Stuff with WAV");
my $icon = $main ->Photo(
    -format => 'png', 
    -file => 'src/main/sinc_icon.png',
    -width => 32,
    -height => 32
    );

$main->iconimage ($icon);

my $FSref = $main->FileSelect(
    -directory => 'C:\\',
    -filter    => '*.wav',
    -filelabel => 'Select WAV file',
);

my $left_frame = $main->Frame(
    -background => $left_background_color,
    -borderwidth => 2,
    -relief => 'sunken',
)->pack(
    -side => 'left', 
    -fill => 'both',
    -expand => 1
);

my $middle_frame = $main->Frame(
    -background => $middle_background_color,
    -borderwidth => 2,
    -relief => 'sunken',
    -width => 450,
)->pack(
    -side => 'left',
    -fill => 'both',
    #-expand => 1
);

my $right_frame = $main->Frame(
    -background => $right_background_color,
    -borderwidth => 2,
    -relief => 'sunken',
)->pack(
    -side => 'right',
    -fill => 'both',
    -expand => 1
);

create_left_gui();
create_middle_gui();
create_right_gui();

#game::chooseGame($main);

#create_startup_animation();



$main->MainLoop();

sub create_left_gui {
    create_register_login_gui();
    create_amplify_wav_gui();
    create_echo_gui();
    create_reverse_gui();
    create_time_stretch_gui();
    create_fade_in_out_gui();
    create_logo_gui();
    
}

sub create_amplify_wav_gui {

    my $amp_frame = $left_frame->Frame(
        -background => $left_field_background_color,
        -borderwidth => 2,
        -relief => 'raised',
    )->pack(
        -anchor => 'n',
        -side => 'top',
        -pady => 5,
        -padx => 10,
        -fill => 'both',
    );

    my $amp_label = $amp_frame->Label(
        -text => "Adjust Volume:",
        -font => ['DejaVu Serif', 10],
        -background => $left_field_background_color2,
        -foreground => $left_text_color,
        -borderwidth => 2,
        -relief => 'raised',
    )->pack(
        -anchor => 'n',
        -pady => 5,
        -padx => 10,
        -fill => 'x'
    );

    $amp_input = $amp_frame->Scale(
        -from => 0,
        -to => 5,
        -resolution => 0.1,
        -orient => 'horizontal',
        -label => 'Volume Multiplier',
        -background => $left_field_background_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10],
        -relief => 'raised',
        -borderwidth => 2
    )->pack(
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    );

    my $amp_button = $amp_frame->Button(
        -text   => "Apply Volume Change",
        -relief => 'raised',
        -command => sub {
        amplify_wav();
    },
        -background => $left_button_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10]
    )->pack(
        -pady => 5,
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    );
}

sub create_echo_gui {
    my $echo_frame = $left_frame->Frame(
        -background => $left_field_background_color,
        -borderwidth => 2,
        -relief => 'raised',
    )->pack(
        -anchor => 'n',
        -side => 'top',
        -pady => 5,
        -padx => 10,
        -fill => 'both',
    );

    my $echo_label = $echo_frame->Label(
        -text => "Echo Effect:",
        -font => ['DejaVu Serif', 10],
        -background => $left_field_background_color2,
        -foreground => $left_text_color,
        -borderwidth => 2,
        -relief => 'raised',
    )->pack(
        -anchor => 'n',
        -pady => 5,
        -padx => 10,
        -fill => 'x'
    );

    $echo_input = $echo_frame->Scale(
        -from => 0,
        -to => 5,
        -resolution => 0.1,
        -length => 10,
        -orient => 'horizontal',
        -label => 'Echo Delay [seconds]',
        -background => $left_field_background_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10],
        -relief => 'raised',
        -borderwidth => 2
    )->pack(
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    );

    my $echo_button = $echo_frame->Button(
        -text   => "Apply Echo Change",
        -command => \&add_echo,
        -background => $left_button_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10]
    )->pack(
        -pady => 5,
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    );
}

sub create_reverse_gui {
    my $reverse_frame = $left_frame->Frame(
        -background => $left_field_background_color,
        -borderwidth => 2,
        -relief => 'raised',
    )->pack(
        -anchor => 'n',
        -side => 'top',
        -pady => 5,
        -padx => 10,
        -fill => 'both',
    );
    my $reverse_label = $reverse_frame->Label(
        -text => "Reverse Audio:",
        -font => ['DejaVu Serif', 10],
        -background => $left_field_background_color2,
        -foreground => $left_text_color,
        -borderwidth => 2,
        -relief => 'raised',
    )->pack(
        -anchor => 'n',
        -pady => 5,
        -padx => 10,
        -fill => 'x'
    );

    my $reverse_button = $reverse_frame->Button(
        -text   => "Apply Reverse",
        -command => \&reverse_wav,
        -background => $left_button_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10]
    )->pack(
        -pady => 5,
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    );
}

sub create_time_stretch_gui {
    my $time_stretch_frame = $left_frame->Frame(
        -background => $left_field_background_color,
        -borderwidth => 2,
        -relief => 'raised',
    )->pack(
        -anchor => 'n',
        -side => 'top',
        -pady => 5,
        -padx => 10,
        -fill => 'both',
    );

    my $time_stretch_label = $time_stretch_frame->Label(
        -text => "Change Speed",
        -font => ['DejaVu Serif', 10],
        -background => $left_field_background_color2,
        -foreground => $left_text_color,
        -borderwidth => 2,
        -relief => 'raised',
    )->pack(
        -anchor => 'n',
        -pady => 5,
        -padx => 10,
        -fill => 'x'
    );

    $time_stretch_input = $time_stretch_frame->Scale(
        -from => 0,
        -to => 5,
        -resolution => 0.1,
        -orient => 'horizontal',
        -label => 'Speed Multiplier',
        -background => $left_field_background_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10],
        -relief => 'raised',
        -borderwidth => 2
    )->pack(
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    );

    my $time_stretch_button = $time_stretch_frame->Button(
        -text   => "Apply Speed Changes",
        -command => \&time_stretch_1,
        -background => $left_button_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10]
    )->pack(
        -pady => 5,
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    );
}

sub create_fade_in_out_gui {
    my $fade_in_frame = $left_frame->Frame(
        -background => $left_field_background_color,
        -borderwidth => 2,
        -relief => 'raised',
    )->pack(
        -anchor => 'n',
        -side => 'top',
        -pady => 5,
        -padx => 10,
        -fill => 'both',
    );


    my $fade_in_label = $fade_in_frame->Label(
        -text => "Fade In/Out",
        -font => ['DejaVu Serif', 10],
        -background => $left_field_background_color2,
        -foreground => $left_text_color,
        -borderwidth => 2,
        -relief => 'raised',
    )->pack(
        -anchor => 'n',
        -pady => 5,
        -padx => 10,
        -fill => 'x'
    );

    $fade_in_input = $fade_in_frame->Scale(
        -from => 0,
        -to => 5,
        -resolution => 0.1,
        -orient => 'horizontal',
        -label => 'Fade Length [seconds]',
        -background => $left_field_background_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10],
        -relief => 'raised',
        -borderwidth => 2
    )->pack(
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    );

    my $fade_in_button = $fade_in_frame->Button(
        -text   => "Apply Fade",
        -command => \&fade_in,
        -background => $left_button_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10]
    )->pack(
        -pady => 5,
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    );
}

sub create_logo_gui {
    $logo_frame = $left_frame->Frame(
        -background => $left_field_background_color,
        -borderwidth => 2,
        -relief => 'raised',
    )->pack(
        -anchor => 'n',
        -side => 'top',
        -pady => 5,
        -padx => 10,
        -fill => 'both',
    );

    
    my $image = 'src/main/sinc_logo.png';
    my $logo = $logo_frame->Photo(-file => $image);
    $button_logo = $logo_frame->Button(
        -image => $logo,
        -command => \&easter_egg_show_god,
        -background => $left_field_background_color,
    )->pack(
        -side => 'top',
        -padx => 10,
        -pady => 10
    ); 
}

sub easter_egg_show_god {
    my $till_god = $logo_frame->Photo(-file => 'src/main/till_god_text_cropped.png');
    $button_logo->configure(-image => $till_god);

    my $image = 'src/main/sinc_logo.png';
    my $logo = $logo_frame->Photo(-file => $image);

    $logo_frame->after(5000, sub {
        $button_logo->configure(-image => $logo);
    });
}

sub create_register_login_gui {

    if (!$register_login_frame) {
        $register_login_frame = $left_frame->Frame(
            -background => $left_field_background_color,
            -borderwidth => 2,
            -relief => 'raised',
        )->pack(
            -anchor => 'n',
            -side => 'top',
            -pady => 5,
            -padx => 10,
            -fill => 'both',
        );
    }
    

    $register_button = $register_login_frame->Button(
        -text   => "Register",
        -command => \&register,
        -background => $left_button_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10]
    )->pack(
        -pady => 5,
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    );

    $login_button = $register_login_frame->Button(
        -text   => "Login",
        -command => \&login,
        -background => $left_button_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10]
    )->pack(
        -pady => 5,
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    );
}

sub register {
    my $register_frame = $main->Toplevel(
        -background => $left_field_background_color,
        -borderwidth => 2,
        -relief => 'raised',
    );

    my $username_label = $register_frame->Label(
        -text => "Username:",
        -font => ['Arial', 12],
    )->pack(
        -pady => [10, 10],
    );

    my $username_entry = $register_frame->Entry(
        -font => ['Arial', 12]
    )->pack(
        -pady => 10,
    );

    my $password_label = $register_frame->Label(
        -text => "Password:",
        -font => ['Arial', 12]
    )->pack(
        -pady => 10,
    );

    my $password_entry = $register_frame->Entry(
        -font => ['Arial', 12],
        -show => '*'
    )->pack(
        -pady => 10,
    );

    my $confirm_password_label = $register_frame->Label(
        -text => "Confirm Password:",
        -font => ['Arial', 12]
    )->pack(
        -pady => 10,
    );

    my $confirm_password_entry = $register_frame->Entry(
        -font => ['Arial', 12],
        -show => '*'
    )->pack(
        -pady => 10,
    );
    my $register_button = $register_frame->Button(
        -text => "Register",
        -background => 'blue',
        -foreground => 'white',
        -font => ['Arial', 12, 'bold'],
        -command => sub {
        $username = $username_entry->get();
        $password = $password_entry->get();
            if ($username && $password) {
                account_utils::register($username, $password, $register_frame, $main);
                $display_name = $username;
                logged_in_ui();
            }
        },
    )->pack(  
    );

    my $return_button = $register_frame->Button(
        -text => "Return",
        -background => 'red',
        -foreground => 'white',
        -font => ['Arial', 12, 'bold'],
        -command => sub {
            print("COMING SOON");
            #login_page($login_frame, $frame);
        },
    )->pack(
    );
}

sub login {
    my $login_frame = $main->Toplevel(
        -background => $left_field_background_color,
        -borderwidth => 2,
        -relief => 'raised',
    );

}

sub logged_in_ui {
    $register_button->destroy();
    $login_button->destroy();

    $logged_in_frame = $register_login_frame->Frame(
        -background => $left_field_background_color,
        #-borderwidth => 2,
        #-relief => 'raised',
    )->pack(
        -anchor => 'n',
        -side => 'top',
        -pady => 5,
        -padx => 10,
        -fill => 'both',
    );
    
    $user_button = $logged_in_frame->Button(
        -text => "User: $display_name",
        -background => $left_button_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10]
    )->pack(
        -pady => 5,
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    );

    my $manage_user_button = $logged_in_frame->Button(
        -text => "Manage User",
        -background => $left_button_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10],
        -command =>  sub {
            manage_user();
        },
    )->pack(
        -pady => 5,
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    );
}

sub logged_out_ui {
    $logged_in_frame->destroy();

    create_register_login_gui();
}

sub manage_user {
    my $manage_user_frame = $main->Toplevel(
        -background => $left_field_background_color,
        -borderwidth => 2,
        -relief => 'raised',
    );

    my $manage_user_label = $manage_user_frame->Label(
        -text => "Manage User: $display_name",
        -font => ['Arial', 12],
    )->pack(
        -pady => [10, 10],
    );

    my $logout_button = $manage_user_frame->Button(
        -text => "Logout",
        -background => $left_button_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10],
        -command => sub {
            #logout($username);
            logged_out_ui();
            $manage_user_frame->destroy();
        },
    )->pack(
        -pady => 5,
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    );

    my $change_password_button = $manage_user_frame->Button(
        -text => "Change Password",
        -background => $left_button_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10],
        -command => sub {
            change_password();
            $manage_user_frame->destroy();
        },
    )->pack(
        -pady => 5,
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    );

    my $change_display_name = $manage_user_frame->Button(
        -text => "Change Display Name",
        -background => $left_button_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10],
        -command => sub {
            change_display_name();        
            $manage_user_frame->destroy();
        },
    )->pack(
        -pady => 5,
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    )
}

sub change_display_name {
    my $change_display_name_frame = $main->Toplevel(
        -background => $left_field_background_color,
        -borderwidth => 2,
        -relief => 'raised',
    );

    my $account_name_label = $change_display_name_frame->Label(
        -text => "$username",
        -font => ['Arial', 12],
    )->pack(
        -pady => [10, 10],
    );

    my $display_name_label = $change_display_name_frame->Label(
        -text => "Change your display name:\nCurrent display name: $display_name",
        -font => ['Arial', 12]
    )->pack(
        -pady => 10,
    );

    my $display_name_entry = $change_display_name_frame->Entry(
        -font => ['Arial', 12],
    )->pack(
        -pady => 10,
    );

    my $change_display_name_button = $change_display_name_frame->Button(
        -text => "Change Display Name",
        -background => $left_button_color,
        -foreground => $left_text_color,
        -font => ['DejaVu Serif', 10],
        -command => sub {
            my $new_display_name = $display_name_entry->get();
            account_utils::change_display_name($new_display_name);
            $display_name = $new_display_name;
            print("Display NAme: $display_name\n");
            $user_button->configure(
                -text => "User: $display_name"
            ),
            $change_display_name_frame->destroy();
        },
    )->pack(
        -pady => 5,
        -anchor => 'n',
        -fill => 'x',
        -padx => 10
    );
}

sub change_password {
    my $change_password_frame = $main->Toplevel(
        -background => $left_field_background_color,
        -borderwidth => 2,
        -relief => 'raised',
    );

    my $account_name_label = $change_password_frame->Label(
        -text => "$display_name",
        -font => ['Arial', 12],
    )->pack(
        -pady => [10, 10],
    );

    my $old_password_label = $change_password_frame->Label(
        -text => "Old Password:",
        -font => ['Arial', 12]
    )->pack(
        -pady => 10,
    );

    my $old_password_entry = $change_password_frame->Entry(
        -font => ['Arial', 12],
        -show => '*'
    )->pack(
        -pady => 10,
    );

    my $new_password_label = $change_password_frame->Label(
        -text => "New Password:",
        -font => ['Arial', 12]
    )->pack(
        -pady => 10,
    );

    my $new_password_entry = $change_password_frame->Entry(
        -font => ['Arial', 12],
        -show => '*'
    )->pack(
        -pady => 10,
    );

    my $confirm_new_password_label = $change_password_frame->Label(
        -text => "Confirm New Password:",
        -font => ['Arial', 12]
    )->pack(
        -pady => 10,
    );

    my $confirm_new_password_entry = $change_password_frame->Entry(
        -font => ['Arial', 12],
        -show => '*'
    )->pack(
        -pady => 10,
    );

    my $change_password_button = $change_password_frame->Button(
        -text => "Change Password",
        -background => 'blue',
        -foreground => 'white',
        -font => ['Arial', 12, 'bold'],
        -command => sub {
            my $old_password = $old_password_entry->get();
            my $new_password = $new_password_entry->get();
            my $confirm_new_password = $confirm_new_password_entry->get();

            if ($new_password && $confirm_new_password && $new_password eq $confirm_new_password && $old_password && $old_password eq $password) {
                account_utils::change_password($new_password);
                $password = $new_password;
                $change_password_frame->destroy();
            } else {
                $change_password_frame->Label(
                    -text => "Current or New Password entry is wrong",
                    -font => ['Arial', 12],
                    -foreground => 'red'
                )->pack(
                    -pady => 10,
                );
            }
        },
    )->pack(
        -pady => 10,
    );

    my $return_button = $change_password_frame->Button(
        -text => "Return",
        -background => 'red',
        -foreground => 'white',
        -font => ['Arial', 12, 'bold'],
        -command => sub {
            $change_password_frame->destroy();
        },
    )->pack(
        -pady => 10,
    );
}

sub create_startup_animation {
    $main ->withdraw;
    my $splash = $main->Splashscreen(-milliseconds => 5000);
    my $gif = 'loadup.gif';
    my $animate = $splash->Animation(-format => 'gif', -file => $gif);
    $splash->Label(
        -image => $animate, 
        -background => $middle_background_color
        )->pack;
    $animate->set_image(0);
    $animate->start_animation(500);
    $splash->Splash;		
    $main->after(1000);
    $splash->Destroy;		
    $main->deiconify;		
    $main->MainLoop;
}


sub create_middle_gui {
    create_wav_label();
    create_utility_frame();
    create_record_frame();
    create_playback_controls_frame();
    create_spectrogram_frame();
    create_sending_frame();
    create_game_frame();
}

sub create_wav_label {
    $wav_label = $middle_frame->Label(
    -text => "SINC Perl - Input a WAV file and experiment",
    -font => ['DejaVu Serif', 14, 'bold'],
    -background => $middle_field_background_color,
    -foreground => $middle_text_color,
    -borderwidth => 2,
    -relief => 'raised',
    -width => 40,
    )->pack(
        -padx => 10,
        -pady => 10,
        -fill => 'x'
    );
}

sub create_utility_frame {
    $utility_frame = $middle_frame->Frame(
    -background => $middle_field_background_color2,
    -borderwidth => 2,
    -relief => 'raised',
    )->pack(
        -side => 'top',
        -padx => 10,
        -pady => 10,
        -fill => 'x'
    );

    create_file_choose_button();
    create_download_button();
}
sub create_file_choose_button {
    my $file_button = $utility_frame->Button(
    -text => "Select WAV file",
    -font => ['DejaVu Serif', 10],
    -background => $button_color,
    -foreground => $middle_text_color,
    
    -command => sub {
        my $old_wav = $output_file ? $output_file : $wav_file;

        $wav_file = $FSref->Show;

        if ($wav_file) {
            my $file_name = get_file_name($wav_file);
            $wav_label->configure(-text => "Selected: $file_name");
            $output_file = undef;
        } elsif ($old_wav) {  
            my $file_name = get_file_name($old_wav);
            $wav_label->configure(-text => "Operation cancled, continue using $file_name");
            $wav_file = $old_wav;
        } else {
            $wav_label->configure(-text => "No file selected");
        }
    }
    )->pack(
        -padx => 10,
        -pady => [10, 0],
        -fill => 'x',
    );
}

sub create_download_button {
    my $download_button = $utility_frame->Button(
    -text => "Download WAV file",
    -font => ['DejaVu Serif', 10],
    -background => $button_color,
    -foreground => $middle_text_color,
    -command => sub {
        my $file_to_save = $output_file || $wav_file;

        if (!$file_to_save) {
            $wav_label->configure(-text => "No WAV file selected to download");
            return;
        }

        my $save_dir = $main->chooseDirectory(
                -initialdir => '/',
                -title => 'Select a directory to save your modified WAV file'
        );


        if (!$save_dir) {
            $wav_label->configure(-text => "No directory selected for saving");
            return;
        }

        my $dialog = $main->DialogBox(
                    -title   => "Enter File Name",
                    -buttons => ["OK", "Cancel"],
        );

        $dialog->add('Label', -text => "Enter a name for your WAV file:")->pack();
        my $file_name_entry = $dialog->add('Entry')->pack();
        my $result = $dialog->Show();

        if (!$result eq "OK") {
            $wav_label->configure(-text => "Save operation canceled");
            return;
        }
                
        my $file_name = $file_name_entry->get();
        $file_name .= ".wav" unless $file_name =~ /\.wav$/;         
                
        my $save_path = "$save_dir/$file_name";

        if (-e $save_path) {
            my $overwrite_dialog = $main->DialogBox(
                -title   => "Overwrite File",
                -buttons => ["Yes", "No"],
            );

            $overwrite_dialog->add('Label', -text => "File already exists, overwrite?")->pack();

            my $result = $overwrite_dialog->Show();

            if ($result eq "No") {
                $wav_label->configure(-text => "Save operation canceled");
                return;
            }
        }

        if (!copy($file_to_save, $save_path)) {
            die "Failed to copy file: $!";
        }

        $wav_label->configure(-text => "File saved to: $save_path");
    }
    )->pack(
        -padx => 10,
        -pady => [10, 0],
        -fill => 'x',
    );
}




sub create_record_frame {
    my $record_frame = $middle_frame->Frame(
        -background => $middle_field_background_color2,
        -borderwidth => 2,
        -relief => 'raised',

    )->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
        #-expand => 1
    );

    my $recording_label = create_record_label($record_frame);
    create_record_button($record_frame, $recording_label);
    create_stop_record_button($record_frame, $recording_label);
    #create_record_status($record_frame);

}

sub create_record_label {
    my ($frame) = @_;

    my $recording_label_create = $frame->Label(
        -text => "Record",
        -font => ['DejaVu Serif', 8],
        -background => $middle_field_background_color,
        -foreground => $middle_text_color,
    )
    ->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
    );
    return $recording_label_create;
}

sub create_record_button {
    my ($frame, $recording_label) = @_;

    my $record_button = $frame->Button(
        -text => "Record",
        -font => ['DejaVu Serif', 10],
        -background => $button_color,
        -foreground => $middle_text_color,
        -command => sub {
            $recording =  Win32::SoundRec->new();
            $recording->record(16, 44100, 2);
            $recording_label->configure(-text => "Recording...");
        }
    )->pack(
        -side => 'left',
        -padx => [50, 10],
        -pady => [0, 10],
        -fill => 'x',
        -expand => 1
    );
}

sub create_stop_record_button {
    my ($frame, $recording_label) = @_;
    my $stop_record_button = $frame->Button(
        -text => "Stop",
        -font => ['DejaVu Serif', 10],
        -background => $button_color,
        -foreground => $middle_text_color,
        -command => sub {
            $recording->stop();
            $counter += 1;
            my $output_file = "$temp_dir/temp$counter.wav";
            $recording->save("temp$counter.wav");
            #my ($temp_fh, $output_file) = tempfile(SUFFIX => '.wav', DIR => $temp_dir);
            #print "Temp directory: $temp_dir\n";
            #print "Output file: $output_file\n";
            

            

            move("temp$counter.wav", $output_file) or die "Failed to copy file: $!";
           



            #$recording->save($output_file);

            $recording_label->configure(-text => "Finished recording");

            $wav_file = $output_file;
            amplify_wav(15);
        }
    )->pack(
        -side => 'right',
        -padx => [10, 50],
        -pady => [0, 10],

        -fill => 'x',
        -expand => 1
    );
}

sub create_playback_controls_frame {
    my $playback_frame = $middle_frame->Frame(
        -background => $middle_field_background_color2,
        -borderwidth => 2,
        -relief => 'raised',
    )->pack(
        -side => 'top', 
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
        #-expand => 1
    );

    create_playback_label($playback_frame);
    create_play_button($playback_frame);
    create_pause_button($playback_frame);
    create_stop_button($playback_frame);
    create_progress_bar($playback_frame);

    
}

sub create_sending_frame {
    my $sending_frame = $middle_frame->Frame(
        -background => $middle_field_background_color2,
        -borderwidth => 2,
        -relief => 'raised',
    )->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
        #-expand => 1
    );

    my $send_label = create_send_label($sending_frame);
    create_socket_button($sending_frame);
    #create_send_status($sending_frame);
}

sub create_send_label {
    my ($frame) = @_;

    my $send_label = $frame->Label(
        -text => "Sent this to a socket server",
        -font => ['DejaVu Serif', 12],
        -background => $middle_field_background_color,
        -foreground => $middle_text_color,
    )
    ->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
    );
    return $send_label;
}

sub create_game_frame {
    my $game_frame = $middle_frame->Frame(
        -background => $middle_field_background_color2,
        -borderwidth => 2,
        -relief => 'raised',
    )->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
        #-expand => 1
    );

    my $game_label = create_game_label($game_frame);
    create_game_button($game_frame);
}

sub create_game_label {
    my ($frame) = @_;

    my $game_label = $frame->Label(
        -text => "Choose a game to play",
        -font => ['DejaVu Serif', 12],
        -background => $middle_field_background_color,
        -foreground => $middle_text_color,
    )->pack(
        -side => 'top',
        -anchor => 'nw',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
    )
}

sub create_game_button {
    my ($frame) = @_;

    my $memory_button = $frame->Button(
        -text => "Choose Game",
        -font => ['DejaVu Serif', 10],
        -background => $button_color,
        -foreground => $middle_text_color,
        -command => sub {
            game::chooseGame($frame);
            #MEMORY::start($frame) 
        }
    )->pack(
        -side => 'top',
        -padx => 10,
        -pady => 10,
    );
}
sub create_socket_button {
    my ($frame) = @_;

    my $socket_button = $frame->Button(
        -text => "Send",
        -font => ['DejaVu Serif', 10],
        -background => $button_color,
        -foreground => $middle_text_color,
        -command => \&socket_send_child
    )->pack(
        -side => 'top',
        -padx => 10,
        -pady => 10,
    );
}

    



sub socket_send_child {
    $wav_file = $output_file if not $wav_file;

    if (!$wav_file) {
        $wav_label->configure(-text => "No WAV file selected to send");
        return;
    }

    my $child = $main->Toplevel();
    $child->title("SINC Perl - Socket Client");


    $child->geometry("350x300");  


    my $bg_color = "#9BE564"; 
    my $fg_color = "#102542";
    my $bg_color2 = "#D7F75B";

    my $main_frame = $child->Frame(
        -background => $bg_color, 
    )->pack(
        -side   => 'top',
        -anchor => 'center',
        #-padx   => 10,
        #-pady   => 10,
        -fill   => 'both',
        -expand => 1
    );


    my $child_label = $main_frame->Label(
        -text       => "Pls input Server Adress",
        -font       => ['Arial', 10],
        -foreground => $fg_color,
        -background => $bg_color,
    )->pack(
        -side   => 'top',
        -anchor => 'w',
        -padx   => 5,
        -pady   => [0, 20]
    );

    $main_frame->Label(
        -text       => "Remote Host IP Address:",
        -font       => ['Arial', 10],
        -foreground => $fg_color,
        -background => $bg_color, 
    )->pack(
        -side   => 'top',
        -anchor => 'w',
        -padx   => 5,
        -pady   => 5
    );

    my $remote_host_entry = $main_frame->Entry(
        -font  => ['Arial', 10],
        -width => 30,
        -background => $bg_color2,  
        -foreground => $fg_color
    )->pack(
        -side   => 'top',
        -anchor => 'center',
        -padx   => 5,
        -pady   => 5,
        -fill   => 'x'
    );

    
    $main_frame->Label(
        -text       => "Remote Port:",
        -font       => ['Arial', 10],
        -background => $bg_color,
        -foreground => $fg_color
    )->pack(
        -side   => 'top',
        -anchor => 'w',
        -padx   => 5,
        -pady   => 5
    );

    my $remote_port_entry = $main_frame->Entry(
        -font  => ['Arial', 10],
        -width => 30,
        -background => $bg_color2,  
        -foreground => $fg_color
    )->pack(
        -side   => 'top',
        -anchor => 'center',
        -padx   => 5,
        -pady   => 5,
        -fill   => 'x'
    );

    
    $main_frame->Label(
        -text       => "Output File Name (Optional):",
        -font       => ['Arial', 10],
        -background => $bg_color,
        -foreground => $fg_color,
    )->pack(
        -side   => 'top',
        -anchor => 'w',
        -padx   => 5,
        -pady   => 5
    );

    my $output_file_entry = $main_frame->Entry(
        -font  => ['Arial', 10],
        -width => 30,
        -background => $bg_color2,  
        -foreground => $fg_color
    )->pack(
        -side   => 'top',
        -anchor => 'center',
        -padx   => 5,
        -pady   => 5,
        -fill   => 'x'
    );

    my $button_frame = $main_frame->Frame(
        -background => $bg_color,
        -foreground => $fg_color,  
    )->pack(
        -side   => 'top',
        -anchor => 'center',
        -padx   => 5,
        -pady   => 10
    );

    my $sent_button = $button_frame->Button(
        -text            => "Send",
        -font            => ['Impact', 10],
        -background      => "#DB4C40",    
        -foreground      => "#F6F5AE",    
        -activebackground => "#45A049",   
        -width           => 10,
        -command         => sub {
            my $remote_host      = $remote_host_entry->get();
            my $remote_port      = $remote_port_entry->get();
            my $output_file_name = $output_file_entry->get();

            if ($remote_host !~ /^(localhost|^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9]))$/) {
                $child_label->configure(-text => "Please input valid IP address."); 
                return;
            }

            if ($remote_port !~ /^\d+$/) {
                $child_label->configure(-text => "Please input valid port number.");
                return;
            }

            if ($remote_port < 0 || $remote_port > 65535) {
                $child_label->configure(-text => "Please input valid port number.");
                return;
            }

            unless ($remote_host && $remote_port) {
                $child_label->configure(-text => "Please input remote host and port.");
                return;
            }

            if ($output_file_name !~ /\.[a-zA-Z]{3}$/) {
                $output_file_name .= ".wav";
            }

            socket_send($remote_host, $remote_port, $output_file_name);
            $child->destroy();
        }
    )->pack(
        -side   => 'top',
        -anchor => 'center',
        -padx   => 5,
        -pady   => 5
    );
}

sub socket_send {

    my ($remote_host, $remote_port, $output_file_name) = @_;
    $wav_file = $output_file if not $wav_file;
    if (!$wav_file) {
        die "cant find any file";
    }
    my $filename = $output_file_name ? $output_file_name : get_file_name($wav_file);


    my $socket = IO::Socket::INET->new(
        PeerAddr => $remote_host,
        PeerPort => $remote_port,
        Proto => "tcp",
        Type => SOCK_STREAM
    ) 
    or die "Cant connect to $remote_host:$remote_port: $!";
    print $socket ("sending file: ",  $filename, "\n");

    open(OUT, '<', $wav_file) or die "Could not open file '$wav_file' $!";

    binmode(OUT);

    my $buffer;

    while (read(OUT, $buffer, 1024)) {
        print $socket $buffer;
        print ".";
    }

    close(OUT);
    print $socket "finished sending file\n";

    $wav_label->configure(-text => "File sent to $remote_host");

    close $socket;

}

sub create_playback_label {
    my ($frame) = @_;
    my $playback_label = $frame->Label(
        -text => "Playback controls",
        -font => ['DejaVu Serif', 12, 'bold'],
        -background => $middle_field_background_color,
        -foreground => $middle_text_color
    )->pack(
        -padx => 10,
        -pady => 5,
        -fill => 'x'
    );
}

sub create_play_button {
    my ($frame) = @_;
     my $play_button = $frame->Button(
        -text   => ">",
        -command => \&play_wav_file,
        -background => "#00b153",
        -foreground => $middle_text_color,
        -font => ['DejaVu Serif', 12, 'bold']
    )->pack(
        -padx => 5,
        -pady => 5,
        -side => 'left'
    );
}

sub create_pause_button {
    my ($frame) = @_;
    my $pause_button = $frame->Button(
        -text   => "||",
        -command => \&pause_wav_file,
        -background => "#e6d845",
        -foreground => $middle_text_color,
        -font => ['DejaVu Serif', 12, 'bold']
    )->pack(
        -padx => 5,
        -pady => 5,
        -side => 'left'
    );
}

sub create_stop_button {
    my ($frame) = @_;
    my $stop_button = $frame->Button(
        -text   => "X",
        -command => \&stop_wav_file,
        -background => "#de3f53",
        -foreground => $middle_text_color,
        -font => ['DejaVu Serif', 12, 'bold']
    )->pack(
        -padx => 5,
        -pady => 5,
        -side => 'left'
    );
}

sub create_progress_bar {
    my ($frame) = @_;

    # Create the progress bar
    $progress_bar = $frame->ProgressBar(
        -background => '#FFFFFF',
        -width => 20,
        -length => 300, 
        -blocks => 50,
        -colors => [0, 'green'],
        -variable => \my $progress,
        -value => 0,
        -background => '#FFFFFF',
        -foreground => 'green',
    )->pack(
        -padx => 10,
        -pady => [10, 5],
        -fill => 'x'
    );
}

sub create_spectrogram_frame {
    $spectrogram_frame = $middle_frame->Frame(
        -background => $middle_field_background_color2,
        -relief => 'raised',
        -borderwidth => 2
    )->pack(
        -side => 'top',
        -anchor => 'e',
        -padx => 10,
        -pady => 10,
        -fill => 'x',
    );

    create_spectrogram_label($spectrogram_frame);
    create_spectrogram_canvas($spectrogram_frame);
    create_color_change_button($spectrogram_frame);
    #update_plot(\@target_freqs, \@test_amps);
}

sub create_spectrogram_label {
    my ($frame) = @_;
    my $spectrogram_label = $frame->Label(
        -text => "Spectrogram",
        -font => ['DejaVu Serif', 12, 'bold'],
        -background => $middle_field_background_color,
        -foreground => $middle_text_color
    )->pack(
        -padx => 10,
        -pady => 5,
        -fill => 'x'
    );
}

sub create_spectrogram_canvas {
    my ($frame) = @_;
    $spectrogram_canvas = $frame->Canvas(
        -background => "#E0E0E0",
        -width => 300,
        -height => 200
    )->pack(
        -padx => 10,
        -pady => 5,
        -fill => 'x'
    );
}

sub create_color_change_button {
    my ($frame) = @_;

    $color_change_button = $frame->Button(
        -text => "Change color of Spectralanalisis chart",
        -command => sub {
            change_color($frame);
        },
        -background => $button_color,
        -foreground => $middle_text_color,
        -font => ['DejaVu Serif', 12, 'bold']
    )->pack(
        -padx => 10,
        -pady => 5,
        -fill => 'x'
    );
}

sub change_color {
    my ($frame, $button) = @_;
    my $color_picker = $frame->ColorEditor(
        -title => 'SINC Perl - Color Picker',
        -cursor => 'hand2',
    );

    

    my $color = $color_picker->Show;
    $button->configure(
    		-bg => $color,
    	);
    
    
    if ($color) {
        $color_picker_color = $color;
    }


}

sub start_spectral_analysis {
    $wav_file = $wav_file if not $output_file;
    open my $wav_fh, '<', $wav_file or die "Cannot open WAV file: $!";
    binmode $wav_fh;
    seek($wav_fh, 44, 0);

    my $global_max_amp = 0;

    while ($is_playing) {
        my $buffer;
        read($wav_fh, $buffer, $fft_size * 2);
        last if length($buffer) < $fft_size * 2;
        #my @plot_shown_frequencies = @plot_shown_frequencies;
        my @samples = unpack("s*", $buffer);
        my $fft = Math::FFT->new(\@samples);
        my $output = $fft->rdft;

        my $max_amp = 0;
        my @amps;
        foreach my $freq (@target_freqs) {
            my $index = int($freq / (44100 / $fft_size));
            my $amp = sqrt($output->[$index * 2]**2 + $output->[$index * 2 + 1]**2);
            push @amps, $amp;
            $global_max_amp = $amp if $amp > $global_max_amp;
            $max_amp = $amp if $amp > $max_amp;
        }#

        @amps = map { $_ / $max_amp } @amps;  
        update_plot(\@target_freqs, \@amps,  \@plot_shown_frequencies);
        $spectrogram_frame->update;
        select(undef, undef, undef, 0.1);
    }

    close $wav_fh;
}

# Update spectrogram plot
sub update_plot {
    my ($freqs, $amps, $plot_shown_frequencies) = @_;

    $spectrogram_canvas->delete('all');

    my $width = 420;
    my $height = 200;
    my $bar_width = $width / @$freqs;

    for (my $i = 0; $i < @$freqs; $i++) {
        my $x = $i * $bar_width;
        my $y = $height - ($amps->[$i] * $height);
        $spectrogram_canvas->createRectangle($x, $y, $x + $bar_width - 2, $height, -fill => $color_picker_color);

        $spectrogram_canvas->createText($x + $bar_width / 2, $height-100-(10*$i), -text => $plot_shown_frequencies->[$i]. " Hz", -font => ['DejaVu Serif', 12, 'bold']);
    }
}

sub create_right_gui {

    my $friends_button = $right_frame->Button(
        -text => "Friends",
        -font => ['DejaVu Serif', 12, 'bold'],
        -background => $left_field_background_color,
        -foreground => $left_text_color,
        -command => sub {
            show_friend_overlay();
        },
    )->pack(
        -padx => 10,
        -pady => 5,
        -fill => 'x'
    );

    my $complete_sinc_logo = $right_frame->Photo(
        -format => 'png',
        -file => 'src/main/complete_sinc_logo_151x840.png'
    );

    my $complete_sinc_logo_label = $right_frame->Label(
        -image => $complete_sinc_logo,
        -background => $left_field_background_color,
        -relief => 'raised',
    )->pack(
        -padx => 10,
        -pady => 5,
        #-fill => 'x'
    );
}

sub show_friend_overlay {
    friend_utils::get_friends_list_uuids();
    friend_utils::get_friends_online_status();
    friend_utils::display_friend_list($main);
}


sub amplify_wav {
    if ($output_file) {
        $wav_file = undef;
    }
    my $amp_factor = shift;
    if ($wav_file || $output_file) {
        $wav_file = $output_file if not $wav_file;
        my ($header, $original_wave_data) = read_original_wave_data($wav_file);

        $amp_factor ||= $amp_input->get() || 15;

        my $changed_wave_data = change_amplification($original_wave_data, $amp_factor);
        write_wave_data($header, $changed_wave_data);
        #$wav_label->configure(-text => "Amplified WAV file created: $wav_file");

    } else {
        $wav_label->configure(-text => "No WAV file selected to amplify");
    }
    $amp_factor = undef;
}

sub add_echo {
    if ($output_file) {
        $wav_file = undef;
    }
    if ($wav_file || $output_file) {
        $wav_file = $output_file if not $wav_file;
        my ($header, $original_wave_data) = read_original_wave_data($wav_file);
        my $delay_in_seconds = $echo_input->get() || 0.8;  # Default to 0.8 if no input
        my $echo_factor = 0.3;  # ! want to do extra input field
        my ($new_header, $changed_wave_data) = echo($original_wave_data, $echo_factor, $delay_in_seconds, $header);
        write_wave_data($new_header, $changed_wave_data);
        #$wav_label->configure(-text => "Echo added to WAV file: $wav_file");
    } else {
        $wav_label->configure(-text => "No WAV file selected to add echo");
    }
}

sub reverse_wav {
    if ($output_file) {
        $wav_file = undef;
    }
    if ($wav_file || $output_file) {
        $wav_file = $output_file if not $wav_file;
        my ($header, $original_wave_data) = read_original_wave_data($wav_file);
        my $changed_wave_data = reverse_wave($original_wave_data);
        write_wave_data($header, $changed_wave_data);
        #$wav_label->configure(-text => "WAV file reversed: $wav_file");
    } else {
        $wav_label->configure(-text => "No WAV file selected to reverse");
    }
}

sub time_stretch_1 {
    if ($output_file) {
        $wav_file = undef;
    }
    if ($wav_file || $output_file) {
        $wav_file = $output_file if not $wav_file;
        my ($header, $original_wave_data) = read_original_wave_data($wav_file);
        my $time_stretch_factor = $time_stretch_input->get() || 1;  # Default to 1 if no input
        my ($new_header, $changed_wave_data) = time_stretch($original_wave_data, $time_stretch_factor, $header);
        write_wave_data($new_header, $changed_wave_data);
        #$wav_label->configure(-text => "Time stretched WAV file: $wav_file");
    } else {
        $wav_label->configure(-text => "No WAV file selected to time stretch");
    }
}

sub fade_in {
    if ($output_file) {
        $wav_file = undef;
    }
    if ($wav_file || $output_file) {
        $wav_file = $output_file if not $wav_file;
        my ($header, $original_wave_data) = read_original_wave_data($wav_file);
        my $fade_in_duration = $fade_in_input->get() || 2;  # Default to 2 seconds if no input
        my $fade_out_duration = $fade_in_input->get() || 2;  # ! maybe extra field
        my $changed_wave_data = fade_in_fade_out($original_wave_data, $fade_in_duration, $fade_out_duration, $header);
        write_wave_data($header, $changed_wave_data);
        #$wav_label->configure(-text => "Fade effect applied to WAV file: $wav_file");
    } else {
        $wav_label->configure(-text => "No WAV file selected to apply fade effect");
    }
}

sub read_original_wave_data {
    my ($filepath) = @_;
    open(IN, '<', $filepath) or die "Could not open file '$filepath' $!";
    binmode(IN);

    my $header;
    read(IN, $header, 44);  # Read wave header, first 44 bytes

    my $original_wave_data;
    {
        local $/ = undef;
        $original_wave_data = <IN>;
    }
    close(IN);

    return ($header, $original_wave_data);
}

sub write_wave_data {
    my ($header, $changed_wave_data) = @_;
    #my ($temp_fh, $output_file);
    my $temp_fh;
    ($temp_fh, $output_file) = tempfile(SUFFIX => '.wav', DIR => $temp_dir);

    #open(OUT, '>', $output_file) or die "Could not open file '$output_file' $!";
    
    binmode($temp_fh);
    print $temp_fh $header;
    print $temp_fh $changed_wave_data;
    close($temp_fh);
    my $file_name = get_file_name($output_file);
    $wav_label->configure(-text => "temp file saved: $file_name");
    print($temp_dir, " ", $output_file, "\n");
    $wav_file = undef;
}
sub change_amplification {  
    my ($original_wave_data, $amp_factor) = @_;
    my $amp_data = "";
    if ($original_wave_data && $amp_factor) {
        for (my $i = 0; $i < length($original_wave_data); $i += 2) {
            my $sample = unpack("s<", substr($original_wave_data, $i, 2));
            
            my $new_sample = int($sample * $amp_factor);

            $new_sample = 32767 if $new_sample > 32767;
            $new_sample = -32768 if $new_sample < -32768;

            $amp_data .= pack("s<", $new_sample);
        }

        return $amp_data;
    }
    else {
        return undef;
    }
}

sub echo {
    my ($original_wave_data, $echo_factor, $delay_in_seconds, $header) = @_;

    my $sample_rate = get_sample_rate($header);
    my $delay_in_samples = int($sample_rate * $delay_in_seconds);

    my $echo_data = "";

    for (my $i = 0; $i < length($original_wave_data); $i += 2) {
        my $sample = unpack("s<", substr($original_wave_data, $i, 2));
        my $echo_sample = unpack("s<", substr($original_wave_data, $i-$delay_in_samples*2, 2));

        my $new_sample = int($sample + $echo_sample * $echo_factor);

        substr($echo_data, $i, 2, pack("s<", $new_sample));
    }

    for (my $i = length($original_wave_data); $i < length($original_wave_data)+ $delay_in_samples * 2; $i += 2) {
        my $echo_sample = unpack("s<", substr($original_wave_data, $i-$delay_in_samples*2, 2));

        my $new_sample = int($echo_sample * $echo_factor);

        substr($echo_data, $i, 2, pack("s<", $new_sample));
    }

    my $new_file_size = length($echo_data) + 44;
    my $new_header = update_header($header, $new_file_size);
    return ($new_header, $echo_data);

}

sub reverse_wave {
    my ($original_wave_data) = @_;

    my $reverse_data = "";

    for (my $i = length($original_wave_data) - 2; $i >= 0; $i -= 2) {
        $reverse_data .= substr($original_wave_data, $i, 2);
    }

    return $reverse_data;
}

sub time_stretch {
    my ($original_wave_data, $time_stretch_factor, $header) = @_;
    print("time stretch faktor: ", $time_stretch_factor, "\n");
    print("original wave length: ", length($original_wave_data), "\n");
    my $original_sample_count = length($original_wave_data) / 2;
    my $new_sample_count = int($original_sample_count * $time_stretch_factor);

    my $stretched_wave_data = "";

     if ($time_stretch_factor > 1) {
        for (my $i = 0; $i < $original_sample_count; $i += $time_stretch_factor) {
            my $sample = substr($original_wave_data, int($i) * 2, 2);
            $stretched_wave_data .= $sample;
        }
    } elsif ($time_stretch_factor < 1) {
        my $step = 1 / $time_stretch_factor;
        for (my $i = 0; $i < $original_sample_count; $i++) {
            my $sample = substr($original_wave_data, $i * 2, 2);
            for (my $j = 0; $j < $step; $j++) {
                $stretched_wave_data .= $sample;
            }
        }
    }
    else {
        $stretched_wave_data = $original_wave_data;
    }

    my $expected_length = int($original_sample_count / $time_stretch_factor) * 2;
    print($expected_length);
    if (length($stretched_wave_data) != $expected_length) {
        print("Error: Expected length $expected_length, but got " . length($stretched_wave_data) . " instead.\n");
    }

    my $new_file_size = (length($stretched_wave_data)) + 44;
    my $new_header = update_header($header, $new_file_size);
    return ($new_header, $stretched_wave_data);
}

sub fade_in_fade_out {
    my ($original_wave_data, $fade_in_duration, $fade_out_duration, $header) = @_;

    my $sample_rate = get_sample_rate($header);

    my $fade_in_samples = int($sample_rate * $fade_in_duration);
    my $fade_out_samples = int($sample_rate * $fade_out_duration);

    my $fade_data = "";

    for (my $i = 0; $i < length($original_wave_data)/2; $i++) {
        my $sample = unpack("s<", substr($original_wave_data, $i*2, 2));
        
        if ($i < $fade_in_samples) 
        {
            $sample = int($sample * $i / $fade_in_samples);
        } 
        elsif ($i > length($original_wave_data)/2 - $fade_out_samples)
        {
            $sample = int($sample * ($fade_out_samples - ($i - (length($original_wave_data)/2 - $fade_out_samples))) / $fade_in_samples);
        }

        $fade_data .= pack("s<", $sample);
    }
    return $fade_data;
}

sub get_sample_rate {
    my ($header) = @_;
    return unpack("V", substr($header, 24, 4));  # Extract 4 bytes starting from byte 24
}

sub update_header {
    my ($header, $new_file_size) = @_;
    substr($header, 4, 4, pack("V", $new_file_size-8));
    substr($header, 40, 4, pack("V", $new_file_size-44));
    return $header;
}

sub play_wav_file {
    $wav_file = $output_file ? $output_file : $wav_file;
    #$wav_file = 'C:/Users/Geisthardt/Documents/Ausbildung/Hausaufgaben/Week 6/perl wav/test.wav';

    if (!$wav_file || $is_playing) {
        $wav_label->configure(-text => "No WAV file selected to play") unless $wav_file;
        return;
    }

    my $file_name = get_file_name($wav_file);
    
    $wav_label->configure(-text => "Playing: $file_name");
    $is_playing = 1;
    $spectrogram_frame->after(0, \&start_spectral_analysis);

    $duration = get_wav_duration($wav_file);
    if (!$is_paused && !$playing_wav && !$wav_file)  {
        $start_time = start_time() - $pause_time;
        $playing_wav->Restart();
        print("resumed");
    } elsif ($wav_file) {
        print("hello");
        $start_time = start_time();
        #printf "%s %s\n",$^V,$Win32::Sound::VERSION;
        #print($wav_file, "\n");
        #print(Win32::Sound::Devices());
        #my $wav_file = "C:/Users/Geisthardt/Documents/Ausbildung/Hausaufgaben/Week 6/perl wav/test.wav";
        #$wav_file =~ s/\\/\//g;
        #print($wav_file, "\n");

        Win32::Sound::Play($wav_file, SND_ASYNC) or die $!;

        #$playing_wav = new Win32::Sound::WaveOut($wav_file);
        #$playing_wav->Load($wav_file) or die $!;
        #$playing_wav->Play();
        
        $spectrogram_canvas->delete('all');
    }
    else 
    {
        print("no wav file");
    }

    $is_paused = 0;

    update_progress_bar();
}


sub pause_wav_file {
    if ($is_playing) {
        $is_playing = 0;
        Win32::Sound::Stop();
        #$playing_wav->Pause();
        $wav_label->configure(-text => "Playback paused");
        $pause_time = $current_time;
        $is_paused = 1;
    }
}

sub stop_wav_file {

    $is_playing = 0;
    $current_time = 0;
    $progress = 0;
    $progress_bar->value($progress);
    Win32::Sound::Stop();
    #$playing_wav->Reset();
    #$playing_wav->Unload();
    #Win32::Sound::Stop();
    $wav_label->configure(-text => "Playback stopped");
    $spectrogram_canvas->delete('all');
    $pause_time = undef;
    $is_paused = undef;
}

sub update_progress_bar {
    if ($is_playing) {
        $current_time = time() - $start_time;
        $progress = ($current_time / $duration) * 100;
        $progress_bar->value($progress);  
        if ($current_time < $duration) {
            $main->after(100, \&update_progress_bar);  
        } else {
            stop_wav_file();  
        }
    }
}

sub start_time {
    return time();
}

sub get_wav_duration {
    my ($file) = @_;
    open my $fh, '<', $file or die "Could not open '$file' $!";
    binmode $fh;
    seek $fh, 40, 0;
    read $fh, my $filesiz_crack, 4;
    my $file_size = unpack('V', $filesiz_crack) +44;
    seek $fh, 22, 0;
    read $fh, my $numchnl, 2;
    my $num_channels = unpack('v', $numchnl);
    seek $fh, 24, 0;
    read $fh, my $samp_per_sec, 4;
    my $sample_rate = unpack('V', $samp_per_sec);  
    seek $fh, 34, 0;
    read $fh, my $bitssample, 2;
    my $bits_per_sample = unpack('v', $bitssample);
    return ((8 * $file_size) / ($sample_rate * $num_channels * $bits_per_sample))
}

sub get_file_name {
    my ($file) = @_;
    my ($filename) = $file =~ /([^\/\\]+)$/;
    return $filename;
}