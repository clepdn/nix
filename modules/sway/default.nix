{ config, pkgs, lib, ... }:
let
  cfg = config.myNixOS.sway;
  defaultStatusCommand = pkgs.writeShellScript "sway-status" ''
    while true; do
      date '+%a %d %b  %H:%M'
      sleep 10
    done
  '';
  swayConfig = pkgs.writeText "sway-config" ''
    ### Variables
    set $mod ${cfg.modifier}
    set $term foot
    set $menu fuzzel
    set $lock ${lib.getExe config.myNixOS.swaylock.package} -f

    ${cfg.outputConfig}

    ### Window appearance
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
    exec ${pkgs.swayidle}/bin/swayidle -w \
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
    bindsym Mod4+Mod1+l exec $lock

    # Focus
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

    ### Hardware keys
    bindsym --locked XF86MonBrightnessUp exec brightnessctl set 10%+
    bindsym --locked XF86MonBrightnessDown exec brightnessctl set 10%-
    bindsym --locked XF86AudioRaiseVolume exec wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
    bindsym --locked XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    bindsym --locked XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    bindsym --locked XF86AudioMicMute exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    bindsym --locked XF86AudioPlay exec playerctl play-pause
    bindsym --locked XF86AudioNext exec playerctl next
    bindsym --locked XF86AudioPrev exec playerctl previous

    ### Status bar
    bar {
      position top
      font pango:JetBrainsMono Nerd Font 10
      status_command ${cfg.statusCommand}
      colors {
        statusline #ffffff
        background #000000cc
      }
    }

    ${cfg.extraConfig}
    include /etc/sway/config.d/*
  '';
in
{
  imports = [ ../swaylock ];

  options.myNixOS.sway = {
    enable = lib.mkEnableOption "the shared Sway desktop configuration";

    modifier = lib.mkOption {
      type = lib.types.str;
      default = "Mod4";
      description = "Sway modifier key; Mod4 is Super and Mod1 is Alt.";
    };

    outputConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Host-specific Sway output configuration.";
    };

    statusCommand = lib.mkOption {
      type = lib.types.str;
      default = defaultStatusCommand;
      description = "Long-running command used by swaybar for status text.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional lines appended to the generated Sway configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    myNixOS.swaylock.enable = true;

    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      extraPackages = with pkgs; [
        foot
        fuzzel
        mako
        libnotify
        grim
        slurp
        wl-clipboard
        swayidle
        swaybg
        brightnessctl
        playerctl
        networkmanagerapplet
        polkit_gnome
        wdisplays
        waybar
      ];
    };

    environment.etc."sway/config".source = swayConfig;

    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd sway";
        user = "greeter";
      };
    };

    security.polkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = false;
      pulse.enable = true;
    };
    security.rtkit.enable = true;

    xdg.portal = {
      enable = true;
      wlr.enable = true;
    };

    services.udev.packages = [ pkgs.brightnessctl ];

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
      dejavu_fonts
    ];
  };
}
