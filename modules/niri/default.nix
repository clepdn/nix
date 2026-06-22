{ config, pkgs, lib, inputs, ... }:
let
  quickshellConfig = pkgs.runCommand "quickshell-eww-config" { } ''
    mkdir -p $out
    cp -r ${inputs.quickshell-config}/. $out/
  '';
  niriPkgs = inputs.niri.packages.${pkgs.system};
in
{
  imports = [
    inputs.niri.nixosModules.niri
  ];

  programs.niri = {
    enable = true;
    package = niriPkgs.niri-unstable;
  };

  services.gnome.gnome-keyring.enable = lib.mkForce false;

  home-manager.users.callie.imports = [
    ./settings.nix
    ./binds.nix
    {
      services.gnome-keyring.enable = lib.mkForce false;

      programs.niri.settings.xwayland-satellite = {
        enable = true;
        path = lib.getExe niriPkgs.xwayland-satellite-unstable;
      };
    }
  ];

  environment.systemPackages = with pkgs; [ 
    quickshell 
    awww 
    brightnessctl 
    rofi 
    rofimoji
   ];

  services.udev.packages = [ pkgs.brightnessctl ];

  systemd.packages = with pkgs.kdePackages; [
    kded
    powerdevil
    kwallet-pam
    polkit-kde-agent-1
  ];

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
  systemd.user.services.plasma-kded6 = {
    overrideStrategy = "asDropin";
    wantedBy = [ "niri.service" ];
  };
  systemd.user.services.plasma-powerdevil = {
    overrideStrategy = "asDropin";
    wantedBy = [ "niri.service" ];
  };
  systemd.user.services.plasma-kwallet-pam = {
    overrideStrategy = "asDropin";
    wantedBy = [ "niri.service" ];
  };
  systemd.user.services.plasma-polkit-agent = {
    overrideStrategy = "asDropin";
    wantedBy = [ "niri.service" ];
  };
}
