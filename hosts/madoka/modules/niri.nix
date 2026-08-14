{ self, pkgs, ... }:
{
  imports = [
    "${self}/modules/niri"
  ];

  myNixOS.niri.idle.sleep = {
    enable = true;
  };
  myNixOS.niri.idle.dim.enable = true;

  home-manager.users.callie.programs.niri.settings.outputs."eDP-1" = {
    mode = { width = 1920; height = 1200; refresh = 59.950; };
    scale = 1.25;
  };

  systemd.user.services.awww-wallpaper = {
    description = "Hatsune Miku wallpaper";
    wantedBy = [ "niri.service" ];
    after = [ "awww-daemon.service" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.awww}/bin/awww img ${self}/assets/hatsunemiku.jpg";
    };
  };
}
