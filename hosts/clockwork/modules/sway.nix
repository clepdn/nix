{ config, pkgs, lib, ... }:
let
	# swaybar status line. Kept in its own script so sway's config parser doesn't
	# try to expand the shell '$' expressions as sway variables.
	statusScript = pkgs.writeShellScript "sway-status" ''
		while true; do
			bat=$(cat /sys/class/power_supply/*/capacity 2>/dev/null | head -n1)
			stat=$(cat /sys/class/power_supply/*/status 2>/dev/null | head -n1)
			echo "''${stat} ''${bat}%  |  $(date '+%a %d %b  %H:%M')"
			sleep 10
		done
	'';

	# uConsole 5" panel is a 720x1280 portrait DSI display mounted sideways, so
	# we rotate 90deg for landscape. The kernel usually names it DSI-1 on CM4,
	# but some kernel revisions expose it as DSI-2 -- configuring both is
	# harmless (sway ignores output blocks for connectors that don't exist).
	swayConfig = pkgs.writeText "sway-config" ''
		### Variables
		set $mod Mod4
		set $term foot
		set $menu fuzzel
		set $lock swaylock -f

		### Display (built-in uConsole panel)
		output DSI-1 {
			mode 720x1280
			transform 90
			scale 1.0
		}
		output DSI-2 {
			mode 720x1280
			transform 90
			scale 1.0
		}
		# External HDMI, when connected, sits to the right of the internal panel.
		output HDMI-A-1 {
			scale 1.0
			position 1280 0
		}

		### Small-screen ergonomics
		default_border pixel 2
		default_floating_border pixel 2
		titlebar_padding 3
		gaps inner 0
		gaps outer 0
		font pango:JetBrainsMono Nerd Font 10

		### Input
		input type:keyboard {
			xkb_layout us
		}
		input type:pointer {
			natural_scroll disabled
			tap enabled
		}
		input type:touchpad {
			natural_scroll enabled
			tap enabled
		}

		### Autostart
		exec ${pkgs.mako}/bin/mako
		exec ${pkgs.networkmanagerapplet}/bin/nm-applet --indicator
		exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
		exec swayidle -w \
			timeout 300 '$lock' \
			timeout 600 'swaymsg "output * power off"' \
				resume 'swaymsg "output * power on"' \
			before-sleep '$lock'

		### Key bindings
		bindsym $mod+Return exec $term
		bindsym $mod+d exec $menu
		bindsym $mod+Shift+q kill
		bindsym $mod+Shift+c reload
		bindsym $mod+Shift+e exec swaynag -t warning \
			-m 'Exit sway?' -B 'Yes' 'swaymsg exit'
		bindsym $mod+l exec $lock

		# Focus (arrows + vim keys, handy on the built-in keyboard)
		bindsym $mod+Left focus left
		bindsym $mod+Down focus down
		bindsym $mod+Up focus up
		bindsym $mod+Right focus right
		bindsym $mod+h focus left
		bindsym $mod+j focus down
		bindsym $mod+k focus up
		bindsym $mod+l focus right

		# Move windows
		bindsym $mod+Shift+Left move left
		bindsym $mod+Shift+Down move down
		bindsym $mod+Shift+Up move up
		bindsym $mod+Shift+Right move right

		# Workspaces
		bindsym $mod+1 workspace number 1
		bindsym $mod+2 workspace number 2
		bindsym $mod+3 workspace number 3
		bindsym $mod+4 workspace number 4
		bindsym $mod+5 workspace number 5
		bindsym $mod+6 workspace number 6
		bindsym $mod+Shift+1 move container to workspace number 1
		bindsym $mod+Shift+2 move container to workspace number 2
		bindsym $mod+Shift+3 move container to workspace number 3
		bindsym $mod+Shift+4 move container to workspace number 4
		bindsym $mod+Shift+5 move container to workspace number 5
		bindsym $mod+Shift+6 move container to workspace number 6

		# Layout
		bindsym $mod+b splith
		bindsym $mod+v splitv
		bindsym $mod+f fullscreen
		bindsym $mod+Shift+space floating toggle
		bindsym $mod+space focus mode_toggle
		bindsym $mod+s layout stacking
		bindsym $mod+w layout tabbed
		bindsym $mod+e layout toggle split

		# Screenshots
		bindsym Print exec grim - | wl-copy
		bindsym $mod+Print exec grim -g "$(slurp)" - | wl-copy

		### Hardware keys (also work while locked)
		bindsym --locked XF86MonBrightnessUp exec brightnessctl set 10%+
		bindsym --locked XF86MonBrightnessDown exec brightnessctl set 10%-
		bindsym --locked XF86AudioRaiseVolume exec wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
		bindsym --locked XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
		bindsym --locked XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
		bindsym --locked XF86AudioMicMute exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
		bindsym --locked XF86AudioPlay exec playerctl play-pause
		bindsym --locked XF86AudioNext exec playerctl next
		bindsym --locked XF86AudioPrev exec playerctl previous

		### Status bar (built-in swaybar; battery from AXP fuel gauge)
		bar {
			position top
			font pango:JetBrainsMono Nerd Font 10
			status_command ${statusScript}
			colors {
				statusline #ffffff
				background #000000cc
			}
		}

		include /etc/sway/config.d/*
	'';
in
{
	programs.sway = {
		enable = true;
		wrapperFeatures.gtk = true;
		extraPackages = with pkgs; [
			foot            # terminal
			fuzzel          # launcher
			mako            # notifications
			libnotify       # notify-send
			grim slurp      # screenshots
			wl-clipboard    # wl-copy / wl-paste
			swaylock swayidle swaybg
			brightnessctl
			playerctl
			networkmanagerapplet
			polkit_gnome
			wdisplays       # GUI display arrangement
			waybar          # available if you prefer it over swaybar
		];
	};

	# Provide the config at /etc/sway/config (sway searches here after the user's
	# ~/.config/sway/config, so callie can still override per-user).
	environment.etc."sway/config".source = swayConfig;

	# Minimal swaylock appearance.
	environment.etc."swaylock/config".text = ''
		color=000000
		ignore-empty-password
		show-failed-attempts
		indicator-caps-lock
	'';

	# Login manager: tuigreet on tty1 that launches sway after auth.
	services.greetd = {
		enable = true;
		settings = {
			default_session = {
				command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd sway";
				user = "greeter";
			};
		};
	};

	# swaylock must be able to authenticate via PAM.
	security.pam.services.swaylock = { };
	security.polkit.enable = true;

	# Audio.
	services.pipewire = {
		enable = true;
		alsa.enable = true;
		alsa.support32Bit = false;
		pulse.enable = true;
	};
	security.rtkit.enable = true;

	# Screenshot/screencast portal for wlroots.
	xdg.portal = {
		enable = true;
		wlr.enable = true;
	};

	# Let brightnessctl adjust the backlight without root.
	services.udev.packages = [ pkgs.brightnessctl ];

	fonts.packages = with pkgs; [
		nerd-fonts.jetbrains-mono
		noto-fonts
		noto-fonts-color-emoji
		dejavu_fonts
	];

	environment.systemPackages = with pkgs; [
		firefox
		pavucontrol
		foot
		htop
	];
}
