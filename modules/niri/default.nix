{ config, pkgs, lib, inputs, ... }:
let
  quickshellConfig = pkgs.runCommand "quickshell-eww-config" { } ''
    mkdir -p $out
    cp -r ${inputs.quickshell-config}/. $out/
  '';
  niriPkgs = inputs.niri.packages.${pkgs.system};
  niri-kill-focused = pkgs.callPackage ./niri-kill-focused.nix {
    inherit (niriPkgs) niri-unstable;
  };
in
{
  imports = [
    inputs.niri.nixosModules.niri
    ./idle.nix
  ];

  programs = {
    niri = {
      enable = true;
      package = niriPkgs.niri-unstable;
    };

    uwsm = {
      enable = true;
      waylandCompositors.niri = {
        prettyName = "Niri";
        binPath = lib.getExe config.programs.niri.package;
      };
    };

    nm_applet.enable = true;
  };

  services.gnome.gnome-keyring.enable = lib.mkForce false;

  services.blueman.enable = true;
  hardware.bluetooth.enable = true;

  # This was applied in err chasing down a discord fix (I didn't have mako.) I don't know if it actually does anything useful but the name sounds promising.
  environment.sessionVariables.NIXOS_OZONE_WL = "1"; 

  home-manager.users.callie.imports = [
    ./settings.nix
    ./binds.nix
    ./plasma.nix
    {
      services.gnome-keyring.enable = lib.mkForce false;

      programs.niri.settings.xwayland-satellite = {
        enable = true;
        path = lib.getExe niriPkgs.xwayland-satellite-unstable;
      };

      services.mako = {
        enable = true;
        settings = {
          font = "Inter 11";
          background-color = "#000000ff";
          text-color = "#ffffffff";
          border-color = "#bdbdbdff";
          border-size = 2;
          border-radius = 0;
          default-timeout = 5000;
          ignore-timeout = false;
          margin = 12;
          padding = "10";
          max-icon-size = 48;
          icons = true;
          markup = true;
          layer = "overlay";
          anchor = "top-right";

          "urgency=high".default-timeout = 0;
        };
      };

      xdg.configFile."swaylock/config".text = ''
        color=000000
        ignore-empty-password
        show-failed-attempts
        indicator-caps-lock
      '';

      home.packages = [ niri-kill-focused pkgs.playerctl ];
    }
  ];

  security.pam.services.swaylock.fprintAuth = false;

  environment.systemPackages = with pkgs; [
    quickshell
    awww
    brightnessctl
    rofi
    rofimoji
    lxmenu-data
    wlogout
    swaylock
    swayidle
  ];

  environment.pathsToLink = [ "/etc/xdg/menus" ];

  services.udev.packages = [ pkgs.brightnessctl ];

  systemd.packages = [ pkgs.mako pkgs.blueman ] ++ (with pkgs.kdePackages; [
    powerdevil
    kwallet-pam
    polkit-kde-agent-1
  ]);

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    config.niri = {
      default = [ "kde" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
    };
  };

  qt = {
    enable = true;
    platformTheme = "kde";
  };

  security.pam.services.sddm.kwallet.enable = true;

  security.pam.services.swaylock = { };

  environment.etc."quickshell/eww".source = quickshellConfig;

  systemd.user.services.quickshell-bar = {
    description = "Quickshell bar (eww config) for niri";
    wantedBy = [ "niri.service" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    path = [ config.programs.niri.package ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.quickshell}/bin/qs -c /etc/quickshell/eww";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  fonts.packages = with pkgs; [
    inter
    maple-mono.NF
    papirus-icon-theme
  ];

  systemd.user.services.awww-daemon = {
    description = "awww wallpaper daemon";
    wantedBy = [ "niri.service" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  # systemd.user.services.<name>.wantedBy renders a full stub unit into
  # /etc/systemd/user/ that shadows the package-shipped one (no ExecStart).
  # asDropin emits only [Install] as a .d/overrides.conf overlay instead.
  systemd.user.services.mako = {
    overrideStrategy = "asDropin";
    wantedBy = [ "niri.service" ];
  };

  systemd.user.services.plasma-powerdevil = {
    overrideStrategy = "asDropin";
    wantedBy = [ "niri.service" ];
  };
  # pam_kwallet_init must run after niri has imported WAYLAND_DISPLAY into
  # the user systemd env, otherwise the PAM-launched ksecretd aborts on
  # QApplication and the wallet stays locked.
  systemd.user.services.plasma-kwallet-pam = {
    overrideStrategy = "asDropin";
    wantedBy = [ "niri.service" ];
    after = [ "niri.service" ];
  };
  systemd.user.services.plasma-polkit-agent = {
    overrideStrategy = "asDropin";
    wantedBy = [ "niri.service" ];
  };

  systemd.user.services.blueman-applet = {
    overrideStrategy = "asDropin";
    wantedBy = [ "niri.service" ];
  };
}
