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

  # Fonts + icon theme the bar's shell.qml hardcodes.
  fonts.packages = with pkgs; [
    inter
    maple-mono.NF
    papirus-icon-theme
  ];

  environment.systemPackages = with pkgs; [ quickshell ];

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
}
