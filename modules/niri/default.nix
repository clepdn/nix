{ pkgs, inputs, ... }:
let
  # Quickshell config dir (from inputs.quickshell-config / tangled repo).
  # Materialise it as a plain directory in the store so `qs -c <path>` is happy.
  quickshellConfig = pkgs.runCommand "quickshell-eww-config" { } ''
    mkdir -p $out
    cp -r ${inputs.quickshell-config}/. $out/
  '';
in
{
  imports = [
    inputs.niri.nixosModules.niri
  ];

  programs.niri.enable = true;

  home-manager.users.callie.imports = [ ./settings.nix ./binds.nix ];

  # Fonts + icon theme the bar's shell.qml hardcodes.
  fonts.packages = with pkgs; [
    inter
    maple-mono.NF
    papirus-icon-theme
  ];

  environment.systemPackages = with pkgs; [ quickshell awww ];

  systemd.packages = with pkgs.kdePackages; [
    kded
    powerdevil
    kwallet-pam
    polkit-kde-agent-1
  ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

  # Capture the login password so plasma-kwallet-pam can unlock the wallet
  # when niri starts from SDDM.
  security.pam.services.sddm.kwallet.enable = true;

  # Expose the bar config at a stable path so it can be launched manually too:
  #   qs -c /etc/quickshell/eww
  environment.etc."quickshell/eww".source = quickshellConfig;

  # Run the bar as a user service tied to the niri session.
  # Same lifecycle pattern niri-flake uses for its own polkit agent.
  systemd.user.services.quickshell-bar = {
    description = "Quickshell bar (eww config) for niri";
    wantedBy = [ "niri.service" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.quickshell}/bin/qs -c /etc/quickshell/eww";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

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

  systemd.user.services.plasma-kded6.wantedBy = [ "niri.service" ];
  systemd.user.services.plasma-powerdevil.wantedBy = [ "niri.service" ];
  systemd.user.services.plasma-kwallet-pam.wantedBy = [ "niri.service" ];
  systemd.user.services.plasma-polkit-agent.wantedBy = [ "niri.service" ];
}
